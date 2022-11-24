import 'models.dart';

class Route {
  String number;
  String towards;
  String from;
  List<RouteDirection> directions;
  Route({
    required this.number,
    required this.towards,
    required this.from,
    required this.directions
  });
}

class RouteDirection {
  Route route;
  String dirName;
  String dirCode;
  List<Stop> stops = [];
  RouteDirection({
    required this.route,
    required this.dirName,
    required this.dirCode,
  });
}