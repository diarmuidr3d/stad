class Strings {
  static const _search = {
    Lang.EN: "Search here for a stop",
    Lang.GA: "Cuardaigh stad anseo",
  };

  static const _myFavourites = {
    Lang.EN: "My Favourites",
    Lang.GA: "Mo Ceanáin",
  };

  static String get search {
    return _search[Lang.EN];
  }

  static String get myFavourites {
    return _myFavourites[Lang.EN];
  }
}

enum Lang {
  EN, GA
}