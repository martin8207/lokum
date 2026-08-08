import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_theme.dart';
import 'core/app_config.dart';
import 'core/asset_paths.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BundledAssets.ensureLoaded();
  await AppThemeMode.ensureLoaded();
  await AppConfig.ensureLoaded();

  runApp(const LokumApp());
}
