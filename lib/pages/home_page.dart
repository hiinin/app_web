import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;
import 'criarlocacao_page.dart';
import 'listalocacao_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  List<sala_model.Sala> salas = [];
  List<curso_model.Curso> cursos = [];

  sala_model.Sala? salaSelecionada;
  curso_model.Curso? cursoSelecionado;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => isLoading = true);
    try {
      final responseSalas = await supabase
          .from('salas')
          .select()
          .eq('disponivel', true);
      print('responseSalas: $responseSalas');

      final responseCursos = await supabase.from('cursos').select();
      print('DEBUG - responseCursos: $responseCursos');

      setState(() {
        salas =
            (responseSalas as List)
                .map((e) => sala_model.Sala.fromMap(e))
                .toList();
        cursos =
            (responseCursos as List)
                .map((e) => curso_model.Curso.fromMap(e))
                .toList();
      });
      print('Salas carregadas: ${salas.length}');
      print('Cursos carregados: ${cursos.length}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/imagemfundologin.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0.0, -0.5),
            colors: [
              Colors.black.withOpacity(0.6), // Mais escuro no topo
              Colors.black.withOpacity(0.4), // Meio termo
              Colors.black.withOpacity(0.2), // Mais claro
              Colors.transparent, // Totalmente transparente na parte inferior
            ],
            stops: const [0.0, 0.3, 0.7, 1.0], // Controla onde cada cor aparece
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Homepage Administrador',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/criarlocacao'),
                style: TextButton.styleFrom(
                  overlayColor: Colors.black.withOpacity(1.0),
                ),
                child: const Text(
                  'Novo Agendamento',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),

              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/listalocacao'),
                style: TextButton.styleFrom(
                  overlayColor: Colors.black.withOpacity(1.0),
                ),
                child: const Text(
                  'Lista de Agendamento',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),

              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                padding: const EdgeInsets.all(15.0),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deslogado com sucesso')),
                  );
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 238, 236, 236),
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_business,
                    color: Colors.black87,
                  ),
                  title: const Text(
                    'Novo Agendamento',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CriarLocacaoPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt, color: Colors.black87),
                  title: const Text(
                    'Lista de Agendamentos',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListaLocacaoPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.meeting_room,
                    color: Colors.black87,
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
                  leading: const Icon(Icons.school, color: Colors.black87),
                  title: const Text(
                    'Novo Curso',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/criarcurso');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.black87),
                  title: const Text(
                    'Nova Matéria',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/criarmateria');
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
          body: Stack(
            children: [
              // Quadrado branco na metade inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height:
                    MediaQuery.of(context).size.height *
                    0.5, // 50% da altura da tela
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 32.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Bem-vindo ao Painel RH!',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _InfoCard(
                                      label: 'Salas',
                                      value: salas.length.toString(),
                                      icon: Icons.meeting_room,
                                    ),
                                    const SizedBox(width: 32),
                                    _InfoCard(
                                      label: 'Cursos',
                                      value: cursos.length.toString(),
                                      icon: Icons.school,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Utilize o menu lateral ou os botões acima para navegar entre as funções do sistema.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ],
          ),
          // Body vazio, apenas a imagem de fundo com gradiente
        ),
      ),
    );
  }
}

// Widget auxiliar para exibir informações
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
