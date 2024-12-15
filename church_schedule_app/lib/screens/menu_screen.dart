import 'package:flutter/material.dart';
import 'departments_screen.dart';
import 'add_members_screen.dart';
import 'add_edit_scale_screen.dart';
import 'manage_positions_screen.dart';
import 'scales_view_screen.dart'; // Importar a tela de visualização de escalas

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.business, 'label': 'Departamentos', 'screen': DepartmentsScreen()},
    {'icon': Icons.person, 'label': 'Membros', 'screen': AddMembersScreen()},
    {'icon': Icons.schedule, 'label': 'Escalas', 'screen': AddEditScaleScreen()},
    {'icon': Icons.calendar_today, 'label': 'Visualizar Escalas', 'screen': ScalesViewScreen()}, // Novo item de menu
    {'icon': Icons.settings, 'label': 'Gerenciar Posições', 'screen': ManagePositionsScreen()}, // Novo item
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Principal'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Número de colunas
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        padding: EdgeInsets.all(20),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item['screen']),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Icon(item['icon'], size: 40),
                ),
                SizedBox(height: 10),
                Text(item['label']),
              ],
            ),
          );
        },
      ),
    );
  }
}
