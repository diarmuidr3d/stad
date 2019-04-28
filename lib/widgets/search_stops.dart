import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/widgets/fav_drawer.dart';

class SearchStops extends StatelessWidget {
  final List stops;
  final Function stopTapCallback;

  const SearchStops({Key key, @required this.stops, @required this.stopTapCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return stops == null ?
        Container()
    :
    ListView.builder(
      itemCount: stops.length * 2 + 1,
      itemBuilder: (context, index) {
        if (index == 0) return ListTile(); // Add a tile to the start until we figure out how to make the list start after the appbar
        index--;
        if (index % 2 == 1) return Divider(); // add a divider in between each item
        index = index ~/ 2;
        return StopResult(stop: stops[index], stopTapCallback: stopTapCallback,);
      },
    );
  }
}

class StopResult extends StatefulWidget {
  final stop;
  final Function stopTapCallback;

  const StopResult({Key key, this.stop, this.stopTapCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => StopResultState();

}

class StopResultState extends State<StopResult> {
  bool isFavourite;

  @override
  Widget build(BuildContext context) {
    if (widget.stop is Map) {
      Favourites().isFavourite(widget.stop["stop_code"]).then((isFav) => setState(() => isFavourite = isFav));
      return ListTile(
        leading: Text(widget.stop["stop_code"], style: Styles.routeNumberStyle,),
        title: Text(widget.stop["address"]),
        trailing: getFavIcon(),
        onTap: () => onTapSearchedItem(widget.stop),
      );}
    if (widget.stop is String) return FavListTile(stopCode: widget.stop, onTap: widget.stopTapCallback,);
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
    widget.stopTapCallback(stop);
  }


  IconButton getFavIcon() {
    return IconButton(
        icon: isFavourite != null && isFavourite ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
        onPressed: () {
          String stopCode = widget.stop is Map ? widget.stop["stop_code"] : widget.stop;
          if (isFavourite == null || !isFavourite) {
            Favourites().addFavourite(stopCode);
            setState(() => isFavourite = true);
          } else {
            Favourites().removeFavourite(stopCode);
            setState(() => isFavourite = false);
          }
        }
    );
  }

}