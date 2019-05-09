import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/real_time_apis.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/views/search.dart';
import 'package:stad/widgets/map.dart';
import 'package:stad/widgets/real_time_list.dart';
import 'package:stad/widgets/search_app_bar.dart';

class StopView extends StatefulWidget {
  final Stop stop;

  const StopView({
    Key key,
    @required this.stop
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StopViewState();

}

class StopViewState extends State<StopView> {

  var loading = true;
  var stopData = RealTimeStopData();
  final textController = TextEditingController();
  bool isFavourite;


  @override
  void initState() {
    super.initState();
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
                onStopTapped: () {},
                interactionEnabled: false,
                stopToShow: widget.stop,
              )
            ),
            Row(children: <Widget>[
              SizedBox(width: 10.0,),
              Text(widget.stop.stopCode, style: Styles.routeNumberStyle,),
              Expanded(child:
                Text(" - ${widget.stop.address}", style: Styles.biggerFont, overflow: TextOverflow.ellipsis, maxLines: 1,),
              ),
              IconButton(icon: Icon(Icons.refresh), onPressed: () => getTimings(widget.stop),),
              getFavIcon(),
            ]),
            Divider(),
            Expanded(child:
              RealTimeList(
                stopData: stopData,
                loading: loading,
              )
            )
          ],),
          Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              child: SearchAppBar(
                scaffoldKey: Keys.scaffoldKey,
                onTapCallback: () => startSearching(context),
                searching: false,
                viewingStop: true,
                backCallback: () {Navigator.pop(context);},
                handleInputCallback: () {},
                textFieldController: textController,
              )
          )
        ],)
    );
  }

  void startSearching(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchView()));
  }

  void getTimings(Stop stop) async {
    RealTimeUtilities.getStopTimings(stop).then((stopData) {
      setState(() {
        print(stopData);
        this.stopData = stopData;
        loading = false;
      });
    });
  }

  IconButton getFavIcon() {
    return IconButton(
        icon: isFavourite != null && isFavourite ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
        onPressed: () {
          if (isFavourite == null || !isFavourite) {
            Favourites().addFavourite(stopData.stop.stopCode);
            setState(() => isFavourite = true);
          } else {
            Favourites().removeFavourite(stopData.stop.stopCode);
            setState(() => isFavourite = false);
          }
        }
    );
  }

}