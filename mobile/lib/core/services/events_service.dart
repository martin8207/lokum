/// Зарежда и кешира събитията на бара от локалния asset `events.json`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../shared/models/event.dart';

class Events {
  final List<BarEvent> upcoming;
  final List<BarEvent> past;

  const Events({this.upcoming = const [], this.past = const []});

  factory Events.fromJson(Map<String, dynamic> json) {
    final upcomingJson = (json['upcoming'] as List? ?? const []);
    final pastJson = (json['past'] as List? ?? const []);
    return Events(
      upcoming: upcomingJson
          .map((e) => BarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      past: pastJson
          .map((e) => BarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventsService {
  EventsService._();

  static final EventsService instance = EventsService._();

  static const String _path = 'assets/data/events.json';

  Events? _cached;

  Future<Events> loadEvents({bool forceReload = false}) async {
    if (_cached != null && !forceReload) {
      return _cached!;
    }
    final raw = await rootBundle.loadString(_path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final events = Events.fromJson(json);
    _cached = events;
    return events;
  }
}
