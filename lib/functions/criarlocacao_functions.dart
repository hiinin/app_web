import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

class CriarLocacaoFunctions {
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

  // Função para carregar dados iniciais
  Future<Map<String, dynamic>> carregarDados() async {
    try {
      final responseSalas = await supabase
          .from('salas')
          .select()
          .eq('disponivel', true);
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

  // Função para carregar professores por turma (curso)
  Future<List<Map<String, dynamic>>> carregarProfessoresPorTurma(
    int cursoId,
  ) async {
    try {
      final response = await supabase
          .from('professor_turmas')
          .select('professor_id, professores!inner(id, nome_professor)')
          .eq('curso_id', cursoId);

      return (response as List).map((item) {
        return item['professores'] as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar professores: $e');
    }
  }

  // Função para verificar agendamentos por curso em um dia específico
  // Considera os períodos de aula selecionados para verificar agendamentos
  // Retorna: { cursoId: { 'periodo_selecionado': count, 'total_dia': count, 'periodos_com_agendamento': ['Primeira Aula', ...] } }
  Future<Map<int, Map<String, dynamic>>> verificarAgendamentosCursosPorDia(
    DateTime dia,
    Set<String> periodosAulaSelecionados,
  ) async {
    try {
      final dataFormatada =
          '${dia.year.toString().padLeft(4, '0')}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';

      // Retorna um Map com informações detalhadas:
      // { cursoId: { 'periodo_selecionado': count, 'total_dia': count, 'periodos_com_agendamento': List<String> } }
      Map<int, Map<String, dynamic>> contagemPorCurso = {};

      if (periodosAulaSelecionados.isEmpty) {
        // Se nenhum período está selecionado, retorna contagem total do dia
        final agendamentos = await supabase
            .from('agendamento')
            .select('curso_id')
            .eq('dia', dataFormatada);

        for (final agendamento in agendamentos) {
          final cursoId = agendamento['curso_id'] as int;
          if (!contagemPorCurso.containsKey(cursoId)) {
            contagemPorCurso[cursoId] = {
              'periodo_selecionado': 0,
              'total_dia': 0,
              'periodos_com_agendamento': <String>[],
            };
          }
          contagemPorCurso[cursoId]!['total_dia'] =
              (contagemPorCurso[cursoId]!['total_dia'] as int? ?? 0) + 1;
        }
        return contagemPorCurso;
      }

      // Busca agendamentos nos períodos selecionados
      final agendamentosPeriodoSelecionado = await supabase
          .from('agendamento')
          .select('curso_id, aula_periodo')
          .eq('dia', dataFormatada)
          .in_('aula_periodo', periodosAulaSelecionados.toList());

      // Busca todos os agendamentos do dia para contar total e verificar quais períodos têm agendamento
      final agendamentosDia = await supabase
          .from('agendamento')
          .select('curso_id, aula_periodo')
          .eq('dia', dataFormatada);

      // Map para armazenar quais períodos têm agendamento por curso
      Map<int, Set<String>> periodosComAgendamentoPorCurso = {};

      // Conta agendamentos no período selecionado
      for (final agendamento in agendamentosPeriodoSelecionado) {
        final cursoId = agendamento['curso_id'] as int;
        final aulaPeriodo = agendamento['aula_periodo'] as String? ?? '';

        if (!contagemPorCurso.containsKey(cursoId)) {
          contagemPorCurso[cursoId] = {
            'periodo_selecionado': 0,
            'total_dia': 0,
            'periodos_com_agendamento': <String>[],
          };
          periodosComAgendamentoPorCurso[cursoId] = <String>{};
        }
        contagemPorCurso[cursoId]!['periodo_selecionado'] =
            (contagemPorCurso[cursoId]!['periodo_selecionado'] as int? ?? 0) +
            1;

        // Adiciona o período à lista de períodos com agendamento
        if (!periodosComAgendamentoPorCurso[cursoId]!.contains(aulaPeriodo)) {
          periodosComAgendamentoPorCurso[cursoId]!.add(aulaPeriodo);
        }
      }

      // Conta total do dia e coleta todos os períodos com agendamento
      for (final agendamento in agendamentosDia) {
        final cursoId = agendamento['curso_id'] as int;
        final aulaPeriodo = agendamento['aula_periodo'] as String? ?? '';

        if (!contagemPorCurso.containsKey(cursoId)) {
          contagemPorCurso[cursoId] = {
            'periodo_selecionado': 0,
            'total_dia': 0,
            'periodos_com_agendamento': <String>[],
          };
          periodosComAgendamentoPorCurso[cursoId] = <String>{};
        }
        contagemPorCurso[cursoId]!['total_dia'] =
            (contagemPorCurso[cursoId]!['total_dia'] as int? ?? 0) + 1;

        // Adiciona o período à lista de períodos com agendamento (para todos os períodos do dia)
        if (!periodosComAgendamentoPorCurso[cursoId]!.contains(aulaPeriodo)) {
          periodosComAgendamentoPorCurso[cursoId]!.add(aulaPeriodo);
        }
      }

      // Atualiza a lista de períodos com agendamento no resultado
      for (final cursoId in contagemPorCurso.keys) {
        contagemPorCurso[cursoId]!['periodos_com_agendamento'] =
            periodosComAgendamentoPorCurso[cursoId]?.toList() ?? <String>[];
      }

      return contagemPorCurso;
    } catch (e) {
      throw Exception('Erro ao verificar agendamentos por curso: $e');
    }
  }

  // Função para filtrar salas
  Future<List<Map<String, dynamic>>> filtrarSalas({
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
  }) async {
    if (periodosAulaSelecionados.isEmpty ||
        cursosSelecionados.isEmpty ||
        (modoMultiplo ? diasMultiplosSelecionados.isEmpty : dia == null)) {
      return [];
    }

    try {
      List<DateTime> diasParaVerificar = [];
      if (modoMultiplo) {
        diasParaVerificar = diasMultiplosSelecionados.toList();
      } else {
        diasParaVerificar = [dia!];
      }

      // Busca TODAS as salas (incluindo não disponíveis para mostrar com indicador vermelho)
      final todasSalas = await supabase
          .from('salas')
          .select('id, numero_sala, qtd_cadeiras, disponivel');

      Map<int, Map<String, dynamic>> salasDisponiveis = {};

      // Para cada dia selecionado
      for (DateTime diaVerificar in diasParaVerificar) {
        final dataFormatada =
            '${diaVerificar.year.toString().padLeft(4, '0')}-${diaVerificar.month.toString().padLeft(2, '0')}-${diaVerificar.day.toString().padLeft(2, '0')}';

        final periodoCursoReferencia = cursosSelecionados.first.periodo;

        // Para cada período de aula selecionado, busca agendamentos existentes
        // (apenas para indicador visual)
        Map<int, int> contagemPorSala = {};

        for (String periodoAula in periodosAulaSelecionados) {
          final agendamentosExistentes = await supabase
              .from('agendamento')
              .select('sala_id')
              .eq('dia', dataFormatada)
              .eq('aula_periodo', periodoAula)
              .eq('periodo', periodoCursoReferencia!);

          // Conta agendamentos por sala para este período (apenas para indicador visual)
          for (final agendamento in agendamentosExistentes) {
            final salaId = agendamento['sala_id'];
            contagemPorSala[salaId] = (contagemPorSala[salaId] ?? 0) + 1;
          }
        }

        // ADICIONA TODAS AS SALAS (sem filtrar por quantidade de agendamentos)
        for (final sala in todasSalas) {
          final salaId = sala['id'];
          final agendamentosExistentes = contagemPorSala[salaId] ?? 0;

          // Sempre inclui a sala, apenas marca quantos agendamentos existem
          if (!salasDisponiveis.containsKey(salaId)) {
            salasDisponiveis[salaId] = {
              'sala_id': salaId,
              'numero_sala': sala['numero_sala'],
              'qtd_cadeiras': sala['qtd_cadeiras'],
              'disponivel': sala['disponivel'],
              'agendamentos_existentes': agendamentosExistentes,
            };
          } else {
            // Se a sala já existe, pega a maior contagem de agendamentos entre os períodos
            if (agendamentosExistentes >
                salasDisponiveis[salaId]!['agendamentos_existentes']) {
              salasDisponiveis[salaId]!['agendamentos_existentes'] =
                  agendamentosExistentes;
            }
          }
        }
      }

      List<Map<String, dynamic>> salasFiltradas =
          salasDisponiveis.values.toList();

      // Ordena: primeiro por disponibilidade (disponível primeiro), depois por agendamentos, depois por número da sala
      salasFiltradas.sort((a, b) {
        // Primeiro ordena por disponibilidade (true vem antes de false)
        // Converte de forma segura para bool
        final aDisponivel = a['disponivel'] == true;
        final bDisponivel = b['disponivel'] == true;
        if (aDisponivel != bDisponivel) {
          // Converte para int: true = 0 (vem primeiro), false = 1 (vem depois)
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

      return salasFiltradas;
    } catch (e) {
      throw Exception('Erro ao filtrar salas: $e');
    }
  }

  // Função para verificar se todos os campos estão preenchidos
  bool todosCamposPreenchidos({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required sala_model.Sala? salaSelecionada,
  }) {
    bool temDia =
        modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;
    bool temPeriodo = periodosAulaSelecionados.isNotEmpty;
    bool temCurso = cursosSelecionados.isNotEmpty;
    bool temSala = salaSelecionada != null;

    return temDia && temPeriodo && temCurso && temSala;
  }

  // Função para gerar mensagem de validação em ordem
  String getMensagemValidacao({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required sala_model.Sala? salaSelecionada,
  }) {
    List<String> camposFaltando = [];

    // Verifica dia
    bool temDia =
        modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;
    if (!temDia) {
      camposFaltando.add('um dia');
    }

    // Verifica período da aula
    if (periodosAulaSelecionados.isEmpty) {
      camposFaltando.add('pelo menos um período de aula');
    }

    // Verifica curso
    if (cursosSelecionados.isEmpty) {
      camposFaltando.add('pelo menos um curso');
    }

    // Verifica sala
    if (salaSelecionada == null) {
      camposFaltando.add('uma sala');
    }

    if (camposFaltando.isEmpty) {
      return 'Todos os campos estão preenchidos!';
    }

    String mensagem = 'Selecione ';
    if (camposFaltando.length == 1) {
      mensagem += camposFaltando.first;
    } else if (camposFaltando.length == 2) {
      mensagem += '${camposFaltando.first} e ${camposFaltando.last}';
    } else {
      mensagem += camposFaltando.take(camposFaltando.length - 1).join(', ');
      mensagem += ' e ${camposFaltando.last}';
    }

    return mensagem;
  }

  // Função para salvar locação
  Future<void> salvarLocacao({
    required bool isLoading,
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required sala_model.Sala? salaSelecionada,
    required List<curso_model.Curso> cursosSelecionados,
    required String? periodoAulaSelecionado,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
    required Map<int, Map<String, dynamic>?> professoresPorCurso,
    Function(String)? onProgress,
  }) async {
    if (isLoading) return; // Evita duplo clique

    print(
      'Chamou salvarLocacao para: '
      'cursos=${cursosSelecionados.length}, '
      'sala=${salaSelecionada?.id}, '
      'aula=$periodoAulaSelecionado',
    );

    onProgress?.call('🔍 Verificando dados do agendamento...');

    final bool temDiasSelecionados =
        modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;

    // Verificar se há cursos selecionados
    if (!temDiasSelecionados ||
        salaSelecionada == null ||
        cursosSelecionados.isEmpty ||
        periodoAulaSelecionado == null) {
      throw Exception('Por favor, preencha todos os campos obrigatórios');
    }

    // Verificar se cada curso tem matéria e professor selecionados
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null ||
          professoresPorCurso[curso.id] == null) {
        throw Exception(
          'Por favor, selecione matéria e professor para o curso "${curso.curso}"',
        );
      }
    }

    // Para múltiplos cursos, vamos usar o período do primeiro curso como referência
    final periodoCurso =
        cursosSelecionados.first.periodo; // 1=Matutino, 2=Vespertino, 3=Noturno

    // Lista de dias para processar
    List<DateTime> diasParaProcessar = [];
    if (modoMultiplo) {
      diasParaProcessar = diasMultiplosSelecionados.toList();
    } else {
      diasParaProcessar = [dia!];
    }

    // Verifica todos os dias antes de salvar
    int diaAtual = 0;
    for (DateTime diaProcessar in diasParaProcessar) {
      diaAtual++;
      onProgress?.call(
        '📅 Verificando disponibilidade do dia $diaAtual de ${diasParaProcessar.length}...',
      );

      final dataFormatada =
          '${diaProcessar.year.toString().padLeft(4, '0')}-${diaProcessar.month.toString().padLeft(2, '0')}-${diaProcessar.day.toString().padLeft(2, '0')}';

      // 1. Verifica quantos agendamentos já existem para a sala nesse dia e período (NOVA REGRA: 4 agendamentos por período)
      // IMPORTANTE: 2 cursos em 1 sala = conta como 1 utilização da sala
      final agendamentosSalaPeriodo = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('periodo', periodoCurso);

      // Conta quantas vezes a sala foi utilizada (não quantos agendamentos)
      // 2 cursos em 1 sala = 1 utilização
      Map<String, int> utilizacoesSala = {};
      for (final agendamento in agendamentosSalaPeriodo) {
        final chave =
            '${agendamento['aula_periodo']}_${agendamento['periodo']}';
        utilizacoesSala[chave] = (utilizacoesSala[chave] ?? 0) + 1;
      }

      // Verifica se já atingiu o limite de 4 utilizações por período
      int totalUtilizacoes = utilizacoesSala.values.fold(
        0,
        (sum, count) => sum + count,
      );
      if (totalUtilizacoes >= 4) {
        String periodoNome = '';
        switch (periodoCurso) {
          case 1:
            periodoNome = 'Matutino';
            break;
          case 2:
            periodoNome = 'Vespertino';
            break;
          case 3:
            periodoNome = 'Noturno';
            break;
          default:
            periodoNome = 'Desconhecido';
        }

        throw Exception(
          'Essa sala já atingiu o limite de 4 utilizações para o período $periodoNome no dia ${dataFormatada.split('-').reversed.join('/')}.',
        );
      }

      // 2. Verifica quantos agendamentos do mesmo tipo já existem para a sala nesse dia, período e aula_periodo específico
      // IMPORTANTE: Filtrar por período específico para permitir aulas em 3 períodos diferentes
      final agendamentosSalaPeriodoTipo = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado!)
          .eq(
            'periodo',
            periodoCurso,
          ) // IMPORTANTE: Filtrar por período específico
          .eq(
            'tipo_agendamento',
            'A',
          ); // Verifica apenas agendamentos do tipo Aula

      // Verifica se há espaço suficiente para todos os cursos selecionados
      final espacoDisponivel = 2 - agendamentosSalaPeriodoTipo.length;
      if (espacoDisponivel < cursosSelecionados.length) {
        throw Exception(
          'Essa sala só tem espaço para $espacoDisponivel aula(s) no período "${periodoAulaSelecionado}" no dia ${dataFormatada.split('-').reversed.join('/')}. Você selecionou ${cursosSelecionados.length} curso(s).',
        );
      }

      // 3. Verifica quantos agendamentos já existem para cada curso nesse dia (máximo 2 vezes por dia)
      for (final curso in cursosSelecionados) {
        final agendamentosCurso = await supabase
            .from('agendamento')
            .select()
            .eq('curso_id', curso.id)
            .eq('dia', dataFormatada);

        if (agendamentosCurso.length >= 2) {
          throw Exception(
            'O curso "${curso.curso}" já atingiu o limite de 2 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
          );
        }
      }

      // 4. Verifica se já existe um agendamento igual para cada curso, sala, dia, período e aula
      for (final curso in cursosSelecionados) {
        final agendamentoExistente =
            await supabase
                .from('agendamento')
                .select()
                .eq('sala_id', salaSelecionada!.id)
                .eq('curso_id', curso.id)
                .eq('dia', dataFormatada)
                .eq('aula_periodo', periodoAulaSelecionado!)
                .eq(
                  'periodo',
                  periodoCurso,
                ) // IMPORTANTE: Filtrar por período específico
                .maybeSingle();

        if (agendamentoExistente != null) {
          throw Exception(
            'Já existe um agendamento igual para o curso "${curso.curso}" no período ${periodoCurso == 1
                ? 'Matutino'
                : periodoCurso == 2
                ? 'Vespertino'
                : 'Noturno'} no dia ${dataFormatada.split('-').reversed.join('/')}!',
          );
        }
      }

      // 5. Verifica se há conflito de horário com outros tipos de agendamento (aula, prova, evento)
      // IMPORTANTE: Para aulas, permitir que 1 aula aconteça em 3 períodos diferentes
      // Só verificar conflitos no MESMO período, não em períodos diferentes
      final conflitosHorario = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado!)
          .eq(
            'periodo',
            periodoCurso,
          ); // IMPORTANTE: Filtrar por período específico

      if (conflitosHorario.isNotEmpty) {
        // Verifica se já existe um agendamento do mesmo tipo (aula) no mesmo horário
        final tiposExistentes =
            conflitosHorario.map((a) => a['tipo_agendamento']).toSet();

        // NOVA REGRA: Para aulas, permitir 1 aula OU 1 aula com 2 cursos no mesmo horário
        if (tiposExistentes.contains('A')) {
          final aulasMesmoHorario =
              conflitosHorario
                  .where((a) => a['tipo_agendamento'] == 'A')
                  .toList();

          // Verifica se já existem 2 cursos no mesmo horário
          if (aulasMesmoHorario.length >= 2) {
            throw Exception(
              'Já existem 2 cursos agendados para este horário. Máximo permitido: 2 cursos por horário.',
            );
          }

          // Verificar se algum dos cursos já está agendado neste horário
          for (final curso in cursosSelecionados) {
            final cursoJaAgendado = aulasMesmoHorario.any(
              (a) => a['curso_id'] == curso.id,
            );

            if (cursoJaAgendado) {
              throw Exception(
                'O curso "${curso.curso}" já está agendado para este horário.',
              );
            }
          }

          // Verifica se há espaço suficiente para todos os cursos selecionados
          final espacoDisponivelHorario = 2 - aulasMesmoHorario.length;
          if (espacoDisponivelHorario < cursosSelecionados.length) {
            throw Exception(
              'Já existem ${aulasMesmoHorario.length} curso(s) agendados para este horário. Só há espaço para $espacoDisponivelHorario curso(s) adicional(is).',
            );
          }
        }

        // NOVA LÓGICA: Para aulas, permitir que 1 aula aconteça em 3 períodos diferentes
        // Só bloquear se for prova ou evento no mesmo horário
        if (tiposExistentes.contains('M') || tiposExistentes.contains('E')) {
          String tipoExistente = '';
          if (tiposExistentes.contains('M')) {
            tipoExistente = 'prova';
          } else {
            tipoExistente = 'evento';
          }

          throw Exception(
            'Já existe uma $tipoExistente agendada para o horário "$periodoAulaSelecionado" neste dia.',
          );
        }

        // Se chegou até aqui e há conflitos, mas são apenas aulas, permitir
        // (pois queremos permitir 1 aula em 3 períodos diferentes)
      }
    }

    try {
      List<int> idsAgendamentosCriados = [];
      final timestampCriacao = DateTime.now();

      print('DEBUG - ==========================================');
      print('DEBUG - INICIANDO PROCESSO DE SALVAMENTO');
      print('DEBUG - ==========================================');
      print(
        'DEBUG - Iniciando salvamento de ${cursosSelecionados.length} cursos',
      );
      print(
        'DEBUG - Cursos selecionados: ${cursosSelecionados.map((c) => '${c.curso} (ID: ${c.id})').join(', ')}',
      );
      print('DEBUG - Sala selecionada: ${salaSelecionada?.id}');
      print('DEBUG - Período aula: $periodoAulaSelecionado');
      print('DEBUG - Modo múltiplo: $modoMultiplo');
      print('DEBUG - Dias para processar: ${diasParaProcessar.length}');

      onProgress?.call('💾 Iniciando salvamento dos agendamentos...');

      // Salva agendamentos para todos os cursos e dias selecionados
      int diaSalvando = 0;
      for (DateTime diaProcessar in diasParaProcessar) {
        diaSalvando++;
        onProgress?.call(
          '📝 Salvando agendamentos do dia $diaSalvando de ${diasParaProcessar.length}...',
        );

        final dataFormatada =
            '${diaProcessar.year.toString().padLeft(4, '0')}-${diaProcessar.month.toString().padLeft(2, '0')}-${diaProcessar.day.toString().padLeft(2, '0')}';

        // Para cada curso selecionado
        for (final curso in cursosSelecionados) {
          final periodoCurso = curso.periodo;
          final professor = professoresPorCurso[curso.id];

          print('DEBUG - ==========================================');
          print('DEBUG - TENTANDO INSERIR AGENDAMENTO');
          print('DEBUG - ==========================================');
          print('DEBUG - Curso: ${curso.curso} (ID: ${curso.id})');
          print('DEBUG - Sala ID: ${salaSelecionada!.id}');
          print('DEBUG - Professor ID: ${professor!['id']}');
          print('DEBUG - Data formatada: $dataFormatada');
          print('DEBUG - Período curso: $periodoCurso');
          print('DEBUG - Período aula: $periodoAulaSelecionado');

          // Preparar dados para inserção
          final dadosInserir = {
            'aula_periodo': periodoAulaSelecionado!,
            'sala_id': salaSelecionada!.id,
            'curso_id': curso.id,
            'professor_id': professor!['id'],
            'dia': dataFormatada,
            'periodo': periodoCurso,
            'tipo_agendamento': 'A', // A=Aula
          };

          print('DEBUG - Dados para inserção: $dadosInserir');

          try {
            print('DEBUG - Executando INSERT no Supabase...');
            final response =
                await supabase
                    .from('agendamento')
                    .insert(dadosInserir)
                    .select();

            print('DEBUG - Resposta da inserção: $response');

            // Captura o ID do agendamento criado
            if (response != null && response.isNotEmpty) {
              idsAgendamentosCriados.add(response[0]['id']);
              print(
                'DEBUG - ✅ Agendamento criado com sucesso para curso ${curso.curso}, ID: ${response[0]['id']}',
              );
            } else {
              print(
                'DEBUG - ❌ ERRO: Falha ao criar agendamento para curso ${curso.curso} - resposta vazia',
              );
            }
          } catch (e) {
            print(
              'DEBUG - ❌ ERRO ao inserir agendamento para curso ${curso.curso}: $e',
            );
            throw Exception(
              'Erro ao criar agendamento para curso ${curso.curso}: $e',
            );
          }
        }
      }

      print(
        'DEBUG - Total de agendamentos criados: ${idsAgendamentosCriados.length}',
      );

      // Se foram criados múltiplos agendamentos, aguarda um pouco e então
      // remove os registros individuais do histórico e cria um registro múltiplo
      if (idsAgendamentosCriados.length > 1) {
        onProgress?.call('✨ Finalizando e organizando dados do agendamento...');

        // Aguarda um pouco para os triggers criarem os registros
        await Future.delayed(const Duration(milliseconds: 1000));

        // Remove os registros individuais do histórico criados pelos triggers
        await supabase
            .from('historico_acoes')
            .delete()
            .eq('tabela_afetada', 'agendamento')
            .eq('acao', 'INSERT')
            .in_('registro_id', idsAgendamentosCriados)
            .gte(
              'data_hora',
              timestampCriacao
                  .subtract(const Duration(seconds: 10))
                  .toIso8601String(),
            )
            .lte(
              'data_hora',
              timestampCriacao
                  .add(const Duration(seconds: 10))
                  .toIso8601String(),
            );

        // Formata as datas para exibição
        final datasFormatadas =
            diasParaProcessar.map((data) {
              return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
            }).toList();

        final detalhes =
            'Agendamento múltiplo criado para ${diasParaProcessar.length} dias: ${datasFormatadas.join(', ')}';

        // Cria um registro especial no histórico que agrupa todos os agendamentos
        await supabase.from('historico_acoes').insert({
          'tabela_afetada': 'agendamento',
          'acao': 'INSERT_MULTIPLE',
          'registro_id':
              idsAgendamentosCriados.first, // Usa o primeiro ID como referência
          'dados_anteriores': null,
          'dados_novos': {
            'ids_agendamentos': idsAgendamentosCriados,
            'quantidade_dias': diasParaProcessar.length,
            'datas': datasFormatadas,
            'sala_id': salaSelecionada!.id,
            'cursos_ids': cursosSelecionados.map((c) => c.id).toList(),
            'cursos_nomes': cursosSelecionados.map((c) => c.curso).toList(),
            'materias_professores':
                cursosSelecionados
                    .map(
                      (c) => {
                        'curso_id': c.id,
                        'curso_nome': c.curso,
                        'materia_id': materiasPorCurso[c.id]!['id'],
                        'materia_nome': materiasPorCurso[c.id]!['nome'],
                        'professor_id': professoresPorCurso[c.id]!['id'],
                        'professor_nome':
                            professoresPorCurso[c.id]!['nome_professor'],
                      },
                    )
                    .toList(),
            'periodo': periodoCurso,
            'aula_periodo': periodoAulaSelecionado,
            'tipo_agendamento': 'A',
          },
          'detalhes': detalhes,
          'data_hora': timestampCriacao.toIso8601String(),
        });
      }

      // Mensagem final de conclusão
      onProgress?.call('🎉 Agendamento criado com sucesso!');

      // Aguarda um pouco para garantir que a mensagem final seja exibida
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw Exception('Erro ao salvar agendamento: $e');
    }
  }

  // Função de teste simplificada para inserção de agendamento
  Future<void> salvarLocacaoTeste({
    required List<curso_model.Curso> cursosSelecionados,
    required sala_model.Sala? salaSelecionada,
    required Set<String> periodosAulaSelecionados,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
    required Map<int, Map<String, dynamic>?> professoresPorCurso,
    required DateTime? dia,
    required Set<DateTime> diasMultiplosSelecionados,
    required bool modoMultiplo,
    String? observacao,
    Function(String)? onProgress,
  }) async {
    print('DEBUG - ==========================================');
    print('DEBUG - INICIANDO TESTE DE INSERÇÃO SIMPLIFICADA');
    print('DEBUG - ==========================================');

    try {
      // Validação: verifica se a sala está disponível
      if (salaSelecionada == null) {
        throw Exception('Por favor, selecione uma sala');
      }

      // Verifica se a sala está disponível no banco de dados
      final salaAtualizada =
          await supabase
              .from('salas')
              .select('disponivel')
              .eq('id', salaSelecionada.id)
              .maybeSingle();

      if (salaAtualizada == null) {
        throw Exception('Sala não encontrada');
      }

      final salaDisponivel = salaAtualizada['disponivel'] == true;
      if (!salaDisponivel) {
        throw Exception(
          'Não é possível agendar na sala ${salaSelecionada.numeroSala} pois ela está marcada como indisponível.',
        );
      }

      List<int> idsAgendamentosCriados = [];
      final timestampCriacao = DateTime.now();

      // Lista de dias para processar
      List<DateTime> diasParaProcessar = [];
      if (modoMultiplo) {
        diasParaProcessar = diasMultiplosSelecionados.toList();
      } else {
        diasParaProcessar = [dia!];
      }

      print('DEBUG - Dias para processar: ${diasParaProcessar.length}');
      print('DEBUG - Cursos selecionados: ${cursosSelecionados.length}');
      print(
        'DEBUG - Períodos de aula selecionados: ${periodosAulaSelecionados.length}',
      );

      // Salva agendamentos para todos os cursos, dias e períodos selecionados
      for (DateTime diaProcessar in diasParaProcessar) {
        final dataFormatada =
            '${diaProcessar.year.toString().padLeft(4, '0')}-${diaProcessar.month.toString().padLeft(2, '0')}-${diaProcessar.day.toString().padLeft(2, '0')}';

        print('DEBUG - Processando dia: $dataFormatada');

        // Para cada curso selecionado
        for (final curso in cursosSelecionados) {
          final periodoCurso = curso.periodo;
          final materia = materiasPorCurso[curso.id];
          final professor = professoresPorCurso[curso.id];

          // Para cada período de aula selecionado (cria um agendamento para cada um)
          for (String periodoAula in periodosAulaSelecionados) {
            print('DEBUG - ==========================================');
            print('DEBUG - TENTANDO INSERIR AGENDAMENTO');
            print('DEBUG - ==========================================');
            print('DEBUG - Curso: ${curso.curso} (ID: ${curso.id})');
            print('DEBUG - Sala ID: ${salaSelecionada!.id}');
            print('DEBUG - Matéria ID: ${materia!['id']}');
            print('DEBUG - Professor ID: ${professor!['id']}');
            print('DEBUG - Data formatada: $dataFormatada');
            print('DEBUG - Período curso: $periodoCurso');
            print('DEBUG - Período aula: $periodoAula');

            // Obtém os horários baseados no período da aula e período do curso
            final horarios = obterHorariosPorPeriodo(
              periodoAula,
              periodoCurso!,
            );
            final horaInicio = horarios['hora_inicio']!;
            final horaFim = horarios['hora_fim']!;

            print('DEBUG - Horário início: ${formatHora(horaInicio)}');
            print('DEBUG - Horário fim: ${formatHora(horaFim)}');

            // Preparar dados para inserção
            final dadosInserir = {
              'aula_periodo':
                  periodoAula, // Mantém "Primeira Aula" ou "Segunda Aula"
              'hora_inicio': formatHora(horaInicio),
              'hora_fim': formatHora(horaFim),
              'sala_id': salaSelecionada!.id,
              'curso_id': curso.id,
              'materia_id': materia!['id'],
              'professor_id': professor!['id'],
              'dia': dataFormatada,
              'periodo': periodoCurso,
              'tipo_agendamento': 'A', // A=Aula
              if (observacao != null && observacao.isNotEmpty)
                'observacao': observacao,
            };

            print('DEBUG - Dados para inserção: $dadosInserir');

            try {
              print('DEBUG - Executando INSERT no Supabase...');
              final response =
                  await supabase
                      .from('agendamento')
                      .insert(dadosInserir)
                      .select();

              print('DEBUG - Resposta da inserção: $response');

              // Captura o ID do agendamento criado
              if (response != null && response.isNotEmpty) {
                idsAgendamentosCriados.add(response[0]['id']);
                print(
                  'DEBUG - ✅ Agendamento criado com sucesso para curso ${curso.curso}, período $periodoAula, ID: ${response[0]['id']}',
                );
              } else {
                print(
                  'DEBUG - ❌ ERRO: Falha ao criar agendamento para curso ${curso.curso}, período $periodoAula - resposta vazia',
                );
              }
            } catch (e) {
              print(
                'DEBUG - ❌ ERRO ao inserir agendamento para curso ${curso.curso}, período $periodoAula: $e',
              );
              throw Exception(
                'Erro ao criar agendamento para curso ${curso.curso}, período $periodoAula: $e',
              );
            }
          }
        }
      }

      print(
        'DEBUG - Total de agendamentos criados: ${idsAgendamentosCriados.length}',
      );

      // Se foram criados múltiplos agendamentos, remove os registros individuais
      // do histórico e cria um registro múltiplo agrupado
      if (idsAgendamentosCriados.length > 1) {
        onProgress?.call('✨ Organizando histórico de agendamentos...');

        // Aguarda um pouco para os triggers criarem os registros individuais
        await Future.delayed(const Duration(milliseconds: 1000));

        // Remove os registros individuais do histórico criados pelos triggers
        await supabase
            .from('historico_acoes')
            .delete()
            .eq('tabela_afetada', 'agendamento')
            .eq('acao', 'INSERT')
            .in_('registro_id', idsAgendamentosCriados)
            .gte(
              'data_hora',
              timestampCriacao
                  .subtract(const Duration(seconds: 10))
                  .toIso8601String(),
            )
            .lte(
              'data_hora',
              timestampCriacao
                  .add(const Duration(seconds: 10))
                  .toIso8601String(),
            );

        // Formata as datas para exibição
        final datasFormatadas =
            diasParaProcessar.map((data) {
              return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
            }).toList();

        // Obtém o período do primeiro curso como referência
        final periodoCursoReferencia = cursosSelecionados.first.periodo;
        final primeiroCurso = cursosSelecionados.first;
        final primeiraMateria = materiasPorCurso[primeiroCurso.id]!;

        // Prepara a lista de cursos com seus detalhes
        final materiasProfessores =
            cursosSelecionados
                .map(
                  (c) => {
                    'curso_id': c.id,
                    'curso_nome': c.curso,
                    'materia_id': materiasPorCurso[c.id]!['id'],
                    'materia_nome': materiasPorCurso[c.id]!['nome'],
                    'professor_id': professoresPorCurso[c.id]!['id'],
                    'professor_nome':
                        professoresPorCurso[c.id]!['nome_professor'],
                  },
                )
                .toList();

        // Obtém os períodos de aula como lista
        final periodosAulaLista = periodosAulaSelecionados.toList();

        final detalhes =
            'Agendamento múltiplo criado para ${diasParaProcessar.length} dia(s), ${cursosSelecionados.length} curso(s) e ${periodosAulaSelecionados.length} período(s): ${datasFormatadas.join(', ')}';

        // Cria um registro especial no histórico que agrupa todos os agendamentos
        await supabase.from('historico_acoes').insert({
          'tabela_afetada': 'agendamento',
          'acao': 'INSERT_MULTIPLE',
          'registro_id':
              idsAgendamentosCriados.first, // Usa o primeiro ID como referência
          'dados_anteriores': null,
          'dados_novos': {
            'ids_agendamentos': idsAgendamentosCriados,
            'quantidade_dias': diasParaProcessar.length,
            'quantidade_cursos': cursosSelecionados.length,
            'quantidade_periodos': periodosAulaSelecionados.length,
            'datas': datasFormatadas,
            'sala_id': salaSelecionada!.id,
            'curso_id': primeiroCurso.id, // Primeiro curso para compatibilidade
            'materia_id':
                primeiraMateria['id'], // Primeira matéria para compatibilidade
            'cursos_ids': cursosSelecionados.map((c) => c.id).toList(),
            'cursos_nomes': cursosSelecionados.map((c) => c.curso).toList(),
            'materias_professores': materiasProfessores,
            'periodo': periodoCursoReferencia,
            'aula_periodo':
                periodosAulaLista.length == 1
                    ? periodosAulaLista.first
                    : periodosAulaLista,
            'aula_periodos': periodosAulaLista, // Lista de períodos
            'tipo_agendamento': 'A',
            if (observacao != null && observacao.isNotEmpty)
              'observacao': observacao,
          },
          'detalhes': detalhes,
          'data_hora': timestampCriacao.toIso8601String(),
        });
      } else if (idsAgendamentosCriados.length == 1) {
        // Para agendamento único, verifica se já existe registro criado pelo trigger
        // Se não existir, cria um registro individual
        onProgress?.call('✨ Registrando no histórico...');

        // Aguarda um pouco para o trigger criar o registro
        await Future.delayed(const Duration(milliseconds: 500));

        // Verifica se já existe registro criado pelo trigger
        final registroExistente =
            await supabase
                .from('historico_acoes')
                .select()
                .eq('tabela_afetada', 'agendamento')
                .eq('acao', 'INSERT')
                .eq('registro_id', idsAgendamentosCriados.first)
                .gte(
                  'data_hora',
                  timestampCriacao
                      .subtract(const Duration(seconds: 5))
                      .toIso8601String(),
                )
                .lte(
                  'data_hora',
                  timestampCriacao
                      .add(const Duration(seconds: 5))
                      .toIso8601String(),
                )
                .maybeSingle();

        // Se não existe registro criado pelo trigger, cria um manualmente
        if (registroExistente == null) {
          final curso = cursosSelecionados.first;
          final materia = materiasPorCurso[curso.id]!;
          final professor = professoresPorCurso[curso.id]!;
          final periodoAula = periodosAulaSelecionados.first;
          final dataFormatada =
              '${diasParaProcessar.first.year.toString().padLeft(4, '0')}-${diasParaProcessar.first.month.toString().padLeft(2, '0')}-${diasParaProcessar.first.day.toString().padLeft(2, '0')}';

          await supabase.from('historico_acoes').insert({
            'tabela_afetada': 'agendamento',
            'acao': 'INSERT',
            'registro_id': idsAgendamentosCriados.first,
            'dados_anteriores': null,
            'dados_novos': {
              'aula_periodo': periodoAula,
              'sala_id': salaSelecionada!.id,
              'curso_id': curso.id,
              'materia_id': materia['id'],
              'professor_id': professor['id'],
              'dia': dataFormatada,
              'periodo': curso.periodo,
              'tipo_agendamento': 'A',
              if (observacao != null && observacao.isNotEmpty)
                'observacao': observacao,
            },
            'detalhes': 'Agendamento criado para ${curso.curso}',
            'data_hora': timestampCriacao.toIso8601String(),
          });
        }
      }

      onProgress?.call('🎉 Agendamento(s) criado(s) com sucesso!');
    } catch (e) {
      print('DEBUG - ❌ ERRO GERAL: $e');
      throw Exception('Erro ao salvar agendamento: $e');
    }
  }

  // Função para carregar agendamentos múltiplos existentes
  Future<List<Map<String, dynamic>>> carregarAgendamentosMultiplos({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? salaId,
    int? cursoId,
  }) async {
    try {
      var query = supabase
          .from('historico_acoes')
          .select()
          .eq('tabela_afetada', 'agendamento')
          .eq('acao', 'INSERT_MULTIPLE')
          .order('data_hora', ascending: false);

      final response = await query;

      if (response == null || response.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> agendamentosMultiplos = [];

      for (final item in response) {
        final dadosNovos = item['dados_novos'] as Map<String, dynamic>?;
        if (dadosNovos != null) {
          // Aplicar filtros adicionais se fornecidos
          if (salaId != null && dadosNovos['sala_id'] != salaId) {
            continue;
          }
          if (cursoId != null &&
              !(dadosNovos['cursos_ids'] as List).contains(cursoId)) {
            continue;
          }

          // Aplicar filtros de data se fornecidos
          if (dataInicio != null) {
            final dataHora = DateTime.parse(item['data_hora']);
            if (dataHora.isBefore(dataInicio)) {
              continue;
            }
          }
          if (dataFim != null) {
            final dataHora = DateTime.parse(item['data_hora']);
            if (dataHora.isAfter(dataFim)) {
              continue;
            }
          }

          agendamentosMultiplos.add({
            'id': item['id'],
            'data_hora': item['data_hora'],
            'detalhes': item['detalhes'],
            'dados_novos': dadosNovos,
            'registro_id': item['registro_id'],
          });
        }
      }

      return agendamentosMultiplos;
    } catch (e) {
      print('Erro ao carregar agendamentos múltiplos: $e');
      return [];
    }
  }

  // Função para verificar se existem agendamentos múltiplos para um período específico
  Future<List<Map<String, dynamic>>> verificarAgendamentosMultiplosExistentes({
    required DateTime data,
    required int? salaId,
    required String periodoAula,
    required int periodoCurso,
  }) async {
    try {
      final dataFormatada =
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

      // Buscar agendamentos múltiplos que incluem esta data
      final response = await supabase
          .from('historico_acoes')
          .select()
          .eq('tabela_afetada', 'agendamento')
          .eq('acao', 'INSERT_MULTIPLE');

      List<Map<String, dynamic>> agendamentosEncontrados = [];

      for (final item in response) {
        final dadosNovos = item['dados_novos'] as Map<String, dynamic>?;
        if (dadosNovos != null) {
          final datas = dadosNovos['datas'] as List<String>?;
          final salaIdHistorico = dadosNovos['sala_id'];
          final aulaPeriodo = dadosNovos['aula_periodo'];
          final periodo = dadosNovos['periodo'];

          // Verificar se este agendamento múltiplo inclui a data e sala específicas
          if (datas != null &&
              datas.contains(dataFormatada.split('-').reversed.join('/')) &&
              salaIdHistorico == salaId &&
              aulaPeriodo == periodoAula &&
              periodo == periodoCurso) {
            agendamentosEncontrados.add({
              'id': item['id'],
              'data_hora': item['data_hora'],
              'detalhes': item['detalhes'],
              'dados_novos': dadosNovos,
              'registro_id': item['registro_id'],
            });
          }
        }
      }

      return agendamentosEncontrados;
    } catch (e) {
      print('Erro ao verificar agendamentos múltiplos existentes: $e');
      return [];
    }
  }

  // Funções de validação sequencial
  bool podeSelecionarAula({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
  }) {
    return modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;
  }

  bool podeSelecionarCurso({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
  }) {
    return podeSelecionarAula(
          modoMultiplo: modoMultiplo,
          diasMultiplosSelecionados: diasMultiplosSelecionados,
          dia: dia,
        ) &&
        periodosAulaSelecionados.isNotEmpty;
  }

  bool podeSelecionarMateria({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required int cursoId,
  }) {
    return podeSelecionarCurso(
          modoMultiplo: modoMultiplo,
          diasMultiplosSelecionados: diasMultiplosSelecionados,
          dia: dia,
          periodosAulaSelecionados: periodosAulaSelecionados,
        ) &&
        cursosSelecionados.isNotEmpty;
  }

  bool podeSelecionarProfessor({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required int cursoId,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
  }) {
    return podeSelecionarMateria(
          modoMultiplo: modoMultiplo,
          diasMultiplosSelecionados: diasMultiplosSelecionados,
          dia: dia,
          periodosAulaSelecionados: periodosAulaSelecionados,
          cursosSelecionados: cursosSelecionados,
          cursoId: cursoId,
        ) &&
        materiasPorCurso[cursoId] != null;
  }

  bool podeSelecionarSala({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
    required Map<int, Map<String, dynamic>?> professoresPorCurso,
  }) {
    if (!podeSelecionarCurso(
          modoMultiplo: modoMultiplo,
          diasMultiplosSelecionados: diasMultiplosSelecionados,
          dia: dia,
          periodosAulaSelecionados: periodosAulaSelecionados,
        ) ||
        cursosSelecionados.isEmpty) {
      return false;
    }

    // Verifica se todos os cursos têm matéria e professor selecionados
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null ||
          professoresPorCurso[curso.id] == null) {
        return false;
      }
    }
    return true;
  }

  // Função para obter mensagem de validação sequencial
  String getMensagemValidacaoSequencial({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required Set<String> periodosAulaSelecionados,
    required List<curso_model.Curso> cursosSelecionados,
    required Map<int, Map<String, dynamic>?> materiasPorCurso,
    required Map<int, Map<String, dynamic>?> professoresPorCurso,
  }) {
    if (!podeSelecionarAula(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
    )) {
      return ' Primeiro selecione o(s) dia(s) no calendário';
    }
    if (!podeSelecionarCurso(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
    )) {
      return '⚠️ Agora selecione o(s) período(s) da aula';
    }
    if (!podeSelecionarMateria(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      cursoId: 0,
    )) {
      return '⚠️ Adicione pelo menos um curso';
    }

    // Verifica se todos os cursos têm matéria selecionada
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null) {
        return '⚠️ Selecione a disciplina para o curso ${curso.curso}';
      }
    }

    // Verifica se todos os cursos têm professor selecionado
    for (final curso in cursosSelecionados) {
      if (professoresPorCurso[curso.id] == null) {
        return '⚠️ Selecione o professor para o curso ${curso.curso}';
      }
    }

    return '✅ Todos os campos preenchidos! Agora selecione a sala.';
  }
}
