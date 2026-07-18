import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'router.dart';

class LokumApp extends StatelessWidget {
  const LokumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lokum',
      theme: AppTheme.dark,
      initialRoute: AppRouter.home,
      routes: AppRouter.routes,
    );
  }
}
