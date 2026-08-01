import 'package:flutter/material.dart';

import '../../core/asset_paths.dart';

/// Слага [AssetPaths.featuredBackground] като фонова снимка зад [child],
/// с притъмняващ градиент отгоре за четимост на текста. Ако файлът все
/// още не е качен, просто връща [child] непроменен - страницата изглежда
/// точно както сега, без нужда от промяна в кода, щом снимката пристигне.
class FeaturedBackground extends StatelessWidget {
  final Widget child;

  const FeaturedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!BundledAssets.has(AssetPaths.featuredBackground)) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.featuredBackground, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
