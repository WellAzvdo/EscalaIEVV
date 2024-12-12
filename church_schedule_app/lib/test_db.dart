import 'package:church_schedule_app/database/db_helper.dart';

void testDatabase() async {
  final db = await DBHelper.instance.database;

  // Inserir um departamento
  await db.insert('departments', {'name': 'Diaconato'});

  // Obter os departamentos
  List<Map<String, dynamic>> departments = await db.query('departments');
  print('Departamentos: $departments');
}
