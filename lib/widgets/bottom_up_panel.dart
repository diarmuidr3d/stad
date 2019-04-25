import 'package:flutter/material.dart';

import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/real_time_list.dart';
import 'package:stad/widgets/slide_open_panel.dart';

class BottomUpPanel extends StatefulWidget {
  final Stop stop;
  final PanelController panelController;
  final Function onHeightChanged;

  const BottomUpPanel({
    Key key,
    @required this.stop,
    this.panelController, this.onHeightChanged
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomUpPanelState();
}

class BottomUpPanelState extends State<BottomUpPanel> {
  RealTimeStopData stopData;
  bool loading = true;
  bool isFavourite;

  @override
  Widget build(BuildContext context) {
    if((stopData == null || widget.stop != stopData.stop) && widget.stop != null ) {
      isFavourite = false;
      loading = true;
      stopData = RealTimeStopData(stop: widget.stop);
      Favourites().isFavourite(widget.stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
      getTimings();
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
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(children: <Widget>[
                Text("  " + widget.stop.stopCode, style: Styles.routeNumberStyle,),
                Text(" - ${widget.stop.address}", style: Styles.biggerFont,),
              ],),
              Row(children: <Widget>[
                getFavIcon(),
                IconButton(icon: Icon(Icons.refresh), onPressed: getTimings,),
              ],)
        ]),
        Expanded(child: RealTimeList(loading: loading, stopData: stopData,)),
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