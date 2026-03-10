/// =====================================================================
/// TIPO SOLICITAÇÃO DTOs
/// Categorias de manutenção (Corretiva, Preventiva, etc.)
/// =====================================================================
library;

class TipoSolicitacaoDto {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;

  TipoSolicitacaoDto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
  });

  factory TipoSolicitacaoDto.fromJson(Map<String, dynamic> json) {
    return TipoSolicitacaoDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'ativo': ativo,
  };
}

/// Request para criar tipo de solicitação
class CriarTipoSolicitacaoRequest {
  final String nome;
  final String? descricao;

  CriarTipoSolicitacaoRequest({
    required this.nome,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
  };
}

/// Request para atualizar tipo de solicitação
class AtualizarTipoSolicitacaoRequest {
  final String? nome;
  final String? descricao;
  final bool? ativo;

  AtualizarTipoSolicitacaoRequest({
    this.nome,
    this.descricao,
    this.ativo,
  });

  Map<String, dynamic> toJson() => {
    if (nome != null) 'nome': nome,
    if (descricao != null) 'descricao': descricao,
    if (ativo != null) 'ativo': ativo,
  };
}
