import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/historico_acoes.dart';

class HistoricoAcoesPage extends StatefulWidget {
  const HistoricoAcoesPage({super.key});

  @override
  State<HistoricoAcoesPage> createState() => _HistoricoAcoesPageState();
}

class _HistoricoAcoesPageState extends State<HistoricoAcoesPage> {
  final supabase = Supabase.instance.client;

  List<HistoricoAcoes> historico = [];
  List<HistoricoAcoes> historicoFiltrado = [];
  bool isLoading = true;

  // Filtros
  String? filtroAcao;
  String? filtroTabela;
  DateTime? dataEspecifica;
  final TextEditingController buscaController = TextEditingController();

  // Opcoes de filtro
  final List<String> acoes = [
    'INSERT',
    'INSERT_MULTIPLE',
    'UPDATE',
    'DELETE',
    'DELETE_MULTIPLE',
  ];
  final List<String> tabelas = [
    'agendamento',
    'salas',
    'cursos',
    'materias',
    'professores',
  ];

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarHistorico() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('historico_acoes')
          .select()
          .order('data_hora', ascending: false)
          .limit(1000);

      if (response == null) {
        setState(() {
          historico = [];
          historicoFiltrado = [];
          isLoading = false;
        });
        return;
      }

      setState(() {
        try {
          historico =
              (response as List)
                  .where((e) => e != null)
                  .map((e) {
                    try {
                      return HistoricoAcoes.fromMap(e);
                    } catch (e) {
                      print('Erro ao converter item do histórico: $e');
                      return null;
                    }
                  })
                  .where((e) => e != null)
                  .cast<HistoricoAcoes>()
                  .toList();
          aplicarFiltros();
        } catch (e) {
          print('Erro ao processar dados do histórico: $e');
          historico = [];
          historicoFiltrado = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void aplicarFiltros() {
    try {
      historicoFiltrado =
          historico.where((acao) {
            // Filtro por acao
            if (filtroAcao != null && acao.acao != filtroAcao) return false;

            // Filtro por tabela
            if (filtroTabela != null && acao.tabelaAfetada != filtroTabela) {
              return false;
            }

            // Filtro por data específica
            if (dataEspecifica != null) {
              final dataAcao = DateTime(
                acao.dataHora.year,
                acao.dataHora.month,
                acao.dataHora.day,
              );
              final dataFiltro = DateTime(
                dataEspecifica!.year,
                dataEspecifica!.month,
                dataEspecifica!.day,
              );
              if (dataAcao != dataFiltro) return false;
            }

            // Filtro por busca
            if (buscaController.text.isNotEmpty) {
              final busca = buscaController.text.toLowerCase().trim();
              final tabela = acao.tabelaFormatada.toLowerCase();
              final acaoText = acao.acaoFormatada.toLowerCase();
              final tabelaOriginal = acao.tabelaAfetada.toLowerCase();
              final acaoOriginal = acao.acao.toLowerCase();
              final registroId = acao.registroId?.toString() ?? '';

              // Busca nos dados JSON
              String dadosAnterioresStr = '';
              String dadosNovosStr = '';

              if (acao.dadosAnteriores != null) {
                dadosAnterioresStr =
                    acao.dadosAnteriores!.toString().toLowerCase();
              }
              if (acao.dadosNovos != null) {
                dadosNovosStr = acao.dadosNovos!.toString().toLowerCase();
              }

              if (!tabela.contains(busca) &&
                  !acaoText.contains(busca) &&
                  !tabelaOriginal.contains(busca) &&
                  !acaoOriginal.contains(busca) &&
                  !registroId.contains(busca) &&
                  !dadosAnterioresStr.contains(busca) &&
                  !dadosNovosStr.contains(busca)) {
                return false;
              }
            }

            return true;
          }).toList();
    } catch (e) {
      print('Erro ao aplicar filtros: $e');
      historicoFiltrado = [];
    }
  }

  void limparFiltros() {
    setState(() {
      filtroAcao = null;
      filtroTabela = null;
      dataEspecifica = null;
      buscaController.clear();
    });
    aplicarFiltros();
  }

  Future<void> selecionarData(BuildContext context) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (dataSelecionada != null) {
      setState(() {
        dataEspecifica = dataSelecionada;
      });
      aplicarFiltros();
    }
  }

  void mostrarDetalhes(HistoricoAcoes acao) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(acao.iconeAcao, color: acao.corAcao),
                const SizedBox(width: 8),
                const Text('Detalhes da Ação'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow('Ação', acao.acaoFormatada),
                  _buildInfoRow('Tabela', acao.tabelaFormatada),
                  _buildInfoRow(
                    'ID do Registro',
                    acao.registroId?.toString() ?? 'N/A',
                  ),
                  _buildInfoRow('Data/Hora', _formatarData(acao.dataHora)),
                  if (acao.detalhes != null)
                    _buildInfoRow('Detalhes', acao.detalhes!),
                  const SizedBox(height: 16),
                  if (acao.dadosAnteriores != null) ...[
                    const Text(
                      'Dados Anteriores:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatarJson(acao.dadosAnteriores!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (acao.dadosNovos != null) ...[
                    const Text(
                      'Dados Novos:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatarJson(acao.dadosNovos!),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // Botão de desfazer para agendamentos múltiplos
              if (acao.acao == 'INSERT_MULTIPLE')
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    desfazerAgendamentoMultiplo(acao);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Desfazer'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}:${data.second.toString().padLeft(2, '0')}';
  }

  String _formatarJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }

  Future<void> desfazerAgendamentoMultiplo(HistoricoAcoes acao) async {
    if (acao.acao != 'INSERT_MULTIPLE') return;

    try {
      final dadosNovos = acao.dadosNovos;
      if (dadosNovos == null || !dadosNovos.containsKey('ids_agendamentos')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados do agendamento múltiplo não encontrados'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final idsAgendamentos = List<int>.from(dadosNovos['ids_agendamentos']);
      final quantidadeDias = dadosNovos['quantidade_dias'] ?? 0;
      final datas = List<String>.from(dadosNovos['datas'] ?? []);
      final salaId = dadosNovos['sala_id'];
      final cursoId = dadosNovos['curso_id'];
      final materiaId = dadosNovos['materia_id'];

      // Confirmação do usuário
      final confirmar = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Desfazer Agendamento Múltiplo'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deseja desfazer o agendamento para $quantidadeDias dias?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 Datas: ${datas.join(', ')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🏫 Sala ID: $salaId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '📚 Curso ID: $cursoId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '📖 Matéria ID: $materiaId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta ação irá excluir todos os $quantidadeDias agendamentos relacionados e não pode ser desfeita.',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Desfazer Agendamentos'),
                ),
              ],
            ),
      );

      if (confirmar != true) return;

      setState(() => isLoading = true);

      // Verifica se os agendamentos ainda existem antes de remover
      final agendamentosExistentes = await supabase
          .from('agendamento')
          .select('id')
          .in_('id', idsAgendamentos);

      if (agendamentosExistentes == null || agendamentosExistentes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum agendamento encontrado para desfazer'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // Remove todos os agendamentos
      await supabase.from('agendamento').delete().in_('id', idsAgendamentos);

      // Cria um registro no histórico para documentar a desfazer
      await supabase.from('historico_acoes').insert({
        'tabela_afetada': 'agendamento',
        'acao': 'DELETE_MULTIPLE',
        'registro_id': acao.registroId,
        'dados_anteriores': acao.dadosNovos,
        'dados_novos': null,
        'detalhes': 'Agendamento múltiplo desfeito: ${datas.join(', ')}',
        'data_hora': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $quantidadeDias agendamentos desfeitos com sucesso'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Recarrega o histórico
      await carregarHistorico();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao desfazer agendamento: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Ações',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF44A301),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarHistorico,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF44A301), Color(0xFF66BB6A)],
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Campus Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bem-vindo!',
                        style: TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF44A301)),
              title: const Text(
                'Início',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarlocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Color(0xFF44A301)),
              title: const Text(
                'Lista Agendamento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/listalocacao'),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Sala',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarsala'),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Curso',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarcurso'),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Color(0xFF44A301)),
              title: const Text(
                'Nova Matéria',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarmateria'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Professor',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprofessor'),
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF44A301)),
              title: const Text(
                'Novo Evento',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarevento'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Color(0xFF44A301)),
              title: const Text(
                'Agendar Prova',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/criarprova'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF44A301)),
              title: const Text(
                'Histórico de Ações',
                style: TextStyle(color: Colors.black87),
              ),
              onTap: () => Navigator.pushNamed(context, '/historicoacoes'),
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
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF44A301).withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título dos filtros
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF44A301),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filtros de Busca',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44A301),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Busca
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: buscaController,
                    decoration: InputDecoration(
                      hintText: '🔍 Buscar por tabela ou ação...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF44A301),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          buscaController.clear();
                          aplicarFiltros();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => aplicarFiltros(),
                  ),
                ),
                const SizedBox(height: 20),

                // Filtros de ação e tabela
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: filtroAcao,
                          decoration: InputDecoration(
                            labelText: '📝 Tipo de Ação',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                              fontWeight: FontWeight.w500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.category,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF44A301),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Todas as ações',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...acoes.map(
                              (acao) => DropdownMenuItem(
                                value: acao,
                                child: Row(
                                  children: [
                                    Icon(
                                      acao == 'INSERT'
                                          ? Icons.add_circle
                                          : acao == 'INSERT_MULTIPLE'
                                          ? Icons.add_circle_outline
                                          : acao == 'UPDATE'
                                          ? Icons.edit
                                          : acao == 'DELETE'
                                          ? Icons.delete
                                          : Icons.delete_outline,
                                      color:
                                          acao == 'INSERT' ||
                                                  acao == 'INSERT_MULTIPLE'
                                              ? Colors.green
                                              : acao == 'UPDATE'
                                              ? Colors.orange
                                              : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getAcaoDisplayName(acao)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => filtroAcao = value);
                            aplicarFiltros();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: filtroTabela,
                          decoration: InputDecoration(
                            labelText: '🗂️ Tabela Afetada',
                            labelStyle: const TextStyle(
                              color: Color(0xFF44A301),
                              fontWeight: FontWeight.w500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              Icons.table_chart,
                              color: Color(0xFF44A301),
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF44A301),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Todas as tabelas',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...tabelas.map(
                              (tabela) => DropdownMenuItem(
                                value: tabela,
                                child: Text(tabela),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => filtroTabela = value);
                            aplicarFiltros();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filtro de data específica
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () => selecionarData(context),
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF44A301),
                          ),
                          label: Text(
                            dataEspecifica != null
                                ? '📅 ${_formatarData(dataEspecifica!)}'
                                : '📅 Selecionar Data',
                            style: const TextStyle(color: Color(0xFF44A301)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF44A301), Color(0xFF66BB6A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF44A301).withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: limparFiltros,
                        icon: const Icon(Icons.clear_all, color: Colors.white),
                        label: const Text(
                          'Limpar Filtros',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de ações
          Expanded(
            child: Container(
              color: Colors.white,
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : historicoFiltrado.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              buscaController.text.isNotEmpty
                                  ? 'Nenhuma ação encontrada para "${buscaController.text}"'
                                  : 'Nenhuma ação encontrada',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (buscaController.text.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Tente usar termos diferentes ou limpar os filtros',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: historicoFiltrado.length,
                        itemBuilder: (context, index) {
                          if (index >= historicoFiltrado.length) {
                            return const SizedBox.shrink();
                          }

                          final acao = historicoFiltrado[index];
                          if (acao == null) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => mostrarDetalhes(acao),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar com cor da ação
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: acao.corAcao,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: acao.corAcao.withOpacity(
                                                0.3,
                                              ),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          acao.iconeAcao,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Conteúdo principal
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Linha superior com ação e tabela
                                            Row(
                                              children: [
                                                Text(
                                                  acao.acaoFormatada,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF44A301),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: acao.corAcao
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: acao.corAcao
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    acao.tabelaFormatada,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: acao.corAcao,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Detalhes da ação
                                            if (acao.detalhes != null) ...[
                                              Text(
                                                acao.detalhes!,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                            ],

                                            // Data e hora
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatarData(acao.dataHora),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Botão de detalhes
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF44A301,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.info_outline,
                                            color: Color(0xFF44A301),
                                          ),
                                          onPressed:
                                              () => mostrarDetalhes(acao),
                                          tooltip: 'Ver detalhes',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAcaoDisplayName(String acao) {
    switch (acao) {
      case 'INSERT':
        return 'Criação';
      case 'INSERT_MULTIPLE':
        return 'Criação Múltipla';
      case 'UPDATE':
        return 'Alteração';
      case 'DELETE':
        return 'Exclusão';
      case 'DELETE_MULTIPLE':
        return 'Exclusão Múltipla';
      default:
        return acao;
    }
  }
}
