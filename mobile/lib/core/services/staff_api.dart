/// HTTP клиент за бележника на персонала - говори с `lokum-server` през
/// `/api/*`, проксирано от nginx на СЪЩИЯ произход (виж mobile/nginx.conf),
/// затова `Uri.base.resolve(...)` е достатъчно - няма нужда от отделен host
/// или CORS. Работи само като Flutter Web build (lokum-web-v2, tailnet-only) -
/// клиентското мобилно приложение не ползва този сервиз.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/models/staff_order.dart';

class StaffApiException implements Exception {
  final String message;
  const StaffApiException(this.message);

  @override
  String toString() => message;
}

class StaffApi {
  StaffApi._();
  static final StaffApi instance = StaffApi._();

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.base.resolve(path);
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StaffApiException(
        'Сървърът върна грешка ${res.statusCode} за ${res.request?.url.path}.',
      );
    }
  }

  Future<List<StaffProduct>> searchProducts({
    String query = '',
    String? category,
  }) async {
    final params = <String, String>{if (query.isNotEmpty) 'q': query};
    if (category != null) params['category'] = category;
    final res = await http.get(_uri('/api/products', params));
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => StaffProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TableSummary>> fetchTables() async {
    final res = await http.get(_uri('/api/tables'));
    _checkOk(res);
    return (jsonDecode(res.body) as List)
        .map((e) => TableSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TableSessionDetail> fetchTableDetail(int tableNumber) async {
    final res = await http.get(_uri('/api/tables/$tableNumber'));
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
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'items': items}),
    );
    _checkOk(res);
  }

  Future<void> serveOrder(String orderId) async {
    _checkOk(await http.patch(_uri('/api/orders/$orderId/serve')));
  }

  Future<void> cancelOrder(String orderId) async {
    _checkOk(await http.patch(_uri('/api/orders/$orderId/cancel')));
  }

  Future<void> confirmItem(String orderId, String itemId) async {
    _checkOk(
      await http.patch(_uri('/api/orders/$orderId/items/$itemId/confirm')),
    );
  }

  Future<void> removeItem(String orderId, String itemId) async {
    _checkOk(await http.delete(_uri('/api/orders/$orderId/items/$itemId')));
  }

  Future<void> invoiceTable(int tableNumber, String paymentMethod) async {
    final res = await http.patch(
      _uri('/api/tables/$tableNumber/invoice'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    _checkOk(res);
  }
}
