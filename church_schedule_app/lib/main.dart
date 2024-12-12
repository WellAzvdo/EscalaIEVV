import 'package:flutter/material.dart';
import 'screens/departments_screen.dart';
import 'test/test_db.dart';

void main() {
  runApp(MyApp());
  testScales();
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
