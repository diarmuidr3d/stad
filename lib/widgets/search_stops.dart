import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/fav_drawer.dart';

class SearchStops extends StatelessWidget {
  final List stops;
  final Function stopTapCallback;

  const SearchStops({Key key, @required this.stops, @required this.stopTapCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("build search");
    return ListView.builder(
      itemCount: stops.length * 2 + 1,
      itemBuilder: (context, index) {
        if (index == 0) return ListTile();
        index--;
        if (index % 2 == 1) return Divider();
        index = index ~/ 2;
        if (stops[index] is Map) {
          return ListTile(
            leading: Text(stops[index]["stop_code"], style: Styles.routeNumberStyle,),
            title: Text(stops[index]["address"] + ", " + stops[index]["location"]),
            onTap: () => onTapSearchedItem(stops[index]),
          );}
        if (stops[index] is String) return FavListTile(stopCode: stops[index], onTap: stopTapCallback,);
      },
    );
  }

  void onTapSearchedItem(Map<String, dynamic> stopMap) {
    print(stopMap);
      var stop = Stop(
        stopCode: stopMap["stop_code"],
        latLng: LatLng(double.parse(stopMap["latitude"]),
          double.parse(stopMap["longitude"]),
        ),
        address: stopMap["address"],
      );
      RouteDB().getOperatorsForStop(stop.stopCode).then((operators) {stop.operators = operators;});
      stopTapCallback(stop);
  }
}