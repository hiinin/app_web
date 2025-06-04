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
  List<Map<String, dynamic>> materias = [];
  sala_model.Sala? salaSelecionada;
  curso_model.Curso? cursoSelecionado;
  Map<String, dynamic>? materiaSelecionada;

  bool isLoading = false;

  DateTime? dia;
  TimeOfDay? horaSelecionada;
  String? periodoAulaSelecionado;

  TimeOfDay? horaInicio;
  TimeOfDay? horaFim;

  String formatHora(TimeOfDay hora) {
    final horaFormatada = hora.hour.toString().padLeft(2, '0');
    final minutoFormatado = hora.minute.toString().padLeft(2, '0');
    return '$horaFormatada:$minutoFormatado';
  }

  final List<String> periodosAula = ['Matutino', 'Vespertino', 'Noturno'];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() => isLoading = true);
    try {
      final responseSalas = await supabase.from('salas').select();
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
        cursos.sort(
          (a, b) => a.curso.toLowerCase().compareTo(b.curso.toLowerCase()),
        );
        materias = [];
        materiaSelecionada = null;
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

  Future<void> carregarMateriasPorCurso(int cursoId) async {
    setState(() {
      materias = [];
      materiaSelecionada = null;
      isLoading = true;
    });
    try {
      final response = await supabase
          .from('materias')
          .select()
          .eq('curso_id', cursoId);
      setState(() {
        materias = List<Map<String, dynamic>>.from(response as List);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar matérias: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> selecionarDia() async {
    final DateTime hoje = DateTime.now();
    final DateTime dataInicial = DateTime(hoje.year, hoje.month, hoje.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dia ?? dataInicial,
      firstDate: dataInicial,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => dia = picked);
    }
  }

  Future<void> salvarLocacao() async {
    if (dia == null ||
        salaSelecionada == null ||
        cursoSelecionado == null ||
        periodoAulaSelecionado == null ||
        materiaSelecionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    setState(() => isLoading = true);

    // Verifica se já existe um agendamento com a mesma sala, dia e período
    final agendamentosExistentes = await supabase
        .from('agendamento')
        .select()
        .eq('sala_id', salaSelecionada!.id)
        .eq(
          'dia',
          '${dia!.year.toString().padLeft(4, '0')}-${dia!.month.toString().padLeft(2, '0')}-${dia!.day.toString().padLeft(2, '0')}',
        )
        .eq('aula_periodo', periodoAulaSelecionado!);

    if (agendamentosExistentes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Essa sala já está alocada nesse período. Escolha outro.',
          ),
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      // Inserir na tabela 'agendamento' com a matéria selecionada
      await supabase.from('agendamento').insert({
        'aula_periodo': periodoAulaSelecionado!,
        'sala_id': salaSelecionada!.id,
        'curso_id': cursoSelecionado!.id,
        'materia_id': materiaSelecionada!['id'],
        'dia':
            '${dia!.year.toString().padLeft(4, '0')}-${dia!.month.toString().padLeft(2, '0')}-${dia!.day.toString().padLeft(2, '0')}',
      });
      // 4. Resetar campos
      setState(() {
        salaSelecionada = null;
        cursoSelecionado = null;
        periodoAulaSelecionado = null;
        horaInicio = null;
        horaFim = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento salvo com sucesso')),
      );

      carregarDados(); // Recarrega as opções
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar agendamento: $e')));
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 41, 123, 216),
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nova Alocação',
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
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 41, 123, 216),
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
                      style: TextStyle(color: Colors.black87),
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                  children: [
                    // Calendário à esquerda (agora 55% da tela)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 245, 244, 244),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(0),
                          bottomRight: Radius.circular(0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 30),
                          const Text(
                            'Selecione o Dia',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: CalendarDatePicker(
                              initialDate: dia ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                              onDateChanged: (picked) {
                                setState(() => dia = picked);
                              },
                              currentDate: DateTime.now(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Formulário à direita (agora 45% da tela)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          bottomLeft: Radius.circular(0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'Preencha os dados para alocar uma sala',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              DropdownButtonFormField<String>(
                                value: periodoAulaSelecionado,
                                decoration: InputDecoration(
                                  labelText: 'Selecione a Aula (Período)',
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.blue[50],
                                iconEnabledColor: Colors.blue,
                                style: const TextStyle(color: Colors.blue),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Primeira Aula',
                                    child: Text(
                                      'Primeira Aula',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Segunda Aula',
                                    child: Text(
                                      'Segunda Aula',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ],
                                onChanged:
                                    (value) => setState(
                                      () => periodoAulaSelecionado = value,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              DropdownButtonFormField<sala_model.Sala>(
                                value: salaSelecionada,
                                decoration: InputDecoration(
                                  labelText: 'Selecione a Sala',
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.blue[50],
                                iconEnabledColor: Colors.blue,
                                style: const TextStyle(color: Colors.blue),
                                items:
                                    salas
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              '${s.numeroSala} - ${s.qtdCadeiras} cadeiras',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() => salaSelecionada = value);
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Selecione uma sala'
                                            : null,
                              ),
                              const SizedBox(height: 18),
                              DropdownButtonFormField<curso_model.Curso>(
                                value: cursoSelecionado,
                                decoration: InputDecoration(
                                  labelText: 'Selecione o Curso',
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.blue[50],
                                iconEnabledColor: Colors.blue,
                                style: const TextStyle(color: Colors.blue),
                                items:
                                    cursos
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              '${c.curso} - ${c.semestre ?? "Semestre?"} - ${c.periodo != null ? periodoToString(c.periodo) : "Período?"}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    cursoSelecionado = value;
                                    materiaSelecionada = null;
                                    materias = [];
                                  });
                                  if (value != null) {
                                    carregarMateriasPorCurso(value.id);
                                  }
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Selecione um curso'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              if (cursoSelecionado != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Curso: ${cursoSelecionado!.curso}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            'Semestre: ${cursoSelecionado!.semestre ?? "Não informado"}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Período: ${periodoToString(cursoSelecionado!.periodo)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: materiaSelecionada,
                                decoration: InputDecoration(
                                  labelText: 'Selecione a Matéria',
                                  labelStyle: const TextStyle(
                                    color: Colors.blue,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blue[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.blue[50],
                                iconEnabledColor: Colors.blue,
                                style: const TextStyle(color: Colors.blue),
                                items:
                                    materias
                                        .map(
                                          (m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(
                                              m['nome'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    materiaSelecionada = value;
                                  });
                                },
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Selecione uma matéria'
                                            : null,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                  ],
                ),
      ),
    );
  }
}
