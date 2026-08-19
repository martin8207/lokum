import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../../shared/models/staff_order.dart';

/// Бележникът на персонала за една маса - търсене/добавяне на артикули,
/// статус по бройка (потвърдено в КА / изтрито), сервиране, отказ и
/// приключване на сметката. Всичко в едно скролируемо табло вместо отделни
/// екрани - виж разговора след lokum-staff-search-demo.html.
class StaffTablePage extends StatefulWidget {
  final int tableNumber;

  const StaffTablePage({super.key, required this.tableNumber});

  @override
  State<StaffTablePage> createState() => _StaffTablePageState();
}

class _StaffTablePageState extends State<StaffTablePage> {
  static const _pollInterval = Duration(seconds: 4);
  static const _confirmedColor = Color(0xFF1F9254);
  static const _attentionColor = Color(0xFFE0473F);
  static const _progressColor = Color(0xFF2F6FED);

  Timer? _timer;
  TableSessionDetail? _detail;
  String? _loadError;

  final _searchController = TextEditingController();
  List<StaffProduct> _results = [];
  bool _searching = false;

  final Map<String, int> _cart = {};
  final Map<String, StaffProduct> _cartProducts = {};
  bool _submitting = false;

  String _paymentMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final detail = await StaffApi.instance.fetchTableDetail(
        widget.tableNumber,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _loadError = e.toString());
    }
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await StaffApi.instance.searchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      _showError(e.toString());
    }
  }

  void _addToCart(StaffProduct product) {
    setState(() {
      _cart[product.id] = (_cart[product.id] ?? 0) + 1;
      _cartProducts[product.id] = product;
    });
  }

  void _changeQty(String productId, int delta) {
    setState(() {
      final next = (_cart[productId] ?? 0) + delta;
      if (next <= 0) {
        _cart.remove(productId);
        _cartProducts.remove(productId);
      } else {
        _cart[productId] = next;
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final items = _cart.entries
          .map((e) => {'productId': e.key, 'quantity': e.value})
          .toList();
      await StaffApi.instance.submitOrder(widget.tableNumber, items);
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _cartProducts.clear();
        _results.clear();
        _searchController.clear();
        _submitting = false;
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.toString());
    }
  }

  // Лесно, без потвърждение - само отказът на ЦЯЛА поръчка изисква двойно
  // потвърждение (виж _cancelOrderWithConfirmation). Премахването на ЕДНА
  // бройка (свършила бира и т.н.) трябва да е бърз единичен tap.
  Future<void> _confirmItem(StaffOrder order, StaffOrderItem item) async {
    try {
      await StaffApi.instance.confirmItem(order.id, item.id);
      await _refresh();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _removeItem(StaffOrder order, StaffOrderItem item) async {
    try {
      await StaffApi.instance.removeItem(order.id, item.id);
      await _refresh();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _serveOrder(StaffOrder order) async {
    try {
      await StaffApi.instance.serveOrder(order.id);
      await _refresh();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _cancelOrderWithConfirmation(StaffOrder order) async {
    final first = await _confirmDialog(
      title: 'Отказ на поръчката?',
      message: 'Ще махнеш всички артикули от този кръг поръчки на масата.',
      confirmLabel: 'Продължи',
    );
    if (first != true || !mounted) return;

    final second = await _confirmDialog(
      title: 'Наистина ли?',
      message: 'Това е окончателно и не може да се върне.',
      confirmLabel: 'Да, откажи поръчката',
      danger: true,
    );
    if (second != true) return;

    try {
      await StaffApi.instance.cancelOrder(order.id);
      await _refresh();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Назад'),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(backgroundColor: _attentionColor)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _invoice() async {
    try {
      await StaffApi.instance.invoiceTable(widget.tableNumber, _paymentMethod);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(
        'Не може да се фактурира - провери дали всички артикули са минали през КА.',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Map<String, List<StaffOrderItem>> _groupByProduct(
    List<StaffOrderItem> items,
  ) {
    final map = <String, List<StaffOrderItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.productId, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: Text('Маса ${widget.tableNumber}')),
      body: detail == null
          ? Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Text(_loadError!),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalHeader(detail, colors),
                const SizedBox(height: 20),
                _buildNotebookSection(colors),
                if (detail.activeOrders.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Поръчки на масата',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colors.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final order in detail.activeOrders)
                    _buildOrderCard(order, colors),
                  const SizedBox(height: 8),
                  _buildInvoiceSection(detail, colors),
                ],
              ],
            ),
    );
  }

  Widget _buildTotalHeader(TableSessionDetail detail, LokumColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Маса ${detail.tableNumber}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.accent,
              ),
            ),
            if (detail.needsKaAttention) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.warning_amber_rounded,
                color: _attentionColor,
                size: 20,
              ),
            ],
          ],
        ),
        Text(
          '${detail.total.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildNotebookSection(LokumColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Нова поръчка',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: colors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Търси артикул...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          onChanged: (value) {
            final trimmed = value.trim();
            if (trimmed.length < 2) {
              setState(() => _results = []);
              return;
            }
            _search(trimmed);
          },
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._results.map((p) => _buildResultRow(p, colors)),
        ],
        if (_cart.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Добавени артикули',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          ..._cart.entries.map((e) => _buildCartRow(e.key, e.value, colors)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submitOrder,
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Поръчай'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultRow(StaffProduct product, LokumColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => _addToCart(product),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameBg,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textMain,
                        ),
                      ),
                      Text(
                        '${product.priceEur.toStringAsFixed(2)} €',
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.accent,
                  child: Icon(Icons.add, size: 16, color: colors.surface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartRow(String productId, int qty, LokumColors colors) {
    final product = _cartProducts[productId]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.nameBg,
              style: TextStyle(color: colors.textMain),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _changeQty(productId, -1),
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
            onPressed: () => _changeQty(productId, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(StaffOrder order, LokumColors colors) {
    final grouped = _groupByProduct(order.activeItems);
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
                  'Поръчка · ${_formatTime(order.submittedAt)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                _buildOrderStatusPill(order),
              ],
            ),
            const SizedBox(height: 10),
            for (final entry in grouped.entries)
              _buildProductLine(order, entry.value, colors),
            if (order.needsKaAttention) ...[
              const SizedBox(height: 4),
              _buildWarningBanner(order),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${order.confirmedTotal.toStringAsFixed(2)} €',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (!order.isServed)
                  TextButton(
                    onPressed: () => _serveOrder(order),
                    child: const Text('Маркирай сервирано'),
                  ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _attentionColor),
                  onPressed: () => _cancelOrderWithConfirmation(order),
                  child: const Text('Откажи'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusPill(StaffOrder order) {
    final color = order.isServed ? _confirmedColor : _progressColor;
    final label = order.isServed ? 'Сервиран' : 'Чака сервиране';
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

  Widget _buildProductLine(
    StaffOrder order,
    List<StaffOrderItem> items,
    LokumColors colors,
  ) {
    final first = items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${first.nameBg} ×${items.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) => _buildUnitChip(order, item)).toList(),
          ),
        ],
      ),
    );
  }

  // Зелено чек = наляно в КА (tap на червения "!" маркира точно това).
  // Червен "!" + отделен "×" до него = не е налично - tap-ни "!" щом го
  // прекуцаш, или "×" за да го изтриеш и добавиш заместител от търсачката.
  Widget _buildUnitChip(StaffOrder order, StaffOrderItem item) {
    const size = 26.0;
    if (item.isConfirmed) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _confirmedColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, size: 14, color: _confirmedColor),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => _confirmItem(order, item),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _attentionColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.priority_high,
              size: 14,
              color: _attentionColor,
            ),
          ),
        ),
        const SizedBox(width: 3),
        InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => _removeItem(order, item),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: _attentionColor, width: 1.2),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.close, size: 14, color: _attentionColor),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(StaffOrder order) {
    final pending = order.activeItems.where((it) => it.needsAttention).length;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _attentionColor.withValues(alpha: 0.1),
        border: Border.all(color: _attentionColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: _attentionColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pending == 1
                  ? '1 бройка не е минала през КА.'
                  : '$pending бройки не са минали през КА.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _attentionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection(TableSessionDetail detail, LokumColors colors) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Приключване на сметка',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    'CASH',
                    'В брой',
                    Icons.payments_outlined,
                    colors,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentOption(
                    'CARD',
                    'Карта',
                    Icons.credit_card,
                    colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!detail.readyToInvoice)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Не всички артикули са минали през КА - фактурирането е заключено.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: detail.readyToInvoice ? _invoice : null,
                child: const Text('Фактурирай'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String label,
    IconData icon,
    LokumColors colors,
  ) {
    final selected = _paymentMethod == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 2 : 1,
          ),
          color: selected ? colors.accent.withValues(alpha: 0.08) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.textMain),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textMain,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
