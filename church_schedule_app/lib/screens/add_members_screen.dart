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
  final DBHelper dbHelper = DBHelper();  // Instanciando DBHelper

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

  // Função para adicionar ou atualizar membro
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
      _loadMembers(); // Atualiza a lista de membros
    }
  }

  // Correção do método de exclusão
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
        _loadMembers(); // Atualiza a lista de membros após exclusão
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
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  if (_selectedDepartment == null ||
                      member['departmentId'].toString() == _selectedDepartment) {
                      
                    // Encontrar o departamento pelo ID
                    final department = _departments.firstWhere(
                      (dept) => dept['id'] == member['departmentId'],
                      orElse: () => {'name': 'Departamento Não Encontrado'} // Caso o departamento não seja encontrado
                    );
            
                    return ListTile(
                      title: Text(member['name']),
                      subtitle: Text('Departamento: ${department['name']}'), // Exibe o nome do departamento
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showEditDialog(member),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteMember(member['id']),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox(); // Para itens que não correspondem ao filtro
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
