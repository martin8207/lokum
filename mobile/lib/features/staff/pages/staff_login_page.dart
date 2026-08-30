import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/staff_api.dart';
import '../../kitchen/pages/kitchen_board_page.dart';
import 'staff_dashboard_page.dart';

/// Вход за персонала - едно поле за парола, обща за всички (не индивидуален
/// login). Ролята (бележник/кухня) се определя от коя парола е въведена, не
/// от отделен избор тук - виж StaffApi.role/server/src/routes/auth.js.
/// Пази екраните недостъпни за клиенти, ако/когато test build-ът някога
/// стане публичен.
class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await StaffApi.instance.login(password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StaffApi.instance.role == 'kitchen'
              ? const KitchenBoardPage()
              : const StaffDashboardPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Вход за персонал')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 40, color: colors.accent),
                const SizedBox(height: 12),
                Text(
                  'Тази част е само за персонала на бара.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Парола',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Влез'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
