import '../../core/constants/schedule.dart';
import 'product.dart' show AppLang;

/// Събитие в бара – предстоящо (постер) или минало (снимки от галерията).
/// Може да е еднократно (с фиксирана [date]) или повтарящо се всяка седмица
/// (с [recurring] разписание, напр. неделния Брънч).
class BarEvent {
  final String id;
  final String titleBg;
  final String titleEn;

  /// Кратък текст за картата в списъка - трябва да се събира на един ред
  /// без изрязване (напр. "Всяка понеделник вечер"). Пълното описание
  /// излиза само в detail екрана, никога на картата.
  final String? cardSubtitleBg;
  final String? cardSubtitleEn;

  final String? descriptionBg;
  final String? descriptionEn;

  /// Телефон за връзка/записвания, показван като tappable `tel:` линк в
  /// detail екрана.
  final String? phone;

  final DateTime? date;
  final WeeklySchedule? recurring;
  final String? posterImage;

  /// По-голямо лого/изображение на самото събитие, показвано в detail
  /// екрана (отделно от [posterImage], който е за картата в списъка).
  final String? logoImage;

  final List<String> galleryImages;

  /// Линкове към социални мрежи/платформи за слушане - показват се като
  /// tappable икони в detail екрана (само тези, които са зададени).
  final String? instagramUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String? spotifyUrl;
  final String? appleMusicUrl;

  /// Само за архивни събития: показва картата като квадратно изображение
  /// (като "Нещо за хапване" картите), без текстов ред до нея - за събития
  /// без отделно описание, само снимка.
  final bool squareCard;

  /// Само за предстоящи събития: показва картата на цяла ширина (2x по-
  /// широка от стандартните карти в 2-колонния grid), с целия постер
  /// видим (без изрязване) - за специални концерти/събития, които трябва
  /// да се набиват на очи. Виж [FeaturedEventCard].
  final bool featured;

  const BarEvent({
    required this.id,
    required this.titleBg,
    required this.titleEn,
    this.cardSubtitleBg,
    this.cardSubtitleEn,
    this.descriptionBg,
    this.descriptionEn,
    this.phone,
    this.date,
    this.recurring,
    this.posterImage,
    this.logoImage,
    this.galleryImages = const [],
    this.instagramUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.spotifyUrl,
    this.appleMusicUrl,
    this.squareCard = false,
    this.featured = false,
  });

  String title(AppLang lang) => lang == AppLang.bg ? titleBg : titleEn;

  String? description(AppLang lang) {
    final value = lang == AppLang.bg ? descriptionBg : descriptionEn;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Кратък subtitle за картата - fallback към [description] само ако
  /// изрично зададен cardSubtitle липсва, за съвместимост със стари данни.
  String? cardSubtitle(AppLang lang) {
    final value = lang == AppLang.bg ? cardSubtitleBg : cardSubtitleEn;
    if (value != null && value.isNotEmpty) return value;
    return description(lang);
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

  /// Кратка дата без час, за архивните карти (напр. "25 юли 2026").
  String? formattedDateShort(AppLang lang) {
    final d = date;
    if (d == null) return null;
    final months = lang == AppLang.bg ? _monthsBg : _monthsEn;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  factory BarEvent.fromJson(Map<String, dynamic> json) {
    return BarEvent(
      id: json['id'] as String,
      titleBg: json['titleBg'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      cardSubtitleBg: json['cardSubtitleBg'] as String?,
      cardSubtitleEn: json['cardSubtitleEn'] as String?,
      descriptionBg: json['descriptionBg'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      phone: json['phone'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      recurring: _recurringFromJson(json),
      posterImage: json['posterImage'] as String?,
      logoImage: json['logoImage'] as String?,
      galleryImages:
          (json['galleryImages'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      tiktokUrl: json['tiktokUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      spotifyUrl: json['spotifyUrl'] as String?,
      appleMusicUrl: json['appleMusicUrl'] as String?,
      squareCard: json['squareCard'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
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
