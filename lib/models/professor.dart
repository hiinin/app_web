class Professor {
  final int id;
  final String nomeProfessor;
  final int? materiaId;

  Professor({required this.id, required this.nomeProfessor, this.materiaId});

  factory Professor.fromMap(Map<String, dynamic> map) {
    return Professor(
      id: map['id'] ?? map['professor_id'] ?? 0,
      nomeProfessor: map['nome_professor'] ?? map['nome'] ?? '',
      materiaId: map['materia_id'],
    );
  }

  @override
  String toString() => nomeProfessor;
}
