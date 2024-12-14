import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ManagePositionsScreen extends StatefulWidget {
  @override
  _ManagePositionsScreenState createState() => _ManagePositionsScreenState();
}

class _ManagePositionsScreenState extends State<ManagePositionsScreen> {
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _positions = [];
  int? _selectedDepartmentId;

  final TextEditingController _positionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final departments = await DBHelper.getDepartments();
    setState(() {
      _departments = departments;
    });
  }

  Future<void> _loadPositions() async {
    if (_selectedDepartmentId != null) {
      final positions =
          await DBHelper.getPositionsByDepartment(_selectedDepartmentId!);
      setState(() {
        _positions = positions;
      });
    }
  }

  Future<void> _addPosition() async {
    if (_positionNameController.text.isNotEmpty && _selectedDepartmentId != null) {
      await DBHelper.insertPosition(
        _selectedDepartmentId!,
        _positionNameController.text,
      );
      _positionNameController.clear();
      _loadPositions();
    }
  }

  Future<void> _deletePosition(int id) async {
    await DBHelper.deletePosition(id);
    _loadPositions();
  }

  Future<void> _editPosition(int id, String newName) async {
    await DBHelper.updatePosition(id, newName);
    _loadPositions();
  }

  void _showEditDialog(Map<String, dynamic> position) {
    _positionNameController.text = position['name'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Posição'),
        content: TextField(
          controller: _positionNameController,
          decoration: InputDecoration(labelText: 'Nome da Posição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _editPosition(position['id'], _positionNameController.text);
              Navigator.pop(context);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Posições'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: _selectedDepartmentId,
              hint: Text('Selecione um Departamento'),
              items: _departments
                  .map((dept) => DropdownMenuItem<int>(
                        value: dept['id'],
                        child: Text(dept['name']),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                   _positions = [];
                });
                _loadPositions();
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _positionNameController,
              decoration: InputDecoration(
                labelText: 'Nova Posição',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addPosition,
              child: Text('Adicionar Posição'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _positions.length,
                itemBuilder: (context, index) {
                  final position = _positions[index];
                  return ListTile(
                    title: Text(position['name']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditDialog(position),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deletePosition(position['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
