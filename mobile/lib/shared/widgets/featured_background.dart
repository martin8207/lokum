import 'package:flutter/material.dart';

import '../../core/asset_paths.dart';
import '../../core/constants/schedule.dart';

/// Фонови снимки по седмично разписание - автоматично се показват и махат
/// сами, синхронизирано с реалните повтарящи се събития (Брънч, Викторина).
/// За да добавиш ново разписание/снимка, просто добави нов ред тук - няма
/// нужда от ръчна дата за "изтича на", както преди.
const List<(WeeklySchedule, String)> _scheduledBackgrounds = [
  (
    WeeklySchedule(weekday: DateTime.sunday, startHour: 11, endHour: 16),
    AssetPaths.featuredBackgroundSunday,
  ),
  (
    WeeklySchedule(weekday: DateTime.monday, startHour: 19, endHour: 22),
    AssetPaths.featuredBackgroundMonday,
  ),
];

/// Еднократни поводи, вързани за конкретна календарна дата (не се повтарят
/// седмично) - виж [DateSchedule]. Проверяват се с приоритет пред
/// седмичните разписания.
const List<(DateSchedule, String)> _oneOffBackgrounds = [
  (
    DateSchedule(year: 2026, month: 8, day: 7), // Международен ден на бирата
    AssetPaths.featuredBackgroundBeerDay,
  ),
];

/// Слага текущата активна фонова снимка (по [_scheduledBackgrounds]) зад
/// [child], с притъмняващ градиент отгоре за четимост на текста. Ако няма
/// активно разписание в момента (или файлът липсва), просто връща [child]
/// непроменен.
class FeaturedBackground extends StatelessWidget {
  final Widget child;

  const FeaturedBackground({super.key, required this.child});

  String? _activeBackgroundPath() {
    final now = DateTime.now();
    for (final (schedule, assetPath) in _oneOffBackgrounds) {
      if (schedule.isActiveAt(now) && BundledAssets.has(assetPath)) {
        return assetPath;
      }
    }
    for (final (schedule, assetPath) in _scheduledBackgrounds) {
      if (schedule.isActiveAt(now) && BundledAssets.has(assetPath)) {
        return assetPath;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPath = _activeBackgroundPath();
    if (backgroundPath == null) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(backgroundPath, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
