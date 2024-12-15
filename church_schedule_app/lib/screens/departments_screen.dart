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
      // Adicione mais ícones conforme necessário
    ];

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select an Icon'),
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

  void _showAddEditDialog({int? id, String? currentName, String? currentIcon}) {
    final _nameController = TextEditingController(text: currentName ?? '');
    String? selectedIcon = currentIcon; // Mantém o ícone atual (se houver)
  
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder( // Para atualizar o estado dentro do dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(id == null ? 'Add Department' : 'Edit Department'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Department Name'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Selected Icon: '),
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
                        child: Text('Select Icon'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedIcon == null) {
                      // Mostra mensagem de erro se o ícone não foi selecionado
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select an icon!')),
                      );
                      return; // Não permite salvar
                    }
  
                    if (id == null) {
                      _addDepartment(_nameController.text, selectedIcon!);
                    } else {
                      _editDepartment(id, _nameController.text, selectedIcon!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<String?> _showIconPicker(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        final icons = [
          Icons.home,
          Icons.school,
          Icons.work,
          Icons.star,
          Icons.favorite,
          Icons.people,
          Icons.music_note,
          Icons.sports,
          Icons.business,
        ];

        return AlertDialog(
          title: Text('Select an Icon'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              shrinkWrap: true,
              itemCount: icons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(icons[index].codePoint.toString());
                  },
                  child: Icon(icons[index], size: 30),
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
                  leading: department['icon'] != null
                      ? Icon(
                          IconData(
                            int.parse(department['icon']),
                            fontFamily: 'MaterialIcons',
                          ),
                        )
                      : null,
                  title: Text(department['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(
                          id: department['id'],
                          currentName: department['name'],
                          currentIcon: department['icon'],
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
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}
