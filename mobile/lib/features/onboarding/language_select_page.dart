import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/asset_paths.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/featured_background.dart';
import '../home/home_page.dart';

/// Първият екран след сканиране на QR кода: лого на бара и избор на език.
/// Задава [AppLanguage.instance] и подменя екрана с [HomePage] (без връщане
/// назад към избора на език чрез бутона "Назад").
class LanguageSelectPage extends StatelessWidget {
  const LanguageSelectPage({super.key});

  void _selectLanguage(BuildContext context, AppLang lang) {
    AppLanguage.instance.value = lang;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: FeaturedBackground(
        child: SafeArea(
          // LayoutBuilder + SingleChildScrollView + ConstrainedBox(minHeight)
          // - центрира съдържанието, когато се събира на екрана (както
          // преди), но скролва вместо да overflow-не, ако логото/съдържанието
          // не се съберат (напр. при голямо лого или нисък екран).
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ширина на логото като % от наличното място (не фиксирани
              // пиксели) - на 360px телефон fixed 560px overflow-ваше
              // хоризонтално. Височината следва реалния аспект на
              // изрязаните лога (1080x645), за да няма нито overflow, нито
              // разтягане/пилърбокс.
              final logoWidth = (constraints.maxWidth * 0.75).clamp(
                220.0,
                340.0,
              );
              final logoHeight = logoWidth * 645 / 1080;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: SizedBox(
                                      height: logoHeight,
                                      width: logoWidth,
                                      child: Image.asset(
                                        AssetPaths.logoFor(
                                          Theme.of(context).brightness,
                                          AppLanguage.instance.value,
                                        ),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) => Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.local_bar,
                                                  size: 72,
                                                  color: colors.accent,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'LOKUM',
                                                  style: brandTextStyle(
                                                    color: colors.accent,
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.w700,
                                                  ).copyWith(letterSpacing: 4),
                                                ),
                                              ],
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  Text(
                                    'Изберете език  ·  Choose your language',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _LanguageButton(
                                    flagAsset: AssetPaths.flagBg,
                                    flagEmoji: '🇧🇬',
                                    label: 'БЪЛГАРСКИ',
                                    onTap: () =>
                                        _selectLanguage(context, AppLang.bg),
                                  ),
                                  const SizedBox(height: 14),
                                  _LanguageButton(
                                    flagAsset: AssetPaths.flagGb,
                                    flagEmoji: '🇬🇧',
                                    label: 'ENGLISH',
                                    onTap: () =>
                                        _selectLanguage(context, AppLang.en),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const _CreditsFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Малък надпис в долния край на заглавната страница.
class _CreditsFooter extends StatelessWidget {
  const _CreditsFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered by OpenAI · Claude',
            style: TextStyle(
              color: colors.textMuted.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Created by Martin Dragozov',
            style: TextStyle(
              color: colors.textMuted.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flagAsset;
  final String flagEmoji;
  final String label;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flagAsset,
    required this.flagEmoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Флагче като снимка (не emoji) - CanvasKit тегли Noto emoji fallback
    // шрифта от fonts.gstatic.com при среща на emoji, което е излишен CDN
    // fetch само за 2 знака. Ако снимката все още не е качена, пада
    // обратно към emoji-то.
    final flagWidget = BundledAssets.has(flagAsset)
        ? ClipOval(
            child: Image.asset(flagAsset, width: 40, height: 40, fit: BoxFit.cover),
          )
        : Text(flagEmoji, style: const TextStyle(fontSize: 22));
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            flagWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
