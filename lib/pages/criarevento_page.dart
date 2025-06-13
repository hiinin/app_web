import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CriarEventoPage extends StatefulWidget {
  const CriarEventoPage({super.key});

  @override
  State<CriarEventoPage> createState() => _CriarEventoPageState();
}

class _CriarEventoPageState extends State<CriarEventoPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  String? nomeEvento;
  String? descricao;
  DateTime? dataEvento;
  TimeOfDay? horaInicio;
  TimeOfDay? horaFim;
  int? salaSelecionada;

  List<Map<String, dynamic>> salas = [];

  @override
  void initState() {
    super.initState();
    carregarSalas();
  }

  Future<void> carregarSalas() async {
    final response = await supabase.from('salas').select('id, numero_sala');
    setState(() {
      salas = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> salvarEvento() async {
    if (!_formKey.currentState!.validate() || dataEvento == null) return;
    _formKey.currentState!.save();

    final dataStr =
        '${dataEvento!.year.toString().padLeft(4, '0')}-${dataEvento!.month.toString().padLeft(2, '0')}-${dataEvento!.day.toString().padLeft(2, '0')}';
    final horaInicioStr =
        horaInicio != null
            ? '${horaInicio!.hour.toString().padLeft(2, '0')}:${horaInicio!.minute.toString().padLeft(2, '0')}'
            : null;
    final horaFimStr =
        horaFim != null
            ? '${horaFim!.hour.toString().padLeft(2, '0')}:${horaFim!.minute.toString().padLeft(2, '0')}'
            : null;

    await supabase.from('eventos').insert({
      'nome': nomeEvento,
      'descricao': descricao,
      'data': dataStr,
      'hora_inicio': horaInicioStr,
      'hora_fim': horaFimStr,
      'sala_id': salaSelecionada,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento cadastrado com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novo Evento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Image.asset(
                      'assets/images/logo.png', // Use o mesmo caminho da CriarLocacaoPage
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
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF1E40AF)),
              title: const Text(
                'Novo Evento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarevento'),
            ),
            // ...adicione outros ListTile conforme seu menu...
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome do evento'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                onSaved: (v) => nomeEvento = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
                onSaved: (v) => descricao = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  dataEvento == null
                      ? 'Selecione a data'
                      : '${dataEvento!.day.toString().padLeft(2, '0')}/${dataEvento!.month.toString().padLeft(2, '0')}/${dataEvento!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => dataEvento = picked);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        horaInicio == null
                            ? 'Hora início'
                            : horaInicio!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => horaInicio = picked);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        horaFim == null ? 'Hora fim' : horaFim!.format(context),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => horaFim = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: salaSelecionada,
                decoration: const InputDecoration(labelText: 'Sala'),
                items:
                    salas
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text('Sala ${s['numero_sala']}'),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => salaSelecionada = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar Evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: salvarEvento,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
