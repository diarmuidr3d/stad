import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models/route.dart';
import 'package:stad/models/vehicle.dart';

import '../utilities/apis/real_time_apis.dart';

class Trip {
  String id;
  Vehicle? vehicle;
  RouteDirection? routeDirection;
  RealTimeAPI? api;

  Trip({required this.id, this.api});

  Future<LatLng?> currentLocation() async {
    if(this.api != null) {
      return api!.getVehicleLocationForTrip(this);
    }
  }

  String toString() => "Trip: $id by $vehicle";
}