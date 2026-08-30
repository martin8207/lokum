/// Модели за бележника на персонала (v2.0, staff-only, само в test/lokum-web-v2
/// build-а). За разлика от [Product]/[BarEvent], тези идват от `lokum-server`
/// през HTTP, не от локален bundled asset - виж [StaffApi].
library;

/// Една бройка от артикул в поръчка - НЕ ред с количество. "Потвърден в КА"
/// (наляно/прекуцано на касовия апарат) и "изтрит" (не е налично, свършило
/// е) са независими флагове на всяка отделна бройка, защото 2 бройки от
/// едно и също количество може да имат различна съдба.
class StaffOrderItem {
  final String id;
  final String productId;
  final String nameBg;
  final String nameEn;
  final double priceEur;
  final DateTime? kaConfirmedAt;
  final DateTime? removedAt;

  const StaffOrderItem({
    required this.id,
    required this.productId,
    required this.nameBg,
    required this.nameEn,
    required this.priceEur,
    this.kaConfirmedAt,
    this.removedAt,
  });

  bool get isConfirmed => kaConfirmedAt != null;
  bool get isRemoved => removedAt != null;

  /// Чака - нито потвърдена в КА, нито изтрита като неналична.
  bool get needsAttention => !isConfirmed && !isRemoved;

  factory StaffOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return StaffOrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      nameBg: product?['nameBg'] as String? ?? '',
      nameEn: product?['nameEn'] as String? ?? '',
      priceEur: double.tryParse(json['priceEur'].toString()) ?? 0,
      kaConfirmedAt: json['kaConfirmedAt'] == null
          ? null
          : DateTime.parse(json['kaConfirmedAt'] as String),
      removedAt: json['removedAt'] == null
          ? null
          : DateTime.parse(json['removedAt'] as String),
    );
  }
}

/// Един кръг поръчки, подаден наведнъж от бележника. [servedAt]/[cancelledAt]
/// са на ниво поръчка (сервира се или се отказва наведнъж) - потвърждението
/// в касата е на ниво отделна бройка, виж [StaffOrderItem].
class StaffOrder {
  final String id;
  final DateTime submittedAt;
  final DateTime? servedAt;
  final DateTime? cancelledAt;
  final List<StaffOrderItem> items;

  const StaffOrder({
    required this.id,
    required this.submittedAt,
    this.servedAt,
    this.cancelledAt,
    this.items = const [],
  });

  bool get isCancelled => cancelledAt != null;
  bool get isServed => servedAt != null;

  List<StaffOrderItem> get activeItems =>
      items.where((it) => !it.isRemoved).toList();

  /// Сервирана е, но поне една бройка все още не е минала през касата -
  /// реален сценарий при опашка на КА (виж бележника, разговора за Маса 7).
  bool get needsKaAttention =>
      !isCancelled && activeItems.any((it) => it.needsAttention);

  double get confirmedTotal => activeItems
      .where((it) => it.isConfirmed)
      .fold(0.0, (sum, it) => sum + it.priceEur);

  /// Клиентът може сам да откаже поръчката само докато персоналът не я е
  /// докоснал - виж POST /api/customer/tables/:n/orders/:id/cancel, същото
  /// условие е приложено и server-side (409, ако вече е сервирана/потвърдена).
  bool get customerCancellable =>
      !isCancelled && !isServed && !items.any((it) => it.isConfirmed);

  factory StaffOrder.fromJson(Map<String, dynamic> json) {
    return StaffOrder(
      id: json['id'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      servedAt: json['servedAt'] == null
          ? null
          : DateTime.parse(json['servedAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      items: (json['items'] as List? ?? const [])
          .map((e) => StaffOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Сметката на цяла маса - групира всички кръгове поръчки от началото на
/// седенето, за да "Фактуриран" покрива всичко, не само последния кръг.
class TableSessionDetail {
  final int tableNumber;
  final List<StaffOrder> orders;

  const TableSessionDetail({required this.tableNumber, this.orders = const []});

  List<StaffOrder> get activeOrders =>
      orders.where((o) => !o.isCancelled).toList();

  double get total =>
      activeOrders.fold(0.0, (sum, o) => sum + o.confirmedTotal);

  /// За клиентския статус екран - очакваната сметка от ВСИЧКИ неотказани
  /// бройки, не само вече потвърдените в КА (виж [total]) - иначе клиентът
  /// вижда 0.00 € веднага след поръчка, преди персоналът да е стигнал до нея.
  double get estimatedTotal => activeOrders.fold(
    0.0,
    (sum, o) => sum + o.activeItems.fold(0.0, (s, it) => s + it.priceEur),
  );

  bool get needsKaAttention => activeOrders.any((o) => o.needsKaAttention);

  /// Готова за фактуриране - има поне един активен ред и всяка негова
  /// НЕизтрита бройка е потвърдена в КА.
  bool get readyToInvoice =>
      activeOrders.isNotEmpty &&
      activeOrders.every((o) => o.activeItems.every((it) => it.isConfirmed));

  factory TableSessionDetail.fromJson(Map<String, dynamic> json) {
    return TableSessionDetail(
      tableNumber: json['tableNumber'] as int,
      orders: (json['orders'] as List? ?? const [])
          .map((e) => StaffOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum TableTileState { free, waiting, needsKa, served }

/// Ред за плочка в таблото (Функция 1, "Табло с общ преглед на всички маси").
class TableSummary {
  final int tableNumber;
  final TableTileState state;

  const TableSummary({required this.tableNumber, required this.state});

  factory TableSummary.fromJson(Map<String, dynamic> json) {
    final state = switch (json['state'] as String? ?? 'free') {
      'waiting' => TableTileState.waiting,
      'needsKa' => TableTileState.needsKa,
      'served' => TableTileState.served,
      _ => TableTileState.free,
    };
    return TableSummary(tableNumber: json['tableNumber'] as int, state: state);
  }
}

/// Резултат от търсенето в бележника - олекотен изглед на [Product],
/// зареден от сървъра (не от bundled menu.json), защото цената трябва да е
/// винаги актуалната от базата в момента на поръчката.
class StaffProduct {
  final String id;
  final String nameBg;
  final String nameEn;
  final double priceEur;
  final String categoryId;

  const StaffProduct({
    required this.id,
    required this.nameBg,
    required this.nameEn,
    required this.priceEur,
    required this.categoryId,
  });

  factory StaffProduct.fromJson(Map<String, dynamic> json) {
    return StaffProduct(
      id: json['id'] as String,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      priceEur: double.tryParse(json['priceEur'].toString()) ?? 0,
      categoryId: json['categoryId'] as String? ?? '',
    );
  }
}
