import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class PositionsScreen extends StatefulWidget {
  @override
  _PositionsScreenState createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  final TextEditingController _positionController = TextEditingController();
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final positions = await DBHelper.getAllPositions();
    final departments = await DBHelper.getDepartments();
    setState(() {
      _positions = positions;
      _departments = departments;
    });
  }

  Future<void> _addPosition() async {
    if (_positionController.text.isNotEmpty && _selectedDepartment != null) {
      // Convertemos o departamento selecionado para int
      int departmentId = int.parse(_selectedDepartment!);
      
      // Passamos o departmentId como int para o método insertPosition
      await DBHelper.insertPosition(departmentId, _positionController.text);
      
      _positionController.clear();
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }


  Future<void> _deletePosition(int id) async {
    await DBHelper.deletePosition(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Positions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _positionController,
              decoration: InputDecoration(
                labelText: 'Position Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department['id'].toString(),
                  child: Text(department['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select Department',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addPosition,
              child: Text('Add Position'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _positions.length,
                itemBuilder: (context, index) {
                  final position = _positions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(position['name']),
                      subtitle: Text(
                        'Department: ${_departments.firstWhere(
                          (dept) => dept['id'] == position['departmentId'],
                          orElse: () => {'name': 'Unknown'},
                        )['name']}',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePosition(position['id']),
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
