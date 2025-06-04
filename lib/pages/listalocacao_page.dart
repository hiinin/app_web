import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'criarlocacao_page.dart';

class ListaLocacaoPage extends StatefulWidget {
  const ListaLocacaoPage({super.key});

  @override
  State<ListaLocacaoPage> createState() => _ListaLocacaoPageState();
}

class _ListaLocacaoPageState extends State<ListaLocacaoPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  List<dynamic> agendamentos = [];

  DateTime diaSelecionado = DateTime.now();

  List<Map<String, dynamic>> cursos = [];
  int? cursoSelecionadoId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> selecionarDia() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: diaSelecionado,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => diaSelecionado = picked);
      carregarAgendamentos();
    }
  }

  Future<void> carregarAgendamentos({int? cursoId}) async {
    setState(() => isLoading = true);

    try {
      final diaStr =
          '${diaSelecionado.year.toString().padLeft(4, '0')}-${diaSelecionado.month.toString().padLeft(2, '0')}-${diaSelecionado.day.toString().padLeft(2, '0')}';

      var query = supabase.from('agendamento').select('''
      id,
      dia,
      aula_periodo,
      hora_inicio,
      hora_fim,
      cursos (
        id,
        curso,
        semestre,
        periodo
      ),
      salas (
        id,I
        numero_sala
      )
    ''');

      query = query.eq('dia', diaStr);

      if (cursoId != null) {
        query = query.eq('curso_id', cursoId);
      }

      final response = await query;

      setState(() => agendamentos = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> buscarPorCurso() async {
    if (cursoSelecionadoId == null) {
      print('Nenhum curso selecionado');
      return;
    }

    final response =
        await supabase
            .from('agendamento')
            .select()
            .eq('curso_id', cursoSelecionadoId)
            .execute();

    if (response.status == 200) {
      // final dados = response.data as List<dynamic>; // Removido: variável não utilizada
      // Atualize a lista com os dados obtidos, se necessário
    } else {
      print('Erro na busca: ${response.status}');
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

  Future<void> editarAgendamento(Map agendamento) async {
    final cursoAtual = agendamento['cursos'];
    final salaAtual = agendamento['salas'];

    final novoCursoController = TextEditingController(
      text: cursoAtual['curso'],
    );
    final novoSemestreController = TextEditingController(
      text: cursoAtual['semestre'].toString(),
    );
    final novoPeriodoController = TextEditingController(
      text: agendamento['aula_periodo'],
    );
    final novaSalaController = TextEditingController(
      text: salaAtual['numero_sala'].toString(),
    );

    final hoje = DateTime.now();
    final dataMinima = DateTime(hoje.year, hoje.month, hoje.day);

    final novaData = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(agendamento['dia']),
      firstDate: dataMinima,
      lastDate: DateTime(2030),
    );

    if (novaData == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Agendamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: novoCursoController,
                  decoration: const InputDecoration(labelText: 'Curso'),
                ),
                TextField(
                  controller: novoSemestreController,
                  decoration: const InputDecoration(labelText: 'Semestre'),
                ),
                TextField(
                  controller: novoPeriodoController,
                  decoration: const InputDecoration(
                    labelText: 'Período da Aula',
                  ),
                ),
                TextField(
                  controller: novaSalaController,
                  decoration: const InputDecoration(labelText: 'Sala'),
                ),
              ],
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

    if (confirmar == true) {
      try {
        await supabase
            .from('agendamento')
            .update({
              'aula_periodo': novoPeriodoController.text,
              'dia':
                  '${novaData.year.toString().padLeft(4, '0')}-${novaData.month.toString().padLeft(2, '0')}-${novaData.day.toString().padLeft(2, '0')}',
            })
            .eq('id', agendamento['id']);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agendamento atualizado')));
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> excluirAgendamento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir este agendamento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('agendamento').delete().eq('id', id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agendamento excluído')));
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Alocações')),
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
      body: Row(
        children: [
          // Lado esquerdo: filtros
          Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Data selecionada:'),
                Text(
                  '${diaSelecionado.day.toString().padLeft(2, '0')}/${diaSelecionado.month.toString().padLeft(2, '0')}/${diaSelecionado.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Selecionar Dia'),
                  onPressed: selecionarDia,
                ),
                const Divider(height: 32),
                const Text('Selecionar Curso:'),
                const SizedBox(height: 8),

                // Dropdown para cursos
                DropdownButtonFormField<int>(
                  value: cursoSelecionadoId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  hint: const Text('Escolha um curso'),
                  items:
                      cursos.map((curso) {
                        return DropdownMenuItem<int>(
                          value: curso['id'],
                          child: Text(curso['curso']),
                        );
                      }).toList(),
                  onChanged: (int? valor) {
                    setState(() {
                      cursoSelecionadoId = valor;
                    });
                  },
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  onPressed: () {
                    if (cursoSelecionadoId != null) {
                      carregarAgendamentos(cursoId: cursoSelecionadoId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um curso primeiro'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Lado direito: lista expandida
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : agendamentos.isEmpty
                    ? const Center(child: Text('Nenhum agendamento encontrado'))
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('Dia')),
                          DataColumn(label: Text('Curso')),
                          DataColumn(label: Text('Semestre')),
                          DataColumn(label: Text('Sala')),
                          DataColumn(label: Text('Período')),
                          DataColumn(label: Text('Aula')),
                          DataColumn(label: Text('Início')),
                          DataColumn(label: Text('Fim')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows:
                            agendamentos.map((agendamento) {
                              final curso = agendamento['cursos'];
                              final sala = agendamento['salas'];
                              final horaInicio = agendamento['hora_inicio'];
                              final horaFim = agendamento['hora_fim'];
                              final dia = DateTime.parse(agendamento['dia']);
                              final dataFormatada =
                                  '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';

                              return DataRow(
                                cells: [
                                  DataCell(Text(dataFormatada)),
                                  DataCell(Text(curso?['curso'] ?? '')),
                                  DataCell(
                                    Text('Sem. ${curso?['semestre'] ?? '-'}'),
                                  ),
                                  DataCell(
                                    Text('${sala?['numero_sala'] ?? '-'}'),
                                  ),
                                  DataCell(
                                    Text(periodoToString(curso?['periodo'])),
                                  ),
                                  DataCell(
                                    Text(agendamento['aula_periodo'] ?? ''),
                                  ),
                                  DataCell(
                                    Text(
                                      horaInicio?.toString().substring(0, 5) ??
                                          '',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      horaFim?.toString().substring(0, 5) ?? '',
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => editarAgendamento(
                                                agendamento,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => excluirAgendamento(
                                                agendamento['id'],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  final TextEditingController cursoController = TextEditingController();

  @override
  void dispose() {
    cursoController.dispose();
    super.dispose();
  }
}
