import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CriarCursoPage extends StatefulWidget {
  const CriarCursoPage({super.key});

  @override
  State<CriarCursoPage> createState() => _CriarCursoPageState();
}

class _CriarCursoPageState extends State<CriarCursoPage> {
  final _formKey = GlobalKey<FormState>();
  final _cursoController = TextEditingController();
  final _semestreController = TextEditingController();
  final _searchController = TextEditingController();
  int? _periodo;

  bool _isLoading = false;
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _cursosFiltrados = [];
  bool _loadingCursos = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _buscarCursos();
    _searchController.addListener(
      _filtrarCursos,
    ); // Adiciona o listener de volta
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filtrarCursos,
    ); // Remove o listener ao destruir
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _buscarCursos() async {
    setState(() => _loadingCursos = true);
    try {
      final data = await Supabase.instance.client
          .from('cursos')
          .select('id, curso, semestre, periodo')
          .order('curso');
      final cursos = List<Map<String, dynamic>>.from(data);
      final query = _searchController.text.trim().toLowerCase();
      final cursosFiltrados =
          query.isEmpty
              ? cursos
              : cursos.where((curso) {
                final nome = (curso['curso'] ?? '').toString().toLowerCase();
                final semestre =
                    (curso['semestre'] ?? '').toString().toLowerCase();
                final periodo = periodoToString(curso['periodo']).toLowerCase();
                return nome.contains(query) ||
                    semestre.contains(query) ||
                    periodo.contains(query);
              }).toList();
      setState(() {
        _cursos = cursos;
        _cursosFiltrados = cursosFiltrados;
        _loadingCursos = false;
      });
    } catch (e) {
      setState(() => _loadingCursos = false);
    }
  }

  void _filtrarCursos() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _cursosFiltrados = _cursos;
      } else {
        _cursosFiltrados =
            _cursos.where((curso) {
              final nome = (curso['curso'] ?? '').toString().toLowerCase();
              final semestre =
                  (curso['semestre'] ?? '').toString().toLowerCase();
              final periodo = periodoToString(curso['periodo']).toLowerCase();
              return nome.contains(query) ||
                  semestre.contains(query) ||
                  periodo.contains(query);
            }).toList();
      }
    });
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
        return 'Período?';
    }
  }

  Future<void> _salvarCurso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verifica duplicidade
      final existing =
          await Supabase.instance.client
              .from('cursos')
              .select()
              .eq('curso', _cursoController.text.trim())
              .eq('semestre', _semestreController.text.trim())
              .eq('periodo', _periodo)
              .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Já existe um curso com esses dados!')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await Supabase.instance.client.from('cursos').insert({
        'curso': _cursoController.text.trim(),
        'semestre': _semestreController.text.trim(),
        'periodo': _periodo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso criado com sucesso!')),
      );

      _cursoController.clear();
      _semestreController.clear();
      setState(() => _periodo = null);

      await _buscarCursos();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar curso: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarCursoDialog(Map<String, dynamic> curso) async {
    final nomeController = TextEditingController(text: curso['curso'] ?? '');
    final semestreController = TextEditingController(
      text: curso['semestre']?.toString() ?? '',
    );
    int? periodoEdit = curso['periodo'];

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Curso'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Curso',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: semestreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Semestre'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: periodoEdit,
                    decoration: const InputDecoration(labelText: 'Período'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Matutino')),
                      DropdownMenuItem(value: 2, child: Text('Vespertino')),
                      DropdownMenuItem(value: 3, child: Text('Noturno')),
                    ],
                    onChanged: (v) => periodoEdit = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );

    if (result == true) {
      final id = curso['id'];
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: id do curso é nulo!')),
        );
        return;
      }
      try {
        await Supabase.instance.client
            .from('cursos')
            .update({
              'curso': nomeController.text.trim(),
              'semestre': semestreController.text.trim(),
              'periodo': periodoEdit,
            })
            .eq('id', id is int ? id : int.parse(id.toString()));
        await _buscarCursos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curso atualizado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar curso: $e')));
      }
    }
  }

  Future<void> _excluirCurso(Map<String, dynamic> curso) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir curso'),
            content: const Text('Tem certeza que deseja excluir este curso?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final id = curso['id'];
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: id do curso é nulo!')),
        );
        return;
      }
      try {
        await Supabase.instance.client
            .from('cursos')
            .delete()
            .eq('id', id is int ? id : int.parse(id.toString()));
        await _buscarCursos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curso excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir curso: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Curso', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
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
              leading: const Icon(Icons.list_alt, color: Colors.black87),
              title: const Text(
                'Lista de Alocações',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listalocacao');
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.black87),
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
              leading: const Icon(Icons.add_business, color: Colors.black87),
              title: const Text(
                'Nova Alocação',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/criarlocacao');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.black87),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                // Já está na tela de criar curso
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
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulário
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 520,
                      child: Card(
                        color: Colors.grey[850],
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
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
                                  'Novo Curso',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _cursoController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Nome do Curso',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
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
                                              ? 'Informe o nome do curso'
                                              : null,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _semestreController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Semestre',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
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
                                              ? 'Informe o semestre'
                                              : null,
                                ),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<int>(
                                  value: _periodo,
                                  decoration: InputDecoration(
                                    labelText: 'Período',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 16,
                                    ),
                                  ),
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text('Matutino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('Vespertino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('Noturno'),
                                    ),
                                  ],
                                  onChanged:
                                      (v) => setState(() => _periodo = v),
                                  validator:
                                      (v) =>
                                          v == null
                                              ? 'Selecione o período'
                                              : null,
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
                                    label: const Text('Salvar Curso'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _salvarCurso,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Lista de cursos com campo de pesquisa
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 520,
                      child: Card(
                        color: Colors.grey[850],
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText:
                                      'Pesquisar curso, semestre ou período...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 12,
                                  ),
                                ),
                                onChanged: (_) => _filtrarCursos(),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Cursos cadastrados:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          'Curso',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Semestre',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Período',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Ações',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                color: Colors.white24,
                                thickness: 1,
                                height: 20,
                              ),
                              Expanded(
                                child:
                                    _loadingCursos
                                        ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                        : _cursosFiltrados.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'Nenhum curso cadastrado.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        )
                                        : ListView.separated(
                                          controller: _scrollController,
                                          itemCount: _cursosFiltrados.length,
                                          separatorBuilder:
                                              (_, __) => const Divider(
                                                color: Colors.white12,
                                                height: 1,
                                              ),
                                          itemBuilder: (context, index) {
                                            final curso =
                                                _cursosFiltrados[index];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      curso['curso'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      '${curso['semestre'] ?? ''}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      periodoToString(
                                                        curso['periodo'],
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            color: Colors.amber,
                                                            size: 22,
                                                          ),
                                                          tooltip: 'Editar',
                                                          onPressed: () async {
                                                            await _editarCursoDialog(
                                                              curso,
                                                            );
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                            size: 22,
                                                          ),
                                                          tooltip: 'Excluir',
                                                          onPressed: () async {
                                                            await _excluirCurso(
                                                              curso,
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
