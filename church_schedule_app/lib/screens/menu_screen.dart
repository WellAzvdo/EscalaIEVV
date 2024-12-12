import 'package:flutter/material.dart';
import 'departments_screen.dart';
import 'add_members_screen.dart';
import 'add_edit_scale_screen.dart';

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.business, 'label': 'Departamentos', 'screen': DepartmentsScreen()},
    {'icon': Icons.person, 'label': 'Membros', 'screen': AddMembersScreen()},
    {'icon': Icons.schedule, 'label': 'Escalas', 'screen': AddEditScaleScreen()},
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
