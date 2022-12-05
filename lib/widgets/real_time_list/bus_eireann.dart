

import 'package:flutter/material.dart';

import '../../styles.dart';
import '../../views/trip.dart';
import '../real_time_list.dart';

class BusEireannItem extends RealTimeItem {

  BusEireannItem({
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
      onTap: viewTrip,
    );
  }

  void viewTrip() {
    if(this.timing.trip != null) {
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => TripView(trip: this.timing.trip!, stop: this.stop)));
    }
  }
}