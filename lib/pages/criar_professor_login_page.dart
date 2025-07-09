import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CriarProfessorLoginPage extends StatefulWidget {
  @override
  State<CriarProfessorLoginPage> createState() =>
      _CriarProfessorLoginPageState();
}

class _CriarProfessorLoginPageState extends State<CriarProfessorLoginPage> {
  final supabase = Supabase.instance.client;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  // Controllers para edição
  final TextEditingController _editEmailController = TextEditingController();
  final TextEditingController _editSenhaController = TextEditingController();
  final TextEditingController _editNomeController = TextEditingController();

  // Variáveis de estado
  List<Map<String, dynamic>> cursos = [];
  List<Map<String, dynamic>> usuarios = [];
  int? cursoSelecionado;
  int? cursoEditSelecionado;
  String? semestreCurso;
  String? periodoCurso;
  bool isLoading = false;
  bool isLoadingUsuarios = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureEditPassword = true;
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();

  // Variáveis para edição
  Map<String, dynamic>? usuarioEditando;
  String filtroUsuario = "";

  @override
  void initState() {
    super.initState();
    _carregarCursos();
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _confirmarSenhaController.dispose();
    _editEmailController.dispose();
    _editSenhaController.dispose();
    _editNomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarCursos() async {
    try {
      final res = await supabase
          .from('cursos')
          .select('id, curso, semestre, periodo')
          .order('curso');
      setState(() {
        cursos = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar cursos: $e')));
    }
  }

  Future<void> _carregarUsuarios() async {
    setState(() => isLoadingUsuarios = true);
    try {
      print('Iniciando carregamento de usuários...'); // Debug

      // Primeiro, vamos verificar se há usuários na tabela
      final todosUsuarios = await supabase
          .from('users')
          .select('id, email, nome, tipo_usuario')
          .order('nome');

      print('Todos os usuários na tabela: $todosUsuarios'); // Debug

      // Agora vamos buscar apenas professores
      final res = await supabase
          .from('users')
          .select('*')
          .eq('tipo_usuario', 'professor')
          .order('nome');

      print('Professores encontrados (todos os campos): $res'); // Debug

      setState(() {
        usuarios = List<Map<String, dynamic>>.from(res);
        isLoadingUsuarios = false;
      });

      print(
        'Lista de usuários atualizada: ${usuarios.length} professores',
      ); // Debug
    } catch (e) {
      setState(() => isLoadingUsuarios = false);
      print('Erro ao carregar usuários: $e'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar professores: $e')),
      );
    }
  }

  // Função para buscar dados do curso quando selecionado
  void _onCursoChanged(int? cursoId) {
    setState(() {
      cursoSelecionado = cursoId;

      if (cursoId != null) {
        final curso = cursos.firstWhere(
          (c) => c['id'] == cursoId,
          orElse: () => {},
        );

        if (curso.isNotEmpty) {
          semestreCurso = curso['semestre']?.toString();
          periodoCurso = _periodoToText(curso['periodo']);
        } else {
          semestreCurso = null;
          periodoCurso = null;
        }
      } else {
        semestreCurso = null;
        periodoCurso = null;
      }
    });
  }

  // Função para buscar dados do curso quando editando
  void _onCursoEditChanged(int? cursoId) {
    setState(() {
      cursoEditSelecionado = cursoId;
    });
  }

  String _periodoToString(int? periodo) {
    switch (periodo) {
      case 1:
        return 'Matutino';
      case 2:
        return 'Vespertino';
      case 3:
        return 'Noturno';
      default:
        return 'Período não informado';
    }
  }

  String _periodoToText(int? periodo) {
    switch (periodo) {
      case 1:
        return 'Matutino';
      case 2:
        return 'Vespertino';
      case 3:
        return 'Noturno';
      default:
        return 'Período não informado';
    }
  }

  Future<void> _criarProfessor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem!')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Criar usuário no auth do Supabase
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Erro ao criar usuário no auth');
      }

      // 2. Inserir dados na tabela users
      final dadosUsuario = {
        'id': authResponse.user!.id,
        'email': _emailController.text.trim(),
        'nome': _nomeController.text.trim(),
        'curso_id': cursoSelecionado,
        'semestre': semestreCurso,
        'periodo': periodoCurso,
        'tipo_usuario': 'professor',
      };

      print('Dados do usuário a serem inseridos: $dadosUsuario'); // Debug

      await supabase.from('users').insert(dadosUsuario);

      print('Usuário inserido com sucesso na tabela users'); // Debug

      // Verificar se o usuário foi realmente inserido
      final usuarioInserido =
          await supabase
              .from('users')
              .select('*')
              .eq('id', authResponse.user!.id)
              .single();

      print('Usuário verificado após inserção: $usuarioInserido'); // Debug

      // 3. Limpar formulário
      _emailController.clear();
      _senhaController.clear();
      _nomeController.clear();
      _confirmarSenhaController.clear();
      setState(() {
        cursoSelecionado = null;
        semestreCurso = null;
        periodoCurso = null;
      });

      // 4. Recarregar lista de usuários
      await _carregarUsuarios();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professor cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar professor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _iniciarEdicao(Map<String, dynamic> usuario) {
    setState(() {
      usuarioEditando = usuario;
      _editNomeController.text = usuario['nome'] ?? '';
      _editEmailController.text = usuario['email'] ?? '';
      _editSenhaController.clear();
      cursoEditSelecionado = usuario['curso_id'];
    });
  }

  void _cancelarEdicao() {
    setState(() {
      usuarioEditando = null;
      _editNomeController.clear();
      _editEmailController.clear();
      _editSenhaController.clear();
      cursoEditSelecionado = null;
    });
  }

  Future<void> _salvarEdicao() async {
    if (!_editFormKey.currentState!.validate()) return;

    if (usuarioEditando == null) return;

    setState(() => isLoading = true);

    try {
      final dadosAtualizados = {
        'nome': _editNomeController.text.trim(),
        'email': _editEmailController.text.trim(),
        'curso_id': cursoEditSelecionado,
      };

      // Se uma nova senha foi fornecida, atualizar também
      if (_editSenhaController.text.isNotEmpty) {
        if (_editSenhaController.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A senha deve ter pelo menos 6 caracteres'),
            ),
          );
          return;
        }

        // Atualizar senha no auth (comentado por enquanto)
        // await supabase.auth.admin.updateUserById(
        //   usuarioEditando!['id'],
        //   attributes: AdminUserAttributes(password: _editSenhaController.text),
        // );
      }

      // Atualizar dados na tabela users
      await supabase
          .from('users')
          .update(dadosAtualizados)
          .eq('id', usuarioEditando!['id']);

      // Recarregar lista
      await _carregarUsuarios();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professor atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      _cancelarEdicao();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar professor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _excluirUsuario(String userId) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text(
              'Tem certeza que deseja excluir este professor?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmacao != true) return;

    setState(() => isLoading = true);

    try {
      // Excluir da tabela users
      await supabase.from('users').delete().eq('id', userId);

      // Recarregar lista
      await _carregarUsuarios();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professor excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir professor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
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
          'Cadastrar Professor',
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
              decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
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
            // INÍCIO
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF1E40AF)),
              title: const Text(
                'Início',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),

            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF1E40AF)),
              title: const Text('Novo Agendamento'),
              onTap:
                  () =>
                      Navigator.pushReplacementNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Color(0xFF1E40AF)),
              title: const Text('Agendar Prova'),
              onTap:
                  () => Navigator.pushReplacementNamed(context, '/criarprova'),
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF1E40AF)),
              title: const Text('Novo Evento'),
              onTap:
                  () => Navigator.pushReplacementNamed(context, '/criarevento'),
            ),

            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF1E40AF)),
              title: const Text('Lista de Agendamento'),
              onTap:
                  () =>
                      Navigator.pushReplacementNamed(context, '/listalocacao'),
            ),

            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF1E40AF)),
              title: const Text('Nova Sala'),
              onTap:
                  () => Navigator.pushReplacementNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF1E40AF)),
              title: const Text('Novo Curso'),
              onTap:
                  () => Navigator.pushReplacementNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF1E40AF)),
              title: const Text('Novo Professor'),
              onTap:
                  () => Navigator.pushReplacementNamed(
                    context,
                    '/criarprofessor',
                  ),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF1E40AF)),
              title: const Text('Nova Matéria'),
              onTap:
                  () =>
                      Navigator.pushReplacementNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF1E40AF)),
              title: const Text('Cadastrar Professor'),
              onTap:
                  () => Navigator.pushReplacementNamed(
                    context,
                    '/criarprofessorlogin',
                  ),
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF1E40AF)),
              title: const Text('Histórico de Ações'),
              onTap:
                  () => Navigator.pushReplacementNamed(
                    context,
                    '/historicoacoes',
                  ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Formulário à esquerda
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height - 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Card do formulário
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Novo Professor',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),

                                // Campo Nome
                                TextFormField(
                                  controller: _nomeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome Completo',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Por favor, insira o nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Campo Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Por favor, insira o email';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Por favor, insira um email válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Campo Senha
                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, insira a senha';
                                    }
                                    if (value.length < 6) {
                                      return 'A senha deve ter pelo menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Campo Confirmar Senha
                                TextFormField(
                                  controller: _confirmarSenhaController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar Senha',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, confirme a senha';
                                    }
                                    if (value != _senhaController.text) {
                                      return 'As senhas não coincidem';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Dropdown Curso
                                DropdownButtonFormField<int>(
                                  value: cursoSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Curso',
                                    prefixIcon: Icon(Icons.school),
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      cursos.map((curso) {
                                        final semestre =
                                            curso['semestre']?.toString() ??
                                            'Semestre não informado';
                                        final periodo = _periodoToText(
                                          curso['periodo'],
                                        );
                                        return DropdownMenuItem<int>(
                                          value: curso['id'] as int,
                                          child: Text(
                                            '${curso['curso']} - $semestre - $periodo',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: _onCursoChanged,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor, selecione um curso';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Exibir informações do curso selecionado
                                if (cursoSelecionado != null &&
                                    (semestreCurso != null ||
                                        periodoCurso != null))
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Informações do Curso:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (semestreCurso != null)
                                          Text(
                                            'Semestre: $semestreCurso',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        if (periodoCurso != null)
                                          Text(
                                            'Período: $periodoCurso',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 30),

                                // Botão Cadastrar
                                ElevatedButton(
                                  onPressed: isLoading ? null : _criarProfessor,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Text(
                                            'Cadastrar Professor',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
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
              ),

              // Lista de usuários à direita
              Expanded(
                child: Container(
                  height: MediaQuery.of(context).size.height - 80,
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Professores Cadastrados',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          IconButton(
                            onPressed: _carregarUsuarios,
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF1E40AF),
                            ),
                            tooltip: 'Atualizar lista',
                          ),
                          IconButton(
                            onPressed: () async {
                              try {
                                final todosUsuarios = await supabase
                                    .from('users')
                                    .select('*')
                                    .order('nome');
                                print(
                                  'TESTE - Todos os usuários: $todosUsuarios',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Total de usuários: ${todosUsuarios.length}',
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              } catch (e) {
                                print('Erro no teste: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro no teste: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.bug_report,
                              color: Colors.orange,
                            ),
                            tooltip: 'Teste - Ver todos usuários',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Campo de busca
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Buscar professor...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            filtroUsuario = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Lista de usuários
                      Expanded(
                        child:
                            isLoadingUsuarios
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : usuarios.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Nenhum professor cadastrado.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount:
                                      usuarios
                                          .where(
                                            (u) =>
                                                filtroUsuario.isEmpty ||
                                                (u['nome'] ?? '')
                                                    .toLowerCase()
                                                    .contains(filtroUsuario) ||
                                                (u['email'] ?? '')
                                                    .toLowerCase()
                                                    .contains(filtroUsuario),
                                          )
                                          .length,
                                  itemBuilder: (context, index) {
                                    final usuariosFiltrados =
                                        usuarios
                                            .where(
                                              (u) =>
                                                  filtroUsuario.isEmpty ||
                                                  (u['nome'] ?? '')
                                                      .toLowerCase()
                                                      .contains(
                                                        filtroUsuario,
                                                      ) ||
                                                  (u['email'] ?? '')
                                                      .toLowerCase()
                                                      .contains(filtroUsuario),
                                            )
                                            .toList();
                                    final usuario = usuariosFiltrados[index];
                                    final curso = usuario['cursos'];

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFF1E40AF,
                                          ),
                                          child: Text(
                                            (usuario['nome'] ?? '')
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          usuario['nome'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(usuario['email'] ?? ''),
                                            if (curso != null)
                                              Text(
                                                '${curso['curso']} - ${curso['semestre']} - ${_periodoToText(curso['periodo'])}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    usuario['tipo_usuario'] ==
                                                            'professor'
                                                        ? Colors.blue
                                                            .withOpacity(0.2)
                                                        : Colors.green
                                                            .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      usuario['tipo_usuario'] ==
                                                              'professor'
                                                          ? Colors.blue
                                                          : Colors.green,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                usuario['tipo_usuario'] ==
                                                        'professor'
                                                    ? 'Professor'
                                                    : 'Aluno',
                                                style: TextStyle(
                                                  color:
                                                      usuario['tipo_usuario'] ==
                                                              'professor'
                                                          ? Colors.blue
                                                          : Colors.green,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed:
                                                  () => _iniciarEdicao(usuario),
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              tooltip: 'Editar',
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _excluirUsuario(
                                                    usuario['id'],
                                                  ),
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Excluir',
                                            ),
                                          ],
                                        ),
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

          // Modal de edição
          if (usuarioEditando != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 500,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _editFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabeçalho do modal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Editar Professor',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            IconButton(
                              onPressed: _cancelarEdicao,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Campo Nome
                        TextFormField(
                          controller: _editNomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Email
                        TextFormField(
                          controller: _editEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira o email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Por favor, insira um email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Nova Senha (opcional)
                        TextFormField(
                          controller: _editSenhaController,
                          obscureText: _obscureEditPassword,
                          decoration: InputDecoration(
                            labelText: 'Nova Senha (opcional)',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureEditPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureEditPassword = !_obscureEditPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Curso
                        DropdownButtonFormField<int>(
                          value: cursoEditSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Curso',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          items:
                              cursos.map((curso) {
                                final semestre =
                                    curso['semestre']?.toString() ??
                                    'Semestre não informado';
                                final periodo = _periodoToText(
                                  curso['periodo'],
                                );
                                return DropdownMenuItem<int>(
                                  value: curso['id'] as int,
                                  child: Text(
                                    '${curso['curso']} - $semestre - $periodo',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                          onChanged: _onCursoEditChanged,
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor, selecione um curso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botões
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelarEdicao,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _salvarEdicao,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text('Salvar'),
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
        ],
      ),
    );
  }
}
