import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/asset_paths.dart';
import '../../../core/constants/schedule.dart';
import '../../../shared/models/product.dart';

/// Ред за продукт в списъка на подкатегорията.
///
/// Стил на менюто: фон = accent, текст = background. Ако продуктът има
/// реална снимка, картата минава на по-богат хоризонтален layout (снимка
/// вляво, цяла, без изрязване — `BoxFit.contain`, per design spec).
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final imagePath = AssetPaths.productImage(product.image);
        final hasImage = BundledAssets.has(imagePath);
        final offeredNow = ProductAvailability.isOfferedNow(product);
        return Opacity(
          opacity: product.available && offeredNow ? 1 : 0.5,
          child: hasImage
              ? _PhotoProductCard(
                  product: product,
                  lang: lang,
                  imagePath: imagePath,
                  colors: colors,
                  onTap: product.available ? onTap : null,
                )
              : _PlainProductCard(
                  product: product,
                  lang: lang,
                  colors: colors,
                  onTap: product.available ? onTap : null,
                ),
        );
      },
    );
  }
}

/// Компактен ред за продукт без снимка (мнозинството от менюто — хартиеното
/// меню е предимно текст, без снимки на артикулите).
class _PlainProductCard extends StatelessWidget {
  final Product product;
  final AppLang lang;
  final LokumColors colors;
  final VoidCallback? onTap;

  const _PlainProductCard({
    required this.product,
    required this.lang,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = product.formattedQuantity();
    return Card(
      elevation: 0,
      color: colors.menuCardBackground,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        hoverColor: colors.hoverOnMenuCard,
        splashColor: colors.splashOnMenuCard,
        contentPadding: const EdgeInsets.all(8),
        title: Text(
          product.name(lang),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.menuCardText,
          ),
        ),
        subtitle: quantity == null
            ? null
            : Text(
                quantity,
                style: TextStyle(
                  color: colors.menuCardText.withValues(alpha: 0.7),
                ),
              ),
        trailing: _PriceColumn(
          product: product,
          lang: lang,
          color: colors.menuCardText,
        ),
      ),
    );
  }
}

/// Разширена карта за продукт С реална снимка: снимката е вляво, цяла (без
/// изрязване), информацията е вдясно — марка / стил / описание / цена.
class _PhotoProductCard extends StatelessWidget {
  final Product product;
  final AppLang lang;
  final String imagePath;
  final LokumColors colors;
  final VoidCallback? onTap;

  const _PhotoProductCard({
    required this.product,
    required this.lang,
    required this.imagePath,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = product.formattedQuantity();
    final description = product.description(lang);

    return Card(
      elevation: 0,
      color: colors.menuCardBackground,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.hoverOnMenuCard,
        splashColor: colors.splashOnMenuCard,
        highlightColor: colors.hoverOnMenuCard,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Снимка: `contain`, не `cover` — цялата бутилка/чаша се вижда.
              Container(
                width: 84,
                height: 120,
                decoration: BoxDecoration(
                  color: colors.menuCardText.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name(lang),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.menuCardText,
                      ),
                    ),
                    if (quantity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        quantity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: colors.menuCardText.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.menuCardText.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PriceColumn(
                product: product,
                lang: lang,
                color: colors.menuCardText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final Product product;
  final AppLang lang;
  final Color color;

  const _PriceColumn({
    required this.product,
    required this.lang,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          product.formattedPrice(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          product.formattedPriceBgn(),
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
        ),
        if (product.isNew || product.featured || product.isRecommended)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              children: [
                if (product.isNew)
                  _Badge(
                    label: lang == AppLang.bg ? 'Ново' : 'New',
                    color: Colors.green,
                  ),
                if (product.isRecommended)
                  _Badge(
                    label: lang == AppLang.bg ? 'Препоръчано' : 'Top pick',
                    color: Colors.orange,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
