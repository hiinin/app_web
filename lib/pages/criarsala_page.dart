import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CriarSalaPage extends StatefulWidget {
  const CriarSalaPage({super.key});

  @override
  State<CriarSalaPage> createState() => _CriarSalaPageState();
}

class _CriarSalaPageState extends State<CriarSalaPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _numeroSalaController = TextEditingController();
  final _qtdCadeirasController = TextEditingController();
  bool _disponivel = true;

  List<Map<String, dynamic>> _salas = [];
  List<Map<String, dynamic>> _salasFiltradas = [];
  bool _loadingSalas = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _projetor = false;
  bool _tv = false;
  bool _arCondicionado = false;

  @override
  void initState() {
    super.initState();
    _buscarSalas();
    _searchController.addListener(_filtrarSalas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _numeroSalaController.dispose();
    _qtdCadeirasController.dispose();
    super.dispose();
  }

  Future<void> _buscarSalas() async {
    setState(() => _loadingSalas = true);
    try {
      final data = await supabase
          .from('salas')
          .select(
            'id, numero_sala, qtd_cadeiras, disponivel, cor, projetor, tv, ar_condicionado',
          )
          .order('numero_sala');

      print('Dados recebidos do banco: $data');

      setState(() {
        _salas = List<Map<String, dynamic>>.from(data);
        _filtrarSalas();
      });
    } catch (e) {
      print('Erro ao buscar salas: $e');
      // Opcional: mostrar erro
    } finally {
      setState(() => _loadingSalas = false);
    }
  }

  void _filtrarSalas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _salasFiltradas = _salas;
      } else {
        _salasFiltradas =
            _salas.where((sala) {
              final numero =
                  (sala['numero_sala'] ?? '').toString().toLowerCase();
              final cadeiras =
                  (sala['qtd_cadeiras'] ?? '').toString().toLowerCase();
              return numero.contains(query) || cadeiras.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _salvarSala() async {
    // Força a atualização do estado antes de salvar
    setState(() {});

    final numeroSala = _numeroSalaController.text.trim();
    final qtdCadeiras = int.tryParse(_qtdCadeirasController.text.trim()) ?? 0;

    if (numeroSala.isEmpty || qtdCadeiras <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
      return;
    }

    // Verifica se já existe uma sala com o mesmo número
    final existe =
        await supabase
            .from('salas')
            .select()
            .eq('numero_sala', numeroSala)
            .maybeSingle();

    if (existe != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma sala com esse número!')),
      );
      return;
    }

    // Gera uma cor baseada no número da sala
    final corSala = _gerarCorSala(numeroSala);

    final dadosSala = {
      'numero_sala': numeroSala,
      'qtd_cadeiras': qtdCadeiras,
      'disponivel': _disponivel,
      'cor': _normalizeColor(corSala),
      'projetor': _projetor,
      'tv': _tv,
      'ar_condicionado': _arCondicionado,
    };

    print('Salvando sala: $dadosSala');
    print(
      'Valores dos switches: disponivel=$_disponivel, projetor=$_projetor, tv=$_tv, ar=$_arCondicionado',
    );

    try {
      final resultado = await supabase.from('salas').insert(dadosSala).select();
      print('Sala salva com sucesso: $resultado');
    } catch (e) {
      print('Erro ao salvar sala: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar sala: $e')));
      return;
    }
    await _buscarSalas(); // Adicione esta linha

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sala criada com sucesso!')));
    // Remova ou comente a linha abaixo para não sair da tela
    // Navigator.pop(context);
  }

  Future<void> _editarSalaDialog(Map<String, dynamic> sala) async {
    final numeroController = TextEditingController(
      text: sala['numero_sala'] ?? '',
    );
    final cadeirasController = TextEditingController(
      text: sala['qtd_cadeiras']?.toString() ?? '',
    );
    bool disponivel = sala['disponivel'] == true;
    bool projetor = sala['projetor'] == true;
    bool tv = sala['tv'] == true;
    bool arCondicionado = sala['ar_condicionado'] == true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _parseSalaColor(sala['cor']),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _parseSalaColor(
                                      sala['cor'],
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  sala['numero_sala'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Editar Sala',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF44A301),
                                    ),
                                  ),
                                  Text(
                                    'Sala ${sala['numero_sala']} - ${sala['qtd_cadeiras']} cadeiras',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Campos de entrada
                        TextFormField(
                          controller: numeroController,
                          decoration: InputDecoration(
                            labelText: 'Número da Sala',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            prefixIcon: const Icon(
                              Icons.confirmation_number,
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: const Color(
                              0xFF44A301,
                            ).withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: cadeirasController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantidade de Cadeiras',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                            ),
                            prefixIcon: const Icon(
                              Icons.chair,
                              color: Color(0xFF44A301),
                            ),
                            filled: true,
                            fillColor: const Color(
                              0xFF44A301,
                            ).withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF44A301),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Seção de equipamentos
                        const Text(
                          'Equipamentos Disponíveis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44A301),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Switches com design melhorado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              _buildSwitchTile(
                                'Disponível',
                                disponivel,
                                Icons.check_circle,
                                (value) =>
                                    setDialogState(() => disponivel = value),
                              ),
                              _buildSwitchTile(
                                'Projetor',
                                projetor,
                                Icons.videocam,
                                (value) =>
                                    setDialogState(() => projetor = value),
                              ),
                              _buildSwitchTile(
                                'TV',
                                tv,
                                Icons.tv,
                                (value) => setDialogState(() => tv = value),
                              ),
                              _buildSwitchTile(
                                'Ar Condicionado',
                                arCondicionado,
                                Icons.ac_unit,
                                (value) => setDialogState(
                                  () => arCondicionado = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botões de ação
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF44A301),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Color(0xFF44A301),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF44A301),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Salvar Alterações',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );

    if (result == true) {
      // Gera uma nova cor baseada no número da sala
      final novaCorSala = _gerarCorSala(numeroController.text.trim());
      await supabase
          .from('salas')
          .update({
            'numero_sala': numeroController.text.trim(),
            'qtd_cadeiras': int.tryParse(cadeirasController.text.trim()) ?? 0,
            'disponivel': disponivel,
            'cor': _normalizeColor(novaCorSala),
            'projetor': projetor,
            'tv': tv,
            'ar_condicionado': arCondicionado,
          })
          .match({'id': sala['id']});
      await _buscarSalas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sala atualizada com sucesso!')),
      );
    }
  }

  Future<void> _excluirSala(Map<String, dynamic> sala) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de aviso
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  const Text(
                    'Excluir Sala',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mensagem
                  Text(
                    'Tem certeza que deseja excluir a sala ${sala['numero_sala']}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Esta ação não pode ser desfeita.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Excluir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirm == true) {
      await supabase.from('salas').delete().match({'id': sala['id']});
      await _buscarSalas();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sala excluída com sucesso!')),
      );
    }
  }

  Color _parseSalaColor(dynamic cor) {
    if (cor == null) return const Color(0xFF44A301);

    try {
      int colorValue;

      if (cor is String) {
        String cleanCor = cor.trim();

        // Remove o prefixo 'ff' se existir (formato hexadecimal)
        if (cleanCor.startsWith('ff')) {
          cleanCor = cleanCor.substring(2);
        }

        // Remove o prefixo '#' se existir
        if (cleanCor.startsWith('#')) {
          cleanCor = cleanCor.substring(1);
        }

        // Verifica se é hexadecimal ou decimal
        if (cleanCor.contains(RegExp(r'[a-fA-F]', caseSensitive: false))) {
          // É hexadecimal
          colorValue = int.parse(cleanCor, radix: 16);
          // Adiciona o alpha se não estiver presente
          if (colorValue < 0xFF000000) {
            colorValue = 0xFF000000 | colorValue;
          }
        } else {
          // É decimal
          colorValue = int.parse(cleanCor);
        }
      } else if (cor is int) {
        colorValue = cor;
      } else {
        return const Color(0xFF44A301);
      }

      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF44A301); // Cor padrão se houver erro
    }
  }

  // Função auxiliar para normalizar cores
  String _normalizeColor(Color color) {
    return color.value.toString();
  }

  // Função para gerar cor baseada no número da sala
  Color _gerarCorSala(String numeroSala) {
    final cores = [
      Colors.green, // 1 - Verde
      Colors.yellow, // 2 - Amarelo
      Colors.red, // 3 - Vermelho
      const Color(0xFF44A301), // 4 - Verde
    ];

    // Usa o número da sala para escolher uma cor
    final numero = int.tryParse(numeroSala) ?? 0;
    return cores[(numero - 1) % cores.length];
  }

  // Widget para criar switch tiles personalizados
  Widget _buildSwitchTile(
    String title,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            value
                ? const Color(0xFF44A301).withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: value ? const Color(0xFF44A301) : Colors.grey,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: value ? const Color(0xFF44A301) : Colors.grey[700],
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF44A301),
          activeTrackColor: const Color(0xFF44A301).withOpacity(0.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF44A301), // Verde principal do tema
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nova Sala',
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
              decoration: const BoxDecoration(color: Color(0xFF44A301)),
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
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF44A301)),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF44A301)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Evento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarevento'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Color(0xFF44A301)),
              title: const Text(
                'Agendar Prova',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprova'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF44A301)),
              title: const Text(
                'Historico de Acoes',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/historicoacoes'),
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
                  color: const Color(0xFFE8F5E8), // verde bem claro
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
                          'Nova Sala',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF44A301),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _numeroSalaController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Número da Sala',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.confirmation_number,
                              color: Color(0xFF44A301),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _qtdCadeirasController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Quantidade de Cadeiras',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.chair,
                              color: Color(0xFF44A301),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SwitchListTile(
                          title: const Text(
                            'Disponível',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _disponivel,
                          activeColor: const Color(0xFF44A301),
                          onChanged: (val) => setState(() => _disponivel = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Projetor',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _projetor,
                          activeColor: const Color(0xFF44A301),
                          onChanged: (val) {
                            print('Projetor alterado para: $val');
                            setState(() => _projetor = val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'TV',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _tv,
                          activeColor: const Color(0xFF44A301),
                          onChanged: (val) {
                            print('TV alterada para: $val');
                            setState(() => _tv = val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Ar Condicionado',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _arCondicionado,
                          activeColor: const Color(0xFF44A301),
                          onChanged: (val) {
                            print('Ar condicionado alterado para: $val');
                            setState(() => _arCondicionado = val);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon:
                                _loadingSalas
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.save),
                            label: const Text('Salvar Sala'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF44A301),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                _loadingSalas
                                    ? null
                                    : () {
                                      _salvarSala();
                                      _numeroSalaController.clear();
                                      _qtdCadeirasController.clear();
                                      setState(() {
                                        _disponivel = true;
                                        _projetor = false;
                                        _tv = false;
                                        _arCondicionado = false;
                                      });
                                    },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lista de salas à direita (restante da tela)
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
                            hintText: 'Pesquisar sala ou cadeiras...',
                            hintStyle: const TextStyle(color: Colors.black45),
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
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Salas cadastradas:',
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
                              flex: 3,
                              child: Text(
                                'Sala',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Cadeiras',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Disponível',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Icon(
                                Icons.videocam,
                                color: Colors.black45,
                                size: 18,
                              ),
                            ), // Projetor
                            Expanded(
                              flex: 1,
                              child: Icon(
                                Icons.tv,
                                color: Colors.black45,
                                size: 18,
                              ),
                            ), // TV
                            Expanded(
                              flex: 1,
                              child: Icon(
                                Icons.ac_unit,
                                color: Colors.black45,
                                size: 18,
                              ),
                            ), // Ar
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Editar',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Excluir',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
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
                              _loadingSalas
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _salasFiltradas.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'Nenhuma sala cadastrada.',
                                      style: TextStyle(color: Colors.black45),
                                    ),
                                  )
                                  : ListView.separated(
                                    controller: _scrollController,
                                    itemCount: _salasFiltradas.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(
                                          color: Colors.black12,
                                          height: 1,
                                        ),
                                    itemBuilder: (context, index) {
                                      final sala = _salasFiltradas[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                        ),
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: _parseSalaColor(
                                                        sala['cor'],
                                                      ),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.08,
                                                              ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        sala['numero_sala'] ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${sala['qtd_cadeiras'] ?? ''}',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                sala['disponivel'] == true
                                                    ? 'Sim'
                                                    : 'Não',
                                                style: TextStyle(
                                                  color:
                                                      sala['disponivel'] == true
                                                          ? Colors.green
                                                          : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Icon(
                                                sala['projetor'] == true
                                                    ? Icons.videocam
                                                    : Icons.videocam_off,
                                                color:
                                                    sala['projetor'] == true
                                                        ? Colors.green
                                                        : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Icon(
                                                sala['tv'] == true
                                                    ? Icons.tv
                                                    : Icons.tv_off,
                                                color:
                                                    sala['tv'] == true
                                                        ? Colors.green
                                                        : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Icon(
                                                sala['ar_condicionado'] == true
                                                    ? Icons.ac_unit
                                                    : Icons.close,
                                                color:
                                                    sala['ar_condicionado'] ==
                                                            true
                                                        ? Colors.green
                                                        : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Color(0xFF44A301),
                                                  size: 20,
                                                ),
                                                tooltip: 'Editar',
                                                onPressed:
                                                    () =>
                                                        _editarSalaDialog(sala),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                tooltip: 'Excluir',
                                                onPressed:
                                                    () => _excluirSala(sala),
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
