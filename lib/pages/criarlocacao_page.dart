import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;
import '../functions/criarlocacao_functions.dart';

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

  bool isLoading = false;

  DateTime? dia;
  DateTime? mesAtual; // NOVO: Variável para controlar o mês atual do calendário
  TimeOfDay? horaSelecionada;
  String? periodoAulaSelecionado;

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

  // NOVO: Controles para dropdowns de matéria e professor por curso
  Map<String, bool> dropdownsAbertos = {};
  Map<String, String> textosPesquisa = {};

  // Overlay entries para dropdowns
  OverlayEntry? _overlayEntry;

  // GlobalKeys para posicionamento dos dropdowns
  final GlobalKey _salaFieldKey = GlobalKey();
  final GlobalKey _cursoFieldKey = GlobalKey();
  final GlobalKey _materiaFieldKey = GlobalKey();
  final GlobalKey _professorFieldKey = GlobalKey();
  final GlobalKey _aulaFieldKey =
      GlobalKey(); // NOVO: Key para o dropdown de aula

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

  Future<void> carregarProfessoresPorMateria(int materiaId, int cursoId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final professores = await functions.carregarProfessoresPorMateria(
        materiaId,
        cursoId,
      );
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

  // NOVO: Adicionar curso à lista de selecionados
  void adicionarCurso(curso_model.Curso curso) {
    if (!cursosSelecionados.any((c) => c.id == curso.id)) {
      setState(() {
        cursosSelecionados.add(curso);
        // Inicializa as seleções para este curso
        materiasPorCurso[curso.id] = null;
        professoresPorCurso[curso.id] = null;
      });
      // Carrega as matérias para este curso específico
      carregarMateriasPorCurso(curso.id);
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
                'Cursos Selecionados (${cursosSelecionados.length})',
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
                      'Semestre: ${curso.semestre ?? "Não informado"} - Período: ${periodoToString(curso.periodo)}',
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
                  labelText: 'Selecione a Matéria',
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
                              professoresPorCurso[curso.id] =
                                  null; // Limpa professor quando muda matéria
                            });
                            // Carrega os professores para esta matéria
                            if (value != null) {
                              carregarProfessoresPorMateria(
                                value['id'],
                                curso.id,
                              );
                            }
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
          // Campo de professor para este curso
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
                                  periodoAulaSelecionado != null &&
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
        if (fieldKey == _materiaFieldKey) {
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
                        } else if (T == Map<String, dynamic>) {
                          // NOVO: Controle individual para dropdowns
                          if (dropdownId != null) {
                            dropdownsAbertos[dropdownId] = false;
                            textosPesquisa[dropdownId] = '';
                          } else {
                            // Fallback para campos globais
                            if (fieldKey == _materiaFieldKey) {
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
                          return ListTile(
                            title: Text(
                              displayText(item),
                              style: const TextStyle(
                                color: Color(0xFF44A301),
                                fontSize: 16,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            onTap: () {
                              onChanged(item);
                              setState(() {
                                if (T == sala_model.Sala) {
                                  isSalaDropdownOpen = false;
                                  salaSearchText = '';
                                } else if (T == curso_model.Curso) {
                                  isCursoDropdownOpen = false;
                                  cursoSearchText = '';
                                } else if (T == Map<String, dynamic>) {
                                  // NOVO: Controle individual para dropdowns
                                  if (dropdownId != null) {
                                    dropdownsAbertos[dropdownId] = false;
                                    textosPesquisa[dropdownId] = '';
                                  } else {
                                    // Fallback para campos globais
                                    if (fieldKey == _materiaFieldKey) {
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
                      if (fieldKey == _materiaFieldKey) {
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
                      ? TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          color:
                              isEnabled ? const Color(0xFF44A301) : Colors.grey,
                          fontSize: 16,
                        ),
                        onChanged: (text) {
                          setState(() {
                            if (T == sala_model.Sala) {
                              salaSearchText = text;
                            } else if (T == curso_model.Curso) {
                              cursoSearchText = text;
                            } else if (T == Map<String, dynamic>) {
                              // NOVO: Controle individual para dropdowns
                              if (dropdownId != null) {
                                textosPesquisa[dropdownId] = text;
                              } else {
                                // Fallback para campos globais
                                if (fieldKey == _materiaFieldKey) {
                                  materiaSearchText = text;
                                } else if (fieldKey == _professorFieldKey) {
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

  // NOVO: Widget para dropdown de seleção de aula
  Widget _buildAulaDropdown() {
    bool isAulaDropdownOpen = false;
    String aulaSearchText = '';

    // Controle do dropdown de aula
    if (dropdownsAbertos['aula'] != null) {
      isAulaDropdownOpen = dropdownsAbertos['aula']!;
      aulaSearchText = textosPesquisa['aula'] ?? '';
    }

    final List<String> opcoesAula = ['Primeira Aula', 'Segunda Aula'];

    void _showAulaOverlay() {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
      }

      double topPosition = 100;
      double leftPosition = 50;
      double width = 300;

      if (_aulaFieldKey.currentContext != null) {
        final renderBox =
            _aulaFieldKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        topPosition = position.dy + 60;
        leftPosition = position.dx;
        width = size.width;

        final screenHeight = MediaQuery.of(context).size.height;
        final availableSpaceBelow = screenHeight - topPosition;
        if (availableSpaceBelow < 200) {
          topPosition = position.dy - 200;
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
                        dropdownsAbertos['aula'] = false;
                        textosPesquisa['aula'] = '';
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
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: opcoesAula.length,
                        itemBuilder: (context, index) {
                          final opcao = opcoesAula[index];
                          return ListTile(
                            title: Text(
                              opcao,
                              style: const TextStyle(
                                color: Color(0xFF44A301),
                                fontSize: 16,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            onTap: () {
                              setState(() {
                                periodoAulaSelecionado = opcao;
                                dropdownsAbertos['aula'] = false;
                                textosPesquisa['aula'] = '';
                              });
                              _overlayEntry?.remove();
                              _overlayEntry = null;
                            },
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

    void _hideAulaOverlay() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    return GestureDetector(
      key: _aulaFieldKey,
      onTap:
          _podeSelecionarAula()
              ? () {
                setState(() {
                  dropdownsAbertos['aula'] =
                      !(dropdownsAbertos['aula'] ?? false);
                  if (!(dropdownsAbertos['aula'] ?? false)) {
                    textosPesquisa['aula'] = '';
                    _hideAulaOverlay();
                  } else {
                    _showAulaOverlay();
                  }
                });
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              _podeSelecionarAula()
                  ? const Color(0xFF44A301).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                _podeSelecionarAula() ? const Color(0xFF44A301) : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione a Aula (Período)',
                    style: TextStyle(
                      color:
                          _podeSelecionarAula()
                              ? const Color(0xFF44A301).withOpacity(0.7)
                              : Colors.grey.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodoAulaSelecionado ?? 'Selecione uma opção',
                    style: TextStyle(
                      color:
                          _podeSelecionarAula()
                              ? (periodoAulaSelecionado != null
                                  ? const Color(0xFF44A301)
                                  : const Color(0xFF44A301).withOpacity(0.5))
                              : Colors.grey.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isAulaDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color:
                  _podeSelecionarAula() ? const Color(0xFF44A301) : Colors.grey,
            ),
          ],
        ),
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
                      });
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

        // Abas estilo Google para seleção de modo de agendamento
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

      await functions.salvarLocacao(
        isLoading: isLoading,
        modoMultiplo: modoMultiplo,
        diasMultiplosSelecionados: diasMultiplosSelecionados,
        dia: dia,
        salaSelecionada: salaSelecionada,
        cursosSelecionados: cursosSelecionados,
        periodoAulaSelecionado: periodoAulaSelecionado,
        materiasPorCurso: materiasPorCurso,
        professoresPorCurso: professoresPorCurso,
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
        periodoAulaSelecionado = null;
        horaInicio = null;
        horaFim = null;
        dia = null;
        mesAtual = DateTime.now();
        diasMultiplosSelecionados.clear();
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
    if (periodoAulaSelecionado == null ||
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
        periodoAulaSelecionado: periodoAulaSelecionado,
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
      periodoAulaSelecionado: periodoAulaSelecionado,
      cursosSelecionados: cursosSelecionados,
      salaSelecionada: salaSelecionada,
    );
  }

  // NOVO: Função para gerar mensagem de validação em ordem
  String _getMensagemValidacao() {
    return functions.getMensagemValidacao(
      modoMultiplo: modoMultiplo,
      diasMultiplosSelecionados: diasMultiplosSelecionados,
      dia: dia,
      periodoAulaSelecionado: periodoAulaSelecionado,
      cursosSelecionados: cursosSelecionados,
      salaSelecionada: salaSelecionada,
    );
  }

  // NOVO: Controles para validação sequencial
  bool _podeSelecionarAula() {
    return modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;
  }

  bool _podeSelecionarCurso() {
    return _podeSelecionarAula() && periodoAulaSelecionado != null;
  }

  bool _podeSelecionarMateria(int cursoId) {
    return _podeSelecionarCurso() && cursosSelecionados.isNotEmpty;
  }

  bool _podeSelecionarProfessor(int cursoId) {
    return _podeSelecionarMateria(cursoId) && materiasPorCurso[cursoId] != null;
  }

  bool _podeSelecionarSala() {
    if (!_podeSelecionarCurso() || cursosSelecionados.isEmpty) {
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

  // NOVO: Função para obter mensagem de validação sequencial
  String _getMensagemValidacaoSequencial() {
    if (!_podeSelecionarAula()) {
      return '⚠️ Primeiro selecione o(s) dia(s) no calendário';
    }
    if (!_podeSelecionarCurso()) {
      return '⚠️ Agora selecione o período da aula';
    }
    if (!_podeSelecionarMateria(0)) {
      return '⚠️ Adicione pelo menos um curso';
    }

    // Verifica se todos os cursos têm matéria selecionada
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null) {
        return '⚠️ Selecione a matéria para o curso ${curso.curso}';
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
          'Novo Agendamento',
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
                  colors: [Color(0xFF2D5A1A), Color(0xFF44A301)],
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                    ), // Espaço à esquerda
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/UniCV-Variacoes-07.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
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
                                _buildAulaDropdown(),

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
                                            'Selecionar Cursos',
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
                                              labelText: 'Adicionar Curso',
                                              items:
                                                  _podeSelecionarCurso()
                                                      ? cursos
                                                          .where(
                                                            (curso) =>
                                                                !cursosSelecionados
                                                                    .any(
                                                                      (c) =>
                                                                          c.id ==
                                                                          curso
                                                                              .id,
                                                                    ),
                                                          )
                                                          .toList()
                                                      : [],
                                              displayText:
                                                  (curso) =>
                                                      '${curso.curso} - ${curso.semestre ?? "Semestre?"} - ${curso.periodo != null ? periodoToString(curso.periodo) : "Período?"}',
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
                                          DropdownButtonFormField<
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
                                            decoration: InputDecoration(
                                              labelText: 'Selecione uma Sala',
                                              labelStyle: const TextStyle(
                                                color: Color(0xFF44A301),
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFF44A301,
                                              ).withOpacity(0.1),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF44A301),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF44A301),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF44A301),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            dropdownColor: Colors.white,
                                            iconEnabledColor: const Color(
                                              0xFF44A301,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF44A301),
                                            ),
                                            isExpanded: true,
                                            items:
                                                salasFiltradas.map((sala) {
                                                  final agendamentos =
                                                      sala['agendamentos_existentes'] ??
                                                      0;
                                                  final emoji =
                                                      agendamentos == 0
                                                          ? '🟢'
                                                          : '🟡';
                                                  final status =
                                                      agendamentos == 0
                                                          ? 'Livre'
                                                          : '1 agendamento';

                                                  return DropdownMenuItem<
                                                    Map<String, dynamic>
                                                  >(
                                                    value: sala,
                                                    child: Container(
                                                      constraints:
                                                          const BoxConstraints(
                                                            minHeight: 32,
                                                            maxHeight: 40,
                                                          ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            emoji,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Container(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minHeight:
                                                                        20,
                                                                    maxHeight:
                                                                        24,
                                                                  ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    'Sala ${sala['numero_sala']}',
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          11,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 0,
                                                                  ),
                                                                  Text(
                                                                    '${sala['qtd_cadeiras']} cadeiras - $status',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          9,
                                                                      color:
                                                                          Colors
                                                                              .grey[600],
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  salaSelecionada =
                                                      sala_model.Sala(
                                                        id: value['sala_id'],
                                                        numeroSala:
                                                            value['numero_sala'],
                                                        qtdCadeiras:
                                                            value['qtd_cadeiras'],
                                                        disponivel: true,
                                                      );
                                                });
                                              }
                                            },
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
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.list,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            247,
                                            245,
                                            96,
                                          ),
                                          foregroundColor: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/listalocacao',
                                          );
                                        },
                                        label: const Text('Ver agendamentos'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
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
                                            fontSize: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        onPressed:
                                            isLoading ? null : salvarLocacao,
                                        label: Text(
                                          isLoading
                                              ? 'Criando agendamento...'
                                              : 'Agendar ${cursosSelecionados.length} curso(s)',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
