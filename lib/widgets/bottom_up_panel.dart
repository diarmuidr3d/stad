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

  @override
  Widget build(BuildContext context) {
    if((stopData == null || widget.stop != stopData.stop) && widget.stop != null ) {
      RealTimeUtilities.getStopTimings(widget.stop).then((stopData) {
        setState(() {
          this.stopData = stopData;
          loading = false;
        });
      });
    }
    var initialHeight = 0.0;
    if(widget.stop != null) initialHeight = 0.6;
    print(initialHeight);
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
          child: Column(children: <Widget>[
            BottomPanelTopBar(),
            Expanded(child: RealTimeList(loading: loading, stopData: stopData,)),
        ])),
      );
  }

}

class BottomPanelTopBar extends StatelessWidget {
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