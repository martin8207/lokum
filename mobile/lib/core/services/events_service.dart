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
    // "upcoming"/"past" в events.json са само за удобство при редакция -
    // кой бъкет наистина важи се решава ТУК, по дата, при всяко зареждане.
    // Иначе събитие като Greesh (23.08) си остава завинаги в "Предстоящи"
    // след като мине, докато някой ръчно не го премести в JSON-а (виж
    // Sprint 3, бележка 3).
    final all = [
      ...upcomingJson.map((e) => BarEvent.fromJson(e as Map<String, dynamic>)),
      ...pastJson.map((e) => BarEvent.fromJson(e as Map<String, dynamic>)),
    ];
    final now = DateTime.now();

    final upcoming = all.where((e) => _isUpcoming(e, now)).toList()
      ..sort((a, b) {
        final aDate = a.date;
        final bDate = b.date;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1; // повтарящи се - най-накрая
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    final past = all.where((e) => !_isUpcoming(e, now)).toList();

    return Events(upcoming: upcoming, past: past);
  }

  // Еднократно събитие е "предстоящо", докато не мине началният му час.
  // Повтарящо се (без фиксирана date, само седмично разписание) е винаги
  // предстоящо - никога не "изтича" в архива.
  static bool _isUpcoming(BarEvent event, DateTime now) {
    final date = event.date;
    if (date == null) return event.recurring != null;
    return date.isAfter(now);
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
