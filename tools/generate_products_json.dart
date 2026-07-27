import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';

void main() {
  final excelFile = File('products_master.xlsx');

  if (!excelFile.existsSync()) {
    print('products_master.xlsx не е намерен!');
    return;
  }

  final bytes = excelFile.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  final sheet = excel.tables['Products'];

  if (sheet == null) {
    print('Лист Products липсва.');
    return;
  }

  final rows = sheet.rows;

  if (rows.isEmpty) {
    print('Листът е празен.');
    return;
  }

  final headers = rows.first
      .map((e) => e?.value.toString().trim() ?? '')
      .toList();

  dynamic value(List<Data?> row, String column) {
    final index = headers.indexOf(column);

    if (index == -1) return null;

    if (index >= row.length) return null;

    return row[index]?.value;
  }

  double? toDouble(dynamic v) {
    if (v == null) return null;

    if (v is num) return v.toDouble();

    final s = v.toString().replaceAll(',', '.').trim();

    if (s.isEmpty) return null;

    return double.tryParse(s);
  }

  bool toBool(dynamic v) {
    if (v == null) return false;

    final s = v.toString().toLowerCase();

    return s == 'true' ||
        s == '1' ||
        s == 'yes' ||
        s == 'да' ||
        s == 'x';
  }

  List<String> toList(dynamic v) {
    if (v == null) return [];

    final s = v.toString().trim();

    if (s.isEmpty) return [];

    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  final products = <Map<String, dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
    final row = rows[i];

    final product = <String, dynamic>{
      "id": value(row, "id")?.toString().trim(),

      "category": value(row, "category")?.toString().trim(),

      "subcategory": value(row, "subcategory")?.toString().trim(),

      "brand": value(row, "brand")?.toString().trim(),

      "variant": value(row, "variant")?.toString().trim(),

      "nameBg": value(row, "nameBg")?.toString().trim(),

      "nameEn": value(row, "nameEn")?.toString().trim(),

      "descriptionBg": value(row, "descriptionBg")?.toString().trim(),

      "descriptionEn": value(row, "descriptionEn")?.toString().trim(),

      "priceEur": toDouble(value(row, "priceEur")),

      "quantity": toDouble(value(row, "quantity")),

      "unit": value(row, "unit")?.toString().trim(),

      "image": value(row, "image")?.toString().trim(),

      "featured": toBool(value(row, "featured")),

      "isNew": toBool(value(row, "isNew")),

      "isRecommended": toBool(value(row, "isRecommended")),

      "available": toBool(value(row, "available")),

      "tags": toList(value(row, "tags")),

      "allergens": toList(value(row, "allergens")),
    };

    products.add(product);
  }

  const encoder = JsonEncoder.withIndent('  ');

  final out = File('assets/data/products.json');

  out.createSync(recursive: true);

  out.writeAsStringSync(encoder.convert(products));

  print("");
  print("===============================");
  print("Готово!");
  print("Продукти: ${products.length}");
  print("Файл: assets/data/products.json");
  print("===============================");
}