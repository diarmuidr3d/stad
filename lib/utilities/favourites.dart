import 'package:shared_preferences/shared_preferences.dart';
import 'package:stad/keys.dart';

class Favourites {

  static final Favourites _singleton = Favourites._internal();
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  List<Function> favouriteUpDateListeners = [];


  factory Favourites() {
    return _singleton;
  }

  Favourites._internal();


  Future<List<String>?> getFavourites() async {
    var myPrefs = await prefs;
    return myPrefs.getStringList(Keys.favouriteStations);
  }

  Future<List<String>> addFavourite(String stopCode) async {
    var myPrefs = await prefs;
    var currentFavs = await getFavourites();
    if (currentFavs != null) {
      if (!currentFavs.contains(stopCode)) {
        currentFavs.add(stopCode);
      }
    } else {
      currentFavs = [stopCode];
    }
    myPrefs.setStringList(Keys.favouriteStations, currentFavs);
    _updateListeners(currentFavs);
    return currentFavs;
  }

  Future<List<String>?> removeFavourite(String stopCode) async {
    var myPrefs = await prefs;
    var currentFavs = await getFavourites();
    if (currentFavs != null) {
      currentFavs.remove(stopCode);
      myPrefs.setStringList(Keys.favouriteStations, currentFavs);
      _updateListeners(currentFavs);
    }
    return currentFavs;
  }

  Future<bool> isFavourite(String stopCode) async {
    var currentFavs = await getFavourites();
    return currentFavs != null && currentFavs.contains(stopCode);
  }

  void _updateListeners(currentFavs) {
    for (var listener in favouriteUpDateListeners) listener(currentFavs);
  }
}