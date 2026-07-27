import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/schedule.dart';
import '../../../shared/models/product.dart';

/// Показва кога дадена подкатегория/продукт се предлага (напр. Брънч — само
/// в неделя, 11:00–16:00) и дали точно сега е активно, спрямо системния час.
class ScheduleBanner extends StatelessWidget {
  final WeeklySchedule schedule;
  final AppLang lang;
  final EdgeInsetsGeometry margin;

  const ScheduleBanner({
    super.key,
    required this.schedule,
    required this.lang,
    this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = schedule.isActiveNow;
    final statusColor = isActive ? const Color(0xFF3DBE6C) : colors.textMuted;
    final statusText = isActive
        ? (lang == AppLang.bg
              ? 'Сервира се точно сега'
              : 'Being served right now')
        : (lang == AppLang.bg
              ? 'Извън часовете на брънч'
              : 'Outside brunch hours');

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 20, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLang.bg
                      ? 'Само в ${schedule.label(lang)}'
                      : 'Only on ${schedule.label(lang)}',
                  style: TextStyle(
                    color: colors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
