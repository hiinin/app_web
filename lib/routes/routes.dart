import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart'; 

final Map<String, WidgetBuilder> appRoutes = {
  '/home': (context) => const HomePage(),
  '/login': (context) => const AdminLoginPage(),
  // outras rotas aqui...
};
