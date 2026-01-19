import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/curso.dart';
import '../functions/drawer_helper.dart';

class CriarMateriaPage extends StatefulWidget {
  const CriarMateriaPage({super.key});

  @override
  State<CriarMateriaPage> createState() => _CriarMateriaPageState();
}

// Adicione esta função no início do seu arquivo ou dentro da classe _CriarMateriaPageState
String periodoToString(int? periodo) {
  switch (periodo) {
    case 1:
      return 'Matutino';
    case 2:
      return 'Vespertino';
    case 3:
      return 'Noturno';
    default:
      return 'Período?';
  }
}

class _CriarMateriaPageState extends State<CriarMateriaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeMateriaController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _materias = [];
  List<Map<String, dynamic>> _materiasFiltradas = [];
  List<Curso> _cursos = [];
  Curso? _cursoSelecionado;
  bool _isLoading = false;
  bool _loadingMaterias = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buscarCursos();
    _buscarMaterias();
    _searchController.addListener(_filtrarMaterias);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarMaterias);
    _searchController.dispose();
    _scrollController.dispose();
    _nomeMateriaController.dispose();
    super.dispose();
  }

  Future<void> _buscarCursos() async {
    final data = await Supabase.instance.client.from('cursos').select();
    setState(() {
      _cursos = (data as List).map((e) => Curso.fromMap(e)).toList();
    });
  }

  Future<void> _buscarMaterias() async {
    setState(() => _loadingMaterias = true);
    try {
      final data = await Supabase.instance.client
          .from('materias')
          .select('id, nome, curso_id')
          .order('nome');
      final materias = List<Map<String, dynamic>>.from(data);
      final query = _searchController.text.trim().toLowerCase();
      final materiasFiltradas =
          query.isEmpty
              ? materias
              : materias.where((materia) {
                final nome = (materia['nome'] ?? '').toString().toLowerCase();
                return nome.contains(query);
              }).toList();
      setState(() {
        _materias = materias;
        _materiasFiltradas = materiasFiltradas;
        _loadingMaterias = false;
      });
    } catch (e) {
      setState(() => _loadingMaterias = false);
    }
  }

  void _filtrarMaterias() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _materiasFiltradas = _materias;
      } else {
        _materiasFiltradas =
            _materias.where((materia) {
              final nome = (materia['nome'] ?? '').toString().toLowerCase();
              return nome.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _salvarMateria() async {
    if (!_formKey.currentState!.validate() || _cursoSelecionado == null) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('materias').insert({
        'nome': _nomeMateriaController.text.trim(),
        'curso_id': _cursoSelecionado!.id,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matéria criada com sucesso!')),
      );
      _nomeMateriaController.clear();
      setState(() => _cursoSelecionado = null);
      await _buscarMaterias();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar matéria: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> excluirMateria(int materiaId) async {
    try {
      await Supabase.instance.client
          .from('materias')
          .delete()
          .eq('id', materiaId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matéria excluída com sucesso!'),
          backgroundColor: Color(0xFF44A301),
        ),
      );

      // Recarrega a lista após excluir
      await _buscarMaterias();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir matéria: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agrupa as matérias por curso_id
    final Map<int, List<Map<String, dynamic>>> materiasPorCurso = {};
    for (final materia in _materiasFiltradas) {
      final cursoId = materia['curso_id'] as int;
      materiasPorCurso.putIfAbsent(cursoId, () => []).add(materia);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF44A301), // Verde principal
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nova Matéria',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: buildAppDrawer(context),
      backgroundColor: const Color(0xFFF8FAFC), // igual criarcurso
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário à esquerda (40% da tela)
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height - 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE8F5E8), // Verde muito claro
                        Color(0xFFF0F8F0), // Verde quase branco
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nova Matéria',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF44A301),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nomeMateriaController,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          decoration: InputDecoration(
                            labelText: 'Nome da Matéria',
                            labelStyle: const TextStyle(
                              color: Color(0xFF388E3C),
                            ), // Verde escuro
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ), // Verde claro
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ), // Verde claro
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ), // Verde principal
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Informe o nome da matéria'
                                      : null,
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<Curso>(
                          value: _cursoSelecionado,
                          decoration: InputDecoration(
                            labelText: 'Curso',
                            labelStyle: const TextStyle(
                              color: Color(0xFF388E3C),
                            ), // Verde escuro
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ), // Verde claro
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ), // Verde claro
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ), // Verde principal
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          items:
                              _cursos
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.curso} - ${c.semestre ?? "Semestre?"} - ${periodoToString(c.periodo)}',
                                        style: const TextStyle(
                                          color: Color(0xFF388E3C),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (c) => setState(() => _cursoSelecionado = c),
                          validator:
                              (v) => v == null ? 'Selecione o curso' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: const Text('Salvar Matéria'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF44A301),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _isLoading ? null : _salvarMateria,
                        ),
                        const SizedBox(height: 32),
                        // Bloco quadrado para associação
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E8), // Verde claro suave
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFF44A301),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Deseja criar um novo professor?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF44A301),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.person_add,
                                            color: Colors.white,
                                          ),
                                          label: const Text('Novo Professor'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF388E3C,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
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
                                              '/criarprofessor',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Deseja criar uma nova turma?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF44A301),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.school,
                                            color: Colors.white,
                                          ),
                                          label: const Text('Nova Turma'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF388E3C,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
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
                                              '/criarcurso',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lista de matérias à direita (60% da tela)
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height - 80,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho da lista
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF44A301),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.book,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Matérias Criadas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _buscarMaterias,
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF44A301),
                            ),
                            tooltip: 'Atualizar lista',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Campo de busca
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '🔍 Buscar matérias...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF44A301),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filtrarMaterias();
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Lista de matérias
                      Expanded(
                        child:
                            _loadingMaterias
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _materiasFiltradas.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isNotEmpty
                                            ? 'Nenhuma matéria encontrada para "${_searchController.text}"'
                                            : 'Nenhuma matéria criada ainda',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_searchController
                                          .text
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tente usar termos diferentes ou limpar a busca',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: materiasPorCurso.length,
                                  itemBuilder: (context, index) {
                                    final cursoId = materiasPorCurso.keys
                                        .elementAt(index);
                                    final materiasDoCurso =
                                        materiasPorCurso[cursoId]!;
                                    final curso = _cursos.firstWhere(
                                      (c) => c.id == cursoId,
                                      orElse:
                                          () => Curso(
                                            id: cursoId,
                                            curso: 'Curso não encontrado',
                                            semestre: null,
                                            periodo: null,
                                          ),
                                    );

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Cabeçalho do curso
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF44A301,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF44A301,
                                                ).withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.school,
                                                  color: Color(0xFF44A301),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${curso.curso} - ${curso.semestre ?? "Semestre?"} - ${periodoToString(curso.periodo)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF44A301),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF44A301,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${materiasDoCurso.length} matéria${materiasDoCurso.length == 1 ? '' : 's'}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Lista de matérias do curso
                                          ...materiasDoCurso
                                              .map(
                                                (materia) => Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        spreadRadius: 1,
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF44A301,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.book,
                                                          color: Color(
                                                            0xFF44A301,
                                                          ),
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              materia['nome'] ??
                                                                  'Nome não informado',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                                color: Color(
                                                                  0xFF44A301,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'ID: ${materia['id']}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () async {
                                                          // Confirmação antes de excluir
                                                          final confirmar = await showDialog<
                                                            bool
                                                          >(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => AlertDialog(
                                                                  title: const Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .warning,
                                                                        color:
                                                                            Colors.orange,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Text(
                                                                        'Confirmar Exclusão',
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  content: Text(
                                                                    'Tem certeza que deseja excluir a matéria "${materia['nome']}"?',
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            context,
                                                                          ).pop(
                                                                            false,
                                                                          ),
                                                                      child: const Text(
                                                                        'Cancelar',
                                                                      ),
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            context,
                                                                          ).pop(
                                                                            true,
                                                                          ),
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                      ),
                                                                      child: const Text(
                                                                        'Excluir',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          );

                                                          if (confirmar ==
                                                              true) {
                                                            await excluirMateria(
                                                              materia['id'],
                                                            );
                                                          }
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip:
                                                            'Excluir matéria',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
