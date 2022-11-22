import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/favourites.dart';
import 'package:stad/utilities/map_icons.dart';

class SearchStops extends StatelessWidget {
  final List? stops;
  final Function? stopTapCallback;

  const SearchStops({
    Key? key,
    this.stops,
    this.stopTapCallback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return stops == null ?
        Container()
    :
    ListView.builder(
      itemCount: stops!.length * 2,
      itemBuilder: (context, index) {
        if (index % 2 == 1) return Divider(); // add a divider in between each item
        index = index ~/ 2;
        return StopResult(stop: stops![index], stopTapCallback: stopTapCallback,);
      },
    );
  }
}

class StopResult extends StatefulWidget {
  final stop;
  final Function? stopTapCallback;

  const StopResult({Key? key, this.stop, this.stopTapCallback}) : super(key: key);
  @override
  State<StatefulWidget> createState() => StopResultState();

}

class StopResultState extends State<StopResult> {
  late bool isFavourite;

  @override
  Widget build(BuildContext context) {
    Stop stop;
    if (widget.stop is Map) stop = Stop.fromMap(widget.stop);
    else stop = widget.stop;
    Favourites().isFavourite(stop.stopCode).then((isFav) => setState(() => isFavourite = isFav));
    return ListTile(
      leading: mapIcon(stop.operator),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if(stop.operator == Operator.DublinBus) Text(stop.stopCode, style: Styles.routeNumberStyle,),
          SizedBox(width: 5,),
          Expanded(child:Text(stop.address, overflow: TextOverflow.ellipsis, maxLines: 1,) ),
        ],),
      trailing: getFavIcon(),
      onTap: () => {
        if(widget.stopTapCallback != null) {
          widget.stopTapCallback!(stop)
        }
      },
    );
  }

  mapIcon(Operator? operator) {
    String? fileAddr = MapIcons.markerFiles[operator]?[IconType.Base];
    if(fileAddr != null) {
      return Image.asset(fileAddr);
    } else {
      return null;
    }
  }


  IconButton getFavIcon() {
    return IconButton(
        icon: isFavourite != null && isFavourite ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
        onPressed: () {
          String stopCode = widget.stop is Map ? widget.stop["stop_code"] : widget.stop.stopCode;
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