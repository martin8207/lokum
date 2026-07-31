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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              hasLogo
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        logoPath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title(lang),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Text(date, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
