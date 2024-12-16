import 'package:flutter/material.dart';
import 'departments_screen.dart';
import 'add_members_screen.dart';
import 'add_edit_scale_screen.dart';
import 'manage_positions_screen.dart';
import 'scales_view_screen.dart'; // Importar a tela de visualização de escalas
import '../screens/departments_selecion_screen.dart'; // Importar a tela de seleção de departamentos

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.business,
      'label': 'Departamentos',
      'screen': DepartmentsScreen()
    },
    {
      'icon': Icons.settings,
      'label': 'Gerenciar Posições',
      'screen': ManagePositionsScreen()
    },
    {
      'icon': Icons.person,
      'label': 'Membros',
      'screen': AddMembersScreen()
    },
    {
      'icon': Icons.schedule,
      'label': 'Escalas',
      'screen': AddEditScaleScreen()
    },
    {
      'icon': Icons.calendar_today,
      'label': 'Visualizar Escalas',
      'screen': DepartmentsSelectionScreen()
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IEVV Aldeota - Escalas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF631221),
      ),
      body: Container(
        color: Color(0xFF1B1B1B),
        child: GridView.builder(
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
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF292929),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF631221),
                      child: Icon(
                        item['icon'],
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      item['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
