import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationManager {

  static final LocationManager _singleton = new LocationManager._internal();
  final _location = new Location();
  Future<bool> _permission;
  bool checkingForPermission = false;
  Stream<LatLng> _onChanged;


  factory LocationManager() {
    return _singleton;
  }

  LocationManager._internal();

  /// Checks if the user has granted location access, requests it if not
  Future<bool> checkForPermission() async {
//    if (await _location.hasPermission()) return true;
//    else return await _location.requestPermission();
    if(!checkingForPermission) {
      checkingForPermission = true;
      _permission = requestPermission();
    }
    bool permission = await _permission;
    return permission;
  }

  Future<bool> requestPermission() async {
    bool serviceStatus = await _location.serviceEnabled();
    print("Service status: $serviceStatus");
    if (serviceStatus) {
      bool _permission = await _location.requestPermission();
      print("Permission: $_permission");
      return _permission;
    } else {
      bool serviceStatusResult = await _location.requestService();
      print("Service status activated after request: $serviceStatusResult");
      if(serviceStatusResult){
        return await checkForPermission();
      }
    }
    return false;
  }

  /// Returns the current user location as a [LatLng]
  Future<LatLng> getLocation() async {
    print("getLocation get permission");
    final permission = await checkForPermission();
    print("getLocation Permission: $permission");
    if (!permission) return null;
    print("has permission, get location");
    final locationData = await _location.getLocation();
    print("locationdata: $locationData");
    return LatLng(locationData.latitude, locationData.longitude);
  }

  /// Returns a stream of [LatLng]s for the current user location
  Future<Stream<LatLng>> getLocationListener() async {
    print("getListener get permission");
    if (!await checkForPermission()) return null;
    if(_onChanged == null) {
      _onChanged = _location.onLocationChanged().map(
              (locationData) => LatLng(locationData.latitude, locationData.longitude));
    }
    return _onChanged;
  }
}