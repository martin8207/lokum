import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/asset_paths.dart';
import '../../core/services/venue_service.dart';
import '../../shared/models/product.dart';
import '../../shared/models/venue.dart';
import '../../shared/widgets/theme_toggle.dart';

/// Раздел "Контакти": телефон, имейл, адрес и социални мрежи.
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late Future<VenueInfo> _venueFuture;

  @override
  void initState() {
    super.initState();
    _venueFuture = VenueService.instance.loadVenue();
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lang == AppLang.bg ? 'Контакти' : 'Contacts'),
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
              final rows = <Widget>[
                if (venue.phone.isNotEmpty)
                  _ContactTile(
                    icon: Icons.phone,
                    label: venue.phone,
                    colors: colors,
                    onTap: () => _launch(Uri(scheme: 'tel', path: venue.phone)),
                  ),
                if (venue.email.isNotEmpty)
                  _ContactTile(
                    icon: Icons.email_outlined,
                    label: venue.email,
                    colors: colors,
                    onTap: () =>
                        _launch(Uri(scheme: 'mailto', path: venue.email)),
                  ),
                if (venue.address(lang).isNotEmpty)
                  _ContactTile(
                    icon: Icons.location_on_outlined,
                    label: venue.address(lang),
                    colors: colors,
                    onTap: (venue.latitude != 0 || venue.longitude != 0)
                        ? () => _launch(
                            Uri.parse(
                              'https://maps.google.com/?q=${venue.latitude},${venue.longitude}',
                            ),
                          )
                        : null,
                  ),
                if (venue.website.isNotEmpty)
                  _ContactTile(
                    icon: Icons.language,
                    label: venue.website,
                    colors: colors,
                    onTap: () => _launch(Uri.parse(venue.website)),
                  ),
                if (venue.facebook.isNotEmpty)
                  _ContactTile(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    colors: colors,
                    onTap: () => _launch(Uri.parse(venue.facebook)),
                  ),
                if (venue.instagram.isNotEmpty)
                  _ContactTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Instagram',
                    colors: colors,
                    onTap: () => _launch(Uri.parse(venue.instagram)),
                  ),
              ];

              if (rows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.contact_phone_outlined,
                          size: 56,
                          color: colors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang == AppLang.bg
                              ? 'Контактите ще бъдат добавени скоро.'
                              : 'Contact details coming soon.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: rows,
              );
            },
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final LokumColors colors;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ListTile(
        hoverColor: colors.hoverOnSurface,
        splashColor: colors.splashOnSurface,
        leading: Icon(icon, color: colors.accent),
        title: Text(label),
        trailing: onTap == null
            ? null
            : Icon(Icons.chevron_right, color: colors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
