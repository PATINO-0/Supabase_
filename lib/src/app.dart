// lib/src/app.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import 'screens/events_list_screen.dart';

class EventTableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventTable',
      theme: appTheme,
      home: EventsListScreen(),
    );
  }
}
