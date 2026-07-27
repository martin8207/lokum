import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_theme.dart';
import 'core/asset_paths.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BundledAssets.ensureLoaded();
  await AppThemeMode.ensureLoaded();

  runApp(const LokumApp());
}
