import 'package:flutter/material.dart';
import '../features/home/home_page.dart';

class AppRouter {
  static const home = '/';
  static final routes = <String, WidgetBuilder>{home: (_) => const HomePage()};
}
