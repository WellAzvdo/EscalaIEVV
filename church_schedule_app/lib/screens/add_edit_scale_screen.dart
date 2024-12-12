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

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadScales();
  }

  Future<void> _loadDepartments() async {
    final departments = await DBHelper.getDepartments();
    setState(() {
      _departments = departments;
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
      final dateTimeString = '${_selectedDate.toIso8601String().split('T')[0]} $_selectedTime';
      final dateTime = DateTime.parse(dateTimeString);

      if (widget.scaleId == null) {
        await DBHelper.insertScale(
          int.parse(_selectedDepartment!),
          dateTime,
          _selectedMembers,
        );
      } else {
        await DBHelper.updateScale(
          widget.scaleId!,
          int.parse(_selectedDepartment!),
          dateTime,
          _selectedMembers,
        );
      }

      _loadScales(); // Atualiza a lista de escalas
      Navigator.of(context).pop();
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
                  });
                },
                validator: (value) => value == null ? 'Selecione um departamento' : null,
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
                    return ListTile(
                      title: Text('Departamento ID: ${scale['departmentId']}'),
                      subtitle: Text('Data: ${scale['dateTime']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DBHelper.deleteScale(scale['id']);
                          _loadScales(); // Atualiza a lista após deletar
                        },
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
