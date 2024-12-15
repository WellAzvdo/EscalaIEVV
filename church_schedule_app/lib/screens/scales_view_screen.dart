import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/db_helper.dart';

class ScalesViewScreen extends StatefulWidget {
  final String departmentName; // Adicionado para receber o nome do departamento

  // Modificando o construtor para aceitar departmentName
  ScalesViewScreen({required this.departmentName});

  @override
  _ScalesViewScreenState createState() => _ScalesViewScreenState();
}

class _ScalesViewScreenState extends State<ScalesViewScreen> {
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late List<Map<String, dynamic>> _scales;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _scales = [];
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escala - ${widget.departmentName}'), // Exibe o nome do departamento
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 1, 1),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),
            SizedBox(height: 16),
            Text(
              'Escalas do Dia ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _scales.length,
                itemBuilder: (context, index) {
                  final scale = _scales[index];

                  // Verificando se a escala corresponde à data selecionada e ao departamento
                  final dateTime = DateTime.tryParse(scale['dateTime'] ?? '');
                  if (dateTime == null || dateTime.day != _selectedDay.day) {
                    return Container(); // Se não for no dia selecionado, ignore
                  }

                  if (scale['departmentName'] != widget.departmentName) {
                    return Container(); // Se o departamento não corresponder, ignore
                  }

                  final department = _departments.firstWhere(
                    (dept) => dept['id'] == scale['departmentId'],
                    orElse: () => {'id': null, 'name': 'Departamento não encontrado'},
                  );

                  final departmentName = department['name'] ?? 'Departamento não encontrado';

                  final position = scale['positionId'] != null
                      ? 'Posição: ${scale['positionId']}'
                      : 'Posição não encontrada';

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

                  final formattedDate = _formatDateTime(dateTime);

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
                          Text(position),
                          Text('Membro(s): $memberNames'),
                          SizedBox(height: 4),
                          Text('Data: $formattedDate'),
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
    );
  }
}
