import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/keys.dart';
import 'package:stad/models/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/apis/real_time_apis.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/utilities/map_icons.dart';
import 'package:stad/views/home.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/real_time_list.dart';
import 'package:stad/widgets/search_app_bar.dart';

import '../models/trip.dart';

class TripView extends StatefulWidget {
  final Stop? stop;
  final Trip trip;

  const TripView({
    super.key,
    this.stop,
    required this.trip,
  });

  @override
  State<StatefulWidget> createState() => TripViewState();

}

class TripViewState extends State<TripView> {

  var loading = true;
  bool getTimingsScheduled = false;
  LatLng? location;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    Marker? marker = locationMarker();
    return Scaffold(
        body: Stack(children: <Widget>[
          Column(children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height,
                child: TransitMap(
                  controller: Completer(),
                  onStopTapped: onTapMap,
                  onMapTapped: onTapMap,
                  interactionEnabled: true,
                  stopToShow: widget.stop,
                  additionalMarkers: marker != null ? {marker} : {},
                ),
              ),
          ],),
        ],)
    );
  }

  Marker? locationMarker() {
    if(location != null) {
      return Marker(
        icon: MapIcons().busMarkerColour,
        markerId: MarkerId(widget.trip.id),
        position: location!,
        infoWindow: InfoWindow(title: "BUS"),
      );
    }
    return null;
  }

  void onTapMap (latLng) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeView(stopToShow: widget.stop,)));
  }

  void getLocation() async {
    if(loading != true) {
      setState(() => loading = true);
    }
    LatLng? _location = await widget.trip.currentLocation();
    if(_location != null) {
      setState(() {
        location = _location;
        loading = false;
      });
      getTimingsScheduled = false;
      autoRefresh();
    } else {
      getLocation();
    }
  }

  void autoRefresh() async {
    // if (!getTimingsScheduled) {
    //   getTimingsScheduled = true;
      Future.delayed(Duration(seconds: 10), () => getLocation());
    // }
  }
}