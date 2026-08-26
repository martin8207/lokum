/// Модели за менюто на бара: Product, Subcategory, MenuCategory.
///
/// Съответстват 1:1 на JSON структурата, генерирана от
/// `tools/excel_to_json.py` в `mobile/assets/data/menu.json`.
library;

/// Поддържани езици в приложението.
enum AppLang { bg, en }

extension AppLangCode on AppLang {
  String get code => this == AppLang.bg ? 'bg' : 'en';
}

class Product {
  final String id;
  final String categoryId;
  final String subcategoryId;
  final String? brand;
  final String? variant;
  final String nameBg;
  final String nameEn;
  final String? descriptionBg;
  final String? descriptionEn;
  final double priceEur;
  final double? quantity;
  final String? unit;
  final String image;
  final bool featured;
  final bool isNew;
  final bool isRecommended;
  final bool available;
  final List<String> tags;
  final List<String> allergens;

  const Product({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.nameBg,
    required this.nameEn,
    required this.priceEur,
    required this.image,
    this.brand,
    this.variant,
    this.descriptionBg,
    this.descriptionEn,
    this.quantity,
    this.unit,
    this.featured = false,
    this.isNew = false,
    this.isRecommended = false,
    this.available = true,
    this.tags = const [],
    this.allergens = const [],
  });

  /// Локализирано име според избрания език.
  String name(AppLang lang) => lang == AppLang.bg ? nameBg : nameEn;

  /// Локализирано описание (може да липсва).
  String? description(AppLang lang) {
    final value = lang == AppLang.bg ? descriptionBg : descriptionEn;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Форматирана цена, напр. "3.30 €".
  String formattedPrice() => '${priceEur.toStringAsFixed(2)} €';

  /// Порция/обем, напр. "500 ml" или "200 g". Null ако липсва.
  String? formattedQuantity() {
    if (quantity == null || unit == null) return null;
    final q = quantity!;
    final qStr = q == q.roundToDouble() ? q.toInt().toString() : q.toString();
    return '$qStr $unit';
  }

  static String? _prettify(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// "Модел" — марка + вариант, разчетени от excel-ските id-та (напр.
  /// "glarus"/"pale_ale" -> "Glarus · Pale Ale"). Null ако липсват и двете.
  String? formattedModel() {
    final b = _prettify(brand);
    final v = _prettify(variant);
    if (b == null) return v;
    if (v == null) return b;
    return '$b · $v';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return Product(
      id: id,
      categoryId: json['categoryId'] as String,
      subcategoryId: json['subcategoryId'] as String,
      brand: json['brand'] as String?,
      variant: json['variant'] as String?,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      descriptionBg: json['descriptionBg'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      priceEur: (json['priceEur'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      image: json['image'] as String? ?? '$id.webp',
      featured: json['featured'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      allergens:
          (json['allergens'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class Subcategory {
  final String id;
  final String nameBg;
  final String nameEn;
  final List<Product> products;

  const Subcategory({
    required this.id,
    required this.nameBg,
    required this.nameEn,
    required this.products,
  });

  String name(AppLang lang) => lang == AppLang.bg ? nameBg : nameEn;

  /// Брой налични продукти в подкатегорията.
  int get availableCount => products.where((p) => p.available).length;

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    final productsJson = (json['products'] as List? ?? const []);
    return Subcategory(
      id: json['id'] as String,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      products: productsJson
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuCategory {
  final String id;
  final String nameBg;
  final String nameEn;
  final List<Subcategory> subcategories;

  const MenuCategory({
    required this.id,
    required this.nameBg,
    required this.nameEn,
    required this.subcategories,
  });

  String name(AppLang lang) => lang == AppLang.bg ? nameBg : nameEn;

  /// Общ брой продукти във всички подкатегории.
  int get productCount =>
      subcategories.fold(0, (sum, s) => sum + s.products.length);

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final subsJson = (json['subcategories'] as List? ?? const []);
    return MenuCategory(
      id: json['id'] as String,
      nameBg: json['nameBg'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      subcategories: subsJson
          .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Наименование на алерген (по числовия код от excel-а), за да не показваме
/// голи числа на клиента. Идва от листа "allergens" в excel-а.
class AllergenInfo {
  final String id;
  final String nameBg;
  final String nameEn;
  final String? descriptionBg;
  final String? descriptionEn;

  const AllergenInfo({
    required this.id,
    required this.nameBg,
    required this.nameEn,
    this.descriptionBg,
    this.descriptionEn,
  });

  String name(AppLang lang) => lang == AppLang.bg ? nameBg : nameEn;

  String? description(AppLang lang) {
    final value = lang == AppLang.bg ? descriptionBg : descriptionEn;
    return (value == null || value.isEmpty) ? null : value;
  }

  factory AllergenInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    return AllergenInfo(
      id: id,
      nameBg: json['nameBg'] as String? ?? id,
      nameEn: json['nameEn'] as String? ?? id,
      descriptionBg: json['descriptionBg'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
    );
  }
}

/// Целият, разпарснат menu.json.
class Menu {
  final DateTime? generatedAt;
  final int productCount;
  final List<MenuCategory> categories;
  final List<AllergenInfo> allergenLegend;

  const Menu({
    required this.categories,
    this.generatedAt,
    this.productCount = 0,
    this.allergenLegend = const [],
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final categoriesJson = (json['categories'] as List? ?? const []);
    final allergenLegendJson = (json['allergenLegend'] as List? ?? const []);
    return Menu(
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? ''),
      productCount: json['productCount'] as int? ?? 0,
      categories: categoriesJson
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      allergenLegend: allergenLegendJson
          .map((e) => AllergenInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Локализирано име на алерген по неговия код, напр. "7" -> "Мляко".
  /// Ако кодът липсва в легендата, връща самия код като fallback.
  String allergenName(String code, AppLang lang) {
    for (final a in allergenLegend) {
      if (a.id == code) return a.name(lang);
    }
    return code;
  }
}
