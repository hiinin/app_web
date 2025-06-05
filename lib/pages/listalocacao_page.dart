import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        id,
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
    final salaAtual = agendamento['salas'];

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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: novaSalaController,
                    decoration: const InputDecoration(labelText: 'Sala'),
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

    if (confirmar == true) {
      try {
        // Buscar o id da sala pelo número informado
        final salaResult =
            await supabase
                .from('salas')
                .select('id')
                .eq('numero_sala', novaSalaController.text.trim())
                .maybeSingle();
        if (salaResult == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sala não encontrada!')));
          return;
        }
        await supabase
            .from('agendamento')
            .update({
              'sala_id': salaResult['id'],
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
      appBar: AppBar(
        title: const Text(
          'Lista de Alocações',
          style: TextStyle(color: Colors.white),
        ),
        toolbarHeight: 80,
        backgroundColor: const Color.fromARGB(255, 41, 123, 216),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[800]),
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
                    leading: const Icon(
                      Icons.home,
                      color: Color.fromARGB(255, 41, 123, 216),
                    ),
                    title: const Text(
                      'Início',
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.school,
                      color: Color.fromARGB(255, 41, 123, 216),
                    ),
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
                      'Criar Sala',
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2025 RH Company',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Lado esquerdo: filtros
          Container(
            width: 390, // aumentei a largura do painel de filtros
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE3EAFD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Selecione o dia:'),
                SizedBox(
                  height: 320,
                  child: CalendarDatePicker(
                    initialDate: diaSelecionado,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    onDateChanged: (picked) {
                      setState(() {
                        diaSelecionado = picked;
                        carregarAgendamentos();
                      });
                    },
                  ),
                ),
                // Removido o Dropdown de curso e botão buscar
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Lado direito: lista expandida
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      color: const Color(0xFFF5F6FA),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              top: 18,
                              left: 18,
                              right: 18,
                              bottom: 0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFE3EAFD),
                              ),
                              headingTextStyle: const TextStyle(
                                color: Color(0xFF297BD8),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              dataRowColor: MaterialStateProperty.resolveWith<
                                Color?
                              >((states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return const Color(
                                    0xFFE3EAFD,
                                  ).withOpacity(0.45); // leve azul
                                }
                                return Colors.transparent;
                              }),
                              dataTextStyle: const TextStyle(
                                color: Color(0xFF222B45),
                                fontSize: 14,
                              ),
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
                                  agendamentos.isEmpty
                                      ? [
                                        DataRow(
                                          cells: [
                                            const DataCell(
                                              Text(
                                                'Nenhum agendamento encontrado',
                                              ),
                                            ),
                                            ...List.generate(
                                              8,
                                              (index) =>
                                                  const DataCell(Text('')),
                                            ),
                                          ],
                                        ),
                                      ]
                                      : agendamentos.map((agendamento) {
                                        final curso = agendamento['cursos'];
                                        final sala = agendamento['salas'];
                                        final horaInicio =
                                            agendamento['hora_inicio'];
                                        final horaFim = agendamento['hora_fim'];
                                        final dia = DateTime.parse(
                                          agendamento['dia'],
                                        );
                                        final dataFormatada =
                                            '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(dataFormatada)),
                                            DataCell(
                                              Text(curso?['curso'] ?? ''),
                                            ),
                                            DataCell(
                                              Text(
                                                'Sem. ${curso?['semestre'] ?? '-'}',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${sala?['numero_sala'] ?? '-'}',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                periodoToString(
                                                  curso?['periodo'],
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                agendamento['aula_periodo'] ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                horaInicio
                                                        ?.toString()
                                                        .substring(0, 5) ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                horaFim?.toString().substring(
                                                      0,
                                                      5,
                                                    ) ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Color(0xFF297BD8),
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
                                                        () =>
                                                            excluirAgendamento(
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
                        ],
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
