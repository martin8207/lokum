/// Централни константи за пътища до assets + лек, self-contained
/// избор на език (BG/EN), споделен между всички menu страници.
///
/// Ако проектът вече има собствено решение за смяна на език (Provider,
/// Riverpod, BLoC и т.н.), просто заменете `AppLanguage` по-долу с него —
/// всички widget-и тук четат езика само през `AppLanguage.instance`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../shared/models/product.dart';

class AssetPaths {
  AssetPaths._();

  /// Логото на бара за тъмна тема, показвано след сканиране на QR код.
  static const String logoDark = 'assets/logos/logo.jpg';

  /// Логото на бара за светла тема (отделен файл, четим на светъл фон).
  static const String logoLight = 'assets/logos/lokum_light_logo.jpg';

  /// Правилното лого според текущата тема.
  static String logoFor(Brightness brightness) =>
      brightness == Brightness.light ? logoLight : logoDark;

  /// Генерираният от tools/excel_to_json.py каталог с продукти.
  static const String menuJson = 'assets/data/menu.json';

  /// QR код към публичния адрес на апа, генериран от scripts/generate-qr.js.
  static const String menuQr = 'assets/qr/menu-qr.png';

  /// Оригинални цветни лога на социалните мрежи (не Material икони - за да
  /// пазим истинските брандови цветове/градиент, особено на Instagram).
  static const String facebookLogo = 'assets/icons/facebook.webp';
  static const String instagramLogo = 'assets/icons/instagram.webp';

  /// По желание: фонова снимка (напр. за промотирано събитие) на екрана за
  /// избор на език и началния екран - виж [FeaturedBackground]. Ако файлът
  /// липсва, страниците изглеждат както обичайно (без фон).
  static const String featuredBackground =
      'assets/campaign/featured_background.jpg';

  /// Директория с продуктови снимки (bundled в приложението).
  /// Очакван формат на файловете: `product.image`, напр. "glarus_500.webp".
  static const String productImagesDir = 'assets/images/products';

  /// Placeholder, показван когато продуктова снимка липсва/не се зарежда.
  static const String placeholderImage = 'assets/images/placeholder.png';

  /// Пълен път до снимката на даден продукт. Ако `fileName` вече е път
  /// (напр. "beer/glarus/pale_ale.jpg", зададен ръчно в excel-а), се ползва
  /// директно спрямо `assets/`. Иначе се очаква плосък файл в
  /// [productImagesDir], по конвенция `product.id` + ".webp".
  static String productImage(String fileName) {
    if (fileName.contains('/')) return 'assets/$fileName';
    return '$productImagesDir/$fileName';
  }

  /// Пълен път до снимка на събитие (постер/галерия), зададена в
  /// `events.json` спрямо `assets/`, напр. "events/brunch/brunch.jpg".
  static String eventImage(String relativePath) => 'assets/$relativePath';
}

/// Дали даден asset е реално bundle-нат в приложението. Използва се, за да
/// не показваме/отваряме снимка за артикули, които все още нямат такава —
/// повечето продукти в менюто засега са само текст, без снимка.
///
/// Трябва да се зареди веднъж в main() чрез [ensureLoaded], преди runApp().
class BundledAssets {
  BundledAssets._();

  static Set<String>? _keys;

  static Future<void> ensureLoaded() async {
    if (_keys != null) return;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _keys = manifest.listAssets().toSet();
  }

  /// Дали `path` е наличен като bundled asset. Връща false, докато
  /// [ensureLoaded] все още не е приключил.
  static bool has(String path) => _keys?.contains(path) ?? false;
}

/// Много лек, глобален избор на език. Задайте стойността на екрана за
/// избор на език (EN/БГ) след сканиране на QR кода:
///
/// ```dart
/// AppLanguage.instance.value = AppLang.bg;
/// ```
///
/// Всички menu widget-и слушат тази стойност чрез `ValueListenableBuilder`
/// и се обновяват автоматично при смяна на езика.
class AppLanguage {
  AppLanguage._();

  static final ValueNotifier<AppLang> instance = ValueNotifier<AppLang>(
    AppLang.bg,
  );
}
