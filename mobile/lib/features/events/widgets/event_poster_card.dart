import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';

/// Постер-плочка за предстоящо събитие: снимка на цяла ширина с
/// градиент, заглавие и дата отгоре.
class EventPosterCard extends StatelessWidget {
  final BarEvent event;
  final AppLang lang;

  const EventPosterCard({super.key, required this.event, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = event.formattedDate(lang);
    final description = event.description(lang);
    final posterPath = event.posterImage == null
        ? null
        : AssetPaths.eventImage(event.posterImage!);
    final hasPoster = posterPath != null && BundledAssets.has(posterPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPoster)
              Image.asset(posterPath, fit: BoxFit.cover)
            else
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.event, size: 56, color: theme.hintColor),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.4, 1],
                ),
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title(lang),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: Colors.white70)),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
