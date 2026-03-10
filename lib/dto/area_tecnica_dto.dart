class AreaTecnicaDto {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;

  AreaTecnicaDto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
  });

  factory AreaTecnicaDto.fromJson(Map<String, dynamic> json) {
    return AreaTecnicaDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
    };
  }
}
