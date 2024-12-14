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
  int? _selectedPosition;
  List<int> _selectedMembers = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _scales = [];
  final List<String> _availableTimes = [
    '08:00', '10:00', '16:00', '17:00', '18:00', '19:00', '20:00'
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

  void validateDropdownValue<T>(List<T> items, T? currentValue, Function(T?) onInvalid) {
    if (currentValue != null && !items.contains(currentValue)) {
      onInvalid(null);
    }
  }

  Future<void> _loadPositions(int departmentId) async {
    final positions = await DBHelper.getPositionsByDepartment(departmentId);
    
    // Remova duplicatas com base no ID
    final uniquePositions = positions.toSet().toList();
    
    setState(() {
      _positions = uniquePositions;
        // Redefina _selectedPosition se o valor atual não existir em _positions
      if (!_positions.any((position) => position['id'] == _selectedPosition)) {
      _selectedPosition = null;
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione ao menos um membro.')),
        );
        return;
      }

      final dateTimeString = '${_selectedDate.toIso8601String().split('T')[0]} $_selectedTime';
      final dateTime = DateTime.parse(dateTimeString);

      for (var memberId in _selectedMembers) {
        final member = _members.firstWhere((m) => m['id'] == memberId);
        final memberName = member['name'];

        final isScheduled = await DBHelper.checkIfMemberIsScheduled(memberName, dateTime);

        if (isScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('O membro $memberName já está escalado para esse horário!')),
          );
          return;
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
        await DBHelper.insertScale(
          int.parse(_selectedDepartment!),
          _selectedPosition!,
          dateTime,
          _selectedMembers,
        );
      } else {
        await DBHelper.updateScale(
          widget.scaleId!,
          int.parse(_selectedDepartment!),
          _selectedPosition!,
          dateTime,
          _selectedMembers,
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Info'),
            content: Text('Escala adicionada com sucesso!'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      _loadScales();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
    }
  }

  void _filterMembersByDepartment(int departmentId) {
    setState(() {
      _filteredMembers = _members
          .where((member) => member['departmentId'] == departmentId)
          .toList();

      _selectedMembers.removeWhere(
          (id) => !_filteredMembers.any((member) => member['id'] == id));
    });
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
                onChanged: (value) async {
                  setState(() {
                    _selectedDepartment = value;
                    _selectedPosition = null;
                  });
                  if (value != null) {
                    await _loadPositions(int.parse(value));
                    _filterMembersByDepartment(int.parse(value));
                  }
                },
                validator: (value) => value == null ? 'Selecione um departamento' : null,
              ),
              if (_positions.isNotEmpty)
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Posição'),
                value: _positions.any((position) => position['id'] == _selectedPosition) 
                    ? _selectedPosition 
                    : null, // Corrige o valor se não for válido
                items: _positions
                    .map((position) => DropdownMenuItem<int>(
                          value: position['id'],
                          child: Text(position['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (!_positions.any((position) => position['id'] == _selectedPosition)) {
                    _selectedPosition = null; // Reseta o valor se não for válido
                  }
                  setState(() {
                    _selectedPosition = value; // Atualiza com o valor selecionado
                  });
                },
                validator: (value) => value == null ? 'Selecione uma posição' : null,
              ),

              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Membro'),
                value: _selectedMembers.isNotEmpty ? _selectedMembers.last : null,
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
                        final member = _members.firstWhere(
                          (member) => member['id'] == id,
                          orElse: () => {'id': id, 'name': 'Membro não encontrado'},
                        );
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

                    // Garantindo que 'scale' esteja correto
                    final dateTime = DateTime.tryParse(scale['dateTime'] ?? '');
                    final formattedDate = dateTime != null
                        ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                        : 'Data inválida';

                    final department = _departments.firstWhere(
                      (dept) => dept['id'] == scale['departmentId'],
                      orElse: () => {'id': null, 'name': 'Departamento não encontrado'},
                    );
                    final departmentName = department['name'] ?? 'Departamento não encontrado';

                    final position = _positions.firstWhere(
                      (pos) => pos['id'] == scale['positionId'],
                      orElse: () => {'id': null, 'name': 'Posição não encontrada'},
                    );
                    final positionName = position['name'] ?? 'Posição não encontrada';

                    final memberIds = (scale['memberIds'] as String?)
                        ?.split(',')
                        .map((id) => int.tryParse(id.trim()))
                        .where((id) => id != null)
                        .toList() ?? [];

                    final memberNames = memberIds.map<String>((id) {
                      final member = _members.firstWhere(
                        (member) => member['id'] == id,
                        orElse: () => {'id': id, 'name': 'Membro não encontrado'},
                      );
                      return member['name'] ?? 'Membro não encontrado';
                    }).join(', ');

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          'Departamento: $departmentName',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Posição: $positionName'),
                            Text('Membro(s): $memberNames'),
                            SizedBox(height: 4),
                            Text('Data: $formattedDate'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Confirmar Deleção'),
                                  content: Text('Tem certeza de que deseja excluir esta escala?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: Text('Não'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text('Sim'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              await DBHelper.deleteScale(scale['id']);
                              _loadScales();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Escala deletada com sucesso.')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
