import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart'; // Certifique-se de importar seu DBHelper

class ScalesViewScreen extends StatefulWidget {
  final String departmentName; // Recebe o nome do departamento

  const ScalesViewScreen({required this.departmentName});

  @override
  _ScalesViewScreenState createState() => _ScalesViewScreenState();
}

class _ScalesViewScreenState extends State<ScalesViewScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  List<Event> _getEventsForDay(DateTime day) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(day);
    List<Event> events = [];
    
    DBHelper.getScales().then((scales) {
      for (var scale in scales) {
        DateTime scaleDate = DateTime.parse(scale['dateTime']);
        if (DateFormat('yyyy-MM-dd').format(scaleDate) == formattedDate && scale['departmentName'] == widget.departmentName) {
          events.add(Event(scale)); // Filtra pela escala do departamento selecionado
        }
      }
      _selectedEvents.value = events;
    });

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escala - ${widget.departmentName}'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents.value = _getEventsForDay(selectedDay);
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView(
                  children: value.map((event) {
                    return ListTile(
                      title: Text('Escala: ${event.scale['departmentName']}'),
                      subtitle: Text('Posição: ${event.scale['positionName']}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final dynamic scale;

  Event(this.scale);
}
