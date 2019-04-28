import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpath/xpath.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities/database.dart';

abstract class RealTimeAPI {

  Future<List<Timing>> getTimings(String stopCode);
}

class DublinBusAPI implements RealTimeAPI {

  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    var envelope =
    '''<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
    <GetRealTimeStopData xmlns="http://dublinbus.ie/">
    <forceRefresh>false</forceRefresh>
    <stopId>$stopCode</stopId>
    </GetRealTimeStopData>
    </soap:Body>
    </soap:Envelope>''';

    http.Response response =
      await http.post('http://rtpi.dublinbus.ie/DublinBusRTPIService.asmx',
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction": "http://dublinbus.ie/GetRealTimeStopData",
          "Host": "rtpi.dublinbus.ie",
          "User-Agent": "okhttp/3.11.0"
        },
        body: envelope);

    final respBody = response.body.substring(response.body.indexOf('>') + 1); // Removes the xml artifact from the start of the response so it can be parsed
    return ETree.fromString(respBody);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData');
    var timings;
    if (xmlStopData != null) {
      timings = xmlStopData.map(getDetailsFromStopDataXml).toList();
    }
    return timings;
  }

  static Timing getDetailsFromStopDataXml(element) {
    Timing details = new Timing();
    details.route = element.xpath('/MonitoredVehicleJourney_PublishedLineName/text()')[0].name;
    details.heading = element.xpath('/MonitoredVehicleJourney_DestinationName/text()')[0].name;
    details.dueMins = DateTime.parse(
        element.xpath('/MonitoredCall_ExpectedDepartureTime/text()')[0].name)
        .difference(DateTime.now()).inMinutes;
    details.inbound = element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0;
    final journeyElement = element.xpath('/MonitoredVehicleJourney_VehicleRef/text()');
    if (journeyElement != null) details.journeyReference = journeyElement[0].name;
    return details;
  }

  Future<bool> stopHasJourneyDue(String stopCode, String journeyRef) async {
    final tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData/MonitoredVehicleJourney_VehicleRef/text()');
    if (xmlStopData != null) {
      for (final element in xmlStopData) {
        final journeyReference = element.name;
        if (journeyReference == journeyRef) return true;
      }
    }
    print("no journey ref for " + stopCode + " - " + journeyRef);
    return false;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    int curr = ((left + right) / 2).floor();
    final stop = stopList[curr];
    bool isDue = await stopHasJourneyDue(stop.stopCode, journeyRef);
    StopState state;
    if (isDue) {
      right = curr - 1;
      state = StopState.UNVISITED;
      callback(curr, stopList.length-1, state);
    } else {
      left = curr + 1;
      state = StopState.VISITED;
      callback(0, curr, state);
    }
    if (left > right) return stopList;
    return searchForBus(left, right, stopList, journeyRef, callback);
  }

}

class IarnrodEireannAPI  implements RealTimeAPI {
  
  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    http.Response response = await http.get('http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=$stopCode');
    final respBody = response.body.substring(response.body.indexOf('>') + 1); // Removes the xml artifact from the start of the response so it can be parsed
    return ETree.fromString(respBody);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/ArrayOfObjStationData/objStationData');
    var timings;
    if (xmlStopData != null) {
      timings = xmlStopData.map((element){
        Timing details = new Timing();
        details.route = element.xpath('/Traincode/text()')[0].name;
        details.heading = element.xpath('/Destination/text()')[0].name;
        details.journeyReference = element.xpath('/Traincode/text()')[0].name;
        details.dueMins = int.parse(element.xpath('/Duein/text()')[0].name);
//        TODO: Figure out how to parse direction for irish rail
//        details.inbound = element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0;
        return details;
      }).toList();
    }
    return timings;
  }

}

class BusEireannAPI  implements RealTimeAPI {

  Future<Map<String, dynamic>> _getRealTimeStopDataTree(String stopCode) async {
    HttpClient client = new HttpClient();
    client.badCertificateCallback =((X509Certificate cert, String host, int port) => true);
    HttpClientRequest request = await client.openUrl("GET", Uri.parse('http://buseireann.ie/inc/proto/stopPassageTdi.php?stop_point=$stopCode'));
    HttpClientResponse response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    return jsonDecode(reply)["stopPassageTdi"];
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var stopMap = await _getRealTimeStopDataTree(stopCode);
    var timings = <Timing>[];
    for (var v in stopMap.values) {
      if (v != 0 && v["departure_data"] != null) {
        final departureData = v["departure_data"];
        if (departureData == null) break; // TODO: handle arrivals
        final routeNum = await RouteDB().getRouteNumForApiNum(
            v["route_duid"]["duid"]);
        final dueIn = DateTime.fromMillisecondsSinceEpoch(departureData["scheduled_passage_time_utc"] * 1000)
            .difference(DateTime.now()).inMinutes;
        if (dueIn > 0)
          timings.add(Timing(
            dueMins: dueIn,
            heading: departureData["multilingual_direction_text"]["defaultValue"],
            journeyReference: v["trip_duid"]["duid"],
            route: routeNum,
          ));
      }
    }
    return timings;
  }

}

class LuasAPI  implements RealTimeAPI {

  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    http.Response response = await http.get('http://luasforecasts.rpa.ie/xml/get.ashx?action=forecast&encrypt=false&stop=$stopCode');
    print(response.body);
    return ETree.fromString(response.body);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/stopInfo/direction/tram');
    var timings = <Timing>[];
    if (xmlStopData != null) {
      for (var element in xmlStopData) {
        if(element.attributes["dueMins"] != "") {
          final dueMins = element.attributes["dueMins"] == "DUE" ? 0 : int.parse(element.attributes["dueMins"]);
          Timing details = new Timing(
            heading: element.attributes["destination"],
            dueMins: dueMins,
          );
//        TODO: Figure out how to parse direction, journey, route for luas
          timings.add(details);
        }
      };
    }
    return timings;
  }

}

class RealTimeUtilities {

  static Future<RealTimeStopData> getStopTimings(Stop stop) async {
    final stopCode = stop.stopCode;
    final stopData = RealTimeStopData(stop: stop);
    if (stop.operators == null) stop.operators = await RouteDB().getOperatorsForStop(stop.stopCode);
    if(stop.operators.contains(Operator.DublinBus)) {
      var dbTimings = await DublinBusAPI().getTimings(stopCode);
      if (dbTimings != null) stopData.timings.addAll(dbTimings);
    }
    if(stop.operators.contains(Operator.IarnrodEireann)) {
      var ieTimings = await IarnrodEireannAPI().getTimings(stopCode);
      if (ieTimings != null) stopData.timings.addAll(ieTimings);
    }
    if(stop.operators.contains(Operator.BusEireann)) {
      var beTimings = await BusEireannAPI().getTimings(stop.apiStopCode);
      if (beTimings != null) stopData.timings.addAll(beTimings);
    }
    if(stop.operators.contains(Operator.Luas)) {
      var luasTimings = await LuasAPI().getTimings(stop.apiStopCode);
      if (luasTimings != null) stopData.timings.addAll(luasTimings);
    }
    stopData.timings.sort((a, b) => a.dueMins.compareTo(b.dueMins));
    return stopData;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    return DublinBusAPI().searchForBus(left, right, stopList, journeyRef, callback);
  }
}



class Favourites {

  static final Favourites _singleton = Favourites._internal();
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  List<Function> favouriteUpDateListeners = [];


  factory Favourites() {
    return _singleton;
  }

  Favourites._internal();


  Future<List<String>> getFavourites() async {
    var myPrefs = await prefs;
    return myPrefs.getStringList(Keys.favouriteStations);
  }

  Future<List<String>> addFavourite(String stopCode) async {
    var myPrefs = await prefs;
    var currentFavs = await getFavourites();
    if (currentFavs != null) {
      if (!currentFavs.contains(stopCode)) {
        currentFavs.add(stopCode);
      }
    } else {
      currentFavs = [stopCode];
    }
    myPrefs.setStringList(Keys.favouriteStations, currentFavs);
    _updateListeners(currentFavs);
    return currentFavs;
  }

  Future<List<String>> removeFavourite(String stopCode) async {
    var myPrefs = await prefs;
    var currentFavs = await getFavourites();
    if (currentFavs != null) {
        currentFavs.remove(stopCode);
        myPrefs.setStringList(Keys.favouriteStations, currentFavs);
        _updateListeners(currentFavs);
    }
    return currentFavs;
  }

  Future<bool> isFavourite(String stopCode) async {
    var currentFavs = await getFavourites();
    return currentFavs != null && currentFavs.contains(stopCode);
  }

  void _updateListeners(currentFavs) {
    for (var listener in favouriteUpDateListeners) listener(currentFavs);
  }
}