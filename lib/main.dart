// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app.dart';
import 'theme.dart';

/// Initialize the app reading Supabase config from .env
/// Comments are in English. UI strings are Spanish.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (create .env in project root using .env.example)
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    // If env vars are missing we stop and instruct the developer.
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env. Copy .env.example to .env and fill values.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(EventTableApp());
}
