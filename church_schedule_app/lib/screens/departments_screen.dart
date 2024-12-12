import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'add_edit_scale_screen.dart';  // Importe a tela para adicionar/editar escala.

class DepartmentsScreen extends StatefulWidget {
  @override
  _DepartmentsScreenState createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final data = await DBHelper.getDepartments();
    setState(() {
      _departments = data;
    });
  }

  Future<void> _addDepartment(String name) async {
    await DBHelper.insertDepartment(name);
    _fetchDepartments();
  }

  Future<void> _editDepartment(int id, String newName) async {
    await DBHelper.updateDepartment(id, newName);
    _fetchDepartments();
  }

  Future<void> _deleteDepartment(int id) async {
    await DBHelper.deleteDepartment(id);
    _fetchDepartments();
  }

  void _showAddEditDialog({int? id, String? currentName}) {
    final _controller = TextEditingController(text: currentName ?? '');
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(id == null ? 'Add Department' : 'Edit Department'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Department Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (id == null) {
                  _addDepartment(_controller.text);
                } else {
                  _editDepartment(id, _controller.text);
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this department?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteDepartment(id);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar as opções do FAB
  void _showFABOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Add New Scale'),
                onTap: () {
                  Navigator.of(context).pop();  // Fecha o menu
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditScaleScreen())
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add New Department'),
                onTap: () {
                  Navigator.of(context).pop();  // Fecha o menu
                  _showAddEditDialog();  // Chama a função para adicionar um departamento
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Departments'),
      ),
      body: _departments.isEmpty
          ? Center(child: Text('No departments added yet.'))
          : ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final department = _departments[index];
                return ListTile(
                  title: Text(department['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(
                          id: department['id'],
                          currentName: department['name'],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _confirmDelete(department['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showFABOptions,  // Chama a função para abrir as opções
      ),
    );
  }
}
