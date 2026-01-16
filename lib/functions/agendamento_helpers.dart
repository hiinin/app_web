import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<Map<String, dynamic>>> buscarMateriasPorCurso(
  SupabaseClient supabase,
  int cursoId,
) async {
  final response = await supabase
      .from('materias')
      .select('*')
      .eq('curso_id', cursoId)
      .order('nome');
  return List<Map<String, dynamic>>.from(response);
}

Future<List<Map<String, dynamic>>> buscarProfessoresPorTurma(
  SupabaseClient supabase,
  int cursoId,
) async {
  final response = await supabase
      .from('professor_turmas')
      .select('professor_id, professores!inner(id, nome_professor)')
      .eq('curso_id', cursoId);
  return (response as List)
      .map((item) => item['professores'] as Map<String, dynamic>)
      .toList();
}

Future<List<Map<String, dynamic>>> buscarProfessoresPorMateria(
  SupabaseClient supabase,
  int materiaId,
) async {
  // Primeiro, busca o curso_id da matéria
  final materiaResponse = await supabase
      .from('materias')
      .select('curso_id')
      .eq('id', materiaId)
      .single();
  
  final cursoId = materiaResponse['curso_id'] as int;
  
  // Depois, busca os professores associados à turma (curso)
  return await buscarProfessoresPorTurma(supabase, cursoId);
}
