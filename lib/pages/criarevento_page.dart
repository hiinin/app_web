import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

class CriarEventoPage extends StatefulWidget {
  const CriarEventoPage({super.key});

  @override
  State<CriarEventoPage> createState() => _CriarEventoPageState();
}

class _CriarEventoPageState extends State<CriarEventoPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  final TextEditingController _nomeEventoController = TextEditingController();

  // Campos do evento
  String? nomeEvento;
  String? descricao;
  DateTime? dataEvento;
  String? periodoAulaSelecionado;

  // Campos relacionados ao agendamento
  sala_model.Sala? salaSelecionada;
  curso_model.Curso? cursoSelecionado;
  Map<String, dynamic>? materiaSelecionada;
  Map<String, dynamic>? professorSelecionado;

  // Listas de dados
  List<sala_model.Sala> salas = [];
  List<curso_model.Curso> cursos = [];
  List<Map<String, dynamic>> materias = [];
  List<Map<String, dynamic>> professores = [];

  // Controles para pesquisa nos dropdowns
  bool isSalaDropdownOpen = false;
  bool isCursoDropdownOpen = false;
  bool isMateriaDropdownOpen = false;
  bool isProfessorDropdownOpen = false;
  String salaSearchText = '';
  String cursoSearchText = '';
  String materiaSearchText = '';
  String professorSearchText = '';

  // Overlay entries para dropdowns
  OverlayEntry? _overlayEntry;

  // NOVO: Controles para dropdowns individuais
  Map<String, bool> dropdownsAbertos = {};
  Map<String, String> textosPesquisa = {};

  // GlobalKeys para posicionamento dos dropdowns
  final GlobalKey _salaFieldKey = GlobalKey();
  final GlobalKey _cursoFieldKey = GlobalKey();
  final GlobalKey _materiaFieldKey = GlobalKey();
  final GlobalKey _professorFieldKey = GlobalKey();
  final GlobalKey _aulaFieldKey =
      GlobalKey(); // NOVO: Key para o dropdown de aula

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: Página de evento carregada - TESTE DE MUDANÇAS');
    carregarDados();
  }

  @override
  void dispose() {
    // Fechar todos os dropdowns ao sair da tela
    print('DEBUG: Fechando dropdowns ao sair da tela - Evento');
    isCursoDropdownOpen = false;
    isSalaDropdownOpen = false;
    isMateriaDropdownOpen = false;
    isProfessorDropdownOpen = false;
    dropdownsAbertos.clear(); // Limpar todos os dropdowns (incluindo aula)
    textosPesquisa.clear();

    // Fechar overlay
    _overlayEntry?.remove();
    _overlayEntry = null;

    _nomeEventoController.dispose();
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
        cursos.sort(
          (a, b) => a.curso.toLowerCase().compareTo(b.curso.toLowerCase()),
        );
        professores = List<Map<String, dynamic>>.from(
          responseProfessores as List,
        );
        materias = [];
        materiaSelecionada = null;
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
      materias = [];
      materiaSelecionada = null;
      professorSelecionado = null;
      professores = [];
      isLoading = true;
    });
    try {
      final response = await supabase
          .from('materias')
          .select()
          .eq('curso_id', cursoId);
      setState(() {
        materias = List<Map<String, dynamic>>.from(response as List);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar matérias: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> carregarProfessoresPorMateria(int materiaId) async {
    setState(() {
      professores = [];
      professorSelecionado = null;
      isLoading = true;
    });
    try {
      // Busca os professores associados à matéria através da tabela professor_materias
      final response = await supabase
          .from('professor_materias')
          .select('professor_id, professores!inner(id, nome_professor)')
          .eq('materia_id', materiaId);

      setState(() {
        professores =
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

  Widget _buildSearchableDropdown<T>({
    required T? value,
    required String labelText,
    required List<T> items,
    required String Function(T) displayText,
    required Function(T?) onChanged,
    required String? Function(T?) validator,
    required GlobalKey fieldKey,
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
      if (fieldKey == _materiaFieldKey) {
        isOpen = isMateriaDropdownOpen;
        searchText = materiaSearchText;
      } else {
        isOpen = isProfessorDropdownOpen;
        searchText = professorSearchText;
      }
    }

    // Sem validação sequencial, todos os campos sempre habilitados
    bool isEnabled = true;

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

      double topPosition = 100;
      if (fieldKey.currentContext != null) {
        final renderBox =
            fieldKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        topPosition = position.dy + 60;

        final screenHeight = MediaQuery.of(context).size.height;
        final availableSpaceBelow = screenHeight - topPosition;
        if (availableSpaceBelow < 400) {
          topPosition = position.dy - 350;
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
                          if (fieldKey == _materiaFieldKey) {
                            isMateriaDropdownOpen = false;
                            materiaSearchText = '';
                          } else {
                            isProfessorDropdownOpen = false;
                            professorSearchText = '';
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
                                  if (fieldKey == _materiaFieldKey) {
                                    isMateriaDropdownOpen = false;
                                    materiaSearchText = '';
                                  } else {
                                    isProfessorDropdownOpen = false;
                                    professorSearchText = '';
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
                    if (fieldKey == _materiaFieldKey) {
                      isMateriaDropdownOpen = !isMateriaDropdownOpen;
                      if (!isMateriaDropdownOpen) {
                        materiaSearchText = '';
                        _hideOverlay();
                      } else {
                        _showOverlay();
                      }
                    } else {
                      isProfessorDropdownOpen = !isProfessorDropdownOpen;
                      if (!isProfessorDropdownOpen) {
                        professorSearchText = '';
                        _hideOverlay();
                      } else {
                        _showOverlay();
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
                  ? const Color(0xFFE8F5E8)
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
                        decoration: const InputDecoration(
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
                              if (fieldKey == _materiaFieldKey) {
                                materiaSearchText = text;
                              } else {
                                professorSearchText = text;
                              }
                            }
                          });
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
                                      : const Color(0xFF66BB6A))
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
                        color: const Color(0xFFE8F5E8),
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
      onTap: () {
        setState(() {
          dropdownsAbertos['aula'] = !(dropdownsAbertos['aula'] ?? false);
          if (!(dropdownsAbertos['aula'] ?? false)) {
            textosPesquisa['aula'] = '';
            _hideAulaOverlay();
          } else {
            _showAulaOverlay();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF44A301)),
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
                      color: const Color(0xFF44A301).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    periodoAulaSelecionado ?? 'Selecione uma opção',
                    style: TextStyle(
                      color:
                          periodoAulaSelecionado != null
                              ? const Color(0xFF44A301)
                              : const Color(0xFF44A301).withOpacity(0.5),
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
              color: const Color(0xFF44A301),
            ),
          ],
        ),
      ),
    );
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

  Future<void> salvarEvento() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    // Pega os valores dos controllers
    nomeEvento = _nomeEventoController.text;
    descricao = ''; // Campo removido, mas mantido para compatibilidade

    if (dataEvento == null ||
        periodoAulaSelecionado == null ||
        cursoSelecionado == null ||
        materiaSelecionada == null ||
        professorSelecionado == null ||
        salaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final dataFormatada =
          '${dataEvento!.year.toString().padLeft(4, '0')}-${dataEvento!.month.toString().padLeft(2, '0')}-${dataEvento!.day.toString().padLeft(2, '0')}';

      // Usa o período do curso selecionado
      final periodoCurso =
          cursoSelecionado!.periodo; // 1=Matutino, 2=Vespertino, 3=Noturno

      // 1. Verifica quantos agendamentos já existem para a sala nesse dia e período
      final agendamentosSala = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('periodo', periodoCurso);

      if (agendamentosSala.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Essa sala já atingiu o limite de 6 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
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
          .eq('periodo', periodoCurso)
          .eq('aula_periodo', periodoAulaSelecionado)
          .eq(
            'tipo_agendamento',
            'E',
          ); // Verifica apenas agendamentos do tipo Evento

      if (agendamentosSalaPeriodoTipo.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Essa sala já atingiu o limite de 2 eventos para o período "$periodoAulaSelecionado" no dia ${dataFormatada.split('-').reversed.join('/')}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 3. Verifica quantos agendamentos já existem para este curso nesse dia
      final agendamentosCurso = await supabase
          .from('agendamento')
          .select('id, tipo_agendamento, aula_periodo')
          .eq('curso_id', cursoSelecionado!.id)
          .eq('dia', dataFormatada);

      if (agendamentosCurso.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Este curso já atingiu o limite de 2 agendamentos para o dia ${dataFormatada.split('-').reversed.join('/')}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // Verificar se já existe qualquer tipo de agendamento para este curso, dia e sala
      final agendamentoExistente =
          await supabase
              .from('agendamento')
              .select('id, tipo_agendamento, aula_periodo')
              .eq('curso_id', cursoSelecionado!.id)
              .eq('dia', dataFormatada)
              .eq('sala_id', salaSelecionada!.id)
              .eq('aula_periodo', periodoAulaSelecionado)
              .maybeSingle();

      if (agendamentoExistente != null) {
        String tipoExistente = '';
        switch (agendamentoExistente['tipo_agendamento']) {
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
              'Não é possível criar evento. Já existte uma $tipoExistente cadastrada para este curso, sala e dia ${dataFormatada.split('-').reversed.join('/')}.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // 4. Verifica se há conflito de horário com outros tipos de agendamento (aula, prova, evento)
      print('DEBUG - Iniciando verificação de conflitos para evento...');
      print('DEBUG - Parâmetros da consulta:');
      print('  - Sala ID: ${salaSelecionada!.id}');
      print('  - Data: $dataFormatada');
      print('  - Aula período: $periodoAulaSelecionado');

      final conflitosHorario = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada)
          .eq('aula_periodo', periodoAulaSelecionado);

      print('DEBUG - Conflitos encontrados: $conflitosHorario');
      print('DEBUG - Quantidade de conflitos: ${conflitosHorario.length}');

      // Vamos verificar se há agendamentos na sala para este dia
      final todosAgendamentosSala = await supabase
          .from('agendamento')
          .select()
          .eq('sala_id', salaSelecionada!.id)
          .eq('dia', dataFormatada);

      print(
        'DEBUG - Todos os agendamentos da sala para este dia: $todosAgendamentosSala',
      );
      print(
        'DEBUG - Quantidade total de agendamentos na sala: ${todosAgendamentosSala.length}',
      );

      if (conflitosHorario.isNotEmpty) {
        // Verifica se já existe um agendamento do mesmo tipo (evento) no mesmo horário
        final tiposExistentes =
            conflitosHorario.map((a) => a['tipo_agendamento']).toSet();

        if (tiposExistentes.contains('E')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Já existe um evento agendado para este horário.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
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

      // Salva na tabela agendamento
      await supabase.from('agendamento').insert({
        'curso_id': cursoSelecionado!.id,
        'materia_id': materiaSelecionada!['id'],
        'professor_id': professorSelecionado!['id'],
        'sala_id': salaSelecionada!.id,
        'dia': dataFormatada,
        'aula_periodo': periodoAulaSelecionado,
        'periodo': periodoCurso,
        'nome_evento': nomeEvento,
        'descricao_evento': descricao,
        'tipo_agendamento': 'E', // E = Evento
      });

      // Limpa os controllers
      _nomeEventoController.clear();

      setState(() {
        dataEvento = null;
        periodoAulaSelecionado = null;
        salaSelecionada = null;
        cursoSelecionado = null;
        materiaSelecionada = null;
        professorSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento salvo com sucesso!')),
      );

      carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar evento: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final currentMonth = dataEvento ?? now;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    // Ajusta o weekday para começar no domingo (0) em vez de segunda (1)
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
      final isSelected =
          dataEvento != null &&
          dataEvento!.year == currentDate.year &&
          dataEvento!.month == currentDate.month &&
          dataEvento!.day == currentDate.day;
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
                        dataEvento = currentDate;
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
        const SizedBox(height: 20),
        // Calendário completo em uma caixa
        Container(
          height: 420, // Altura fixa para manter consistência
          padding: const EdgeInsets.all(20),
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
            children: [
              // Cabeçalho do mês
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        dataEvento = DateTime(
                          currentMonth.year,
                          currentMonth.month - 1,
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
                    '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF44A301),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        dataEvento = DateTime(
                          currentMonth.year,
                          currentMonth.month + 1,
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

              // Dias da semana
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

  bool _todosCamposPreenchidos() {
    return dataEvento != null &&
        periodoAulaSelecionado != null &&
        cursoSelecionado != null &&
        materiaSelecionada != null &&
        professorSelecionado != null &&
        salaSelecionada != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF44A301),
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Novo Evento',
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
                    padding: const EdgeInsets.only(left: 16.0),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Calendário à esquerda (45% da tela)
            Expanded(
              flex: 45,
              child: Container(
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E8),
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
                    // Título do calendário
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Selecione o dia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF44A301),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCustomCalendar(),
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
            // Formulário à direita (53% da tela)
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
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Preencha os dados do evento',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                              letterSpacing: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Nome do evento
                          TextFormField(
                            controller: _nomeEventoController,
                            decoration: InputDecoration(
                              labelText: 'Nome do Evento *',
                              labelStyle: const TextStyle(
                                color: Color(0xFF44A301),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE8F5E8),
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
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe o nome do evento'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          // Aula (período)
                          _buildAulaDropdown(),
                          const SizedBox(height: 16),
                          // Curso
                          Row(
                            children: [
                              Expanded(
                                child: _buildSearchableDropdown<
                                  curso_model.Curso
                                >(
                                  value: cursoSelecionado,
                                  labelText: 'Selecione o Curso *',
                                  items: cursos,
                                  displayText:
                                      (curso) =>
                                          '${curso.curso} - ${curso.semestre ?? "Semestre?"} - ${periodoToString(curso.periodo)}',
                                  onChanged: (value) {
                                    setState(() {
                                      cursoSelecionado = value;
                                      materiaSelecionada = null;
                                      professorSelecionado = null;
                                      materias = [];
                                      professores = [];
                                    });
                                    if (value != null) {
                                      carregarMateriasPorCurso(value.id);
                                    }
                                  },
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Selecione um curso'
                                              : null,
                                  fieldKey: _cursoFieldKey,
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
                          const SizedBox(height: 16),
                          // Matéria
                          Row(
                            children: [
                              Expanded(
                                child: _buildSearchableDropdown<
                                  Map<String, dynamic>
                                >(
                                  value: materiaSelecionada,
                                  labelText: 'Selecione a Matéria *',
                                  items: materias,
                                  displayText:
                                      (materia) => materia['nome'] ?? '',
                                  onChanged: (value) {
                                    setState(() {
                                      materiaSelecionada = value;
                                      professorSelecionado = null;
                                      professores = [];
                                    });
                                    if (value != null) {
                                      carregarProfessoresPorMateria(
                                        value['id'],
                                      );
                                    }
                                  },
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Selecione uma matéria'
                                              : null,
                                  fieldKey: _materiaFieldKey,
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
                                      () => Navigator.pushNamed(
                                        context,
                                        '/criarmateria',
                                      ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Criar nova matéria',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Professor
                          Row(
                            children: [
                              Expanded(
                                child: _buildSearchableDropdown<
                                  Map<String, dynamic>
                                >(
                                  value: professorSelecionado,
                                  labelText: 'Selecione o Professor *',
                                  items: professores,
                                  displayText:
                                      (professor) =>
                                          professor['nome_professor'] ?? '',
                                  onChanged: (value) {
                                    setState(() {
                                      professorSelecionado = value;
                                    });
                                  },
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Selecione um professor'
                                              : null,
                                  fieldKey: _professorFieldKey,
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
                                      () => Navigator.pushNamed(
                                        context,
                                        '/criarprofessor',
                                      ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Criar novo professor',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Sala
                          Row(
                            children: [
                              Expanded(
                                child: _buildSearchableDropdown<
                                  sala_model.Sala
                                >(
                                  value: salaSelecionada,
                                  labelText: 'Selecione a Sala *',
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
                              const SizedBox(width: 12),
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
                                    textStyle: const TextStyle(fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/listalocacao',
                                      ),
                                  label: const Text('Ver agendamentos'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF44A301),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: isLoading ? null : salvarEvento,
                                  label: const Text('Salvar Evento'),
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
            ),
          ],
        ),
      ),
    );
  }
}
