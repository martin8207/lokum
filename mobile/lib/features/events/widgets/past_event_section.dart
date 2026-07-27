import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
import '../../gallery/photo_viewer_page.dart';

/// Минало събитие: заглавие, дата и решетка със снимки от галерията.
/// Докосването на снимка отваря цял екран преглед.
class PastEventSection extends StatelessWidget {
  final BarEvent event;
  final AppLang lang;

  const PastEventSection({super.key, required this.event, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = event.formattedDate(lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title(lang),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 2),
            Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final photos = event.galleryImages
                  .map(AssetPaths.eventImage)
                  .where(BundledAssets.has)
                  .toList();
              if (photos.isEmpty) {
                return Text(
                  lang == AppLang.bg
                      ? 'Няма качени снимки от това събитие.'
                      : 'No photos uploaded for this event.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final image = photos[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerPage(
                            images: photos,
                            initialIndex: index,
                            heroTagPrefix: event.id,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: '${event.id}_$image',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(image, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
