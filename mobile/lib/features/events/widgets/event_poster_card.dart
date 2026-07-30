import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';

/// Постер-плочка за предстоящо събитие: снимка отгоре, заглавие/дата/
/// описание в четим текстов блок под нея (не върху снимката).
class EventPosterCard extends StatelessWidget {
  final BarEvent event;
  final AppLang lang;
  final VoidCallback? onTap;

  const EventPosterCard({
    super.key,
    required this.event,
    required this.lang,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = event.formattedDate(lang);
    final cardSubtitle = event.cardSubtitle(lang);
    final posterPath = event.posterImage == null
        ? null
        : AssetPaths.eventImage(event.posterImage!);
    final hasPoster = posterPath != null && BundledAssets.has(posterPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPoster)
                      Image.asset(posterPath, fit: BoxFit.cover)
                    else
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.event,
                          size: 56,
                          color: theme.hintColor,
                        ),
                      ),
                    if (event.isHappeningNow)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3DBE6C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lang == AppLang.bg ? 'СЕГА' : 'NOW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                    if (cardSubtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
