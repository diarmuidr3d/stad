import 'package:google_maps_flutter/google_maps_flutter.dart';

enum Operator {DublinBus, IarnrodEireann}

final operators = {
  "Dublin Bus": Operator.DublinBus,
  "Iarnród Éireann": Operator.IarnrodEireann,
};

class Route {
  String number;
  String towards;
  String from;
  List<RouteDirection> directions;
  Route({
    this.number,
    this.towards,
    this.from,
    this.directions
  });
}

class RouteDirection {
  Route route;
  String dirName;
  String dirCode;
  List<Stop> stops = [];
  RouteDirection({
    this.route,
    this.dirName,
    this.dirCode,
  });
}

class Stop {
  String stopCode;
  String address;
  LatLng latLng;
  List<Operator> operators;
  List<RouteDirection> servedBy = [];
  Stop({
    this.stopCode,
    this.address,
    this.latLng,
    this.operators
  });

  String toString() => stopCode + " - " + address;

  static Stop fromMap(Map<String, dynamic> map) {
    return Stop(
      stopCode: map["stop_code"],
      address: map["address"],
      latLng: LatLng(double.parse(map["latitude"]), double.parse(map["longitude"])),
    );
  }
}

enum StopState {UNKNOWN, UNVISITED, VISITING, VISITED, LOADING}

class StopVisited extends Stop {
  StopState state = StopState.LOADING;
  StopVisited(String stopCode, String address, LatLng latLng)
      : super(stopCode: stopCode, address: address, latLng: latLng);
}

class RealTimeStopData {
  Stop stop;
  List<Timing> timings = [];
  RealTimeStopData({this.stop});
}

class Timing {
  String route;
  String heading;
  int dueMins;
  String journeyReference;
  int inbound;

  Timing({
    this.route,
    this.heading,
    this.dueMins,
    this.journeyReference,
    this.inbound
  });
}