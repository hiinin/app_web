import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../functions/agendamento_helpers.dart';

class ListaLocacaoPage extends StatefulWidget {
  const ListaLocacaoPage({super.key});

  @override
  State<ListaLocacaoPage> createState() => _ListaLocacaoPageState();
}

// No início do _ListaLocacaoPageState
final TextEditingController pesquisaController = TextEditingController();
final TextEditingController pesquisaSalaController = TextEditingController();
String filtroCurso = '';
String filtroSala = '';

// Filtro para tipo de agendamento
String filtroTipo = 'Todos'; // 'Todos', 'Aulas', 'Eventos'

// Filtro para período
String filtroPeriodo = 'Todos'; // 'Todos', 'Manhã', 'Vespertino', 'Noturno'

@override
void dispose() {
  pesquisaController.dispose();
  pesquisaSalaController.dispose();
}

class _ListaLocacaoPageState extends State<ListaLocacaoPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  List<dynamic> agendamentos = [];

  DateTime diaSelecionado = DateTime.now();

  List<Map<String, dynamic>> cursos = [];
  int? cursoSelecionadoId;

  @override
  void initState() {
    super.initState();
    carregarAgendamentos(); // Adicione esta linha
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
      // final dados = response.data as List<dynamic>; // Removido: variável não utilizada
      // Atualize a lista com os dados obtidos, se necessário
    } else {
      print('Erro na busca: ${response.status}');
    }
  }

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

  Future<void> editarAgendamento(Map agendamento) async {
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

    // Listas para os dropdowns
    List<Map<String, dynamic>> salas = [];
    List<Map<String, dynamic>> cursos = [];
    List<Map<String, dynamic>> materias = [];
    List<Map<String, dynamic>> professores = [];

    try {
      // Carregar salas
      final salasResponse = await supabase
          .from('salas')
          .select('*')
          .order('numero_sala');
      salas = List<Map<String, dynamic>>.from(salasResponse);

      // Verificar se a sala selecionada existe na lista
      if (salaSelecionada != null &&
          !salas.any((s) => s['id'].toString() == salaSelecionada)) {
        salaSelecionada = null;
      }

      // Carregar cursos
      final cursosResponse = await supabase
          .from('cursos')
          .select('*')
          .order('curso');
      cursos = List<Map<String, dynamic>>.from(cursosResponse);

      // Verificar se o curso selecionado existe na lista
      if (cursoSelecionado != null &&
          !cursos.any((c) => c['id'].toString() == cursoSelecionado)) {
        cursoSelecionado = null;
        materiaSelecionada = null;
        professorSelecionado = null;
        materias = [];
        professores = [];
      }

      // Carregar matérias do curso atual (se houver)
      if (cursoSelecionado != null) {
        materias = await buscarMateriasPorCurso(
          supabase,
          int.parse(cursoSelecionado!),
        );
        // Verificar se a matéria selecionada ainda existe na nova lista
        if (materiaSelecionada != null &&
            !materias.any((m) => m['id'].toString() == materiaSelecionada)) {
          materiaSelecionada = null;
          professorSelecionado = null;
          professores = [];
        }
      }

      // Carregar professores da matéria atual (se houver)
      if (materiaSelecionada != null) {
        professores = await buscarProfessoresPorMateria(
          supabase,
          int.parse(materiaSelecionada!),
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
                                      materias = await buscarMateriasPorCurso(
                                        supabase,
                                        int.parse(value),
                                      );
                                      setState(() {});
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Dropdown Matéria
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
                                            ? 'Matéria'
                                            : 'Matéria (selecione um curso primeiro)',
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
                                              professores =
                                                  await buscarProfessoresPorMateria(
                                                    supabase,
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
                                            : 'Professor (selecione uma matéria primeiro)',
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

                                // Dropdown Período da Aula
                                DropdownButtonFormField<String>(
                                  value: aulaPeriodoOriginal,
                                  decoration: InputDecoration(
                                    labelText: 'Período da Aula',
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
        // Verificar conflitos
        final conflito = await verificarConflitos(
          result['sala_id'],
          result['curso_id'],
          result['materia_id'],
          result['professor_id'],
          result['data'],
          agendamento['id'], // Excluir o próprio agendamento da verificação
        );

        if (conflito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Conflito detectado! Esta sala/curso já está agendada para esta data.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Atualizar agendamento - os horários serão definidos automaticamente pelo trigger
        await supabase
            .from('agendamento')
            .update({
              'sala_id': result['sala_id'],
              'curso_id': result['curso_id'],
              'materia_id': result['materia_id'],
              'professor_id': result['professor_id'],
              'dia':
                  '${result['data'].year.toString().padLeft(4, '0')}-${result['data'].month.toString().padLeft(2, '0')}-${result['data'].day.toString().padLeft(2, '0')}',
              'aula_periodo': aulaPeriodoOriginal,
              // Os horários serão definidos automaticamente pelo trigger baseado no curso e período da aula
            })
            .eq('id', agendamento['id']);

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

  Future<bool> verificarConflitos(
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D5A1A), // Verde escuro
                    Color(0xFF44A301), // Verde médio
                  ],
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                    ), // Espaço à esquerda
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Campus Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bem-vindo!',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF44A301)),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF44A301)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Evento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarevento'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Color(0xFF44A301)),
              title: const Text(
                'Agendar Prova',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprova'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF44A301)),
              title: const Text(
                'Historico de Acoes',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/historicoacoes'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2025 RH Company',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
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
                          // Título para filtro por curso
                          const Text(
                            'Filtrar por curso:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Campo de pesquisa de curso
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF44A301),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: TextField(
                              controller: pesquisaController,
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar curso...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF44A301),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  filtroCurso = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Título para filtro por sala
                          const Text(
                            'Filtrar por sala:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Campo de pesquisa de sala
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF44A301),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: TextField(
                              controller: pesquisaSalaController,
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar sala...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: const Icon(
                                  Icons.meeting_room,
                                  color: Color(0xFF44A301),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  filtroSala = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Filtrar por tipo:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: filtroTipo,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
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
                                child: Text('Eventos'),
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
                          const SizedBox(height: 20),
                          const Text(
                            'Filtrar por período:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: filtroPeriodo,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
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
                                child: Text('Vespertino'),
                              ),
                              DropdownMenuItem(
                                value: 'Noturno',
                                child: Text('Noturno'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                filtroPeriodo = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Limpar Filtros'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                filtroCurso = '';
                                filtroSala = '';
                                filtroTipo = 'Todos';
                                filtroPeriodo = 'Todos';
                                pesquisaController.clear();
                                pesquisaSalaController.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_box, size: 16),
                                  label: const Text('Nova Aula'),
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
                          if (agendamentos.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Text(
                                'Cursos com agendamentos cadastrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF44A301),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView(
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
                                    if (periodoFiltrado != filtroPeriodo) {
                                      return <Widget>[];
                                    }
                                  }

                                  final Map<int, Map<String, dynamic>>
                                  cursosUnicos = {};
                                  for (final ag in agendamentos) {
                                    final curso = ag['cursos'];
                                    if (curso != null &&
                                        curso['periodo'] == periodo) {
                                      cursosUnicos[curso['id']] = curso;
                                    }
                                  }
                                  if (cursosUnicos.isEmpty) return <Widget>[];

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
                                      padding: const EdgeInsets.symmetric(
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
                                    ...cursosUnicos.values
                                        .where(
                                          (curso) =>
                                              filtroCurso.isEmpty ||
                                              (curso['curso'] ?? '')
                                                  .toLowerCase()
                                                  .contains(filtroCurso),
                                        )
                                        .where((curso) {
                                          // Verifica se o curso tem agendamentos do tipo filtrado
                                          final agsDoCursoFiltrados =
                                              agendamentos
                                                  .where(
                                                    (ag) =>
                                                        ag['cursos']?['id'] ==
                                                            curso['id'] &&
                                                        (filtroTipo ==
                                                                'Todos' ||
                                                            (filtroTipo ==
                                                                    'Aulas' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'A') ||
                                                            (filtroTipo ==
                                                                    'Eventos' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'E') ||
                                                            (filtroTipo ==
                                                                    'Provas' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'M')) &&
                                                        (filtroSala.isEmpty ||
                                                            (ag['salas']?['numero_sala']
                                                                        ?.toString() ??
                                                                    '')
                                                                .toLowerCase()
                                                                .contains(
                                                                  filtroSala,
                                                                )),
                                                  )
                                                  .toList();

                                          return agsDoCursoFiltrados.isNotEmpty;
                                        })
                                        .map((curso) {
                                          final agsDoCurso =
                                              agendamentos
                                                  .where(
                                                    (ag) =>
                                                        ag['cursos']?['id'] ==
                                                            curso['id'] &&
                                                        (filtroTipo ==
                                                                'Todos' ||
                                                            (filtroTipo ==
                                                                    'Aulas' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'A') ||
                                                            (filtroTipo ==
                                                                    'Eventos' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'E') ||
                                                            (filtroTipo ==
                                                                    'Provas' &&
                                                                ag['tipo_agendamento'] ==
                                                                    'M')) &&
                                                        (filtroSala.isEmpty ||
                                                            (ag['salas']?['numero_sala']
                                                                        ?.toString() ??
                                                                    '')
                                                                .toLowerCase()
                                                                .contains(
                                                                  filtroSala,
                                                                )),
                                                  )
                                                  .toList();

                                          final Set<String> chavesUnicas = {};
                                          final List<dynamic> agsUnicos = [];
                                          for (final ag in agsDoCurso) {
                                            final chave =
                                                '${ag['sala_id']}_${ag['curso_id']}_${ag['dia']}_${ag['periodo']}_${ag['aula_periodo']}';
                                            if (!chavesUnicas.contains(chave)) {
                                              chavesUnicas.add(chave);
                                              agsUnicos.add(ag);
                                            }
                                          }
                                          return Card(
                                            elevation: 6,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: ExpansionTile(
                                              tilePadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              title: Text(
                                                curso['curso'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFF44A301),
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Semestre: ${curso['semestre'] ?? '-'}',
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
                                                        label: Text('Tipo'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Data'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Aula'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Sala'),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          'Matéria/Evento',
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text(
                                                          'Professor',
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Período'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Início'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Fim'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Ações'),
                                                      ),
                                                    ],
                                                    rows:
                                                        agsUnicos.map<DataRow>((
                                                          agendamento,
                                                        ) {
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
                                                                  ? Colors.red
                                                                  : Colors.grey;

                                                          // Determina sala
                                                          final salaLocal =
                                                              sala?['numero_sala']
                                                                  ?.toString() ??
                                                              '-';

                                                          // Determina matéria/evento
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
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        tipoColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                  ),
                                                                  child: Text(
                                                                    tipoTexto,
                                                                    style: const TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
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
                                                                Text(salaLocal),
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
                                                                  horaInicio
                                                                          ?.toString()
                                                                          .substring(
                                                                            0,
                                                                            5,
                                                                          ) ??
                                                                      '',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  horaFim
                                                                          ?.toString()
                                                                          .substring(
                                                                            0,
                                                                            5,
                                                                          ) ??
                                                                      '',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .edit,
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
                                                                        Icons
                                                                            .delete,
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
                                        })
                                        .toList(),
                                  ];
                                }),
                                if (agendamentos.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Column(
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
