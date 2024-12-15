import 'package:flutter/material.dart';
import 'scales_view_screen.dart'; // Certifique-se de importar a tela de visualização de escalas
import '../database/db_helper.dart'; // Para acessar os departamentos do banco

class DepartmentsSelectionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _departments = [
    {'icon': Icons.business, 'label': 'Diaconato', 'name': 'Diaconato'},
    {'icon': Icons.child_care, 'label': 'Infantil', 'name': 'Infantil'},
    // Adicione mais departamentos conforme necessário
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleção de Departamentos'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Número de colunas
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        padding: EdgeInsets.all(20),
        itemCount: _departments.length,
        itemBuilder: (context, index) {
          final department = _departments[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScalesViewScreen(departmentName: department['name']),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(department['icon'], size: 40),
                ),
                SizedBox(height: 10),
                Text(department['label']),
              ],
            ),
          );
        },
      ),
    );
  }
}
