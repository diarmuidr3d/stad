import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationManager {
  static final LocationManager _singleton = new LocationManager._internal();
  final Location _location = Location();
  bool _permission = false;
  bool checkingForPermission = false;
  Stream<LatLng?>? _onChanged;

  factory LocationManager() {
    return _singleton;
  }

  LocationManager._internal();

  /// Checks if the user has granted location access, requests it if not
  Future<bool> checkForPermission() async {
    _permission = await requestPermission();
    return _permission;
  }

  Future<bool> requestPermission() async {
    bool serviceStatus = await _location.serviceEnabled();
    if (serviceStatus) {
      bool _permission =
          (await _location.requestPermission()) == PermissionStatus.granted;
      return _permission;
    } else {
      bool serviceStatusResult = await _location.requestService();
      if (serviceStatusResult) {
        return await checkForPermission();
      }
    }
    return false;
  }

  /// Returns the current user location as a [LatLng]
  Future<LatLng?> getLocation() async {
    final permission = await checkForPermission();
    if (!permission) return null;
    final locationData = await _location.getLocation();
    return locationDataToLatLng(locationData);
  }

  LatLng? locationDataToLatLng(LocationData? locationData) {
    if (locationData == null) return null;
    if (locationData.latitude == null || locationData.longitude == null)
      return null;
    return LatLng(locationData.latitude!, locationData.longitude!);
  }

  /// Returns a stream of [LatLng]s for the current user location
  Future<Stream<LatLng?>?> getLocationListener() async {
    if (!await checkForPermission()) return null;
    if (_onChanged == null) {
      _onChanged = _location.onLocationChanged
          .map((locationData) => locationDataToLatLng(locationData));
    }
    return _onChanged;
  }
}
