import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://neiedqopzdnievgmfbmt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5laWVkcW9wemRuaWV2Z21mYm10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM3ODYxMjcsImV4cCI6MjA1OTM2MjEyN30.wD9Qa5qwmstJVofDIT2hpMoxvrIDzH_uyN-IGigehC0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // 👈 Início na tela de login
      routes: appRoutes,       // 👈 Usa as rotas definidas em routes.dart
    );
  }
}
