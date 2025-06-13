import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaLocacaoPage extends StatefulWidget {
  const ListaLocacaoPage({super.key});

  @override
  State<ListaLocacaoPage> createState() => _ListaLocacaoPageState();
}

// No início do _ListaLocacaoPageState
final TextEditingController pesquisaController = TextEditingController();
String filtroCurso = '';

@override
void dispose() {
  pesquisaController.dispose();
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
    carregarAgendamentos(); // Adicione esta linha
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
      cursos (id,curso,semestre,periodo),
      salas (id,numero_sala),
      materias (id,nome),
      professores (id,nome_professor)
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
        backgroundColor: const Color(
          0xFF1E40AF,
        ), // Azul principal igual criarcurso
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lista Agendamento',
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A), // Azul escuro
                    Color(0xFF3B82F6), // Azul médio
                  ],
                ),
              ),
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
              leading: const Icon(Icons.home, color: Color(0xFF1E40AF)),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF1E40AF)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF1E40AF)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF1E40AF)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
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
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: const Color(
                          0xFF1E40AF,
                        ), // Azul escuro para o dia selecionado
                        onPrimary:
                            Colors.white, // Texto branco no dia selecionado
                      ),
                    ),
                    child: CalendarDatePicker(
                      initialDate: diaSelecionado,
                      currentDate:
                          DateTime.now(), // <-- ESSA LINHA faz o dia selecionado ficar azul escuro
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: pesquisaController,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar curso...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            filtroCurso = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 52),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_box),
                        label: const Text('Novo Agendamento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/criarlocacao');
                        },
                      ),
                    ],
                  ),
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
                    : Container(
                      color: const Color(0xFFF5F6FA),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (agendamentos.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Text(
                                'Cursos com agendamentos cadastrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(18),
                              children: [
                                ...[1, 2, 3].expand((periodo) {
                                  final Map<int, Map<String, dynamic>>
                                  cursosUnicos = {};
                                  for (final ag in agendamentos) {
                                    final curso = ag['cursos'];
                                    if (curso != null &&
                                        curso['periodo'] == periodo) {
                                      cursosUnicos[curso['id']] = curso;
                                    }
                                  }
                                  if (cursosUnicos.isEmpty) return <Widget>[];

                                  String tituloPeriodo;
                                  switch (periodo) {
                                    case 1:
                                      tituloPeriodo = 'Manhã';
                                      break;
                                    case 2:
                                      tituloPeriodo = 'Vespertino';
                                      break;
                                    case 3:
                                      tituloPeriodo = 'Noturno';
                                      break;
                                    default:
                                      tituloPeriodo = 'Outro';
                                  }

                                  return [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        tituloPeriodo,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                    ...cursosUnicos.values
                                        .where(
                                          (curso) =>
                                              filtroCurso.isEmpty ||
                                              (curso['curso'] ?? '')
                                                  .toLowerCase()
                                                  .contains(filtroCurso),
                                        )
                                        .map((curso) {
                                          final agsDoCurso =
                                              agendamentos
                                                  .where(
                                                    (ag) =>
                                                        ag['cursos']?['id'] ==
                                                        curso['id'],
                                                  )
                                                  .toList();
                                          final Set<String> chavesUnicas = {};
                                          final List<dynamic> agsUnicos = [];
                                          for (final ag in agsDoCurso) {
                                            final chave =
                                                '${ag['sala_id']}_${ag['curso_id']}_${ag['dia']}_${ag['periodo']}_${ag['aula_periodo']}';
                                            if (!chavesUnicas.contains(chave)) {
                                              chavesUnicas.add(chave);
                                              agsUnicos.add(ag);
                                            }
                                          }
                                          return Card(
                                            elevation: 6,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: ExpansionTile(
                                              tilePadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 8,
                                                  ),
                                              title: Text(
                                                curso['curso'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFF1E40AF),
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Semestre: ${curso['semestre'] ?? '-'}',
                                              ),
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 0,
                                                        vertical: 8,
                                                      ),
                                                  child: DataTable(
                                                    columnSpacing: 16,
                                                    columns: const [
                                                      DataColumn(
                                                        label: Text('Data'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Aula'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Sala'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Matéria'),
                                                      ), // NOVO
                                                      DataColumn(
                                                        label: Text(
                                                          'Professor',
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Período'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Início'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Fim'),
                                                      ),
                                                      DataColumn(
                                                        label: Text('Ações'),
                                                      ),
                                                    ],
                                                    rows:
                                                        agsUnicos.map<DataRow>((
                                                          agendamento,
                                                        ) {
                                                          final sala =
                                                              agendamento['salas'];
                                                          final materia =
                                                              agendamento['materias'];
                                                          final professor =
                                                              agendamento['professores'];
                                                          final horaInicio =
                                                              agendamento['hora_inicio'];
                                                          final horaFim =
                                                              agendamento['hora_fim'];
                                                          final dia =
                                                              DateTime.parse(
                                                                agendamento['dia'],
                                                              );
                                                          final dataFormatada =
                                                              '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';
                                                          return DataRow(
                                                            cells: [
                                                              DataCell(
                                                                Text(
                                                                  dataFormatada,
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
                                                                  sala?['numero_sala']
                                                                          ?.toString() ??
                                                                      '-',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  materia?['nome'] ??
                                                                      '-',
                                                                ),
                                                              ), // Matéria
                                                              DataCell(
                                                                Text(
                                                                  professor?['nome_professor'] ??
                                                                      '-',
                                                                ),
                                                              ), // Professor
                                                              DataCell(
                                                                Text(
                                                                  periodoToString(
                                                                    curso['periodo'],
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  horaInicio
                                                                          ?.toString()
                                                                          .substring(
                                                                            0,
                                                                            5,
                                                                          ) ??
                                                                      '',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Text(
                                                                  horaFim
                                                                          ?.toString()
                                                                          .substring(
                                                                            0,
                                                                            5,
                                                                          ) ??
                                                                      '',
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color: Color(
                                                                          0xFF297BD8,
                                                                        ),
                                                                      ),
                                                                      onPressed:
                                                                          () => editarAgendamento(
                                                                            agendamento,
                                                                          ),
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(
                                                                        Icons
                                                                            .delete,
                                                                        color:
                                                                            Colors.red,
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
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ];
                                }),
                                if (agendamentos.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Text(
                                        'Nenhum agendamento encontrado',
                                      ),
                                    ),
                                  ),
                              ],
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
}

class Curso {
  final int id;
  final String curso;
  final int semestre;
  final int periodo;

  Curso({
    required this.id,
    required this.curso,
    required this.semestre,
    required this.periodo,
  });
}
