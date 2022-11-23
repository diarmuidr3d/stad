// @dart=2.9
// TODO: remove the above line after replacing the xpath dependency

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
      home: HomeView(),
      theme: ThemeData(
        primarySwatch: Styles.appPurple,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Styles.iconColour)
      ),
    );
  }
}