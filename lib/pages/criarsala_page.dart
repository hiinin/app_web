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
      'cor': _corSelecionada.value.toRadixString(16), // Salva cor como string hexadecimal
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sala criada com sucesso!')),
    );
    // Remova ou comente a linha abaixo para não sair da tela
    // Navigator.pop(context);
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
              leading: const Icon(Icons.list_alt, color: Colors.black87),
              title: const Text('Lista de Alocações', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listalocacao');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_business, color: Colors.black87),
              title: const Text('Nova Alocação', style: TextStyle(color: Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/criarlocacao');
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8, // 80% da largura da tela
              ),
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
        ),
      ),
    );
  }
}