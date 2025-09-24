// lib/src/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseService: central place to interact with Supabase
/// Updated to handle PostgrestException (newer supabase client behavior).
class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  /// Create event in 'events' table
  Future<Map<String, dynamic>> createEvent({
    required String name,
    required String description,
    required DateTime startAt,
    required int expectedAttendees,
  }) async {
    try {
      final res = await client.from('events').insert({
        'name': name,
        'description': description,
        'start_at': startAt.toUtc().toIso8601String(),
        'expected_attendees': expectedAttendees,
        'status': 'scheduled',
      }).execute();

      // res.data contains the created row(s)
      if (res.data == null) {
        throw Exception('No data returned from insert');
      }

      // Return the first inserted row as map
      final List<dynamic> rows = res.data as List<dynamic>;
      return Map<String, dynamic>.from(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Bubble up a helpful message
      throw Exception('Supabase error creating event: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error creating event: $e');
    }
  }

  /// Fetch all events ordered by date
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    try {
      final res = await client.from('events').select().order('start_at', ascending: true).execute();
      final data = res.data;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Supabase error fetching events: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error fetching events: $e');
    }
  }

  /// Start event: update status to 'started'
  Future<void> startEvent(String eventId) async {
    try {
      await client.from('events').update({'status': 'started'}).eq('id', eventId).execute();
    } on PostgrestException catch (e) {
      throw Exception('Supabase error starting event: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error starting event: $e');
    }
  }

  /// Finish event: update status to 'finished'
  Future<void> finishEvent(String eventId) async {
    try {
      await client.from('events').update({'status': 'finished'}).eq('id', eventId).execute();
    } on PostgrestException catch (e) {
      throw Exception('Supabase error finishing event: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error finishing event: $e');
    }
  }

  /// Register attendee for an event
  Future<Map<String, dynamic>> registerAttendee({
    required String eventId,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final res = await client.from('attendees').insert({
        'event_id': eventId,
        'first_name': firstName,
        'last_name': lastName,
      }).execute();

      if (res.data == null) throw Exception('No data returned from insert attendee');

      final rows = res.data as List<dynamic>;
      return Map<String, dynamic>.from(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Supabase error registering attendee: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error registering attendee: $e');
    }
  }

  /// Fetch attendees for event
  Future<List<Map<String, dynamic>>> fetchAttendees(String eventId) async {
    try {
      final res = await client.from('attendees').select().eq('event_id', eventId).order('registered_at', ascending: true).execute();
      final data = res.data;
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Supabase error fetching attendees: ${e.message}');
    } catch (e) {
      throw Exception('Unknown error fetching attendees: $e');
    }
  }
}
