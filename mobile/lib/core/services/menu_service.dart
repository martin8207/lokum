/// Зарежда и кешира менюто на бара от локалния asset `menu.json`
/// (генериран от `tools/excel_to_json.py`).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../asset_paths.dart';
import '../../shared/models/product.dart';

class MenuService {
  MenuService._();

  static final MenuService instance = MenuService._();

  Menu? _cachedMenu;

  /// Дали менюто вече е заредено в паметта.
  bool get isLoaded => _cachedMenu != null;

  /// Зарежда menu.json от assets (само веднъж, освен ако `forceReload: true`).
  Future<Menu> loadMenu({bool forceReload = false}) async {
    if (_cachedMenu != null && !forceReload) {
      return _cachedMenu!;
    }
    final raw = await rootBundle.loadString(AssetPaths.menuJson);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final menu = Menu.fromJson(json);
    _cachedMenu = menu;
    return menu;
  }

  /// Синхронен достъп до вече заредено меню. Хвърля, ако още не е заредено –
  /// извикайте `loadMenu()` първо (напр. в `menu_page.dart`).
  Menu get menu {
    final cached = _cachedMenu;
    if (cached == null) {
      throw StateError(
        'MenuService.menu е достъпен само след loadMenu(). '
        'Извикайте await MenuService.instance.loadMenu() първо.',
      );
    }
    return cached;
  }

  MenuCategory? findCategoryById(String id) {
    for (final c in menu.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Subcategory? findSubcategory(String categoryId, String subcategoryId) {
    final category = findCategoryById(categoryId);
    if (category == null) return null;
    for (final s in category.subcategories) {
      if (s.id == subcategoryId) return s;
    }
    return null;
  }

  Product? findProductById(String productId) {
    for (final c in menu.categories) {
      for (final s in c.subcategories) {
        for (final p in s.products) {
          if (p.id == productId) return p;
        }
      }
    }
    return null;
  }

  /// Прост текстов търсач по локализирано име (case-insensitive).
  List<Product> searchProducts(String query, AppLang lang) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <Product>[];
    for (final c in menu.categories) {
      for (final s in c.subcategories) {
        for (final p in s.products) {
          if (p.name(lang).toLowerCase().contains(q)) {
            results.add(p);
          }
        }
      }
    }
    return results;
  }
}
