import 'package:flutter/material.dart';

class AddEditScaleScreen extends StatefulWidget {
  @override
  _AddEditScaleScreenState createState() => _AddEditScaleScreenState();
}

class _AddEditScaleScreenState extends State<AddEditScaleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar/Editar Escala'),
      ),
      body: Center(
        child: Text('Conteúdo da tela de adicionar/editar escala'),
      ),
    );
  }
}
