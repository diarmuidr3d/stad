import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/resources/strings.dart';



class SearchAppBar extends StatelessWidget {
  final scaffoldKey;
  final Function onTapCallback;
  final bool searching;
  final bool viewingStop;
  final Function backCallback;
  final Function handleInputCallback;
  final TextEditingController textFieldController;

  const SearchAppBar({
    Key key,
    @required this.scaffoldKey,
    @required this.onTapCallback,
    @required this.searching,
    @required this.viewingStop,
    @required this.backCallback,
    @required this.handleInputCallback,
    @required this.textFieldController
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Container(
        child: Row(children: <Widget>[
          getIcon(context),
          Expanded(child: TextField(
            controller: textFieldController,
            key: Keys.searchField,
            autofocus: searching,
            enabled: !searching,
            decoration: InputDecoration(
                hintText: Strings.search,
                border: InputBorder.none,
            ),
            onTap: () => onTapCallback(),
            onChanged: (string) => handleInputCallback(string),
          )),
        ],),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      backgroundColor: Colors.transparent, //No more green
      elevation: 0.0, //Shadow gone
    );
  }

  IconButton getIcon(context) {
    if (searching || viewingStop) {
      return IconButton(icon: Icon(Icons.arrow_back),
        onPressed: () {
          backCallback();
        },
        color: Colors.black,);
    } else {
      return IconButton(icon: Icon(Icons.dehaze),
        onPressed: () => scaffoldKey.currentState.openDrawer(),
        color: Colors.black,);
    }
  }

}