import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/asset_paths.dart';
import '../../../core/services/order_cart_service.dart';
import '../../../shared/models/product.dart';

/// Избор на номер на маса преди първата поръчка - клиентът трябва да каже
/// на приложението къде седи, за да стигне поръчката до правилния сервитьор
/// (виж бележника на персонала - таблото се организира по номер на маса).
class OrderTableEntryPage extends StatelessWidget {
  static const _minTable = 1;
  static const _maxTable = 14;

  const OrderTableEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              lang == AppLang.bg ? 'На коя маса си?' : 'Which table?',
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lang == AppLang.bg
                      ? 'Избери номера на масата си, за да стигне поръчката ти до персонала.'
                      : 'Pick your table number so your order reaches the staff.',
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: _maxTable - _minTable + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final number = _minTable + index;
                      return Material(
                        color: colors.menuCardBackground,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await OrderCartService.instance.setTableNumber(
                              number,
                            );
                            if (context.mounted) {
                              Navigator.pop(context, number);
                            }
                          },
                          child: Center(
                            child: Text(
                              '$number',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colors.menuCardText,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
