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

Future<List<Map<String, dynamic>>> buscarProfessoresPorMateria(
  SupabaseClient supabase,
  int materiaId,
) async {
  final response = await supabase
      .from('professor_materias')
      .select('professor_id, professores!inner(id, nome_professor)')
      .eq('materia_id', materiaId);
  return (response as List)
      .map((item) => item['professores'] as Map<String, dynamic>)
      .toList();
}
