import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';

/// Карта за минало събитие в архива: миниатюра (ако има) + заглавие + кратка
/// дата. Пълните снимки/видеа излизат в detail екрана след тап.
class ArchiveEventCard extends StatelessWidget {
  final BarEvent event;
  final AppLang lang;
  final VoidCallback? onTap;

  const ArchiveEventCard({
    super.key,
    required this.event,
    required this.lang,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = event.formattedDateShort(lang);
    final logoPath = event.logoImage == null
        ? null
        : AssetPaths.eventImage(event.logoImage!);
    final hasLogo = logoPath != null && BundledAssets.has(logoPath);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: hasLogo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  logoPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.event_note, color: theme.colorScheme.primary),
        title: Text(
          event.title(lang),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: date == null ? null : Text(date),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
