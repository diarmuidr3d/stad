import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Keys {
  // WIDGETS
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  static final map = const Key('__gmap__');

  static final realTimeList = const Key('__realTimeList__');
  static final realTimeLoading = const Key('__realTimeLoading__');
  static final realTimeItem = const Key('__realTimeIteam__');

  static final searchList = const Key('__searchList__');
  static final searchField = const Key('__searchField__');

  static final finder = const Key('__finder__');
  static final finderItem = const Key('__finderItem__');


  // Preference Keys
  static final dbCopied = '__databaseCopied__';
  static final favouriteStations = '__favouriteStations__';
}