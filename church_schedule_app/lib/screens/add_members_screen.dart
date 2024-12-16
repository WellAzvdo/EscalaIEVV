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
  final DBHelper dbHelper = DBHelper();

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

  void addMemberToDepartment(String memberName, int departmentId) async {
    await DBHelper.addOrUpdateMemberWithDepartment(memberName, departmentId);
  }

  Future<void> _saveMember() async {
    if (_formKey.currentState!.validate()) {
      await DBHelper.insertMember(
        _nameController.text,
        int.parse(_selectedDepartment!),
      );
      _nameController.clear();
      _loadMembers();
    }
  }

  Future<void> _deleteMember(int id) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Tem certeza de que deseja excluir este membro?'),
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
        await dbHelper.deleteMember(id);
        _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membro excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir membro: $e')),
        );
      }
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> member) async {
    _nameController.text = member['name'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Membro'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Nome do Membro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              addMemberToDepartment(_nameController.text, member['departmentId']);
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
          'Gerenciar Membros',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF631221),
        centerTitle: true,
      ),
      body: Container(
        color: Color(0xFF1B1B1B),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Membro',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) =>
                        value!.isEmpty ? 'Insira o nome do membro' : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Departamento',
                      labelStyle: TextStyle(color: Colors.white70),  // Cor da label
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),  // Borda quando não está focado
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),  // Borda quando está focado
                      ),
                    ),
                    items: _departments
                        .map((dept) => DropdownMenuItem<String>(
                              value: dept['id'].toString(),
                              child: Text(
                                dept['name'],
                                style: TextStyle(color: Colors.white),  // Cor do texto na lista
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione um departamento' : null,
                    dropdownColor: Color(0xFF292929),  // Cor do fundo da lista dropdown
                  ),

                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveMember,
                    child: Text('Salvar Membro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF631221),
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Filtrar por Departamento:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            DropdownButton<String>(
              value: _selectedDepartment,
              hint: Text('Todos os Departamentos', style: TextStyle(color: Colors.white70)),
              dropdownColor: Color(0xFF292929),
              items: [
                DropdownMenuItem(value: null, child: Text('Todos os Departamentos', style: TextStyle(color: Colors.white))),
                ..._departments.map(
                  (dept) => DropdownMenuItem(
                    value: dept['id'].toString(),
                    child: Text(dept['name'], style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
            SizedBox(height: 24),
            Expanded(
              child: _members.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum membro cadastrado.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        if (_selectedDepartment == null ||
                            member['departmentId'].toString() == _selectedDepartment) {
                          final department = _departments.firstWhere(
                            (dept) => dept['id'] == member['departmentId'],
                            orElse: () => {'name': 'Departamento Não Encontrado'},
                          );

                          return Card(
                            color: Color(0xFF292929),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                member['name'],
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Departamento: ${department['name']}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.white70),
                                    onPressed: () => _showEditDialog(member),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteMember(member['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return SizedBox();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
