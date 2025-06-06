import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart' as sala_model;
import '../models/curso.dart' as curso_model;

class CriarLocacaoPage extends StatefulWidget {
  const CriarLocacaoPage({super.key});

  @override
  State<CriarLocacaoPage> createState() => _CriarLocacaoPageState();
}

class _CriarLocacaoPageState extends State<CriarLocacaoPage> {
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
        cursos.sort((a, b) => a.curso.toLowerCase().compareTo(b.curso.toLowerCase())); // Ordena alfabeticamente
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
        'curso_id': cursoSelecionado!.id,
      });

      await supabase
          .from('salas')
          .update({'disponivel': false})
          .eq('id', salaSelecionada!.id);

      if (!mounted) return;
      setState(() {
        salaSelecionada = null;
        cursoSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alocação salva com sucesso')),
      );
      carregarDados(); // Atualiza as opções após salvar
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar alocação: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  String periodoToString(int? periodo) {
    switch (periodo) {
      case 1:
        return 'Matutino';
      case 2:
        return 'Vespertino';
      case 3:
        return 'Noturno';
      default:
        return 'Não informado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nova Alocação',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Sair',
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
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_business, color: Colors.black87),
                    title: const Text('Nova Alocação', style: TextStyle(color: Colors.black87)),
                    onTap: () => Navigator.pop(context),
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
                    leading: const Icon(Icons.meeting_room, color: Colors.black87),
                    title: const Text('Nova Sala', style: TextStyle(color: Colors.black87)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/criarsala');
                    },
                  ),
                ],
              ),
            ),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8, // 80% da tela
                    ),
                    child: Card(
                      color: Colors.grey[850],
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Preencha os dados para alocar uma sala',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<sala_model.Sala>(
                              value: salaSelecionada,
                              decoration: InputDecoration(
                                labelText: 'Selecione a Sala',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.grey[900],
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
                              ),
                              dropdownColor: Colors.grey[900],
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              items: salas
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        '${s.numeroSala} - ${s.qtdCadeiras} cadeiras',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => salaSelecionada = value);
                              },
                              validator: (value) =>
                                  value == null ? 'Selecione uma sala' : null,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<curso_model.Curso>(
                              value: cursoSelecionado,
                              decoration: InputDecoration(
                                labelText: 'Selecione o Curso',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.grey[900],
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
                              ),
                              dropdownColor: Colors.grey[900],
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              items: cursos
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.curso} - ${c.semestre ?? "Semestre?"} - ${c.periodo != null ? periodoToString(c.periodo) : "Período?"}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  cursoSelecionado = value;
                                });
                                print('Selecionado: ${cursoSelecionado?.curso}, ${cursoSelecionado?.semestre}, ${cursoSelecionado?.periodo}');
                              },
                              validator: (value) => value == null ? 'Selecione um curso' : null,
                            ),
                            if (cursoSelecionado != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Curso: ${cursoSelecionado!.curso}',
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: const BoxDecoration(
                                            color: Colors.blue, // Cor da bolinha
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(
                                          'Semestre: ${cursoSelecionado!.semestre ?? "Não informado"}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Período: ${periodoToString(cursoSelecionado!.periodo)}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: salvarLocacao,
                                label: const Text('Alocar Sala'),
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
