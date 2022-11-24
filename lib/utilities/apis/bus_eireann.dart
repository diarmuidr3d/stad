import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:stad/models/models.dart';
import 'package:stad/utilities/apis/real_time_apis.dart';

import '../../models/trip.dart';
import '../database.dart';

class BusEireannAPI  implements RealTimeAPI {

  Future<Map<String, dynamic>> _getRealTimeDataTree(Uri uri) async {
    HttpClient client = new HttpClient();
    client.badCertificateCallback =((X509Certificate cert, String host, int port) => true);
    HttpClientRequest request = await client.openUrl("GET", uri);
    HttpClientResponse response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    return jsonDecode(reply)["stopPassageTdi"];
  }

  Future<Map<String, dynamic>> _getRealTimeStopDataTree(String stopCode) async {
    return _getRealTimeDataTree(Uri.parse('http://buseireann.ie/inc/proto/stopPassageTdi.php?stop_point=$stopCode'));
  }

  Future<Map<String, dynamic>> _getRealTimeTripDataTree(Trip trip) async {
    String tripId = trip.id;
    return _getRealTimeDataTree(Uri.parse('http://buseireann.ie/inc/proto/stopPassageTdi.php?trip=$tripId'));
  }

  Future<Timing?> parseStopPassageAndCreateTiming(stopValues) async {
    if (stopValues != 0 && stopValues["departure_data"] != null) {
      final departureData = stopValues["departure_data"];
      if (departureData == null) return null; // TODO: handle arrivals
      final routeNum = await RouteDB().getRouteNumForApiNum(
          stopValues["route_duid"]["duid"]);
      final realTime = departureData["actual_passage_time_utc"] != null;
      final dueTime = realTime ? departureData["actual_passage_time_utc"] : departureData["scheduled_passage_time_utc"];
      final dueIn = DateTime.fromMillisecondsSinceEpoch(dueTime * 1000)
          .difference(DateTime.now()).inMinutes;
      return Timing(
          dueMins: dueIn,
          heading: departureData["multilingual_direction_text"]["defaultValue"],
          journeyReference: stopValues["trip_duid"]["duid"],
          route: routeNum,
          realTime: realTime,
          trip: parseTrip(stopValues),
      );
    }
  }

  Trip? parseTrip(stopValues) {
    if(stopValues["trip_duid"]["duid"] != null) {
      return Trip(id: stopValues["trip_duid"]["duid"], api: this);
    }
    return null;
  }

  LatLng? parseStopPassageAndGetVehicleLocation(stopValues) {
    if (stopValues != 0 && stopValues["latitude"] != null && stopValues["longitude"] != null) {
      return LatLng(
          be_lat_or_lon_to_degree(stopValues["latitude"]),
          be_lat_or_lon_to_degree(stopValues["longitude"])
      );
    }
    return null;
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var stopMap = await _getRealTimeStopDataTree(stopCode);
    var timings = <Timing>[];
    for (var v in stopMap.values) {
      final timing = await parseStopPassageAndCreateTiming(v);
      if(timing != null) timings.add(timing);
    }
    return timings;
  }

  @override
  Future<LatLng?> getVehicleLocationForTrip(Trip trip) async {
    var stopMap = await _getRealTimeTripDataTree(trip);
    LatLng? location;
    for (var v in stopMap.values) {
      final latLng = parseStopPassageAndGetVehicleLocation(v);
      if(latLng != null) {
        location = latLng;
        break;
      }
    }
    return location;
  }

  double be_lat_or_lon_to_degree(int lat_or_lon) {
    return lat_or_lon / 3600000.0;
  }

}