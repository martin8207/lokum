import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../../gallery/photo_viewer_page.dart';

/// Детайлен изглед на минало събитие: заглавие, дата и решетка със снимки
/// (видео поддръжка може да се добави по-късно - засега само снимки).
class ArchiveEventDetailPage extends StatelessWidget {
  final BarEvent event;

  const ArchiveEventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        final theme = Theme.of(context);
        final date = event.formattedDateShort(lang);
        final description = event.description(lang);
        final logoPath = event.logoImage == null
            ? null
            : AssetPaths.eventImage(event.logoImage!);
        final hasLogo = logoPath != null && BundledAssets.has(logoPath);
        final photos = event.galleryImages
            .map(AssetPaths.eventImage)
            .where(BundledAssets.has)
            .toList();

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
              if (hasLogo) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(logoPath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
                const SizedBox(height: 12),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 20),
              if (photos.isEmpty)
                Text(
                  lang == AppLang.bg
                      ? 'Няма качени снимки от това събитие.'
                      : 'No photos uploaded for this event.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                )
              else
                GridView.builder(
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
                ),
            ],
          ),
        );
      },
    );
  }
}
