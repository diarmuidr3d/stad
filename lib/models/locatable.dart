import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoLocation {
  final double _latitude;
  final double _longitude;

  GeoLocation({required double latitude, required double longitude})
    : _latitude = latitude,
      _longitude = longitude;

  GeoLocation.fromLatLng({required LatLng latLng})
    : _latitude = latLng.latitude,
      _longitude = latLng.longitude;

  toLatLng() {
    return LatLng(_latitude, _longitude);
  }

  get latitude => _latitude;
  get longitude => _longitude;
}

abstract class Locatable {
  GeoLocation? get location;
}