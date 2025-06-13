import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

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

      final responseCursos = await supabase.from('cursos').select();

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
            toolbarHeight: 110, // era 80
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 38,
            ), // maior
            title: const Text(
              'Homepage Administrador',
              style: TextStyle(
                fontSize: 32, // era 24
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
                  style: TextStyle(color: Colors.white, fontSize: 25),
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
                  style: TextStyle(color: Colors.white, fontSize: 25),
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
                      const SizedBox(width: 24),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'RH Painel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bem-vindo!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
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
                  leading: const Icon(
                    Icons.meeting_room,
                    color: Color(0xFF1E40AF),
                  ),
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
                ListTile(
                  leading: const Icon(Icons.event, color: Color(0xFF1E40AF)),
                  title: const Text(
                    'Novo Evento',
                    style: TextStyle(color: Colors.black87),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/criarevento'),
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
          body: Padding(
            padding: const EdgeInsets.only(top: 80.0, left: 32.0, right: 32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrossel alinhado à esquerda
                Expanded(child: _HomeCarousel()),
              ],
            ),
          ),
          // Body vazio, apenas a imagem de fundo com gradiente
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final _HomeActionCardData data;
  final double size;
  final bool isActive;
  final VoidCallback onPressed;

  const _HomeActionCard({
    required this.data,
    required this.size,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(22),
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                data.icon,
                color: const Color(0xFF1E40AF),
                size: 64, // era 44
              ),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 22, // era 17
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    data.help,
                    style: const TextStyle(
                      fontSize: 16, // era 13
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Opacity(
                opacity: 1.0,
                child: SizedBox(
                  width: double.infinity,
                  height: 48, // era 38
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1E40AF,
                      ), // Cor escura do drawer
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      data.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // era 15
                        color: Colors.white, // Texto branco no botão
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Adicione este widget ao final do arquivo:
class _HomeCarousel extends StatefulWidget {
  @override
  State<_HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<_HomeCarousel> {
  // Troque o valor do viewportFraction para ~0.26
  final PageController _controller = PageController(viewportFraction: 0.26);
  int _currentPage = 0;

  final List<_HomeActionCardData> _cards = [
    _HomeActionCardData(
      icon: Icons.add_box,
      title: 'Novo Agendamento',
      help: 'Quer realizar um agendamento?\nClique no botão abaixo.',
      buttonText: 'Agendar',
      route: '/criarlocacao',
    ),
    _HomeActionCardData(
      icon: Icons.list_alt,
      title: 'Consultar Agendamento',
      help: 'Quer consultar um agendamento?\nClique no botão abaixo.',
      buttonText: 'Consultar',
      route: '/listalocacao',
    ),
    _HomeActionCardData(
      icon: Icons.school,
      title: 'Criar Curso',
      help: 'Quer criar um novo curso?\nClique no botão abaixo.',
      buttonText: 'Novo Curso',
      route: '/criarcurso',
    ),
    _HomeActionCardData(
      icon: Icons.book,
      title: 'Criar Matéria',
      help: 'Quer criar uma nova matéria?\nClique no botão abaixo.',
      buttonText: 'Nova Matéria',
      route: '/criarmateria',
    ),
    _HomeActionCardData(
      icon: Icons.person,
      title: 'Criar Professor',
      help: 'Quer cadastrar um professor?\nClique no botão abaixo.',
      buttonText: 'Novo Professor',
      route: '/criarprofessor',
    ),
    _HomeActionCardData(
      icon: Icons.meeting_room,
      title: 'Criar Sala',
      help: 'Quer cadastrar uma sala?\nClique no botão abaixo.',
      buttonText: 'Nova Sala',
      route: '/criarsala',
    ),
  ];

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardSize = 270; // era 210, agora maior
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32.0, left: 0, right: 0),
        child: SizedBox(
          height: cardSize + 24,
          width: double.infinity,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                ), // igual ou maior que o raio das setas + margem
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.02, 0.98, 1.0], // FADE BEM MENOR
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _cards.length,
                    padEnds: false,
                    onPageChanged:
                        (page) => setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      // final isActive = index == _currentPage; // pode remover se não usar mais
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 18, // valor fixo para todos os cards
                          vertical: 0, // sem efeito de "aumentar"
                        ),
                        child: _HomeActionCard(
                          data: _cards[index],
                          size: cardSize,
                          isActive:
                              false, // ou remova o parâmetro se não usar mais
                          onPressed: () {
                            Navigator.pushNamed(context, _cards[index].route);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Setas de navegação
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 28,
                        color: Colors.blue, // Azul forte para destaque
                      ),
                      onPressed:
                          _currentPage > 0
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                      splashRadius: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 28,
                        color: Colors.blue, // Azul forte para destaque
                      ),
                      onPressed:
                          _currentPage < _cards.length - 1
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                      splashRadius: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dados do card
class _HomeActionCardData {
  final IconData icon;
  final String title;
  final String help;
  final String buttonText;
  final String route;
  _HomeActionCardData({
    required this.icon,
    required this.title,
    required this.help,
    required this.buttonText,
    required this.route,
  });
}
