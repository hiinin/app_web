import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/curso.dart';

class CriarMateriaPage extends StatefulWidget {
  const CriarMateriaPage({super.key});

  @override
  State<CriarMateriaPage> createState() => _CriarMateriaPageState();
}

class _CriarMateriaPageState extends State<CriarMateriaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeMateriaController = TextEditingController();
  List<Curso> _cursos = [];
  Curso? _cursoSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _buscarCursos();
  }

  Future<void> _buscarCursos() async {
    final data = await Supabase.instance.client.from('cursos').select();
    setState(() {
      _cursos = (data as List).map((e) => Curso.fromMap(e)).toList();
    });
  }

  Future<void> _salvarMateria() async {
    if (!_formKey.currentState!.validate() || _cursoSelecionado == null) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('materias').insert({
        'nome': _nomeMateriaController.text.trim(),
        'curso_id': _cursoSelecionado!.id,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matéria criada com sucesso!')),
      );
      _nomeMateriaController.clear();
      setState(() => _cursoSelecionado = null);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar matéria: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar Matéria',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black87),
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
              leading: const Icon(Icons.add_business, color: Colors.black87),
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
              leading: const Icon(Icons.list_alt, color: Colors.black87),
              title: const Text(
                'Lista de Alocações',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listalocacao');
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Colors.black87),
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
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              color: Colors.grey[850],
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nova Matéria',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nomeMateriaController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nome da Matéria',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Informe o nome da matéria'
                                    : null,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<Curso>(
                        value: _cursoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Curso',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                        ),
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        items:
                            _cursos
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      '${c.curso} - ${c.semestre ?? "Semestre?"}',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (c) => setState(() => _cursoSelecionado = c),
                        validator:
                            (v) => v == null ? 'Selecione o curso' : null,
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
                          label: const Text('Salvar Matéria'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _salvarMateria,
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
    );
  }
}
