import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(logoPath, fit: BoxFit.cover),
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
