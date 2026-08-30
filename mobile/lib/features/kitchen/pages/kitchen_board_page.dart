import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/kitchen_api.dart';
import '../../../shared/models/kitchen_order.dart';
import 'kitchen_login_page.dart';

/// Кухненско табло - само за гледане (виж разговора: v1 без "готово"
/// маркиране). Показва кои ястия чакат по маси, групирани по артикул за
/// четимост. Веднъж сервирана поръчката, изчезва оттук - kitchen.js вече я
/// филтрира сървър-side.
class KitchenBoardPage extends StatefulWidget {
  const KitchenBoardPage({super.key});

  @override
  State<KitchenBoardPage> createState() => _KitchenBoardPageState();
}

class _KitchenBoardPageState extends State<KitchenBoardPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);

  List<KitchenTable>? _tables;
  String? _error;
  Timer? _timer;

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
      final tables = await KitchenApi.instance.fetchTables();
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _error = null;
      });
    } on KitchenAuthException {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KitchenLoginPage()),
      );
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  // Сървърът праща UTC timestamps - виж същата бележка в staff/customer
  // екраните.
  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Map<String, int> _groupCounts(List<KitchenItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final name = item.nameBg.isNotEmpty ? item.nameBg : item.nameEn;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tables = _tables;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кухня', style: TextStyle(fontSize: 18)),
      ),
      body: tables == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : _ErrorState(message: _error!, onRetry: _refresh)
          : tables.isEmpty
          ? Center(
              child: Text(
                'Няма чакащи ястия за приготвяне.',
                style: TextStyle(color: colors.textMuted),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tables.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) =>
                    _buildTableCard(tables[index], colors),
              ),
            ),
    );
  }

  Widget _buildTableCard(KitchenTable table, LokumColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Маса ${table.tableNumber}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final order in table.orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(order.submittedAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final entry in _groupCounts(order.items).entries)
                          Text(
                            '${entry.value}× ${entry.key}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textMain,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Опитай пак')),
          ],
        ),
      ),
    );
  }
}
