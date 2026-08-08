/// Глобални runtime флагове от `assets/data/config.json`, независими от
/// venue.json обединяването във [VenueService] - засега само дали цените
/// да се показват (`showPrices: false` за случаи като частно събитие, за
/// които не се показват цени за вечерта).
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  AppConfig._();

  static bool _showPrices = true;

  static Future<void> ensureLoaded() async {
    try {
      final raw = await rootBundle.loadString('assets/data/config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _showPrices = json['showPrices'] as bool? ?? true;
    } catch (_) {
      _showPrices = true;
    }
  }

  static bool get showPrices => _showPrices;
}
