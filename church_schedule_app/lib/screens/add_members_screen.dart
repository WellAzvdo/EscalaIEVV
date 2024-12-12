import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class AddMembersScreen extends StatefulWidget {
  @override
  _AddMembersScreenState createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDepartment;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _departments = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadMembers();
  }

  Future<void> _loadDepartments() async {
    final departments = await DBHelper.getDepartments();
    setState(() {
      _departments = departments;
    });
  }

  Future<void> _loadMembers() async {
    final members = await DBHelper.getMembers();
    setState(() {
      _members = members;
    });
  }

  Future<void> _saveMember() async {
    if (_formKey.currentState!.validate()) {
      await DBHelper.insertMember(
        _nameController.text,
        int.parse(_selectedDepartment!),
      );
      _nameController.clear();
      _loadMembers(); // Atualiza a lista de membros
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Membro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Nome do Membro'),
                    validator: (value) =>
                        value!.isEmpty ? 'Insira o nome do membro' : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Departamento'),
                    items: _departments
                        .map((dept) => DropdownMenuItem<String>(
                              value: dept['id'].toString(),
                              child: Text(dept['name']),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione um departamento' : null,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveMember,
                    child: Text('Salvar Membro'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            DropdownButton<String>(
              value: _selectedDepartment,
              hint: Text('Filtrar por Departamento'),
              items: [
                DropdownMenuItem(value: null, child: Text('Todos os Departamentos')),
                ..._departments.map(
                  (dept) => DropdownMenuItem(
                    value: dept['id'].toString(),
                    child: Text(dept['name']),
                  ),
                )
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
            Expanded(
              child: ListView(
                children: _members
                    .where((member) =>
                        _selectedDepartment == null ||
                        member['departmentId'].toString() == _selectedDepartment)
                    .map((member) => ListTile(
                          title: Text(member['name']),
                          subtitle:
                              Text('Departamento ID: ${member['departmentId']}'),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
