import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:stad/models/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/apis/real_time_apis.dart';
import 'package:stad/keys.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/widgets/real_time_list/bus_eireann.dart';

import '../views/trip.dart';

class RealTimeList extends StatelessWidget {
  final RealTimeStopData? stopData;
  final bool loading;

  RealTimeList({
    this.stopData,
    required this.loading,
  }) : super(key: Keys.realTimeList);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: loading
          ? Center(child: CircularProgressIndicator())
          : stopData?.timings == null || stopData!.timings!.isEmpty
            ? Text(Strings.noResults)
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: stopData!.timings!.length,
                itemBuilder: (context, i) {
                    return RealTimeItem(
                      context: context,
                      timing: stopData!.timings![i],
                      stop: stopData!.stop,
                    );
                }
              ),
    );
  }
}

class RealTimeItem extends StatelessWidget {
  final Timing timing;
  final Stop stop;
  final BuildContext context;

  RealTimeItem({
    Key? key,
    required this.timing,
    required this.stop,
    required this.context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(stop.operator == Operator.IarnrodEireann || stop.operator == Operator.Luas) {
      return IarnrodItem(timing: timing, context: context, stop: stop);
    } else if (stop.operator == Operator.BusEireann) {
      return BusEireannItem(timing: timing, context: context, stop: stop);
    } else {
      return DublinBusItem(timing: timing, context: context, stop: stop);
    }
//    TODO: Add Bus Eireann / Luas specifics here as necessary
  }
}

class IarnrodItem extends RealTimeItem {

  IarnrodItem({
    super.key,
    required super.timing,
    required super.context,
    required super.stop
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        timing.heading,
      ),
      trailing: RealTimeMins(timing: timing,),
    );
  }
}

class DublinBusItem extends RealTimeItem {

  DublinBusItem({
    super.key,
    required super.timing,
    required super.context,
    required super.stop
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        timing.route ?? "",
        style: Styles.routeNumberStyle,
      ),
      title: Text(
        timing.heading,
      ),
      trailing: RealTimeMins(timing: timing,),
    );
  }
}

class RealTimeMins extends StatelessWidget {
  final Timing timing;

  const RealTimeMins({required this.timing});

  @override
  Widget build(BuildContext context) {
    if (timing.realTime) {
      return Row(mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.rss_feed, color: Colors.green,),
          Text("${timing.dueMins} ${Strings.shortenedMinutes}",
            style: Styles.biggerFont,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,)
        ],);
    } else {
      return Text("${timing.dueMins} ${Strings.shortenedMinutes}", style: Styles.biggerFont,);
    }
  }

}

class RealTimePage extends StatefulWidget {
  final Stop stop;

  const RealTimePage({required this.stop});

  @override
  State<StatefulWidget> createState() => RealTimePageState();
}

class RealTimePageState extends State<RealTimePage> {

  var loading = true;
  late RealTimeStopData stopData;
  var firstRun = true;
  var isFavourite;

  @override
  Widget build(BuildContext context) {
    stopData = RealTimeStopData(stop: widget.stop);
    if (firstRun) {
      firstRun = false;
      displayStopReal(widget.stop);
    }
    if(isFavourite == null) Favourites().isFavourite(stopData.stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
    return Scaffold(
      appBar: AppBar(
        title: Text('Stop ' + stopData.stop.stopCode),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.refresh), onPressed: () => {
            displayStopReal(stopData.stop)
          }),
          IconButton(
              icon: isFavourite != null && isFavourite ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
              onPressed: () {
                if (!isFavourite) {
                  Favourites().addFavourite(stopData.stop.stopCode);
                  setState(() => isFavourite = true);
                } else {
                  Favourites().removeFavourite(stopData.stop.stopCode);
                  setState(() => isFavourite = false);
                }
              }
          ),
        ],
      ),
      body: RealTimeList(loading: loading, stopData: stopData,),
    );
  }

  void displayStopReal(Stop stop) async {
    RealTimeUtilities.getStopTimings(stop).then((stopData) {
      setState(() {
        this.stopData = stopData;
        loading = false;
      });
    });
  }

}
