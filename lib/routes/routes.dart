import 'package:flutter/material.dart';
import 'package:app_web/pages/criarcurso_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/criarlocacao_page.dart';
import '../pages/listalocacao_page.dart';
import '../pages/criarsala_page.dart';
import '../pages/criarmateria_page.dart';
import '../pages/criarprofessor_page.dart';
import '../pages/criar_professor_login_page.dart';
import '../pages/criarevento_page.dart';
import '../pages/criarprova_page.dart';
import '../pages/historicoacoes_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/home': (context) => const HomePage(),
  '/login': (context) => const AdminLoginPage(),
  '/criarlocacao': (context) => const CriarLocacaoPage(),
  '/listalocacao': (context) => const ListaLocacaoPage(),
  '/criarsala': (context) => const CriarSalaPage(),
  '/criarcurso': (context) => const CriarCursoPage(),
  '/criarmateria': (context) => const CriarMateriaPage(),
  '/criarprofessor': (context) => CriarProfessorPage(),
  '/criarprofessorlogin': (context) => CriarProfessorLoginPage(),
  '/criarevento': (context) => const CriarEventoPage(),
  '/criarprova': (context) => const CriarProvaPage(),
  '/historicoacoes': (context) => const HistoricoAcoesPage(),
};
