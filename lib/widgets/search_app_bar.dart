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
      title: buildSearchAppBarTitle(context, textFieldController, searching, onTapCallback, handleInputCallback),
      backgroundColor: Colors.transparent, //No more green
      elevation: 0.0, // means no shadow
      brightness: Brightness.light
    );
  }
  
  static Widget buildSearchAppBarTitle(
      BuildContext context,
      TextEditingController textController,
      bool searching,
      Function onTapCallback,
      Function handleInputCallback,
      )
  {
    return Container(
      child: Row(children: <Widget>[
        _getIcon(context),
        Expanded(child: SearchAppBarText(
          editable: searching,
          onInput: handleInputCallback,
          onTapCallback: onTapCallback,
          textController: textController,
        ),),
      ],),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    );
  }

  static Widget _getIcon(BuildContext context) {
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

class SearchAppBarText extends StatelessWidget {
  final bool editable;
  final Function onTapCallback;
  final TextEditingController textController;
  final Function onInput;

  /// Creates either a [TextField] or a [Text] depending on the [editable] parameter.
  /// [onTapCallback] is only used if not [editable] and is called when the widget is tapped.
  /// [textController] is only used when [editable], it's so the text in the [TextField] isn't lost.
  /// [onInput] is also only used when [editable], it is called for each change in input text.
  const SearchAppBarText({
    Key key,
    this.editable,
    this.onTapCallback, 
    this.textController, 
    this.onInput,
  });

  @override
  Widget build(BuildContext context) {
    if(editable) {
      return TextField(
        controller: textController,
        key: Keys.searchField,
        autofocus: true,
        decoration: InputDecoration(
          hintText: Strings.search,
          border: InputBorder.none,
        ),
        onChanged: onInput,
      );
    } else {
      return GestureDetector(
        child: Text(Strings.search, style: _getInlineStyle(Theme.of(context)),),
        onTap: onTapCallback,
      );
    }
  }

  TextStyle _getInlineStyle(ThemeData themeData) {
    return themeData.textTheme.subhead.copyWith(color: themeData.hintColor);
  }
}