/// DTOs para geração de QR Codes em lote
/// Endpoints: /api/qrcodebatch/*
library;

import '../utils/app_date_time.dart';

/// Item do relatório de QR codes
class QrCodeBatchItemDto {
  final String id;
  final String codigoPatrimonio;
  final String nome;
  final String tipo;
  final int quantidade;
  final String estado;
  final String apartamentoNumero;
  final String apartamentoBloco;
  final String? qrCodeBase64;

  QrCodeBatchItemDto({
    required this.id,
    required this.codigoPatrimonio,
    required this.nome,
    required this.tipo,
    required this.quantidade,
    required this.estado,
    required this.apartamentoNumero,
    required this.apartamentoBloco,
    this.qrCodeBase64,
  });

  factory QrCodeBatchItemDto.fromJson(Map<String, dynamic> json) {
    return QrCodeBatchItemDto(
      id: json['id']?.toString() ?? '',
      codigoPatrimonio: json['codigoPatrimonio']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      quantidade: json['quantidade'] as int? ?? 1,
      estado: json['estado']?.toString() ?? '',
      apartamentoNumero:
          json['apartamentoNumero']?.toString() ??
          json['apartamento']?['numero']?.toString() ??
          '',
      apartamentoBloco:
          json['apartamentoBloco']?.toString() ??
          json['apartamento']?['bloco']?.toString() ??
          '',
      qrCodeBase64: json['qrCodeBase64']?.toString(),
    );
  }
}

/// Relatório de QR codes em lote
class QrCodeBatchRelatorioDto {
  final int totalItens;
  final DateTime dataRelatorio;
  final Map<String, int> agrupadoPorEstado;
  final int quantidade;
  final List<QrCodeBatchItemDto> itens;

  QrCodeBatchRelatorioDto({
    required this.totalItens,
    required this.dataRelatorio,
    required this.agrupadoPorEstado,
    required this.quantidade,
    required this.itens,
  });

  factory QrCodeBatchRelatorioDto.fromJson(Map<String, dynamic> json) {
    final agrupadoRaw =
        json['agrupadoPorEstado'] as Map<String, dynamic>? ?? {};
    final agrupado = agrupadoRaw.map((k, v) => MapEntry(k, v as int? ?? 0));

    final itensRaw = json['itens'] as List<dynamic>? ?? [];
    final itens = itensRaw
        .map((e) => QrCodeBatchItemDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return QrCodeBatchRelatorioDto(
      totalItens: json['totalItens'] as int? ?? 0,
      dataRelatorio:
          tryParseBackendDateTimeToLocal(json['dataRelatorio']?.toString() ?? '') ??
          DateTime.now(),
      agrupadoPorEstado: agrupado,
      quantidade: json['quantidade'] as int? ?? 0,
      itens: itens,
    );
  }
}

/// Opções disponíveis para geração de QR codes
class QrCodeBatchOpcoesDto {
  final List<String> formatos;
  final List<String> estados;
  final String exemploUrl;
  final String exemploHtmlUrl;

  QrCodeBatchOpcoesDto({
    required this.formatos,
    required this.estados,
    required this.exemploUrl,
    required this.exemploHtmlUrl,
  });

  factory QrCodeBatchOpcoesDto.fromJson(Map<String, dynamic> json) {
    return QrCodeBatchOpcoesDto(
      formatos:
          (json['formatos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['svg', 'png', 'pdf'],
      estados:
          (json['estados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Disponivel', 'Manutencao', 'Danificado', 'EmStock'],
      exemploUrl:
          json['exemploUrl']?.toString() ??
          '/api/qrcodebatch/download?estado=Disponivel&formato=svg',
      exemploHtmlUrl:
          json['exemploHtmlUrl']?.toString() ??
          '/api/qrcodebatch/html-impressao?estado=Disponivel',
    );
  }
}
