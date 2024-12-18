import 'package:church_schedule_app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: false, // Habilite o Device Preview
      builder: (context) => MyApp(), // A aplicação principal
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Church Schedule App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(), // Sua tela principal
      builder: DevicePreview.appBuilder, // Necessário para o DevicePreview
      // Adicione suporte para localizações
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'), // Português do Brasil
        const Locale('en', 'US'), // Inglês (opcional)
      ],
      locale: const Locale('pt', 'BR'), // Define o padrão como pt_BR
    );
  }
}
