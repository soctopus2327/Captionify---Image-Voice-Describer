import 'package:flutter/material.dart';
import 'home_page.dart';
import 'generate_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captionify',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        hintColor: Colors.deepPurpleAccent,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Lato',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: HomePage(),
      routes: {
        '/generate': (context) => GenerateCaptionPage(),
      },
    );
  }
}
