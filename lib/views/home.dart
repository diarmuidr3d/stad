import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/search.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/bottom_up_panel.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/nearby_stops.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/map.dart';

import '../styles.dart';

class HomeView extends StatefulWidget {
  final Stop stopToShow;

  const HomeView({this.stopToShow});

  @override
  State<StatefulWidget> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  List<String> currentFavourites;
  List searchedStops;
  Stop selectedStop;
  GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  final TextEditingController searchFieldController = TextEditingController();
  var mapCompleter = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then((favs) =>
        setState(() => currentFavourites = favs));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      drawer: FavDrawer(onStopTap: closeFavsOnSelect,),
      body: Stack(children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height,
          child: ListView(
            padding: EdgeInsets.all(0),
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * (widget.stopToShow == null ? 0.75 : 1.0 ),
                child: TransitMap(
                  controller: mapCompleter,
                  onStopTapped: viewStop,
                  interactionEnabled: true,
                  stopToShow: widget.stopToShow,
                ),
              ),
              if(widget.stopToShow == null) DragBar(),
              if(widget.stopToShow == null) Row(children: <Widget>[Spacer(), Text(Strings.nearbyStops, style: Styles.biggerFont,), Spacer(),]),
              if(widget.stopToShow == null) NearbyStops(),
            ],
          ),
        ),
        Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: SearchAppBar(
              scaffoldKey: key,
              onTapCallback: () => startSearching(context),
              searching: false,
              handleInputCallback: () {},
              textFieldController: searchFieldController,
            )
        )
      ], )
    );
  }

  void startSearching( context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchView()));
  }

  void closeFavsOnSelect(Stop stop) {
    viewStop(stop);
  }

  void viewStop(Stop stop) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StopView(stop: stop,)));
  }

}