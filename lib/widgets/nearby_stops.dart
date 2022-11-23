import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/utilities/location_manager.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/search_stops.dart';

class NearbyStops extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NearbyStopsState();

}

class NearbyStopsState extends State<NearbyStops> {

  List<Stop> nearbyStops = [];

  @override
  void initState() {
    super.initState();
    LocationManager().getLocationListener().then((locationListener){
      locationListener?.first.then((loc) async {
        if(loc != null) {
          final stops = await RouteDB().getNearbyStopsOrderedByDistance(loc);
          setState(() => nearbyStops = stops);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (nearbyStops.isNotEmpty) return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        itemCount: nearbyStops.length < 10 ? nearbyStops.length : 10,
        itemBuilder: (context, index) => StopResult(stop: nearbyStops[index], stopTapCallback: viewStop,)
    );
    else return Text("No nearby stops found or we are waiting for your location");
  }

  void viewStop(Stop stop) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => StopView(stop: stop,)));
  }

}