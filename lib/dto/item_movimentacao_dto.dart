import '../utils/app_date_time.dart';

class TransferirItemRequest {
  final String itemApartamentoId;
  final String apartamentoDestinoId;
  final String? novoEstado;
  final String? motivo;
  final String? observacoes;

  TransferirItemRequest({
    required this.itemApartamentoId,
    required this.apartamentoDestinoId,
    this.novoEstado,
    this.motivo,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'itemApartamentoId': itemApartamentoId,
    'apartamentoDestinoId': apartamentoDestinoId,
    if (novoEstado != null) 'novoEstado': novoEstado,
    if (motivo != null) 'motivo': motivo,
    if (observacoes != null) 'observacoes': observacoes,
  };
}

class AtualizarEstadoItemRequest {
  final String itemApartamentoId;
  final String novoEstado;
  final String? motivo;
  final String? observacoes;

  AtualizarEstadoItemRequest({
    required this.itemApartamentoId,
    required this.novoEstado,
    this.motivo,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'itemApartamentoId': itemApartamentoId,
    'novoEstado': novoEstado,
    if (motivo != null) 'motivo': motivo,
    if (observacoes != null) 'observacoes': observacoes,
  };
}

/// Resumo de uma solicitação vinculada a uma movimentação de item
class SolicitacaoResumoMovDto {
  final String id;
  final String titulo;
  final String status;

  SolicitacaoResumoMovDto({
    required this.id,
    required this.titulo,
    required this.status,
  });

  factory SolicitacaoResumoMovDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoResumoMovDto(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class MovimentacaoDto {
  final String id;
  final String itemApartamentoId;
  final String? apartamentoOrigemId;
  final String? apartamentoDestinoId;
  final String? novoEstado;
  final String? motivo;
  final String? observacoes;
  final DateTime criadoEm;
  final String? usuarioNome;
  final String tipo; // 'Transferencia' | 'AtualizacaoEstado' | 'VinculoSolicitacao' etc.
  final SolicitacaoResumoMovDto? solicitacao;

  MovimentacaoDto({
    required this.id,
    required this.itemApartamentoId,
    this.apartamentoOrigemId,
    this.apartamentoDestinoId,
    this.novoEstado,
    this.motivo,
    this.observacoes,
    required this.criadoEm,
    this.usuarioNome,
    required this.tipo,
    this.solicitacao,
  });

  factory MovimentacaoDto.fromJson(Map<String, dynamic> json) {
    return MovimentacaoDto(
      id: json['id'] as String,
      itemApartamentoId: json['itemApartamentoId'] as String,
      apartamentoOrigemId: json['apartamentoOrigemId'] as String?,
      apartamentoDestinoId: json['apartamentoDestinoId'] as String?,
      novoEstado: json['novoEstado'] as String?,
      motivo: json['motivo'] as String?,
      observacoes: json['observacoes'] as String?,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm'] as String),
      usuarioNome: json['usuarioNome'] as String?,
      tipo: json['tipo'] as String? ?? 'Movimentacao',
      solicitacao: json['solicitacao'] != null
          ? SolicitacaoResumoMovDto.fromJson(
              json['solicitacao'] as Map<String, dynamic>)
          : null,
    );
  }
}
