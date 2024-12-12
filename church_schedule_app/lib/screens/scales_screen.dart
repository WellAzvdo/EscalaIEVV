import 'package:flutter/material.dart';
import 'package:church_schedule_app/screens/add_edit_scale_screen.dart';
import 'package:church_schedule_app/screens/departments_screen.dart'; // Importe a tela para adicionar ou editar departamento

class ScalesScreen extends StatefulWidget {
  @override
  _ScalesScreenState createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escalas'),
      ),
      body: Center(
        child: Text('Tela de escalas aqui'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para a tela de criação de escala
          _showMenu(context);
        },

        child: Icon(Icons.add),
      ),
    );
  }
}

// Método para mostrar o menu de opções ao clicar no FAB
void _showMenu(BuildContext context) async {
  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(100, 100, 100, 100), // Você pode ajustar a posição do menu
    items: [
      PopupMenuItem<String>(
        value: 'addScale',
        child: Text('Adicionar Escala'),
      ),
      PopupMenuItem<String>(
        value: 'addDepartment',
        child: Text('Adicionar Departamento'),
      ),
    ],
    elevation: 8.0,
  );

  // Dependendo da opção escolhida, navega para a tela correspondente
  if (result == 'addScale') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditScaleScreen()),
    );
  } else if (result == 'addDepartment') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DepartmentsScreen()),
    );
  }
}