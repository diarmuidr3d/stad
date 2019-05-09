import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/utilities/map_icons.dart';
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
      final stop = Stop.fromMap(widget.stop);
      Favourites().isFavourite(stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
      return ListTile(
        leading: Image.asset(MapIcons.markerFiles[stop.operator][IconType.Base]),
        title: Row(children: <Widget>[Text(stop.stopCode, style: Styles.routeNumberStyle,), Text(stop.address)],),
        trailing: getFavIcon(),
        onTap: () => widget.stopTapCallback(stop),
      );}
    else return FavListTile(stopCode: widget.stop, onTap: widget.stopTapCallback,); // If the stop is just a stopcode
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