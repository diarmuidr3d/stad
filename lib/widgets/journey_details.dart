import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities/real_time_apis.dart';
import 'package:stad/utilities/database.dart';

class JourneyDetails extends StatefulWidget {
  final Timing timing;
  final String currentStop;
  final RouteDB db;

  JourneyDetails(this.timing, this.currentStop, this.db,)
      : super(key: Keys.finder);

  @override
  JourneyDetailsState createState() => JourneyDetailsState();
}

class JourneyDetailsState extends State<JourneyDetails> {
  List<StopVisited> stopsBefore;
  bool firstRun = true;

  @override
  Widget build(BuildContext context) {
    final timing = widget.timing;
    if (firstRun) {
      print("first run");
      firstRun = false;
      widget.db.getPreviousStops(timing.route, widget.currentStop, timing.inbound)
          .then((stops) {
        setState(() {
          stopsBefore = stops;
        });
        RealTimeUtilities().searchForBus(0, stops.length - 1, stopsBefore, widget.timing.journeyReference, _setAllInRangeToState);
      });
    }
    return stopsBefore == null
        ? Center( child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: stopsBefore.length ,
            itemBuilder: (context, i) {
              return JourneyDetailsItem(stopsBefore[i]);
            }
          );
  }



  void _setAllInRangeToState(int start, int finish, StopState state) {
    for(int i = start; i <= finish; i++) {
      setState(() {
        stopsBefore[i].state = state;
      });
    }
  }

}



class JourneyDetailsItem extends StatelessWidget {
  final StopVisited stop;

  const JourneyDetailsItem(this.stop);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: getIcon(),
      title: Text(stop.address),
      subtitle: Text(stop.stopCode),
    );
  }

  Widget getIcon() {
    switch (stop.state) {
//      case StopState.LOADING:
//        return Icon(Icons.donut_large, color: Colors.grey,);
      case StopState.LOADING:
        return CircularProgressIndicator();
      case StopState.UNVISITED:
        return Icon(Icons.remove_circle, color: Colors.grey);
      case StopState.VISITED:
        return Icon(Icons.check_circle, color: Colors.green);
      case StopState.VISITING:
        return Icon(Icons.check_circle_outline, color: Colors.lightGreen,);
      case StopState.UNKNOWN:
        return Icon(Icons.error, color: Colors.red,);
    }
  }
}