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
          .select(
            'id, numero_sala, qtd_cadeiras, disponivel, cor, projetor, tv, ar_condicionado',
          )
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
    bool disponivel = sala['disponivel'] ?? true;
    bool projetor = sala['projetor'] ?? false;
    bool tv = sala['tv'] ?? false;
    bool arCondicionado = sala['ar_condicionado'] ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Sala'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numeroController,
                    decoration: const InputDecoration(
                      labelText: 'Número da Sala',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cadeirasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de Cadeiras',
                    ),
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
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir sala'),
            content: const Text('Tem certeza que deseja excluir esta sala?'),
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
        backgroundColor: const Color.fromARGB(255, 41, 123, 216),
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
                Icons.school,
                color: Color.fromARGB(255, 41, 123, 216),
              ),
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
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
            padding: const EdgeInsets.all(0), // Remove padding externo
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário à esquerda (40% da tela)
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height - 80,
                  color: const Color(0xFFE3EAFD), // azul bem claro
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
                            color: Color(0xFF297BD8),
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
                              color: Color(0xFF297BD8),
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
                              color: Color(0xFF297BD8),
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
                          activeColor: const Color(0xFF297BD8),
                          onChanged: (val) => setState(() => _disponivel = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Projetor',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _projetor,
                          activeColor: const Color(0xFF297BD8),
                          onChanged: (val) => setState(() => _projetor = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'TV',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _tv,
                          activeColor: const Color(0xFF297BD8),
                          onChanged: (val) => setState(() => _tv = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Ar Condicionado',
                            style: TextStyle(color: Colors.black),
                          ),
                          value: _arCondicionado,
                          activeColor: const Color(0xFF297BD8),
                          onChanged:
                              (val) => setState(() => _arCondicionado = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text(
                              'Cor da Sala:',
                              style: TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () async {
                                final cor = await showDialog<Color>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Escolha uma cor'),
                                        content: SingleChildScrollView(
                                          child: BlockPicker(
                                            pickerColor: _corSelecionada,
                                            onColorChanged:
                                                (color) => Navigator.of(
                                                  context,
                                                ).pop(color),
                                          ),
                                        ),
                                      ),
                                );
                                if (cor != null)
                                  setState(() => _corSelecionada = cor);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _corSelecionada,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black12,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.color_lens,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
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
                              backgroundColor: const Color(0xFF297BD8),
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
                                                    child: Text(
                                                      sala['numero_sala'] ?? '',
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
                                                    ? Icons.check
                                                    : Icons.close,
                                                color:
                                                    sala['projetor'] == true
                                                        ? Colors.green
                                                        : Colors.red,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Icon(
                                                sala['tv'] == true
                                                    ? Icons.check
                                                    : Icons.close,
                                                color:
                                                    sala['tv'] == true
                                                        ? Colors.green
                                                        : Colors.red,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Icon(
                                                sala['ar_condicionado'] == true
                                                    ? Icons.check
                                                    : Icons.close,
                                                color:
                                                    sala['ar_condicionado'] ==
                                                            true
                                                        ? Colors.green
                                                        : Colors.red,
                                                size: 18,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Color(0xFF297BD8),
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
