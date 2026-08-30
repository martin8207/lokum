/// Клиентската количка за директно поръчване от масата (не бележника на
/// персонала - виж StaffApi/staff_table_detail.dart за него). Живее в
/// паметта, докато номерът на масата се пази в SharedPreferences, за да не
/// пита пак при презареждане на страницата в браузъра.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/product.dart';

class OrderCartService extends ChangeNotifier {
  OrderCartService._();
  static final OrderCartService instance = OrderCartService._();

  static const _tableNumberPrefsKey = 'customer_table_number';

  final Map<String, int> _quantities = {};
  final Map<String, Product> _products = {};
  int? _tableNumber;

  int? get tableNumber => _tableNumber;
  bool get isEmpty => _quantities.isEmpty;
  int get itemCount => _quantities.values.fold(0, (sum, q) => sum + q);

  double get total => _quantities.entries.fold(
    0.0,
    (sum, e) => sum + (_products[e.key]?.priceEur ?? 0) * e.value,
  );

  List<MapEntry<Product, int>> get lines => _quantities.entries
      .map((e) => MapEntry(_products[e.key]!, e.value))
      .toList();

  /// Пуска се веднъж при старт на приложението (виж main.dart), за да не има
  /// кратък момент, в който масата изглежда неизбрана, докато се зареди.
  Future<void> loadStoredTable() async {
    final prefs = await SharedPreferences.getInstance();
    _tableNumber = prefs.getInt(_tableNumberPrefsKey);
    notifyListeners();
  }

  Future<void> setTableNumber(int number) async {
    _tableNumber = number;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tableNumberPrefsKey, number);
    notifyListeners();
  }

  void add(Product product, [int qty = 1]) {
    _quantities[product.id] = (_quantities[product.id] ?? 0) + qty;
    _products[product.id] = product;
    notifyListeners();
  }

  void changeQty(String productId, int delta) {
    final next = (_quantities[productId] ?? 0) + delta;
    if (next <= 0) {
      _quantities.remove(productId);
      _products.remove(productId);
    } else {
      _quantities[productId] = next;
    }
    notifyListeners();
  }

  void clear() {
    _quantities.clear();
    _products.clear();
    notifyListeners();
  }
}
