import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';

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
    print("getOperatorsForStop");
    Database db = await databaseFuture;
    final result = await db.rawQuery(
        'SELECT operator FROM `stop_served_by_operator` WHERE ' +
            '  stop_code = "' + stopCode + '" ;'
    );
    return result.map((map) => allOperators[map["operator"]]).toList();
  }

  Future<List<Map<String, dynamic>>> getStopsMatchingParm(String searchText) async {
    print("getStopsMatchingParm");
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
    print("getStopWithStopCode");
    Database db = await databaseFuture;
    final result = await db.rawQuery(
        ' SELECT * FROM `stops` ' +
            ' WHERE stop_code = "' + stopCode + '"; '
    );
    if (result.length > 1) throw Exception("Multiple results for stop code: " + stopCode);
    if (result.length > 0) return Stop.fromMap(result[0]);
    else throw Exception("This stop does not exist: " + stopCode);
  }

  Future<List<Stop>> getNearbyStopsOrderedByDistance(LatLng latLng) async {

    double getDistance(LatLng a, LatLng b) {
      return sqrt(pow(a.latitude - b.latitude, 2) + pow(a.longitude - b.longitude, 2));
    }

    var stopLoadRange = 0.006;
    var stops =  await getNearbyStops(latLng, stopLoadRange: stopLoadRange);
    while (stops == null || stops.isEmpty || stops.length < 10) {
      stopLoadRange = stopLoadRange * 2;
      print(stopLoadRange);
      stops = await getNearbyStops(latLng, stopLoadRange: stopLoadRange);
    }
    print(stops);
    stops.sort((stopA, stopB) => getDistance(latLng, stopA.latLng).compareTo(getDistance(latLng, stopB.latLng)));
    return stops;
  }

  /// Retrieves the stops within the [stopLoadRange] of [latLng].
  /// [stopLoadRange] is the latitude or longitude degrees in which to search
  Future<List<Stop>> getNearbyStops(LatLng latLng, { double stopLoadRange = 0.006 }) async {
    print("getNearbyStops");
    Database db = await databaseFuture;
    var lat = latLng.latitude;
    var lng = latLng.longitude;
//    NB: The negative longitude is considered positive (eg: -1 < -2)
    final result = await db.rawQuery("""
        SELECT stop_code, longitude, latitude, address, operator, api_stop_code
        FROM stops 
        WHERE latitude < "${lat + stopLoadRange}"
          AND latitude > "${lat - stopLoadRange}"
          AND longitude > "${lng + stopLoadRange}"
          AND longitude < "${lng - stopLoadRange}" ;  """);
    return result.map((stopMap) => Stop.fromMap(stopMap)).toList();
  }


  Future<List<StopVisited>> getPreviousStops(route, stopCode, inbound) async {
    print("getPreviousStops");
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

  Future<String> getRouteNumForApiNum(String apiNum) async {
    print("getRouteNumForApiNum");
    Database db = await databaseFuture;
    List<Map<String, dynamic>> result = await db.rawQuery(
        """SELECT number FROM `routes`
           WHERE api_route_number = "$apiNum"; """
    );
    if (result.length > 1) print("Multiple results for route code: " + apiNum);
    if (result.length > 0) {
      return result[0]["number"];
    }
    else throw Exception("$apiNum has no corresponding Route Number");
  }
}