import 'package:stad/models/locatable.dart';

class Vehicle implements Locatable {
  String? id;
  GeoLocation? location;

  Vehicle({this.id, this.location});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else {
      return other is Vehicle && other.id == id;
    }
  }

  String toString() => "Vehicle: $id at $location";
}