// lib/src/screens/events_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'event_create_screen.dart';
import 'attendees_screen.dart';

/// EventsListScreen: lists events, allows create, start, finish and navigate to attendee registration.
class EventsListScreen extends StatefulWidget {
  @override
  _EventsListScreenState createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  late final SupabaseService _service;
  List<Map<String, dynamic>> events = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _service = SupabaseService(Supabase.instance.client);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => loading = true);
    try {
      final res = await _service.fetchEvents();
      setState(() {
        events = res;
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando eventos')));
    } finally {
      setState(() => loading = false);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd MMM yyyy — HH:mm').format(dt);
  }

  Future<void> _startEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Iniciar evento'),
        content: Text('¿Deseas iniciar el evento ahora?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Iniciar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.startEvent(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evento iniciado')));
      _loadEvents();
    } catch (e) {
      debugPrint('Error starting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al iniciar evento')));
    }
  }

  Future<void> _finishEvent(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Finalizar evento'),
        content: Text('¿Finalizar "$name"? Esto guardará el conteo final de asistentes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Finalizar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.finishEvent(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evento finalizado')));
      _loadEvents();
    } catch (e) {
      debugPrint('Error finishing event: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al finalizar evento')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EventTable — Eventos', style: TextStyle(color: Theme.of(context).primaryColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: loading
            ? Center(child: CircularProgressIndicator())
            : events.isEmpty
                ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('No hay eventos. Crea uno nuevo.', style: TextStyle(color: Colors.grey)))
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      final name = e['name'] ?? '';
                      final startAt = e['start_at'] ?? '';
                      final status = e['status'] ?? 'scheduled';
                      final expected = e['expected_attendees'] ?? 0;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 6),
                              Text(_formatDate(startAt)),
                              SizedBox(height: 4),
                              Text('Esperados: $expected • Estado: ${status.toString()}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'start') await _startEvent(e['id'] as String);
                              if (val == 'finish') await _finishEvent(e['id'] as String, name);
                              if (val == 'attendees') {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AttendeesScreen(event: e)));
                                _loadEvents();
                              }
                            },
                            itemBuilder: (_) => [
                              if (status != 'started') PopupMenuItem(value: 'start', child: Text('Iniciar')),
                              if (status != 'finished') PopupMenuItem(value: 'finish', child: Text('Finalizar')),
                              PopupMenuItem(value: 'attendees', child: Text('Asistentes')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => EventCreateScreen()));
          if (created == true) _loadEvents();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
        tooltip: 'Crear evento',
      ),
    );
  }
}
