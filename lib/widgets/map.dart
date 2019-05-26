import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities/location_manager.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/utilities/map_icons.dart';

class TransitMap extends StatefulWidget {
  static const SOUTHWEST_BOUND = LatLng(51.294321, -10.576554);
  static const NORTHEAST_BOUND = LatLng(55.402704, -5.452611);

  final Completer<GoogleMapController> controller;
  final Function onStopTapped;
  final bool interactionEnabled;
  final Stop stopToShow;

  final CameraPosition initialPosition;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  TransitMap({
    @required this.controller,
    @required this.onStopTapped,
    @required this.interactionEnabled,
    this.stopToShow,
    this.initialPosition = const CameraPosition(
      target: LatLng(53.3834, -8.2177501),
      zoom: 7,
    ),
    this.gestureRecognizers,
  }) : super(key: Keys.map);


  @override
  State<StatefulWidget> createState() {
    return TransitMapState(currentPosition: initialPosition);
  }
}

class TransitMapState extends State<TransitMap> {
  Set<Marker> markers;
  final minimumZoom = 14; // The minimum zoom level required to see markers
  CameraPosition currentPosition;
  LatLng userPosition;
  RouteDB db = RouteDB();
  MapIcons mapIcons;

  TransitMapState({
    this.currentPosition
  });

  @override
  void initState() {
    super.initState();
    /// If we're just showing the stop, we just want a static view, so don't care for user's location
    if(widget.stopToShow == null) {
      LocationManager().getLocationListener().then((locationListener){
        locationListener.first.then((loc) {
          userPosition = loc;
          currentPosition = CameraPosition(
            target: userPosition,
            zoom: 17,
          );
          moveCameraTo(userPosition);
        });
        locationListener.listen((loc) => userPosition = loc);
      });
    } else {
      currentPosition = CameraPosition(target: widget.stopToShow.latLng, zoom: 17,);
    }
    }

  @override
  Widget build(BuildContext context) {
    mapIcons = MapIcons(context: context);
    if (markers == null) _updateMarkers(currentPosition, context);
    return Stack(children: <Widget>[
      GoogleMap(
        initialCameraPosition: currentPosition,
        onMapCreated: (GoogleMapController controller) async {
          widget.controller.complete(controller);
        },
        rotateGesturesEnabled: widget.interactionEnabled,
        scrollGesturesEnabled: widget.interactionEnabled,
        tiltGesturesEnabled: widget.interactionEnabled,
        zoomGesturesEnabled: widget.interactionEnabled,
        myLocationButtonEnabled: false,
        myLocationEnabled: true,
        compassEnabled: false,
        markers: markers,
        onCameraMove: (CameraPosition p) => currentPosition = p,
        onCameraIdle: () => _updateMarkers(currentPosition, context),
        cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: TransitMap.SOUTHWEST_BOUND, northeast: TransitMap.NORTHEAST_BOUND)),
        gestureRecognizers: widget.gestureRecognizers,
      ),
      if (widget.interactionEnabled) Positioned(
        right: 10,
        bottom: 10,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(28)),
            border: Border.all(color: Colors.grey, width: 1)
          ),
          child: IconButton(
              icon: Icon(Icons.my_location),
              onPressed: () {
                print(userPosition);
                moveCameraTo(userPosition);
              }
          ),
        ),
      ),
    ],);
  }

  void _updateMarkers(CameraPosition p, BuildContext context) {
    db.getNearbyStopsIteratingRange(p.target).then((stops) {
        Iterable<Marker> markerMapList = stops.map((stop) {
          var iconType = IconType.Base;
          if (widget.stopToShow != null && stop.stopCode == widget.stopToShow.stopCode) iconType = IconType.Selected;
          return Marker(
            icon: mapIcons.getMarkerIconForOperatorAndType(stop.operator, iconType, context),
            markerId: MarkerId(stop.stopCode),
            position: stop.latLng,
            infoWindow: InfoWindow(title: stop.stopCode,
                snippet: stop.address,
            ),
            onTap: widget.interactionEnabled ?
                () => _tapMarker(stop)
                :
                null
            ,
            consumeTapEvents: !widget.interactionEnabled,
          );
        });
        setState(() {
          print("setting markers");
          markers = markerMapList.toSet();
          currentPosition = p;
        });
      }
    );
  }

  void _tapMarker(Stop stop) {
    widget.onStopTapped(stop);
  }

  void moveCameraTo(LatLng latLng) {
    widget.controller.future.then((controller) {
      print("animated camera");
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: currentPosition.zoom)));
    });
  }
}