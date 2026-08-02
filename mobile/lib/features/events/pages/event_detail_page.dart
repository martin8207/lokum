import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/social_button.dart';
import '../../../shared/widgets/theme_toggle.dart';

/// Пълен изглед на предстоящо събитие: голямо лого/изображение, пълен текст
/// и телефон за връзка (tappable `tel:` линк).
class EventDetailPage extends StatelessWidget {
  final BarEvent event;

  const EventDetailPage({super.key, required this.event});

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final theme = Theme.of(context);
        final date = event.formattedDate(lang);
        final description = event.description(lang);
        final logoPath = event.logoImage == null
            ? null
            : AssetPaths.eventImage(event.logoImage!);
        final hasLogo = logoPath != null && BundledAssets.has(logoPath);

        return Scaffold(
          appBar: AppBar(
            title: Text(event.title(lang)),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: ThemeToggle(),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (hasLogo)
                // Без фиксиран aspect ratio - снимката пази естествените си
                // пропорции на цяла ширина (без изрязване И без черни ленти).
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    logoPath,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                event.title(lang),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 6),
                Text(
                  date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: 16),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              if (event.instagramUrl != null ||
                  event.facebookUrl != null ||
                  event.tiktokUrl != null ||
                  event.youtubeUrl != null ||
                  event.spotifyUrl != null ||
                  event.appleMusicUrl != null) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (event.instagramUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.instagramLogo,
                        fallbackIcon: Icons.camera_alt,
                        fallbackColor: const Color(0xFFE1306C),
                        tooltip: 'Instagram',
                        onTap: () => _openUrl(event.instagramUrl!),
                      ),
                    if (event.facebookUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.facebookLogo,
                        fallbackIcon: Icons.facebook,
                        fallbackColor: const Color(0xFF1877F2),
                        tooltip: 'Facebook',
                        onTap: () => _openUrl(event.facebookUrl!),
                      ),
                    if (event.tiktokUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.tiktokLogo,
                        fallbackIcon: Icons.music_note,
                        fallbackColor: theme.colorScheme.onSurface,
                        tooltip: 'TikTok',
                        onTap: () => _openUrl(event.tiktokUrl!),
                      ),
                    if (event.youtubeUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.youtubeLogo,
                        fallbackIcon: Icons.play_circle_fill,
                        fallbackColor: const Color(0xFFFF0000),
                        tooltip: 'YouTube',
                        onTap: () => _openUrl(event.youtubeUrl!),
                      ),
                    if (event.spotifyUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.spotifyLogo,
                        fallbackIcon: Icons.music_note,
                        fallbackColor: const Color(0xFF1DB954),
                        tooltip: 'Spotify',
                        onTap: () => _openUrl(event.spotifyUrl!),
                      ),
                    if (event.appleMusicUrl != null)
                      SocialButton(
                        logoPath: AssetPaths.appleMusicLogo,
                        fallbackIcon: Icons.music_note,
                        fallbackColor: const Color(0xFFFA243C),
                        tooltip: 'Apple Music',
                        onTap: () => _openUrl(event.appleMusicUrl!),
                      ),
                  ],
                ),
              ],
              if (event.phone != null && event.phone!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.phone, color: theme.colorScheme.primary),
                    title: Text(event.phone!),
                    subtitle: Text(
                      lang == AppLang.bg ? 'За връзка' : 'Contact',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _callPhone(event.phone!),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
