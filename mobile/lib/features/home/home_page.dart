import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/asset_paths.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/featured_background.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../about/about_page.dart';
import '../about/contact_page.dart';
import '../events/pages/events_page.dart';
import '../menu/pages/menu_page.dart';
import '../menu/widgets/language_switch.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          body: FeaturedBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          ThemeToggle(),
                          SizedBox(width: 8),
                          LanguageSwitch(),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                height: 130,
                                width: 220,
                                child: Image.asset(
                                  AssetPaths.logoFor(
                                    Theme.of(context).brightness,
                                  ),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.local_bar,
                                            size: 56,
                                            color: colors.accent,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "LOKUM",
                                            style: brandTextStyle(
                                              color: colors.accent,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                            ).copyWith(letterSpacing: 2),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "riffs & drinks",
                              style: TextStyle(
                                color: colors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              lang == AppLang.bg
                                  ? "Добре дошли в Бар Локум"
                                  : "Welcome to Bar Lokum",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textMain,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      _buildCard(
                        context: context,
                        colors: colors,
                        icon: Icons.restaurant_menu,
                        title: lang == AppLang.bg ? "Меню" : "Menu",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MenuPage()),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildCard(
                        context: context,
                        colors: colors,
                        icon: Icons.music_note,
                        title: lang == AppLang.bg ? "Събития" : "Events",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EventsPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildCard(
                        context: context,
                        colors: colors,
                        icon: Icons.info_outline,
                        title: lang == AppLang.bg ? "За Lokum" : "About Lokum",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutPage(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildCard(
                        context: context,
                        colors: colors,
                        icon: Icons.phone,
                        title: lang == AppLang.bg ? "Контакти" : "Contacts",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required LokumColors colors,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: ListTile(
        hoverColor: colors.hoverOnSurface,
        splashColor: colors.splashOnSurface,
        leading: Icon(icon, color: colors.accent),
        title: Text(
          title,
          // Изрично взето от textTheme (Nunito), за да съвпада сигурно с
          // шрифта на менюто/продуктовите карти.
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: colors.textMain,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
