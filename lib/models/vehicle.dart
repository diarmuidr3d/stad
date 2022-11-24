import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/utilities/apis/real_time_apis.dart';

class Vehicle {
  String? id;
  LatLng? location;

  Vehicle({this.id, this.location});

  String toString() => "Vehicle: $id at $location";
}