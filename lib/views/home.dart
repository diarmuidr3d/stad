import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/search.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/slide_open_panel.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/bottom_up_panel.dart';

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

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then((favs) =>
        setState(() => currentFavourites = favs));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Keys.scaffoldKey,
      drawer: FavDrawer(onStopTap: closeFavsOnSelect,),
      body: Stack(children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: TransitMap(controller: mapCompleter, onStopTapped: viewStop, interactionEnabled: true),
        ),
        BottomUpPanel(panelController: _panelController, onNearbyStopSelected: viewStop,),
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