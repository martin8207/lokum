import 'product.dart' show AppLang;

/// Данни за бара – взети от `venue.json` (адрес, контакти, работно време),
/// допълнени от `config.json` (слоган, град) там, където `venue.json` е празен.
class WorkingHours {
  final String monday;
  final String tuesday;
  final String wednesday;
  final String thursday;
  final String friday;
  final String saturday;
  final String sunday;

  const WorkingHours({
    this.monday = '',
    this.tuesday = '',
    this.wednesday = '',
    this.thursday = '',
    this.friday = '',
    this.saturday = '',
    this.sunday = '',
  });

  bool get isEmpty =>
      monday.isEmpty &&
      tuesday.isEmpty &&
      wednesday.isEmpty &&
      thursday.isEmpty &&
      friday.isEmpty &&
      saturday.isEmpty &&
      sunday.isEmpty;

  factory WorkingHours.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WorkingHours();
    return WorkingHours(
      monday: json['monday'] as String? ?? '',
      tuesday: json['tuesday'] as String? ?? '',
      wednesday: json['wednesday'] as String? ?? '',
      thursday: json['thursday'] as String? ?? '',
      friday: json['friday'] as String? ?? '',
      saturday: json['saturday'] as String? ?? '',
      sunday: json['sunday'] as String? ?? '',
    );
  }
}

class VenueInfo {
  final String name;
  final String slogan;
  final String description;
  final String addressBg;
  final String addressEn;
  final String phone;
  final String email;
  final String website;
  final String facebook;
  final String instagram;
  final WorkingHours workingHours;
  final double latitude;
  final double longitude;

  const VenueInfo({
    this.name = 'Lokum',
    this.slogan = '',
    this.description = '',
    this.addressBg = '',
    this.addressEn = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.facebook = '',
    this.instagram = '',
    this.workingHours = const WorkingHours(),
    this.latitude = 0,
    this.longitude = 0,
  });

  /// Обединява `venue.json` (основен източник) с `config.json` (fallback за
  /// полетата, които `venue.json` все още няма, напр. слоган).
  factory VenueInfo.merge(
    Map<String, dynamic> venueJson,
    Map<String, dynamic> configJson,
  ) {
    final restaurant =
        configJson['restaurant'] as Map<String, dynamic>? ?? const {};
    String pick(String? venueValue, String? configValue) {
      if (venueValue != null && venueValue.isNotEmpty) return venueValue;
      return configValue ?? '';
    }

    final location = venueJson['location'] as Map<String, dynamic>? ?? const {};

    return VenueInfo(
      name: pick(venueJson['name'] as String?, restaurant['name'] as String?),
      slogan: restaurant['slogan'] as String? ?? '',
      description: venueJson['description'] as String? ?? '',
      addressBg: venueJson['addressBg'] as String? ?? '',
      addressEn: venueJson['addressEn'] as String? ?? '',
      phone: pick(
        venueJson['phone'] as String?,
        restaurant['phone'] as String?,
      ),
      email: pick(
        venueJson['email'] as String?,
        restaurant['email'] as String?,
      ),
      website: pick(
        venueJson['website'] as String?,
        restaurant['website'] as String?,
      ),
      facebook: pick(
        venueJson['facebook'] as String?,
        restaurant['facebook'] as String?,
      ),
      instagram: pick(
        venueJson['instagram'] as String?,
        restaurant['instagram'] as String?,
      ),
      workingHours: WorkingHours.fromJson(
        venueJson['workingHours'] as Map<String, dynamic>?,
      ),
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  String address(AppLang lang) => lang == AppLang.bg ? addressBg : addressEn;
}
