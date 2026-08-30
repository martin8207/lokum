import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/services/kitchen_api.dart';
import 'kitchen_board_page.dart';

/// Вход за кухнята - отделна споделена парола от бележника на персонала
/// (виж KitchenApi/server/src/routes/auth.js:/kitchen-login).
class KitchenLoginPage extends StatefulWidget {
  const KitchenLoginPage({super.key});

  @override
  State<KitchenLoginPage> createState() => _KitchenLoginPageState();
}

class _KitchenLoginPageState extends State<KitchenLoginPage> {
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
      await KitchenApi.instance.login(password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KitchenBoardPage()),
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
      appBar: AppBar(title: const Text('Вход за кухнята')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.soup_kitchen_outlined,
                  size: 40,
                  color: colors.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Тази част е само за кухнята.',
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
