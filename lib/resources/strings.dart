class Strings {
  static Lang lang = Lang.EN;

  static const _search = {
    Lang.EN: "Search here for a stop",
    Lang.GA: "Cuardaigh stad anseo",
  };

  static String get search => _search[lang] ?? "";

  static const _myFavourites = {
    Lang.EN: "My Favourites",
    Lang.GA: "Mo Ceanáin",
  };

  static String get myFavourites => _myFavourites[lang] ?? "";

  static const _noResults = {
    Lang.EN: "No results found for this stop 😭",
    Lang.GA: "Níl aon torthaí don stad seo 😭",
  };

  static String get noResults => _noResults[lang] ?? "";

  static const _shortenedMinutes = {
    Lang.EN: "min",
    Lang.GA: "nóm",
  };

  static String get shortenedMinutes => _shortenedMinutes[lang] ?? "";

  static const _nearbyStops = {
    Lang.EN: "Nearby Stops",
    Lang.GA: "Stadanna is gaire",
  };

  static String get nearbyStops => _nearbyStops[lang] ?? "";
}

enum Lang {
  EN, GA
}