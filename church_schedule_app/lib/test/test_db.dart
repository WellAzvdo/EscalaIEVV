import 'package:flutter/material.dart';
import 'package:church_schedule_app/database/db_helper.dart';

void testScales() async {
  DBHelper dbHelper = DBHelper();

  // Inserir uma nova escala
  await DBHelper.insertScale(1, DateTime(2024, 12, 15, 9, 0), [1, 2]);

  // Verificar se existe um conflito de escala
  bool conflict = await DBHelper.checkForScaleConflict(1, DateTime(2024, 12, 15, 9, 0));
  print('Conflict exists: $conflict');

  // Recuperar todas as escalas
  List<Map<String, dynamic>> scales = await DBHelper.getScales();
  print('Scales: $scales');

}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('Testes de Escalas'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            testScales();
          },
          child: Text('Testar Escalas'),
        ),
      ),
    ),
  ));
}
