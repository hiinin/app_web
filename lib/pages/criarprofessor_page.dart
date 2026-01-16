import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../functions/drawer_helper.dart';

class CriarProfessorPage extends StatefulWidget {
  @override
  State<CriarProfessorPage> createState() => _CriarProfessorPageState();
}

class MultiSelectItem {
  final int value;
  final String label;

  MultiSelectItem(this.value, this.label);
}

class _CriarProfessorPageState extends State<CriarProfessorPage> {
  final supabase = Supabase.instance.client;

  // Variáveis de estado:
  List<Map<String, dynamic>> professores = [];
  int? professorSelecionado;
  List<int> turmasSelecionadas = [];
  final TextEditingController _nomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String filtroProfessor = "";
  List<Map<String, dynamic>> cursos = [];

  @override
  void initState() {
    super.initState();
    _carregarCursos();
    _carregarProfessores();
  }

  // Função para carregar cursos (turmas):
  Future<void> _carregarCursos() async {
    final res = await supabase
        .from('cursos')
        .select('id, curso, periodo, semestre');
    setState(() {
      cursos = List<Map<String, dynamic>>.from(res);
    });
  }

  // Carregar professores com turmas associadas
  Future<void> _carregarProfessores() async {
    setState(() => isLoading = true);
    final res = await supabase
        .from('professores')
        .select(
          'id, nome_professor, professor_turmas(cursos(id, curso, periodo, semestre))',
        )
        .order('id', ascending: false);
    setState(() {
      professores = List<Map<String, dynamic>>.from(res);
      isLoading = false;
    });
  }

  // Salvar novo professor
  Future<void> _salvarProfessor() async {
    if (!_formKey.currentState!.validate()) return;
    await supabase.from('professores').insert({
      'nome_professor': _nomeController.text.trim(),
    });
    _nomeController.clear();
    await _carregarProfessores();
  }

  // Mostrar diálogo para seleção múltipla de turmas
  Future<void> _mostrarDialogoTurmas(BuildContext context) async {
    Set<int> turmasSelecionadasTemp = Set.from(turmasSelecionadas);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Selecionar Turmas'),
              content: SizedBox(
                width: double.maxFinite,
                child:
                    cursos.isEmpty
                        ? const Text('Nenhuma turma disponível')
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: cursos.length,
                          itemBuilder: (context, index) {
                            final curso = cursos[index];
                            String periodoStr = '';
                            if (curso['periodo'] != null) {
                              switch (curso['periodo']) {
                                case 1:
                                  periodoStr = ' - Matutino';
                                  break;
                                case 2:
                                  periodoStr = ' - Vespertino';
                                  break;
                                case 3:
                                  periodoStr = ' - Noturno';
                                  break;
                              }
                            }
                            String semestreStr =
                                curso['semestre'] != null
                                    ? ' - ${curso['semestre']}'
                                    : '';
                            final cursoId = curso['id'] as int;
                            final isSelected = turmasSelecionadasTemp.contains(
                              cursoId,
                            );

                            return CheckboxListTile(
                              title: Text(
                                '${curso['curso'] ?? ''}$periodoStr$semestreStr',
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    turmasSelecionadasTemp.add(cursoId);
                                  } else {
                                    turmasSelecionadasTemp.remove(cursoId);
                                  }
                                });
                              },
                            );
                          },
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF44A301),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      turmasSelecionadas = turmasSelecionadasTemp.toList();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Associar turmas ao professor selecionado
  Future<void> _associarTurmas() async {
    if (professorSelecionado == null || turmasSelecionadas.isEmpty) return;

    // Busca turmas já associadas
    final existentes = await supabase
        .from('professor_turmas')
        .select('curso_id')
        .eq('professor_id', professorSelecionado);

    final idsExistentes = existentes.map((e) => e['curso_id'] as int).toSet();

    // Adiciona apenas as novas
    for (final cursoId in turmasSelecionadas) {
      if (!idsExistentes.contains(cursoId)) {
        await supabase.from('professor_turmas').insert({
          'professor_id': professorSelecionado,
          'curso_id': cursoId,
        });
      }
    }

    turmasSelecionadas = [];
    await _carregarProfessores();
    setState(() {});
  }

  // Excluir professor
  Future<void> _excluirProfessor(int id) async {
    await supabase.from('professores').delete().eq('id', id);
    await _carregarProfessores();
  }

  Future<void> excluirProfessor(int professorId) async {
    try {
      await supabase
          .from('professor_turmas')
          .delete()
          .eq('professor_id', professorId);

      await supabase.from('professores').delete().eq('id', professorId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professor excluído com sucesso!')),
      );
      await _carregarProfessores();
      setState(() {
        professorSelecionado = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
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
          'Novo Professor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: buildAppDrawer(context),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ajusta a largura baseado no tamanho da tela
          final isSmallScreen = constraints.maxWidth < 800;
          final leftWidth =
              isSmallScreen
                  ? constraints.maxWidth * 0.45
                  : constraints.maxWidth * 0.4;

          return Row(
            children: [
              // Formulário à esquerda
              Container(
                width: leftWidth,
                height: constraints.maxHeight - 80,
                color: const Color(0xFFE8F5E8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // NOVO PROFESSOR
                        const Text(
                          'Novo Professor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF44A301),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Professor',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Digite o nome'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44A301),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: isLoading ? null : _salvarProfessor,
                          label: const Text('Adicionar'),
                        ),
                        const SizedBox(height: 40),

                        // ASSOCIAR PROFESSOR E TURMA
                        const Text(
                          'Associar Professor à Turma',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF44A301),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<int>(
                          value:
                              professores.any(
                                    (p) => p['id'] == professorSelecionado,
                                  )
                                  ? professorSelecionado
                                  : null,
                          items:
                              professores
                                  .map(
                                    (p) => DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(p['nome_professor'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => professorSelecionado = v),
                          decoration: const InputDecoration(
                            labelText: 'Professor',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.checklist),
                          label: const Text('Selecionar Turmas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF44A301),
                            side: const BorderSide(color: Color(0xFF44A301)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () => _mostrarDialogoTurmas(context),
                        ),
                        const SizedBox(height: 8),

                        // Exibe as turmas selecionadas com opção de remover
                        Wrap(
                          spacing: 8,
                          children:
                              turmasSelecionadas.map((id) {
                                final curso = cursos.firstWhere(
                                  (c) => c['id'] == id,
                                  orElse: () => {},
                                );
                                String periodoStr = '';
                                if (curso['periodo'] != null) {
                                  switch (curso['periodo']) {
                                    case 1:
                                      periodoStr = ' - Matutino';
                                      break;
                                    case 2:
                                      periodoStr = ' - Vespertino';
                                      break;
                                    case 3:
                                      periodoStr = ' - Noturno';
                                      break;
                                  }
                                }
                                String semestreStr =
                                    curso['semestre'] != null
                                        ? ' - ${curso['semestre']}'
                                        : '';
                                return Chip(
                                  label: Text(
                                    '${curso['curso'] ?? ''}$periodoStr$semestreStr',
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      turmasSelecionadas.remove(id);
                                    });
                                  },
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44A301),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed:
                              (professorSelecionado != null &&
                                      turmasSelecionadas.isNotEmpty)
                                  ? _associarTurmas
                                  : null,
                          label: const Text('Associar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Lista de professores à direita
              Expanded(
                child: Container(
                  height: constraints.maxHeight - 80,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Professores cadastrados',
                                style: TextStyle(
                                  color: Color(0xFF44A301),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Pesquisar professor',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      filtroProfessor = value.toLowerCase();
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child:
                                    professores.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'Nenhum professor cadastrado.',
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                        : ListView.separated(
                                          itemCount:
                                              professores
                                                  .where(
                                                    (p) =>
                                                        filtroProfessor
                                                            .isEmpty ||
                                                        (p['nome_professor'] ??
                                                                '')
                                                            .toLowerCase()
                                                            .contains(
                                                              filtroProfessor,
                                                            ),
                                                  )
                                                  .length,
                                          separatorBuilder:
                                              (_, __) =>
                                                  const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final listaFiltrada =
                                                professores
                                                    .where(
                                                      (p) =>
                                                          filtroProfessor
                                                              .isEmpty ||
                                                          (p['nome_professor'] ??
                                                                  '')
                                                              .toLowerCase()
                                                              .contains(
                                                                filtroProfessor,
                                                              ),
                                                    )
                                                    .toList();
                                            final p = listaFiltrada[index];
                                            final turmasList =
                                                (p['professor_turmas'] as List?)
                                                    ?.map((e) {
                                                      final curso = e['cursos'];
                                                      String periodoStr = '';
                                                      if (curso?['periodo'] !=
                                                          null) {
                                                        switch (curso['periodo']) {
                                                          case 1:
                                                            periodoStr =
                                                                ' - Matutino';
                                                            break;
                                                          case 2:
                                                            periodoStr =
                                                                ' - Vespertino';
                                                            break;
                                                          case 3:
                                                            periodoStr =
                                                                ' - Noturno';
                                                            break;
                                                        }
                                                      }
                                                      String semestreStr =
                                                          curso?['semestre'] !=
                                                                  null
                                                              ? ' - ${curso['semestre']}'
                                                              : '';
                                                      return {
                                                        'id': curso?['id'],
                                                        'nome':
                                                            '${curso?['curso'] ?? ''}$periodoStr$semestreStr',
                                                        'associacaoId':
                                                            e['id'], // id da associação, se existir
                                                      };
                                                    })
                                                    .where(
                                                      (t) =>
                                                          t['id'] != null &&
                                                          t['nome'] != null,
                                                    )
                                                    .toList() ??
                                                [];

                                            bool isExpanded =
                                                p['isExpanded'] == true;

                                            return StatefulBuilder(
                                              builder: (context, setTileState) {
                                                return Card(
                                                  color: Colors.grey[100],
                                                  elevation: 1,
                                                  child: Column(
                                                    children: [
                                                      ListTile(
                                                        title: Text(
                                                          p['nome_professor'] ??
                                                              '',
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                        trailing: SizedBox(
                                                          width: 80,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                icon: Icon(
                                                                  isExpanded
                                                                      ? Icons
                                                                          .expand_less
                                                                      : Icons
                                                                          .expand_more,
                                                                  size: 20,
                                                                ),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    professores[index]['isExpanded'] =
                                                                        !isExpanded;
                                                                  });
                                                                },
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons.delete,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                  size: 20,
                                                                ),
                                                                onPressed:
                                                                    () => _excluirProfessor(
                                                                      p['id']
                                                                          as int,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (isExpanded)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 12,
                                                                right: 12,
                                                                bottom: 8,
                                                              ),
                                                          child:
                                                              turmasList
                                                                      .isNotEmpty
                                                                  ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children:
                                                                        turmasList.map((
                                                                          t,
                                                                        ) {
                                                                          return Padding(
                                                                            padding: const EdgeInsets.symmetric(
                                                                              vertical:
                                                                                  2.0,
                                                                            ),
                                                                            child: Row(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    t['nome'] ??
                                                                                        '',
                                                                                    style: const TextStyle(
                                                                                      color:
                                                                                          Colors.black54,
                                                                                      fontSize:
                                                                                          13,
                                                                                    ),
                                                                                    overflow:
                                                                                        TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                                IconButton(
                                                                                  icon: const Icon(
                                                                                    Icons.close,
                                                                                    color:
                                                                                        Colors.red,
                                                                                    size:
                                                                                        16,
                                                                                  ),
                                                                                  tooltip:
                                                                                      'Remover associação',
                                                                                  onPressed: () async {
                                                                                    // Remove associação professor-turma
                                                                                    await supabase
                                                                                        .from(
                                                                                          'professor_turmas',
                                                                                        )
                                                                                        .delete()
                                                                                        .eq(
                                                                                          'professor_id',
                                                                                          p['id'],
                                                                                        )
                                                                                        .eq(
                                                                                          'curso_id',
                                                                                          t['id'],
                                                                                        );
                                                                                    await _carregarProfessores();
                                                                                    setState(
                                                                                      () {},
                                                                                    );
                                                                                  },
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                  )
                                                                  : const Text(
                                                                    'Nenhuma turma associada',
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .black54,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MultiSelectChipField extends StatelessWidget {
  final List<MultiSelectItem> items;
  final Function(List<dynamic>) onTap;
  final List<dynamic> initialValue;
  final String title;
  final Color headerColor;
  final Color selectedColor;
  final TextStyle? titleStyle;
  final TextStyle? headerStyle;
  final double? chipPadding;
  final double? chipSpacing;
  final Color? chipColor;
  final Color? disabledColor;
  final bool isDense;
  final bool isWrapped;
  final FormFieldValidator<List<dynamic>>? validator;

  const MultiSelectChipField({
    Key? key,
    required this.items,
    required this.onTap,
    this.initialValue = const [],
    this.title = "",
    this.headerColor = Colors.transparent,
    this.selectedColor = const Color(0xFF44A301),
    this.titleStyle,
    this.headerStyle,
    this.chipPadding,
    this.chipSpacing,
    this.chipColor,
    this.disabledColor,
    this.isDense = false,
    this.isWrapped = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> selectedItems = initialValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: chipSpacing ?? 8.0,
          runSpacing: chipPadding ?? 4.0,
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedItems.contains(item.value);
            return ChoiceChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  selectedItems.add(item.value);
                } else {
                  selectedItems.remove(item.value);
                }
                onTap(selectedItems);
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: chipColor ?? Colors.grey[200],
              selectedColor: selectedColor,
              disabledColor: disabledColor ?? Colors.grey,
              padding: EdgeInsets.symmetric(
                vertical: isDense ? 4.0 : 8.0,
                horizontal: 12.0,
              ),
            );
          }),
        ),
      ],
    );
  }
}
