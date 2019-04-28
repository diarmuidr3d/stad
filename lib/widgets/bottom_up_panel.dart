import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/widgets/real_time_list.dart';
import 'package:stad/widgets/slide_open_panel.dart';

class BottomUpPanel extends StatefulWidget {
  final Stop stop;
  final PanelController panelController;
  final Function onHeightChanged;
  final Function onNearbyStopSelected;

  const BottomUpPanel({
    Key key,
    @required this.stop,
    this.panelController, this.onHeightChanged, this.onNearbyStopSelected
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomUpPanelState();
}

class BottomUpPanelState extends State<BottomUpPanel> {
  RealTimeStopData stopData;
  bool loading = true;
  bool isFavourite;
  List<Stop> nearbyStops;

  @override
  Widget build(BuildContext context) {
    if((stopData == null || widget.stop != stopData.stop) && widget.stop != null ) {
      isFavourite = false;
      loading = true;
      stopData = RealTimeStopData(stop: widget.stop);
      Favourites().isFavourite(widget.stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
      getTimings();
    } else if (widget.stop == null) {
      var location = new Location();
      location.getLocation().then((loc) {
        RouteDB().getNearbyStopsOrderedByDistance(LatLng(loc.latitude, loc.longitude)).then((list) {
          print(list);
          setState(() => nearbyStops = list);
        });
      });
    }
    var initialHeight = 0.0;
    if(widget.stop != null) initialHeight = 0.6;
    return
      SlidingUpPanel(
        color: Colors.transparent,
        maxHeight: MediaQuery.of(context).size.height - 120,
        minHeight: 120,
        initialHeight: initialHeight,
        parallaxEnabled: true,
        parallaxOffset: 0.5,
        controller: widget.panelController,
        onHeightChanged: widget.onHeightChanged,
        panel: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Styles.appPurple),
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0), ),
          ),
          child: Column(children: getBody())),
      );
  }

  List<Widget> getBody() {
    var body = <Widget>[DragBar()];
    if(widget.stop != null) {
      body.addAll(<Widget>[
        Row(children: <Widget>[
          SizedBox(width: 10.0,),
          Text(widget.stop.stopCode, style: Styles.routeNumberStyle,),
          Expanded(child:
            Text(" - ${widget.stop.address}", style: Styles.biggerFont, overflow: TextOverflow.ellipsis, maxLines: 1,),
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: getTimings,),
          getFavIcon(),
        ]),
        Expanded(child: RealTimeList(loading: loading, stopData: stopData,)),
      ]);
    } else if (nearbyStops != null) {
      body.addAll(<Widget>[
        Row(children: <Widget>[Spacer(), Text(Strings.nearbyStops, style: Styles.biggerFont,), Spacer(),]),
        Expanded(child: ListView.builder(
          itemCount: nearbyStops.length,
          itemBuilder: (context, i) {
            return ListTile(
              leading: Text(nearbyStops[i].stopCode, style: Styles.routeNumberStyle,),
              title: Text(nearbyStops[i].address),
              onTap: () => widget.onNearbyStopSelected(nearbyStops[i]),
            );
          },
        )),
      ]);
    }
    return body;
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

  void getTimings() {
    RealTimeUtilities.getStopTimings(widget.stop).then((stopData) {
      setState(() {
        this.stopData = stopData;
        loading = false;
      });
//      Timer(Duration(seconds: 30), getTimings);
    });
  }

}

class DragBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 12.0,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                  color: Styles.appPurple,
                  borderRadius: BorderRadius.all(Radius.circular(12.0))
              ),
            ),
          ],
        ),
        SizedBox(height: 12.0,),
      ],
    );
  }

}