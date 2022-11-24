
import 'package:stad/models/locatable.dart';
import 'package:stad/models/route.dart';
import 'package:stad/models/vehicle.dart';

import '../utilities/apis/real_time_apis.dart';

class Trip {
  String id;
  Vehicle? vehicle;
  RouteDirection? routeDirection;
  RealTimeAPI? api;

  Trip({required this.id, this.api, this.vehicle});

  Future<GeoLocation?> currentVehicleLocation() async {
    if(this.api != null) {
      final vehicleLocation = api!.getVehicleLocationForTrip(this);
      return vehicleLocation;
    }
  }

  String toString() => "Trip: $id by $vehicle";
}