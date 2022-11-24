import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models/locatable.dart';
import 'package:stad/models/route.dart';
import 'package:stad/models/trip.dart';

enum Operator {DublinBus, IarnrodEireann, BusEireann, Luas}

final allOperators = {
  "Dublin Bus": Operator.DublinBus,
  "Iarnród Éireann": Operator.IarnrodEireann,
  "Bus Éireann": Operator.BusEireann,
  "Luas": Operator.Luas,
};

class Stop implements Locatable {
  String stopCode;
  String address;
  String apiStopCode;
  Operator? operator;
  GeoLocation location;
  List<RouteDirection> servedBy = [];
  Stop({
    required this.stopCode,
    required this.apiStopCode,
    required this.address,
    required this.location,
    this.operator
  });

  String toString() => stopCode + " - " + address;

  static Stop fromMap(Map<String, dynamic> map) {
    return Stop(
      stopCode: map["stop_code"],
      address: map["address"],
      apiStopCode: map["api_stop_code"],
      location: GeoLocation(latitude: double.parse(map["latitude"]), longitude: double.parse(map["longitude"])),
      operator: allOperators[map["operator"]]
    );
  }

  get latLng {
    return location.toLatLng();
  }

  @override
  bool operator ==(Object other) {
    if(other.runtimeType != Stop) {
      return false;
    } else {
      Stop otherStop = other as Stop;
      return operator == otherStop.operator &&
          apiStopCode == otherStop.apiStopCode &&
          stopCode == otherStop.stopCode;
    }
  }
}

enum StopState {UNKNOWN, UNVISITED, VISITING, VISITED, LOADING}

class StopVisited extends Stop {
  StopState state = StopState.LOADING;
  StopVisited({
    required super.stopCode,
    required super.address,
    required super.location,
    required super.apiStopCode
  });
}

class RealTimeStopData {
  Stop stop;
  List<Timing>? timings = [];
  RealTimeStopData({required this.stop});
}

class Timing {
  String? route;
  String heading;
  int dueMins;
  String? journeyReference;
  int? inbound;
  bool realTime;
  Trip? trip;

  Timing({
    this.route,
    required this.heading,
    required this.dueMins,
    this.journeyReference,
    this.inbound,
    this.realTime = true,
    this.trip,
  });

  String toString() => "$route - $heading: $dueMins mins";
}