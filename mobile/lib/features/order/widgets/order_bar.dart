import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/app_config.dart';
import '../../../core/asset_paths.dart';
import '../../../core/services/order_cart_service.dart';
import '../../../shared/models/product.dart';
import '../pages/order_cart_page.dart';

/// Персистираща, подканваща лента "Поръчай" в долната част на менюто -
/// винаги видима (за разлика от скритата зъбчатка на персонала), за да не
/// се налага клиентът да се сети сам как да поръча от масата си.
class OrderBar extends StatelessWidget {
  const OrderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return ListenableBuilder(
          listenable: OrderCartService.instance,
          builder: (context, _) {
            final cart = OrderCartService.instance;
            final hasItems = !cart.isEmpty;
            final label = hasItems
                ? '${lang == AppLang.bg ? "Поръчай" : "Order"} · ${cart.itemCount} ${lang == AppLang.bg ? "арт." : "items"}'
                      '${AppConfig.showPrices ? " · ${cart.total.toStringAsFixed(2)} €" : ""}'
                : (lang == AppLang.bg
                      ? 'Поръчай от масата'
                      : 'Order from your table');

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: hasItems ? colors.accent : colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: hasItems ? 3 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrderCartPage()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color: hasItems
                                ? colors.menuCardText
                                : colors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: hasItems
                                    ? colors.menuCardText
                                    : colors.textMain,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: hasItems
                                ? colors.menuCardText
                                : colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
