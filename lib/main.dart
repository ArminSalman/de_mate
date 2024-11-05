import 'package:flutter/material.dart';
import 'main_page.dart'; // Import the file where MainPage is defined

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(), // Set MainPage as the home widget
    );
  }
}
