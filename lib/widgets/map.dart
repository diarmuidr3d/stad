import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stad/models.dart';

import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/utilities/database.dart';

class TransitMap extends StatefulWidget {
  final Completer<GoogleMapController> controller;
  final Function onStopTapped;

  TransitMap({
    @required this.controller,
    @required this.onStopTapped,
  }) : super(key: Keys.map);


  @override
  State<StatefulWidget> createState() {
    return TransitMapState();
  }
}

class TransitMapState extends State<TransitMap> {
  Set<Marker> markers;
  final minimumZoom = 14; // The minimum zoom level required to see markers
  static final initialPosition = CameraPosition(
    target: LatLng(53.3834, -8.2177501),
    zoom: 7,
  );
  var currentPosition = initialPosition;
  LatLng userPosition;
  var locationGot = false;
  RouteDB db = new RouteDB();
  final markerColours = {
    Operator.DublinBus: BitmapDescriptor.hueYellow,
    Operator.IarnrodEireann: BitmapDescriptor.hueGreen,
    Operator.BusEireann: BitmapDescriptor.hueRed,
    Operator.Luas: BitmapDescriptor.hueMagenta,
  };

  @override
  void initState() {
    super.initState();
    var location = new Location();
    location.onLocationChanged().listen((loc) => userPosition = LatLng(loc.latitude, loc.longitude));
    location.getLocation().then((loc) {
      locationGot = true;
      setState(() {
        userPosition = LatLng(loc.latitude, loc.longitude);
        currentPosition = CameraPosition(
          target: userPosition,
          zoom: 17,
        );
      });
      widget.controller.future.then((controller) {
        controller.animateCamera(
            CameraUpdate.newCameraPosition(currentPosition));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: currentPosition,
      onMapCreated: (GoogleMapController controller) async {
        widget.controller.complete(controller);
      },
      myLocationEnabled: true,
      compassEnabled: true,
      markers: markers,
      onCameraMove: _updateMarkers,
    );
  }

  void _updateMarkers(CameraPosition p) {
    if (p.zoom > minimumZoom) {
      db.getNearbyStops(p.target).then((stops) {
          var markerMapList = stops.map((stop) {
            return Marker(
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  markerColours[stop.operator]),
              markerId: MarkerId(stop.stopCode),
              position: stop.latLng,
              infoWindow: InfoWindow(title: stop.stopCode,
                  snippet: stop.address,
              ),
              onTap: () => _tapMarker(stop),
            );
          });
          setState(() {
            markers = markerMapList.toSet();
            currentPosition = p;
          });
        }
      );
    } else if (locationGot){
      setState(() {
        markers = null;
        currentPosition = p;
      });
    }
  }

  void _tapMarker(Stop stop) {
    widget.onStopTapped(stop);
  }

  void moveCameraTo(double lat, double lng) {

  }
}