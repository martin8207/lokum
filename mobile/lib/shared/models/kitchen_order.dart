/// Модели за кухненското табло - виж StaffApi/server/src/routes/kitchen.js.
/// Плосък ред - едно ястие × количество, с номер на маса и час на подаване,
/// вместо влагане по поръчка/маса.
library;

/// Една физическа бройка от реда - кухнята маркира "издадено" по бройка
/// (виж [KitchenLineItem.units]), затова трябва истинско OrderItem id, не
/// само общ брой.
class KitchenUnit {
  final String itemId;
  final bool confirmed;
  final bool issued;

  const KitchenUnit({
    required this.itemId,
    required this.confirmed,
    required this.issued,
  });

  factory KitchenUnit.fromJson(Map<String, dynamic> json) {
    return KitchenUnit(
      itemId: json['itemId'] as String,
      confirmed: json['confirmed'] as bool? ?? false,
      issued: json['issued'] as bool? ?? false,
    );
  }
}

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

  /// Индивидуалните бройки на този ред - за "Издадено" чиповете (виж
  /// KitchenBoardPage). Всяка носи собствен itemId, независим статус за
  /// confirmed (КА) и issued (кухнята).
  final List<KitchenUnit> units;

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
    this.units = const [],
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
      units:
          (json['units'] as List?)
              ?.map((e) => KitchenUnit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
