import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/resources/strings.dart';

import '../styles.dart';



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
      title: buildSearchAppBarTitle(context, textFieldController, searching, viewingStop, backCallback, onTapCallback, handleInputCallback, scaffoldKey),
      backgroundColor: Colors.transparent, //No more green
      elevation: 0.0, // means no shadow
      brightness: Brightness.light
    );
  }
  
  static Widget buildSearchAppBarTitle(
      BuildContext context,
      TextEditingController textController,
      bool searching,
      bool viewingStop,
      Function backCallback,
      Function onTapCallback,
      Function handleInputCallback,
      scaffoldKey)
  {
    print("searching $searching");
    return Container(
      child: Row(children: <Widget>[
        _getIcon(context, searching, viewingStop, backCallback, scaffoldKey),
        Expanded(child: TextField(
          controller: textController,
          key: Keys.searchField,
          autofocus: searching,
          enableInteractiveSelection: searching,
          decoration: InputDecoration(
            hintText: Strings.search,
            border: InputBorder.none,
          ),
          onTap: onTapCallback,
          onChanged: (string) => handleInputCallback(string),
        )),
      ],),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    );
  }

  static Widget _getIcon(BuildContext context, bool searching, bool viewingStop, Function backCallback, scaffoldKey) {
    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    if (canPop) {
      return BackButton(color: Styles.iconColour,);
    } else {
      return IconButton(
        icon: const Icon(Icons.menu),
        color: Styles.iconColour,
        onPressed: () => Scaffold.of(context).openDrawer(),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }
  }

}