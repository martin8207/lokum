import '../../core/constants/schedule.dart';
import 'product.dart' show AppLang;

/// Събитие в бара – предстоящо (постер) или минало (снимки от галерията).
/// Може да е еднократно (с фиксирана [date]) или повтарящо се всяка седмица
/// (с [recurring] разписание, напр. неделния Брънч).
class BarEvent {
  final String id;
  final String titleBg;
  final String titleEn;
  final String? descriptionBg;
  final String? descriptionEn;
  final DateTime? date;
  final WeeklySchedule? recurring;
  final String? posterImage;
  final List<String> galleryImages;

  const BarEvent({
    required this.id,
    required this.titleBg,
    required this.titleEn,
    this.descriptionBg,
    this.descriptionEn,
    this.date,
    this.recurring,
    this.posterImage,
    this.galleryImages = const [],
  });

  String title(AppLang lang) => lang == AppLang.bg ? titleBg : titleEn;

  String? description(AppLang lang) {
    final value = lang == AppLang.bg ? descriptionBg : descriptionEn;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// За повтарящи се събития: дали точно сега се провежда.
  bool get isHappeningNow => recurring?.isActiveNow ?? false;

  static const _monthsBg = [
    'януари',
    'февруари',
    'март',
    'април',
    'май',
    'юни',
    'юли',
    'август',
    'септември',
    'октомври',
    'ноември',
    'декември',
  ];
  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Форматирана дата, напр. "1 август 2026, 20:00", или — за повтарящи се
  /// събития — седмичното разписание, напр. "Всяка неделя, 11:00 – 16:00 ч.".
  String? formattedDate(AppLang lang) {
    final d = date;
    if (d != null) {
      final months = lang == AppLang.bg ? _monthsBg : _monthsEn;
      final time =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return '${d.day} ${months[d.month - 1]} ${d.year}, $time';
    }
    final schedule = recurring;
    if (schedule != null) {
      return lang == AppLang.bg
          ? 'Всяка ${schedule.label(lang)}'
          : 'Every ${schedule.label(lang)}';
    }
    return null;
  }

  factory BarEvent.fromJson(Map<String, dynamic> json) {
    return BarEvent(
      id: json['id'] as String,
      titleBg: json['titleBg'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      descriptionBg: json['descriptionBg'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      recurring: _recurringFromJson(json),
      posterImage: json['posterImage'] as String?,
      galleryImages:
          (json['galleryImages'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  static WeeklySchedule? _recurringFromJson(Map<String, dynamic> json) {
    final weekday = json['recurringWeekday'] as int?;
    final start = json['recurringStart'] as String?;
    final end = json['recurringEnd'] as String?;
    if (weekday == null || start == null || end == null) return null;
    final startParts = start.split(':');
    final endParts = end.split(':');
    return WeeklySchedule(
      weekday: weekday,
      startHour: int.parse(startParts[0]),
      startMinute: startParts.length > 1 ? int.parse(startParts[1]) : 0,
      endHour: int.parse(endParts[0]),
      endMinute: endParts.length > 1 ? int.parse(endParts[1]) : 0,
    );
  }
}
