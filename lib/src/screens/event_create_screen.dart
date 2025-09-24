// lib/src/screens/event_create_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen to create a new event. UI in Spanish, code comments in English.
class EventCreateScreen extends StatefulWidget {
  @override
  _EventCreateScreenState createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _expectedCtl = TextEditingController(text: '0');
  DateTime? _selectedDateTime;
  bool _saving = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: 365)),
      lastDate: now.add(Duration(days: 365 * 5)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Save event using Supabase client.
  /// Uses .select() after insert to ensure the server returns the inserted row.
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seleccione fecha y hora')));
      return;
    }

    setState(() => _saving = true);

    try {
      final client = Supabase.instance.client;

      // Insert + select to force returned representation
      final res = await client.from('events').insert({
        'name': _nameCtl.text.trim(),
        'description': _descCtl.text.trim(),
        'expected_attendees': int.tryParse(_expectedCtl.text.trim()) ?? 0,
        'start_at': _selectedDateTime!.toUtc().toIso8601String(),
        'status': 'scheduled',
      }).select().execute();

      // Debug / diagnostics
      debugPrint('Insert response status: ${res.status}');
      debugPrint('Insert response count: ${res.count}');
      debugPrint('Insert response data: ${res.data}');

      if (res.data == null) {
        // Provide helpful error info
        throw Exception('Insert returned no data. Status: ${res.status ?? 'unknown'}');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evento creado')));
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      debugPrint('Supabase PostgrestException creating event: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear evento: ${e.message}')));
    } catch (e) {
      debugPrint('Unknown error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear evento')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _expectedCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDateTime == null
        ? 'Seleccionar fecha y hora'
        : DateFormat('dd MMM yyyy — HH:mm').format(_selectedDateTime!.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear evento', style: TextStyle(color: Theme.of(context).primaryColor)),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: InputDecoration(labelText: 'Nombre del evento'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese un nombre' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descCtl,
                decoration: InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _expectedCtl,
                decoration: InputDecoration(labelText: 'Número esperado de asistentes'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Ingrese un número' : null,
              ),
              SizedBox(height: 12),
              ListTile(
                onTap: _pickDateTime,
                tileColor: Colors.transparent,
                title: Text(dateStr),
                trailing: Icon(Icons.calendar_today),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _saveEvent,
                child: _saving
                    ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Crear evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
