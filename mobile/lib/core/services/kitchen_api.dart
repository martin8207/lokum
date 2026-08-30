/// HTTP клиент за кухненското табло - отделна роля/парола от StaffApi (виж
/// server/src/routes/auth.js:/kitchen-login и middleware/requireKitchenAuth).
/// Само за гледане - едно GET, никакви мутиращи endpoint-и за v1.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/kitchen_order.dart';

class KitchenApiException implements Exception {
  final String message;
  const KitchenApiException(this.message);

  @override
  String toString() => message;
}

class KitchenAuthException implements Exception {
  const KitchenAuthException();
  @override
  String toString() => 'Сесията е изтекла - влез отново.';
}

class KitchenApi {
  KitchenApi._();
  static final KitchenApi instance = KitchenApi._();

  static const _tokenPrefsKey = 'kitchen_auth_token';

  String? _token;

  bool get isLoggedIn => _token != null;

  Future<void> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenPrefsKey);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
  }

  Uri _uri(String path) => Uri.base.resolve(path);

  Map<String, String> _headers() => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  void _checkOk(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) {
      _token = null;
      SharedPreferences.getInstance().then((p) => p.remove(_tokenPrefsKey));
      throw const KitchenAuthException();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw KitchenApiException('Сървърът върна грешка ${res.statusCode}.');
    }
  }

  Future<void> login(String password) async {
    final res = await http.post(
      _uri('/api/auth/kitchen-login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode == 401) {
      throw const KitchenApiException('Грешна парола.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const KitchenApiException('Неуспешен вход - опитай пак.');
    }
    final token =
        (jsonDecode(res.body) as Map<String, dynamic>)['token'] as String;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
  }

  Future<List<KitchenTable>> fetchTables() async {
    final res = await http.get(
      _uri('/api/kitchen/tables'),
      headers: _headers(),
    );
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => KitchenTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
