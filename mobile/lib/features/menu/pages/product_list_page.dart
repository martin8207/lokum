import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../core/constants/schedule.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../../order/widgets/order_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/schedule_banner.dart';
import 'product_details_page.dart';

/// Показва продуктите в избраната подкатегория (напр. всички бири).
class ProductListPage extends StatelessWidget {
  final MenuCategory category;
  final Subcategory subcategory;

  const ProductListPage({
    super.key,
    required this.category,
    required this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        // Ред: Featured (напр. Гларус) първи, после наличните преди
        // изчерпаните, после със снимка преди тези без, после азбучно на
        // текущия избран език - независимо от реда им в Excel-а, автоматично
        // за всеки нов продукт.
        final products = [...subcategory.products]
          ..sort((a, b) {
            if (a.featured != b.featured) return a.featured ? -1 : 1;
            if (a.available != b.available) return a.available ? -1 : 1;
            final aHasImage = BundledAssets.has(
              AssetPaths.productImage(a.image),
            );
            final bHasImage = BundledAssets.has(
              AssetPaths.productImage(b.image),
            );
            if (aHasImage != bHasImage) return aHasImage ? -1 : 1;
            return a
                .name(lang)
                .toLowerCase()
                .compareTo(b.name(lang).toLowerCase());
          });
        final schedule = kSubcategorySchedules[subcategory.id];
        return Scaffold(
          appBar: AppBar(
            title: Text(subcategory.name(lang)),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: Column(
            children: [
              if (schedule != null)
                ScheduleBanner(schedule: schedule, lang: lang),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          lang == AppLang.bg
                              ? 'Няма продукти.'
                              : 'No products.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsPage(product: product),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: const OrderBar(),
        );
      },
    );
  }
}
