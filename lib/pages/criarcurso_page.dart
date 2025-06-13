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
            backgroundColor: Colors.white,
            title: const Text(
              'Editar Curso',
              style: TextStyle(color: Color(0xFF1E3A8A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: Color(0xFF1E3A8A)),
                    decoration: InputDecoration(
                      labelText: 'Nome do Curso',
                      labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: semestreController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF1E3A8A)),
                    decoration: InputDecoration(
                      labelText: 'Semestre',
                      labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: periodoEdit,
                    decoration: InputDecoration(
                      labelText: 'Período',
                      labelStyle: const TextStyle(color: Color(0xFF3B82F6)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF1E3A8A)),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Matutino',
                          style: TextStyle(color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          'Vespertino',
                          style: TextStyle(color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                          'Noturno',
                          style: TextStyle(color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                    onChanged: (v) => periodoEdit = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
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
            backgroundColor: Colors.white,
            title: const Text(
              'Excluir curso',
              style: TextStyle(color: Color(0xFF1E3A8A)),
            ),
            content: const Text(
              'Tem certeza que deseja excluir este curso?',
              style: TextStyle(color: Color(0xFF374151)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Color(0xFFDC2626)),
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
        backgroundColor: const Color(0xFF1E40AF), // Azul mais escuro e elegante
        elevation: 2,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Novo Curso',
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
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF3B82F6)),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF3B82F6)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF3B82F6)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF3B82F6)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(
                Icons.school,
                color: Color(0xFF1E3A8A), // Destaque para página atual
              ),
              title: const Text(
                'Novo Curso',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              tileColor: const Color(0xFFF0F4FF), // Fundo sutil para item ativo
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF3B82F6)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF3B82F6)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
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
      backgroundColor: const Color(0xFFF8FAFC), // Fundo cinza muito claro
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(0), // Remove padding externo
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário à esquerda ocupando 40% da tela, colado no canto esquerdo, sem borda arredondada
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height:
                      MediaQuery.of(context).size.height -
                      80, // 100% da tela menos o AppBar
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE0E7FF), // Azul muito claro
                        Color(0xFFF0F4FF), // Azul quase branco
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
                          'Novo Curso',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _cursoController,
                          style: const TextStyle(color: Color(0xFF1E3A8A)),
                          decoration: InputDecoration(
                            labelText: 'Nome do Curso',
                            labelStyle: const TextStyle(
                              color: Color(0xFF3B82F6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 2,
                              ),
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
                          style: const TextStyle(color: Color(0xFF1E3A8A)),
                          decoration: InputDecoration(
                            labelText: 'Semestre',
                            labelStyle: const TextStyle(
                              color: Color(0xFF3B82F6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 2,
                              ),
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
                              color: Color(0xFF3B82F6),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF1E3A8A)),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                'Matutino',
                                style: TextStyle(color: Color(0xFF1E3A8A)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                'Vespertino',
                                style: TextStyle(color: Color(0xFF1E3A8A)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                'Noturno',
                                style: TextStyle(color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _periodo = v),
                          validator:
                              (v) => v == null ? 'Selecione o período' : null,
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
                              backgroundColor: const Color(0xFF1E40AF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _isLoading ? null : _salvarCurso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lista de cursos à direita ocupando 60% da tela, colada no canto direito, sem borda arredondada
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height - 80,
                    // Removido o fundo e borda arredondada para colar na parede da tela
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 36,
                    ), // Padding interno para o conteúdo
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Color(0xFF1F2937)),
                          decoration: InputDecoration(
                            hintText: 'Pesquisar curso, semestre ou período...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF6B7280),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 2,
                              ),
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
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cabeçalho da lista
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Curso',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Semestre',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
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
                                    color: Color(0xFF475569),
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
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _loadingCursos
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF3B82F6),
                                    ),
                                  )
                                  : _cursosFiltrados.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Nenhum curso cadastrado.',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  )
                                  : ListView.separated(
                                    controller: _scrollController,
                                    itemCount: _cursosFiltrados.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(
                                          color: Color(0xFFE2E8F0),
                                          height: 1,
                                        ),
                                    itemBuilder: (context, index) {
                                      final curso = _cursosFiltrados[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              index % 2 == 0
                                                  ? Colors.white
                                                  : const Color(
                                                    0xFFFAFBFC,
                                                  ), // Alternância de cores sutil
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                curso['curso'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFF1F2937),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${curso['semestre'] ?? ''}',
                                                style: const TextStyle(
                                                  color: Color(0xFF374151),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getPeriodoColor(
                                                    curso['periodo'],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  periodoToString(
                                                    curso['periodo'],
                                                  ),
                                                  style: TextStyle(
                                                    color: _getPeriodoTextColor(
                                                      curso['periodo'],
                                                    ),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFEF3C7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Color(
                                                          0xFFD97706,
                                                        ),
                                                        size: 20,
                                                      ),
                                                      tooltip: 'Editar',
                                                      onPressed: () async {
                                                        await _editarCursoDialog(
                                                          curso,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFEE2E2,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Color(
                                                          0xFFDC2626,
                                                        ),
                                                        size: 20,
                                                      ),
                                                      tooltip: 'Excluir',
                                                      onPressed: () async {
                                                        await _excluirCurso(
                                                          curso,
                                                        );
                                                      },
                                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função para retornar cor de fundo baseada no período
  Color _getPeriodoColor(int? periodo) {
    switch (periodo) {
      case 1: // Matutino
        return const Color(0xFFDCFDF7); // Verde claro
      case 2: // Vespertino
        return const Color(0xFFFEF3C7); // Amarelo claro
      case 3: // Noturno
        return const Color(0xFFE0E7FF); // Azul claro
      default:
        return const Color(0xFFF3F4F6); // Cinza claro
    }
  }

  // Função para retornar cor do texto baseada no período
  Color _getPeriodoTextColor(int? periodo) {
    switch (periodo) {
      case 1: // Matutino
        return const Color(0xFF047857); // Verde escuro
      case 2: // Vespertino
        return const Color(0xFFD97706); // Amarelo escuro
      case 3: // Noturno
        return const Color(0xFF1E3A8A); // Azul escuro
      default:
        return const Color(0xFF6B7280); // Cinza escuro
    }
  }
}
