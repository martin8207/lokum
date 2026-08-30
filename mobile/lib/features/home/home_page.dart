import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/asset_paths.dart';
import '../../core/services/events_service.dart';
import '../../core/services/staff_api.dart';
import '../../shared/models/event.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/featured_background.dart';
import '../../shared/widgets/theme_toggle.dart';
import '../about/about_page.dart';
import '../about/contact_page.dart';
import '../events/pages/events_page.dart';
import '../menu/pages/menu_page.dart';
import '../menu/widgets/language_switch.dart';
import '../staff/pages/staff_dashboard_page.dart';
import '../staff/pages/staff_login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Постерът за бутона "Събития" се сменя автоматично според съдържанието
  // на events.json - виж lokum-events-button-task.md. Няма нужда от ръчна
  // намеса тук, когато събитие мине или се добави ново предстоящо.
  BarEvent? _nearestUpcomingEvent;

  @override
  void initState() {
    super.initState();
    _loadNearestUpcomingEvent();
  }

  Future<void> _loadNearestUpcomingEvent() async {
    final events = await EventsService.instance.loadEvents();
    final now = DateTime.now();
    final dated =
        events.upcoming
            .where((e) => e.date != null && e.date!.isAfter(now))
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));
    if (!mounted) return;
    setState(() {
      _nearestUpcomingEvent = dated.isEmpty ? null : dated.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        // Ширина на логото като % от екрана (не фиксирани пиксели) - на
        // 360px телефон fixed 440px overflow-ваше хоризонтално. Височината
        // следва реалния аспект на изрязаните лога (1080x645).
        final logoWidth = (MediaQuery.sizeOf(context).width * 0.7).clamp(
          200.0,
          320.0,
        );
        final logoHeight = logoWidth * 645 / 1080;
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Бележник на персонала (v2.0, само в test/
                          // lokum-web-v2 build-а) - зад споделена парола
                          // (lokum-version2-planning.md, Функция 2), за да
                          // остане недостъпен за клиенти, щом този build
                          // някога стане публичен. Вляво, а не до theme/
                          // language - да не се трупат и трите от една страна.
                          IconButton(
                            icon: Icon(Icons.settings, color: colors.textMuted),
                            onPressed: () async {
                              await StaffApi.instance.loadStoredToken();
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StaffApi.instance.isLoggedIn
                                      ? const StaffDashboardPage()
                                      : const StaffLoginPage(),
                                ),
                              );
                            },
                          ),
                          Row(
                            children: const [
                              ThemeToggle(),
                              SizedBox(width: 8),
                              LanguageSwitch(),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                height: logoHeight,
                                width: logoWidth,
                                child: Image.asset(
                                  AssetPaths.logoFor(
                                    Theme.of(context).brightness,
                                    lang,
                                  ),
                                  fit: BoxFit.contain,
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

                      _buildEventsCard(
                        context: context,
                        colors: colors,
                        title: lang == AppLang.bg ? "Събития" : "Events",
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

  void _openEvents(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsPage()),
    );
  }

  /// Бутонът "Събития" - виж lokum-events-button-task.md. Ако има предстоящо
  /// събитие с постер, качен вече чрез обичайния flow за създаване на
  /// събитие, бутонът става по-висок с постера като фон. Иначе (няма
  /// предстоящи или нито едно няма постер) пада обратно към стандартния
  /// плътен бутон, без визуална разлика от другите три.
  Widget _buildEventsCard({
    required BuildContext context,
    required LokumColors colors,
    required String title,
  }) {
    final posterImage = _nearestUpcomingEvent?.posterImage;
    final posterPath = posterImage == null
        ? null
        : AssetPaths.eventImage(posterImage);
    final hasPoster = posterPath != null && BundledAssets.has(posterPath);

    if (!hasPoster) {
      return _buildCard(
        context: context,
        colors: colors,
        icon: Icons.music_note,
        title: title,
        onTap: () => _openEvents(context),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 150,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openEvents(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(posterPath, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromRGBO(20, 10, 40, 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: Color(0xFFF3C94A),
                      size: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
