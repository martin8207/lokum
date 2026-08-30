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

  // Сървърът праща UTC timestamps (Prisma/Postgres) - .toLocal() е нужен,
  // иначе часът показан на клиента изостава с часовата зона на бара.
  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

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
              style: const TextStyle(fontSize: 17),
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
            // order.activeItems маха отказаните бройки съвсем (полезно за
            // сметката), но точно тях трябва да види клиентът - иначе
            // "няма наличност" известието никога не се показва, артикулът
            // просто изчезва мълчаливо. Затова тук е пълният items списък.
            for (final item in order.items) _buildItemRow(item, lang, colors),
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

  // Същият визуален език като бележника на персонала (зелен чек = потвърдено
  // в КА, червено "!" = няма наличност) - за да разпознае клиентът веднага
  // статуса, без да учи нова легенда.
  Widget _buildItemRow(StaffOrderItem item, AppLang lang, LokumColors colors) {
    final name = lang == AppLang.bg ? item.nameBg : item.nameEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildStatusChip(item, colors),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.isRemoved
                  ? (lang == AppLang.bg
                        ? '$name - няма наличност'
                        : '$name - unavailable')
                  : name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: item.isRemoved ? FontWeight.w700 : FontWeight.w400,
                color: item.isRemoved ? _attentionColor : colors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StaffOrderItem item, LokumColors colors) {
    const size = 22.0;
    if (item.isRemoved) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _attentionColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.priority_high,
          size: 14,
          color: _attentionColor,
        ),
      );
    }
    if (item.isConfirmed) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _confirmedColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, size: 14, color: _confirmedColor),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.textMuted.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.schedule, size: 13, color: colors.textMuted),
    );
  }
}
