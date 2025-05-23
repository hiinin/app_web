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
