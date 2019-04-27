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
    Operator.IarnrodEireann: BitmapDescriptor.hueGreen
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

  void _updateMarkers(CameraPosition p) async {
    if (p.zoom > minimumZoom) {
      db.getNearbyStops(p.target).then(
        (list) {
          var markerStopsByCode = <String,Stop>{};
          var markerMapList = list.map((stopMap) {
            if(markerStopsByCode[stopMap["stop_code"]] == null) {
              final loc = LatLng(double.parse(stopMap["latitude"]),
                  double.parse(stopMap["longitude"]));
              final stop = Stop(stopCode: stopMap["stop_code"],
                address: stopMap["address"],
                latLng: loc,
                operators: [ operators[stopMap["operator"]], ]
              );
              markerStopsByCode.addAll({stop.stopCode: stop});
              return Marker(
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    markerColours[operators[stopMap["operator"]]]),
                markerId: MarkerId(stopMap["stop_code"]),
                position: loc,
                infoWindow: InfoWindow(title: stopMap["stop_code"],
                    snippet: stopMap["address"],
                ),
                onTap: () => _tapMarker(stop),
              );
            } else {
              markerStopsByCode[stopMap["stop_code"]].operators.add(stopMap["operator"]);
            }
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