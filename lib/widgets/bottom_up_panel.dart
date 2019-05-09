import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/widgets/search_stops.dart';
import 'package:stad/widgets/slide_open_panel.dart';

class BottomUpPanel extends StatefulWidget {
  final PanelController panelController;
  final Function onNearbyStopSelected;

  const BottomUpPanel({
    Key key,
    this.panelController, this.onNearbyStopSelected
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
  void initState() {
    super.initState();
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
    return
      SlidingUpPanel(
        color: Colors.transparent,
        maxHeight: MediaQuery.of(context).size.height - 120,
        minHeight: 120,
        controller: widget.panelController,
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
    if (nearbyStops != null) {
      body.addAll(<Widget>[
        Row(children: <Widget>[Spacer(), Text(Strings.nearbyStops, style: Styles.biggerFont,), Spacer(),]),
        Expanded(child: SearchStops(
          stops: nearbyStops,
          stopTapCallback: widget.onNearbyStopSelected,
        )),
      ]);
    }
    return body;
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