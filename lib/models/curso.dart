import 'package:flutter/material.dart';

class Curso {
  final int id;
  final String curso;
  final int? periodo;
  final String? semestre; // Aceita semestre como String

  Curso({required this.id, required this.curso, this.periodo, this.semestre});

  factory Curso.fromMap(Map<String, dynamic> map) {
    int? periodo;
    if (map['periodo'] is int) {
      periodo = map['periodo'];
    } else if (map['periodo'] is String) {
      periodo = int.tryParse(map['periodo']);
    }

    // semestre pode ser string ou int, sempre salva como string
    String? semestre;
    if (map['semestre'] != null) {
      semestre = map['semestre'].toString();
    }

    return Curso(
      id: map['id'] ?? map['curso_id'] ?? 0,
      curso: map['curso'] ?? map['nome'] ?? map['nome_curso'] ?? '',
      periodo: periodo,
      semestre: semestre,
    );
  }
}

class DetalhesCurso extends StatelessWidget {
  final Curso? cursoSelecionado;

  const DetalhesCurso({Key? key, this.cursoSelecionado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Curso'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Text(
                      'Semestre: ${cursoSelecionado!.semestre ?? "Não informado"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      'Período: ${cursoSelecionado!.periodo != null ? cursoSelecionado!.periodo.toString() : "Não informado"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
