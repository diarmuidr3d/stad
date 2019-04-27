import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/utilities/database.dart';

class FavDrawer extends StatefulWidget {
  final onStopTap;

  FavDrawer({this.onStopTap});

  @override
  State<StatefulWidget> createState() => FavDrawerState();
}

class FavDrawerState extends State<FavDrawer> {
  List<String> favourites;

  @override
  void initState() {
    super.initState();
    Favourites().getFavourites().then(_setFavs);
    Favourites().favouriteUpDateListeners.add(_setFavs);
  }

  @override
  Widget build(BuildContext context) {
    var child;
    if(favourites == null) child = Center( child: CircularProgressIndicator());
    else child = ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: favourites.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) return ListTile(title: Text(Strings.myFavourites, style: Styles.biggerFont,),);
          else if (i == 1) return Divider();
          else {
            i = i-2;
            return FavListTile(stopCode: favourites[i], onTap: widget.onStopTap);
          }
        },);
    return Drawer(child: child);
  }

  void _setFavs(favs) => setState(() => favourites = favs);

}

class FavListTile extends StatefulWidget {

  final String stopCode;
  final Function onTap;

  const FavListTile({@required this.stopCode, this.onTap});

  @override
  State<StatefulWidget> createState() => FavListTileState();

}

class FavListTileState extends State<FavListTile> {

  Future<Stop> stopFuture;
  Stop stop;
  bool isFavourite = true;

  @override
  Widget build(BuildContext context) {
    if (stopFuture == null) {
      stopFuture = RouteDB().getStopWithStopCode(widget.stopCode).then((stop) {
        setState(() {
          this.stop = stop;
        });
      });
    }
    if(stop == null) {
      return ListTile(
        leading: Text(widget.stopCode, style: Styles.routeNumberStyle,),
        onTap: () async => stopFuture.then((stop) => widget.onTap(stop)),
        trailing: getFavIcon(),
      );
    } else {
      return ListTile(
        leading: Text(stop.stopCode, style: Styles.routeNumberStyle,),
        title: Text(stop.address),
        trailing: getFavIcon(),
        onTap: () => widget.onTap(stop),
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