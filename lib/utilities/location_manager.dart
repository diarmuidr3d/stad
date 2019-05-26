import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationManager {

  static final LocationManager _singleton = new LocationManager._internal();
  final _location = new Location();
  Stream<LatLng> _onChanged;


  factory LocationManager() {
    return _singleton;
  }

  LocationManager._internal();

  /// Checks if the user has granted location access, requests it if not
  Future<bool> checkForPermission() async {
    if (await _location.hasPermission()) return true;
    else return await _location.requestPermission();
  }

  /// Returns the current user location as a [LatLng]
  Future<LatLng> getLocation() async {
    if (!await checkForPermission()) return null;
    final locationData = await _location.getLocation();
    return LatLng(locationData.latitude, locationData.longitude);
  }

  /// Returns a stream of [LatLng]s for the current user location
  Future<Stream<LatLng>> getLocationListener() async {
    if (!await checkForPermission()) return null;
    if(_onChanged == null) {
      _onChanged = _location.onLocationChanged().map(
              (locationData) => LatLng(locationData.latitude, locationData.longitude));
    }
    return _onChanged;
  }
}