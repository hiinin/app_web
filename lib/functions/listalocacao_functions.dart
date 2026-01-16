import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Função para carregar agendamentos
Future<List<dynamic>> carregarAgendamentos(
  SupabaseClient supabase,
  DateTime diaSelecionado, {
  int? cursoId,
}) async {
  try {
    final diaStr =
        '${diaSelecionado.year.toString().padLeft(4, '0')}-${diaSelecionado.month.toString().padLeft(2, '0')}-${diaSelecionado.day.toString().padLeft(2, '0')}';

    var query = supabase.from('agendamento').select('''
      id,
      dia,
      aula_periodo,
      hora_inicio,
      hora_fim,
      tipo_agendamento,
      nome_evento,
      descricao_evento,
      observacao,
      cursos (id,curso,semestre,periodo),
      salas (id,numero_sala),
      materias (id,nome),
      professores (id,nome_professor)
    ''');

    query = query.eq('dia', diaStr);

    if (cursoId != null) {
      query = query.eq('curso_id', cursoId);
    }

    final response = await query;

    print('DEBUG - Agendamentos carregados: ${response.length}');
    if (response.isNotEmpty) {
      print('DEBUG - Primeiro agendamento: ${response.first}');
    }

    return response;
  } catch (e) {
    print('Erro ao carregar agendamentos: $e');
    rethrow;
  }
}

// Função para buscar por curso
Future<void> buscarPorCurso(
  SupabaseClient supabase,
  int? cursoSelecionadoId,
) async {
  if (cursoSelecionadoId == null) {
    print('Nenhum curso selecionado');
    return;
  }

  final response =
      await supabase
          .from('agendamento')
          .select()
          .eq('curso_id', cursoSelecionadoId)
          .execute();

  if (response.status == 200) {
    // Atualize a lista com os dados obtidos, se necessário
  } else {
    print('Erro na busca: ${response.status}');
  }
}

// Função para converter período em string
String periodoToString(int? periodo) {
  switch (periodo) {
    case 1:
      return 'Matutino';
    case 2:
      return 'Vespertino';
    case 3:
      return 'Noturno';
    default:
      return 'Não informado';
  }
}

// Função para obter nome do mês
String getMonthName(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return months[month - 1];
}

// Função para verificar conflitos
Future<bool> verificarConflitos(
  SupabaseClient supabase,
  int salaId,
  int cursoId,
  int materiaId,
  int professorId,
  DateTime data,
  int agendamentoId,
) async {
  try {
    final dataFormatada =
        '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    // Verificar se já existe um agendamento para esta sala/curso/matéria/professor/data (excluindo o próprio agendamento)
    final conflitos = await supabase
        .from('agendamento')
        .select('id')
        .eq('sala_id', salaId)
        .eq('curso_id', cursoId)
        .eq('materia_id', materiaId)
        .eq('professor_id', professorId)
        .eq('dia', dataFormatada)
        .neq('id', agendamentoId);

    return conflitos.isNotEmpty;
  } catch (e) {
    print('Erro ao verificar conflitos: $e');
    return false;
  }
}

// Função para filtrar agendamentos por múltiplas turmas em uma sala
List<dynamic> filtrarAgendamentosMultiplasTurmas(List<dynamic> agendamentos) {
  // Agrupa por sala e dia
  final Map<String, List<dynamic>> agendamentosPorSala = {};

  for (final ag in agendamentos) {
    final salaId = ag['salas']?['id']?.toString() ?? '';
    final dia = ag['dia']?.toString() ?? '';
    final chave = '$salaId-$dia';

    if (!agendamentosPorSala.containsKey(chave)) {
      agendamentosPorSala[chave] = [];
    }
    agendamentosPorSala[chave]!.add(ag);
  }

  // Retorna apenas salas com múltiplas turmas (cursos diferentes)
  final List<dynamic> agendamentosFiltrados = [];

  for (final entry in agendamentosPorSala.entries) {
    final ags = entry.value;
    final cursosUnicos = ags.map((ag) => ag['cursos']?['id']).toSet();

    // Se há mais de um curso na mesma sala no mesmo dia, inclui todos
    if (cursosUnicos.length > 1) {
      agendamentosFiltrados.addAll(ags);
    }
  }

  return agendamentosFiltrados;
}

// Função para aplicar filtros aos agendamentos
List<dynamic> aplicarFiltros(
  List<dynamic> agendamentos, {
  String? pesquisaTexto,
  String? filtroTipo,
  String? filtroPeriodo,
  bool mostrarMultiplasTurmas = false,
}) {
  List<dynamic> agendamentosFiltrados = List.from(agendamentos);

  // Filtro por múltiplas turmas
  if (mostrarMultiplasTurmas) {
    agendamentosFiltrados = filtrarAgendamentosMultiplasTurmas(
      agendamentosFiltrados,
    );
  }

  // Filtro por texto (sala e curso)
  if (pesquisaTexto != null && pesquisaTexto.isNotEmpty) {
    final textoLower = pesquisaTexto.toLowerCase();
    agendamentosFiltrados =
        agendamentosFiltrados.where((ag) {
          final sala =
              ag['salas']?['numero_sala']?.toString().toLowerCase() ?? '';
          final curso = ag['cursos']?['curso']?.toString().toLowerCase() ?? '';
          return sala.contains(textoLower) || curso.contains(textoLower);
        }).toList();
  }

  // Filtro por tipo
  if (filtroTipo != null && filtroTipo != 'Todos') {
    agendamentosFiltrados =
        agendamentosFiltrados.where((ag) {
          final tipo = ag['tipo_agendamento'];
          switch (filtroTipo) {
            case 'Aulas':
              return tipo == 'A';
            case 'Eventos':
              return tipo == 'E';
            case 'Provas':
              return tipo == 'M';
            default:
              return true;
          }
        }).toList();
  }

  // Filtro por período
  if (filtroPeriodo != null && filtroPeriodo != 'Todos') {
    agendamentosFiltrados =
        agendamentosFiltrados.where((ag) {
          final periodo = ag['cursos']?['periodo'];
          switch (filtroPeriodo) {
            case 'Manhã':
              return periodo == 1;
            case 'Vespertino':
              return periodo == 2;
            case 'Noturno':
              return periodo == 3;
            default:
              return true;
          }
        }).toList();
  }

  return agendamentosFiltrados;
}

// Função para obter cor baseada no tipo de agendamento
Color obterCorPorTipo(String? tipoAgendamento) {
  switch (tipoAgendamento) {
    case 'A': // Aulas
      return const Color(0xFF44A301); // Verde
    case 'E': // Eventos
      return Colors.orange; // Laranja
    case 'M': // Provas
      return Colors.red; // Vermelho
    default:
      return const Color(0xFF44A301); // Verde padrão
  }
}

// Função para gerar cor única baseada no tipo e na sala
Color gerarCorUnicaPorSala(String? tipoAgendamento, String salaId) {
  // Gera uma variação baseada no ID da sala para diferenciar salas diferentes
  // Usa o hash do ID da sala para criar uma variação consistente
  final hash = salaId.hashCode;

  // Ajusta o brilho/saturação baseado no hash para criar tons diferentes
  if (tipoAgendamento == 'A') {
    // Variações de verde
    final variacoes = [
      const Color(0xFF44A301), // Verde original
      const Color(0xFF5CB300), // Verde mais claro
      const Color(0xFF2E7D00), // Verde mais escuro
      const Color(0xFF6BC400), // Verde claro
      const Color(0xFF3A8F00), // Verde médio
    ];
    return variacoes[hash.abs() % variacoes.length];
  } else if (tipoAgendamento == 'E') {
    // Variações de laranja
    final variacoes = [
      Colors.orange,
      Colors.deepOrange,
      Colors.orange.shade700,
      Colors.orange.shade300,
      Colors.deepOrange.shade400,
    ];
    return variacoes[hash.abs() % variacoes.length];
  } else if (tipoAgendamento == 'M') {
    // Variações de vermelho
    final variacoes = [
      Colors.red,
      Colors.red.shade700,
      Colors.red.shade300,
      Colors.redAccent,
      Colors.red.shade900,
    ];
    return variacoes[hash.abs() % variacoes.length];
  }

  // Retorno padrão caso o tipo não seja reconhecido
  return obterCorPorTipo(tipoAgendamento);
}

// Função para mapear salas com múltiplas turmas para cores
Map<String, Color> mapearCoresPorSala(List<dynamic> agendamentos) {
  final Map<String, Color> coresPorSala = {};
  final Map<String, List<dynamic>> agendamentosPorSala = {};
  final Map<String, int> indiceCorPorSala =
      {}; // Mapeia sala para índice de cor

  // Agrupa agendamentos por sala e dia
  for (final ag in agendamentos) {
    final salaId = ag['salas']?['id']?.toString() ?? '';
    final dia = ag['dia']?.toString() ?? '';
    final chave = '$salaId-$dia';

    if (!agendamentosPorSala.containsKey(chave)) {
      agendamentosPorSala[chave] = [];
    }
    agendamentosPorSala[chave]!.add(ag);
  }

  // Identifica salas com múltiplas turmas e atribui cor única baseada no tipo e sala
  int contadorIndice = 0;
  for (final entry in agendamentosPorSala.entries) {
    final ags = entry.value;
    final cursosUnicos = ags.map((ag) => ag['cursos']?['id']).toSet();

    // Se há mais de um curso na mesma sala no mesmo dia, atribui cor única
    if (cursosUnicos.length > 1) {
      final primeiroAg = ags.first;
      final tipoAgendamento = primeiroAg['tipo_agendamento'];
      final salaId = primeiroAg['salas']?['id']?.toString() ?? '';

      // Usa um índice sequencial para garantir cores diferentes para salas diferentes
      if (!indiceCorPorSala.containsKey(salaId)) {
        indiceCorPorSala[salaId] = contadorIndice++;
      }

      // Gera cor única baseada no tipo e no índice da sala
      coresPorSala[entry.key] = gerarCorUnicaPorSalaComIndice(
        tipoAgendamento,
        indiceCorPorSala[salaId]!,
      );
    }
  }

  return coresPorSala;
}

// Função para gerar cor única baseada no tipo e no índice da sala
Color gerarCorUnicaPorSalaComIndice(String? tipoAgendamento, int indiceSala) {
  if (tipoAgendamento == 'A') {
    // Variações de verde - mais variações para diferenciar melhor
    final variacoes = [
      const Color(0xFF44A301), // Verde original
      const Color(0xFF5CB300), // Verde mais claro
      const Color(0xFF2E7D00), // Verde mais escuro
      const Color(0xFF6BC400), // Verde claro
      const Color(0xFF3A8F00), // Verde médio
      const Color(0xFF7ED321), // Verde limão
      const Color(0xFF4CAF50), // Verde material
      const Color(0xFF8BC34A), // Verde claro material
    ];
    return variacoes[indiceSala % variacoes.length];
  } else if (tipoAgendamento == 'E') {
    // Variações de laranja
    final variacoes = [
      Colors.orange,
      Colors.deepOrange,
      Colors.orange.shade700,
      Colors.orange.shade300,
      Colors.deepOrange.shade400,
      Colors.orange.shade600,
      Colors.deepOrange.shade300,
      Colors.orange.shade800,
    ];
    return variacoes[indiceSala % variacoes.length];
  } else if (tipoAgendamento == 'M') {
    // Variações de vermelho
    final variacoes = [
      Colors.red,
      Colors.red.shade700,
      Colors.red.shade300,
      Colors.redAccent,
      Colors.red.shade900,
      Colors.red.shade600,
      Colors.redAccent.shade700,
      Colors.red.shade800,
    ];
    return variacoes[indiceSala % variacoes.length];
  }

  // Retorno padrão caso o tipo não seja reconhecido
  return obterCorPorTipo(tipoAgendamento);
}

// Função para obter a cor de uma sala específica baseada no tipo de agendamento
Color? obterCorSala(Map<String, Color> coresPorSala, dynamic agendamento) {
  final salaId = agendamento['salas']?['id']?.toString() ?? '';
  final dia = agendamento['dia']?.toString() ?? '';
  final chave = '$salaId-$dia';

  // Se a sala está no mapa de cores (tem múltiplas turmas), retorna a cor única da sala
  // A cor já foi gerada considerando o tipo e a sala, então retorna diretamente
  if (coresPorSala.containsKey(chave)) {
    return coresPorSala[chave];
  }

  // Caso contrário, retorna null (sem destaque)
  return null;
}

// Função para agrupar agendamentos por sala quando "turmas juntas" estiver ativo
Map<String, Map<String, dynamic>> agruparAgendamentosPorSala(
  List<dynamic> agendamentos,
) {
  // Agrupa por sala e dia
  final Map<String, List<dynamic>> agendamentosPorSala = {};

  for (final ag in agendamentos) {
    final salaId = ag['salas']?['id']?.toString() ?? '';
    final dia = ag['dia']?.toString() ?? '';
    final chave = '$salaId-$dia';

    if (!agendamentosPorSala.containsKey(chave)) {
      agendamentosPorSala[chave] = [];
    }
    agendamentosPorSala[chave]!.add(ag);
  }

  // Agrupa as turmas dentro de cada sala
  final Map<String, Map<String, dynamic>> salasAgrupadas = {};

  for (final entry in agendamentosPorSala.entries) {
    final ags = entry.value;
    final salaId = ags.first['salas']?['id']?.toString() ?? '';
    final dia = ags.first['dia']?.toString() ?? '';
    final sala = ags.first['salas'];
    final salaNumero = sala?['numero_sala']?.toString() ?? 'N/A';

    // Agrupa por curso dentro da sala
    final Map<int, Map<String, dynamic>> turmasPorCurso = {};

    for (final ag in ags) {
      final cursoId = ag['cursos']?['id'];
      if (cursoId != null) {
        if (!turmasPorCurso.containsKey(cursoId)) {
          turmasPorCurso[cursoId] = {'curso': ag['cursos'], 'agendamentos': []};
        }
        turmasPorCurso[cursoId]!['agendamentos'].add(ag);
      }
    }

    // Só inclui salas com múltiplas turmas (mais de um curso)
    if (turmasPorCurso.length > 1) {
      salasAgrupadas[entry.key] = {
        'sala': sala,
        'salaNumero': salaNumero,
        'salaId': salaId,
        'dia': dia,
        'turmas': turmasPorCurso.values.toList(),
        'agendamentos': ags,
      };
    }
  }

  return salasAgrupadas;
}
