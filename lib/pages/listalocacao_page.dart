import 'package:app_web/pages/criarlocacao_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaLocacaoPage extends StatefulWidget {
  const ListaLocacaoPage({super.key});

  @override
  State<ListaLocacaoPage> createState() => _ListaLocacaoPageState();
}

class _ListaLocacaoPageState extends State<ListaLocacaoPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> alocacoes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    carregarAlocacoes();
  }

  Future<void> carregarAlocacoes() async {
    setState(() => isLoading = true);
    try {
      final responseAlocacoes = await supabase
          .from('alocacoes')
          .select(
            'id, sala:salas(id, numero_sala, qtd_cadeiras, cor), curso:cursos(curso, periodo, semestre)',
          );
      setState(() {
        alocacoes = List<Map<String, dynamic>>.from(responseAlocacoes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar alocações: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editarAlocacao(Map<String, dynamic> alocacao) async {
    // Buscar salas disponíveis (disponivel = true) e adicionar a sala atual da alocação
    final responseSalas = await supabase
        .from('salas')
        .select('id, numero_sala, qtd_cadeiras')
        .eq('disponivel', true);

    // Adiciona a sala atual da alocação (caso não esteja disponível)
    final salaAtual = alocacao['sala']?['numero_sala'];
    List<dynamic> salasDisponiveis = List.from(responseSalas);
    if (salaAtual != null &&
        !salasDisponiveis.any((s) => s['numero_sala'] == salaAtual)) {
      // Busca a sala atual pelo número
      final salaAtualData =
          await supabase
              .from('salas')
              .select('id, numero_sala, qtd_cadeiras')
              .eq('numero_sala', salaAtual)
              .single();
      salasDisponiveis.add(salaAtualData);
    }

    // Buscar cursos
    final responseCursos = await supabase.from('cursos').select();

    // Ordena os cursos por nome (campo 'curso')
    responseCursos.sort((a, b) => (a['curso'] as String).compareTo(b['curso'] as String));

    String? novaSala = salaAtual;
    int? cursoSelecionadoId = alocacao['curso']?['id'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Alocação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: novaSala,
                decoration: const InputDecoration(labelText: 'Sala'),
                items: salasDisponiveis
                    .map<DropdownMenuItem<String>>(
                      (s) => DropdownMenuItem<String>(
                        value: s['numero_sala'] as String,
                        child: Text(
                          '${s['numero_sala']} (${s['qtd_cadeiras'] ?? '0'} cadeiras)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => novaSala = value,
              ),
              DropdownButtonFormField<int>(
                value: cursoSelecionadoId, // int? id do curso selecionado
                decoration: const InputDecoration(labelText: 'Curso'),
                items: responseCursos.map<DropdownMenuItem<int>>(
                  (curso) {
                    // Converte o período numérico para texto
                    String periodo = '-';
                    if (curso['periodo'] == 1) periodo = 'Matutino';
                    else if (curso['periodo'] == 2) periodo = 'Vespertino';
                    else if (curso['periodo'] == 3) periodo = 'Noturno';

                    return DropdownMenuItem<int>(
                      value: curso['id'],
                      child: Text(
                        '${curso['curso']} - $periodo - ${curso['semestre'] ?? "-"}º semestre',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    cursoSelecionadoId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final salaSelecionada = salasDisponiveis.firstWhere(
                  (s) => s['numero_sala'] == novaSala,
                );
                final cursoSelecionado = responseCursos.firstWhere(
                  (c) => c['id'] == cursoSelecionadoId,
                );

                await supabase
                    .from('alocacoes')
                    .update({
                      'sala_id': salaSelecionada['id'],
                      'curso_id': cursoSelecionado['id'],
                    })
                    .eq('id', alocacao['id']);

                Navigator.of(context).pop();
                await carregarAlocacoes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alocação editada com sucesso')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color getContrastingTextColor(Color background) {
    // Calcula o brilho da cor (fórmula padrão de contraste)
    final double brightness =
        (background.red * 299 +
            background.green * 587 +
            background.blue * 114) /
        1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // Agrupa as alocações por número da sala (primeiro caractere do número da sala)
    Map<String, List<Map<String, dynamic>>> agrupadas = {};
    for (var aloc in alocacoes) {
      final salaNum =
          (aloc['sala']?['numero_sala'] ?? 'Desconhecida').toString();
      final grupo = salaNum.isNotEmpty ? salaNum[0] : 'Desconhecida';
      agrupadas.putIfAbsent(grupo, () => []).add(aloc);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // <-- Ícone do Drawer branco
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Sair',
          ),
        ],
        title: const Text(
          'Lista de Alocações',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black), // preto
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
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context); // Fecha o Drawer
                Navigator.pushReplacementNamed(context, '/home'); // Vai para a Home Page
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text('Nova Alocação'),
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
              leading: const Icon(Icons.list_alt),
              title: const Text('Lista de Alocações'),
              onTap: () {
                Navigator.pop(context);
                // Você já está na lista, pode apenas fechar o drawer ou navegar se quiser recarregar
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SizedBox(
                  width:
                      1100, // aumenta a largura máxima do quadradão de cada grupo
                  child:
                      alocacoes.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Nenhuma alocação encontrada.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                          : ListView(
                            shrinkWrap: true,
                            children:
                                agrupadas.entries.map((entry) {
                                  final grupo = entry.key;
                                  final lista = entry.value;

                                  // Pega a cor da primeira sala do grupo (ou padrão)
                                  final corHexGrupo =
                                      lista.isNotEmpty
                                          ? (lista.first['sala']?['cor'] ??
                                              '#1976D2')
                                          : '#1976D2';
                                  Color corGrupo;
                                  try {
                                    final hex = corHexGrupo.replaceFirst(
                                      '#',
                                      '',
                                    );
                                    corGrupo = Color(int.parse('0xFF$hex'));
                                    corGrupo = blendWithWhite(
                                      corGrupo,
                                      0.65,
                                    ); // deixa pastel
                                  } catch (_) {
                                    corGrupo = blendWithWhite(
                                      const Color(0xFF1976D2),
                                      0.65,
                                    );
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 32),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Cabeçalho da "tabela" para o grupo
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: corGrupo,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: corGrupo
                                                            .withOpacity(0.18),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Salas $grupo',
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Tabela de títulos (agora com cor pastel da sala e mais "gordinho")
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16, // aumenta a altura
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: corGrupo,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: corGrupo.withOpacity(
                                                  0.13,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: const [
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  'Sala',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  'Cadeiras',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Curso',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Período',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Semestre',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              SizedBox(width: 40),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Lista das alocações desse grupo
                                        ...lista.map((aloc) {
                                          final sala =
                                              aloc['sala']?['numero_sala'] ??
                                              'Sala desconhecida';
                                          final cadeiras =
                                              aloc['sala']?['qtd_cadeiras']
                                                  ?.toString() ??
                                              '0';
                                          final curso =
                                              aloc['curso']?['curso'] ??
                                              'Curso desconhecido';
                                          final periodoNum =
                                              aloc['curso']?['periodo'];
                                          final semestre =
                                              aloc['curso']?['semestre']
                                                  ?.toString() ??
                                              '-';

                                          // Converte o período numérico para texto
                                          String periodo = '-';
                                          if (periodoNum == 1) {
                                            periodo = 'Matutino';
                                          } else if (periodoNum == 2)
                                            periodo = 'Vespertino';
                                          else if (periodoNum == 3)
                                            periodo = 'Noturno';

                                          final corHex =
                                              aloc['sala']?['cor'] ?? '#1976D2';
                                          Color corSala;
                                          try {
                                            final hex = corHex.replaceFirst(
                                              '#',
                                              '',
                                            );
                                            corSala = Color(
                                              int.parse('0xFF$hex'),
                                            );
                                            corSala = blendWithWhite(
                                              corSala,
                                              0.65,
                                            ); // deixa pastel
                                          } catch (_) {
                                            corSala = blendWithWhite(
                                              const Color(0xFF1976D2),
                                              0.65,
                                            );
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Quadrado Sala
                                                SizedBox(
                                                  width: 80,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.13,
                                                              ),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      sala,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Quadrado Cadeiras
                                                SizedBox(
                                                  width: 80,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.13,
                                                              ),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      cadeiras,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Quadrado Curso
                                                Expanded(
                                                  flex: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                          horizontal: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF8F9FA,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.10,
                                                              ),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      curso,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Quadrado Período (destacado)
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.13,
                                                              ),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      periodo,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Quadrado Semestre (destacado)
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.13,
                                                              ),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      semestre,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Color(0xFF1976D2),
                                                  ),
                                                  tooltip: 'Editar alocação',
                                                  onPressed: () => _editarAlocacao(aloc),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Excluir alocação',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Confirmar exclusão'),
                                                        content: const Text('Tem certeza que deseja excluir esta alocação?'),
                                                        actions: [
                                                          TextButton(
                                                            child: const Text('Cancelar'),
                                                            onPressed: () => Navigator.of(context).pop(false),
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                            child: const Text('Excluir'),
                                                            onPressed: () => Navigator.of(context).pop(true),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      // 1. Torna a sala disponível novamente
                                                      final salaId = aloc['sala']?['id'];
                                                      if (salaId != null) {
                                                        await supabase
                                                            .from('salas')
                                                            .update({'disponivel': true})
                                                            .eq('id', salaId);
                                                      }

                                                      // 2. Exclui a alocação
                                                      await supabase
                                                          .from('alocacoes')
                                                          .delete()
                                                          .eq('id', aloc['id']);

                                                      await carregarAlocacoes();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Alocação excluída com sucesso')),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                ),
              ),
    );
  }
}

// Função para aplicar um blend e deixar a cor pastel
Color blendWithWhite(Color color, [double amount = 0.65]) {
  // amount: 0.0 = original, 1.0 = branco
  return Color.lerp(color, Colors.white, amount)!;
}
