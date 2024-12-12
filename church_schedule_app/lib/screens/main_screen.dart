import 'package:flutter/material.dart';
import 'menu_screen.dart'; // Importa a tela de Menu

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            );
          },
          child: Text('Entrar'),
        ),
      ),
    );
  }
}
