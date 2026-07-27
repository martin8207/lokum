import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Малък бутон за смяна на Light/Dark режим (слънце/луна).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeMode.instance,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return InkWell(
          onTap: AppThemeMode.toggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 18,
              color: colors.accent,
            ),
          ),
        );
      },
    );
  }
}
