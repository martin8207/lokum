import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../widgets/subcategory_card.dart';
import 'product_list_page.dart';

/// Показва подкатегориите на избраната категория (напр. за "Напитки":
/// Ободряващи, Безалкохолни, Алкохолни, Шотове, Бира, Вино, Други).
class SubcategoryPage extends StatelessWidget {
  final MenuCategory category;

  const SubcategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(category.name(lang)),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: category.subcategories.isEmpty
              ? Center(
                  child: Text(
                    lang == AppLang.bg
                        ? 'Няма подкатегории.'
                        : 'No subcategories.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: category.subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = category.subcategories[index];
                    return SubcategoryCard(
                      subcategory: subcategory,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductListPage(
                              category: category,
                              subcategory: subcategory,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
