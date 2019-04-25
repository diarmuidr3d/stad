class Strings {
  static Lang lang = Lang.EN;

  static const _search = {
    Lang.EN: "Search here for a stop",
    Lang.GA: "Cuardaigh stad anseo",
  };

  static const _myFavourites = {
    Lang.EN: "My Favourites",
    Lang.GA: "Mo Ceanáin",
  };

  static const _noResults = {
    Lang.EN: "No results found for this stop 😭",
    Lang.GA: "Níl aon torthaí don stad seo 😭",
  };

  static const _shortenedMinutes = {
    Lang.EN: "min",
    Lang.GA: "nóm",
  };

  static String get search {
    return _search[lang];
  }

  static String get myFavourites {
    return _myFavourites[lang];
  }

  static String get noResults {
    return _noResults[lang];
  }

  static String get shortenedMinutes {
    return _shortenedMinutes[lang];
  }
}

enum Lang {
  EN, GA
}