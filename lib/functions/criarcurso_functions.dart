import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CriarCursoFunctions {
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para converter período para string
  String periodoToString(int? periodo) {
    switch (periodo) {
      case 1:
        return 'Matutino';
      case 2:
        return 'Vespertino';
      case 3:
        return 'Noturno';
      default:
        return 'Período?';
    }
  }

  // Função para converter semestre para string
  String semestreToString(int? semestre) {
    if (semestre == null) return '';
    return '$semestre° semestre';
  }

  // Função para converter string de semestre para int
  int? semestreFromString(String? semestreStr) {
    if (semestreStr == null || semestreStr.isEmpty) return null;
    // Remove "° semestre" e converte para int
    final match = RegExp(r'^(\d+)').firstMatch(semestreStr);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return int.tryParse(semestreStr);
  }

  // Função para buscar cursos
  Future<List<Map<String, dynamic>>> buscarCursos() async {
    try {
      final data = await supabase
          .from('cursos')
          .select('id, curso, semestre, periodo, quantidade_alunos')
          .order('curso');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Erro ao buscar cursos: $e');
    }
  }

  // Função para filtrar cursos
  List<Map<String, dynamic>> filtrarCursos(
    List<Map<String, dynamic>> cursos,
    String query,
  ) {
    if (query.isEmpty) return cursos;

    final queryLower = query.trim().toLowerCase();
    return cursos.where((curso) {
      final nome = (curso['curso'] ?? '').toString().toLowerCase();
      final semestre = (curso['semestre'] ?? '').toString().toLowerCase();
      final periodo = periodoToString(curso['periodo']).toLowerCase();
      final quantidadeAlunos =
          (curso['quantidade_alunos'] ?? '').toString().toLowerCase();
      return nome.contains(queryLower) ||
          semestre.contains(queryLower) ||
          periodo.contains(queryLower) ||
          quantidadeAlunos.contains(queryLower);
    }).toList();
  }

  // Função para salvar curso
  Future<void> salvarCurso({
    required String nomeCurso,
    required int? semestre,
    required int? periodo,
    required int? quantidadeAlunos,
  }) async {
    // Verifica duplicidade
    final existing =
        await supabase
            .from('cursos')
            .select()
            .eq('curso', nomeCurso.trim())
            .eq('semestre', semestreToString(semestre))
            .eq('periodo', periodo)
            .maybeSingle();

    if (existing != null) {
      throw Exception('Já existe uma turma com esses dados!');
    }

    await supabase.from('cursos').insert({
      'curso': nomeCurso.trim(),
      'semestre': semestreToString(semestre),
      'periodo': periodo,
      'quantidade_alunos': quantidadeAlunos,
    });
  }

  // Função para atualizar curso
  Future<void> atualizarCurso({
    required int id,
    required String nomeCurso,
    required int? semestre,
    required int? periodo,
    required int? quantidadeAlunos,
  }) async {
    await supabase
        .from('cursos')
        .update({
          'curso': nomeCurso.trim(),
          'semestre': semestreToString(semestre),
          'periodo': periodo,
          'quantidade_alunos': quantidadeAlunos,
        })
        .eq('id', id);
  }

  // Função para excluir curso
  Future<void> excluirCurso(int id) async {
    await supabase.from('cursos').delete().eq('id', id);
  }

  // Função para retornar cor de fundo baseada no período
  Color getPeriodoColor(int? periodo) {
    switch (periodo) {
      case 1: // Matutino
        return const Color(0xFFDCFDF7); // Verde claro
      case 2: // Vespertino
        return const Color(0xFFFEF3C7); // Amarelo claro
      case 3: // Noturno
        return const Color(0xFFE0E7FF); // Azul claro
      default:
        return const Color(0xFFF3F4F6); // Cinza claro
    }
  }

  // Função para retornar cor do texto baseada no período
  Color getPeriodoTextColor(int? periodo) {
    switch (periodo) {
      case 1: // Matutino
        return const Color(0xFF047857); // Verde escuro
      case 2: // Vespertino
        return const Color(0xFFD97706); // Amarelo escuro
      case 3: // Noturno
        return const Color(0xFF1E3A8A); // Azul escuro
      default:
        return const Color(0xFF6B7280); // Cinza escuro
    }
  }
}
