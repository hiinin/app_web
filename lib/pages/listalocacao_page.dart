import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../functions/drawer_helper.dart';
import '../functions/listalocacao_functions.dart' as locacao_functions;

class ListaLocacaoPage extends StatefulWidget {
  const ListaLocacaoPage({super.key});

  @override
  State<ListaLocacaoPage> createState() => _ListaLocacaoPageState();
}

class _ListaLocacaoPageState extends State<ListaLocacaoPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  List<dynamic> agendamentos = [];

  DateTime diaSelecionado = DateTime.now();

  List<Map<String, dynamic>> cursos = [];
  int? cursoSelecionadoId;

  // Controllers e filtros
  final TextEditingController pesquisaController = TextEditingController();
  String filtroTipo = 'Todos'; // 'Todos', 'Aulas', 'Eventos', 'Provas'
  String filtroPeriodo = 'Todos'; // 'Todos', 'Manhã', 'Vespertino', 'Noturno'
  bool mostrarMultiplasTurmas = false;
  bool mostrarFiltroAvancado = false;

  @override
  void initState() {
    super.initState();
    carregarAgendamentos();
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  Future<void> selecionarDia() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: diaSelecionado,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => diaSelecionado = picked);
      carregarAgendamentos();
    }
  }

  Future<void> carregarAgendamentos({int? cursoId}) async {
    setState(() => isLoading = true);

    try {
      final response = await locacao_functions.carregarAgendamentos(
        supabase,
        diaSelecionado,
        cursoId: cursoId,
      );

      setState(() => agendamentos = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> buscarPorCurso() async {
    await locacao_functions.buscarPorCurso(supabase, cursoSelecionadoId);
  }

  String periodoToString(int? periodo) {
    return locacao_functions.periodoToString(periodo);
  }

  Future<void> editarAgendamento(Map agendamento) async {
    // Instância da classe de funções de edição
    final editarFunctions = locacao_functions.EditarLocacaoFunctions();

    // Dados atuais do agendamento
    final salaAtual = agendamento['salas'];
    final cursoAtual = agendamento['cursos'];
    final dataAtual = DateTime.parse(agendamento['dia']);

    // Controllers para os dropdowns
    String? salaSelecionada = salaAtual['id']?.toString();
    String? cursoSelecionado = cursoAtual['id']?.toString();
    String? materiaSelecionada = agendamento['materias']?['id']?.toString();
    String? professorSelecionado =
        agendamento['professores']?['id']?.toString();
    DateTime dataSelecionada = dataAtual;

    // Preservar período da aula original
    String aulaPeriodoOriginal = agendamento['aula_periodo'] ?? 'Primeira Aula';

    // Controller para observação
    final TextEditingController observacaoController = TextEditingController(
      text: agendamento['observacao'] ?? '',
    );

    // Listas para os dropdowns
    List<Map<String, dynamic>> salas = [];
    List<Map<String, dynamic>> cursos = [];
    List<Map<String, dynamic>> materias = [];
    List<Map<String, dynamic>> professores = [];

    try {
      // Carregar dados usando a classe de funções
      final dados = await editarFunctions.carregarDadosEdicao();
      salas = dados['salas'] as List<Map<String, dynamic>>;
      cursos = dados['cursos'] as List<Map<String, dynamic>>;

      // Verificar se a sala selecionada existe na lista
      if (salaSelecionada != null &&
          !salas.any((s) => s['id'].toString() == salaSelecionada)) {
        salaSelecionada = null;
      }

      // Verificar se o curso selecionado existe na lista
      if (cursoSelecionado != null &&
          !cursos.any((c) => c['id'].toString() == cursoSelecionado)) {
        cursoSelecionado = null;
        materiaSelecionada = null;
        professorSelecionado = null;
        materias = [];
        professores = [];
      }

      // Carregar disciplinas do curso atual (se houver)
      if (cursoSelecionado != null) {
        materias = await editarFunctions.carregarMateriasPorCurso(
          int.parse(cursoSelecionado),
        );
        // Verificar se a disciplina selecionada ainda existe na nova lista
        if (materiaSelecionada != null &&
            !materias.any((m) => m['id'].toString() == materiaSelecionada)) {
          materiaSelecionada = null;
          professorSelecionado = null;
          professores = [];
        }
      }

      // Carregar professores do curso atual (se houver)
      if (cursoSelecionado != null) {
        professores = await editarFunctions.carregarProfessoresPorTurma(
          int.parse(cursoSelecionado),
        );
        // Verificar se o professor selecionado ainda existe na nova lista
        if (professorSelecionado != null &&
            !professores.any(
              (p) => p['id'].toString() == professorSelecionado,
            )) {
          professorSelecionado = null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.edit, color: const Color(0xFF44A301)),
                      const SizedBox(width: 8),
                      const Text('Editar Agendamento'),
                    ],
                  ),
                  content: SizedBox(
                    width: 1000,
                    height: 500,
                    child: Row(
                      children: [
                        // Lado esquerdo: Calendário
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 500,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                // Cabeçalho do calendário
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF44A301),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            dataSelecionada = DateTime(
                                              dataSelecionada.year,
                                              dataSelecionada.month - 1,
                                              1,
                                            );
                                          });
                                        },
                                      ),
                                      Text(
                                        '${_getMonthName(dataSelecionada.month)} ${dataSelecionada.year}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            dataSelecionada = DateTime(
                                              dataSelecionada.year,
                                              dataSelecionada.month + 1,
                                              1,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Dias da semana
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children:
                                        [
                                              'Dom',
                                              'Seg',
                                              'Ter',
                                              'Qua',
                                              'Qui',
                                              'Sex',
                                              'Sáb',
                                            ]
                                            .map(
                                              (day) => Expanded(
                                                child: Center(
                                                  child: Text(
                                                    day,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                                // Grade do calendário
                                Expanded(
                                  child: _buildCalendarGrid(
                                    dataSelecionada,
                                    setState,
                                    selectedDate: dataSelecionada,
                                    onDateSelected: (DateTime newDate) {
                                      setState(() {
                                        dataSelecionada = newDate;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Lado direito: Campos
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Editar Agendamento',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Dropdown Sala
                                DropdownButtonFormField<String>(
                                  value:
                                      salaSelecionada != null &&
                                              salas.any(
                                                (s) =>
                                                    s['id'].toString() ==
                                                    salaSelecionada,
                                              )
                                          ? salaSelecionada
                                          : null,
                                  decoration: InputDecoration(
                                    labelText: 'Sala',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.meeting_room),
                                  ),
                                  items:
                                      salas
                                          .map(
                                            (sala) => DropdownMenuItem(
                                              value: sala['id'].toString(),
                                              child: Text(
                                                'Sala ${sala['numero_sala']}',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      salaSelecionada = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Dropdown Curso
                                DropdownButtonFormField<String>(
                                  value:
                                      cursoSelecionado != null &&
                                              cursos.any(
                                                (c) =>
                                                    c['id'].toString() ==
                                                    cursoSelecionado,
                                              )
                                          ? cursoSelecionado
                                          : null,
                                  decoration: InputDecoration(
                                    labelText: 'Curso',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.school),
                                  ),
                                  items:
                                      cursos
                                          .map(
                                            (curso) => DropdownMenuItem(
                                              value: curso['id'].toString(),
                                              child: Text(curso['curso']),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) async {
                                    setState(() {
                                      cursoSelecionado = value;
                                      materiaSelecionada = null;
                                      professorSelecionado = null;
                                      materias = [];
                                      professores = [];
                                    });
                                    if (value != null) {
                                      materias = await editarFunctions
                                          .carregarMateriasPorCurso(
                                            int.parse(value),
                                          );
                                      setState(() {});
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Dropdown Disciplina
                                DropdownButtonFormField<String>(
                                  value:
                                      materiaSelecionada != null &&
                                              materias.any(
                                                (m) =>
                                                    m['id'].toString() ==
                                                    materiaSelecionada,
                                              )
                                          ? materiaSelecionada
                                          : null,
                                  decoration: InputDecoration(
                                    labelText:
                                        cursoSelecionado != null
                                            ? 'Disciplina'
                                            : 'Disciplina (selecione um curso primeiro)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.book),
                                  ),
                                  items:
                                      materias
                                          .map(
                                            (materia) => DropdownMenuItem(
                                              value: materia['id'].toString(),
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 200,
                                                    ),
                                                child: Text(
                                                  materia['nome'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  menuMaxHeight: 200,
                                  onChanged:
                                      cursoSelecionado != null
                                          ? (value) async {
                                            setState(() {
                                              materiaSelecionada = value;
                                              professorSelecionado = null;
                                              professores = [];
                                            });
                                            if (value != null) {
                                              professores = await editarFunctions
                                                  .carregarProfessoresPorMateria(
                                                    int.parse(value),
                                                  );
                                              setState(() {});
                                            }
                                          }
                                          : null,
                                ),

                                const SizedBox(height: 16),

                                // Dropdown Professor
                                DropdownButtonFormField<String>(
                                  value:
                                      professorSelecionado != null &&
                                              professores.any(
                                                (p) =>
                                                    p['id'].toString() ==
                                                    professorSelecionado,
                                              )
                                          ? professorSelecionado
                                          : null,
                                  decoration: InputDecoration(
                                    labelText:
                                        materiaSelecionada != null
                                            ? 'Professor'
                                            : 'Professor (selecione uma disciplina primeiro)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  items:
                                      professores
                                          .map(
                                            (professor) => DropdownMenuItem(
                                              value: professor['id'].toString(),
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 200,
                                                    ),
                                                child: Text(
                                                  professor['nome_professor'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  menuMaxHeight: 200,
                                  onChanged:
                                      materiaSelecionada != null
                                          ? (value) {
                                            setState(() {
                                              professorSelecionado = value;
                                            });
                                          }
                                          : null,
                                ),

                                const SizedBox(height: 16),

                                // Dropdown Turno da Aula
                                DropdownButtonFormField<String>(
                                  value: aulaPeriodoOriginal,
                                  decoration: InputDecoration(
                                    labelText: 'Turno da Aula',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.schedule),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Primeira Aula',
                                      child: Text('Primeira Aula'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Segunda Aula',
                                      child: Text('Segunda Aula'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      aulaPeriodoOriginal = value!;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Campo de Observação
                                TextField(
                                  controller: observacaoController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Observação',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.note),
                                    hintText:
                                        'Digite uma observação sobre o agendamento...',
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (salaSelecionada != null &&
                            cursoSelecionado != null &&
                            materiaSelecionada != null &&
                            professorSelecionado != null) {
                          Navigator.pop(context, {
                            'sala_id': int.parse(salaSelecionada!),
                            'curso_id': int.parse(cursoSelecionado!),
                            'materia_id': int.parse(materiaSelecionada!),
                            'professor_id': int.parse(professorSelecionado!),
                            'data': dataSelecionada,
                            'aula_periodo': aulaPeriodoOriginal,
                            'observacao': observacaoController.text,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      try {
        // Verificar conflitos usando a função da classe
        final conflito = await editarFunctions.verificarConflitosEdicao(
          result['sala_id'],
          result['curso_id'],
          result['materia_id'],
          result['professor_id'],
          result['data'],
          result['aula_periodo'],
          agendamento['id'], // Excluir o próprio agendamento da verificação
        );

        if (conflito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Conflito detectado! Esta sala/curso já está agendada para esta data e período.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Atualizar agendamento usando a função da classe
        await editarFunctions.atualizarAgendamento(
          agendamentoId: agendamento['id'],
          salaId: result['sala_id'],
          cursoId: result['curso_id'],
          materiaId: result['materia_id'],
          professorId: result['professor_id'],
          data: result['data'],
          aulaPeriodo: result['aula_periodo'],
          observacao: result['observacao'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Agendamento atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar agendamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Dispose do controller
    observacaoController.dispose();
  }

  Future<void> excluirAgendamento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir este agendamento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('agendamento').delete().eq('id', id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agendamento excluído')));
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  String _getMonthName(int month) {
    return locacao_functions.getMonthName(month);
  }

  Widget _buildCalendarGrid(
    DateTime currentMonth,
    StateSetter setState, {
    DateTime? selectedDate,
    Function(DateTime)? onDateSelected,
  }) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    List<Widget> calendarDays = [];

    // Adiciona dias vazios no início
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    // Adiciona os dias do mês
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final currentDate = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected =
          currentDate.day == diaSelecionado.day &&
          currentDate.month == diaSelecionado.month &&
          currentDate.year == diaSelecionado.year;
      final isToday =
          currentDate.day == DateTime.now().day &&
          currentDate.month == DateTime.now().month &&
          currentDate.year == DateTime.now().year;
      final isPastDate = currentDate.isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );

      calendarDays.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                diaSelecionado = currentDate;
              });
              // Chamar o callback se fornecido
              if (onDateSelected != null) {
                onDateSelected(currentDate);
              }
            },
            child: Container(
              height: 28,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected
                        ? const Color(0xFF44A301)
                        : isToday
                        ? const Color(0xFFE8F5E8)
                        : Colors.transparent,
                border:
                    isToday && !isSelected
                        ? Border.all(color: const Color(0xFF44A301), width: 2)
                        : null,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: const Color(0xFF44A301).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : isToday
                            ? const Color(0xFF44A301)
                            : isPastDate
                            ? Colors.grey[600]
                            : Colors.black87,
                    fontWeight:
                        isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Adiciona dias vazios no final para completar 6 semanas (42 dias)
    while (calendarDays.length < 42) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: List.generate((calendarDays.length / 7).ceil(), (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: calendarDays.skip(weekIndex * 7).take(7).toList(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final currentMonth = diaSelecionado;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    List<Widget> calendarDays = [];

    // Adiciona dias vazios no início
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    // Adiciona os dias do mês
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final currentDate = DateTime(currentMonth.year, currentMonth.month, day);
      final isSelected =
          diaSelecionado.year == currentDate.year &&
          diaSelecionado.month == currentDate.month &&
          diaSelecionado.day == currentDate.day;
      final isToday =
          now.year == currentDate.year &&
          now.month == currentDate.month &&
          now.day == currentDate.day;
      final isPastDate = currentDate.isBefore(
        DateTime(now.year, now.month, now.day),
      );

      calendarDays.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                diaSelecionado = currentDate;
                carregarAgendamentos();
              });
            },
            child: Container(
              height: 40, // Aumentei a altura para ocupar melhor o espaço
              margin: const EdgeInsets.all(2), // Aumentei a margem
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected
                        ? const Color(0xFF44A301)
                        : isToday
                        ? const Color(0xFFE8F5E8)
                        : Colors.transparent,
                border:
                    isToday && !isSelected
                        ? Border.all(color: const Color(0xFF44A301), width: 2)
                        : null,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: const Color(0xFF44A301).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : isToday
                            ? const Color(0xFF44A301)
                            : isPastDate
                            ? Colors.grey[600]
                            : Colors.black87,
                    fontWeight:
                        isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                    fontSize: 14, // Aumentei o tamanho da fonte
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Adiciona dias vazios no final para completar 6 semanas (42 dias)
    while (calendarDays.length < 42) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    return Container(
      padding: const EdgeInsets.all(
        12,
      ), // Reduzi o padding para diminuir espaço
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
        children: [
          // Cabeçalho do mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    diaSelecionado = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                      1,
                    );
                    carregarAgendamentos();
                  });
                },
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF44A301),
                  size: 20,
                ),
              ),
              Text(
                '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF44A301),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    diaSelecionado = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                      1,
                    );
                    carregarAgendamentos();
                  });
                },
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF44A301),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Aumentei o espaçamento
          // Dias da semana
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Dom',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11, // Reduzi o tamanho da fonte
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Seg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Ter',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Qua',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Qui',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sex',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sáb',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Aumentei o espaçamento
          // Grade do calendário
          ...List.generate((calendarDays.length / 7).ceil(), (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 3,
              ), // Aumentei o padding
              child: Row(
                children: calendarDays.skip(weekIndex * 7).take(7).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF44A301), // Verde principal do tema
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lista Agendamento',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: buildAppDrawer(context),
      backgroundColor: const Color(0xFFF8FAFC), // igual criarcurso
      body: Row(
        children: [
          // Lado esquerdo: filtros
          Container(
            width: 390, // aumentei a largura do painel de filtros
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8F5E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendário com altura fixa
                Container(
                  height: 380,
                  child: SingleChildScrollView(child: _buildCustomCalendar()),
                ),
                // Área de filtros com scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_box, size: 16),
                                  label: const Text('Novo Ensalamento'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF44A301),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/criarlocacao',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.event, size: 16),
                                  label: const Text('Novo Evento'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/criarevento',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.quiz, size: 16),
                                  label: const Text('Nova Prova'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/criarprova');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Lado direito: lista expandida
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      color: const Color(0xFFF5F6FA),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Barra de pesquisa e filtros
                          Container(
                            padding: const EdgeInsets.all(18),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Barra de pesquisa
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF44A301),
                                            width: 2,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: pesquisaController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Pesquisar por Sala ou Turma...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              color: Color(0xFF44A301),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Botão de filtro avançado
                                    ElevatedButton.icon(
                                      icon: Icon(
                                        mostrarFiltroAvancado
                                            ? Icons.filter_alt
                                            : Icons.filter_alt_outlined,
                                      ),
                                      label: const Text('Filtro Avançado'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            mostrarFiltroAvancado
                                                ? const Color(0xFF44A301)
                                                : Colors.grey[300],
                                        foregroundColor:
                                            mostrarFiltroAvancado
                                                ? Colors.white
                                                : Colors.black87,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          mostrarFiltroAvancado =
                                              !mostrarFiltroAvancado;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Builder(
                                  builder: (context) {
                                    // Aplicar filtros
                                    final agendamentosFiltrados =
                                        locacao_functions.aplicarFiltros(
                                          agendamentos,
                                          pesquisaTexto:
                                              pesquisaController.text,
                                          filtroTipo: filtroTipo,
                                          filtroPeriodo: filtroPeriodo,
                                          mostrarMultiplasTurmas:
                                              mostrarMultiplasTurmas,
                                        );

                                    // Mapear cores para salas com múltiplas turmas (apenas se o filtro estiver ativo)
                                    final coresPorSala =
                                        mostrarMultiplasTurmas
                                            ? locacao_functions
                                                .mapearCoresPorSala(
                                                  agendamentosFiltrados,
                                                )
                                            : <String, Color>{};

                                    if (agendamentosFiltrados.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.event_busy,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Nenhum agendamento encontrado',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tente ajustar os filtros ou selecionar outra data',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView(
                                      padding: const EdgeInsets.all(18),
                                      children: [
                                        ...[1, 2, 3].expand((periodo) {
                                          // Verifica se o período está sendo filtrado
                                          if (filtroPeriodo != 'Todos') {
                                            String periodoFiltrado;
                                            switch (periodo) {
                                              case 1:
                                                periodoFiltrado = 'Manhã';
                                                break;
                                              case 2:
                                                periodoFiltrado = 'Vespertino';
                                                break;
                                              case 3:
                                                periodoFiltrado = 'Noturno';
                                                break;
                                              default:
                                                periodoFiltrado = 'Outro';
                                            }
                                            if (periodoFiltrado !=
                                                filtroPeriodo) {
                                              return <Widget>[];
                                            }
                                          }

                                          // Se mostrarMultiplasTurmas está ativo, agrupa por sala
                                          if (mostrarMultiplasTurmas) {
                                            // Filtra agendamentos por período
                                            final agsDoPeriodo =
                                                agendamentosFiltrados
                                                    .where(
                                                      (ag) =>
                                                          ag['cursos']?['periodo'] ==
                                                          periodo,
                                                    )
                                                    .toList();

                                            if (agsDoPeriodo.isEmpty)
                                              return <Widget>[];

                                            // Agrupa por sala
                                            final salasAgrupadas =
                                                locacao_functions
                                                    .agruparAgendamentosPorSala(
                                                      agsDoPeriodo,
                                                    );

                                            if (salasAgrupadas.isEmpty)
                                              return <Widget>[];

                                            String tituloPeriodo;
                                            switch (periodo) {
                                              case 1:
                                                tituloPeriodo = 'Manhã';
                                                break;
                                              case 2:
                                                tituloPeriodo = 'Vespertino';
                                                break;
                                              case 3:
                                                tituloPeriodo = 'Noturno';
                                                break;
                                              default:
                                                tituloPeriodo = 'Outro';
                                            }

                                            return [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                child: Text(
                                                  tituloPeriodo,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF44A301),
                                                  ),
                                                ),
                                              ),
                                              ...salasAgrupadas.values.map((
                                                salaData,
                                              ) {
                                                final salaNumero =
                                                    salaData['salaNumero'];
                                                final turmas =
                                                    salaData['turmas'] as List;
                                                final agendamentos =
                                                    salaData['agendamentos']
                                                        as List;

                                                // Obter cor da sala
                                                Color? corSala;
                                                if (!agendamentos.isEmpty) {
                                                  corSala = locacao_functions
                                                      .obterCorSala(
                                                        coresPorSala,
                                                        agendamentos.first,
                                                      );
                                                }

                                                // Determinar cor baseada no tipo de agendamento (usa o primeiro)
                                                Color corCard;
                                                if (!agendamentos.isEmpty) {
                                                  final tipoAgendamento =
                                                      agendamentos
                                                          .first['tipo_agendamento'];
                                                  if (tipoAgendamento == 'A') {
                                                    corCard = const Color(
                                                      0xFF44A301,
                                                    );
                                                  } else if (tipoAgendamento ==
                                                      'E') {
                                                    corCard = Colors.orange;
                                                  } else if (tipoAgendamento ==
                                                      'M') {
                                                    corCard = Colors.red;
                                                  } else {
                                                    corCard = const Color(
                                                      0xFF44A301,
                                                    );
                                                  }
                                                } else {
                                                  corCard = const Color(
                                                    0xFF44A301,
                                                  );
                                                }

                                                final corParaDestacar =
                                                    corSala ?? corCard;
                                                final corParaTitulo =
                                                    corParaDestacar;

                                                return Card(
                                                  elevation: 6,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    side: BorderSide(
                                                      color: corParaDestacar,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                        colors: [
                                                          corParaDestacar
                                                              .withOpacity(0.1),
                                                          corParaDestacar
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                          corParaDestacar
                                                              .withOpacity(0.1),
                                                          corParaDestacar
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                        ],
                                                        stops: const [
                                                          0.0,
                                                          0.5,
                                                          0.5,
                                                          1.0,
                                                        ],
                                                      ),
                                                    ),
                                                    child: ExpansionTile(
                                                      tilePadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 24,
                                                            vertical: 8,
                                                          ),
                                                      title: Text(
                                                        'Sala: $salaNumero',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: corParaTitulo,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        '${turmas.length} ${turmas.length == 1 ? 'turma' : 'turmas'} nesta sala',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[700],
                                                        ),
                                                      ),
                                                      children:
                                                          turmas.map<Widget>((
                                                            turma,
                                                          ) {
                                                            final curso =
                                                                turma['curso']
                                                                    as Map<
                                                                      String,
                                                                      dynamic
                                                                    >;
                                                            final agsTurma =
                                                                turma['agendamentos']
                                                                    as List;

                                                            final Set<String>
                                                            chavesUnicas = {};
                                                            final List<dynamic>
                                                            agsUnicos = [];
                                                            for (final ag
                                                                in agsTurma) {
                                                              final chave =
                                                                  '${ag['sala_id']}_${ag['curso_id']}_${ag['dia']}_${ag['periodo']}_${ag['aula_periodo']}';
                                                              if (!chavesUnicas
                                                                  .contains(
                                                                    chave,
                                                                  )) {
                                                                chavesUnicas
                                                                    .add(chave);
                                                                agsUnicos.add(
                                                                  ag,
                                                                );
                                                              }
                                                            }

                                                            return Card(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                              elevation: 2,
                                                              child: ExpansionTile(
                                                                title: Text(
                                                                  'Turma: ${curso['curso'] ?? ''}',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                                subtitle: Text(
                                                                  '${agsUnicos.length} agendamento(s)',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                  ),
                                                                ),
                                                                children: [
                                                                  Container(
                                                                    width:
                                                                        double
                                                                            .infinity,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          0,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                    child: DataTable(
                                                                      columnSpacing:
                                                                          16,
                                                                      columns: const [
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Tipo',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Data',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Turno',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Sala',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Disciplina/Evento',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Professor',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Turno',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Início',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Fim',
                                                                          ),
                                                                        ),
                                                                        DataColumn(
                                                                          label: Text(
                                                                            'Ações',
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      rows:
                                                                          agsUnicos.map<
                                                                            DataRow
                                                                          >((
                                                                            agendamento,
                                                                          ) {
                                                                            final salaAg =
                                                                                agendamento['salas'];
                                                                            final materia =
                                                                                agendamento['materias'];
                                                                            final professor =
                                                                                agendamento['professores'];
                                                                            final cursoAg =
                                                                                agendamento['cursos'];
                                                                            final horaInicio =
                                                                                agendamento['hora_inicio'];
                                                                            final horaFim =
                                                                                agendamento['hora_fim'];
                                                                            final tipoAgendamento =
                                                                                agendamento['tipo_agendamento'];
                                                                            final nomeEvento =
                                                                                agendamento['nome_evento'];
                                                                            final dia = DateTime.parse(
                                                                              agendamento['dia'],
                                                                            );
                                                                            final dataFormatada =
                                                                                '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';

                                                                            final tipoTexto =
                                                                                tipoAgendamento ==
                                                                                        'A'
                                                                                    ? 'Aula'
                                                                                    : tipoAgendamento ==
                                                                                        'E'
                                                                                    ? 'Evento'
                                                                                    : tipoAgendamento ==
                                                                                        'M'
                                                                                    ? 'Prova'
                                                                                    : 'Desconhecido';
                                                                            final tipoColor =
                                                                                tipoAgendamento ==
                                                                                        'A'
                                                                                    ? const Color(
                                                                                      0xFF44A301,
                                                                                    )
                                                                                    : tipoAgendamento ==
                                                                                        'E'
                                                                                    ? Colors.orange
                                                                                    : tipoAgendamento ==
                                                                                        'M'
                                                                                    ? Colors.red
                                                                                    : Colors.grey;

                                                                            final salaLocal =
                                                                                salaAg?['numero_sala']?.toString() ??
                                                                                '-';

                                                                            final materiaEvento =
                                                                                tipoAgendamento ==
                                                                                        'A'
                                                                                    ? (materia?['nome'] ??
                                                                                        '-')
                                                                                    : tipoAgendamento ==
                                                                                        'E'
                                                                                    ? (nomeEvento ??
                                                                                        '-')
                                                                                    : tipoAgendamento ==
                                                                                        'M'
                                                                                    ? (materia?['nome'] ??
                                                                                        '-')
                                                                                    : '-';

                                                                            return DataRow(
                                                                              cells: [
                                                                                DataCell(
                                                                                  Container(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      horizontal:
                                                                                          8,
                                                                                      vertical:
                                                                                          4,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      color:
                                                                                          tipoColor,
                                                                                      borderRadius: BorderRadius.circular(
                                                                                        12,
                                                                                      ),
                                                                                    ),
                                                                                    child: Text(
                                                                                      tipoTexto,
                                                                                      style: const TextStyle(
                                                                                        color:
                                                                                            Colors.white,
                                                                                        fontWeight:
                                                                                            FontWeight.bold,
                                                                                        fontSize:
                                                                                            12,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    dataFormatada,
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    agendamento['aula_periodo'] ??
                                                                                        '',
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    salaLocal,
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    materiaEvento,
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    professor?['nome_professor'] ??
                                                                                        '-',
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    locacao_functions.periodoToString(
                                                                                      cursoAg['periodo'],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    horaInicio?.toString().substring(
                                                                                          0,
                                                                                          5,
                                                                                        ) ??
                                                                                        '',
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Text(
                                                                                    horaFim?.toString().substring(
                                                                                          0,
                                                                                          5,
                                                                                        ) ??
                                                                                        '',
                                                                                  ),
                                                                                ),
                                                                                DataCell(
                                                                                  Row(
                                                                                    mainAxisSize:
                                                                                        MainAxisSize.min,
                                                                                    children: [
                                                                                      IconButton(
                                                                                        icon: const Icon(
                                                                                          Icons.edit,
                                                                                          color: Color(
                                                                                            0xFF44A301,
                                                                                          ),
                                                                                        ),
                                                                                        onPressed:
                                                                                            () => editarAgendamento(
                                                                                              agendamento,
                                                                                            ),
                                                                                      ),
                                                                                      IconButton(
                                                                                        icon: const Icon(
                                                                                          Icons.delete,
                                                                                          color:
                                                                                              Colors.red,
                                                                                        ),
                                                                                        onPressed:
                                                                                            () => excluirAgendamento(
                                                                                              agendamento['id'],
                                                                                            ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          }).toList(),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }).toList(),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ];
                                          }

                                          final Map<int, Map<String, dynamic>>
                                          cursosUnicos = {};
                                          for (final ag
                                              in agendamentosFiltrados) {
                                            final curso = ag['cursos'];
                                            if (curso != null &&
                                                curso['periodo'] == periodo) {
                                              cursosUnicos[curso['id']] = curso;
                                            }
                                          }
                                          if (cursosUnicos.isEmpty)
                                            return <Widget>[];

                                          String tituloPeriodo;
                                          switch (periodo) {
                                            case 1:
                                              tituloPeriodo = 'Manhã';
                                              break;
                                            case 2:
                                              tituloPeriodo = 'Vespertino';
                                              break;
                                            case 3:
                                              tituloPeriodo = 'Noturno';
                                              break;
                                            default:
                                              tituloPeriodo = 'Outro';
                                          }

                                          return [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Text(
                                                tituloPeriodo,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF44A301),
                                                ),
                                              ),
                                            ),
                                            ...cursosUnicos.values.map((curso) {
                                              final agsDoCurso =
                                                  agendamentosFiltrados
                                                      .where(
                                                        (ag) =>
                                                            ag['cursos']?['id'] ==
                                                            curso['id'],
                                                      )
                                                      .toList();

                                              final Set<String> chavesUnicas =
                                                  {};
                                              final List<dynamic> agsUnicos =
                                                  [];
                                              for (final ag in agsDoCurso) {
                                                final chave =
                                                    '${ag['sala_id']}_${ag['curso_id']}_${ag['dia']}_${ag['periodo']}_${ag['aula_periodo']}';
                                                if (!chavesUnicas.contains(
                                                  chave,
                                                )) {
                                                  chavesUnicas.add(chave);
                                                  agsUnicos.add(ag);
                                                }
                                              }
                                              // Pegar informações do primeiro agendamento para o card
                                              final primeiroAg =
                                                  agsUnicos.isNotEmpty
                                                      ? agsUnicos.first
                                                      : null;
                                              final sala = primeiroAg?['salas'];
                                              final materia =
                                                  primeiroAg?['materias'];
                                              final nomeEvento =
                                                  primeiroAg?['nome_evento'];
                                              final tipoAgendamento =
                                                  primeiroAg?['tipo_agendamento'];
                                              final aulaPeriodo =
                                                  primeiroAg?['aula_periodo'] ??
                                                  '';

                                              // Determinar cor baseada no tipo de agendamento
                                              Color corCard;
                                              String disciplinaEvento;

                                              if (tipoAgendamento == 'A') {
                                                corCard = const Color(
                                                  0xFF44A301,
                                                ); // Verde
                                                disciplinaEvento =
                                                    materia?['nome'] ?? '-';
                                              } else if (tipoAgendamento ==
                                                  'E') {
                                                corCard =
                                                    Colors.orange; // Laranja
                                                disciplinaEvento =
                                                    nomeEvento ?? '-';
                                              } else if (tipoAgendamento ==
                                                  'M') {
                                                corCard =
                                                    Colors.red; // Vermelho
                                                disciplinaEvento =
                                                    materia?['nome'] ?? '-';
                                              } else {
                                                corCard = const Color(
                                                  0xFF44A301,
                                                ); // Verde padrão
                                                disciplinaEvento =
                                                    materia?['nome'] ??
                                                    nomeEvento ??
                                                    '-';
                                              }

                                              // Verificar se algum agendamento está em sala com múltiplas turmas
                                              Color? corSala;
                                              bool temMultiplasTurmas = false;
                                              for (final ag in agsUnicos) {
                                                final cor = locacao_functions
                                                    .obterCorSala(
                                                      coresPorSala,
                                                      ag,
                                                    );
                                                if (cor != null) {
                                                  corSala = cor;
                                                  temMultiplasTurmas = true;
                                                  break; // Usa a primeira cor encontrada
                                                }
                                              }

                                              // Se o filtro está ativo e tem múltiplas turmas, usa a cor única da sala
                                              // Caso contrário, usa a cor do tipo
                                              final deveDestacar =
                                                  mostrarMultiplasTurmas &&
                                                  temMultiplasTurmas;
                                              final corParaDestacar =
                                                  deveDestacar &&
                                                          corSala != null
                                                      ? corSala
                                                      : corCard;
                                              final corParaTitulo =
                                                  deveDestacar &&
                                                          corSala != null
                                                      ? corSala
                                                      : corCard;

                                              // Informações para o subtítulo
                                              final salaNumero =
                                                  sala?['numero_sala']
                                                      ?.toString() ??
                                                  '-';
                                              final subtitulo =
                                                  'Sala: $salaNumero | ${disciplinaEvento.isNotEmpty ? disciplinaEvento : 'N/A'} | Turno: $aulaPeriodo';

                                              return Card(
                                                elevation: 6,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side:
                                                      deveDestacar
                                                          ? BorderSide(
                                                            color:
                                                                corParaDestacar,
                                                            width: 3,
                                                          )
                                                          : BorderSide.none,
                                                ),
                                                child: Container(
                                                  decoration:
                                                      deveDestacar
                                                          ? BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                            // Efeito listrado
                                                            gradient: LinearGradient(
                                                              begin:
                                                                  Alignment
                                                                      .topLeft,
                                                              end:
                                                                  Alignment
                                                                      .bottomRight,
                                                              colors: [
                                                                corParaDestacar
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                corParaDestacar
                                                                    .withOpacity(
                                                                      0.05,
                                                                    ),
                                                                corParaDestacar
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                corParaDestacar
                                                                    .withOpacity(
                                                                      0.05,
                                                                    ),
                                                              ],
                                                              stops: const [
                                                                0.0,
                                                                0.5,
                                                                0.5,
                                                                1.0,
                                                              ],
                                                            ),
                                                          )
                                                          : null,
                                                  child: ExpansionTile(
                                                    tilePadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 8,
                                                        ),
                                                    title: Text(
                                                      'Turma: ${curso['curso'] ?? ''}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: corParaTitulo,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      subtitulo,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    children: [
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 0,
                                                              vertical: 8,
                                                            ),
                                                        child: DataTable(
                                                          columnSpacing: 16,
                                                          columns: const [
                                                            DataColumn(
                                                              label: Text(
                                                                'Tipo',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Data',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Turno',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Sala',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Disciplina/Evento',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Professor',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Turno',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Início',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Fim',
                                                              ),
                                                            ),
                                                            DataColumn(
                                                              label: Text(
                                                                'Ações',
                                                              ),
                                                            ),
                                                          ],
                                                          rows:
                                                              agsUnicos.map<
                                                                DataRow
                                                              >((agendamento) {
                                                                final sala =
                                                                    agendamento['salas'];
                                                                final materia =
                                                                    agendamento['materias'];
                                                                final professor =
                                                                    agendamento['professores'];
                                                                final curso =
                                                                    agendamento['cursos'];
                                                                final horaInicio =
                                                                    agendamento['hora_inicio'];
                                                                final horaFim =
                                                                    agendamento['hora_fim'];
                                                                final tipoAgendamento =
                                                                    agendamento['tipo_agendamento'];
                                                                final nomeEvento =
                                                                    agendamento['nome_evento'];
                                                                final dia =
                                                                    DateTime.parse(
                                                                      agendamento['dia'],
                                                                    );
                                                                final dataFormatada =
                                                                    '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';

                                                                // Determina o tipo de agendamento
                                                                final tipoTexto =
                                                                    tipoAgendamento ==
                                                                            'A'
                                                                        ? 'Aula'
                                                                        : tipoAgendamento ==
                                                                            'E'
                                                                        ? 'Evento'
                                                                        : tipoAgendamento ==
                                                                            'M'
                                                                        ? 'Prova'
                                                                        : 'Desconhecido';
                                                                final tipoColor =
                                                                    tipoAgendamento ==
                                                                            'A'
                                                                        ? const Color(
                                                                          0xFF44A301,
                                                                        )
                                                                        : tipoAgendamento ==
                                                                            'E'
                                                                        ? Colors
                                                                            .orange
                                                                        : tipoAgendamento ==
                                                                            'M'
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .grey;

                                                                // Determina sala
                                                                final salaLocal =
                                                                    sala?['numero_sala']
                                                                        ?.toString() ??
                                                                    '-';

                                                                // Determina disciplina/evento
                                                                final materiaEvento =
                                                                    tipoAgendamento ==
                                                                            'A'
                                                                        ? (materia?['nome'] ??
                                                                            '-')
                                                                        : tipoAgendamento ==
                                                                            'E'
                                                                        ? (nomeEvento ??
                                                                            '-')
                                                                        : tipoAgendamento ==
                                                                            'M'
                                                                        ? (materia?['nome'] ??
                                                                            '-')
                                                                        : '-';

                                                                // Obter cor da sala para esta linha
                                                                final corLinha =
                                                                    locacao_functions.obterCorSala(
                                                                      coresPorSala,
                                                                      agendamento,
                                                                    );

                                                                return DataRow(
                                                                  color:
                                                                      corLinha !=
                                                                              null
                                                                          ? MaterialStateProperty.all(
                                                                            corLinha.withOpacity(
                                                                              0.15,
                                                                            ),
                                                                          )
                                                                          : null,
                                                                  cells: [
                                                                    DataCell(
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              8,
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              tipoColor,
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                        ),
                                                                        child: Text(
                                                                          tipoTexto,
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        dataFormatada,
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        agendamento['aula_periodo'] ??
                                                                            '',
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        salaLocal,
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        materiaEvento,
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        professor?['nome_professor'] ??
                                                                            '-',
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        periodoToString(
                                                                          curso['periodo'],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        horaInicio?.toString().substring(
                                                                              0,
                                                                              5,
                                                                            ) ??
                                                                            '',
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Text(
                                                                        horaFim?.toString().substring(
                                                                              0,
                                                                              5,
                                                                            ) ??
                                                                            '',
                                                                      ),
                                                                    ),
                                                                    DataCell(
                                                                      Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          IconButton(
                                                                            icon: const Icon(
                                                                              Icons.edit,
                                                                              color: Color(
                                                                                0xFF44A301,
                                                                              ),
                                                                            ),
                                                                            onPressed:
                                                                                () => editarAgendamento(
                                                                                  agendamento,
                                                                                ),
                                                                          ),
                                                                          IconButton(
                                                                            icon: const Icon(
                                                                              Icons.delete,
                                                                              color:
                                                                                  Colors.red,
                                                                            ),
                                                                            onPressed:
                                                                                () => excluirAgendamento(
                                                                                  agendamento['id'],
                                                                                ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              }).toList(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ];
                                        }),
                                      ],
                                    );
                                  },
                                ),
                                // Painel de filtro avançado sobreposto
                                if (mostrarFiltroAvancado)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      margin: const EdgeInsets.all(18),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF44A301),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Filtros Avançados',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF44A301),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  setState(() {
                                                    mostrarFiltroAvancado =
                                                        false;
                                                  });
                                                },
                                                color: Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Filtros em uma linha: Tipo, Turno e Turmas em conjunto
                                          Row(
                                            children: [
                                              // Filtro por tipo
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'Tipo:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    DropdownButtonFormField<
                                                      String
                                                    >(
                                                      value: filtroTipo,
                                                      isExpanded: true,
                                                      decoration: InputDecoration(
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      items: const [
                                                        DropdownMenuItem(
                                                          value: 'Todos',
                                                          child: Text('Todos'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Aulas',
                                                          child: Text('Aulas'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Eventos',
                                                          child: Text(
                                                            'Eventos',
                                                          ),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Provas',
                                                          child: Text('Provas'),
                                                        ),
                                                      ],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          filtroTipo = value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Filtro por turno
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'Turno:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    DropdownButtonFormField<
                                                      String
                                                    >(
                                                      value: filtroPeriodo,
                                                      isExpanded: true,
                                                      decoration: InputDecoration(
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      items: const [
                                                        DropdownMenuItem(
                                                          value: 'Todos',
                                                          child: Text('Todos'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Manhã',
                                                          child: Text('Manhã'),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Vespertino',
                                                          child: Text(
                                                            'Vespertino',
                                                          ),
                                                        ),
                                                        DropdownMenuItem(
                                                          value: 'Noturno',
                                                          child: Text(
                                                            'Noturno',
                                                          ),
                                                        ),
                                                      ],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          filtroPeriodo =
                                                              value!;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Botão para mostrar múltiplas turmas
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'Turmas em conjunto:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color:
                                                            mostrarMultiplasTurmas
                                                                ? const Color(
                                                                  0xFF44A301,
                                                                )
                                                                : Colors
                                                                    .grey[300],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: CheckboxListTile(
                                                        title: const Text(
                                                          'Ativar',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        value:
                                                            mostrarMultiplasTurmas,
                                                        activeColor:
                                                            Colors.white,
                                                        checkColor: const Color(
                                                          0xFF44A301,
                                                        ),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            mostrarMultiplasTurmas =
                                                                value ?? false;
                                                          });
                                                        },
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 0,
                                                            ),
                                                        dense: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Botão limpar filtros
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: const Icon(Icons.clear),
                                                label: const Text(
                                                  'Limpar Filtros',
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    pesquisaController.clear();
                                                    filtroTipo = 'Todos';
                                                    filtroPeriodo = 'Todos';
                                                    mostrarMultiplasTurmas =
                                                        false;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class Curso {
  final int id;
  final String curso;
  final int semestre;
  final int periodo;

  Curso({
    required this.id,
    required this.curso,
    required this.semestre,
    required this.periodo,
  });
}
