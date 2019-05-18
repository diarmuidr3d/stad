import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stad/models.dart';

import 'package:location/location.dart';
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
  var currentPosition;
  LatLng userPosition;
  RouteDB db = RouteDB();
  MapIcons mapIcons;

  TransitMapState({
    this.currentPosition
  });

  @override
  void initState() {
    super.initState();
    if(widget.stopToShow == null) {
      var locationListener = Location().onLocationChanged();
      locationListener.first.then((loc) {
        print("location got");
        setState(() {
          userPosition = LatLng(loc.latitude, loc.longitude);
          currentPosition = CameraPosition(
            target: userPosition,
            zoom: 17,
          );
        });
        moveCameraTo(userPosition);
      });
      locationListener.listen((loc) {
        print("listener got location");
        userPosition = LatLng(loc.latitude, loc.longitude);
      });
    } else {
      currentPosition = CameraPosition(target: widget.stopToShow.latLng, zoom: 17,);
    }
    }

  @override
  Widget build(BuildContext context) {
    mapIcons = MapIcons(context: context);
    if (markers == null) _updateMarkers(currentPosition, context);
    return GoogleMap(
      initialCameraPosition: currentPosition,
      onMapCreated: (GoogleMapController controller) async {
        widget.controller.complete(controller);
        print("completed");
      },
      rotateGesturesEnabled: widget.interactionEnabled,
      scrollGesturesEnabled: widget.interactionEnabled,
      tiltGesturesEnabled: widget.interactionEnabled,
      zoomGesturesEnabled: widget.interactionEnabled,
      myLocationButtonEnabled: widget.interactionEnabled,
      myLocationEnabled: true,
      compassEnabled: false,
      markers: markers,
      onCameraMove: (CameraPosition p) => currentPosition = p,
      onCameraIdle: () => _updateMarkers(currentPosition, context),
      cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: TransitMap.SOUTHWEST_BOUND, northeast: TransitMap.NORTHEAST_BOUND)),
      gestureRecognizers: widget.gestureRecognizers,
    );
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
      controller.animateCamera(CameraUpdate.newCameraPosition(currentPosition));
    });
  }
}