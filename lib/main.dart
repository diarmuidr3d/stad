import 'package:flutter/material.dart';

import 'package:stad/styles.dart';
import 'package:stad/views/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
      theme: ThemeData(
        primarySwatch: Styles.appPurple,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Styles.iconColour)
      ),
    );
  }
}