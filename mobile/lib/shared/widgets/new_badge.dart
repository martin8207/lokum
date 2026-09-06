import 'package:flutter/material.dart';

/// Плътен зелен таг с бял кант за "Ново" - използва се и върху снимката на
/// продуктовата карта (долу вдясно), и в detail екрана, за да изглежда
/// еднакво навсякъде (виж разговора за вариант Б от двата предложени).
class NewBadge extends StatelessWidget {
  final String label;

  const NewBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
