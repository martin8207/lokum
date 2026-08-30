import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../../shared/models/staff_order.dart';
import 'staff_login_page.dart';
import 'staff_table_detail.dart';

/// Табло на бележника - master-detail на един екран (виж артефакта
/// staff-master-detail.html): тънък списък с номерата на масите вляво
/// (Функция 1, "Табло с общ преглед"), детайлът на избраната маса вдясно,
/// смяна без навигация. Polling на всеки 4 сек - "достатъчно добър"
/// fallback вместо WebSocket за v1 (виж lokum-version2-planning.md).
class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);

  List<TableSummary>? _tables;
  String? _error;
  Timer? _timer;
  int? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // На мобилен браузър таймерът пауза, докато табът е във фон/устройството е
  // заключено - без това, връщайки се, персоналът вижда old данни (напр.
  // маса вече фактурирана от друг телефон), докато не мине следващият tick.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final tables = await StaffApi.instance.fetchTables();
      if (!mounted) return;
      setState(() {
        _tables = tables;
        _error = null;
      });
    } on StaffAuthException {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StaffLoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tables = _tables;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Бележник на персонала',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: tables == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : _ErrorState(message: _error!, onRetry: _refresh)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableRail(
                  tables: tables,
                  selected: _selected,
                  colors: colors,
                  onSelect: (n) => setState(() => _selected = n),
                ),
                Expanded(
                  child: _selected == null
                      ? _EmptyDetail(colors: colors)
                      : StaffTableDetail(
                          key: ValueKey(_selected),
                          tableNumber: _selected!,
                          onChanged: _refresh,
                        ),
                ),
              ],
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

class _EmptyDetail extends StatelessWidget {
  final LokumColors colors;

  const _EmptyDetail({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_bar_outlined, size: 36, color: colors.textMuted),
            const SizedBox(height: 10),
            Text(
              'Избери маса вляво',
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Плосък, нескролируем списък с номерата на масите - виж артефакта
/// staff-master-detail.html: не плочки, а тесен таб-списък с тънка цветна
/// ивица отляво за статус, за да се съберат всички маси без скрол лента.
class _TableRail extends StatelessWidget {
  static const _width = 46.0;

  final List<TableSummary> tables;
  final int? selected;
  final LokumColors colors;
  final ValueChanged<int> onSelect;

  const _TableRail({
    required this.tables,
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  Color _stripeColor(TableTileState state) {
    switch (state) {
      case TableTileState.waiting:
        return const Color(0xFFE8871E);
      case TableTileState.needsKa:
        return const Color(0xFFE0473F);
      case TableTileState.served:
        return const Color(0xFF1F9254);
      case TableTileState.billRequested:
        return const Color(0xFF2F6FED);
      case TableTileState.free:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Container(
        width: _width,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tables.length; i++)
              _RailRow(
                table: tables[i],
                showBottomBorder: i != tables.length - 1,
                isSelected: tables[i].tableNumber == selected,
                stripeColor: _stripeColor(tables[i].state),
                colors: colors,
                onTap: () => onSelect(tables[i].tableNumber),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  static const _height = 34.0;

  final TableSummary table;
  final bool showBottomBorder;
  final bool isSelected;
  final Color stripeColor;
  final LokumColors colors;
  final VoidCallback onTap;

  const _RailRow({
    required this.table,
    required this.showBottomBorder,
    required this.isSelected,
    required this.stripeColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: _height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surface,
          border: Border(
            bottom: showBottomBorder
                ? BorderSide(color: colors.border)
                : BorderSide.none,
            left: BorderSide(color: stripeColor, width: 3),
          ),
        ),
        child: Text(
          '${table.tableNumber}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 13,
            color: isSelected ? colors.menuCardText : colors.textMain,
          ),
        ),
      ),
    );
  }
}
