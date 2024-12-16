import 'package:flutter/material.dart';
import '../database/db_helper.dart';

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

  Future<void> _addDepartment(String name, String? icon) async {
    await DBHelper.insertDepartment(name, icon);
    _fetchDepartments();
  }

  Future<void> _editDepartment(int id, String newName, String? newIcon) async {
    await DBHelper.updateDepartment(id, newName, newIcon);
    _fetchDepartments();
  }

  Future<void> _deleteDepartment(int id) async {
    await DBHelper.deleteDepartment(id);
    _fetchDepartments();
  }

  void _showAddEditDialog({int? id, String? currentName, String? currentIcon}) {
    final _nameController = TextEditingController(text: currentName ?? '');
    String? selectedIcon = currentIcon;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(id == null ? 'Adicionar Departamento' : 'Editar Departamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Nome do Departamento'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Ícone: '),
                      if (selectedIcon != null)
                        Icon(
                          IconData(
                            int.parse(selectedIcon!),
                            fontFamily: 'MaterialIcons',
                          ),
                        )
                      else
                        Text('None', style: TextStyle(color: Colors.red)),
                      Spacer(),
                      TextButton(
                        onPressed: () async {
                          final icon = await _showIconSelectionDialog();
                          if (icon != null) {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          }
                        },
                        child: Text('Selecionar Ícone'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedIcon == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Por favor, selecione um ícone!')),
                      );
                      return;
                    }

                    if (id == null) {
                      _addDepartment(_nameController.text, selectedIcon);
                    } else {
                      _editDepartment(id, _nameController.text, selectedIcon);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showIconSelectionDialog() async {
    final icons = <IconData>[
      Icons.ac_unit,
      Icons.access_alarm,
      Icons.accessibility,
      Icons.account_balance,
      Icons.add_shopping_cart,
      Icons.airplanemode_active,
      Icons.all_inclusive,
      Icons.assessment,
      Icons.bookmark,
      Icons.build,
      Icons.business,
      Icons.camera_alt,
      Icons.chat,
      Icons.cloud,
      Icons.computer,
      Icons.contacts,
      Icons.directions_car,
      Icons.email,
      Icons.favorite,
      Icons.fingerprint,
      Icons.home,
      Icons.language,
      Icons.music_note,
      Icons.notifications,
      Icons.restaurant,
      Icons.school,
      Icons.shop,
      Icons.star,
      Icons.sports_baseball,
      Icons.train,
      Icons.work,
    ];

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione um ícone'),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(icon.codePoint.toString());
                  },
                  child: Icon(icon, size: 40),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Tem certeza de que deseja excluir este Departamento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteDepartment(id);
                Navigator.of(context).pop();
              },
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Departamentos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF631221),
      ),
      body: Container(
        color: Color(0xFF1B1B1B),
        child: Column(
          children: [
            SizedBox(height: 10), // Espaçamento abaixo do título
            Expanded(
              child: _departments.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum departamento adicionado ainda.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _departments.length,
                      itemBuilder: (context, index) {
                        final department = _departments[index];
                        return Card(
                          color: Color(0xFF292929),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: department['icon'] != null
                                ? Icon(
                                    IconData(
                                      int.parse(department['icon']),
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: Colors.white,
                                  )
                                : null,
                            title: Text(
                              department['name'],
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _showAddEditDialog(
                                    id: department['id'],
                                    currentName: department['name'],
                                    currentIcon: department['icon'],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(department['id']),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF631221),
        child: Icon(Icons.add),
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}
