import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/models.dart';
import 'package:stad/styles.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/search_list.dart';

class SearchField extends StatefulWidget {
  final stopTapCallback;

  SearchField(this.stopTapCallback) : super(key: Keys.searchField);

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {

  OverlayEntry _overlayEntry;

  void _createOverlayEntry(String searchString) async {
    if(this._overlayEntry != null) {
      this._overlayEntry.remove();
    }
    if (searchString != "") {
      RenderBox renderBox = context.findRenderObject();
      var size = renderBox.size;
      var offset = renderBox.localToGlobal(Offset.zero);

      var db = new RouteDB();

      final list = await db.getStopsMatchingParm(searchString);
      var searchList = SearchList(searchResults: list, stopTapCallback: _onStopTapped,);

      this._overlayEntry = OverlayEntry(
          builder: (context) =>
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 5.0,
                width: size.width,
                child: Material(
                  elevation: 0.9,
                  child: searchList,
                ),
              )
      );

      Overlay.of(context).insert(this._overlayEntry);
    }
  }

  void _onStopTapped(Stop stop) {
    this._overlayEntry.remove();
    widget.stopTapCallback(stop);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
        onChanged: (string) {_createOverlayEntry(string);},
        autocorrect: false,
//        onSubmitted: (string) => displayStopRealWithMapMove(Stop(stopCode: string)),
        style: Styles.biggerFont,
        decoration: new InputDecoration(
            hintText: "Search for a stop",
            contentPadding: const EdgeInsets.all(16.0),
            prefixIcon: Icon(Icons.search)
        )
    );
  }
}