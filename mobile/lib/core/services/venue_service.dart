/// Зарежда и кешира информацията за бара от `venue.json` + `config.json`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../shared/models/venue.dart';

class VenueService {
  VenueService._();

  static final VenueService instance = VenueService._();

  static const String _venuePath = 'assets/data/venue.json';
  static const String _configPath = 'assets/data/config.json';

  VenueInfo? _cached;

  Future<VenueInfo> loadVenue({bool forceReload = false}) async {
    if (_cached != null && !forceReload) {
      return _cached!;
    }
    final venueRaw = await rootBundle.loadString(_venuePath);
    final configRaw = await rootBundle.loadString(_configPath);
    final venueJson = jsonDecode(venueRaw) as Map<String, dynamic>;
    final configJson = jsonDecode(configRaw) as Map<String, dynamic>;
    final venue = VenueInfo.merge(venueJson, configJson);
    _cached = venue;
    return venue;
  }
}
