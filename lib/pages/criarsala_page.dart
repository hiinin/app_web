import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  Color _corSelecionada = Colors.blue;

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
          .select('id, numero_sala, qtd_cadeiras, disponivel, cor, projetor, tv, ar_condicionado')
          .order('numero_sala');
      setState(() {
        _salas = List<Map<String, dynamic>>.from(data);
        _filtrarSalas();
      });
    } catch (e) {
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
        _salasFiltradas = _salas.where((sala) {
          final numero = (sala['numero_sala'] ?? '').toString().toLowerCase();
          final cadeiras = (sala['qtd_cadeiras'] ?? '').toString().toLowerCase();
          return numero.contains(query) || cadeiras.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _salvarSala() async {
    final numeroSala = _numeroSalaController.text.trim();
    final qtdCadeiras = int.tryParse(_qtdCadeirasController.text.trim()) ?? 0;

    if (numeroSala.isEmpty || qtdCadeiras <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
      return;
    }

    // Verifica se já existe uma sala com o mesmo número
    final existe = await supabase
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

    // Salva a sala
    await supabase.from('salas').insert({
      'numero_sala': numeroSala,
      'qtd_cadeiras': qtdCadeiras,
      'disponivel': _disponivel,
      'cor': _corSelecionada.value.toRadixString(16).padLeft(8, '0'),
      'projetor': _projetor,
      'tv': _tv,
      'ar_condicionado': _arCondicionado,
    });
    await _buscarSalas(); // Adicione esta linha

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sala criada com sucesso!')),
    );
    // Remova ou comente a linha abaixo para não sair da tela
    // Navigator.pop(context);
  }

  Future<void> _editarSalaDialog(Map<String, dynamic> sala) async {
    final numeroController = TextEditingController(text: sala['numero_sala'] ?? '');
    final cadeirasController = TextEditingController(text: sala['qtd_cadeiras']?.toString() ?? '');
    bool disponivel = sala['disponivel'] ?? true;
    bool projetor = sala['projetor'] ?? false;
    bool tv = sala['tv'] ?? false;
    bool arCondicionado = sala['ar_condicionado'] ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Sala'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroController,
                decoration: const InputDecoration(labelText: 'Número da Sala'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cadeirasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade de Cadeiras'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Disponível'),
                value: disponivel,
                onChanged: (v) => disponivel = v,
              ),
              SwitchListTile(
                title: const Text('Projetor'),
                value: projetor,
                onChanged: (v) => projetor = v,
              ),
              SwitchListTile(
                title: const Text('TV'),
                value: tv,
                onChanged: (v) => tv = v,
              ),
              SwitchListTile(
                title: const Text('Ar Condicionado'),
                value: arCondicionado,
                onChanged: (v) => arCondicionado = v,
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
      await supabase
          .from('salas')
          .update({
            'numero_sala': numeroController.text.trim(),
            'qtd_cadeiras': int.tryParse(cadeirasController.text.trim()) ?? 0,
            'disponivel': disponivel,
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
      builder: (context) => AlertDialog(
        title: const Text('Excluir sala'),
        content: const Text('Tem certeza que deseja excluir esta sala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    if (cor == null) return Colors.white;
    String corStr = cor.toString().toUpperCase().replaceAll('#', '');
    // Se vier só com 6 dígitos (RGB), adiciona FF (opacidade máxima)
    if (corStr.length == 6) corStr = 'FF$corStr';
    try {
      return Color(int.parse('0x$corStr'));
    } catch (_) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sala'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
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
                    leading: const Icon(Icons.home, color: Colors.black87),
                    title: const Text('Início', style: TextStyle(color: Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_business, color: Colors.black87),
                    title: const Text('Novo Agendamento', style: TextStyle(color: Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/criarlocacao');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school, color: Colors.black87),
                    title: const Text(
                      'Criar Curso',
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
                  
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.black87),
                    title: const Text('Lista de Alocações', style: TextStyle(color: Colors.black87)),
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
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // 80% da tela
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Formulário
                  Expanded(
                    flex: 4,
                    child: Card(
                      color: Colors.grey[900],
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room, size: 48, color: Color(0xFF1976D2)),
                                const SizedBox(height: 18),
                                const Text(
                                  "Cadastrar Nova Sala",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                TextFormField(
                                  controller: _numeroSalaController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Número da Sala',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.grey[850],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.confirmation_number, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _qtdCadeirasController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Quantidade de Cadeiras',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.grey[850],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.chair, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SwitchListTile(
                                  title: const Text('Disponível', style: TextStyle(color: Colors.white)),
                                  value: _disponivel,
                                  activeColor: const Color(0xFF1976D2),
                                  onChanged: (val) => setState(() => _disponivel = val),
                                ),
                                const SizedBox(height: 18),
                                SwitchListTile(
                                  title: const Text('Projetor', style: TextStyle(color: Colors.white)),
                                  value: _projetor,
                                  activeColor: const Color(0xFF1976D2),
                                  onChanged: (val) => setState(() => _projetor = val),
                                ),
                                SwitchListTile(
                                  title: const Text('TV', style: TextStyle(color: Colors.white)),
                                  value: _tv,
                                  activeColor: const Color(0xFF1976D2),
                                  onChanged: (val) => setState(() => _tv = val),
                                ),
                                SwitchListTile(
                                  title: const Text('Ar Condicionado', style: TextStyle(color: Colors.white)),
                                  value: _arCondicionado,
                                  activeColor: const Color(0xFF1976D2),
                                  onChanged: (val) => setState(() => _arCondicionado = val),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Text('Cor da Sala:', style: TextStyle(color: Colors.white)),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () async {
                                        final cor = await showDialog<Color>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Escolha uma cor'),
                                            content: SingleChildScrollView(
                                              child: BlockPicker(
                                                pickerColor: _corSelecionada,
                                                onColorChanged: (color) =>
                                                    Navigator.of(context).pop(color),
                                              ),
                                            ),
                                          ),
                                        );
                                        if (cor != null) setState(() => _corSelecionada = cor);
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _corSelecionada,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.color_lens, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.save, color: Colors.white),
                                    label: const Text("Salvar Sala"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: () {
                                      _salvarSala();
                                      _numeroSalaController.clear();
                                      _qtdCadeirasController.clear();
                                      setState(() {
                                        _disponivel = true;
                                        _corSelecionada = Colors.blue;
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Lista de salas
                  Expanded(
                    flex: 7,
                    child: Card(
                      color: Colors.grey[850],
                      elevation: 10,
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
                                hintText: 'Pesquisar sala ou cadeiras...',
                                hintStyle: TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Salas cadastradas:',
                              style: TextStyle(
                                color: Colors.white,
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
                                      color: Colors.white70,
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
                                      color: Colors.white70,
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
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Icon(Icons.videocam, color: Colors.white70, size: 18),
                                ), // Projetor
                                Expanded(
                                  flex: 1,
                                  child: Icon(Icons.tv, color: Colors.white70, size: 18),
                                ), // TV
                                Expanded(
                                  flex: 1,
                                  child: Icon(Icons.ac_unit, color: Colors.white70, size: 18),
                                ), // Ar
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Editar',
                                    style: TextStyle(
                                      color: Colors.white70,
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
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, thickness: 1, height: 20),
                            Expanded(
                              child: _loadingSalas
                                  ? const Center(child: CircularProgressIndicator())
                                  : _salasFiltradas.isEmpty
                                      ? const Text(
                                          'Nenhuma sala cadastrada.',
                                          style: TextStyle(color: Colors.white70),
                                        )
                                      : Scrollbar(
                                          thumbVisibility: true,
                                          controller: _scrollController,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 8), // Afasta a barra da borda
                                            child: ListView.builder(
                                              controller: _scrollController,
                                              itemCount: _salasFiltradas.length,
                                              itemBuilder: (context, index) {
                                                final sala = _salasFiltradas[index];
                                                return Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[800],
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.18),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(width: 10), // Espaço menor à esquerda da bolinha
                                                        Expanded(
                                                          flex: 3,
                                                          child: Stack(
                                                            alignment: Alignment.centerLeft,
                                                            children: [
                                                              // Bola colorida atrás do texto, com shadow escuro
                                                              Container(
                                                                margin: const EdgeInsets.only(left: 0, right: 12),
                                                                width: 44,
                                                                height: 44,
                                                                decoration: BoxDecoration(
                                                                  color: _parseSalaColor(sala['cor']),
                                                                  shape: BoxShape.circle,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors.black.withOpacity(0.5), // shadow escuro
                                                                      blurRadius: 10,
                                                                      offset: const Offset(0, 4),
                                                                    ),
                                                                  ],
                                                                ),
                                                                alignment: Alignment.center,
                                                                child: Text(
                                                                  sala['numero_sala'] ?? '',
                                                                  textAlign: TextAlign.center,
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 20,
                                                                    fontWeight: FontWeight.bold,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: Colors.black54,
                                                                        blurRadius: 6,
                                                                        offset: Offset(0, 2),
                                                                      ),
                                                                    ],
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
                                                              color: Colors.white70,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                            sala['disponivel'] == true ? 'Sim' : 'Não',
                                                            style: TextStyle(
                                                              color: sala['disponivel'] == true ? Colors.green : Colors.red,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Icon(
                                                            sala['projetor'] == true ? Icons.check : Icons.close,
                                                            color: sala['projetor'] == true ? Colors.green : Colors.red,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Icon(
                                                            sala['tv'] == true ? Icons.check : Icons.close,
                                                            color: sala['tv'] == true ? Colors.green : Colors.red,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Icon(
                                                            sala['ar_condicionado'] == true ? Icons.check : Icons.close,
                                                            color: sala['ar_condicionado'] == true ? Colors.green : Colors.red,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: IconButton(
                                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                                                            tooltip: 'Editar',
                                                            onPressed: () => _editarSalaDialog(sala),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                                            tooltip: 'Excluir',
                                                            onPressed: () => _excluirSala(sala),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                            ),
                          ],
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