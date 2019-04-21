import 'dart:core';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xpath/xpath.dart';

abstract class RealTimeAPI {
  Future<ETree> getRealTimeStopDataTree(String stopCode);

  Future<List<Timing>> getTimings(String stopCode);
}

class DublinBusAPI implements RealTimeAPI {

  Future<ETree> getRealTimeStopDataTree(String stopCode) async {
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
    var tree = await getRealTimeStopDataTree(stopCode);
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
    final tree = await getRealTimeStopDataTree(stopCode);
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
    print("Start: L $left, R $right, C $curr");
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
    print("   End: L $left, R $right, Due $isDue, State $state");
    if (left > right) return stopList;
    return searchForBus(left, right, stopList, journeyRef, callback);
  }

}

class IarnrodEireannAPI  implements RealTimeAPI {
  
  Future<ETree> getRealTimeStopDataTree(String stopCode) async {
    http.Response response = await http.get('http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=$stopCode');
    final respBody = response.body.substring(response.body.indexOf('>') + 1); // Removes the xml artifact from the start of the response so it can be parsed
    return ETree.fromString(respBody);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await getRealTimeStopDataTree(stopCode);
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
      var dbTimings = await IarnrodEireannAPI().getTimings(stopCode);
      if (dbTimings != null) stopData.timings.addAll(dbTimings);
    }
    stopData.timings.sort((a, b) => a.dueMins.compareTo(b.dueMins));
    print(stopData.timings);
    return stopData;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    return DublinBusAPI().searchForBus(left, right, stopList, journeyRef, callback);
  }
}

class RouteDB {
  static final RouteDB _singleton = new RouteDB._internal();
  Future<Database> databaseFuture = _getDatabase();


  factory RouteDB() {
    return _singleton;
  }

  RouteDB._internal();

  static Future<Database> _getDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "station.db");
    final prefs = await SharedPreferences.getInstance();
    final copied = prefs.getBool(Keys.dbCopied);
//    Copy data from the assets/station.db to the working station.db if not done before
    if(copied != true) {
      ByteData data = await rootBundle.load(join("assets", "station.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await new File(path).writeAsBytes(bytes);
      prefs.setBool(Keys.dbCopied, true);
    }
    return openDatabase(path, version: 1,);
  }

  Future<List<Operator>> getOperatorsForStop(String stopCode) async {
    Database db = await databaseFuture;
    final result = await db.rawQuery(
        'SELECT operator FROM `stop_served_by_operator` WHERE ' +
            '  stop_code = "' + stopCode + '" ;'
    );
    return result.map((map) => operators[map["operator"]]).toList();
  }

  Future<List<Map<String, dynamic>>> getStopsMatchingParm(String searchText) async {
    RegExp numRegex = new RegExp(r"^\s*(\d)+\s*$");
    if (numRegex.hasMatch(searchText)) {
      return _getStopsMatchingInt(int.parse(searchText.trim()));
    } else {
      return _getStopsMatchingString(searchText);
    }
  }

  Future<List<Map<String, dynamic>>> _getStopsMatchingInt(int searchNum) async {
    Database db = await databaseFuture;
    return db.rawQuery(
        'SELECT * FROM `stops` WHERE ' +
            '  stop_code LIKE "' + searchNum.toString() + '%" ' +
            '  ORDER BY length(stop_code), stop_code ' +
            '  LIMIT 15; '
    );
  }

  Future<List<Map<String, dynamic>>> _getStopsMatchingString(String searchText) async {
    Database db = await databaseFuture;
    return db.rawQuery(
        'SELECT * FROM `stops` WHERE ' +
            '  address LIKE "%' + searchText + '%" ' +
            '  ORDER BY length(address) ; '
    );
  }

  Future<Stop> getStopWithStopCode(String stopCode) async {
    Database db = await databaseFuture;
    final result = await db.rawQuery(
        ' SELECT * FROM `stops` ' +
            ' WHERE stop_code = "' + stopCode + '"; '
    );
    if (result.length > 1) print("Multiple results for stop code: " + stopCode);
    if (result.length > 0) {
      final stopMap = result[0];
      final operators = await getOperatorsForStop(stopCode);
      return Stop(
        stopCode: stopCode,
        address: stopMap["address"],
        latLng: LatLng(double.parse(stopMap["latitude"]),
            double.parse(stopMap["longitude"])),
        operators: operators,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyStops(LatLng latLng) async {
    final stopLoadRange = "0.006"; // The range for which to load the stop markers
    Database db = await databaseFuture;
    var lat = latLng.latitude.toString();
    var lng = latLng.longitude.toString();
    return db.rawQuery('SELECT stops.stop_code AS stop_code, longitude, latitude, address, stop_served_by_operator.operator AS operator FROM stops ' +
        ' INNER JOIN stop_served_by_operator ON stops.stop_code = stop_served_by_operator.stop_code ' +
        ' WHERE (latitude - "' + lat + '") < ' + stopLoadRange +
        '  AND (latitude - "' + lat + '") > -' + stopLoadRange +
        '  AND (longitude - "' + lng + '") < ' + stopLoadRange +
        '  AND (longitude - "' + lng + '") > -' + stopLoadRange
    );
  }


  Future<List<StopVisited>> getPreviousStops(route, stopCode, inbound) async {
    Database db = await databaseFuture;
    List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT B.stop_code AS stopCode, address, latitude, longitude ' +
        ' FROM `stops` INNER JOIN ( ' +
          ' SELECT stop_code, sequence FROM `stop_for_route` WHERE ' +
            ' route_num = "'+route+'" AND inbound = '+inbound.toString()+' AND sequence != -1 ' +
        ' ) AS B ON stops.stop_code = B.stop_code ' +
        ' ORDER BY sequence; '
    );
    return results.map((obj) {
      return StopVisited(obj["stopCode"], obj["address"], LatLng(double.parse(obj["latitude"]), double.parse(obj["longitude"])));
    }).toList();
  }
}

class Favourites {

  static final Favourites _singleton = Favourites._internal();
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();


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
    return currentFavs;
  }

  Future<List<String>> removeFavourite(String stopCode) async {
    var myPrefs = await prefs;
    var currentFavs = await getFavourites();
    if (currentFavs != null) {
        currentFavs.remove(stopCode);
        myPrefs.setStringList(Keys.favouriteStations, currentFavs);
    }
    return currentFavs;
  }

  Future<bool> isFavourite(String stopCode) async {
    var currentFavs = await getFavourites();
    return currentFavs.contains(stopCode);
  }
}