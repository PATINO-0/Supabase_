// lib/src/screens/attendees_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AttendeesScreen shows list of attendees for an event and allows registering new ones.
/// UI strings are Spanish; comments and code in English.
class AttendeesScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  AttendeesScreen({required this.event});

  @override
  _AttendeesScreenState createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  List<Map<String, dynamic>> attendees = [];
  bool loading = false;
  final _firstCtl = TextEditingController();
  final _lastCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAttendees();
  }

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    super.dispose();
  }

  /// Fetch attendees for the given event from Supabase.
  Future<void> _fetchAttendees() async {
    setState(() => loading = true);
    try {
      final res = await Supabase.instance.client
          .from('attendees')
          .select()
          .eq('event_id', widget.event['id'])
          .order('registered_at', ascending: true)
          .execute();

      debugPrint('Fetch attendees status: ${res.status}');
      debugPrint('Fetch attendees data: ${res.data}');

      final data = res.data;
      if (data == null) {
        attendees = [];
      } else {
        attendees = List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
    } on PostgrestException catch (e) {
      debugPrint('Supabase PostgrestException fetching attendees: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar asistentes: ${e.message}')));
    } catch (e) {
      debugPrint('Unknown error fetching attendees: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar asistentes')));
    } finally {
      setState(() => loading = false);
    }
  }

  /// Register a new attendee for the event. Uses .select() to get the inserted row.
  Future<void> _register() async {
    final first = _firstCtl.text.trim();
    final last = _lastCtl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ingrese nombre y apellido')));
      return;
    }

    setState(() => loading = true);
    try {
      final res = await Supabase.instance.client.from('attendees').insert({
        'event_id': widget.event['id'],
        'first_name': first,
        'last_name': last,
      }).select().execute(); // <- select() ensures returned row

      debugPrint('Insert attendee status: ${res.status}');
      debugPrint('Insert attendee data: ${res.data}');

      if (res.data == null) {
        throw Exception('No data returned from insert attendee. Status: ${res.status ?? 'unknown'}');
      }

      _firstCtl.clear();
      _lastCtl.clear();
      await _fetchAttendees();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Asistente registrado')));
    } on PostgrestException catch (e) {
      debugPrint('Supabase PostgrestException registering attendee: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar: ${e.message}')));
    } catch (e) {
      debugPrint('Unknown error registering attendee: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName = widget.event['name'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistentes — $eventName', style: TextStyle(color: Theme.of(context).primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Registration form row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstCtl,
                    decoration: InputDecoration(labelText: 'Nombre'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lastCtl,
                    decoration: InputDecoration(labelText: 'Apellido'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!loading) _register();
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: loading ? null : _register, child: Text('Registrar')),
              ],
            ),
            SizedBox(height: 18),
            // Attendees list area
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator())
                  : attendees.isEmpty
                      ? Center(child: Text('No hay asistentes registrados aún', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          itemCount: attendees.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = attendees[i];
                            final registeredAt = a['registered_at'];
                            String subtitle = '';
                            try {
                              if (registeredAt != null) {
                                subtitle = DateTime.parse(registeredAt).toLocal().toString();
                              }
                            } catch (_) {
                              subtitle = registeredAt?.toString() ?? '';
                            }
                            return ListTile(
                              title: Text('${a['first_name']} ${a['last_name']}'),
                              subtitle: Text('Registrado: $subtitle'),
                            );
                          },
                        ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final count = attendees.length;
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Conteo final'),
                    content: Text('Asistieron $count personas. ¿Deseas guardar este registro?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar')),
                    ],
                  ),
                );
              },
              child: Text('Mostrar conteo final'),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(40)),
            ),
          ],
        ),
      ),
    );
  }
}
