// DTOs para movimentação de itens de apartamento

import '../utils/app_date_time.dart';

class TransferirItemApartamentoRequest {
  final String itemApartamentoId;
  final String apartamentoDestinoId;
  final String novoEstado;
  final String motivo;
  final String observacoes;

  TransferirItemApartamentoRequest({
    required this.itemApartamentoId,
    required this.apartamentoDestinoId,
    required this.novoEstado,
    required this.motivo,
    required this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'itemApartamentoId': itemApartamentoId,
    'apartamentoDestinoId': apartamentoDestinoId,
    'novoEstado': novoEstado,
    'motivo': motivo,
    'observacoes': observacoes,
  };
}

class AtualizarEstadoItemApartamentoRequest {
  final String itemApartamentoId;
  final String novoEstado;
  final String motivo;
  final String observacoes;

  AtualizarEstadoItemApartamentoRequest({
    required this.itemApartamentoId,
    required this.novoEstado,
    required this.motivo,
    required this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'itemApartamentoId': itemApartamentoId,
    'novoEstado': novoEstado,
    'motivo': motivo,
    'observacoes': observacoes,
  };
}

class ApartamentoMovimentacaoDto {
  final String id;
  final String numero;
  final String bloco;

  ApartamentoMovimentacaoDto({
    required this.id,
    required this.numero,
    required this.bloco,
  });

  factory ApartamentoMovimentacaoDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ApartamentoMovimentacaoDto(id: '', numero: '', bloco: '');
    }
    return ApartamentoMovimentacaoDto(
      id: json['id']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      bloco: json['bloco']?.toString() ?? '',
    );
  }
}

class ResponsavelMovimentacaoDto {
  final String id;
  final String nome;

  ResponsavelMovimentacaoDto({
    required this.id,
    required this.nome,
  });

  factory ResponsavelMovimentacaoDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ResponsavelMovimentacaoDto(id: '', nome: '');
    }
    return ResponsavelMovimentacaoDto(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
    );
  }
}

/// Resumo de uma solicitação vinculada a uma movimentação de item
class SolicitacaoResumoItemDto {
  final String id;
  final String titulo;
  final String status;

  SolicitacaoResumoItemDto({
    required this.id,
    required this.titulo,
    required this.status,
  });

  factory SolicitacaoResumoItemDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoResumoItemDto(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class ItemApartamentoMovimentacaoHistoricoDto {
  final String id;
  final String itemApartamentoId;
  final String apartamentoOrigemId;
  final String apartamentoDestinoId;
  final String estadoAnterior;
  final String estadoNovo;
  final String motivo;
  final String observacoes;
  final DateTime criadoEm;
  final ApartamentoMovimentacaoDto? origem;
  final ApartamentoMovimentacaoDto? destino;
  final ResponsavelMovimentacaoDto? responsavel;
  final String estado;
  final SolicitacaoResumoItemDto? solicitacao;

  ItemApartamentoMovimentacaoHistoricoDto({
    required this.id,
    required this.itemApartamentoId,
    required this.apartamentoOrigemId,
    required this.apartamentoDestinoId,
    required this.estadoAnterior,
    required this.estadoNovo,
    required this.motivo,
    required this.observacoes,
    required this.criadoEm,
    this.origem,
    this.destino,
    this.responsavel,
    this.estado = '',
    this.solicitacao,
  });

  factory ItemApartamentoMovimentacaoHistoricoDto.fromJson(Map<String, dynamic> json) {
    return ItemApartamentoMovimentacaoHistoricoDto(
      id: json['id']?.toString() ?? '',
      itemApartamentoId: json['itemApartamentoId']?.toString() ?? '',
      apartamentoOrigemId: json['apartamentoOrigemId']?.toString() ?? json['apartamentoAnteriorId']?.toString() ?? '',
      apartamentoDestinoId: json['apartamentoDestinoId']?.toString() ?? json['apartamentoNovoId']?.toString() ?? '',
      estadoAnterior: json['estadoAnterior']?.toString() ?? '',
      estadoNovo: json['estadoNovo']?.toString() ?? json['novoEstado']?.toString() ?? '',
      motivo: json['motivo']?.toString() ?? json['tipoMovimentacao']?.toString() ?? '',
      observacoes: json['observacoes']?.toString() ?? '',
      criadoEm: json['criadoEm'] != null
          ? (tryParseBackendDateTimeToLocal(json['criadoEm'].toString()) ?? DateTime.now())
          : (json['dataMovimentacao'] != null
              ? (tryParseBackendDateTimeToLocal(json['dataMovimentacao'].toString()) ?? DateTime.now())
              : DateTime.now()),
      origem: json['origem'] != null
          ? ApartamentoMovimentacaoDto.fromJson(json['origem'])
          : (json['apartamentoOrigem'] != null
              ? ApartamentoMovimentacaoDto.fromJson(json['apartamentoOrigem'])
              : null),
      destino: json['destino'] != null
          ? ApartamentoMovimentacaoDto.fromJson(json['destino'])
          : (json['apartamentoDestino'] != null
              ? ApartamentoMovimentacaoDto.fromJson(json['apartamentoDestino'])
              : null),
      responsavel: json['responsavel'] != null
          ? ResponsavelMovimentacaoDto.fromJson(json['responsavel'])
          : (json['usuarioResponsavel'] != null
              ? ResponsavelMovimentacaoDto.fromJson(json['usuarioResponsavel'])
              : null),
      estado: json['estado']?.toString() ?? '',
      solicitacao: json['solicitacao'] != null
          ? SolicitacaoResumoItemDto.fromJson(
              json['solicitacao'] as Map<String, dynamic>)
          : null,
    );
  }
}
