import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/resources/strings.dart';

import '../styles.dart';



class SearchAppBar extends StatelessWidget {
  final scaffoldKey;
  final Function onTapCallback;
  final bool searching;
  final Function handleInputCallback;
  final TextEditingController textFieldController;

  const SearchAppBar({
    Key key,
    @required this.scaffoldKey,
    @required this.onTapCallback,
    @required this.searching,
    @required this.handleInputCallback,
    @required this.textFieldController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: SearchWidget(
          textController: textFieldController,
          searching: searching,
          onTapCallback: onTapCallback,
          handleInputCallback: handleInputCallback),
      backgroundColor: Colors.transparent, //No more green
      elevation: 0.0, // means no shadow
      brightness: Brightness.light
    );
  }

}

class SearchWidget extends StatelessWidget {
  final TextEditingController textController;
  final bool searching;
  final Function onTapCallback;
  final Function handleInputCallback;
  final FocusNode editableFocusNode;

  /// Builds a box with rounded edges containing an Icon button on the left and a [SearchText] on the right.
  /// The button is either a menu icon to open the drawer or a back button.
  /// All the parms are for passing to [SearchText].
  const SearchWidget({this.textController, this.searching, this.onTapCallback, this.handleInputCallback, this.editableFocusNode});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(children: <Widget>[
        _getIcon(context),
        Expanded(child: SearchText(
          editable: searching,
          onInput: handleInputCallback,
          onTapCallback: onTapCallback,
          textController: textController,
          editableFocusNode: editableFocusNode,
        ),),
      ],),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    );
  }

  Widget _getIcon(BuildContext context) {
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

class SearchText extends StatelessWidget {
  final bool editable;
  final Function onTapCallback;
  final TextEditingController textController;
  final Function onInput;
  final FocusNode editableFocusNode;

  /// Creates either a [TextField] or a [Text] depending on the [editable] parameter.
  /// [onTapCallback] is only used if not [editable] and is called when the widget is tapped.
  /// [textController] is only used when [editable], it's so the text in the [TextField] isn't lost.
  /// [onInput] is also only used when [editable], it is called for each change in input text.
  const SearchText({
    this.editable,
    this.onTapCallback, 
    this.textController, 
    this.editableFocusNode,
    this.onInput,
  });

  @override
  Widget build(BuildContext context) {
    if(editable) {
      return TextField(
        controller: textController,
        key: Keys.searchField,
        autofocus: true,
        focusNode: editableFocusNode,
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
    return themeData.textTheme.subtitle1.copyWith(color: themeData.hintColor);
  }
}