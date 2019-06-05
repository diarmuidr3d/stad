import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/utilities/location_manager.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/search.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/bottom_up_panel.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/search_stops.dart';
import 'package:stad/widgets/map.dart';

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
  var mapCompleter = Completer<GoogleMapController>();
  var nearbyStops = <Stop>[];
  final Set<Factory<OneSequenceGestureRecognizer>> mapGestureRecognizers = Set.from([
    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
    Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
    Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
    Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer())
  ]);

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then((favs) =>
        setState(() => currentFavourites = favs));
    LocationManager().getLocation().then((LatLng loc) async {
      final stops = await RouteDB().getNearbyStopsOrderedByDistance(loc);
      setState(() => nearbyStops = stops);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Keys.homeScaffoldKey,
      drawer: FavDrawer(onStopTap: closeFavsOnSelect,),
      body: Stack(children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height,
          child: ListView(
            padding: EdgeInsets.all(0),
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: TransitMap(
                  controller: mapCompleter,
                  onStopTapped: viewStop,
                  interactionEnabled: true,
                  gestureRecognizers: mapGestureRecognizers,
                ),
              ),
              DragBar(),
              Row(children: <Widget>[Spacer(), Text(Strings.nearbyStops, style: Styles.biggerFont,), Spacer(),]),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                itemCount: nearbyStops.length < 10 ? nearbyStops.length : 10,
                itemBuilder: (context, index) => StopResult(stop: nearbyStops[index], stopTapCallback: viewStop,)
              ),
            ],
          ),
        ),
        Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: SearchAppBar(
              scaffoldKey: Keys.homeScaffoldKey,
              onTapCallback: () => startSearching(context),
              searching: false,
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