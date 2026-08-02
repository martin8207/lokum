import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';

/// Карта на цяла ширина за специално/подчертано предстоящо събитие (напр.
/// концерт) - двойно по-широка от стандартните карти в 2-колонния grid.
/// Постерът е изцяло видим (`BoxFit.contain`, не се изрязва), а под него
/// излиза само едно кратко ред текст ([BarEvent.cardSubtitle]) - пълното
/// описание е само в detail екрана.
class FeaturedEventCard extends StatelessWidget {
  final BarEvent event;
  final AppLang lang;
  final VoidCallback? onTap;

  const FeaturedEventCard({
    super.key,
    required this.event,
    required this.lang,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterPath = event.posterImage == null
        ? null
        : AssetPaths.eventImage(event.posterImage!);
    final hasPoster = posterPath != null && BundledAssets.has(posterPath);
    final subtitle = event.cardSubtitle(lang);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Без фиксиран aspect ratio - снимката пази естествените си
            // пропорции на цяла ширина (без изрязване И без черни ленти).
            hasPoster
                ? Image.asset(
                    posterPath,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  )
                : Container(
                    height: 220,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.event,
                      size: 56,
                      color: theme.hintColor,
                    ),
                  ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
