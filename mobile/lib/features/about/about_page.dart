import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/asset_paths.dart';
import '../../core/services/venue_service.dart';
import '../../shared/models/product.dart';
import '../../shared/models/venue.dart';
import '../../shared/widgets/social_button.dart';
import '../../shared/widgets/theme_toggle.dart';

/// Отваря Facebook страницата на бара - през нативното приложение, ако е
/// инсталирано, иначе fallback към браузъра.
Future<void> _openFacebookPage() async {
  const pageId = '61574669643238';
  const webUrl = 'https://www.facebook.com/profile.php?id=$pageId';
  final fbAppUrl = Uri.parse('fb://page/$pageId');
  final fallbackUrl = Uri.parse(webUrl);

  if (await canLaunchUrl(fbAppUrl)) {
    await launchUrl(fbAppUrl);
  } else {
    await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
  }
}

/// Отваря Instagram профила на бара - през нативното приложение, ако е
/// инсталирано, иначе fallback към браузъра.
Future<void> _openInstagramPage() async {
  const username = 'lokum.riffsndrinks';
  const webUrl = 'https://www.instagram.com/$username';
  final igAppUrl = Uri.parse('instagram://user?username=$username');
  final fallbackUrl = Uri.parse(webUrl);

  if (await canLaunchUrl(igAppUrl)) {
    await launchUrl(igAppUrl);
  } else {
    await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
  }
}

/// Раздел "За Lokum": описание на бара и работно време.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late Future<VenueInfo> _venueFuture;

  @override
  void initState() {
    super.initState();
    _venueFuture = VenueService.instance.loadVenue();
  }

  static const _dayLabelsBg = [
    'Понеделник',
    'Вторник',
    'Сряда',
    'Четвъртък',
    'Петък',
    'Събота',
    'Неделя',
  ];
  static const _dayLabelsEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lang == AppLang.bg ? 'За Lokum' : 'About Lokum'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: FutureBuilder<VenueInfo>(
            future: _venueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    lang == AppLang.bg
                        ? 'Възникна грешка при зареждане: ${snapshot.error}'
                        : 'Failed to load: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final venue = snapshot.data!;
              final theme = Theme.of(context);
              final days = lang == AppLang.bg ? _dayLabelsBg : _dayLabelsEn;
              final hours = [
                venue.workingHours.monday,
                venue.workingHours.tuesday,
                venue.workingHours.wednesday,
                venue.workingHours.thursday,
                venue.workingHours.friday,
                venue.workingHours.saturday,
                venue.workingHours.sunday,
              ];

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_bar, size: 64, color: colors.accent),
                        const SizedBox(height: 12),
                        Text(
                          venue.name,
                          style: brandTextStyle(
                            color: colors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (venue.slogan.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            venue.slogan,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                        if (venue.address(lang).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            venue.address(lang),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialButton(
                              logoPath: AssetPaths.facebookLogo,
                              fallbackIcon: Icons.facebook,
                              fallbackColor: const Color(0xFF1877F2),
                              tooltip: 'Facebook',
                              onTap: _openFacebookPage,
                            ),
                            const SizedBox(width: 16),
                            SocialButton(
                              logoPath: AssetPaths.instagramLogo,
                              fallbackIcon: Icons.camera_alt,
                              fallbackColor: const Color(0xFFE1306C),
                              tooltip: 'Instagram',
                              onTap: _openInstagramPage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (venue.description.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      venue.description,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!venue.workingHours.isEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      lang == AppLang.bg ? 'Работно време' : 'Opening Hours',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < 7; i++)
                              if (hours[i].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(days[i]),
                                      Text(
                                        hours[i],
                                        style: TextStyle(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (BundledAssets.has(AssetPaths.menuQr)) ...[
                    const SizedBox(height: 32),
                    Text(
                      lang == AppLang.bg ? 'Сподели менюто' : 'Share the menu',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Image.asset(
                          AssetPaths.menuQr,
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang == AppLang.bg
                          ? 'Сканирай, за да отвориш менюто на своя телефон'
                          : 'Scan to open the menu on your phone',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
