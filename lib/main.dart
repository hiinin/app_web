import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/routes.dart';
import 'package:flutter/services.dart';

// FORÇA NOVO DEPLOY - ATUALIZA BANCO DE DADOS
void main() async {
  // Garante que o Flutter seja inicializado na zona correta
  WidgetsFlutterBinding.ensureInitialized();

  // Configura o sistema de serviços
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Configuração específica para evitar problemas com multi-view
  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  // Inicializa o Supabase de forma assíncrona mas controlada
  await _initializeApp();
}

Future<void> _initializeApp() async {
  try {
    await Supabase.initialize(
      url: 'https://kjtfpumdexotigyxauyb.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdGZwdW1kZXhvdGlneXhhdXliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4OTMzOTcsImV4cCI6MjA2OTQ2OTM5N30.qTJaYkGyXdJEbyOglc3WkH50P6BmhiBtOFFa83mdvSY',
    );
    print('Supabase inicializado com sucesso');
  } catch (e) {
    print('Erro ao inicializar Supabase: $e');
    // Continua mesmo com erro para não quebrar o app
  }

  // Executa o app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SupabaseClient? supabase;

  @override
  void initState() {
    super.initState();
    // Tenta obter o cliente Supabase de forma segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        supabase = Supabase.instance.client;
        print('Cliente Supabase obtido com sucesso');
      } catch (e) {
        print('Erro ao obter cliente Supabase: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unicv Ensalamento RH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // 👈 Início na tela de login
      routes: appRoutes, // 👈 Usa as rotas definidas em routes.dart
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      // Configuração para compatibilidade com multi-view
      home: null, // Força o uso de routes ao invés de home
    );
  }
}
