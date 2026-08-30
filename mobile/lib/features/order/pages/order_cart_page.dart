import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/app_config.dart';
import '../../../core/asset_paths.dart';
import '../../../core/services/customer_order_api.dart';
import '../../../core/services/order_cart_service.dart';
import '../../../shared/models/product.dart';
import 'order_status_page.dart';
import 'order_table_entry_page.dart';

/// Преглед на количката преди подаване на поръчката - маса, артикули,
/// бройки, обща сума. Вгражда се от [OrderBar], видима от всеки екран на
/// менюто.
class OrderCartPage extends StatefulWidget {
  const OrderCartPage({super.key});

  @override
  State<OrderCartPage> createState() => _OrderCartPageState();
}

class _OrderCartPageState extends State<OrderCartPage> {
  bool _submitting = false;

  Future<void> _submit() async {
    final cart = OrderCartService.instance;
    var tableNumber = cart.tableNumber;
    if (tableNumber == null) {
      final picked = await Navigator.of(context).push<int>(
        MaterialPageRoute(builder: (_) => const OrderTableEntryPage()),
      );
      if (picked == null || !mounted) return;
      tableNumber = picked;
    }

    setState(() => _submitting = true);
    try {
      final items = cart.lines
          .map((e) => {'productId': e.key.id, 'quantity': e.value})
          .toList();
      await CustomerOrderApi.instance.submitOrder(tableNumber, items);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderStatusPage(tableNumber: tableNumber!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

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
            return Scaffold(
              appBar: AppBar(
                title: Text(lang == AppLang.bg ? 'Количка' : 'Cart'),
              ),
              body: cart.isEmpty
                  ? _buildEmpty(context, lang, colors)
                  : _buildCart(context, lang, colors, cart),
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, AppLang lang, LokumColors colors) {
    final tableNumber = OrderCartService.instance.tableNumber;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              lang == AppLang.bg
                  ? 'Количката е празна - разгледай менюто и добави артикули.'
                  : 'Your cart is empty - browse the menu and add items.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
            if (tableNumber != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderStatusPage(tableNumber: tableNumber),
                  ),
                ),
                child: Text(
                  lang == AppLang.bg
                      ? 'Виж статус на поръчката (маса $tableNumber)'
                      : 'View order status (table $tableNumber)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCart(
    BuildContext context,
    AppLang lang,
    LokumColors colors,
    OrderCartService cart,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (cart.tableNumber != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.table_bar_outlined, color: colors.accent),
                      const SizedBox(width: 8),
                      Text(
                        lang == AppLang.bg
                            ? 'Маса ${cart.tableNumber}'
                            : 'Table ${cart.tableNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textMain,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OrderTableEntryPage(),
                          ),
                        ),
                        child: Text(lang == AppLang.bg ? 'Смени' : 'Change'),
                      ),
                    ],
                  ),
                ),
              for (final line in cart.lines)
                _buildLine(context, lang, colors, line),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (AppConfig.showPrices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang == AppLang.bg ? 'Общо' : 'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textMain,
                          ),
                        ),
                        Text(
                          '${cart.total.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(lang == AppLang.bg ? 'Поръчай' : 'Place order'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLine(
    BuildContext context,
    AppLang lang,
    LokumColors colors,
    MapEntry<Product, int> line,
  ) {
    final product = line.key;
    final qty = line.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name(lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                if (AppConfig.showPrices)
                  Text(
                    product.formattedPrice(),
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                OrderCartService.instance.changeQty(product.id, -1),
          ),
          Text(
            '$qty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textMain,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => OrderCartService.instance.changeQty(product.id, 1),
          ),
        ],
      ),
    );
  }
}
