/// Седмичен времеви прозорец, в който дадена подкатегория/продукт се
/// предлага (напр. Брънч — само в неделя, 11:00–16:00). Проверката е спрямо
/// системната дата и час на устройството ([DateTime.now]).
library;

import '../../shared/models/product.dart';

class WeeklySchedule {
  /// [DateTime.monday]..[DateTime.sunday].
  final int weekday;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const WeeklySchedule({
    required this.weekday,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
  });

  bool isActiveAt(DateTime now) {
    if (now.weekday != weekday) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  bool get isActiveNow => isActiveAt(DateTime.now());

  static const _weekdaysBg = [
    'понеделник',
    'вторник',
    'сряда',
    'четвъртък',
    'петък',
    'събота',
    'неделя',
  ];
  static const _weekdaysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Напр. "неделя, 11:00 – 16:00 ч." / "Sunday, 11:00 – 16:00".
  String label(AppLang lang) {
    final day = lang == AppLang.bg
        ? _weekdaysBg[weekday - 1]
        : _weekdaysEn[weekday - 1];
    final start = _time(startHour, startMinute);
    final end = _time(endHour, endMinute);
    return lang == AppLang.bg
        ? '$day, $start – $end ч.'
        : '$day, $start – $end';
  }
}

/// Годишен повод, вързан за "първия [ден от седмицата] от [месец]" - напр.
/// Международен ден на бирата = първи петък на август. Изчислява
/// конкретната дата динамично за текущата година, така че работи
/// автоматично всяка година, без ръчна поддръжка.
class AnnualFirstWeekdaySchedule {
  final int month;

  /// [DateTime.monday]..[DateTime.sunday].
  final int weekday;

  const AnnualFirstWeekdaySchedule({required this.month, required this.weekday});

  bool isActiveAt(DateTime now) {
    if (now.month != month) return false;
    var d = DateTime(now.year, month, 1);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return now.day == d.day;
  }

  bool get isActiveNow => isActiveAt(DateTime.now());
}

/// Разписание по subcategoryId — засега само Брънч (само в неделя).
const Map<String, WeeklySchedule> kSubcategorySchedules = {
  'brunch': WeeklySchedule(
    weekday: DateTime.sunday,
    startHour: 11,
    endHour: 16,
  ),
};

class ProductAvailability {
  ProductAvailability._();

  static WeeklySchedule? scheduleFor(Product product) =>
      kSubcategorySchedules[product.subcategoryId];

  /// Дали продуктът се предлага точно сега според разписанието (продукти без
  /// разписание винаги минават за "предлагат се сега").
  static bool isOfferedNow(Product product) {
    final schedule = scheduleFor(product);
    if (schedule == null) return true;
    return schedule.isActiveNow;
  }
}
