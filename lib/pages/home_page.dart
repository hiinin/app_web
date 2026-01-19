import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;
import '../functions/drawer_helper.dart';
import '../services/auth_service.dart';

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
          image: AssetImage('assets/images/fundounicv1.png'),
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
                  'Novo Ensalamento',
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
                  'Lista de Ensalamentos',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),

              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                padding: const EdgeInsets.all(15.0),
                onPressed: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deslogado com sucesso')),
                  );
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          drawer: buildAppDrawer(context),
          body: Padding(
            padding: const EdgeInsets.only(top: 80.0, left: 32.0, right: 32.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Calendário à esquerda (35% da largura)
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.35,
                      child: _HomeCalendar(),
                    ),
                    const SizedBox(width: 32),
                    // Carrossel alinhado à direita (65% da largura)
                    Expanded(child: _HomeCarousel()),
                  ],
                ),
              ),
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
              color: const Color(0xFF44A301).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF44A301).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                data.icon,
                color: const Color(0xFF44A301),
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
                        0xFF44A301,
                      ), // Cor verde do tema
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
  // Ajustado o viewportFraction para melhor visualização dos cards maiores
  final PageController _controller = PageController(viewportFraction: 0.32);
  int _currentPage = 0;

  final List<_HomeActionCardData> _cards = [
    _HomeActionCardData(
      icon: Icons.add_box,
      title: 'Novo Ensalamento',
      help: 'Quer realizar um agendamento?\nClique no botão abaixo.',
      buttonText: 'Agendar',
      route: '/criarlocacao',
    ),
    _HomeActionCardData(
      icon: Icons.list_alt,
      title: 'Consultar Ensalamento',
      help: 'Quer consultar um agendamento?\nClique no botão abaixo.',
      buttonText: 'Consultar',
      route: '/listalocacao',
    ),
    _HomeActionCardData(
      icon: Icons.school,
      title: 'Criar Turma',
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
    final double cardSize = 400; // Exatamente igual à altura do calendário
    return SizedBox(
      height: cardSize, // Removido o +24 para ser exatamente igual
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
                onPageChanged: (page) => setState(() => _currentPage = page),
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
                      isActive: false, // ou remova o parâmetro se não usar mais
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
                    color: Color(0xFF44A301), // Verde para destaque
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
                    color: Color(0xFF44A301), // Verde para destaque
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
    );
  }
}

// Widget do Calendário
class _HomeCalendar extends StatefulWidget {
  @override
  State<_HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<_HomeCalendar> {
  final supabase = Supabase.instance.client;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      // Buscar agendamentos do mês atual
      final startOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
      final endOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);

      final response = await supabase
          .from('agendamento')
          .select('dia, tipo_agendamento')
          .gte('dia', startOfMonth.toIso8601String().split('T')[0])
          .lte('dia', endOfMonth.toIso8601String().split('T')[0]);

      setState(() {
        _events.clear();
        for (var event in response) {
          final date = DateTime.parse(event['dia']).toLocal();
          final day = DateTime(date.year, date.month, date.day);
          if (!_events.containsKey(day)) {
            _events[day] = [];
          }
          _events[day]!.add({
            'tipo': event['tipo_agendamento'],
            'data': event['dia'],
          });
        }
      });
    } catch (e) {
      print('Erro ao carregar eventos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500, // Aumentei de 450 para 500 para resolver o overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44A301).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF44A301).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduzi mais o padding
        child: Column(
          children: [
            // Título do calendário
            const Text(
              'Calendário de Agendamentos',
              style: TextStyle(
                fontSize: 16, // Reduzi mais o tamanho da fonte
                fontWeight: FontWeight.bold,
                color: Color(0xFF44A301),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Reduzi o espaçamento
            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Aulas', const Color(0xFF44A301)),
                _buildLegendItem('Eventos', Colors.orange),
                _buildLegendItem('Provas', Colors.red),
              ],
            ),
            const SizedBox(height: 8), // Reduzi o espaçamento
            // Cabeçalho do calendário
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF44A301),
                    size: 18, // Reduzi mais o tamanho do ícone
                  ),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month - 1,
                      );
                    });
                    _loadEvents();
                  },
                ),
                Text(
                  '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                  style: const TextStyle(
                    fontSize: 14, // Reduzi mais o tamanho da fonte
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF44A301),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF44A301),
                    size: 18, // Reduzi mais o tamanho do ícone
                  ),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(
                        _focusedDate.year,
                        _focusedDate.month + 1,
                      );
                    });
                    _loadEvents();
                  },
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduzi o espaçamento
            // Dias da semana
            Row(
              children: const [
                Expanded(
                  child: Center(
                    child: Text(
                      'Dom',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Seg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Ter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Qua',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Qui',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Sex',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Sáb',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                        fontSize: 11, // Reduzi mais o tamanho da fonte
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduzi o espaçamento
            // Grade do calendário - agora ocupa mais espaço
            Expanded(
              flex: 3, // Dá mais espaço para o calendário
              child: _buildCalendarGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final currentMonth = _focusedDate;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );
    // Ajusta o weekday para começar no domingo (0) em vez de segunda (1)
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    List<Widget> calendarDays = [];

    // Adiciona dias vazios no início (corrigindo o alinhamento)
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    // Adiciona os dias do mês
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final currentDate = DateTime(currentMonth.year, currentMonth.month, day);

      // Verifica se há eventos neste dia
      final events =
          _events.entries
              .where(
                (e) =>
                    e.key.year == currentDate.year &&
                    e.key.month == currentDate.month &&
                    e.key.day == currentDate.day,
              )
              .expand((e) => e.value)
              .toList();
      final hasEvents = events.isNotEmpty;

      final isToday =
          now.year == currentDate.year &&
          now.month == currentDate.month &&
          now.day == currentDate.day;
      final isPastDate = currentDate.isBefore(
        DateTime(now.year, now.month, now.day),
      );

      // Determina os tipos de eventos presentes
      final hasProvas = events.any((e) => e['tipo'] == 'M');
      final hasEventos = events.any((e) => e['tipo'] == 'E');
      final hasAulas = events.any((e) => e['tipo'] == 'A');

      calendarDays.add(
        Expanded(
          child: Container(
            height: 50, // Aumentei de 45 para 50 para dar mais espaço
            margin: const EdgeInsets.all(2), // Aumentei um pouco a margem
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent, // Sempre transparente
              border:
                  isToday
                      ? Border.all(color: const Color(0xFF44A301), width: 2)
                      : Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ), // Borda sutil para todos os dias
              boxShadow:
                  isToday
                      ? [
                        BoxShadow(
                          color: const Color(0xFF44A301).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color:
                          isToday
                              ? const Color(
                                0xFF44A301,
                              ) // Texto verde para o dia atual
                              : isPastDate
                              ? Colors.grey[400]
                              : const Color(0xFF44A301),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16, // Aumentei mais o tamanho da fonte
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    bottom: 2,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasProvas)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 0.5,
                              ),
                            ),
                          ),
                        if (hasEventos)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 0.5,
                              ),
                            ),
                          ),
                        if (hasAulas)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF44A301),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 0.5,
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
      );
    }

    // Adiciona dias vazios no final para completar 6 semanas (42 dias)
    final totalDias = calendarDays.length;
    final diasNecessarios = 42; // 6 semanas * 7 dias
    for (int i = totalDias; i < diasNecessarios; i++) {
      calendarDays.add(const Expanded(child: SizedBox()));
    }

    return Column(
      children: List.generate((calendarDays.length / 7).ceil(), (weekIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 1,
          ), // Reduzi o espaçamento vertical
          child: Row(
            children: calendarDays.skip(weekIndex * 7).take(7).toList(),
          ),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
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
