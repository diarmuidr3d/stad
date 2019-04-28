import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/utilities/database.dart';

enum Operator {DublinBus, IarnrodEireann, BusEireann, Luas}

final allOperators = {
  "Dublin Bus": Operator.DublinBus,
  "Iarnród Éireann": Operator.IarnrodEireann,
  "Bus Éireann": Operator.BusEireann,
  "Luas": Operator.Luas,
};

List<Operator> operatorsFromStringList(List operators) {
  if (operators[0] is Operator) return operators;
  else if (operators[0] is String) return operators.map((op) => allOperators[op]);
  else throw Exception("Operator is neither Operator nor String, don't know how to handle!");
}

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
  String apiStopCode;
  List<Operator> operators;
  List<RouteDirection> servedBy = [];
  Stop({
    this.stopCode,
    this.apiStopCode,
    this.address,
    this.latLng,
    this.operators
  });

  String toString() => stopCode + " - " + address;

  static Future<Stop> fromMap(Map<String, dynamic> map) async {
    var stop = Stop(
      stopCode: map["stop_code"],
      address: map["address"],
      apiStopCode: map["api_stop_code"],
      latLng: LatLng(double.parse(map["latitude"]), double.parse(map["longitude"])),
    );
    if (map.containsKey("operators")) stop.operators = operatorsFromStringList(map["operators"]);
    else stop.operators = operatorsFromStringList(await RouteDB().getOperatorsForStop(stop.stopCode));
    return stop;
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

  String toString() => "$route - $heading: $dueMins mins";
}