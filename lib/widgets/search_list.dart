import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';

class SearchList extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final stopTapCallback;

  SearchList({
    @required this.searchResults,
    @required this.stopTapCallback,
  }) : super(key: Keys.searchList);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: searchResults.length * 2 - 1,
          shrinkWrap: true,
          itemBuilder: (context, i) {
            if (i.isOdd) return Divider();
            final index = i ~/ 2;
            if (searchResults.isNotEmpty &&
                !(index >= searchResults.length)) {
              var thisResult = searchResults[index];
              return ListTile(
                leading: Text(
                  thisResult["stop_code"],
                  style: Styles.routeNumberStyle,
                ),
                title: Text(
                    thisResult["location"] + ", " + thisResult["address"],
                ),
                onTap: () {
                  var stop = Stop(
                    stopCode: thisResult["stop_code"],
                    latLng: LatLng(double.parse(thisResult["latitude"]),
                      double.parse(thisResult["longitude"]),
                    ),
                    address: thisResult["address"],
                  );
                  RouteDB().getOperatorsForStop(thisResult["stop_code"]).then((operators) {stop.operators = operators;});
                  stopTapCallback(stop);
                },
              );
            }
          }),
    );
  }
}