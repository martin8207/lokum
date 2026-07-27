import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/product.dart';

/// Малък BG/EN превключвател. Чете/пише директно в [AppLanguage.instance],
/// така че всички екрани, слушащи го, се обновяват веднага.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangOption(
                label: 'БГ',
                selected: lang == AppLang.bg,
                onTap: () => AppLanguage.instance.value = AppLang.bg,
              ),
              _LangOption(
                label: 'EN',
                selected: lang == AppLang.en,
                onTap: () => AppLanguage.instance.value = AppLang.en,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? theme.colorScheme.onPrimary : theme.hintColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
