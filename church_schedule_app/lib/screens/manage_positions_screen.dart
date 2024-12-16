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
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Tem certeza de que deseja excluir esta posição?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      try {
        await DBHelper.deletePosition(id);
        _loadPositions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Posição excluída com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir posição: $e')),
        );
      }
    }
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
        title: Text(
          'Gerenciar Posições',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF631221),
      ),
      body: Container(
        color: Color(0xFF1B1B1B),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: _selectedDepartmentId,
              dropdownColor: Color(0xFF292929),
              hint: Text('Selecione um Departamento', style: TextStyle(color: Colors.white)),
              items: _departments
                  .map((dept) => DropdownMenuItem<int>(
                        value: dept['id'],
                        child: Text(dept['name'], style: TextStyle(color: Colors.white)),
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
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nova Posição',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF631221),
              ),
              onPressed: _addPosition,
              child: Text('Adicionar Posição'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _positions.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma posição cadastrada.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _positions.length,
                      itemBuilder: (context, index) {
                        final position = _positions[index];
                        return Card(
                          color: Color(0xFF292929),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              position['name'],
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _showEditDialog(position),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deletePosition(position['id']),
                                ),
                              ],
                            ),
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
