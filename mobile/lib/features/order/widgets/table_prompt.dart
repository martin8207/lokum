import 'package:flutter/material.dart';

import '../../../core/services/order_cart_service.dart';
import '../../../shared/models/product.dart';
import '../pages/order_table_entry_page.dart';

/// При първото добавяне в количката, ако клиентът още не е казал на коя
/// маса седи, го подканваме веднага - вместо да чака чак до финалното
/// "Поръчай" в количката, за да не се обърка после накъде да прати поръчката.
Future<void> promptTableIfNeeded(BuildContext context, AppLang lang) async {
  if (OrderCartService.instance.tableNumber != null) return;
  if (!context.mounted) return;

  final choose = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        lang == AppLang.bg ? 'На коя маса си?' : 'Which table are you at?',
      ),
      content: Text(
        lang == AppLang.bg
            ? 'Избери номера на масата си, за да стигне поръчката ти до персонала.'
            : 'Pick your table number so your order reaches the staff.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(lang == AppLang.bg ? 'По-късно' : 'Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(lang == AppLang.bg ? 'Избери маса' : 'Pick table'),
        ),
      ],
    ),
  );

  if (choose == true && context.mounted) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OrderTableEntryPage()));
  }
}
