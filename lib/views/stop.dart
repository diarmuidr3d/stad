import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/real_time_apis.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/home.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/real_time_list.dart';
import 'package:stad/widgets/search_app_bar.dart';

class StopView extends StatefulWidget {
  final Stop stop;

  const StopView({
    Key? key,
    required this.stop
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StopViewState();

}

class StopViewState extends State<StopView> {

  var loading = true;
  RealTimeStopData? stopData;
  final textController = TextEditingController();
  bool? isFavourite;
  bool getTimingsScheduled = false;


  @override
  void initState() {
    super.initState();
    stopData = RealTimeStopData(stop: widget.stop);
    getTimings(widget.stop);
    Favourites().isFavourite(widget.stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
  }

  @override
  Widget build(BuildContext context) {
    textController.value = TextEditingValue(text: "${widget.stop}");
    return Scaffold(
        body: Stack(children: <Widget>[
          Column(children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                child: TransitMap(
                  controller: Completer(),
                  onStopTapped: onTapMap,
                  onMapTapped: onTapMap,
                  interactionEnabled: false,
                  stopToShow: widget.stop,
                ),
              ),
            Row(children: <Widget>[
              SizedBox(width: 10.0,),
              Text(widget.stop.stopCode, style: Styles.routeNumberStyle,),
              Expanded(child:
                Text(" - ${widget.stop.address}", style: Styles.biggerFont, overflow: TextOverflow.ellipsis, maxLines: 1,),
              ),
              if(loading) CircularProgressIndicator()
              else IconButton(icon: Icon(Icons.refresh), onPressed: () => getTimings(widget.stop),),
              getFavIcon(),
            ]),
            Divider(),
            Expanded(child:
              RealTimeList(
                stopData: stopData!,
                loading: loading,
              )
            )
          ],),
          Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: SearchAppBar(
                scaffoldKey: Keys.viewStopScaffoldKey,
                onTapCallback: () => startSearching(context),
                searching: false,
                textFieldController: textController,
              )
          )
        ],)
    );
  }

  void onTapMap (latLng) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeView(stopToShow: widget.stop,)));
  }

  void startSearching(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void getTimings(Stop stop) async {
    setState(() => loading = true);
    RealTimeUtilities.getStopTimings(stop).then((stopData) {
      setState(() {
        this.stopData = stopData;
        loading = false;
      });
      getTimingsScheduled = false;
      autoRefresh(stop);
    });
  }

  void autoRefresh(Stop stop) async {
    if (!getTimingsScheduled) {
      getTimingsScheduled = true;
      Future.delayed(Duration(seconds: 30), () => getTimings(stop));
    }
  }

  IconButton getFavIcon() {
    return IconButton(
        icon: isFavourite != null && isFavourite! ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
        onPressed: () {
          if (isFavourite == null || !isFavourite!) {
            Favourites().addFavourite(stopData!.stop.stopCode);
            setState(() => isFavourite = true);
          } else {
            Favourites().removeFavourite(stopData!.stop.stopCode);
            setState(() => isFavourite = false);
          }
        }
    );
  }
}