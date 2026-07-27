import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/asset_paths.dart';
import '../../../shared/models/product.dart';

/// Ред за категория от най-високо ниво (Нещо за хапване / Коктейли / Напитки).
/// Стил на менюто: фон = accent, текст = background (виж design spec).
class CategoryCard extends StatelessWidget {
  final MenuCategory category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  IconData get _icon {
    switch (category.id) {
      case 'food':
        return Icons.restaurant_menu;
      case 'cocktails':
        return Icons.local_bar;
      case 'drinks':
        return Icons.local_cafe;
      case 'shakes':
        return Icons.icecream;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Card(
          elevation: 0,
          color: colors.menuCardBackground,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            hoverColor: colors.hoverOnMenuCard,
            splashColor: colors.splashOnMenuCard,
            leading: Icon(_icon, color: colors.menuCardText),
            title: Text(
              category.name(lang),
              style: TextStyle(
                fontSize: 18,
                color: colors.menuCardText,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${category.productCount} ${lang == AppLang.bg ? "продукта" : "items"}',
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
