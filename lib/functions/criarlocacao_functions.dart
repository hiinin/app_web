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

  // Função para carregar professores por matéria
  Future<List<Map<String, dynamic>>> carregarProfessoresPorMateria(
    int materiaId,
    int cursoId,
  ) async {
    try {
      final response = await supabase
          .from('professor_materias')
          .select('professor_id, professores!inner(id, nome_professor)')
          .eq('materia_id', materiaId);

      return (response as List).map((item) {
        return item['professores'] as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar professores: $e');
    }
  }

  // Função para filtrar salas
  Future<List<Map<String, dynamic>>> filtrarSalas({
    required String? periodoAulaSelecionado,
    required List<curso_model.Curso> cursosSelecionados,
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
  }) async {
    if (periodoAulaSelecionado == null ||
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

      // Primeiro, busca todas as salas disponíveis
      final todasSalas = await supabase
          .from('salas')
          .select('id, numero_sala, qtd_cadeiras')
          .eq('disponivel', true);

      Map<int, Map<String, dynamic>> salasDisponiveis = {};

      // Para cada dia selecionado
      for (DateTime diaVerificar in diasParaVerificar) {
        final dataFormatada =
            '${diaVerificar.year.toString().padLeft(4, '0')}-${diaVerificar.month.toString().padLeft(2, '0')}-${diaVerificar.day.toString().padLeft(2, '0')}';

        // Para cada curso selecionado
        for (final curso in cursosSelecionados) {
          final periodoCurso = curso.periodo;

          // Busca agendamentos existentes para esta data, período da aula e período do curso
          final agendamentosExistentes = await supabase
              .from('agendamento')
              .select('sala_id')
              .eq('dia', dataFormatada)
              .eq('aula_periodo', periodoAulaSelecionado!)
              .eq('periodo', periodoCurso);

          // Conta agendamentos por sala
          Map<int, int> contagemPorSala = {};
          for (final agendamento in agendamentosExistentes) {
            final salaId = agendamento['sala_id'];
            contagemPorSala[salaId] = (contagemPorSala[salaId] ?? 0) + 1;
          }

          // Verifica todas as salas disponíveis
          for (final sala in todasSalas) {
            final salaId = sala['id'];
            final contagem = contagemPorSala[salaId] ?? 0;

            // Só inclui se tem menos de 2 agendamentos
            if (contagem < 2) {
              if (!salasDisponiveis.containsKey(salaId)) {
                salasDisponiveis[salaId] = {
                  'sala_id': salaId,
                  'numero_sala': sala['numero_sala'],
                  'qtd_cadeiras': sala['qtd_cadeiras'],
                  'agendamentos_existentes': contagem,
                };
              } else {
                // Se a sala já existe, pega a maior contagem de agendamentos
                if (contagem >
                    salasDisponiveis[salaId]!['agendamentos_existentes']) {
                  salasDisponiveis[salaId]!['agendamentos_existentes'] =
                      contagem;
                }
              }
            }
          }
        }
      }

      List<Map<String, dynamic>> salasFiltradas =
          salasDisponiveis.values.toList();

      // Ordena por número de agendamentos (menos primeiro) e depois por número da sala
      salasFiltradas.sort((a, b) {
        if (a['agendamentos_existentes'] != b['agendamentos_existentes']) {
          return a['agendamentos_existentes'].compareTo(
            b['agendamentos_existentes'],
          );
        }
        return a['numero_sala'].compareTo(b['numero_sala']);
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
    required String? periodoAulaSelecionado,
    required List<curso_model.Curso> cursosSelecionados,
    required sala_model.Sala? salaSelecionada,
  }) {
    bool temDia =
        modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;
    bool temPeriodo = periodoAulaSelecionado != null;
    bool temCurso = cursosSelecionados.isNotEmpty;
    bool temSala = salaSelecionada != null;

    return temDia && temPeriodo && temCurso && temSala;
  }

  // Função para gerar mensagem de validação em ordem
  String getMensagemValidacao({
    required bool modoMultiplo,
    required Set<DateTime> diasMultiplosSelecionados,
    required DateTime? dia,
    required String? periodoAulaSelecionado,
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
    if (periodoAulaSelecionado == null) {
      camposFaltando.add('um período de aula');
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

      print(
        'DEBUG - Iniciando salvamento de ${cursosSelecionados.length} cursos',
      );
      print(
        'DEBUG - Cursos selecionados: ${cursosSelecionados.map((c) => '${c.curso} (ID: ${c.id})').join(', ')}',
      );

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
          final materia = materiasPorCurso[curso.id];
          final professor = professoresPorCurso[curso.id];

          final response =
              await supabase.from('agendamento').insert({
                'aula_periodo': periodoAulaSelecionado!,
                'sala_id': salaSelecionada!.id,
                'curso_id': curso.id,
                'materia_id': materia!['id'],
                'professor_id': professor!['id'],
                'dia': dataFormatada,
                'periodo': periodoCurso,
                'tipo_agendamento': 'A', // A=Aula
              }).select();

          // Captura o ID do agendamento criado
          if (response != null && response.isNotEmpty) {
            idsAgendamentosCriados.add(response[0]['id']);
          } else {
            print(
              'DEBUG - ERRO: Falha ao criar agendamento para curso ${curso.curso}',
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
}
