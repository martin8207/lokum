/// HTTP клиент за бележника на персонала И кухнята - говори с `lokum-server`
/// през `/api/*`, проксирано от nginx на СЪЩИЯ произход (виж
/// mobile/nginx.conf), затова `Uri.base.resolve(...)` е достатъчно - няма
/// нужда от отделен host или CORS. Работи само като Flutter Web build
/// (lokum-web-v2, tailnet-only) - клиентското мобилно приложение не ползва
/// този сервиз. Един login екран, една зъбчатка - коя парола въведеш решава
/// дали получаваш staff или kitchen роля (виж server/src/routes/auth.js).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/kitchen_order.dart';
import '../../shared/models/staff_order.dart';

class StaffApiException implements Exception {
  final String message;
  const StaffApiException(this.message);

  @override
  String toString() => message;
}

/// Токенът липсва/невалиден/изтекъл - UI-ят трябва да върне на login екрана,
/// не просто да покаже обща грешка.
class StaffAuthException implements Exception {
  const StaffAuthException();
  @override
  String toString() => 'Сесията е изтекла - влез отново.';
}

class StaffApi {
  StaffApi._();
  static final StaffApi instance = StaffApi._();

  static const _tokenPrefsKey = 'staff_auth_token';
  static const _rolePrefsKey = 'staff_auth_role';

  String? _token;
  String? _role;

  bool get isLoggedIn => _token != null;

  /// 'staff' или 'kitchen' - определя се от коя парола е въведена при
  /// login, не от избор в UI-я (виж server/src/routes/auth.js). Стар
  /// запазен token отпреди тази промяна няма запазена роля - третираме го
  /// като 'staff' (единствената роля, която е съществувала тогава).
  String get role => _role ?? 'staff';

  /// Пуска се веднъж при старт на приложението (виж main.dart), за да не
  /// пита за парола при всяко презареждане на страницата.
  Future<void> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenPrefsKey);
    _role = prefs.getString(_rolePrefsKey);
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
    await prefs.remove(_rolePrefsKey);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.base.resolve(path);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _headers([Map<String, String>? extra]) => {
    if (_token != null) 'Authorization': 'Bearer $_token',
    ...?extra,
  };

  void _checkOk(http.Response res) {
    if (res.statusCode == 401) {
      // Текущият токен вече не важи - изчистваме го веднага, за да не се
      // изпращат повече заявки с него, докато не се логне отново.
      _token = null;
      _role = null;
      SharedPreferences.getInstance().then((p) {
        p.remove(_tokenPrefsKey);
        p.remove(_rolePrefsKey);
      });
      throw const StaffAuthException();
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StaffApiException(
        'Сървърът върна грешка ${res.statusCode} за ${res.request?.url.path}.',
      );
    }
  }

  /// Споделена парола, изрично избрана роля от combo box-а на login екрана
  /// (не auto-detect) - паролата се проверява само срещу избраната роля,
  /// виж server/src/routes/auth.js.
  Future<void> login(String password, String role) async {
    final res = await http.post(
      _uri('/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password, 'role': role}),
    );
    if (res.statusCode == 401) {
      throw const StaffApiException('Грешна парола.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw const StaffApiException('Неуспешен вход - опитай пак.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    _token = token;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
    await prefs.setString(_rolePrefsKey, role);
  }

  Future<List<StaffProduct>> searchProducts({
    String query = '',
    String? category,
  }) async {
    final params = <String, String>{if (query.isNotEmpty) 'q': query};
    if (category != null) params['category'] = category;
    final res = await http.get(
      _uri('/api/products', params),
      headers: _headers(),
    );
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => StaffProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TableSummary>> fetchTables() async {
    final res = await http.get(_uri('/api/tables'), headers: _headers());
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => TableSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TableSessionDetail> fetchTableDetail(int tableNumber) async {
    final res = await http.get(
      _uri('/api/tables/$tableNumber'),
      headers: _headers(),
    );
    _checkOk(res);
    return TableSessionDetail.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// items: списък от {productId, quantity} - виж POST /api/tables/:n/orders.
  Future<void> submitOrder(
    int tableNumber,
    List<Map<String, Object>> items,
  ) async {
    final res = await http.post(
      _uri('/api/tables/$tableNumber/orders'),
      headers: _headers(const {'Content-Type': 'application/json'}),
      body: jsonEncode({'items': items}),
    );
    _checkOk(res);
  }

  Future<void> serveOrder(String orderId) async {
    _checkOk(
      await http.patch(_uri('/api/orders/$orderId/serve'), headers: _headers()),
    );
  }

  Future<void> cancelOrder(String orderId) async {
    _checkOk(
      await http.patch(
        _uri('/api/orders/$orderId/cancel'),
        headers: _headers(),
      ),
    );
  }

  Future<void> confirmItem(String orderId, String itemId) async {
    _checkOk(
      await http.patch(
        _uri('/api/orders/$orderId/items/$itemId/confirm'),
        headers: _headers(),
      ),
    );
  }

  /// Връща грешно потвърдена бройка обратно в "чака" - за поправка на
  /// случайно тапване в КА.
  Future<void> unconfirmItem(String orderId, String itemId) async {
    _checkOk(
      await http.patch(
        _uri('/api/orders/$orderId/items/$itemId/unconfirm'),
        headers: _headers(),
      ),
    );
  }

  Future<void> removeItem(String orderId, String itemId) async {
    _checkOk(
      await http.delete(
        _uri('/api/orders/$orderId/items/$itemId'),
        headers: _headers(),
      ),
    );
  }

  Future<void> invoiceTable(int tableNumber, String paymentMethod) async {
    final res = await http.patch(
      _uri('/api/tables/$tableNumber/invoice'),
      headers: _headers(const {'Content-Type': 'application/json'}),
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    _checkOk(res);
  }

  /// Само за kitchen роля - виж server/src/routes/kitchen.js. Kitchen
  /// токените нямат достъп до нищо друго от този клас (requireStaffAuth
  /// проверява ролята сървър-side). Сървърът вече връща сортирано възходящо
  /// по час на подаване (FIFO).
  Future<List<KitchenLineItem>> fetchKitchenItems() async {
    final res = await http.get(_uri('/api/kitchen/items'), headers: _headers());
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => KitchenLineItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// "Освободи маса" - изрично действие, отделно от отказ/изтриване на
  /// артикули. Затваря сесията без плащане/КА проверка (за изоставена маса,
  /// тестова поръчка и т.н.) - виж PATCH /api/tables/:n/free.
  Future<void> freeTable(int tableNumber) async {
    _checkOk(
      await http.patch(
        _uri('/api/tables/$tableNumber/free'),
        headers: _headers(),
      ),
    );
  }
}
