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
  static const DEFAULT_CENTRE = LatLng(53.3834, -8.2177501);

  final Completer<GoogleMapController> controller;
  final Function onStopTapped;
  final ArgumentCallback<LatLng>? onMapTapped;
  final bool interactionEnabled;
  final Stop? stopToShow;

  final CameraPosition initialPosition;

  /// Builds a Google Map
  /// [onMapTapped] is only used if [interactionEnabled] is set to false.
  TransitMap({
    required this.controller,
    required this.onStopTapped,
    required this.interactionEnabled,
    this.onMapTapped,
    this.stopToShow,
    this.initialPosition = const CameraPosition(
      target: DEFAULT_CENTRE,
      zoom: 7,
    ),
  }) : super(key: Keys.map);


  @override
  State<StatefulWidget> createState() {
    return TransitMapState(currentPosition: initialPosition);
  }
}

class TransitMapState extends State<TransitMap> {
  Set<Marker> markers = {};
  final minimumZoom = 14; // The minimum zoom level required to see markers
  CameraPosition currentPosition;
  LatLng? userPosition;
  RouteDB db = RouteDB();
  late MapIcons mapIcons;

  TransitMapState({
    required this.currentPosition
  }) {
    mapIcons = MapIcons(context: context);
  }

  @override
  void initState() {
    super.initState();
    /// If we're just showing the stop, we just want a static view, so don't care for user's location
    if(widget.stopToShow != null) currentPosition = CameraPosition(target: widget.stopToShow!.latLng, zoom: 17,);
    if(widget.interactionEnabled) setupLocation();
  }

  /// Gets the user's location and moves the camera to that position.
  /// If there's a value in [widget.stopToShow], it moves the camera to that position instead.
  setupLocation() async {
    final locationManager = LocationManager();
    if(widget.stopToShow != null ) {
      setCurrentPositionAndMoveCamera(userPosition);
    } else {
      print("setting up location");
      userPosition = await locationManager.getLocation();
      print("user is at $userPosition");
      if(userPosition != null) {
        setCurrentPositionAndMoveCamera(userPosition);
      }
    }
    final listener = await locationManager.getLocationListener();
    listener?.listen((loc) {
      userPosition = loc;
      print("userpos: $userPosition");
    });
  }

  setCurrentPositionAndMoveCamera(LatLng? latLng) {
    if(latLng != null) {
      currentPosition = CameraPosition(target: latLng, zoom: 17,);
      moveCameraToPosition(currentPosition);
    }
  }

  mapGestureRecognizers() {
    return {
      Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
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
        myLocationButtonEnabled: widget.stopToShow != null && widget.interactionEnabled,
        zoomControlsEnabled: false,
        myLocationEnabled: true,
        compassEnabled: false,
        markers: markers,
        onCameraMove: (CameraPosition p) => currentPosition = p,
        onCameraIdle: () => _updateMarkers(currentPosition, context),
        cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: TransitMap.SOUTHWEST_BOUND, northeast: TransitMap.NORTHEAST_BOUND)),
        gestureRecognizers: widget.interactionEnabled ? mapGestureRecognizers() : {},
        onTap: widget.interactionEnabled ? (latLng) {} : widget.onMapTapped,
      ),
      if (widget.interactionEnabled && widget.stopToShow == null) Positioned(
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
                setCurrentPositionAndMoveCamera(userPosition);
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
          if (widget.stopToShow != null && stop.stopCode == widget.stopToShow!.stopCode) iconType = IconType.Selected;
          var icon = mapIcons.getMarkerIconForOperatorAndType(operator: stop.operator, iconType: iconType);
          if(icon != null) {
            return Marker(
              icon: icon,
              markerId: MarkerId(stop.stopCode),
              position: stop.latLng,
              infoWindow: InfoWindow(title: stop.stopCode,
                snippet: stop.address,
              ),
              onTap: () => _tapMarker(stop),
              consumeTapEvents: !widget.interactionEnabled,
            );
          } else {
            return Marker(
              markerId: MarkerId(stop.stopCode),
              position: stop.latLng,
              infoWindow: InfoWindow(title: stop.stopCode,
                snippet: stop.address,
              ),
              onTap: () => _tapMarker(stop),
              consumeTapEvents: !widget.interactionEnabled,
            );
          }
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

  void moveCameraToLatLng(LatLng latLng) {
      moveCameraToPosition(CameraPosition(target: latLng, zoom: currentPosition.zoom));
  }

  void moveCameraToPosition(CameraPosition position) {
    widget.controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newCameraPosition(position));
    });
  }
}