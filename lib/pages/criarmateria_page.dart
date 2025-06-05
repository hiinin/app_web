import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/curso.dart';

class CriarMateriaPage extends StatefulWidget {
  const CriarMateriaPage({super.key});

  @override
  State<CriarMateriaPage> createState() => _CriarMateriaPageState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 41, 123, 216),
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
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 48,
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
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              title: const Text(
                'Início',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.meeting_room,
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/criarsala');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.book,
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/criarmateria');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_business,
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/criarlocacao');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.list_alt,
                color: Color.fromARGB(255, 41, 123, 216),
              ),
              title: const Text(
                'Lista de Alocações',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listalocacao');
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2025 RH Company',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
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
                  color: const Color(0xFFE3EAFD),
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
                            color: Color(0xFF297BD8),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nomeMateriaController,
                          style: const TextStyle(color: Color(0xFF297BD8)),
                          decoration: InputDecoration(
                            labelText: 'Nome da Matéria',
                            labelStyle: const TextStyle(
                              color: Color(0xFF297BD8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
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
                              color: Color(0xFF297BD8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF297BD8)),
                          items:
                              _cursos
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.curso} - ${c.semestre ?? "Semestre?"}',
                                        style: const TextStyle(
                                          color: Color(0xFF297BD8),
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
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
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
                              backgroundColor: const Color(0xFF297BD8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _salvarMateria,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Pesquisar matéria...',
                            hintStyle: TextStyle(color: Colors.black45),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.black45,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
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
                            color: Colors.black,
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
                                    color: Colors.black54,
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
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.black12,
                          thickness: 1,
                          height: 20,
                        ),
                        Expanded(
                          child:
                              _loadingMaterias
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _materiasFiltradas.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Nenhuma matéria cadastrada.',
                                      style: TextStyle(color: Colors.black45),
                                    ),
                                  )
                                  : ListView.separated(
                                    controller: _scrollController,
                                    itemCount: _materiasFiltradas.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(
                                          color: Colors.black12,
                                          height: 1,
                                        ),
                                    itemBuilder: (context, index) {
                                      final materia = _materiasFiltradas[index];
                                      final curso = _cursos.firstWhere(
                                        (c) =>
                                            c.id ==
                                            (materia['curso_id'] is int
                                                ? materia['curso_id']
                                                : int.tryParse(
                                                      materia['curso_id']
                                                          .toString(),
                                                    ) ??
                                                    0),
                                        orElse:
                                            () => Curso(
                                              id: 0,
                                              curso: 'Curso?',
                                              semestre: '',
                                              periodo: 0,
                                            ),
                                      );
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ), // aumenta separação
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.03,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                materia['nome'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                curso.curso,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 22,
                                              ),
                                              tooltip: 'Excluir',
                                              onPressed: () async {
                                                final confirm = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: const Text(
                                                          'Excluir matéria',
                                                        ),
                                                        content: const Text(
                                                          'Tem certeza que deseja excluir esta matéria?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                            child: const Text(
                                                              'Excluir',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (confirm == true) {
                                                  await Supabase.instance.client
                                                      .from('materias')
                                                      .delete()
                                                      .eq('id', materia['id']);
                                                  await _buscarMaterias();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Matéria excluída com sucesso!',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
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
          ),
        ),
      ),
    );
  }
}
