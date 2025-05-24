import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;
import 'criarlocacao_page.dart';
import 'listalocacao_page.dart'; // Importe a página da lista

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  List<sala_model.Sala> salas = [];
  List<curso_model.Curso> cursos = [];
  List<Map<String, dynamic>> alocacoes = [];

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

      final responseAlocacoes = await supabase
          .from('alocacoes')
          .select('id, sala:salas(numero_sala), curso:cursos(curso)');

      setState(() {
        salas =
            (responseSalas as List)
                .map((e) => sala_model.Sala.fromMap(e))
                .toList();
        cursos =
            (responseCursos as List)
                .map((e) => curso_model.Curso.fromMap(e))
                .toList();
        alocacoes = List<Map<String, dynamic>>.from(responseAlocacoes);
      });
      print('Salas carregadas: ${salas.length}');
      print('Cursos carregados: ${cursos.length}');
      print('Alocações carregadas: ${alocacoes.length}');
    } catch (e) {
      if (!mounted) return; // Para evitar erro de uso do context após async gap
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> salvarLocacao() async {
    if (salaSelecionada == null || cursoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione sala e curso')));
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.from('alocacoes').insert({
        'sala_id': salaSelecionada!.id,
        'curso_id': cursoSelecionado!.id, // Corrigido para usar o ID do curso
      });

      await supabase
          .from('salas')
          .update({'disponivel': false})
          .eq('id', salaSelecionada!.id);

      await carregarDados();

      if (!mounted) return;
      setState(() {
        salaSelecionada = null;
        cursoSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alocação salva com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar alocação: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Drawer icon branco
        title: const Text(
          'Painel de Alocação de Salas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
              leading: const Icon(Icons.add_business, color: Colors.black87),
              title: const Text(
                'Nova Alocação',
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
                'Lista de Alocações',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: Colors.black, // ÍCONE PRETO
              ),
              const SizedBox(height: 24),
              const Text(
                'Bem-vindo, Administrador!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // TEXTO PRETO
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'O que deseja fazer?',
                style: TextStyle(fontSize: 18, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_business, size: 18, color: Colors.black),
                      label: const Text(
                        'Criar Nova Alocação',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 38),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CriarLocacaoPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.list_alt,
                        color: Colors.black,
                        size: 18,
                      ),
                      label: const Text(
                        'Ver Lista de Alocações',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 38),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ListaLocacaoPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.meeting_room, color: Colors.black, size: 18),
                      label: const Text(
                        'Criar Nova Sala',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 38),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/criarsala');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
