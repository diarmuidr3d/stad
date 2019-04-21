import 'package:flutter/material.dart';

import 'package:stad/styles.dart';
import 'package:stad/widgets/home.dart';

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
      theme: new ThemeData(
        primaryColor: Styles.appPurple,
        textTheme: TextTheme().apply(bodyColor: Colors.green, displayColor: Colors.orange)
      )
    );
  }
}