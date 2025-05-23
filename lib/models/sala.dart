class Sala {
  final int id;
  final String numeroSala;
  final int qtdCadeiras;
  final bool disponivel;

  Sala({
    required this.id,
    required this.numeroSala,
    required this.qtdCadeiras,
    required this.disponivel,
  });

  factory Sala.fromMap(Map<String, dynamic> map) {
    return Sala(
      id: map['id'],
      numeroSala: map['numero_sala'],
      qtdCadeiras: map['qtd_cadeiras'],
      disponivel: map['disponivel'],
    );
  }
  @override
  String toString() => numeroSala;
}
