import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart'; // Necessário para configurar a localização
import '../database/db_helper.dart'; // Certifique-se de importar seu DBHelper

class ScalesViewScreen extends StatefulWidget {
  @override
  _ScalesViewScreenState createState() => _ScalesViewScreenState();
}

class _ScalesViewScreenState extends State<ScalesViewScreen> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month; // Formato inicial do calendário

  @override
  void initState() {
    super.initState();
    // Configurar o idioma para Português (Brasil)
    Intl.defaultLocale = 'pt_BR';  // Define o locale como 'pt_BR' para Português do Brasil
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now(); // Inicializa com o dia de hoje
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Recuperar as escalas do banco de dados para o dia selecionado
    final formattedDate = DateFormat('yyyy-MM-dd').format(day);
    List<Event> events = [];
    
    DBHelper.getScales().then((scales) {
      for (var scale in scales) {
        DateTime scaleDate = DateTime.parse(scale['dateTime']);
        if (DateFormat('yyyy-MM-dd').format(scaleDate) == formattedDate) {
          events.add(Event(scale)); // Adicionar escala para o dia
        }
      }
      _selectedEvents.value = events;
    });

    return events;
  }

  // Função de callback para lidar com mudanças no formato do calendário
  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualização das Escalas'),
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
            calendarFormat: _calendarFormat, // Passa o formato atual
            onFormatChanged: _onFormatChanged, // Adiciona o callback
            locale: 'pt_BR', // Define o idioma para português do Brasil
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
