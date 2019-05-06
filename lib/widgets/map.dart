import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stad/models.dart';

import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/utilities/database.dart';

class TransitMap extends StatefulWidget {
  static const SOUTHWEST_BOUND = LatLng(51.294321, -10.576554);
  static const NORTHEAST_BOUND = LatLng(55.402704, -5.452611);

  final Completer<GoogleMapController> controller;
  final Function onStopTapped;
  final bool interactionEnabled;

  final CameraPosition initialPosition;

  TransitMap({
    @required this.controller,
    @required this.onStopTapped,
    @required this.interactionEnabled,
    this.initialPosition = const CameraPosition(
      target: LatLng(53.3834, -8.2177501),
      zoom: 7,
    ),
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
  RouteDB db = new RouteDB();
  final markerColours = {
    Operator.DublinBus: BitmapDescriptor.hueYellow,
    Operator.IarnrodEireann: BitmapDescriptor.hueGreen,
    Operator.BusEireann: BitmapDescriptor.hueRed,
    Operator.Luas: BitmapDescriptor.hueMagenta,
  };
  var markerIcons = <Operator, BitmapDescriptor>{
    Operator.DublinBus: null,
    Operator.IarnrodEireann: null,
    Operator.BusEireann: null,
    Operator.Luas: null,
  };

  TransitMapState({
    this.currentPosition
  });

  @override
  void initState() {
    super.initState();
    print("get location");
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
    }

  @override
  Widget build(BuildContext context) {
    getMarkerIcons(context);
    if (markers == null) _updateMarkers(currentPosition);
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
      onCameraIdle: () => _updateMarkers(currentPosition),
      cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: TransitMap.SOUTHWEST_BOUND, northeast: TransitMap.NORTHEAST_BOUND)),
    );
  }

  DateTime getNearbyStopsLastCalled;

  void _updateMarkers(CameraPosition p) {
    getNearbyStopsLastCalled = DateTime.now();
    db.getNearbyStops(p.target).then((stops) {
        Iterable<Marker> markerMapList = stops.map((stop) {
          return Marker(
            icon: markerIcons[stop.operator] != null ?
              markerIcons[stop.operator]
              :
              BitmapDescriptor.defaultMarkerWithHue(
                markerColours[stop.operator]),
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

  void getMarkerIcons(BuildContext context) {
    if (markerIcons[Operator.DublinBus] == null) {
      BitmapDescriptor.fromAssetImage(
          createLocalImageConfiguration(context), "assets/img/DublinBusLogo.png")
          .then((icon) {setState(() => markerIcons[Operator.DublinBus] = icon);});
    }
    if (markerIcons[Operator.IarnrodEireann] == null) {
      BitmapDescriptor.fromAssetImage(
          createLocalImageConfiguration(context), "assets/img/irish_rail_icon.png")
          .then((icon) {setState(() => markerIcons[Operator.IarnrodEireann] = icon);});
    }
    if (markerIcons[Operator.Luas] == null) {
      BitmapDescriptor.fromAssetImage(
          createLocalImageConfiguration(context), "assets/img/luas_icon.png")
          .then((icon) {setState(() => markerIcons[Operator.Luas] = icon);});
    }
    if (markerIcons[Operator.BusEireann] == null) {
      BitmapDescriptor.fromAssetImage(
          createLocalImageConfiguration(context), "assets/img/bus_eireann_icon.png")
          .then((icon) {setState(() => markerIcons[Operator.BusEireann] = icon);});
    }
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