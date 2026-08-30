import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/app_config.dart';
import '../../../core/asset_paths.dart';
import '../../../core/services/customer_order_api.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/staff_order.dart';

/// Статус на поръчката на клиента - поле по поле кои артикули чакат, кои са
/// потвърдени в КА и кои са отказани от бара като неналични (за да разбере
/// клиентът, а не да чака мълчаливо нещо, което няма да дойде).
class OrderStatusPage extends StatefulWidget {
  final int tableNumber;

  const OrderStatusPage({super.key, required this.tableNumber});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);
  static const _confirmedColor = Color(0xFF1F9254);
  static const _attentionColor = Color(0xFFE0473F);
  static const _pendingColor = Color(0xFF2F6FED);

  Timer? _timer;
  TableSessionDetail? _detail;
  String? _error;
  String? _cancellingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final detail = await CustomerOrderApi.instance.fetchStatus(
        widget.tableNumber,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _cancelOrder(StaffOrder order) async {
    setState(() => _cancellingOrderId = order.id);
    try {
      await CustomerOrderApi.instance.cancelOrder(widget.tableNumber, order.id);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = _detail;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              lang == AppLang.bg
                  ? 'Поръчката ти - маса ${widget.tableNumber}'
                  : 'Your order - table ${widget.tableNumber}',
            ),
          ),
          body: detail == null
              ? Center(
                  child: _error == null
                      ? const CircularProgressIndicator()
                      : Text(_error!),
                )
              : detail.activeOrders.isEmpty
              ? Center(
                  child: Text(
                    lang == AppLang.bg
                        ? 'Все още няма подадена поръчка на тази маса.'
                        : 'No order has been placed at this table yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textMuted),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (AppConfig.showPrices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang == AppLang.bg
                                    ? 'Очаквана сметка'
                                    : 'Estimated total',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMain,
                                ),
                              ),
                              Text(
                                '${detail.estimatedTotal.toStringAsFixed(2)} €',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final order in detail.activeOrders)
                        _buildOrderCard(order, lang, colors),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOrderCard(StaffOrder order, AppLang lang, LokumColors colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${lang == AppLang.bg ? "Поръчка" : "Order"} · ${_formatTime(order.submittedAt)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                _buildStatusPill(order, lang),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in order.activeItems)
              _buildItemRow(item, lang, colors),
            if (order.customerCancellable) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: _attentionColor),
                  onPressed: _cancellingOrderId == order.id
                      ? null
                      : () => _confirmCancel(order, lang),
                  child: Text(lang == AppLang.bg ? 'Откажи' : 'Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(StaffOrder order, AppLang lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          lang == AppLang.bg ? 'Отказ на поръчката?' : 'Cancel order?',
        ),
        content: Text(
          lang == AppLang.bg
              ? 'Артикулите от този кръг ще бъдат премахнати.'
              : 'The items in this round will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang == AppLang.bg ? 'Назад' : 'Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _attentionColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang == AppLang.bg ? 'Да, откажи' : 'Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _cancelOrder(order);
  }

  Widget _buildStatusPill(StaffOrder order, AppLang lang) {
    final color = order.isServed ? _confirmedColor : _pendingColor;
    final label = order.isServed
        ? (lang == AppLang.bg ? 'Сервирана' : 'Served')
        : (lang == AppLang.bg ? 'Приета' : 'Received');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItemRow(StaffOrderItem item, AppLang lang, LokumColors colors) {
    final name = lang == AppLang.bg ? item.nameBg : item.nameEn;
    if (item.isRemoved) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: _attentionColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lang == AppLang.bg
                    ? '$name - за съжаление не е налично'
                    : '$name - unfortunately unavailable',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _attentionColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final color = item.isConfirmed ? _confirmedColor : colors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            item.isConfirmed ? Icons.check_circle : Icons.schedule,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: colors.textMain),
            ),
          ),
        ],
      ),
    );
  }
}
