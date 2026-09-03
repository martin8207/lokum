/// Модел за кухненското табло (само за гледане - виж StaffApi/
/// server/src/routes/kitchen.js). Плосък ред - едно ястие × количество, с
/// номер на маса и час на подаване, вместо влагане по поръчка/маса.
library;

class KitchenLineItem {
  final String id;
  final String productId;
  final String nameBg;
  final String nameEn;
  final int quantity;
  final int tableNumber;
  final DateTime submittedAt;

  /// Всички бройки от този ред минали ли са през КА. Редът се маха от
  /// таблото само когато е И [confirmed], И [served] - иначе остава като
  /// напомняне на сервитьора да го чекне, дори ако вече е занесен физически.
  final bool confirmed;
  final bool served;

  const KitchenLineItem({
    required this.id,
    required this.productId,
    required this.nameBg,
    required this.nameEn,
    required this.quantity,
    required this.tableNumber,
    required this.submittedAt,
    required this.confirmed,
    required this.served,
  });

  factory KitchenLineItem.fromJson(Map<String, dynamic> json) {
    return KitchenLineItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      tableNumber: json['tableNumber'] as int,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      confirmed: json['confirmed'] as bool? ?? false,
      served: json['served'] as bool? ?? false,
    );
  }
}
