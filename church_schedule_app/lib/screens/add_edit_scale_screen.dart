import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class AddEditScaleScreen extends StatefulWidget {
  final int? scaleId;

  AddEditScaleScreen({this.scaleId});

  @override
  _AddEditScaleScreenState createState() => _AddEditScaleScreenState();
}

class _AddEditScaleScreenState extends State<AddEditScaleScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String? _selectedDepartment;
  String? _selectedTime;
  List<int> _selectedMembers = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _scales = [];
  final List<String> _availableTimes = [
    '08:00',
    '10:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00'
  ];
  
  List<Map<String, dynamic>> _filteredMembers = [];
  
  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadMembers();
    _loadScales();
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

  Future<void> _loadScales() async {
    final scales = await DBHelper.getScales();
    setState(() {
      _scales = scales;
    });
  }

  Future<void> _saveScale() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.isEmpty) {
        // Verifica se pelo menos um membro foi selecionado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione ao menos um membro.')),
        );
        return;
      }

      final dateTimeString = '${_selectedDate.toIso8601String().split('T')[0]} $_selectedTime';
      final dateTime = DateTime.parse(dateTimeString);

      // Verificar se algum membro está escalado para o mesmo horário e data
      for (var memberId in _selectedMembers) {
        final member = _members.firstWhere((m) => m['id'] == memberId);
        final memberName = member['name'];
  
        final isScheduled = await DBHelper.checkIfMemberIsScheduled(memberName, dateTime);
  
        if (isScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('O membro $memberName já está escalado para esse horário!')),
          );
          return; // Se encontrar conflito, retorna
        }
      }

      final conflictExists = await DBHelper.checkForScaleConflict(
        int.parse(_selectedDepartment!),
        dateTime,
        _selectedMembers,
      );

      if (conflictExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conflito encontrado: Membro já escalado nesse horário!')),
        );
        return;
      }

      if (widget.scaleId == null) {
        // Insere uma nova escala
        await DBHelper.insertScale(
          int.parse(_selectedDepartment!),
          dateTime,
          _selectedMembers,
        );
      } else {
        // Atualiza uma escala existente
        await DBHelper.updateScale(
          widget.scaleId!,
          int.parse(_selectedDepartment!),
          dateTime,
          _selectedMembers,
        );
      }

      // Mostra uma mensagem de sucesso
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Info'),
            content: Text('Escala adicionada com sucesso!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o pop-up
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      // Atualiza a lista de escalas e continua na tela
      _loadScales();
    } else {
      // Exibe uma mensagem se o formulário não for válido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scaleId == null ? 'Adicionar Escala' : 'Editar Escala'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Departamento'),
                items: _departments
                    .map((department) => DropdownMenuItem<String>(
                          value: department['id'].toString(),
                          child: Text(department['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    _filterMembersByDepartment(int.parse(value!));
                  });
                },
                validator: (value) => value == null ? 'Selecione um departamento' : null,
              ),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Membro'),
                value: _selectedMembers.isNotEmpty ? _selectedMembers.last : null, // Seleciona o último membro, ou null se não houver seleção
                items: _filteredMembers
                    .map((member) => DropdownMenuItem<int>(
                          value: member['id'],
                          child: Text(member['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      if (!_selectedMembers.contains(value)) {
                        _selectedMembers.add(value);
                      }
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(labelText: 'Data'),
                controller: TextEditingController(
                  text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Horário'),
                items: _availableTimes
                    .map((time) => DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value;
                  });
                },
                validator: (value) => value == null ? 'Selecione um horário' : null,
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _selectedMembers
                    .map(
                      (id) {
                        // Tenta encontrar o membro correspondente
                        final member = _members.firstWhere(
                          (member) => member['id'] == id,
                          orElse: () => {'id': id, 'name': 'Membro não encontrado'}, // Valor padrão
                        );

                        // Retorna o Chip
                        return Chip(
                          label: Text(member['name']),
                          onDeleted: () {
                            setState(() {
                              _selectedMembers.remove(id);
                            });
                          },
                        );
                      },
                    )
                    .toList(),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveScale,
                child: Text(widget.scaleId == null ? 'Salvar Escala' : 'Atualizar Escala'),
              ),
              SizedBox(height: 24),
              Text(
                'Escalas Criadas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _scales.length,
                  itemBuilder: (context, index) {
                    final scale = _scales[index];

                    // Formatar a data e hora no padrão brasileiro
                    final dateTime = DateTime.parse(scale['dateTime']);
                    final formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

                    // Obter o nome do departamento
                    final departmentName = _departments.firstWhere((dept) => dept['id'] == scale['departmentId'])['name'];

                    // Verifique se 'memberIds' é uma string com IDs separados por vírgula
                    final memberIds = (scale['memberIds'] as String).split(',').map((id) => int.tryParse(id.trim())).where((id) => id != null).toList();

                    // Obter os nomes dos membros a partir dos IDs
                    final memberNames = memberIds.map<String>((id) {
                      final member = _members.firstWhere((member) => member['id'] == id);
                      return member['name'];
                    }).join(', ');

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Departamento: $departmentName',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Membro(s): $memberNames'),
                            SizedBox(height: 4),
                            Text('Data: $formattedDate'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Exibe o diálogo de confirmação
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirmar Deleção'),
                                  content: Text('Tem certeza de que deseja excluir esta escala?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // Retorna 'false' se o usuário clicar em 'Não'
                                      },
                                      child: Text('Não'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true); // Retorna 'true' se o usuário clicar em 'Sim'
                                      },
                                      child: Text('Sim'),
                                    ),
                                  ],
                                );
                              },
                            );
                        
                            // Se o usuário confirmar a deleção
                            if (confirmDelete == true) {
                              await DBHelper.deleteScale(scale['id']);
                              _loadScales(); // Atualiza a lista de escalas após a deleção
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Escala deletada com sucesso.')),
                              );
                            }
                          },
                        )
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  void _filterMembersByDepartment(int departmentId) {
    setState(() {
      _filteredMembers = _members
          .where((member) => member['departmentId'] == departmentId)
          .toList();

      // Remover membros de _selectedMembers que não pertencem ao departamento atual
      _selectedMembers.removeWhere((id) => !_filteredMembers.any((member) => member['id'] == id));
    });
  }
}
