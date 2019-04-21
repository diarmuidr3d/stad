import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:floating_search_bar/floating_search_bar.dart';

import 'package:stad/keys.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/fav_drawer.dart';
import 'package:stad/widgets/real_time_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Time Info',
      home: RealTime(),
//      home: FloatingSearchBar.builder(
//          itemCount: 100,
//          itemBuilder: (BuildContext context, int index) {
//            return ListTile(
//              leading: Text(index.toString()),
//            );
//          },
//          trailing: CircleAvatar(
//            child: Text("RD"),
//          ),
//          drawer: Drawer(
//            child: Container(),
//          ),
//        ),
      theme: new ThemeData(
        primaryColor: Styles.appPurple,
      ),
    );
  }
}

class RealTimeState extends State<RealTime> {
//  final _saved = new Set<WordPair>();

  var stopData = RealTimeStopData();
  var loading = false;
  var listHidden = true;
  List<String> currentFavourites;
  var loadingFavourites = false;
  Completer<GoogleMapController> gmapController = Completer();

  @override
  Widget build(BuildContext context) {
    if(!loadingFavourites) {
      loadingFavourites = true;
      Favourites().getFavourites().then((favs) =>
          setState(() => currentFavourites = favs));
    }
    return Scaffold(
      key: Keys.scaffoldKey,
      appBar: AppBar(
        title: Text('Real Time Info'),
      ),
      drawer: FavDrawer(favourites: currentFavourites, onStopTap: displayStopRealWithMapMove,),
      body: _buildMain(),
    );
  }

  void displayStopReal(Stop stop) async {
    setState(() {
      stopData.stop = stop;
      listHidden = false;
      loading = true;
    });
    getTimingsAndUpdateUI(stop);
  }

  void getTimingsAndUpdateUI(Stop stop) {
    RealTimeUtilities.getStopTimings(stop).then((stopData) {
      setState(() {
        this.stopData = stopData;
        loading = false;
        listHidden = false;
      });
    });
  }

  void displayStopRealWithMapMove(Stop stop) async {
    gmapController.future.then((controller){
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(stop.latLng.latitude, stop.latLng.longitude), zoom: 17)));
    });
    displayStopReal(stop);
  }

  Widget _buildMain() {
//  List<Widget> _buildMain() {
//    final bool alreadySaved = _saved.contains(timing);
    var widgets = <Widget>[
//      Row(children: <Widget>[
//        new Expanded(child: SearchField(displayStopRealWithMapMove)),
//        Expanded(child: FloatingSearchBar(
//          drawer: FavDrawer(favourites: currentFavourites, onStopTap: displayStopRealWithMapMove,),
//          children: <Widget>[Flex(direction: Axis.vertical, children: <Widget>[Expanded(child: TransitMap(displayStop: displayStopReal, controller: gmapController,))],),],
//        )),
//      ]),
//      Expanded(
//        child:
      TransitMap(onStopTapped: displayStopReal, controller: gmapController,)
//      ),
    ];
    if (!listHidden) {
      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
              child: Text("Route",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              margin: EdgeInsets.only(left: 18.0, top: 18.0)),
          Center(child: Row(children: [
            currentFavourites != null && currentFavourites.contains(stopData.stop.stopCode) ?
            IconButton(
                icon: Icon(Icons.favorite, color: Colors.red,),
                onPressed: () => Favourites().removeFavourite(stopData.stop.stopCode).then((favs) => setState(() => currentFavourites = favs))
            ) :
            IconButton(
                icon: Icon(Icons.favorite_border,),
                onPressed: () => Favourites().addFavourite(stopData.stop.stopCode).then((favs) => setState(() => currentFavourites = favs))
            ),
            IconButton(icon: Icon(Icons.refresh), onPressed: () => {
            getTimingsAndUpdateUI(stopData.stop)
            }),
            IconButton(icon: Icon(Icons.arrow_upward), onPressed: () {
              setState(() => listHidden = true);
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return RealTimePage(stop: stopData.stop);
                  }));
            }),
            IconButton(icon: Icon(Icons.close), onPressed: () => setState(() => listHidden = true)),
          ]),),
          Align(
            alignment: Alignment.topRight,
            child: Container(
                child: Text("Mins",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                margin: EdgeInsets.only(right: 18.0, top: 18.0)),
          )
        ],
      ));
      widgets.add(Expanded(
          child: RealTimeList(
            stopData: stopData,
            loading: loading,
          )));
    }
    return Column(children: widgets);
//    return widgets;
  }
}

class RealTime extends StatefulWidget {
  @override
  RealTimeState createState() => new RealTimeState();
}

