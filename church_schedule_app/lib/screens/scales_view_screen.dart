import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/db_helper.dart';
import 'add_edit_scale_screen.dart';

class ScalesViewScreen extends StatefulWidget {
  final String departmentName;

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

  final DBHelper dbHelper = DBHelper(); // Instanciando DBHelper

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _scales = []; // Inicializando a lista como uma lista mutável
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
      _scales = List.from(scales); // Garantir que _scales seja uma lista mutável
    });
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _getPositionName(int positionId, int departmentId) async {
    return await dbHelper.getPositionName(positionId, departmentId); // Usando a instância dbHelper
  }

  // Função para excluir uma escala
  Future<void> _deleteScale(int scaleId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Tem certeza de que deseja excluir esta escala?'),
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
        await DBHelper.deleteScale(scaleId);
        setState(() {
          _scales.removeWhere((scale) => scale['id'] == scaleId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escala excluída com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir escala: $e')),
        );
      }
    }
  }


  // Função para navegar para a tela de edição
  Future<void> _editScale(Map<String, dynamic> scale) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScaleScreen(scaleId: scale['id']), // Passando o ID da escala
      ),
    );

    if (result != null && result) {
      // Se a escala foi atualizada, recarregue as escalas
      _loadScales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Escala - ${widget.departmentName}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF631221), // Cor da AppBar
        centerTitle: true,
      ),
      body: Container(
        color: Color(0xFF1B1B1B), // Cor de fundo principal
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              locale: 'pt_BR',
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
              availableCalendarFormats: {
                CalendarFormat.week: 'Semana',        // Traduz "Week" para "Semana"
                CalendarFormat.twoWeeks: '2 Semanas', // Traduz "2 weeks" para "2 Semanas"
                CalendarFormat.month: 'Mês',          // Traduz "Month" para "Mês"
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFF631221),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF292929),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: Colors.white),
                selectedTextStyle: TextStyle(color: Colors.white),
                defaultTextStyle: TextStyle(color: Colors.white70),
                weekendTextStyle: TextStyle(color: Colors.redAccent),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.redAccent),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _scales.length,
                itemBuilder: (context, index) {
                  final scale = _scales[index];

                  final dateTime = DateTime.tryParse(scale['dateTime'] ?? '');
                  if (dateTime == null || dateTime.day != _selectedDay.day) {
                    return Container();
                  }

                  if (scale['departmentName'] != widget.departmentName) {
                    return Container();
                  }

                  final department = _departments.firstWhere(
                    (dept) => dept['id'] == scale['departmentId'],
                    orElse: () => {'id': null, 'name': 'Departamento não encontrado'},
                  );

                  final departmentName = department['name'] ?? 'Departamento não encontrado';

                  final positionName = scale['positionId'] != null
                      ? _getPositionName(scale['positionId'], scale['departmentId'])
                      : Future.value('Posição não encontrada');

                  return FutureBuilder<String>(
                    future: positionName,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Erro ao carregar posição', style: TextStyle(color: Colors.redAccent));
                      } else {
                        final position = snapshot.data ?? 'Posição não encontrada';

                        final memberIds = (scale['memberIds'] as String?)
                                ?.split(',')
                                .map((id) => int.tryParse(id.trim()))
                                .where((id) => id != null)
                                .toList() ??
                            [];

                        final memberNames = memberIds
                            .map<String>((id) {
                              final member = _members.firstWhere(
                                (member) => member['id'] == id,
                                orElse: () => {'id': id, 'name': 'Membro não encontrado'},
                              );
                              return member['name'] ?? 'Membro não encontrado';
                            })
                            .join(', ');

                        final formattedTime = _formatTime(dateTime);

                        return Card(
                          color: Color(0xFF292929), // Cor de fundo do Card
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              'Membro: $memberNames',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posição: $position',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white70),
                                ),
                                Text(
                                  'Hora: $formattedTime',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(                                
                              icon: Icon(Icons.more_vert, color: Colors.white), // Três pontinhos na cor branca
                              color: Color(0xFF1B1B1B),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editScale(scale);
                                } else if (value == 'delete') {
                                  _deleteScale(scale['id']);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Editar', style: TextStyle(color: Colors.white70)),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
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
