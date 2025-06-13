import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Map<String, dynamic>> materias = [];
  List<Map<String, dynamic>> professores = [];
  int? professorSelecionado;
  List<int> materiasSelecionadas = [];
  final TextEditingController _nomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  // Adicione estas variáveis de estado:
  String filtroProfessor = "";
  int? cursoSelecionado;
  List<Map<String, dynamic>> cursos = [];
  List<Map<String, dynamic>> materiasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarCursos();
    _carregarMaterias();
    _carregarProfessores();
  }

  // Função para carregar cursos:
  Future<void> _carregarCursos() async {
    final res = await supabase.from('cursos').select('id, curso');
    setState(() {
      cursos = List<Map<String, dynamic>>.from(res);
    });
  }

  // Carregar matérias
  Future<void> _carregarMaterias({int? cursoId}) async {
    var query = supabase.from('materias').select('id, nome, curso_id');
    if (cursoId != null) {
      query = query.eq('curso_id', cursoId);
    }
    final res = await query;
    setState(() {
      materias = List<Map<String, dynamic>>.from(res);
      materiasFiltradas = materias;
    });
  }

  // Carregar professores com matérias associadas
  Future<void> _carregarProfessores() async {
    setState(() => isLoading = true);
    final res = await supabase
        .from('professores')
        .select('id, nome_professor, professor_materias(materias(id, nome))')
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

  // Associar matérias ao professor selecionado
  Future<void> _associarMaterias() async {
    if (professorSelecionado == null || materiasSelecionadas.isEmpty) return;

    // Busca matérias já associadas
    final existentes = await supabase
        .from('professor_materias')
        .select('materia_id')
        .eq('professor_id', professorSelecionado);

    final idsExistentes = existentes.map((e) => e['materia_id'] as int).toSet();

    // Adiciona apenas as novas
    for (final materiaId in materiasSelecionadas) {
      if (!idsExistentes.contains(materiaId)) {
        await supabase.from('professor_materias').insert({
          'professor_id': professorSelecionado,
          'materia_id': materiaId,
        });
      }
    }

    materiasSelecionadas = [];
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
          .from('professor_materias')
          .delete()
          .eq('professor_id', professorId);

      await supabase.from('professores').delete().eq('id', professorId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Professor excluído com sucesso!')),
      );
      await _carregarProfessores();
      setState(() {
        professorSelecionado = null; // ou cursoSelecionado = null;
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
        backgroundColor: const Color(0xFF1E40AF),
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
                        'RH Painel',
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
              leading: const Icon(Icons.home, color: Color(0xFF1E40AF)),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF1E40AF)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF1E40AF)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),

            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF1E40AF)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
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
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Formulário à esquerda
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height - 80,
            color: const Color(0xFFE3EAFD),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NOVO PROFESSOR
                  const Text(
                    'Novo Professor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF297BD8),
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
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isLoading ? null : _salvarProfessor,
                    label: const Text('Adicionar'),
                  ),
                  const SizedBox(height: 40),

                  // ASSOCIAR PROFESSOR E MATÉRIA
                  const Text(
                    'Associar Professor à Matéria',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF297BD8),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    value:
                        professores.any((p) => p['id'] == professorSelecionado)
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
                    onChanged: (v) => setState(() => professorSelecionado = v),
                    decoration: const InputDecoration(
                      labelText: 'Professor',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: cursoSelecionado,
                    items:
                        cursos
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['curso'] ?? ''),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      setState(() {
                        cursoSelecionado = value;
                        materiasSelecionadas.clear();
                        materiasFiltradas = [];
                      });
                      await _carregarMaterias(cursoId: value);
                      setState(() {
                        materiasFiltradas =
                            materias; // Atualiza matérias filtradas após carregar
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Curso',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: null,
                    items:
                        materiasFiltradas
                            .map(
                              (m) => DropdownMenuItem<int>(
                                value: m['id'] as int,
                                child: Text(m['nome'] ?? ''),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (cursoSelecionado == null)
                            ? null // Desabilita se não selecionou curso
                            : (value) {
                              if (value != null &&
                                  !materiasSelecionadas.contains(value)) {
                                setState(() {
                                  materiasSelecionadas.add(value);
                                });
                              }
                            },
                    decoration: const InputDecoration(
                      labelText: 'Matérias (adicione uma por vez)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    disabledHint: const Text('Selecione um curso primeiro'),
                  ),
                  const SizedBox(height: 8),

                  // Exibe as matérias selecionadas com opção de remover
                  Wrap(
                    spacing: 8,
                    children:
                        materiasSelecionadas.map((id) {
                          final materia = materias.firstWhere(
                            (m) => m['id'] == id,
                            orElse: () => {},
                          );
                          return Chip(
                            label: Text(materia['nome'] ?? ''),
                            onDeleted: () {
                              setState(() {
                                materiasSelecionadas.remove(id);
                              });
                            },
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed:
                        (professorSelecionado != null &&
                                materiasSelecionadas.isNotEmpty)
                            ? _associarMaterias
                            : null,
                    label: const Text('Associar'),
                  ),
                ],
              ),
            ),
          ),
          // Lista de professores à direita
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height - 80,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professores cadastrados',
                            style: TextStyle(
                              color: Color(0xFF297BD8),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextField(
                              decoration: InputDecoration(
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
                                                    filtroProfessor.isEmpty ||
                                                    (p['nome_professor'] ?? '')
                                                        .toLowerCase()
                                                        .contains(
                                                          filtroProfessor,
                                                        ),
                                              )
                                              .length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final listaFiltrada =
                                            professores
                                                .where(
                                                  (p) =>
                                                      filtroProfessor.isEmpty ||
                                                      (p['nome_professor'] ??
                                                              '')
                                                          .toLowerCase()
                                                          .contains(
                                                            filtroProfessor,
                                                          ),
                                                )
                                                .toList();
                                        final p = listaFiltrada[index];
                                        final materiasList =
                                            (p['professor_materias'] as List?)
                                                ?.map(
                                                  (e) => {
                                                    'id': e['materias']?['id'],
                                                    'nome':
                                                        e['materias']?['nome'],
                                                    'associacaoId':
                                                        e['id'], // id da associação, se existir
                                                  },
                                                )
                                                .where(
                                                  (m) =>
                                                      m['id'] != null &&
                                                      m['nome'] != null,
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
                                                      p['nome_professor'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            isExpanded
                                                                ? Icons
                                                                    .expand_less
                                                                : Icons
                                                                    .expand_more,
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
                                                            color: Colors.red,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _excluirProfessor(
                                                                    p['id']
                                                                        as int,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isExpanded)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 16,
                                                            right: 16,
                                                            bottom: 12,
                                                          ),
                                                      child:
                                                          materiasList
                                                                  .isNotEmpty
                                                              ? Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children:
                                                                    materiasList.map((
                                                                      m,
                                                                    ) {
                                                                      return Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                            m['nome'] ??
                                                                                '',
                                                                            style: const TextStyle(
                                                                              color:
                                                                                  Colors.black54,
                                                                              fontSize:
                                                                                  14,
                                                                            ),
                                                                          ),
                                                                          IconButton(
                                                                            icon: const Icon(
                                                                              Icons.close,
                                                                              color:
                                                                                  Colors.red,
                                                                              size:
                                                                                  18,
                                                                            ),
                                                                            tooltip:
                                                                                'Remover associação',
                                                                            onPressed: () async {
                                                                              // Remove associação professor-matéria
                                                                              await supabase
                                                                                  .from(
                                                                                    'professor_materias',
                                                                                  )
                                                                                  .delete()
                                                                                  .eq(
                                                                                    'professor_id',
                                                                                    p['id'],
                                                                                  )
                                                                                  .eq(
                                                                                    'materia_id',
                                                                                    m['id'],
                                                                                  );
                                                                              await _carregarProfessores();
                                                                              setState(
                                                                                () {},
                                                                              );
                                                                            },
                                                                          ),
                                                                        ],
                                                                      );
                                                                    }).toList(),
                                                              )
                                                              : const Text(
                                                                'Nenhuma matéria associada',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black54,
                                                                  fontSize: 14,
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
    this.selectedColor = Colors.blue,
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
