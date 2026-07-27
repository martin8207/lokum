import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/asset_paths.dart';
import '../../../core/constants/schedule.dart';
import '../../../shared/models/product.dart';

/// Ред за подкатегория (напр. "Бира", "Шотове") в списъка на категорията.
/// Стил на менюто: фон = accent, текст = background (виж design spec).
class SubcategoryCard extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onTap;

  const SubcategoryCard({
    super.key,
    required this.subcategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final schedule = kSubcategorySchedules[subcategory.id];
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final countLabel =
            '${subcategory.availableCount} ${lang == AppLang.bg ? "продукта" : "items"}';
        return Card(
          elevation: 0,
          color: colors.menuCardBackground,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            hoverColor: colors.hoverOnMenuCard,
            splashColor: colors.splashOnMenuCard,
            title: Text(
              subcategory.name(lang),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.menuCardText,
              ),
            ),
            subtitle: Text(
              schedule == null
                  ? countLabel
                  : '$countLabel · ${schedule.label(lang)}',
              style: TextStyle(
                color: colors.menuCardText.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.menuCardText),
            onTap: onTap,
          ),
        );
      },
    );
  }
}
