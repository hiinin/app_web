class Materia {
  final int id;
  final String nome;
  final int? cursoId;

  Materia({required this.id, required this.nome, this.cursoId});

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'] ?? map['materia_id'] ?? 0,
      nome: map['nome'] ?? map['nome_materia'] ?? '',
      cursoId: map['curso_id'],
    );
  }

  @override
  String toString() => nome;
}
