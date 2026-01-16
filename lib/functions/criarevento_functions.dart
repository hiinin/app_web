import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

class CriarEventoFunctions {
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para formatar hora
  String formatHora(TimeOfDay hora) {
    final horaFormatada = hora.hour.toString().padLeft(2, '0');
    final minutoFormatado = hora.minute.toString().padLeft(2, '0');
    return '$horaFormatada:$minutoFormatado';
  }

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

  // Função para obter horários baseados no período da aula e período do curso
  // Retorna um Map com 'hora_inicio' e 'hora_fim' no formato TimeOfDay
  Map<String, TimeOfDay> obterHorariosPorPeriodo(
    String periodoAula,
    int periodoCurso,
  ) {
    // periodoCurso: 1 = Matutino, 2 = Vespertino, 3 = Noturno
    if (periodoAula == 'Primeira Aula') {
      if (periodoCurso == 1) {
        // Matutino: 08h00 às 09h40
        return {
          'hora_inicio': const TimeOfDay(hour: 8, minute: 0),
          'hora_fim': const TimeOfDay(hour: 9, minute: 40),
        };
      } else if (periodoCurso == 3) {
        // Noturno: 19h00 às 20h40
        return {
          'hora_inicio': const TimeOfDay(hour: 19, minute: 0),
          'hora_fim': const TimeOfDay(hour: 20, minute: 40),
        };
      }
    } else if (periodoAula == 'Segunda Aula') {
      if (periodoCurso == 1) {
        // Matutino: 09h55 às 11h35
        return {
          'hora_inicio': const TimeOfDay(hour: 9, minute: 55),
          'hora_fim': const TimeOfDay(hour: 11, minute: 35),
        };
      } else if (periodoCurso == 3) {
        // Noturno: 20h55 às 22h35
        return {
          'hora_inicio': const TimeOfDay(hour: 20, minute: 55),
          'hora_fim': const TimeOfDay(hour: 22, minute: 35),
        };
      }
    }
    // Fallback: horário padrão
    return {
      'hora_inicio': const TimeOfDay(hour: 8, minute: 0),
      'hora_fim': const TimeOfDay(hour: 9, minute: 0),
    };
  }

  // Função para carregar dados iniciais
  Future<Map<String, dynamic>> carregarDados() async {
    try {
      final responseSalas = await supabase.from('salas').select();
      final responseCursos = await supabase.from('cursos').select();
      final responseProfessores = await supabase.from('professores').select();

      List<sala_model.Sala> salas =
          (responseSalas as List)
              .map((e) => sala_model.Sala.fromMap(e))
              .toList();

      List<curso_model.Curso> cursos =
          (responseCursos as List)
              .map((e) => curso_model.Curso.fromMap(e))
              .toList();

      List<Map<String, dynamic>> professores = List<Map<String, dynamic>>.from(
        responseProfessores as List,
      );

      cursos.sort(
        (a, b) => a.curso.toLowerCase().compareTo(b.curso.toLowerCase()),
      );

      return {'salas': salas, 'cursos': cursos, 'professores': professores};
    } catch (e) {
      throw Exception('Erro ao carregar dados: $e');
    }
  }

  // Função para carregar matérias por curso
  Future<List<Map<String, dynamic>>> carregarMateriasPorCurso(
    int cursoId,
  ) async {
    try {
      final response = await supabase
          .from('materias')
          .select()
          .eq('curso_id', cursoId);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erro ao carregar matérias: $e');
    }
  }

  // Função para carregar professores por matéria (através de professor_turmas)
  Future<List<Map<String, dynamic>>> carregarProfessoresPorMateria(
    int materiaId,
  ) async {
    try {
      // Primeiro, busca o curso_id da matéria
      final materiaResponse =
          await supabase
              .from('materias')
              .select('curso_id')
              .eq('id', materiaId)
              .single();

      final cursoId = materiaResponse['curso_id'] as int;

      // Depois, busca os professores associados à turma (curso) através da tabela professor_turmas
      final response = await supabase
          .from('professor_turmas')
          .select('professor_id, professores!inner(id, nome_professor)')
          .eq('curso_id', cursoId);

      return (response as List).map((item) {
        // Extrai os dados do professor do resultado da join
        return item['professores'] as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar professores: $e');
    }
  }

  // Função para verificar agendamentos por curso em um dia específico
  Future<Map<int, int>> verificarAgendamentosCursosPorDia(DateTime dia) async {
    try {
      final dataFormatada =
          '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';

      final agendamentos = await supabase
          .from('agendamento')
          .select('curso_id')
          .eq('dia', dataFormatada);

      Map<int, int> contagemPorCurso = {};
      for (final agendamento in agendamentos) {
        final cursoId = agendamento['curso_id'] as int;
        contagemPorCurso[cursoId] = (contagemPorCurso[cursoId] ?? 0) + 1;
      }

      return contagemPorCurso;
    } catch (e) {
      throw Exception('Erro ao verificar agendamentos por curso: $e');
    }
  }

  // Função para obter lista de cursos ordenada (cursos com 2 agendamentos no final)
  List<curso_model.Curso> getCursosOrdenados(
    List<curso_model.Curso> cursosLista,
    Map<int, int> agendamentosPorCurso,
  ) {
    final cursosOrdenados = List<curso_model.Curso>.from(cursosLista);

    // Ordena: cursos com menos de 2 agendamentos primeiro, depois cursos com 2 agendamentos
    cursosOrdenados.sort((a, b) {
      final agendamentosA = agendamentosPorCurso[a.id] ?? 0;
      final agendamentosB = agendamentosPorCurso[b.id] ?? 0;

      // Se ambos têm 2 agendamentos ou ambos têm menos de 2, mantém ordem alfabética
      if ((agendamentosA >= 2 && agendamentosB >= 2) ||
          (agendamentosA < 2 && agendamentosB < 2)) {
        return a.curso.toLowerCase().compareTo(b.curso.toLowerCase());
      }

      // Cursos com menos de 2 agendamentos vêm primeiro
      if (agendamentosA < 2 && agendamentosB >= 2) {
        return -1;
      }
      if (agendamentosA >= 2 && agendamentosB < 2) {
        return 1;
      }

      return 0;
    });

    return cursosOrdenados;
  }

  // Função para filtrar salas baseada nos critérios selecionados
  Future<List<Map<String, dynamic>>> filtrarSalas({
    required String? periodoAulaSelecionado, // Mantém como String? para compatibilidade
    required curso_model.Curso? cursoSelecionado,
    required DateTime? dia,
  }) async {
    if (periodoAulaSelecionado == null ||
        cursoSelecionado == null ||
        dia == null) {
      return [];
    }

    try {
      final dataFormatada =
          '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';

      // Busca TODAS as salas (incluindo não disponíveis para mostrar com indicador vermelho)
      final todasSalas = await supabase
          .from('salas')
          .select('id, numero_sala, qtd_cadeiras, disponivel');

      final periodoCurso = cursoSelecionado.periodo;

      // Para cada período de aula selecionado, busca agendamentos existentes
      final agendamentosExistentes = await supabase
          .from('agendamento')
          .select('sala_id')
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado)
          .eq('periodo', periodoCurso!);

      // Conta agendamentos por sala para este período
      Map<int, int> contagemPorSala = {};
      for (final agendamento in agendamentosExistentes) {
        final salaId = agendamento['sala_id'];
        contagemPorSala[salaId] = (contagemPorSala[salaId] ?? 0) + 1;
      }

      // ADICIONA TODAS AS SALAS (sem filtrar por quantidade de agendamentos)
      List<Map<String, dynamic>> salasDisponiveis = [];
      for (final sala in todasSalas) {
        final salaId = sala['id'];
        final agendamentosExistentes = contagemPorSala[salaId] ?? 0;

        salasDisponiveis.add({
          'sala_id': salaId,
          'numero_sala': sala['numero_sala'],
          'qtd_cadeiras': sala['qtd_cadeiras'],
          'disponivel': sala['disponivel'],
          'agendamentos_existentes': agendamentosExistentes,
        });
      }

      // Ordena: primeiro por disponibilidade (disponível primeiro), depois por agendamentos, depois por número da sala
      salasDisponiveis.sort((a, b) {
        // Primeiro ordena por disponibilidade (true vem antes de false)
        final aDisponivel = a['disponivel'] == true;
        final bDisponivel = b['disponivel'] == true;
        if (aDisponivel != bDisponivel) {
          final aInt = aDisponivel ? 0 : 1;
          final bInt = bDisponivel ? 0 : 1;
          return aInt.compareTo(bInt);
        }
        // Depois ordena por número de agendamentos (menos primeiro)
        final aAgendamentos = a['agendamentos_existentes'] as int? ?? 0;
        final bAgendamentos = b['agendamentos_existentes'] as int? ?? 0;
        if (aAgendamentos != bAgendamentos) {
          return aAgendamentos.compareTo(bAgendamentos);
        }
        // Por último ordena por número da sala
        final aNumero = a['numero_sala'].toString();
        final bNumero = b['numero_sala'].toString();
        return aNumero.compareTo(bNumero);
      });

      return salasDisponiveis;
    } catch (e) {
      throw Exception('Erro ao filtrar salas: $e');
    }
  }

  // Função para salvar evento (suporta múltiplos cursos e múltiplos períodos)
  Future<void> salvarEvento({
    required String? nomeEvento,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required sala_model.Sala? salaSelecionada,
    required List<curso_model.Curso> cursosSelecionados,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
    required Map<int, Map<String, dynamic>?> professoresPorCurso,
    String? observacao,
    Function(String)? onProgress,
  }) async {
    onProgress?.call('🔍 Verificando dados do agendamento...');

    if (nomeEvento == null || nomeEvento.isEmpty) {
      throw Exception('Por favor, informe o nome do evento');
    }

    if (salaSelecionada == null ||
        cursosSelecionados.isEmpty ||
        periodosAulaSelecionados.isEmpty ||
        dia == null) {
      throw Exception('Por favor, preencha todos os campos obrigatórios');
    }

    // Verifica se todos os cursos têm matéria e professor selecionados
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null ||
          professoresPorCurso[curso.id] == null) {
        throw Exception(
          'Por favor, selecione a matéria e o professor para o curso ${curso.curso}',
        );
      }
    }

    final dataFormatada =
        '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';

    onProgress?.call('📅 Verificando disponibilidade...');

    // Para cada período de aula selecionado e cada curso, verifica limites e conflitos
    for (final periodoAulaSelecionado in periodosAulaSelecionados) {
      for (final curso in cursosSelecionados) {
        final periodoCurso = curso.periodo;

        // 1. Verifica quantos agendamentos já existem para a sala nesse dia e período
        final agendamentosSala = await supabase
            .from('agendamento')
            .select()
            .eq('sala_id', salaSelecionada.id)
            .eq('dia', dataFormatada)
            .eq('periodo', periodoCurso);

        if (agendamentosSala.length >= 6) {
          throw Exception(
            'Essa sala já atingiu o limite de 6 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
          );
        }

        // 2. Verifica quantos agendamentos do tipo Evento já existem para a sala nesse dia, período e aula_periodo específico
        final agendamentosSalaPeriodoTipo = await supabase
            .from('agendamento')
            .select()
            .eq('sala_id', salaSelecionada.id)
            .eq('dia', dataFormatada)
            .eq('aula_periodo', periodoAulaSelecionado)
            .eq('periodo', periodoCurso)
            .eq(
              'tipo_agendamento',
              'E',
            ); // Verifica apenas agendamentos do tipo Evento

        if (agendamentosSalaPeriodoTipo.length >= 2) {
          throw Exception(
            'Essa sala já atingiu o limite de 2 eventos para o período "$periodoAulaSelecionado" no dia ${dataFormatada.split('-').reversed.join('/')}.',
          );
        }

      // 3. Verifica quantos agendamentos já existem para este curso nesse dia
      final agendamentosCurso = await supabase
          .from('agendamento')
          .select('id, tipo_agendamento, aula_periodo')
          .eq('curso_id', curso.id)
          .eq('dia', dataFormatada);

      if (agendamentosCurso.length >= 2) {
        throw Exception(
          'O curso ${curso.curso} já atingiu o limite de 2 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
        );
      }

      // 4. Verifica se há conflito de horário - IMPORTANTE: Não permite conflito do mesmo curso no mesmo horário
      final conflitosHorario = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado);

      if (conflitosHorario.isNotEmpty) {
        // Verifica se já existe um agendamento do mesmo tipo (evento) no mesmo horário
        final tiposExistentes =
            conflitosHorario.map((a) => a['tipo_agendamento']).toSet();

        if (tiposExistentes.contains('E')) {
          throw Exception('Já existe um evento agendado para este horário.');
        }

        // Verifica se há conflito do mesmo curso no mesmo horário (mesmo se for tipo diferente)
        final conflitoMesmoCurso = conflitosHorario.any(
          (a) => a['curso_id'] == curso.id,
        );

        if (conflitoMesmoCurso) {
          throw Exception(
            'O curso ${curso.curso} já possui um agendamento para o horário "$periodoAulaSelecionado" neste dia.',
          );
        }

        // Verifica se já existe qualquer tipo de agendamento no mesmo horário
        String tipoExistente = '';
        switch (conflitosHorario.first['tipo_agendamento']) {
          case 'A':
            tipoExistente = 'aula';
            break;
          case 'E':
            tipoExistente = 'evento';
            break;
          case 'M':
            tipoExistente = 'prova';
            break;
          default:
            tipoExistente = 'agendamento';
        }

        throw Exception(
          'Já existe uma $tipoExistente agendada para o horário "$periodoAulaSelecionado" neste dia.',
        );
      }

      // 5. Verifica se já existe um agendamento igual para este curso, sala, dia, período e aula
      final agendamentoExistente2 =
          await supabase
              .from('agendamento')
              .select()
              .eq('sala_id', salaSelecionada.id)
              .eq('curso_id', curso.id)
              .eq('dia', dataFormatada)
              .eq('aula_periodo', periodoAulaSelecionado)
              .maybeSingle();

      if (agendamentoExistente2 != null) {
        throw Exception(
          'Já existe um agendamento igual para o curso ${curso.curso} no dia ${dataFormatada.split('-').reversed.join('/')}!',
        );
      }
      }
    }

    onProgress?.call('💾 Salvando agendamentos...');

    // Salva agendamentos para todos os períodos e cursos selecionados
    for (final periodoAulaSelecionado in periodosAulaSelecionados) {
      for (final curso in cursosSelecionados) {
        final periodoCurso = curso.periodo;
        final materia = materiasPorCurso[curso.id]!;
        final professor = professoresPorCurso[curso.id]!;

        // Obtém os horários baseados no período da aula e período do curso
        final horarios = obterHorariosPorPeriodo(
          periodoAulaSelecionado,
          periodoCurso!,
        );
        final horaInicio = horarios['hora_inicio']!;
        final horaFim = horarios['hora_fim']!;

        // Salva o agendamento
        try {
          final dadosInserir = {
            'aula_periodo': periodoAulaSelecionado,
            'hora_inicio': formatHora(horaInicio),
            'hora_fim': formatHora(horaFim),
            'sala_id': salaSelecionada.id,
            'curso_id': curso.id,
            'materia_id': materia['id'],
            'professor_id': professor['id'],
            'dia': dataFormatada,
            'periodo': periodoCurso,
            'tipo_agendamento': 'E', // E=Evento
            'nome_evento': nomeEvento,
            'descricao_evento': null,
            if (observacao != null && observacao.isNotEmpty)
              'observacao': observacao,
          };

          await supabase.from('agendamento').insert(dadosInserir);
        } catch (e) {
          throw Exception(
            'Erro ao salvar agendamento para o curso ${curso.curso}, período $periodoAulaSelecionado: $e',
          );
        }
      }
    }

    onProgress?.call('🎉 Agendamento(s) criado(s) com sucesso!');
  }
}