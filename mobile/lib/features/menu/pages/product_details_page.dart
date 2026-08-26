import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/app_config.dart';
import '../../../core/asset_paths.dart';
import '../../../core/constants/schedule.dart';
import '../../../core/services/menu_service.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../widgets/schedule_banner.dart';

/// Пълен изглед на продукт: снимка, име, описание, цена, порция, тагове,
/// алергени.
class ProductDetailsPage extends StatelessWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final description = product.description(lang);
        final quantity = product.formattedQuantity();
        final model = product.formattedModel();
        final imagePath = AssetPaths.productImage(product.image);
        final hasImage = BundledAssets.has(imagePath);
        final isFoodPhoto = hasImage && product.categoryId == 'food';
        final schedule = ProductAvailability.scheduleFor(product);

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name(lang)),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isFoodPhoto) ...[
                // "Нещо за хапване": квадратна (4:4) снимка на цяла ширина
                // отгоре, текстът пада под нея - виж
                // lokum-detail-page-demo.html.
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  product.name(lang),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (model != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    model.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
                if (quantity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quantity,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
                if (AppConfig.showPrices) ...[
                  const SizedBox(height: 10),
                  Text(
                    product.formattedPrice(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ] else if (hasImage)
                // Снимката е ляво подравнена, със заоблени краища,
                // `BoxFit.cover` (запълва изцяло, без празно поле) —
                // височината ѝ следва краткия инфо-блок вдясно (име/модел/
                // количество/цена, IntrinsicHeight + stretch). Описанието
                // умишлено НЕ е тук - показва се отделно под hero-реда, за
                // да не се разтяга снимката неестествено при дълъг текст.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 130,
                          child: Image.asset(imagePath, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.name(lang),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (model != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                model.toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                            if (quantity != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                quantity,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                            if (AppConfig.showPrices) ...[
                              const SizedBox(height: 10),
                              Text(
                                product.formattedPrice(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name(lang),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (AppConfig.showPrices)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            product.formattedPrice(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (quantity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quantity,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
              if (!product.available) ...[
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    lang == AppLang.bg
                        ? 'Временно неналично'
                        : 'Currently unavailable',
                  ),
                  backgroundColor: theme.colorScheme.errorContainer,
                ),
              ],
              if (schedule != null) ...[
                const SizedBox(height: 12),
                ScheduleBanner(
                  schedule: schedule,
                  lang: lang,
                  margin: EdgeInsets.zero,
                ),
              ],
              if (product.isNew ||
                  product.featured ||
                  product.isRecommended) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (product.isNew)
                      Chip(label: Text(lang == AppLang.bg ? 'Ново' : 'New')),
                    if (product.featured)
                      Chip(
                        label: Text(
                          lang == AppLang.bg
                              ? 'Препоръчано от бара'
                              : 'Featured',
                        ),
                      ),
                    if (product.isRecommended)
                      Chip(
                        label: Text(
                          lang == AppLang.bg ? 'Топ избор' : 'Top pick',
                        ),
                      ),
                  ],
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: 20),
                Text(
                  lang == AppLang.bg ? 'Съставки' : 'Ingredients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              if (product.allergens.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  lang == AppLang.bg ? 'Алергени' : 'Allergens',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.allergens
                      .map(
                        (code) => MenuService.instance.allergenName(code, lang),
                      )
                      .join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
