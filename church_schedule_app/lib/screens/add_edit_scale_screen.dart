import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  int? _selectedMember; // Alteração para permitir apenas um membro
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _members = [];
  final List<String> _availableTimes = [
    '08:00', '10:00', '16:00', '17:00', '18:00', '19:00', '20:00'
  ];
  List<Map<String, dynamic>> _filteredMembers = [];

@override
void initState() {
  super.initState();
  _loadDepartments();
  _loadMembers();
  if (widget.scaleId != null) {
    _loadScale(widget.scaleId!); // Carregar dados da escala para edição
  }
}

  Future<void> _loadDepartments() async {
    final departments = await DBHelper.getDepartments();
    setState(() {
      _departments = departments;
    });
  }

  Future<void> _loadPositions(int departmentId) async {
    final positions = await DBHelper.getPositionsByDepartment(departmentId);
    final uniquePositions = positions.toSet().toList();
    setState(() {
      _positions = uniquePositions;
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

  Future<void> _loadScale(int scaleId) async {
    try {
      final scale = await DBHelper().getScaleById(scaleId); // Busca a escala no banco

      setState(() {
        // Valores retornados do banco de dados (com tratamento para valores nulos)
        _selectedDepartment = scale['departmentId']?.toString() ?? ''; // Convertendo para string
        _selectedPosition = scale['positionId'] ?? 0; // Valor padrão
        _selectedMember = scale['memberId'] ?? 0; // Valor padrão
        _selectedDate = scale['date'] != null
            ? DateTime.parse(scale['date']) // Convertendo para DateTime
            : DateTime.now(); // Valor padrão se for nulo
        _selectedTime = scale['time'] ?? ''; // Valor padrão
      });
    } catch (e) {
      print('Erro ao carregar escala: $e');
    }
  }


  Future<void> _saveScale() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMember == null) { // Verificando se algum membro foi selecionado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selecione um membro.')),
        );
        return;
      }

      final dateTimeString = '${_selectedDate.toIso8601String().split('T')[0]} $_selectedTime';
      final dateTime = DateTime.parse(dateTimeString);

      final member = _members.firstWhere((m) => m['id'] == _selectedMember);
      final memberName = member['name'];

      final isScheduled = await DBHelper.checkIfMemberIsScheduled(memberName, dateTime);

      if (isScheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Choque de Escala: O membro $memberName já está escalado(a) para esse horário!')),
        );
        return;
      }

      final conflictExists = await DBHelper.checkForScaleConflict(
        int.parse(_selectedDepartment!),
        dateTime,
        [_selectedMember!],
      );

      if (conflictExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Choque de Escala: Membro já escalado(a) nesse horário!')),
        );
        return;
      }

      if (widget.scaleId == null) {
        await DBHelper.insertScale(
          int.parse(_selectedDepartment!),
          _selectedPosition!,
          dateTime,
          [_selectedMember!],
        );
      } else {
        await DBHelper.updateScale(
          widget.scaleId!,
          int.parse(_selectedDepartment!),
          _selectedPosition!,
          dateTime,
          [_selectedMember!],
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scaleId == null ? 'Adicionar Escala' : 'Editar Escala',
        style: TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Color(0xFF631221),
        centerTitle: true,
      ),
      body: Container(
        color: Color(0xFF1B1B1B),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Departamento',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              value: _selectedDepartment, // Definir o valor selecionado
              items: _departments
                  .map((department) => DropdownMenuItem<String>(
                        value: department['id'].toString(),
                        child: Text(
                          department['name'],
                          style: TextStyle(color: Colors.white),  
                        ),
                      ))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedDepartment = value;
                  _selectedPosition = null; // Resetando a posição
                  _selectedMember = null;  // Resetando o membro
                });
                if (value != null) {
                  await _loadPositions(int.parse(value));
                  _filterMembersByDepartment(int.parse(value));
                }
              },
              validator: (value) => 
                value == null ? 'Selecione um departamento' : null,
              dropdownColor: Color(0xFF292929),
            ),
            SizedBox(height: 16),
            if (_positions.isNotEmpty)
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Posição',
                labelStyle: TextStyle(color: Colors.white70),  // Cor da label
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),  // Borda quando não está focado
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),  // Borda quando está focado
                ),
              ),
              value: _selectedPosition, // Definir o valor selecionado
              items: _positions
                  .map((position) => DropdownMenuItem<int>(
                        value: position['id'],
                        child: Text(position['name'],
                        style: TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosition = value;
                });
              },
              validator: (value) => 
                value == null ? 'Selecione uma posição' : null,
              dropdownColor: Color(0xFF292929),  // Cor do fundo da lista dropdown
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Membro',
                labelStyle: TextStyle(color: Colors.white70),  // Cor da label
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),  // Borda quando não está focado
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),  // Borda quando está focado
                ),
              ),
              value: _selectedMember, // Definir o valor selecionado
              items: _filteredMembers
                  .map((member) => DropdownMenuItem<int>(
                        value: member['id'],
                        child: Text(member['name'],
                        style: TextStyle(color: Colors.white),  // Cor do texto na lista
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                });
              },
              validator: (value) => 
                  value == null ? 'Selecione um membro' : null,
              dropdownColor: Color(0xFF292929),  // Cor do fundo da lista dropdown

            ),
              SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                style: TextStyle(color: Colors.white), // Define a cor do texto como branco
                decoration: InputDecoration(
                  labelText: 'Data',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                controller: TextEditingController(
                  text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    locale: const Locale('pt', 'BR'), // Define o calendário em português
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
                decoration: InputDecoration(
                  labelText: 'Horário',
                  labelStyle: TextStyle(color: Colors.white70),  // Cor da label
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),  // Borda quando não está focado
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),  // Borda quando está focado
                  ),
                ),
                items: _availableTimes
                    .map((time) => DropdownMenuItem<String>(
                          value: time,
                          child: Text(
                            time,
                            style: TextStyle(color: Colors.white),  // Cor do texto na lista
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value;
                  });
                },
                validator: (value) => 
                    value == null ? 'Selecione um horário' : null,
                dropdownColor: Color(0xFF292929),  // Cor do fundo da lista dropdown
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveScale,
                child: Text(widget.scaleId == null ? 'Salvar Escala' : 'Atualizar Escala'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF631221),
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
