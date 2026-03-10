/// =====================================================================
/// ATIVOS DTOs
/// Representam estatísticas e relatórios de ativos/itens de apartamento
/// =====================================================================
library;

/// Estatísticas resumidas de ativos
class AtivosEstatisticasDto {
  final int total;
  final int disponiveis;
  final int emManutencao;
  final int danificados;
  final int emUso;
  final int emStock;
  final int vinculados;

  AtivosEstatisticasDto({
    required this.total,
    required this.disponiveis,
    required this.emManutencao,
    required this.danificados,
    required this.emUso,
    required this.emStock,
    required this.vinculados,
  });

  factory AtivosEstatisticasDto.fromJson(Map<String, dynamic> json) {
    return AtivosEstatisticasDto(
      total: json['total'] ?? 0,
      disponiveis: json['disponiveis'] ?? 0,
      emManutencao: json['emManutencao'] ?? 0,
      danificados: json['danificados'] ?? 0,
      emUso: json['emUso'] ?? 0,
      emStock: json['emStock'] ?? 0,
      vinculados: json['vinculados'] ?? 0,
    );
  }
}

/// Agrupamento de ativos por categoria
class AtivoPorCategoriaDto {
  final String categoria;
  final int quantidade;

  AtivoPorCategoriaDto({
    required this.categoria,
    required this.quantidade,
  });

  factory AtivoPorCategoriaDto.fromJson(Map<String, dynamic> json) {
    return AtivoPorCategoriaDto(
      categoria: json['categoria'] ?? json['tipo'] ?? json['nome'] ?? '',
      quantidade: json['quantidade'] ?? json['count'] ?? 0,
    );
  }
}

/// Itens mais solicitados em manutenções
class ItemMaisSolicitadoDto {
  final String itemId;
  final String nome;
  final String? codigoPatrimonio;
  final int quantidadeSolicitacoes;
  final String? ultimaManutencao;

  ItemMaisSolicitadoDto({
    required this.itemId,
    required this.nome,
    this.codigoPatrimonio,
    required this.quantidadeSolicitacoes,
    this.ultimaManutencao,
  });

  factory ItemMaisSolicitadoDto.fromJson(Map<String, dynamic> json) {
    return ItemMaisSolicitadoDto(
      itemId: json['itemId'] ?? json['id'] ?? '',
      nome: json['nome'] ?? '',
      codigoPatrimonio: json['codigoPatrimonio'],
      quantidadeSolicitacoes: json['quantidadeSolicitacoes'] ?? json['quantidade'] ?? 0,
      ultimaManutencao: json['ultimaManutencao'],
    );
  }
}

/// Relatório completo de ativos
class RelatorioAtivosDto {
  final AtivosEstatisticasDto estatisticas;
  final List<AtivoPorCategoriaDto> porTipo;
  final List<AtivoPorCategoriaDto> porEstado;
  final List<AtivoPorCategoriaDto> porApartamento;
  final List<AtivoPorCategoriaDto> porAreaTecnica;
  final List<ItemMaisSolicitadoDto> maisSolicitados;
  final double? idadeMedia; // em dias

  RelatorioAtivosDto({
    required this.estatisticas,
    required this.porTipo,
    required this.porEstado,
    required this.porApartamento,
    required this.porAreaTecnica,
    required this.maisSolicitados,
    this.idadeMedia,
  });

  factory RelatorioAtivosDto.fromJson(Map<String, dynamic> json) {
    return RelatorioAtivosDto(
      estatisticas: AtivosEstatisticasDto.fromJson(json['estatisticas'] ?? {}),
      porTipo: (json['porTipo'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      porEstado: (json['porEstado'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      porApartamento: (json['porApartamento'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      porAreaTecnica: (json['porAreaTecnica'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      maisSolicitados: (json['maisSolicitados'] as List<dynamic>?)
              ?.map((e) => ItemMaisSolicitadoDto.fromJson(e))
              .toList() ??
          [],
      idadeMedia: (json['idadeMedia'] as num?)?.toDouble(),
    );
  }
}

/// DTO para seção de ativos no dashboard
class DashboardAtivosDto {
  final int total;
  final int disponiveis;
  final int emManutencao;
  final int danificados;
  final int emStock;
  final int vinculados;
  final double? idadeMedia;
  final List<AtivoPorCategoriaDto> porTipo;
  final List<AtivoPorCategoriaDto> porEstado;
  final List<AtivoPorCategoriaDto> porAreaTecnica;

  DashboardAtivosDto({
    required this.total,
    required this.disponiveis,
    required this.emManutencao,
    required this.danificados,
    required this.emStock,
    required this.vinculados,
    this.idadeMedia,
    required this.porTipo,
    required this.porEstado,
    required this.porAreaTecnica,
  });

  factory DashboardAtivosDto.fromJson(Map<String, dynamic> json) {
    return DashboardAtivosDto(
      total: json['total'] ?? 0,
      disponiveis: json['disponiveis'] ?? 0,
      emManutencao: json['emManutencao'] ?? 0,
      danificados: json['danificados'] ?? 0,
      emStock: json['emStock'] ?? 0,
      vinculados: json['vinculados'] ?? 0,
      idadeMedia: (json['idadeMedia'] as num?)?.toDouble(),
      porTipo: (json['porTipo'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      porEstado: (json['porEstado'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
      porAreaTecnica: (json['porAreaTecnica'] as List<dynamic>?)
              ?.map((e) => AtivoPorCategoriaDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}
