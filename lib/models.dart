import 'package:google_maps_flutter/google_maps_flutter.dart';

enum Operator {DublinBus, IarnrodEireann, BusEireann, Luas}

final allOperators = {
  "Dublin Bus": Operator.DublinBus,
  "Iarnród Éireann": Operator.IarnrodEireann,
  "Bus Éireann": Operator.BusEireann,
  "Luas": Operator.Luas,
};

class Route {
  String number;
  String towards;
  String from;
  List<RouteDirection> directions;
  Route({
    required this.number,
    required this.towards,
    required this.from,
    required this.directions
  });
}

class RouteDirection {
  Route route;
  String dirName;
  String dirCode;
  List<Stop> stops = [];
  RouteDirection({
    required this.route,
    required this.dirName,
    required this.dirCode,
  });
}

class Stop {
  String stopCode;
  String address;
  LatLng latLng;
  String apiStopCode;
  Operator? operator;
  List<RouteDirection> servedBy = [];
  Stop({
    required this.stopCode,
    required this.apiStopCode,
    required this.address,
    required this.latLng,
    this.operator
  });

  String toString() => stopCode + " - " + address;

  static Stop fromMap(Map<String, dynamic> map) {
    return Stop(
      stopCode: map["stop_code"],
      address: map["address"],
      apiStopCode: map["api_stop_code"],
      latLng: LatLng(double.parse(map["latitude"]), double.parse(map["longitude"])),
      operator: allOperators[map["operator"]]
    );
  }
}

enum StopState {UNKNOWN, UNVISITED, VISITING, VISITED, LOADING}

class StopVisited extends Stop {
  StopState state = StopState.LOADING;
  StopVisited({
    required String stopCode,
    required String address,
    required LatLng latLng,
    required String apiStopCode
  }) : super(stopCode: stopCode, address: address, latLng: latLng, apiStopCode: apiStopCode);
}

class RealTimeStopData {
  Stop stop;
  List<Timing> timings = [];
  RealTimeStopData({required this.stop});
}

class Timing {
  String route;
  String heading;
  int dueMins;
  String journeyReference;
  int inbound;
  bool realTime;
  LatLng? vehicleLocation;

  Timing({
    required this.route,
    required this.heading,
    required this.dueMins,
    required this.journeyReference,
    required this.inbound,
    this.realTime = true,
    this.vehicleLocation,
  });

  String toString() => "$route - $heading: $dueMins mins";
}