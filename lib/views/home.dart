import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/search.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/search_stops.dart';
import 'package:stad/widgets/slide_open_panel.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/bottom_up_panel.dart';

import '../styles.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  List<String> currentFavourites;
  List searchedStops;
  Stop selectedStop;
  final TextEditingController searchFieldController = TextEditingController();
  final PanelController _panelController = PanelController();
  var mapCompleter = Completer<GoogleMapController>();
  var nearbyStops = <Stop>[];

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then((favs) =>
        setState(() => currentFavourites = favs));
    var location = new Location();
    location.getLocation().then((loc) {
      print("nearby stops for location");
      RouteDB().getNearbyStopsOrderedByDistance(LatLng(loc.latitude, loc.longitude)).then((list) {
        setState(() => nearbyStops = list);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Keys.scaffoldKey,
      drawer: FavDrawer(onStopTap: closeFavsOnSelect,),
      body: Stack(children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height,
          child:
        ListView.builder(
          padding: EdgeInsets.only(left: 5, right: 5),
          itemCount: nearbyStops.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return Container(
              height: MediaQuery.of(context).size.height / 2,
              child: TransitMap(controller: mapCompleter, onStopTapped: viewStop, interactionEnabled: true),
            );
            else return StopResult(stop: nearbyStops[index], stopTapCallback: viewStop,);
        })),
        Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: SearchAppBar(
              scaffoldKey: Keys.scaffoldKey,
              onTapCallback: () => startSearching(context),
              searching: false,
              viewingStop: false,
              backCallback: () {},
              handleInputCallback: () {},
              textFieldController: searchFieldController,
            )
        )
      ], )
    );
  }

  void viewStop(Stop stop) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StopView(stop: stop,)));
  }

  void startSearching( context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchView()));
  }

  void closeFavsOnSelect(Stop stop) {
    viewStop(stop);
  }


}