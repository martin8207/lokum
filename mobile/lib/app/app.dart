import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/onboarding/language_select_page.dart';

class LokumApp extends StatelessWidget {
  const LokumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeMode.instance,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Lokum',

          debugShowCheckedModeBanner: false,

          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,

          // Единен фонов градиент зад всеки екран — теми-осъзнат: преливащ
          // тъмно лилав в dark, плосък жълт в light (виж design spec).
          builder: (context, child) {
            final colors = context.colors;
            return DecoratedBox(
              decoration: BoxDecoration(gradient: colors.backgroundGradient),
              child: child ?? const SizedBox.shrink(),
            );
          },

          home: const LanguageSelectPage(),
        );
      },
    );
  }
}
