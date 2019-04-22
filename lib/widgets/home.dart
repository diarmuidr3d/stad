import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/search_stops.dart';
import 'package:stad/widgets/slide_open_panel.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/bottom_up_panel.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  bool searching = false;
  List<String> currentFavourites;
  List searchedStops;
  Stop selectedStop;
  final TextEditingController searchFieldController = TextEditingController();
  final PanelController _panelController = PanelController();
  var mapCompleter = Completer<GoogleMapController>();
  double parallax = 0.0;

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then((favs) =>
        setState(() => currentFavourites = favs));
  }

  @override
  Widget build(BuildContext context) {
    var body = <Widget>[
      Positioned(
        top: parallax,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: TransitMap(controller: mapCompleter, onStopTapped: selectStopInSearch,),
        )
      ),
      BottomUpPanel(stop: selectedStop, panelController: _panelController, onHeightChanged: setParallax,),
    ];
    if (searching) {
      if(searchedStops == null) searchedStops = currentFavourites;
      body.add(Container(
          child: SearchStops(stops: searchedStops, stopTapCallback: selectStopInSearch,),
          decoration: BoxDecoration(color: Colors.white,)
      ));
    }
    body.add(Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: SearchAppBar(
          scaffoldKey: Keys.scaffoldKey,
          onTapCallback: startSearching,
          searching: searching,
          backCallback: clearSearch,
          handleInputCallback: searchForStopMatching,
          textFieldController: searchFieldController,
        )
    ));

    return Scaffold(
      key: Keys.scaffoldKey,
      drawer: FavDrawer(favourites: currentFavourites, onStopTap: closeFavsOnSelect,),
      body: Stack(children: body, )
    );
  }

  void setParallax(double value) {
    setState(() {
      parallax = -value * (MediaQuery.of(context).size.height - 120 - 120) * 0.5;
    });
  }

  void startSearching() => setState(() => searching = true);

  void closeFavsOnSelect(Stop stop) {
    Navigator.of(context).pop();
    selectStopInSearch(stop);
  }

  void selectStopInSearch(Stop stop) {
    clearSearchToString(stop.toString());
    moveMapCameraTo(stop.latLng.latitude, stop.latLng.longitude);
    _panelController.setPanelPosition(0.6);
    setState(() {
      selectedStop = stop;
    });
  }

  void moveMapCameraTo(double lat, double lng) {
    mapCompleter.future.then((controller){
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(lat, lng), zoom: 17)));
    });
  }

  void clearSearchToString(String string) {
    clearSearch();
    searchFieldController.text = string;
  }

  void clearSearch() { 
    setState(() {
      searching = false;
      selectedStop = null;
    });
    searchFieldController.text = "";
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  void searchForStopMatching(String string) async {
    var db = new RouteDB();
    final list = await db.getStopsMatchingParm(string);
    setState(() {
      searchedStops = list;
    });
  }
}