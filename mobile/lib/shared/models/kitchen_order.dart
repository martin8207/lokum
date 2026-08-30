/// Модели за кухненското табло (само за гледане - виж KitchenApi/
/// server/src/routes/kitchen.js). Различни от StaffOrder/StaffOrderItem,
/// защото кухнята не се интересува от КА потвърждение/цена - само какво
/// да сготви, по маси.
library;

class KitchenItem {
  final String id;
  final String productId;
  final String nameBg;
  final String nameEn;

  const KitchenItem({
    required this.id,
    required this.productId,
    required this.nameBg,
    required this.nameEn,
  });

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    return KitchenItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
    );
  }
}

class KitchenOrder {
  final String orderId;
  final DateTime submittedAt;
  final List<KitchenItem> items;

  const KitchenOrder({
    required this.orderId,
    required this.submittedAt,
    this.items = const [],
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      orderId: json['orderId'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      items: (json['items'] as List? ?? const [])
          .map((e) => KitchenItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KitchenTable {
  final int tableNumber;
  final List<KitchenOrder> orders;

  const KitchenTable({required this.tableNumber, this.orders = const []});

  factory KitchenTable.fromJson(Map<String, dynamic> json) {
    return KitchenTable(
      tableNumber: json['tableNumber'] as int,
      orders: (json['orders'] as List? ?? const [])
          .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
