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

  @override
  void initState() {
    super.initState();
    carregarAgendamentos();
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

  Future<void> carregarAgendamentos() async {
    setState(() => isLoading = true);
    try {
      final diaStr =
          '${diaSelecionado.year.toString().padLeft(4, '0')}-${diaSelecionado.month.toString().padLeft(2, '0')}-${diaSelecionado.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('agendamento')
          .select('''
            id,
            dia,
            aula_periodo,
            hora_inicio,
            hora_fim,
            cursos(id, curso, semestre, periodo),
            salas(id, numero_sala)
          ''')
          .eq('dia', diaStr)
          .order('dia');

      setState(() => agendamentos = response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
      );
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
    final dataMinima = DateTime(hoje.year, hoje.month, hoje.day); // Zera a hora

    final novaData = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(agendamento['dia']),
      firstDate: dataMinima, // impede datas anteriores
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
    final String textoDia =
        '${diaSelecionado.day.toString().padLeft(2, '0')}/${diaSelecionado.month.toString().padLeft(2, '0')}/${diaSelecionado.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Alocações'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_business,
                    color: Colors.black87,
                  ),
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
                  leading: const Icon(
                    Icons.meeting_room,
                    color: Colors.black87,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: selecionarDia,
              icon: const Icon(Icons.calendar_today),
              label: Text(textoDia),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : agendamentos.isEmpty
                    ? const Center(child: Text('Nenhum agendamento encontrado'))
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                            DataColumn(label: Text('Dia')),
                            DataColumn(label: Text('Curso')),
                            DataColumn(label: Text('Semestre')),
                            DataColumn(label: Text('Sala')),
                            DataColumn(label: Text('Período')),
                            DataColumn(label: Text('Aula')),     // AULA antes!
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
                                  DataCell(Text(curso['curso'] ?? '')),
                                  DataCell(Text('Sem. ${curso['semestre']}')),
                                  DataCell(Text('${sala['numero_sala']}')),
                                  DataCell(
                                    Text(periodoToString(curso['periodo'])), ),
                                  DataCell(Text(agendamento['aula_periodo'] ?? '')),

                                  DataCell(Text(horaInicio != null
                                      ? horaInicio.toString().substring(0, 5)
                                      : '')),
                                  DataCell(Text(horaFim != null
                                      ? horaFim.toString().substring(0, 5)
                                      : '')), DataCell(
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
}