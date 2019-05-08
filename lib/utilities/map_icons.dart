import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';

enum IconType {Base, Selected}

class MapIcons {

  BuildContext context;

  MapIcons({@required this.context}) {
    getMarkerIcons(this.context);
  }

  final _markerColours = <Operator, BitmapDescriptor>{
    Operator.DublinBus: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    Operator.IarnrodEireann: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    Operator.BusEireann: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    Operator.Luas: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
  };

  var _markerIcons = <Operator, Map<IconType, BitmapDescriptor>>{
    Operator.DublinBus: {IconType.Base: null, IconType.Selected: null},
    Operator.IarnrodEireann: {IconType.Base: null, IconType.Selected: null},
    Operator.BusEireann: {IconType.Base: null, IconType.Selected: null},
    Operator.Luas: {IconType.Base: null, IconType.Selected: null},
  };

  var _markerFiles = <Operator, Map<IconType, String>>{
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

  Future<Map<Operator, Map<IconType, BitmapDescriptor>>> getMarkerIcons(BuildContext context) async {
    await getMarkerIconsForOperator(context, Operator.BusEireann);
    await getMarkerIconsForOperator(context, Operator.DublinBus);
    await getMarkerIconsForOperator(context, Operator.Luas);
    await getMarkerIconsForOperator(context, Operator.IarnrodEireann);
    return _markerIcons;
  }

  Future<Map<IconType, BitmapDescriptor>> getMarkerIconsForOperator(BuildContext context, Operator operator) async {
    await getMarkerIconForOperatorAndTypeAsync(context, operator, IconType.Base);
    await getMarkerIconForOperatorAndTypeAsync(context, operator, IconType.Selected);
    return _markerIcons[operator];
  }

  Future<BitmapDescriptor> getMarkerIconForOperatorAndTypeAsync(BuildContext context, Operator operator, IconType iconType) async {
    if (_markerIcons[operator][iconType] != null) return _markerIcons[operator][iconType];
    else {
      _markerIcons[operator][iconType] = await BitmapDescriptor.fromAssetImage(createLocalImageConfiguration(context), _markerFiles[operator][iconType]);
      return _markerIcons[operator][iconType];
    }
  }
  
  BitmapDescriptor getMarkerIconForOperatorAndType(Operator operator, IconType iconType, BuildContext context, {Function callback}) {
    if(_markerIcons[operator][iconType] != null) return _markerIcons[operator][iconType];
    else {
      if(callback != null) getMarkerIconForOperatorAndTypeAsync(context, operator, iconType).then((icon) => callback(icon));
      else getMarkerIconForOperatorAndTypeAsync(context, operator, iconType);
      return _markerColours[operator];
    }
  }
}