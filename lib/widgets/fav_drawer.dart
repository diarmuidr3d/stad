import 'package:flutter/material.dart';
import 'package:stad/models/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/utilities/favourites.dart';

class FavDrawer extends StatefulWidget {
  final onStopTap;

  FavDrawer({this.onStopTap});

  @override
  State<StatefulWidget> createState() => FavDrawerState();
}

class FavDrawerState extends State<FavDrawer> {
  List<String> favourites = [];
  var loading = true;

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then(_setFavs);
    Favourites().favouriteUpDateListeners.add(_setFavs);
  }

  @override
  Widget build(BuildContext context) {
    var child;
    if(loading == true) child = Center( child: CircularProgressIndicator());
    else child = ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        ListTile(title: Text(Strings.myFavourites, style: Styles.biggerFont,),),
        Divider(),
        if (favourites == null) ListTile(title: Text("Add a favourite to see it listed here")),
        if (favourites != null)
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.all(0),
            itemCount: favourites.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              return FavListTile(stopCode: favourites[i], onTap: widget.onStopTap);
            },
          ),
      ],
    );
    return Drawer(child: child);
  }

  void _setFavs(favs) {
    setState(() {
      loading = false;
      favourites = favs;
    });
  }

}

class FavListTile extends StatefulWidget {

  final String stopCode;
  final Function? onTap;

  const FavListTile({
    required this.stopCode,
    this.onTap
  });

  @override
  State<StatefulWidget> createState() => FavListTileState();

}

class FavListTileState extends State<FavListTile> {

  Future<Stop>? stopFuture;
  Stop? stop;
  bool isFavourite = true;

  @override
  Widget build(BuildContext context) {
    if (stopFuture == null) {
      stopFuture = RouteDB().getStopWithStopCode(widget.stopCode);
      stopFuture!.then((stop) {
        setState(() {
          this.stop = stop;
        });
      });
    }
    if(stop == null) {
      return ListTile(
        leading: Text(widget.stopCode, style: Styles.routeNumberStyle,),
        onTap: widget.onTap != null ? () async => stopFuture?.then((stop) => widget.onTap!(stop)) : null,
        trailing: getFavIcon(),
      );
    } else {
      final leading = stop!.operator == Operator.DublinBus ?
          Text(stop!.stopCode, style: Styles.routeNumberStyle,) : null;
      return ListTile(
        leading: leading,
        title: Text(stop!.address),
        trailing: getFavIcon(),
        onTap: widget.onTap != null ?  () => widget.onTap!(stop) : null,
      );
    }
  }

  IconButton getFavIcon() {
    return IconButton(
        icon: isFavourite ? Icon(Icons.favorite, color: Colors.red,) : Icon(Icons.favorite_border,),
        onPressed: () {
          if (!isFavourite) {
            Favourites().addFavourite(widget.stopCode);
            setState(() => isFavourite = true);
          } else {
            Favourites().removeFavourite(widget.stopCode);
            setState(() => isFavourite = false);
          }
        }
    );
  }
}