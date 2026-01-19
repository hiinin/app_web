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
import '../widgets/auth_guard.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const AdminLoginPage(),
  '/home': (context) => const AuthGuard(child: HomePage()),
  '/criarlocacao': (context) => const AuthGuard(child: CriarLocacaoPage()),
  '/listalocacao': (context) => const AuthGuard(child: ListaLocacaoPage()),
  '/criarsala': (context) => const AuthGuard(child: CriarSalaPage()),
  '/criarcurso': (context) => const AuthGuard(child: CriarCursoPage()),
  '/criarmateria': (context) => const AuthGuard(child: CriarMateriaPage()),
  '/criarprofessor': (context) => AuthGuard(child: CriarProfessorPage()),
  '/criarprofessorlogin': (context) => AuthGuard(child: CriarProfessorLoginPage()),
  '/criarevento': (context) => const AuthGuard(child: CriarEventoPage()),
  '/criarprova': (context) => const AuthGuard(child: CriarProvaPage()),
  '/historicoacoes': (context) => const AuthGuard(child: HistoricoAcoesPage()),
};
