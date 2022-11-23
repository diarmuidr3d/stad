import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';

enum IconType {Base, Selected}

class MapIcons {

  final _markerColours = <Operator, BitmapDescriptor>{
    Operator.DublinBus: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    Operator.IarnrodEireann: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    Operator.BusEireann: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    Operator.Luas: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
  };

  var _markerIcons = <Operator, Map<IconType, BitmapDescriptor?>>{
    Operator.DublinBus: {IconType.Base: null, IconType.Selected: null},
    Operator.IarnrodEireann: {IconType.Base: null, IconType.Selected: null},
    Operator.BusEireann: {IconType.Base: null, IconType.Selected: null},
    Operator.Luas: {IconType.Base: null, IconType.Selected: null},
  };

  static final markerFiles = <Operator, Map<IconType, String>>{
    Operator.DublinBus: {
      IconType.Base: "assets/img/dublin_bus_icon.png",
      IconType.Selected: "assets/img/dublin_bus_icon_selected.png"
    },
    Operator.IarnrodEireann: {
      IconType.Base: "assets/img/irish_rail_icon.png",
      IconType.Selected: "assets/img/irish_rail_icon_selected.png"
    },
    Operator.BusEireann: {
      IconType.Base: "assets/img/bus_eireann_icon.png",
      IconType.Selected: "assets/img/bus_eireann_icon_selected.png"
    },
    Operator.Luas: {
      IconType.Base: "assets/img/luas_icon.png",
      IconType.Selected: "assets/img/luas_icon_selected.png"
    },
  };

  // Future<Map<Operator, Map<IconType, BitmapDescriptor?>>> getMarkerIcons() async {
  //   await getMarkerIconsForOperator(Operator.BusEireann);
  //   await getMarkerIconsForOperator(Operator.DublinBus);
  //   await getMarkerIconsForOperator(Operator.Luas);
  //   await getMarkerIconsForOperator(Operator.IarnrodEireann);
  //   return _markerIcons;
  // }

  // Future<Map<IconType, BitmapDescriptor?>?> getMarkerIconsForOperator(Operator operator) async {
  //   await getMarkerIconForOperatorAndTypeAsync(operator: operator, iconType: IconType.Base);
  //   await getMarkerIconForOperatorAndTypeAsync(operator: operator, iconType: IconType.Selected);
  //   return _markerIcons[operator];
  // }

  Future<BitmapDescriptor?> getMarkerIconForOperatorAndTypeAsync({Operator? operator, IconType iconType = IconType.Base, required BuildContext context}) async {
    if(operator == null) return null;
    if (_markerIcons[operator]?[iconType] != null) return _markerIcons[operator]![iconType];
    else {
      if(markerFiles[operator]?[iconType] != null) {
        _markerIcons[operator]?[iconType] =
        await BitmapDescriptor.fromAssetImage(
            createLocalImageConfiguration(context),
            markerFiles[operator]![iconType]!);
        return _markerIcons[operator]![iconType];
      } else {
        return _markerColours[operator];
      }
    }
  }
  
  // BitmapDescriptor? getMarkerIconForOperatorAndType({Operator? operator, IconType iconType = IconType.Base, Function(BitmapDescriptor?)? callback}) {
  //   if(operator == null) return null;
  //   if(_markerIcons[operator]?[iconType] != null) return _markerIcons[operator]![iconType];
  //   else {
  //     if(callback != null) {
  //       getMarkerIconForOperatorAndTypeAsync(operator: operator, iconType: iconType).then((icon) => callback(icon));
  //     }
  //     getMarkerIconForOperatorAndTypeAsync(operator: operator, iconType: iconType); // to cache
  //     return _markerColours[operator];
  //   }
  // }
}