import 'package:flutter/material.dart';

import '../../core/asset_paths.dart';

/// Бутон за социална мрежа/платформа: показва истинското цветно лого
/// (bundled asset), ако е налично, иначе избледнява до Material икона в
/// приблизителния брандов цвят - докато реалният файл бъде добавен в
/// assets/icons/.
class SocialButton extends StatelessWidget {
  final String logoPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final String tooltip;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.logoPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = BundledAssets.has(logoPath);
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 36,
      icon: hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(logoPath, width: 36, height: 36),
            )
          : Icon(fallbackIcon, color: fallbackColor),
    );
  }
}
