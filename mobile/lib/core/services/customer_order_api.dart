/// HTTP клиент за директното поръчване от масата - публичните
/// `/api/customer/*` endpoints, без login (виж
/// server/src/routes/customerOrders.js). Ползва СЪЩИТЕ модели като
/// бележника на персонала (StaffOrder/StaffOrderItem/TableSessionDetail) -
/// JSON формата, върната от сървъра, е идентична за двата случая (виж
/// server/src/lib/tableSession.js).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/models/staff_order.dart';

class CustomerOrderException implements Exception {
  final String message;
  const CustomerOrderException(this.message);

  @override
  String toString() => message;
}

class CustomerOrderApi {
  CustomerOrderApi._();
  static final CustomerOrderApi instance = CustomerOrderApi._();

  Uri _uri(String path) => Uri.base.resolve(path);

  void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CustomerOrderException('Сървърът върна грешка ${res.statusCode}.');
    }
  }

  Future<TableSessionDetail> fetchStatus(int tableNumber) async {
    final res = await http.get(_uri('/api/customer/tables/$tableNumber'));
    _checkOk(res);
    return TableSessionDetail.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> submitOrder(
    int tableNumber,
    List<Map<String, Object>> items,
  ) async {
    final res = await http.post(
      _uri('/api/customer/tables/$tableNumber/orders'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'items': items}),
    );
    _checkOk(res);
  }

  /// Иска сметката с предпочитан начин на плащане - НЕ фактурира сама по
  /// себе си (клиентът не може да затвори собствената си сметка), само
  /// маркира искането за персонала (виж customerOrders.js:/request-bill).
  Future<void> requestBill(int tableNumber, String paymentMethod) async {
    final res = await http.patch(
      _uri('/api/customer/tables/$tableNumber/request-bill'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    _checkOk(res);
  }

  /// Отказ на собствена поръчка - сървърът връща 409, ако персоналът вече я
  /// е докоснал (сервирана или поне 1 бройка потвърдена в КА) - виж
  /// customerOrders.js за причината.
  Future<void> cancelOrder(int tableNumber, String orderId) async {
    final res = await http.patch(
      _uri('/api/customer/tables/$tableNumber/orders/$orderId/cancel'),
    );
    if (res.statusCode == 409) {
      throw const CustomerOrderException(
        'Персоналът вече е поел поръчката - обърни се към бара за промяна.',
      );
    }
    _checkOk(res);
  }
}
