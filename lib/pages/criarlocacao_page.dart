import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

class CriarLocacaoPage extends StatefulWidget {
  const CriarLocacaoPage({super.key});

  @override
  State<CriarLocacaoPage> createState() => _CriarLocacaoPageState();
}

class _CriarLocacaoPageState extends State<CriarLocacaoPage> {
  final supabase = Supabase.instance.client;

  List<sala_model.Sala> salas = [];
  List<curso_model.Curso> cursos = [];
  List<Map<String, dynamic>> materias = [];
  List<Map<String, dynamic>> professores = [];
  sala_model.Sala? salaSelecionada;
  curso_model.Curso? cursoSelecionado;
  Map<String, dynamic>? materiaSelecionada;
  Map<String, dynamic>? professorSelecionado;

  // NOVO: Lista para múltiplos cursos
  List<curso_model.Curso> cursosSelecionados = [];

  // NOVO: Estrutura para armazenar matéria e professor por curso
  Map<int, Map<String, dynamic>?> materiasPorCurso = {};
  Map<int, Map<String, dynamic>?> professoresPorCurso = {};
  Map<int, List<Map<String, dynamic>>> materiasDisponiveisPorCurso = {};
  Map<int, List<Map<String, dynamic>>> professoresDisponiveisPorCurso = {};

  bool isLoading = false;

  DateTime? dia;
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

  // Novo: controle de modo do calendário
  bool modoMultiplo = false;
  Set<DateTime> diasMultiplosSelecionados = {};

  String formatHora(TimeOfDay hora) {
    final horaFormatada = hora.hour.toString().padLeft(2, '0');
    final minutoFormatado = hora.minute.toString().padLeft(2, '0');
    return '$horaFormatada:$minutoFormatado';
  }

  final List<String> periodosAula = ['Matutino', 'Vespertino', 'Noturno'];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> carregarDados() async {
    setState(() => isLoading = true);
    try {
      final responseSalas = await supabase.from('salas').select();
      final responseCursos = await supabase.from('cursos').select();
      final responseProfessores = await supabase.from('professores').select();
      setState(() {
        salas =
            (responseSalas as List)
                .map((e) => sala_model.Sala.fromMap(e))
                .toList();
        cursos =
            (responseCursos as List)
                .map((e) => curso_model.Curso.fromMap(e))
                .toList();
        professores = List<Map<String, dynamic>>.from(
          responseProfessores as List,
        );
        cursos.sort(
          (a, b) => a.curso.toLowerCase().compareTo(b.curso.toLowerCase()),
        );
        // NOVO: Limpar dados de múltiplos cursos
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
      final response = await supabase
          .from('materias')
          .select()
          .eq('curso_id', cursoId);
      setState(() {
        materiasDisponiveisPorCurso[cursoId] = List<Map<String, dynamic>>.from(
          response as List,
        );
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
      // Busca os professores associados à matéria através da tabela professor_materias
      final response = await supabase
          .from('professor_materias')
          .select('professor_id, professores!inner(id, nome_professor)')
          .eq('materia_id', materiaId);

      setState(() {
        professoresDisponiveisPorCurso[cursoId] =
            (response as List).map((item) {
              // Extrai os dados do professor do resultado da join
              return item['professores'] as Map<String, dynamic>;
            }).toList();
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
    }
  }

  // NOVO: Remover curso da lista de selecionados
  void removerCurso(int cursoId) {
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
    });
  }

  // NOVO: Widget para exibir cursos selecionados
  Widget _buildCursosSelecionados() {
    if (cursosSelecionados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          ...cursosSelecionados.map((curso) => _buildCursoItem(curso)),
        ],
      ),
    );
  }

  // NOVO: Widget para exibir item de curso selecionado
  Widget _buildCursoItem(curso_model.Curso curso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          // Campo de matéria para este curso
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown<Map<String, dynamic>>(
                  value: materiasPorCurso[curso.id],
                  labelText: 'Selecione a Matéria',
                  items: materiasDisponiveisPorCurso[curso.id] ?? [],
                  displayText: (materia) => materia['nome'] ?? '',
                  onChanged: (value) {
                    setState(() {
                      materiasPorCurso[curso.id] = value;
                      professoresPorCurso[curso.id] =
                          null; // Limpa professor quando muda matéria
                    });
                    // Carrega os professores para esta matéria
                    if (value != null) {
                      carregarProfessoresPorMateria(value['id'], curso.id);
                    }
                  },
                  validator:
                      (value) => value == null ? 'Selecione uma matéria' : null,
                  fieldKey: GlobalKey(),
                  dropdownId: 'materia_${curso.id}',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF44A301),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/criarmateria'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Criar nova matéria',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Campo de professor para este curso
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown<Map<String, dynamic>>(
                  value: professoresPorCurso[curso.id],
                  labelText: 'Selecione o Professor',
                  items: professoresDisponiveisPorCurso[curso.id] ?? [],
                  displayText: (professor) => professor['nome_professor'] ?? '',
                  onChanged: (value) {
                    setState(() {
                      professoresPorCurso[curso.id] = value;
                    });
                  },
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
                  color: const Color(0xFF44A301),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/criarprofessor'),
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
      if (fieldKey.currentContext != null) {
        final renderBox =
            fieldKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        topPosition = position.dy + 60;

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
            (context) => Positioned(
              top: topPosition,
              left:
                  fieldKey.currentContext != null
                      ? (fieldKey.currentContext!.findRenderObject()
                              as RenderBox)
                          .localToGlobal(Offset.zero)
                          .dx
                      : 50,
              width:
                  fieldKey.currentContext != null
                      ? (fieldKey.currentContext!.findRenderObject()
                              as RenderBox)
                          .size
                          .width
                      : 300,
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
      );

      Overlay.of(context).insert(_overlayEntry!);
    }

    void _hideOverlay() {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    return GestureDetector(
      key: fieldKey,
      onTap: () {
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
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        decoration: BoxDecoration(
          color: const Color(0xFF44A301).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF44A301)),
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
                        style: const TextStyle(
                          color: Color(0xFF44A301),
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
                              value != null
                                  ? const Color(0xFF44A301)
                                  : const Color(0xFF44A301).withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF44A301),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final currentMonth = dia ?? now;
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
                        dia = DateTime(
                          (dia ?? DateTime.now()).year,
                          (dia ?? DateTime.now()).month - 1,
                          1,
                        );
                      });
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF44A301),
                    ),
                  ),
                  Text(
                    '${_getMonthName((dia ?? DateTime.now()).month)} ${(dia ?? DateTime.now()).year}',
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
                        dia = DateTime(
                          (dia ?? DateTime.now()).year,
                          (dia ?? DateTime.now()).month + 1,
                          1,
                        );
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

              // Grade do calendário
              ...List.generate((calendarDays.length / 7).ceil(), (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: calendarDays.skip(weekIndex * 7).take(7).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
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

  Future<void> salvarLocacao() async {
    if (isLoading) return; // Evita duplo clique

    print(
      'Chamou salvarLocacao para: '
      'cursos=${cursosSelecionados.length}, '
      'sala=${salaSelecionada?.id}, '
      'aula=$periodoAulaSelecionado',
    );

    final bool temDiasSelecionados =
        modoMultiplo ? diasMultiplosSelecionados.isNotEmpty : dia != null;

    // NOVO: Verificar se há cursos selecionados
    if (!temDiasSelecionados ||
        salaSelecionada == null ||
        cursosSelecionados.isEmpty ||
        periodoAulaSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
        ),
      );
      return;
    }

    // Verificar se cada curso tem matéria e professor selecionados
    for (final curso in cursosSelecionados) {
      if (materiasPorCurso[curso.id] == null ||
          professoresPorCurso[curso.id] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor, selecione matéria e professor para o curso "${curso.curso}"',
            ),
          ),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    // Para múltiplos cursos, vamos usar o período do primeiro curso como referência
    // ou implementar uma lógica mais complexa se necessário
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
    for (DateTime diaProcessar in diasParaProcessar) {
      final dataFormatada =
          '${diaProcessar.year.toString().padLeft(4, '0')}-${diaProcessar.month.toString().padLeft(2, '0')}-${diaProcessar.day.toString().padLeft(2, '0')}';

      // 1. Verifica quantos agendamentos já existem para a sala nesse dia e período (NOVA REGRA: 4 agendamentos por período)
      final agendamentosSalaPeriodo = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('periodo', periodoCurso);

      if (agendamentosSalaPeriodo.length >= 4) {
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Essa sala já atingiu o limite de 4 agendamentos para o período $periodoNome no dia ${dataFormatada.split('-').reversed.join('/')}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 2. Verifica quantos agendamentos do mesmo tipo já existem para a sala nesse dia, período e aula_periodo específico
      final agendamentosSalaPeriodoTipo = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado!)
          .eq(
            'tipo_agendamento',
            'A',
          ); // Verifica apenas agendamentos do tipo Aula

      // NOVO: Verifica se há espaço suficiente para todos os cursos selecionados
      final espacoDisponivel = 2 - agendamentosSalaPeriodoTipo.length;
      if (espacoDisponivel < cursosSelecionados.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Essa sala só tem espaço para $espacoDisponivel aula(s) no período "${periodoAulaSelecionado}" no dia ${dataFormatada.split('-').reversed.join('/')}. Você selecionou ${cursosSelecionados.length} curso(s).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 3. Verifica quantos agendamentos já existem para cada curso nesse dia
      for (final curso in cursosSelecionados) {
        final agendamentosCurso = await supabase
            .from('agendamento')
            .select()
            .eq('curso_id', curso.id)
            .eq('dia', dataFormatada);

        if (agendamentosCurso.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'O curso "${curso.curso}" já atingiu o limite de 2 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
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
                .maybeSingle();

        if (agendamentoExistente != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Já existe um agendamento igual para o curso "${curso.curso}" no dia ${dataFormatada.split('-').reversed.join('/')}!',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
        }
      }

      // 5. Verifica se há conflito de horário com outros tipos de agendamento (aula, prova, evento)
      final conflitosHorario = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado!);

      if (conflitosHorario.isNotEmpty) {
        // Verifica se já existe um agendamento do mesmo tipo (aula) no mesmo horário
        final tiposExistentes =
            conflitosHorario.map((a) => a['tipo_agendamento']).toSet();

        // NOVA REGRA: Para aulas, verificar se já existem 2 aulas no mesmo horário
        if (tiposExistentes.contains('A')) {
          final aulasMesmoHorario =
              conflitosHorario
                  .where((a) => a['tipo_agendamento'] == 'A')
                  .toList();

          // NOVO: Verifica se há espaço suficiente para todos os cursos selecionados
          final espacoDisponivelHorario = 2 - aulasMesmoHorario.length;
          if (espacoDisponivelHorario < cursosSelecionados.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Já existem ${aulasMesmoHorario.length} aula(s) agendadas para este horário. Só há espaço para $espacoDisponivelHorario aula(s) adicional(is).',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => isLoading = false);
            return;
          }

          // Verificar se algum dos cursos já está agendado neste horário
          for (final curso in cursosSelecionados) {
            final cursoJaAgendado = aulasMesmoHorario.any(
              (a) => a['curso_id'] == curso.id,
            );

            if (cursoJaAgendado) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'O curso "${curso.curso}" já está agendado para este horário.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() => isLoading = false);
              return;
            }
          }
        }

        // Verifica se já existe qualquer tipo de agendamento no mesmo horário
        // (aula, prova ou evento) - não permite conflitos de horário
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Já existe uma $tipoExistente agendada para o horário "$periodoAulaSelecionado" neste dia.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
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

      // NOVO: Salva agendamentos para todos os cursos e dias selecionados
      for (DateTime diaProcessar in diasParaProcessar) {
        final dataFormatada =
            '${diaProcessar.year.toString().padLeft(4, '0')}-${diaProcessar.month.toString().padLeft(2, '0')}-${diaProcessar.day.toString().padLeft(2, '0')}';

        print('DEBUG - Processando dia: $dataFormatada');

        // Para cada curso selecionado
        for (final curso in cursosSelecionados) {
          final periodoCurso = curso.periodo;
          final materia = materiasPorCurso[curso.id];
          final professor = professoresPorCurso[curso.id];

          print('DEBUG - Salvando curso: ${curso.curso} (ID: ${curso.id})');
          print('DEBUG - Matéria: ${materia?['nome']} (ID: ${materia?['id']})');
          print(
            'DEBUG - Professor: ${professor?['nome_professor']} (ID: ${professor?['id']})',
          );

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
            print('DEBUG - Agendamento criado com ID: ${response[0]['id']}');
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
      print('DEBUG - IDs dos agendamentos: $idsAgendamentosCriados');

      // Se foram criados múltiplos agendamentos, aguarda um pouco e então
      // remove os registros individuais do histórico e cria um registro múltiplo
      if (idsAgendamentosCriados.length > 1) {
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

      setState(() {
        salaSelecionada = null;
        // NOVO: Limpar dados de múltiplos cursos
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
        diasMultiplosSelecionados.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            modoMultiplo
                ? 'Agendamento para ${cursosSelecionados.length} curso(s) em ${diasParaProcessar.length} dia(s) salvo com sucesso'
                : 'Agendamento para ${cursosSelecionados.length} curso(s) salvo com sucesso',
          ),
        ),
      );

      carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar agendamento: $e')));
    } finally {
      setState(() => isLoading = false);
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                  children: [
                    // Calendário à esquerda (agora 45% da tela)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
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
                          const SizedBox(height: 30),
                          Expanded(child: _buildCustomCalendar()),
                        ],
                      ),
                    ),
                    // Linha separadora
                    Container(
                      width: 2,
                      height: double.infinity,
                      color: const Color(0xFF44A301).withOpacity(0.2),
                    ),
                    // Formulário à direita (agora 53% da tela)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.53,
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
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                value: periodoAulaSelecionado,
                                decoration: InputDecoration(
                                  labelText: 'Selecione a Aula (Período)',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF44A301),
                                  ),
                                  filled: true,
                                  fillColor: const Color(
                                    0xFF44A301,
                                  ).withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF44A301),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF44A301),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF44A301),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFF44A301),
                                style: const TextStyle(
                                  color: Color(0xFF44A301),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Primeira Aula',
                                    child: Text(
                                      'Primeira Aula',
                                      style: TextStyle(
                                        color: Color(0xFF44A301),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Segunda Aula',
                                    child: Text(
                                      'Segunda Aula',
                                      style: TextStyle(
                                        color: Color(0xFF44A301),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (value) => setState(
                                      () => periodoAulaSelecionado = value,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSearchableDropdown<
                                      sala_model.Sala
                                    >(
                                      value: salaSelecionada,
                                      labelText: 'Selecione a Sala',
                                      items: salas,
                                      displayText:
                                          (sala) =>
                                              '${sala.numeroSala} - ${sala.qtdCadeiras} cadeiras',
                                      onChanged: (value) {
                                        setState(() => salaSelecionada = value);
                                      },
                                      validator:
                                          (value) =>
                                              value == null
                                                  ? 'Selecione uma sala'
                                                  : null,
                                      fieldKey: _salaFieldKey,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF44A301),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          () => Navigator.pushNamed(
                                            context,
                                            '/criarsala',
                                          ),
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Criar nova sala',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // NOVO: Seção de múltiplos cursos
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF44A301,
                                  ).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF44A301,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.school,
                                          color: Color(0xFF44A301),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Selecionar Cursos',
                                          style: TextStyle(
                                            color: Color(0xFF44A301),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${cursosSelecionados.length} curso(s) selecionado(s)',
                                          style: const TextStyle(
                                            color: Color(0xFF44A301),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
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
                                                cursos
                                                    .where(
                                                      (curso) =>
                                                          !cursosSelecionados
                                                              .any(
                                                                (c) =>
                                                                    c.id ==
                                                                    curso.id,
                                                              ),
                                                    )
                                                    .toList(),
                                            displayText:
                                                (curso) =>
                                                    '${curso.curso} - ${curso.semestre ?? "Semestre?"} - ${curso.periodo != null ? periodoToString(curso.periodo) : "Período?"}',
                                            onChanged: (value) {
                                              if (value != null) {
                                                adicionarCurso(value);
                                                // Limpar o dropdown
                                                setState(() {
                                                  cursoSearchText = '';
                                                  isCursoDropdownOpen = false;
                                                });
                                              }
                                            },
                                            validator:
                                                (value) =>
                                                    null, // Sem validação aqui
                                            fieldKey: _cursoFieldKey,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF44A301),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: IconButton(
                                            onPressed:
                                                () => Navigator.pushNamed(
                                                  context,
                                                  '/criarcurso',
                                                ),
                                            icon: const Icon(
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
                              const SizedBox(height: 20),
                              // NOVO: Exibir cursos selecionados
                              _buildCursosSelecionados(),
                              const SizedBox(height: 20),
                              // NOVO: Verificar se há cursos selecionados
                              if (cursosSelecionados.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Selecione pelo menos um curso para continuar',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              const SizedBox(height: 28),
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
                                      icon: const Icon(
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
                                        'Agendar ${cursosSelecionados.length} curso(s)',
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
                  ],
                ),
      ),
    );
  }
}
