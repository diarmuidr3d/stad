import 'package:flutter/material.dart';
import 'package:stad/models.dart';
import 'package:stad/resources/strings.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/real_time_list.dart';

class FavDrawer extends StatelessWidget {
  final favourites;
  final onStopTap;

  FavDrawer({this.favourites, this.onStopTap});

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
            return FavListTile(stopCode: favourites[i], onTap: onStopTap);
          }
        },);
    return Drawer(child: child);
  }

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
        onTap: () async => stopFuture.then((stop) {widget.onTap(stop);}),
      );
    } else {
      return ListTile(
        leading: Text(stop.stopCode, style: Styles.routeNumberStyle,),
        title: Text(stop.address),
        onTap: () {  widget.onTap(stop); },
//        onTap: () {  _openRealTime(stop); },
      );
    }
  }

  void _openRealTime(Stop stop) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return RealTimePage(stop: stop,);
        },
      ),
    );
  }
}