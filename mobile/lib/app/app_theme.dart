/// Light/Dark тема на LOKUM, по спецификацията в
/// `database/lokum-design-spec.md`. Ролите на цветовете (фон, повърхност,
/// акцент, акцент 2, основен/приглушен текст) се четат навсякъде през
/// [LokumColors] — темата се сменя динамично чрез [AppThemeMode].
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Display шрифт за заглавия/лого-моменти (страница-заглавия, думата
/// LOKUM) — по-характерен, близък по дух до "разтопените" букви на логото.
/// Поддържа кирилица и латиница.
TextStyle brandTextStyle({
  required Color color,
  double fontSize = 20,
  FontWeight fontWeight = FontWeight.w600,
}) {
  return GoogleFonts.unbounded(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

/// Цветови роли на LOKUM, теми-осъзнати (различни за light/dark — не е просто
/// разменени стойности, виж design spec).
class LokumColors extends ThemeExtension<LokumColors> {
  final Color background;

  /// Долен цвят на фоновия градиент. За light режим е same-as-[background]
  /// (плосък цвят, без преливане) — градиентът е само за dark режим, взет от
  /// фона на логото.
  final Color backgroundGradientEnd;
  final Color surface;
  final Color accent;
  final Color accent2;
  final Color textMain;
  final Color textMuted;
  final Color border;

  const LokumColors({
    required this.background,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.accent,
    required this.accent2,
    required this.textMain,
    required this.textMuted,
    required this.border,
  });

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundGradientEnd],
  );

  /// Фон/текст на "менюто" (категории/подкатегории/продукти): по спецификация
  /// фонът е [accent], текстът е [background] — в dark режим това е
  /// познатото златно поле с тъмно лилав текст; в light режим е лилаво поле
  /// с жълт текст.
  Color get menuCardBackground => accent;
  Color get menuCardText => background;

  /// Hover/press фейд за редовете с фон [surface] (начален екран, контакти).
  Color get hoverOnSurface => textMain.withValues(alpha: 0.06);
  Color get splashOnSurface => textMain.withValues(alpha: 0.14);

  /// Hover/press фейд за "менюто" картите — [menuCardText] върху
  /// [menuCardBackground], защото акцентен тон върху акцентен фон не се вижда.
  Color get hoverOnMenuCard => menuCardText.withValues(alpha: 0.10);
  Color get splashOnMenuCard => menuCardText.withValues(alpha: 0.20);

  static const light = LokumColors(
    background: Color(0xFFC9982E),
    backgroundGradientEnd: Color(0xFFFFFFFF),
    surface: Color(0xFFE3B23C),
    accent: Color(0xFF3A1F5C),
    accent2: Color(0xFF3A1F5C),
    textMain: Color(0xFF241A3D),
    textMuted: Color(0xFF6B5A85),
    border: Color(0x264C1D7C),
  );

  static const dark = LokumColors(
    background: Color(0xFF17102B),
    backgroundGradientEnd: Color(0xFF3A1F5C),
    surface: Color(0xFF241A3D),
    accent: Color(0xFFE3B23C),
    accent2: Color(0xFFE3B23C),
    textMain: Color(0xFFF0E9FF),
    textMuted: Color(0xFFB3A3D9),
    border: Color(0x33E3B23C),
  );

  @override
  LokumColors copyWith({
    Color? background,
    Color? backgroundGradientEnd,
    Color? surface,
    Color? accent,
    Color? accent2,
    Color? textMain,
    Color? textMuted,
    Color? border,
  }) {
    return LokumColors(
      background: background ?? this.background,
      backgroundGradientEnd:
          backgroundGradientEnd ?? this.backgroundGradientEnd,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
    );
  }

  @override
  LokumColors lerp(ThemeExtension<LokumColors>? other, double t) {
    if (other is! LokumColors) return this;
    return LokumColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundGradientEnd: Color.lerp(
        backgroundGradientEnd,
        other.backgroundGradientEnd,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Помощник за бърз достъп: `context.colors.accent` вместо
/// `Theme.of(context).extension<LokumColors>()!.accent`.
extension LokumColorsContext on BuildContext {
  LokumColors get colors => Theme.of(this).extension<LokumColors>()!;
}

ThemeData _buildTheme(LokumColors colors, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      primary: colors.accent,
      secondary: colors.accent2,
      surface: colors.surface,
      onSurface: colors.textMain,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: colors.textMain,
      titleTextStyle: brandTextStyle(color: colors.textMain),
    ),
    // Nunito — заоблен, четим, пълна поддръжка на кирилица и латиница;
    // близък по дух до "bubbly" усещането на логото, но четим и в дълъг текст
    // (описания на продукти, работно време и т.н.).
    textTheme: GoogleFonts.nunitoTextTheme(
      Typography.material2021().black,
    ).apply(bodyColor: colors.textMain, displayColor: colors.textMain),
    // Изрично зададен, за да съвпада сигурно с шрифта на менюто/продуктовите
    // карти (Nunito, от textTheme по-горе) - без да разчитаме на default
    // изведеното от Material за табовете.
    tabBarTheme: TabBarThemeData(
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
    ),
    hintColor: colors.textMuted,
    useMaterial3: true,
    extensions: [colors],
  );
}

ThemeData buildLightTheme() => _buildTheme(LokumColors.light, Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(LokumColors.dark, Brightness.dark);

/// Избор на Light/Dark режим, запомнен между сесиите (per design spec —
/// еквивалент на `localStorage` избора в HTML прототипа).
class AppThemeMode {
  AppThemeMode._();

  static const _prefsKey = 'lokum_theme_mode';

  static final ValueNotifier<ThemeMode> instance = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  static Future<void> ensureLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'light') {
      instance.value = ThemeMode.light;
    } else if (saved == 'dark') {
      instance.value = ThemeMode.dark;
    }
    instance.addListener(_persist);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      instance.value == ThemeMode.light ? 'light' : 'dark',
    );
  }

  static void toggle() {
    instance.value = instance.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}
