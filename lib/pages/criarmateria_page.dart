import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/curso.dart';

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

  Future<void> excluirProfessor(int professorId) async {
    await Supabase.instance.client
        .from('professores')
        .delete()
        .eq('id', professorId);
  
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Professor excluído com sucesso!')),
    );
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
        backgroundColor: const Color(0xFF1E40AF), // Azul principal
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A), // Azul escuro
                    Color(0xFF3B82F6), // Azul médio
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
              leading: const Icon(
                Icons.home,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_box,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(
                Icons.list_alt,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(
                Icons.meeting_room,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(
                Icons.school,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(
                Icons.book,
                color: Color(0xFF1E40AF), // Azul principal
              ),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(
                Icons.people,
                color: Color(0xFF1E40AF), // Azul principal
              ),
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
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Cinza muito claro/quase branco
      body: Row(
        children: [
          // Formulário à esquerda (40%)
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height - 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEFF6FF),
                  Color(0xFFDBEAFE),
                ], // Gradiente azul claro
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
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
                      color: Color(0xFF1E40AF), // Azul principal
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nomeMateriaController,
                    style: const TextStyle(color: Color(0xFF1E40AF)),
                    decoration: InputDecoration(
                      labelText: 'Nome da Matéria',
                      labelStyle: const TextStyle(
                        color: Color(0xFF64748B),
                      ), // Cinza azulado
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF93C5FD),
                        ), // Azul claro
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ), // Cinza muito claro
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 2,
                        ), // Azul médio
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
                        color: Color(0xFF64748B),
                      ), // Cinza azulado
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF93C5FD),
                        ), // Azul claro
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ), // Cinza muito claro
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 2,
                        ), // Azul médio
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 16,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF1E40AF)),
                    items:
                        _cursos
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${c.curso} - ${c.semestre ?? "Semestre?"} - ${periodoToString(c.periodo)}',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (c) => setState(() => _cursoSelecionado = c),
                    validator: (v) => v == null ? 'Selecione o curso' : null,
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
                      backgroundColor: const Color(0xFF1E40AF),
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
                    height: 200, // Aumenta a altura para ficar mais quadrado
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFE0F2FE), // Azul claro suave
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Color(0xFF38BDF8), width: 1.2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Deseja associar uma matéria nova ou existente a um professor?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
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
                          label: const Text('Associar Matéria a Professor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF059669), // Verde
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/criarprofessor');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lista de matérias à direita (restante da tela)
          Expanded(
            child: Container(
              height: MediaQuery.of(context).size.height - 80,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar matéria...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                      ), // Cinza azulado claro
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B), // Cinza azulado
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFFF1F5F9,
                      ), // Cinza azulado muito claro
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (_) => _filtrarMaterias(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Matérias cadastradas:',
                    style: TextStyle(
                      color: Color(0xFF1E40AF), // Azul principal
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Matéria',
                            style: TextStyle(
                              color: Color(0xFF475569), // Cinza escuro azulado
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Curso',
                          style: TextStyle(
                            color: Color(0xFF475569), // Cinza escuro azulado
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color(0xFFE2E8F0), // Cinza muito claro
                    thickness: 1,
                    height: 20,
                  ),
                  Expanded(
                    child:
                        _loadingMaterias
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF3B82F6),
                              ),
                            )
                            : _materiasFiltradas.isEmpty
                            ? const Center(
                              child: Text(
                                'Nenhuma matéria cadastrada.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            )
                            : ListView(
                              children:
                                  materiasPorCurso.entries.map((entry) {
                                    final curso = _cursos.firstWhere(
                                      (c) => c.id == entry.key,
                                      orElse:
                                          () => Curso(
                                            id: 0,
                                            curso: 'Curso?',
                                            semestre: '',
                                            periodo: 0,
                                          ),
                                    );
                                    final materiasDoCurso = entry.value;
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: ExpansionTile(
                                        title: Text(
                                          curso.curso,
                                          style: const TextStyle(
                                            color: Color(0xFF1E40AF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        children:
                                            materiasDoCurso.map((materia) {
                                              return ListTile(
                                                title: Text(
                                                  materia['nome'] ?? '',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1E293B),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Color(0xFFDC2626),
                                                    size: 22,
                                                  ),
                                                  tooltip: 'Excluir',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            backgroundColor:
                                                                Colors.white,
                                                            title: const Text(
                                                              'Excluir matéria',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF1E40AF,
                                                                ),
                                                              ),
                                                            ),
                                                            content: const Text(
                                                              'Tem certeza que deseja excluir esta matéria?',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF475569,
                                                                ),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child: const Text(
                                                                  'Cancelar',
                                                                  style: TextStyle(
                                                                    color: Color(
                                                                      0xFF64748B,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child: const Text(
                                                                  'Excluir',
                                                                  style: TextStyle(
                                                                    color: Color(
                                                                      0xFFDC2626,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                    if (confirm == true) {
                                                      await Supabase
                                                          .instance
                                                          .client
                                                          .from('materias')
                                                          .delete()
                                                          .eq(
                                                            'id',
                                                            materia['id'],
                                                          );
                                                      await _buscarMaterias();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: const Text(
                                                            'Matéria excluída com sucesso!',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF059669,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    );
                                  }).toList(),
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
