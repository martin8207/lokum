import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../core/services/menu_service.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../../order/widgets/order_bar.dart';
import '../widgets/category_card.dart';
import 'subcategory_page.dart';

/// Начална страница на менюто – показва категориите от най-високо ниво
/// (Нещо за хапване / Коктейли / Напитки), заредени от menu.json.
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late Future<Menu> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = MenuService.instance.loadMenu();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lang == AppLang.bg ? 'Меню' : 'Menu'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: FutureBuilder<Menu>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      lang == AppLang.bg
                          ? 'Възникна грешка при зареждане на менюто: ${snapshot.error}'
                          : 'Failed to load the menu: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final categories = snapshot.data!.categories;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    category: category,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubcategoryPage(category: category),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          bottomNavigationBar: const OrderBar(),
        );
      },
    );
  }
}
