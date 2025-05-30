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

    final novoCursoController = TextEditingController(text: cursoAtual['curso']);
    final novoSemestreController = TextEditingController(text: cursoAtual['semestre'].toString());
    final novoPeriodoController = TextEditingController(text: agendamento['aula_periodo']);
    final novaSalaController = TextEditingController(text: salaAtual['numero_sala'].toString());

    final novaData = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(agendamento['dia']),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (novaData == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: novoCursoController, decoration: const InputDecoration(labelText: 'Curso')),
            TextField(controller: novoSemestreController, decoration: const InputDecoration(labelText: 'Semestre')),
            TextField(controller: novoPeriodoController, decoration: const InputDecoration(labelText: 'Período da Aula')),
            TextField(controller: novaSalaController, decoration: const InputDecoration(labelText: 'Sala')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('agendamento').update({
          'aula_periodo': novoPeriodoController.text,
          'dia':
              '${novaData.year.toString().padLeft(4, '0')}-${novaData.month.toString().padLeft(2, '0')}-${novaData.day.toString().padLeft(2, '0')}',
        }).eq('id', agendamento['id']);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento atualizado')));
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> excluirAgendamento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este agendamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('agendamento').delete().eq('id', id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendamento excluído')));
        carregarAgendamentos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: selecionarDia,
            tooltip: 'Escolher dia',
          ),
        ],
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
            child: isLoading
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
                            DataColumn(label: Text('Aula')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: agendamentos.map((agendamento) {
                            final curso = agendamento['cursos'];
                            final sala = agendamento['salas'];
                            final dia = DateTime.parse(agendamento['dia']);
                            final dataFormatada =
                                '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}';

                            return DataRow(cells: [
                              DataCell(Text(dataFormatada)),
                              DataCell(Text(curso['curso'] ?? '')),
                              DataCell(Text('Sem. ${curso['semestre']}')),
                              DataCell(Text('${sala['numero_sala']}')),
                              DataCell(Text(periodoToString(curso['periodo']))),
                              DataCell(Text(agendamento['aula_periodo'] ?? '')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => editarAgendamento(agendamento),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => excluirAgendamento(agendamento['id']),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
