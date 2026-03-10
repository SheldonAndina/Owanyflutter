/// DTO for GET /api/dashboard/solicitacoes-kpis
/// Matches backend Owany.DTOs.SolicitacoesKpisDto (camelCase JSON)
class SolicitacoesKpisDto {
  final int total;
  final int pendentes;
  final int emAndamento;
  final int concluidas;
  final int atrasadas;
  final double taxaConclusao;
  final double taxaSla;
  final double mttrHoras;
  final double diasAtrasoMedio;
  final double diasAtrasoMediana;
  final double percentOver48h;
  final List<BucketAtrasoDto> bucketsAtraso;
  final List<ResponsavelAtrasoDto> topResponsaveisAtraso;
  final List<DistribuicaoTipoDto> distribuicaoPorTipo;
  final List<GraficoMensalDto> graficoMensal;

  SolicitacoesKpisDto({
    required this.total,
    required this.pendentes,
    required this.emAndamento,
    required this.concluidas,
    required this.atrasadas,
    required this.taxaConclusao,
    required this.taxaSla,
    required this.mttrHoras,
    required this.diasAtrasoMedio,
    required this.diasAtrasoMediana,
    required this.percentOver48h,
    required this.bucketsAtraso,
    required this.topResponsaveisAtraso,
    required this.distribuicaoPorTipo,
    required this.graficoMensal,
  });

  factory SolicitacoesKpisDto.fromJson(Map<String, dynamic> json) {
    return SolicitacoesKpisDto(
      total: json['totalSolicitacoes'] ?? 0,
      pendentes: json['pendentes'] ?? 0,
      emAndamento: json['emAndamento'] ?? 0,
      concluidas: json['concluidas'] ?? 0,
      atrasadas: json['atrasadas'] ?? 0,
      taxaConclusao: (json['taxaConclusaoPercent'] ?? 0).toDouble(),
      taxaSla: (json['taxaSLAPercent'] ?? json['taxaSlaPercent'] ?? 0).toDouble(),
      mttrHoras: (json['tempoMedioResolucaoHoras'] ?? 0).toDouble(),
      diasAtrasoMedio: (json['diasAtrasoMedio'] ?? 0).toDouble(),
      diasAtrasoMediana: (json['diasAtrasoMediana'] ?? 0).toDouble(),
      percentOver48h: (json['percentOver48h'] ?? 0).toDouble(),
      bucketsAtraso: (json['atrasoBuckets'] as List<dynamic>?)
              ?.map((e) => BucketAtrasoDto.fromJson(e))
              .toList() ??
          [],
      topResponsaveisAtraso: (json['topResponsaveisAtraso'] as List<dynamic>?)
              ?.map((e) => ResponsavelAtrasoDto.fromJson(e))
              .toList() ??
          [],
      distribuicaoPorTipo: (json['solicitacoesPorTipo'] as List<dynamic>?)
              ?.map((e) => DistribuicaoTipoDto.fromJson(e))
              .toList() ??
          [],
      graficoMensal: (json['solicitacoesMensais'] as List<dynamic>?)
              ?.map((e) => GraficoMensalDto.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BucketAtrasoDto {
  final String faixa;
  final int quantidade;

  BucketAtrasoDto({required this.faixa, required this.quantidade});

  factory BucketAtrasoDto.fromJson(Map<String, dynamic> json) {
    return BucketAtrasoDto(
      faixa: json['bucket'] ?? '',
      quantidade: json['count'] ?? 0,
    );
  }
}

class ResponsavelAtrasoDto {
  final String nome;
  final int quantidadeAtrasadas;
  final double diasAtrasoMedio;

  ResponsavelAtrasoDto({
    required this.nome,
    required this.quantidadeAtrasadas,
    required this.diasAtrasoMedio,
  });

  factory ResponsavelAtrasoDto.fromJson(Map<String, dynamic> json) {
    return ResponsavelAtrasoDto(
      nome: json['nome'] ?? '',
      quantidadeAtrasadas: json['count'] ?? 0,
      diasAtrasoMedio: (json['diasAtrasoMedio'] ?? 0).toDouble(),
    );
  }
}

class DistribuicaoTipoDto {
  final String tipo;
  final int quantidade;
  final double percentual;

  DistribuicaoTipoDto({
    required this.tipo,
    required this.quantidade,
    required this.percentual,
  });

  factory DistribuicaoTipoDto.fromJson(Map<String, dynamic> json) {
    return DistribuicaoTipoDto(
      tipo: json['tipo'] ?? '',
      quantidade: json['quantidade'] ?? 0,
      percentual: (json['percentual'] ?? 0).toDouble(),
    );
  }
}

class GraficoMensalDto {
  final String mes;
  final int quantidade;

  GraficoMensalDto({
    required this.mes,
    required this.quantidade,
  });

  factory GraficoMensalDto.fromJson(Map<String, dynamic> json) {
    return GraficoMensalDto(
      mes: json['mesNome'] ?? '',
      quantidade: json['quantidade'] ?? 0,
    );
  }
}
