import 'package:church_schedule_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Habilite o device preview
      builder: (context) => MyApp(), // A aplicação principal
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(), // Substitua com sua tela principal
      builder: DevicePreview.appBuilder, // Necessário para o DevicePreview
    );
  }
}
