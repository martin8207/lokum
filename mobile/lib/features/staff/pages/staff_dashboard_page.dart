import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../../shared/models/staff_order.dart';
import 'staff_table_page.dart';

/// Табло с общ преглед на всички маси (Функция 1, "Табло с общ преглед").
/// Polling на всеки 4 сек - "достатъчно добър" fallback вместо WebSocket за
/// v1 (виж lokum-version2-planning.md), два телефона в tailnet-а виждат
/// едно и също състояние с малко закъснение, без допълнителна инфраструктура.
class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  static const _pollInterval = Duration(seconds: 4);

  List<TableSummary>? _tables;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final tables = await StaffApi.instance.fetchTables();
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Табло — маси')),
      body: _tables == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : _ErrorState(message: _error!, onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tables!.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final table = _tables![index];
                  return _TableTile(
                    table: table,
                    colors: colors,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StaffTablePage(tableNumber: table.tableNumber),
                        ),
                      );
                      _refresh();
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

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

class _TableTile extends StatelessWidget {
  final TableSummary table;
  final LokumColors colors;
  final VoidCallback onTap;

  const _TableTile({
    required this.table,
    required this.colors,
    required this.onTap,
  });

  ({Color bg, Color border, Color text, String label}) _style() {
    switch (table.state) {
      case TableTileState.waiting:
        return (
          bg: const Color(0x29E8871E),
          border: const Color(0xFFE8871E),
          text: const Color(0xFFE8871E),
          label: 'Нова',
        );
      case TableTileState.needsKa:
        return (
          bg: const Color(0x29E0473F),
          border: const Color(0xFFE0473F),
          text: const Color(0xFFE0473F),
          label: 'Чака КА',
        );
      case TableTileState.served:
        return (
          bg: const Color(0x291F9254),
          border: const Color(0xFF1F9254),
          text: const Color(0xFF1F9254),
          label: 'Сервиран',
        );
      case TableTileState.free:
        return (
          bg: colors.surface,
          border: colors.border,
          text: colors.textMuted,
          label: 'Свободна',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();
    return Material(
      color: style.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: style.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${table.tableNumber}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                style.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: style.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
