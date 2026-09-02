import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../../shared/models/kitchen_order.dart';
import '../../staff/pages/staff_login_page.dart';

/// Кухненско табло - плосък списък от чакащи ястия, най-старото първо
/// (FIFO), с триетапно цветово предупреждение по време на чакане - виж
/// lokum-kitchen-view-task.md/lokum-kitchen-view-demo.html. Чисто за
/// гледане: няма "готово" бутон тук - редът изчезва сам, щом сервитьорът
/// маркира поръчката като сервирана от изгледа на масата (един и същ запис
/// зад двата екрана).
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
                Text(
                  '${item.nameBg} ×${item.quantity}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
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
