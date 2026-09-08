import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../../shared/models/kitchen_order.dart';
import '../../staff/pages/staff_login_page.dart';

/// Кухненско табло - плосък списък от чакащи ястия, най-старото първо
/// (FIFO), с триетапно цветово предупреждение по време на чакане - виж
/// lokum-kitchen-view-task.md/lokum-kitchen-view-demo.html. Кухнята може да
/// тапне "Издадено" по бройка (готова/предадена) - междинна стъпка, НЕ
/// заменя "Сервирано" (сервитьорът маркира от изгледа на масата) и не
/// изисква КА. Редът изчезва сам от таблото, щом е И сервиран, И всяка
/// бройка минала през КА (виж routes/kitchen.js) - "издадено" само по себе
/// си не маха реда.
class KitchenBoardPage extends StatefulWidget {
  const KitchenBoardPage({super.key});

  @override
  State<KitchenBoardPage> createState() => _KitchenBoardPageState();
}

class _KitchenBoardPageState extends State<KitchenBoardPage>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);
  static const _freshColor = Color(0xFFF3D98A);
  static const _warmColor = Color(0xFFE8963C);
  static const _lateColor = Color(0xFFE0554F);
  static const _confirmedColor = Color(0xFF1F9254);
  static const _servedColor = Color(0xFF2F6FED);
  static const _issuedColor = Color(0xFF00897B);

  List<KitchenLineItem>? _items;
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
      final items = await StaffApi.instance.fetchKitchenItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } on StaffAuthException {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StaffLoginPage()),
      );
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  // Toggle по бройка - вика се от чиповете в _buildRow. Тих refresh при
  // грешка не е достатъчен тук (за разлика от polling-а) - показваме snackbar,
  // за да разбере готвачката веднага, ако нещо не е минало.
  Future<void> _toggleIssued(KitchenUnit unit) async {
    try {
      if (unit.issued) {
        await StaffApi.instance.unissueItem(unit.itemId);
      } else {
        await StaffApi.instance.issueItem(unit.itemId);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int _waitMinutes(DateTime submittedAt) =>
      DateTime.now().difference(submittedAt).inMinutes;

  Color _waitColor(int minutes) {
    if (minutes >= 15) return _lateColor;
    if (minutes >= 10) return _warmColor;
    return _freshColor;
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кухня', style: TextStyle(fontSize: 18)),
        actions: [
          if (items != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length} ${items.length == 1 ? "чакащ" : "чакащи"}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: colors.menuCardText,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Изход',
            onPressed: () async {
              await StaffApi.instance.logout();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: items == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : _ErrorState(message: _error!, onRetry: _refresh)
          : items.isEmpty
          ? Center(
              child: Text(
                'Няма чакащи ястия за приготвяне.',
                style: TextStyle(color: colors.textMuted),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildRow(items[index], colors),
              ),
            ),
    );
  }

  Widget _buildRow(KitchenLineItem item, LokumColors colors) {
    final minutes = _waitMinutes(item.submittedAt);
    final waitColor = _waitColor(minutes);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: minutes >= 15 ? Border.all(color: _lateColor) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  _formatTime(item.submittedAt),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: waitColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'преди $minutes мин',
                  style: TextStyle(
                    fontSize: 10,
                    color: waitColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 36, color: colors.border),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.confirmed) ...[
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _confirmedColor,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        '${item.nameBg} ×${item.quantity}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Маса ${item.tableNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                    ),
                    if (item.served && !item.confirmed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _servedColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Сервирано - чака КА',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _servedColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Издадено:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.units
                          .map((u) => _buildIssueChip(u, colors))
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Един tap-able square на бройка - зелен check = издадено, tap-ва обратно
  // (виж _toggleIssued). Иконки, не текст на всеки чип - при 5-6 бройки
  // повтарящ се текст "Издадено" на всеки един е нечетимо струпване.
  Widget _buildIssueChip(KitchenUnit unit, LokumColors colors) {
    const size = 24.0;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _toggleIssued(unit),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: unit.issued
              ? _issuedColor.withValues(alpha: 0.16)
              : colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: unit.issued ? _issuedColor : colors.border),
        ),
        alignment: Alignment.center,
        child: Icon(
          unit.issued ? Icons.check : Icons.restaurant_outlined,
          size: 13,
          color: unit.issued ? _issuedColor : colors.textMuted,
        ),
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
