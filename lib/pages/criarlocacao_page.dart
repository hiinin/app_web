import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;
import '../functions/criarlocacao_functions.dart';
import '../functions/drawer_helper.dart';

class CriarLocacaoPage extends StatefulWidget {
  const CriarLocacaoPage({super.key});

  @override
  State<CriarLocacaoPage> createState() => _CriarLocacaoPageState();
}

class _CriarLocacaoPageState extends State<CriarLocacaoPage> {
  final CriarLocacaoFunctions functions = CriarLocacaoFunctions();
  final supabase = Supabase.instance.client;

  List<sala_model.Sala> salas = [];
  List<curso_model.Curso> cursos = [];
  List<Map<String, dynamic>> materias = [];
  List<Map<String, dynamic>> professores = [];
  sala_model.Sala? salaSelecionada;
  curso_model.Curso? cursoSelecionado;
  Map<String, dynamic>? materiaSelecionada;
  Map<String, dynamic>? professorSelecionado;

  // NOVO: Lista de salas filtradas baseada nos critérios
  List<Map<String, dynamic>> salasFiltradas = [];
  bool isLoadingSalas = false;

  // NOVO: Lista para múltiplos cursos
  List<curso_model.Curso> cursosSelecionados = [];

  // NOVO: Estrutura para armazenar matéria e professor por curso
  Map<int, Map<String, dynamic>?> materiasPorCurso = {};
  Map<int, Map<String, dynamic>?> professoresPorCurso = {};
  Map<int, List<Map<String, dynamic>>> materiasDisponiveisPorCurso = {};
  Map<int, List<Map<String, dynamic>>> professoresDisponiveisPorCurso = {};

  // NOVO: Map para armazenar quantidade de agendamentos por curso no dia selecionado
  // Estrutura: { cursoId: { 'periodo_selecionado': count, 'total_dia': count, 'periodos_com_agendamento': List<String> } }
  Map<int, Map<String, dynamic>> agendamentosPorCurso = {};

  bool isLoading = false;

  DateTime? dia;
  DateTime? mesAtual; // NOVO: Variável para controlar o mês atual do calendário
  TimeOfDay? horaSelecionada;
  Set<String> periodosAulaSelecionados =
      {}; // NOVO: Set para permitir múltiplas seleções

  TimeOfDay? horaInicio;
  TimeOfDay? horaFim;

  // Controles para pesquisa nos dropdowns
  bool isSalaDropdownOpen = false;
  bool isCursoDropdownOpen = false;
  bool isMateriaDropdownOpen = false;
  bool isProfessorDropdownOpen = false;
  String salaSearchText = '';
  String cursoSearchText = '';
  String materiaSearchText = '';
  String professorSearchText = '';

  // Controllers para campos de pesquisa
  final TextEditingController cursoSearchController = TextEditingController();

  // Campo de observação
  final TextEditingController observacaoController = TextEditingController();

  // NOVO: Controles para dropdowns de matéria e professor por curso
  Map<String, bool> dropdownsAbertos = {};
  Map<String, String> textosPesquisa = {};

  // Overlay entries para dropdowns
  OverlayEntry? _overlayEntry;

  // GlobalKeys para posicionamento dos dropdowns
  final GlobalKey _cursoFieldKey = GlobalKey();
  final GlobalKey _materiaFieldKey = GlobalKey();
  final GlobalKey _professorFieldKey = GlobalKey();
  final GlobalKey _salaFieldKey = GlobalKey();

  // Novo: controle de modo do calendário
  bool modoMultiplo = false;
  Set<DateTime> diasMultiplosSelecionados = {};

  final List<String> periodosAula = ['Matutino', 'Vespertino', 'Noturno'];

  @override
  void initState() {
    super.initState();
    print('DEBUG: Página de locação carregada - TESTE DE MUDANÇAS');
    // Inicializa o mês atual com o mês atual
    mesAtual = DateTime.now();
    carregarDados();
  }

  @override
  void dispose() {
    // Fechar todos os dropdowns ao sair da tela
    print('DEBUG: Fechando dropdowns ao sair da tela');
    isCursoDropdownOpen = false;
    isSalaDropdownOpen = false;
    isMateriaDropdownOpen = false;
    isProfessorDropdownOpen = false;
    dropdownsAbertos.clear(); // Limpar todos os dropdowns (incluindo aula)
    textosPesquisa.clear();

    // Dispose dos controllers
    cursoSearchController.dispose();
    observacaoController.dispose();

    // Fechar overlay
    _overlayEntry?.remove();
    _overlayEntry = null;

    super.dispose();
  }

  Future<void> carregarDados() async {
    setState(() => isLoading = true);
    try {
      final dados = await functions.carregarDados();
      setState(() {
        salas = dados['salas'] as List<sala_model.Sala>;
        cursos = dados['cursos'] as List<curso_model.Curso>;
        professores = dados['professores'] as List<Map<String, dynamic>>;
        cursosSelecionados.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> carregarMateriasPorCurso(int cursoId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final materias = await functions.carregarMateriasPorCurso(cursoId);
      setState(() {
        materiasDisponiveisPorCurso[cursoId] = materias;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar matérias: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> carregarProfessoresPorTurma(int cursoId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final professores = await functions.carregarProfessoresPorTurma(cursoId);
      setState(() {
        professoresDisponiveisPorCurso[cursoId] = professores;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar professores: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // NOVO: Função para carregar agendamentos por curso no dia selecionado
  Future<void> carregarAgendamentosCursos(DateTime? diaSelecionado) async {
    if (diaSelecionado == null || periodosAulaSelecionados.isEmpty) {
      setState(() {
        agendamentosPorCurso.clear();
      });
      return;
    }

    try {
      final agendamentos = await functions.verificarAgendamentosCursosPorDia(
        diaSelecionado,
        periodosAulaSelecionados,
      );
      setState(() {
        agendamentosPorCurso = agendamentos;
      });
    } catch (e) {
      print('Erro ao carregar agendamentos por curso: $e');
      setState(() {
        agendamentosPorCurso.clear();
      });
    }
  }

  // NOVO: Função para obter lista de cursos ordenada
  // Ordem: cursos não bloqueados (verde) -> cursos bloqueados em cinza -> cursos bloqueados em vermelho (por último)
  List<curso_model.Curso> getCursosOrdenados(
    List<curso_model.Curso> cursosLista,
  ) {
    final cursosOrdenados = List<curso_model.Curso>.from(cursosLista);

    // Função auxiliar para obter o status do curso
    // Retorna: 0 = verde (não bloqueado), 1 = cinza (bloqueado), 2 = vermelho (2 agendamentos)
    int getStatusCurso(curso_model.Curso curso) {
      final infoAgendamentos = agendamentosPorCurso[curso.id];
      final totalDia = (infoAgendamentos?['total_dia'] as int?) ?? 0;
      final agendamentosPeriodo =
          (infoAgendamentos?['periodo_selecionado'] as int?) ?? 0;
      final periodosComAgendamento =
          (infoAgendamentos?['periodos_com_agendamento'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      final ambosPeriodosSelecionados = periodosAulaSelecionados.length == 2;
      final temAgendamentoNoPeriodoSelecionado = agendamentosPeriodo > 0;
      final temAgendamentoEmAlgumPeriodo = periodosComAgendamento.isNotEmpty;

      // Verifica se o período selecionado já tem agendamento
      final periodoSelecionadoTemAgendamento =
          ambosPeriodosSelecionados
              ? temAgendamentoEmAlgumPeriodo
              : temAgendamentoNoPeriodoSelecionado;

      // Retorna 2 (vermelho) se tem 2 agendamentos no dia
      if (totalDia >= 2) {
        return 2;
      }

      // Retorna 1 (cinza) se já tem agendamento no período selecionado
      if (periodoSelecionadoTemAgendamento) {
        return 1;
      }

      // Retorna 0 (verde) se não está bloqueado
      return 0;
    }

    // Ordena: cursos verdes primeiro, depois cinzas, depois vermelhos por último
    cursosOrdenados.sort((a, b) {
      final statusA = getStatusCurso(a);
      final statusB = getStatusCurso(b);

      // Se ambos têm o mesmo status, mantém ordem alfabética
      if (statusA == statusB) {
        return a.curso.toLowerCase().compareTo(b.curso.toLowerCase());
      }

      // Ordena por status: 0 (verde) < 1 (cinza) < 2 (vermelho)
      return statusA.compareTo(statusB);
    });

    return cursosOrdenados;
  }

  // NOVO: Adicionar curso à lista de selecionados
  void adicionarCurso(curso_model.Curso curso) {
    final infoAgendamentos = agendamentosPorCurso[curso.id];
    final totalDia = (infoAgendamentos?['total_dia'] as int?) ?? 0;
    final periodosComAgendamento =
        (infoAgendamentos?['periodos_com_agendamento'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    final ambosPeriodosSelecionados = periodosAulaSelecionados.length == 2;
    final temAgendamentoEmAlgumPeriodo = periodosComAgendamento.isNotEmpty;

    // Verifica se pode adicionar o curso
    if (totalDia >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'O curso "${curso.curso}" já possui 2 agendamentos no dia selecionado e não pode ser adicionado.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Verifica se o período selecionado já tem agendamento
    final agendamentosPeriodo =
        (infoAgendamentos?['periodo_selecionado'] as int?) ?? 0;
    final temAgendamentoNoPeriodoSelecionado = agendamentosPeriodo > 0;

    final periodoSelecionadoTemAgendamento =
        ambosPeriodosSelecionados
            ? temAgendamentoEmAlgumPeriodo
            : temAgendamentoNoPeriodoSelecionado;

    if (periodoSelecionadoTemAgendamento) {
      final horariosFormatados = periodosComAgendamento
          .map((p) => p == 'Primeira Aula' ? 'Primeira Aula' : 'Segunda Aula')
          .join(' e ');

      String mensagem;
      if (ambosPeriodosSelecionados) {
        mensagem =
            'Não é possível fazer agendamento para os dois horários pois já tem agendamento para $horariosFormatados.';
      } else {
        mensagem =
            'Não é possível fazer agendamento pois já tem agendamento para $horariosFormatados.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!cursosSelecionados.any((c) => c.id == curso.id)) {
      setState(() {
        cursosSelecionados.add(curso);
        // Inicializa as seleções para este curso
        materiasPorCurso[curso.id] = null;
        professoresPorCurso[curso.id] = null;
      });
      // Carrega as matérias e professores para este curso específico
      carregarMateriasPorCurso(curso.id);
      carregarProfessoresPorTurma(curso.id);
      // Limpa a sala selecionada quando adiciona um novo curso
      salaSelecionada = null;
      salasFiltradas.clear();
    }
  }

  // NOVO: Remover curso da lista de selecionados
  void removerCurso(int cursoId) {
    print('DEBUG: Removendo curso ID: $cursoId');
    print('DEBUG: Cursos antes da remoção: ${cursosSelecionados.length}');

    setState(() {
      cursosSelecionados.removeWhere((c) => c.id == cursoId);
      // Remove os dados do curso
      materiasPorCurso.remove(cursoId);
      professoresPorCurso.remove(cursoId);
      materiasDisponiveisPorCurso.remove(cursoId);
      professoresDisponiveisPorCurso.remove(cursoId);
      dropdownsAbertos.remove('materia_$cursoId');
      dropdownsAbertos.remove('professor_$cursoId');
      textosPesquisa.remove('materia_$cursoId');
      textosPesquisa.remove('professor_$cursoId');
      // Limpa a sala selecionada quando remove um curso
      salaSelecionada = null;
      salasFiltradas.clear();
    });

    print('DEBUG: Cursos após a remoção: ${cursosSelecionados.length}');
    print(
      'DEBUG: _podeSelecionarSala() após remoção: ${_podeSelecionarSala()}',
    );

    // Verifica se ainda é possível filtrar salas após remover o curso
    if (cursosSelecionados.isNotEmpty && _podeSelecionarSala()) {
      print('DEBUG: Chamando filtrarSalas() após remoção do curso');
      filtrarSalas();
    } else {
      print('DEBUG: Não foi possível filtrar salas após remoção do curso');
    }
  }

  // NOVO: Widget para exibir cursos selecionados
  Widget _buildCursosSelecionados() {
    if (cursosSelecionados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF44A301).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF44A301).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Color(0xFF44A301), size: 20),
              const SizedBox(width: 8),
              Text(
                'Turmas Selecionadas (${cursosSelecionados.length})',
                style: const TextStyle(
                  color: Color(0xFF44A301),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...cursosSelecionados.map((curso) => _buildCursoItem(curso)),
        ],
      ),
    );
  }

  // NOVO: Widget para exibir item de curso selecionado
  Widget _buildCursoItem(curso_model.Curso curso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF44A301).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          curso.curso,
                          style: const TextStyle(
                            color: Color(0xFF44A301),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Indicador de status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (materiasPorCurso[curso.id] != null &&
                                        professoresPorCurso[curso.id] != null)
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  (materiasPorCurso[curso.id] != null &&
                                          professoresPorCurso[curso.id] != null)
                                      ? Colors.green
                                      : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            (materiasPorCurso[curso.id] != null &&
                                    professoresPorCurso[curso.id] != null)
                                ? '✓ Completo'
                                : '⚠ Pendente',
                            style: TextStyle(
                              color:
                                  (materiasPorCurso[curso.id] != null &&
                                          professoresPorCurso[curso.id] != null)
                                      ? Colors.green
                                      : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Semestre: ${curso.semestre ?? "Não informado"} - Turno: ${periodoToString(curso.periodo)}',
                      style: const TextStyle(
                        color: Color(0xFF44A301),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => removerCurso(curso.id),
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Campo de matéria para este curso
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown<Map<String, dynamic>>(
                  value: materiasPorCurso[curso.id],
                  labelText: 'Selecione a Disciplina',
                  items:
                      _podeSelecionarMateria(curso.id)
                          ? (materiasDisponiveisPorCurso[curso.id] ?? [])
                          : [],
                  displayText: (materia) => materia['nome'] ?? '',
                  onChanged:
                      _podeSelecionarMateria(curso.id)
                          ? (value) {
                            setState(() {
                              materiasPorCurso[curso.id] = value;
                            });
                            // Limpa a sala selecionada quando muda matéria
                            salaSelecionada = null;
                            salasFiltradas.clear();
                          }
                          : (Map<String, dynamic>? value) {},
                  validator:
                      (value) => value == null ? 'Selecione uma matéria' : null,
                  fieldKey: GlobalKey(),
                  dropdownId: 'materia_${curso.id}',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color:
                      _podeSelecionarMateria(curso.id)
                          ? const Color(0xFF44A301)
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed:
                      _podeSelecionarMateria(curso.id)
                          ? () => Navigator.pushNamed(context, '/criarmateria')
                          : null,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Criar nova matéria',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Campo de professor para este curso (turma)
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown<Map<String, dynamic>>(
                  value: professoresPorCurso[curso.id],
                  labelText: 'Selecione o Professor',
                  items:
                      _podeSelecionarProfessor(curso.id)
                          ? (professoresDisponiveisPorCurso[curso.id] ?? [])
                          : [],
                  displayText: (professor) => professor['nome_professor'] ?? '',
                  onChanged:
                      _podeSelecionarProfessor(curso.id)
                          ? (value) {
                            setState(() {
                              professoresPorCurso[curso.id] = value;
                            });
                            // Verifica se todos os cursos estão completos e filtra as salas
                            if (value != null) {
                              bool todosCompletos = true;
                              for (final cursoSelecionado
                                  in cursosSelecionados) {
                                if (materiasPorCurso[cursoSelecionado.id] ==
                                        null ||
                                    professoresPorCurso[cursoSelecionado.id] ==
                                        null) {
                                  todosCompletos = false;
                                  break;
                                }
                              }
                              if (todosCompletos &&
                                  periodosAulaSelecionados.isNotEmpty &&
                                  (modoMultiplo
                                      ? diasMultiplosSelecionados.isNotEmpty
                                      : dia != null)) {
                                filtrarSalas();
                              }
                            }
                          }
                          : (Map<String, dynamic>? value) {},
                  validator:
                      (value) =>
                          value == null ? 'Selecione um professor' : null,
                  fieldKey: GlobalKey(),
                  dropdownId: 'professor_${curso.id}',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color:
                      _podeSelecionarProfessor(curso.id)
                          ? const Color(0xFF44A301)
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed:
                      _podeSelecionarProfessor(curso.id)
                          ? () =>
                              Navigator.pushNamed(context, '/criarprofessor')
                          : null,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Criar novo professor',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown<T>({
    required T? value,
    required String labelText,
    required List<T> items,
    required String Function(T) displayText,
    required Function(T?) onChanged,
    required String? Function(T?) validator,
    required GlobalKey fieldKey,
    String? dropdownId, // NOVO: ID único para cada dropdown
  }) {
    bool isOpen = false;
    String searchText = '';

    if (T == sala_model.Sala) {
      isOpen = isSalaDropdownOpen;
      searchText = salaSearchText;
    } else if (T == curso_model.Curso) {
      isOpen = isCursoDropdownOpen;
      searchText = cursoSearchText;
    } else if (T == Map<String, dynamic>) {
      // NOVO: Usa o ID do dropdown para controle individual
      if (dropdownId != null) {
        isOpen = dropdownsAbertos[dropdownId] ?? false;
        searchText = textosPesquisa[dropdownId] ?? '';
      } else {
        // Fallback para campos globais
        if (fieldKey == _salaFieldKey) {
          isOpen = isSalaDropdownOpen;
          searchText = salaSearchText;
        } else if (fieldKey == _materiaFieldKey) {
          isOpen = isMateriaDropdownOpen;
          searchText = materiaSearchText;
        } else if (fieldKey == _professorFieldKey) {
          isOpen = isProfessorDropdownOpen;
          searchText = professorSearchText;
        }
      }
    }

    // NOVO: Determina se o dropdown está habilitado baseado no tipo
    bool isEnabled = true;
    if (T == curso_model.Curso) {
      isEnabled = _podeSelecionarCurso();
    } else if (T == Map<String, dynamic>) {
      if (dropdownId != null) {
        if (dropdownId.startsWith('materia_')) {
          int cursoId = int.parse(dropdownId.split('_')[1]);
          isEnabled = _podeSelecionarMateria(cursoId);
        } else if (dropdownId.startsWith('professor_')) {
          int cursoId = int.parse(dropdownId.split('_')[1]);
          isEnabled = _podeSelecionarProfessor(cursoId);
        }
      }
    }

    List<T> filteredItems =
        items.where((item) {
          return displayText(
            item,
          ).toLowerCase().contains(searchText.toLowerCase());
        }).toList();

    void _showOverlay() {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
      }

      // Verifica se é o campo de matéria ou professor
      bool isMateriaField = fieldKey == _materiaFieldKey;
      bool isProfessorField = fieldKey == _professorFieldKey;

      // Calcula a posição baseada no campo
      double topPosition = 100;
      double leftPosition = 50;
      double width = 300;

      if (fieldKey.currentContext != null) {
        final renderBox =
            fieldKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        topPosition = position.dy + 60;
        leftPosition = position.dx;
        width = size.width;

        // Se for o campo de matéria ou professor e não houver espaço suficiente abaixo, posiciona acima
        if (isMateriaField || isProfessorField) {
          final screenHeight = MediaQuery.of(context).size.height;
          final availableSpaceBelow = screenHeight - topPosition;
          if (availableSpaceBelow < 400) {
            // Se não há espaço suficiente para a lista
            topPosition = position.dy - 350; // Posiciona acima do campo
          }
        }
      }

      _overlayEntry = OverlayEntry(
        builder:
            (context) => Stack(
              children: [
                // GestureDetector que cobre toda a tela para detectar cliques fora
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      // Fecha o dropdown quando clica fora
                      setState(() {
                        if (T == sala_model.Sala) {
                          isSalaDropdownOpen = false;
                          salaSearchText = '';
                        } else if (T == curso_model.Curso) {
                          isCursoDropdownOpen = false;
                          cursoSearchText = '';
                          cursoSearchController.clear();
                        } else if (T == Map<String, dynamic>) {
                          // NOVO: Controle individual para dropdowns
                          if (dropdownId != null) {
                            dropdownsAbertos[dropdownId] = false;
                            textosPesquisa[dropdownId] = '';
                          } else {
                            // Fallback para campos globais
                            if (fieldKey == _salaFieldKey) {
                              isSalaDropdownOpen = false;
                              salaSearchText = '';
                            } else if (fieldKey == _materiaFieldKey) {
                              isMateriaDropdownOpen = false;
                              materiaSearchText = '';
                            } else if (fieldKey == _professorFieldKey) {
                              isProfessorDropdownOpen = false;
                              professorSearchText = '';
                            }
                          }
                        }
                      });
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Dropdown posicionado
                Positioned(
                  top: topPosition,
                  left: leftPosition,
                  width: width,
                  child: Material(
                    elevation: 20,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF44A301),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];

                          // Se for uma sala (Map com 'sala_id'), mostra o indicador visual
                          Widget titleWidget;
                          bool isSala = fieldKey == _salaFieldKey;
                          bool isCurso =
                              fieldKey == _cursoFieldKey &&
                              T == curso_model.Curso;

                          if (isSala ||
                              (item is Map<String, dynamic> &&
                                  (item as Map<String, dynamic>).containsKey(
                                    'sala_id',
                                  ))) {
                            final sala = item as Map<String, dynamic>;
                            final agendamentos =
                                sala['agendamentos_existentes'] ?? 0;
                            final disponivel = sala['disponivel'] ?? true;

                            IconData statusIcon;
                            String status;
                            Color textColor;
                            Color iconColor;

                            if (!disponivel) {
                              statusIcon = Icons.cancel;
                              status = 'Indisponível';
                              textColor = Colors.red;
                              iconColor = Colors.red;
                            } else if (agendamentos > 0) {
                              statusIcon = Icons.warning;
                              status = '$agendamentos agendamento(s)';
                              textColor = const Color(0xFF44A301);
                              iconColor = Colors.orange;
                            } else {
                              statusIcon = Icons.check_circle;
                              status = 'Livre';
                              textColor = const Color(0xFF44A301);
                              iconColor = Colors.green;
                            }

                            titleWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 18,
                                      color: iconColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Sala ${sala['numero_sala']}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${sala['qtd_cadeiras']} Carteiras - $status',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          } else if (isCurso && item is curso_model.Curso) {
                            // Lógica de cores baseada nos agendamentos e períodos selecionados
                            final curso = item as curso_model.Curso;
                            final infoAgendamentos =
                                agendamentosPorCurso[curso.id];
                            final agendamentosPeriodo =
                                (infoAgendamentos?['periodo_selecionado']
                                    as int?) ??
                                0;
                            final totalDia =
                                (infoAgendamentos?['total_dia'] as int?) ?? 0;
                            final periodosComAgendamento =
                                (infoAgendamentos?['periodos_com_agendamento']
                                        as List<dynamic>?)
                                    ?.cast<String>() ??
                                [];

                            final ambosPeriodosSelecionados =
                                periodosAulaSelecionados.length == 2;
                            final temAgendamentoNoPeriodoSelecionado =
                                agendamentosPeriodo > 0;
                            final tem2AgendamentosDia = totalDia >= 2;
                            final temAgendamentoEmAlgumPeriodo =
                                periodosComAgendamento.isNotEmpty;

                            // Verifica se o período selecionado já tem agendamento
                            // Se apenas um período está selecionado, verifica se ele tem agendamento
                            // Se ambos estão selecionados, verifica se algum tem agendamento
                            final periodoSelecionadoTemAgendamento =
                                ambosPeriodosSelecionados
                                    ? temAgendamentoEmAlgumPeriodo
                                    : temAgendamentoNoPeriodoSelecionado;

                            // Cor do texto e indicador
                            Color? corTexto;
                            Color? corIndicador;
                            String? mensagemAviso;

                            if (tem2AgendamentosDia) {
                              // Vermelho: já tem 2 agendamentos no dia
                              corTexto = Colors.red[700];
                              corIndicador = Colors.red;
                            } else if (periodoSelecionadoTemAgendamento) {
                              // Cinza: já tem agendamento no período selecionado
                              corTexto = Colors.grey[700];
                              corIndicador = Colors.grey;
                              // Monta mensagem com os horários que já têm agendamento
                              final horariosFormatados = periodosComAgendamento
                                  .map(
                                    (p) =>
                                        p == 'Primeira Aula'
                                            ? 'Primeira Aula'
                                            : 'Segunda Aula',
                                  )
                                  .join(' e ');
                              mensagemAviso =
                                  'Já tem agendamento para $horariosFormatados';
                            } else {
                              corTexto = const Color(0xFF44A301);
                              corIndicador = null;
                            }

                            titleWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (corIndicador != null) ...[
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: corIndicador,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        displayText(item),
                                        style: TextStyle(
                                          color: corTexto,
                                          fontSize: 16,
                                          fontWeight:
                                              (periodoSelecionadoTemAgendamento ||
                                                      tem2AgendamentosDia)
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (mensagemAviso != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    mensagemAviso,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          } else {
                            titleWidget = Text(
                              displayText(item),
                              style: const TextStyle(
                                color: Color(0xFF44A301),
                                fontSize: 16,
                              ),
                            );
                          }

                          // Verifica se é curso e se pode selecionar
                          // Bloqueia se: tem 2 agendamentos no dia OU já tem agendamento no período selecionado
                          bool podeSelecionar = true;
                          if (isCurso && item is curso_model.Curso) {
                            final curso = item as curso_model.Curso;
                            final infoAgendamentos =
                                agendamentosPorCurso[curso.id];
                            final totalDia =
                                (infoAgendamentos?['total_dia'] as int?) ?? 0;
                            final agendamentosPeriodo =
                                (infoAgendamentos?['periodo_selecionado']
                                    as int?) ??
                                0;
                            final periodosComAgendamento =
                                (infoAgendamentos?['periodos_com_agendamento']
                                        as List<dynamic>?)
                                    ?.cast<String>() ??
                                [];

                            final ambosPeriodosSelecionados =
                                periodosAulaSelecionados.length == 2;
                            final temAgendamentoNoPeriodoSelecionado =
                                agendamentosPeriodo > 0;
                            final temAgendamentoEmAlgumPeriodo =
                                periodosComAgendamento.isNotEmpty;

                            // Verifica se o período selecionado já tem agendamento
                            final periodoSelecionadoTemAgendamento =
                                ambosPeriodosSelecionados
                                    ? temAgendamentoEmAlgumPeriodo
                                    : temAgendamentoNoPeriodoSelecionado;

                            // Bloqueia se tem 2 agendamentos no dia OU se já tem agendamento no período selecionado
                            podeSelecionar =
                                totalDia < 2 &&
                                !periodoSelecionadoTemAgendamento;
                          }

                          return ListTile(
                            title: titleWidget,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            enabled: podeSelecionar,
                            onTap:
                                podeSelecionar
                                    ? () {
                                      onChanged(item);
                                      setState(() {
                                        if (T == sala_model.Sala) {
                                          isSalaDropdownOpen = false;
                                          salaSearchText = '';
                                        } else if (T == curso_model.Curso) {
                                          isCursoDropdownOpen = false;
                                          cursoSearchText = '';
                                          cursoSearchController.clear();
                                        } else if (T == Map<String, dynamic>) {
                                          // NOVO: Controle individual para dropdowns
                                          if (dropdownId != null) {
                                            dropdownsAbertos[dropdownId] =
                                                false;
                                            textosPesquisa[dropdownId] = '';
                                          } else {
                                            // Fallback para campos globais
                                            if (fieldKey == _salaFieldKey) {
                                              isSalaDropdownOpen = false;
                                              salaSearchText = '';
                                            } else if (fieldKey ==
                                                _materiaFieldKey) {
                                              isMateriaDropdownOpen = false;
                                              materiaSearchText = '';
                                            } else if (fieldKey ==
                                                _professorFieldKey) {
                                              isProfessorDropdownOpen = false;
                                              professorSearchText = '';
                                            }
                                          }
                                        }
                                      });
                                      _overlayEntry?.remove();
                                      _overlayEntry = null;
                                    }
                                    : null,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    }

    void _hideOverlay() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    return GestureDetector(
      key: fieldKey,
      onTap:
          isEnabled
              ? () {
                setState(() {
                  if (T == sala_model.Sala) {
                    isSalaDropdownOpen = !isSalaDropdownOpen;
                    if (!isSalaDropdownOpen) {
                      salaSearchText = '';
                      _hideOverlay();
                    } else {
                      _showOverlay();
                    }
                  } else if (T == curso_model.Curso) {
                    isCursoDropdownOpen = !isCursoDropdownOpen;
                    if (!isCursoDropdownOpen) {
                      cursoSearchText = '';
                      cursoSearchController.clear();
                      _hideOverlay();
                    } else {
                      _showOverlay();
                    }
                  } else if (T == Map<String, dynamic>) {
                    // NOVO: Controle individual para dropdowns de matéria e professor
                    if (dropdownId != null) {
                      dropdownsAbertos[dropdownId] =
                          !(dropdownsAbertos[dropdownId] ?? false);
                      if (!(dropdownsAbertos[dropdownId] ?? false)) {
                        textosPesquisa[dropdownId] = '';
                        _hideOverlay();
                      } else {
                        _showOverlay();
                      }
                    } else {
                      // Fallback para campos globais
                      if (fieldKey == _salaFieldKey) {
                        isSalaDropdownOpen = !isSalaDropdownOpen;
                        if (!isSalaDropdownOpen) {
                          salaSearchText = '';
                          _hideOverlay();
                        } else {
                          _showOverlay();
                        }
                      } else if (fieldKey == _materiaFieldKey) {
                        isMateriaDropdownOpen = !isMateriaDropdownOpen;
                        if (!isMateriaDropdownOpen) {
                          materiaSearchText = '';
                          _hideOverlay();
                        } else {
                          _showOverlay();
                        }
                      } else if (fieldKey == _professorFieldKey) {
                        isProfessorDropdownOpen = !isProfessorDropdownOpen;
                        if (!isProfessorDropdownOpen) {
                          professorSearchText = '';
                          _hideOverlay();
                        } else {
                          _showOverlay();
                        }
                      }
                    }
                  }
                });
              }
              : null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color:
              isEnabled
                  ? const Color(0xFF44A301).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? const Color(0xFF44A301) : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  isOpen
                      ? Builder(
                        builder: (context) {
                          // Usa controller para cursos, texto direto para outros
                          if (T == curso_model.Curso) {
                            // Sincroniza o controller com o estado
                            if (cursoSearchController.text != cursoSearchText) {
                              cursoSearchController.text = cursoSearchText;
                              cursoSearchController
                                  .selection = TextSelection.collapsed(
                                offset: cursoSearchText.length,
                              );
                            }
                            return TextField(
                              controller: cursoSearchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Pesquisar...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color:
                                    isEnabled
                                        ? const Color(0xFF44A301)
                                        : Colors.grey,
                                fontSize: 16,
                              ),
                              onChanged: (text) {
                                setState(() {
                                  cursoSearchText = text;
                                });
                                // Atualiza o overlay com a nova filtragem
                                if (isOpen) {
                                  _showOverlay();
                                }
                              },
                            );
                          } else {
                            return TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Pesquisar...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                color:
                                    isEnabled
                                        ? const Color(0xFF44A301)
                                        : Colors.grey,
                                fontSize: 16,
                              ),
                              onChanged: (text) {
                                setState(() {
                                  if (T == sala_model.Sala) {
                                    salaSearchText = text;
                                  } else if (T == Map<String, dynamic>) {
                                    // NOVO: Controle individual para dropdowns
                                    if (dropdownId != null) {
                                      textosPesquisa[dropdownId] = text;
                                    } else {
                                      // Fallback para campos globais
                                      if (fieldKey == _salaFieldKey) {
                                        salaSearchText = text;
                                      } else if (fieldKey == _materiaFieldKey) {
                                        materiaSearchText = text;
                                      } else if (fieldKey ==
                                          _professorFieldKey) {
                                        professorSearchText = text;
                                      }
                                    }
                                  }
                                });
                                // Atualiza o overlay com a nova filtragem
                                if (isOpen) {
                                  _showOverlay();
                                }
                              },
                            );
                          }
                        },
                      )
                      : Text(
                        value != null ? displayText(value) : labelText,
                        style: TextStyle(
                          color:
                              isEnabled
                                  ? (value != null
                                      ? const Color(0xFF44A301)
                                      : const Color(
                                        0xFF44A301,
                                      ).withOpacity(0.6))
                                  : Colors.grey.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isEnabled ? const Color(0xFF44A301) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Widget para seleção de turnos com checkboxes
  Widget _buildAulaCheckboxes() {
    // Lista de opções para exibição
    // Se houver cursos selecionados, mostra os horários baseados no período do primeiro curso
    List<Map<String, String>> opcoesAula = [];
    if (cursosSelecionados.isNotEmpty &&
        cursosSelecionados.first.periodo != null) {
      final periodoCurso = cursosSelecionados.first.periodo;
      if (periodoCurso == 1) {
        // Matutino
        opcoesAula = [
          {
            'valor': 'Primeira Aula',
            'label': 'Primeiro horário (08h00 às 09h40)',
          },
          {
            'valor': 'Segunda Aula',
            'label': 'Segundo horário (09h55 às 11h35)',
          },
        ];
      } else if (periodoCurso == 3) {
        // Noturno
        opcoesAula = [
          {
            'valor': 'Primeira Aula',
            'label': 'Primeiro horário (19h00 às 20h40)',
          },
          {
            'valor': 'Segunda Aula',
            'label': 'Segundo horário (20h55 às 22h35)',
          },
        ];
      } else {
        // Vespertino ou outro - mostra genérico
        opcoesAula = [
          {'valor': 'Primeira Aula', 'label': 'Primeiro Turno'},
          {'valor': 'Segunda Aula', 'label': 'Segundo Turno'},
        ];
      }
    } else {
      // Sem cursos selecionados - mostra genérico
      opcoesAula = [
        {'valor': 'Primeira Aula', 'label': 'Primeiro Turno'},
        {'valor': 'Segunda Aula', 'label': 'Segundo Turno'},
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _podeSelecionarAula()
                ? const Color(0xFF44A301).withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              _podeSelecionarAula()
                  ? const Color(0xFF44A301).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color:
                    _podeSelecionarAula()
                        ? const Color(0xFF44A301)
                        : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selecione o(s) Turno(s)',
                style: TextStyle(
                  color:
                      _podeSelecionarAula()
                          ? const Color(0xFF44A301)
                          : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...opcoesAula.map((opcao) {
            final valor = opcao['valor']!;
            final label = opcao['label']!;
            final isSelected = periodosAulaSelecionados.contains(valor);

            return CheckboxListTile(
              value: isSelected,
              onChanged:
                  _podeSelecionarAula()
                      ? (bool? value) {
                        setState(() {
                          if (value == true) {
                            periodosAulaSelecionados.add(valor);
                          } else {
                            periodosAulaSelecionados.remove(valor);
                          }
                          // Limpa a sala selecionada quando muda os turnos
                          salaSelecionada = null;
                          salasFiltradas.clear();
                          // Atualiza os agendamentos considerando o novo período selecionado
                          carregarAgendamentosCursos(dia);
                        });
                      }
                      : null,
              title: Text(
                label,
                style: TextStyle(
                  color:
                      _podeSelecionarAula()
                          ? (isSelected
                              ? const Color(0xFF44A301)
                              : Colors.black87)
                          : Colors.grey,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              activeColor: const Color(0xFF44A301),
              checkColor: Colors.white,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  // NOVO: Widget para exibir cursos selecionados
  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final currentMonth = mesAtual ?? now; // Usa mesAtual em vez de dia
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    List<Widget> calendarDays = [];

    // Adiciona dias vazios no início (corrigindo o alinhamento)
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    // Adiciona os dias do mês
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final currentDate = DateTime(currentMonth.year, currentMonth.month, day);

      // Verifica se está selecionado (modo único ou múltiplo)
      bool isSelected = false;
      if (modoMultiplo) {
        isSelected = diasMultiplosSelecionados.any(
          (d) =>
              d.year == currentDate.year &&
              d.month == currentDate.month &&
              d.day == currentDate.day,
        );
      } else {
        isSelected =
            dia != null &&
            dia!.year == currentDate.year &&
            dia!.month == currentDate.month &&
            dia!.day == currentDate.day;
      }

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
            onTap:
                isPastDate
                    ? null
                    : () {
                      setState(() {
                        if (modoMultiplo) {
                          // Modo múltiplo: adiciona/remove da lista
                          if (isSelected) {
                            diasMultiplosSelecionados.removeWhere(
                              (d) =>
                                  d.year == currentDate.year &&
                                  d.month == currentDate.month &&
                                  d.day == currentDate.day,
                            );
                          } else {
                            diasMultiplosSelecionados.add(currentDate);
                          }
                        } else {
                          // Modo único: seleciona apenas um dia
                          dia = currentDate;
                        }
                        // Limpa a sala selecionada e salas filtradas quando altera a data
                        salaSelecionada = null;
                        salasFiltradas.clear();
                      });
                      // Carrega agendamentos por curso para o dia selecionado (modo único)
                      if (!modoMultiplo && dia != null) {
                        carregarAgendamentosCursos(dia);
                      } else {
                        setState(() {
                          agendamentosPorCurso.clear();
                        });
                      }
                      // Se todos os critérios estão preenchidos, refiltra as salas
                      if (_podeSelecionarSala()) {
                        filtrarSalas();
                      }
                    },
            child: Container(
              height: 45,
              margin: const EdgeInsets.all(3),
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
                            blurRadius: 8,
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
                            ? Colors.grey[400]
                            : Colors.black87,
                    fontWeight:
                        isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Adiciona dias vazios no final para completar 6 semanas (42 dias)
    final totalDias = calendarDays.length;
    final diasNecessarios = 42; // 6 semanas * 7 dias
    for (int i = totalDias; i < diasNecessarios; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    return Column(
      children: [
        // Título
        const Text(
          'Selecione o(s) Dia(s)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF44A301),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Abas estilo Google para seleção de modo de ensalamento
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Aba "1 dia"
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => setState(() {
                        modoMultiplo = false;
                        // Limpa dados do modo múltiplo quando muda para único
                        diasMultiplosSelecionados.clear();
                        // Limpa a sala selecionada e salas filtradas quando altera o modo
                        salaSelecionada = null;
                        salasFiltradas.clear();
                        // Limpa agendamentos por curso
                        agendamentosPorCurso.clear();
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: !modoMultiplo ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          !modoMultiplo
                              ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      'Único dia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            !modoMultiplo ? FontWeight.bold : FontWeight.normal,
                        color:
                            !modoMultiplo
                                ? const Color(0xFF44A301)
                                : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              // Aba "Vários dias"
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => setState(() {
                        modoMultiplo = true;
                        // Limpa dados do modo único quando muda para múltiplo
                        dia = null;
                        // Limpa a sala selecionada e salas filtradas quando altera o modo
                        salaSelecionada = null;
                        salasFiltradas.clear();
                        // Limpa agendamentos por curso
                        agendamentosPorCurso.clear();
                      }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: modoMultiplo ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          modoMultiplo
                              ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      'Vários dias',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            modoMultiplo ? FontWeight.bold : FontWeight.normal,
                        color:
                            modoMultiplo
                                ? const Color(0xFF44A301)
                                : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calendário completo em uma caixa
        Container(
          height: 420, // Altura fixa para manter consistência
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cabeçalho do mês
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (modoMultiplo) {
                          if (diasMultiplosSelecionados.isNotEmpty)
                            diasMultiplosSelecionados.clear();
                        } else {
                          dia = null;
                        }
                        // Limpa a sala selecionada e salas filtradas quando altera o mês
                        salaSelecionada = null;
                        salasFiltradas.clear();
                        // Limpa agendamentos por curso
                        agendamentosPorCurso.clear();
                        // Atualiza apenas o mês atual, não o dia selecionado
                        final mesAtualTemp = mesAtual ?? DateTime.now();
                        final novoMes = DateTime(
                          mesAtualTemp.month == 1
                              ? mesAtualTemp.year - 1
                              : mesAtualTemp.year,
                          mesAtualTemp.month == 1 ? 12 : mesAtualTemp.month - 1,
                          1,
                        );
                        mesAtual = novoMes;
                      });
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF44A301),
                    ),
                  ),
                  Text(
                    '${functions.getMonthName((mesAtual ?? DateTime.now()).month)} ${(mesAtual ?? DateTime.now()).year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (modoMultiplo) {
                          if (diasMultiplosSelecionados.isNotEmpty)
                            diasMultiplosSelecionados.clear();
                        } else {
                          dia = null;
                        }
                        // Limpa a sala selecionada e salas filtradas quando altera o mês
                        salaSelecionada = null;
                        salasFiltradas.clear();
                        // Limpa agendamentos por curso
                        agendamentosPorCurso.clear();
                        // Atualiza apenas o mês atual, não o dia selecionado
                        final mesAtualTemp = mesAtual ?? DateTime.now();
                        final novoMes = DateTime(
                          mesAtualTemp.month == 12
                              ? mesAtualTemp.year + 1
                              : mesAtualTemp.year,
                          mesAtualTemp.month == 12 ? 1 : mesAtualTemp.month + 1,
                          1,
                        );
                        mesAtual = novoMes;
                      });
                    },
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF44A301),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dias da semana (corrigido o alinhamento)
              Row(
                children: const [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Dom',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Seg',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Ter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Qua',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Qui',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sex',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sáb',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Grade do calendário com altura fixa
              Expanded(
                child: Column(
                  children: List.generate((calendarDays.length / 7).ceil(), (
                    weekIndex,
                  ) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children:
                              calendarDays.skip(weekIndex * 7).take(7).toList(),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> salvarLocacao() async {
    if (isLoading) return; // Evita duplo clique

    setState(() {
      isLoading = true; // Ativa o loading no início
    });

    try {
      // Salva os valores antes de limpar para usar na mensagem
      final numCursos = cursosSelecionados.length;
      final numDias = modoMultiplo ? diasMultiplosSelecionados.length : 1;
      final modoMultiploTemp = modoMultiplo;

      await functions.salvarLocacaoTeste(
        modoMultiplo: modoMultiplo,
        diasMultiplosSelecionados: diasMultiplosSelecionados,
        dia: dia,
        salaSelecionada: salaSelecionada,
        cursosSelecionados: cursosSelecionados,
        periodosAulaSelecionados: periodosAulaSelecionados,
        materiasPorCurso: materiasPorCurso,
        professoresPorCurso: professoresPorCurso,
        observacao:
            observacaoController.text.trim().isEmpty
                ? null
                : observacaoController.text.trim(),
        onProgress: (String message) {
          if (mounted) {
            // Remove o SnackBar anterior se existir
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(message)),
                  ],
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: const Color(0xFF44A301),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      );

      // Aguarda um pouco para garantir que a mensagem final seja exibida
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        salaSelecionada = null;
        cursosSelecionados.clear();
        materiasPorCurso.clear();
        professoresPorCurso.clear();
        materiasDisponiveisPorCurso.clear();
        professoresDisponiveisPorCurso.clear();
        dropdownsAbertos.clear();
        textosPesquisa.clear();
        periodosAulaSelecionados.clear();
        horaInicio = null;
        horaFim = null;
        dia = null;
        mesAtual = DateTime.now();
        diasMultiplosSelecionados.clear();
        agendamentosPorCurso.clear();
        observacaoController.clear();
      });

      // Remove o SnackBar de progresso antes de mostrar o sucesso
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  modoMultiploTemp
                      ? '✅ Agendamento para $numCursos curso(s) em $numDias dia(s) criado com sucesso!'
                      : '✅ Agendamento para $numCursos curso(s) criado com sucesso!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      carregarDados();

      // Só desativa o loading DEPOIS de tudo estar terminado
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;

      // Remove o SnackBar de progresso antes de mostrar o erro
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('❌ Erro: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );

      // Desativa o loading mesmo em caso de erro
      setState(() => isLoading = false);
    }
  }

  // NOVO: Função para filtrar salas baseada nos critérios selecionados
  Future<void> filtrarSalas() async {
    if (periodosAulaSelecionados.isEmpty ||
        cursosSelecionados.isEmpty ||
        (modoMultiplo ? diasMultiplosSelecionados.isEmpty : dia == null)) {
      setState(() {
        salasFiltradas.clear();
      });
      return;
    }

    setState(() {
      isLoadingSalas = true;
    });

    try {
      final salasFiltradasResult = await functions.filtrarSalas(
        periodosAulaSelecionados: periodosAulaSelecionados,
        cursosSelecionados: cursosSelecionados,
        modoMultiplo: modoMultiplo,
        diasMultiplosSelecionados: diasMultiplosSelecionados,
        dia: dia,
      );

      setState(() {
        salasFiltradas = salasFiltradasResult;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao filtrar salas: $e')));
    } finally {
      setState(() {
        isLoadingSalas = false;
      });
    }
  }

  // NOVO: Função para verificar se todos os campos estão preenchidos
  bool _todosCamposPreenchidos() {
    return functions.todosCamposPreenchidos(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      salaSelecionada: salaSelecionada,
    );
  }

  // NOVO: Controles para validação sequencial
  bool _podeSelecionarAula() {
    return functions.podeSelecionarAula(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
    );
  }

  bool _podeSelecionarCurso() {
    return functions.podeSelecionarCurso(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
    );
  }

  bool _podeSelecionarMateria(int cursoId) {
    return functions.podeSelecionarMateria(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      cursoId: cursoId,
    );
  }

  bool _podeSelecionarProfessor(int cursoId) {
    return functions.podeSelecionarProfessor(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      cursoId: cursoId,
      materiasPorCurso: materiasPorCurso,
    );
  }

  bool _podeSelecionarSala() {
    return functions.podeSelecionarSala(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      materiasPorCurso: materiasPorCurso,
      professoresPorCurso: professoresPorCurso,
    );
  }

  // NOVO: Função para obter mensagem de validação sequencial
  String _getMensagemValidacaoSequencial() {
    return functions.getMensagemValidacaoSequencial(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodosAulaSelecionados: periodosAulaSelecionados,
      cursosSelecionados: cursosSelecionados,
      materiasPorCurso: materiasPorCurso,
      professoresPorCurso: professoresPorCurso,
    );
  }

  // NOVO: Widget para exibir mensagem de validação sequencial
  Widget _buildMensagemValidacaoSequencial() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _podeSelecionarSala()
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _podeSelecionarSala()
                  ? Colors.green.withOpacity(0.5)
                  : Colors.orange.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _podeSelecionarSala() ? Icons.check_circle : Icons.warning,
            color: _podeSelecionarSala() ? Colors.green : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMensagemValidacaoSequencial(),
              style: TextStyle(
                color: _podeSelecionarSala() ? Colors.green : Colors.orange,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String periodoToString(int? periodo) {
    return functions.periodoToString(periodo);
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
          'Novo Ensalamento',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: buildAppDrawer(context),
      backgroundColor: const Color(0xFFF8FAFC), // igual criarcurso
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Calendário à esquerda (agora 45% da tela)
                    Expanded(
                      flex: 45,
                      child: Container(
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: const Color(0xFFE8F5E8),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildCustomCalendar(),
                                    // Aviso de validação mais próximo do agendamento
                                    if (!_todosCamposPreenchidos()) ...[
                                      const SizedBox(height: 16),
                                      _buildMensagemValidacaoSequencial(),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Linha separadora
                    Container(
                      width: 2,
                      height: double.infinity,
                      color: const Color(0xFF44A301).withOpacity(0.2),
                    ),
                    // Formulário à direita (agora 53% da tela)
                    Expanded(
                      flex: 53,
                      child: Container(
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'Preencha os dados para realizar um agendamento',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF44A301),
                                    letterSpacing: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                _buildAulaCheckboxes(),

                                const SizedBox(height: 16),
                                // NOVO: Seção de múltiplos cursos
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _podeSelecionarCurso()
                                            ? const Color(
                                              0xFF44A301,
                                            ).withOpacity(0.05)
                                            : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          _podeSelecionarCurso()
                                              ? const Color(
                                                0xFF44A301,
                                              ).withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.school,
                                            color:
                                                _podeSelecionarCurso()
                                                    ? const Color(0xFF44A301)
                                                    : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Selecionar Turmas',
                                            style: TextStyle(
                                              color:
                                                  _podeSelecionarCurso()
                                                      ? const Color(0xFF44A301)
                                                      : Colors.grey,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${cursosSelecionados.length} curso(s) selecionado(s)',
                                            style: TextStyle(
                                              color:
                                                  _podeSelecionarCurso()
                                                      ? const Color(0xFF44A301)
                                                      : Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildSearchableDropdown<
                                              curso_model.Curso
                                            >(
                                              value:
                                                  null, // Sempre vazio para adicionar novos
                                              labelText: 'Adicionar Turmas',
                                              items:
                                                  _podeSelecionarCurso()
                                                      ? getCursosOrdenados(
                                                        cursos
                                                            .where(
                                                              (curso) =>
                                                                  !cursosSelecionados.any(
                                                                    (c) =>
                                                                        c.id ==
                                                                        curso
                                                                            .id,
                                                                  ),
                                                            )
                                                            .toList(),
                                                      )
                                                      : [],
                                              displayText: (curso) {
                                                // Mostra o nome do curso e o período
                                                final periodoStr =
                                                    periodoToString(
                                                      curso.periodo,
                                                    );
                                                return '${curso.curso} - $periodoStr';
                                              },
                                              onChanged:
                                                  _podeSelecionarCurso()
                                                      ? (
                                                        curso_model.Curso?
                                                        value,
                                                      ) {
                                                        if (value != null) {
                                                          adicionarCurso(value);
                                                          // Limpar o dropdown
                                                          setState(() {
                                                            cursoSearchText =
                                                                '';
                                                            isCursoDropdownOpen =
                                                                false;
                                                          });
                                                        }
                                                      }
                                                      : (
                                                        curso_model.Curso?
                                                        value,
                                                      ) {},
                                              validator:
                                                  (value) =>
                                                      null, // Sem validação aqui
                                              fieldKey: _cursoFieldKey,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  _podeSelecionarCurso()
                                                      ? const Color(0xFF44A301)
                                                      : Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              onPressed:
                                                  _podeSelecionarCurso()
                                                      ? () =>
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/criarcurso',
                                                          )
                                                      : null,
                                              icon: Icon(
                                                Icons.add,
                                                color: Colors.white,
                                              ),
                                              tooltip: 'Criar novo curso',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // NOVO: Exibir cursos selecionados
                                _buildCursosSelecionados(),
                                const SizedBox(height: 16),
                                // Seção de seleção de sala com filtro inteligente (agora por último)
                                if (cursosSelecionados.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          _podeSelecionarSala()
                                              ? const Color(
                                                0xFF44A301,
                                              ).withOpacity(0.05)
                                              : Colors.grey.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            _podeSelecionarSala()
                                                ? const Color(
                                                  0xFF44A301,
                                                ).withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.meeting_room,
                                              color:
                                                  _podeSelecionarSala()
                                                      ? const Color(0xFF44A301)
                                                      : Colors.grey,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Selecionar Sala',
                                              style: TextStyle(
                                                color:
                                                    _podeSelecionarSala()
                                                        ? const Color(
                                                          0xFF44A301,
                                                        )
                                                        : Colors.grey,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (isLoadingSalas)
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF44A301)),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (!_podeSelecionarSala())
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _getMensagemValidacaoSequencial(),
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (salasFiltradas.isEmpty &&
                                            !isLoadingSalas)
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Complete todos os campos acima para ver as salas disponíveis',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (salasFiltradas.isNotEmpty)
                                          _buildSearchableDropdown<
                                            Map<String, dynamic>
                                          >(
                                            value:
                                                salaSelecionada != null
                                                    ? salasFiltradas.firstWhere(
                                                      (sala) =>
                                                          sala['sala_id'] ==
                                                          salaSelecionada!.id,
                                                      orElse:
                                                          () =>
                                                              salasFiltradas
                                                                  .first,
                                                    )
                                                    : null,
                                            labelText: 'Selecione uma Sala',
                                            items: salasFiltradas,
                                            displayText: (sala) {
                                              return 'Sala ${sala['numero_sala']} - ${sala['qtd_cadeiras']} Carteiras';
                                            },
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  salaSelecionada = sala_model.Sala(
                                                    id: value['sala_id'],
                                                    numeroSala:
                                                        value['numero_sala'],
                                                    qtdCadeiras:
                                                        value['qtd_cadeiras'],
                                                    disponivel:
                                                        value['disponivel'] ??
                                                        true,
                                                  );
                                                });
                                              }
                                            },
                                            validator:
                                                (value) =>
                                                    value == null
                                                        ? 'Selecione uma sala'
                                                        : null,
                                            fieldKey: _salaFieldKey,
                                          ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color:
                                                _podeSelecionarSala()
                                                    ? const Color(0xFF44A301)
                                                    : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                _podeSelecionarSala()
                                                    ? () => Navigator.pushNamed(
                                                      context,
                                                      '/criarsala',
                                                    )
                                                    : null,
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                            tooltip: 'Criar nova sala',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                // Campo de observação (no final)
                                TextField(
                                  controller: observacaoController,
                                  enabled: salaSelecionada != null,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Observação (opcional)',
                                    hintText:
                                        'Digite uma observação sobre o agendamento...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color:
                                            salaSelecionada != null
                                                ? const Color(0xFF44A301)
                                                : Colors.grey,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color:
                                            salaSelecionada != null
                                                ? const Color(0xFF44A301)
                                                : Colors.grey,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF44A301),
                                        width: 2,
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color:
                                          salaSelecionada != null
                                              ? const Color(0xFF44A301)
                                              : Colors.grey,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color:
                                        salaSelecionada != null
                                            ? const Color(0xFF44A301)
                                            : Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.event,
                                            size: 16,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/criarevento',
                                            );
                                          },
                                          label: const Text('Novo Evento'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.quiz,
                                            size: 16,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/criarprova',
                                            );
                                          },
                                          label: const Text('Nova Prova'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.list,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  247,
                                                  245,
                                                  96,
                                                ),
                                            foregroundColor:
                                                const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/listalocacao',
                                            );
                                          },
                                          label: const Text(
                                            'Consultar Agendamentos',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          icon:
                                              isLoading
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                  : const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF44A301,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          onPressed:
                                              isLoading ? null : salvarLocacao,
                                          label: Text(
                                            isLoading
                                                ? 'Criando agendamento...'
                                                : 'Agendar ${cursosSelecionados.length} curso(s) - ${periodosAulaSelecionados.length} período(s)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Espaço extra para permitir mais scroll para baixo
                                const SizedBox(height: 200),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
