import 'package:flutter/material.dart';
import 'package:stad/keys.dart';
import 'package:stad/utilities/database.dart';
import 'package:stad/views/stop.dart';
import 'package:stad/widgets/search_app_bar.dart';
import 'package:stad/widgets/search_stops.dart';

class SearchView extends StatefulWidget {

  const SearchView({super.key});
  @override
  State<StatefulWidget> createState() => SearchViewState();
}


class SearchViewState extends State<SearchView> {
  List<Map<String, dynamic>> searchedStops = [];
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    FocusNode searchFocusNode = FocusNode();
    return Scaffold(
        key: Keys.searchScaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: SearchWidget(
            textController: textController,
            handleInputCallback: searchForStopMatching,
            searching: true,
            editableFocusNode: searchFocusNode,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0, //Shadow gone
        ),
        body: Stack(children: <Widget>[
          Container(
              child: SearchStops(stops: searchedStops, stopTapCallback: (stop) async {
                bool focus = await Navigator.push(context, MaterialPageRoute(builder: (context) => StopView(stop: stop,)));
                if (focus == true|| focus==null) FocusScope.of(context).requestFocus(searchFocusNode);
                },),
              decoration: BoxDecoration(color: Colors.white,)
          ),
        ], )
    );
  }

  void searchForStopMatching(String string) async {
    var db = new RouteDB();
    final list = await db.getStopsMatchingParm(string);
    setState(() {
      searchedStops = list;
    });
  }

}
