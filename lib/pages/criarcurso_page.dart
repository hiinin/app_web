import 'package:flutter/material.dart';
import '../functions/drawer_helper.dart';
import '../functions/criarcurso_functions.dart';

class CriarCursoPage extends StatefulWidget {
  const CriarCursoPage({super.key});

  @override
  State<CriarCursoPage> createState() => _CriarCursoPageState();
}

class _CriarCursoPageState extends State<CriarCursoPage> {
  final _formKey = GlobalKey<FormState>();
  final _cursoController = TextEditingController();
  final _quantidadeAlunosController = TextEditingController();
  final _searchController = TextEditingController();
  final _functions = CriarCursoFunctions();
  int? _periodo;
  int? _semestre;

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
    _cursoController.dispose();
    _quantidadeAlunosController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _buscarCursos() async {
    setState(() => _loadingCursos = true);
    try {
      final cursos = await _functions.buscarCursos();
      final query = _searchController.text.trim();
      final cursosFiltrados = _functions.filtrarCursos(cursos, query);
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
    final query = _searchController.text.trim();
    setState(() {
      _cursosFiltrados = _functions.filtrarCursos(_cursos, query);
    });
  }

  Future<void> _salvarCurso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantidadeAlunos = int.tryParse(_quantidadeAlunosController.text.trim());
      
      await _functions.salvarCurso(
        nomeCurso: _cursoController.text.trim(),
        semestre: _semestre,
        periodo: _periodo,
        quantidadeAlunos: quantidadeAlunos,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turma criada com sucesso!')),
      );

      _cursoController.clear();
      _quantidadeAlunosController.clear();
      setState(() {
        _periodo = null;
        _semestre = null;
      });

      await _buscarCursos();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar turma: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarCursoDialog(Map<String, dynamic> curso) async {
    final nomeController = TextEditingController(text: curso['curso'] ?? '');
    final quantidadeAlunosController = TextEditingController(
      text: curso['quantidade_alunos']?.toString() ?? '',
    );
    int? periodoEdit = curso['periodo'];
    int? semestreEdit = _functions.semestreFromString(curso['semestre']?.toString());

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Editar Turma',
              style: TextStyle(color: Color(0xFF44A301)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    style: const TextStyle(color: Color(0xFF44A301)),
                    decoration: InputDecoration(
                      labelText: 'Nome da Turma',
                      labelStyle: const TextStyle(color: Color(0xFF44A301)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE8F5E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF44A301)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder:
                        (context, setStateDialog) =>
                            DropdownButtonFormField<int>(
                              value: semestreEdit,
                              decoration: InputDecoration(
                                labelText: 'Semestre',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF44A301),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8F5E8),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF44A301),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF44A301)),
                              items:
                                  List.generate(10, (index) => index + 1).map((
                                    value,
                                  ) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        '$value° semestre',
                                        style: const TextStyle(
                                          color: Color(0xFF44A301),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => setStateDialog(() => semestreEdit = v),
                            ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: periodoEdit,
                    decoration: InputDecoration(
                      labelText: 'Período',
                      labelStyle: const TextStyle(color: Color(0xFF44A301)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE8F5E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF44A301)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF44A301)),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          'Matutino',
                          style: TextStyle(color: Color(0xFF44A301)),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text(
                          'Vespertino',
                          style: TextStyle(color: Color(0xFF44A301)),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(
                          'Noturno',
                          style: TextStyle(color: Color(0xFF44A301)),
                        ),
                      ),
                    ],
                    onChanged: (v) => periodoEdit = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantidadeAlunosController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF44A301)),
                    decoration: InputDecoration(
                      labelText: 'Quantidade de Alunos',
                      labelStyle: const TextStyle(color: Color(0xFF44A301)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE8F5E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF44A301)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                  style: TextStyle(color: Color(0xFF44A301)),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      final id = curso['id'];
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: id da turma é nulo!')),
        );
        return;
      }
      try {
        final quantidadeAlunos = int.tryParse(quantidadeAlunosController.text.trim());
        
        await _functions.atualizarCurso(
          id: id is int ? id : int.parse(id.toString()),
          nomeCurso: nomeController.text.trim(),
          semestre: semestreEdit,
          periodo: periodoEdit,
          quantidadeAlunos: quantidadeAlunos,
        );
        await _buscarCursos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma atualizada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar turma: $e')));
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
              'Excluir turma',
              style: TextStyle(color: Color(0xFF44A301)),
            ),
            content: const Text(
              'Tem certeza que deseja excluir esta turma?',
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
          const SnackBar(content: Text('Erro: id da turma é nulo!')),
        );
        return;
      }
      try {
        await _functions.excluirCurso(
          id is int ? id : int.parse(id.toString()),
        );
        await _buscarCursos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma excluída com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir turma: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF44A301), // Verde principal do tema
        elevation: 2,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nova Turma',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      drawer: buildAppDrawer(context),
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
                          'Nova Turma',
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
                          controller: _cursoController,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          decoration: InputDecoration(
                            labelText: 'Nome da Turma',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
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
                                      ? 'Informe o nome da turma'
                                      : null,
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<int>(
                          value: _semestre,
                          decoration: InputDecoration(
                            labelText: 'Semestre',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          items:
                              List.generate(10, (index) => index + 1).map((
                                value,
                              ) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    '$value° semestre',
                                    style: const TextStyle(
                                      color: Color(0xFF44A301),
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (v) => setState(() => _semestre = v),
                          validator:
                              (v) => v == null ? 'Selecione o semestre' : null,
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<int>(
                          value: _periodo,
                          decoration: InputDecoration(
                            labelText: 'Período',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                'Matutino',
                                style: TextStyle(color: Color(0xFF44A301)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                'Vespertino',
                                style: TextStyle(color: Color(0xFF44A301)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                'Noturno',
                                style: TextStyle(color: Color(0xFF44A301)),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _periodo = v),
                          validator:
                              (v) => v == null ? 'Selecione o período' : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _quantidadeAlunosController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Color(0xFF44A301)),
                          decoration: InputDecoration(
                            labelText: 'Quantidade de Alunos',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8F5E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe a quantidade de alunos';
                            }
                            final quantidade = int.tryParse(v.trim());
                            if (quantidade == null || quantidade <= 0) {
                              return 'Quantidade deve ser um número positivo';
                            }
                            return null;
                          },
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
                            label: const Text('Salvar Turma'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF44A301),
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
                        const SizedBox(height: 32),
                        // Bloco com botões para navegação
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF44A301),
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
                                          'Deseja criar uma nova matéria?',
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
                                            Icons.book,
                                            color: Colors.white,
                                          ),
                                          label: const Text('Nova Matéria'),
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
                                              '/criarmateria',
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
                          style: const TextStyle(color: Color(0xFF44A301)),
                          decoration: InputDecoration(
                            hintText: 'Pesquisar turma, semestre, período ou quantidade...',
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
                                color: Color(0xFF44A301),
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
                          'Turmas cadastradas:',
                          style: TextStyle(
                            color: Color(0xFF44A301),
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
                                flex: 2,
                                child: Text(
                                  'Turma',
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
                                  'Qtd. Alunos',
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
                                      color: Color(0xFF44A301),
                                    ),
                                  )
                                  : _cursosFiltrados.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Nenhuma turma cadastrada.',
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
                                              flex: 2,
                                              child: Text(
                                                curso['curso'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFF44A301),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                curso['semestre']?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Color(0xFF374151),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 4,
                                                      ),
                                                  constraints: const BoxConstraints(
                                                    maxWidth: 100,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _functions.getPeriodoColor(
                                                      curso['periodo'],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    _functions.periodoToString(
                                                      curso['periodo'],
                                                    ),
                                                    style: TextStyle(
                                                      color: _functions.getPeriodoTextColor(
                                                        curso['periodo'],
                                                      ),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                curso['quantidade_alunos']?.toString() ?? '-',
                                                style: const TextStyle(
                                                  color: Color(0xFF374151),
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

}
