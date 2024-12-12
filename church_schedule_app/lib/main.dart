import 'package:flutter/material.dart';
import 'screens/departments_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church Schedule App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DepartmentsScreen(),
    );
  }
}
