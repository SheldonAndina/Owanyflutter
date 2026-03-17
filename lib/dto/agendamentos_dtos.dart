/// =====================================================================
/// AGENDAMENTOS MAINTENANCE DTOs
/// Representam dados de agendamentos de manutenção
/// Corresponde ao modelo AgendamentoManutencao do backend C#
/// =====================================================================
library;

import '../utils/app_date_time.dart';

double? _parseDoubleValue(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final sanitized = raw.replaceAll(RegExp(r'[^0-9,\.]'), '');
  if (sanitized.isEmpty) return null;

  final hasComma = sanitized.contains(',');
  final hasDot = sanitized.contains('.');
  String normalized = sanitized;

  if (hasComma && hasDot) {
    normalized = sanitized.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    normalized = sanitized.replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

class AgendamentoMaintenanceDto {
  final String id;
  final String apartamentoId;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final String titulo;
  final String? descricao;
  final String? tipo; // ManutencaoTipo enum
  final String? tipoSolicitacaoId;
  final String? tipoSolicitacaoNome;
  final String? areaTecnicaId;
  final String? areaTecnicaNome;
  final DateTime dataAgendada;
  final int? duracaoEstimadaHoras;
  final String status; // StatusAgendamentoManutencao
  final String? responsavelTecnicoId;
  final String? responsavelTecnicoNome;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final double? custoEstimado;
  final String? observacoes;
  
  // Aceitação do morador
  final String? respondidoPorMoradorId;
  final String? respondidoPorMoradorNome;
  final DateTime? dataResposta;
  final String? motivoRecusa;
  
  // Execução
  final DateTime? dataInicioReal;
  final DateTime? dataConclusao;
  final double? custoReal;
  final double? custoMaoObra;
  final double? custoMaterial;
  final String? relatorioExecucao;
  final String? notaFiscal;
  final String? fotosAntes;
  final String? fotosDepois;
  final int? avaliacaoMorador;
  final String? comentarioAvaliacao;
  
  // Item vinculado
  final String? itemApartamentoId;
  final String? itemApartamentoNome;
  final String? itemApartamentoCodigoPatrimonio;
  
  // Auditoria
  final DateTime? criadoEm;
  final String? criadoPorId;
  final String? criadoPorNome;
  final DateTime? atualizadoEm;
  final String? atualizadoPorId;
  final String? atualizadoPorNome;

  AgendamentoMaintenanceDto({
    required this.id,
    required this.apartamentoId,
    this.numeroApartamento,
    this.blocoApartamento,
    required this.titulo,
    this.descricao,
    this.tipo,
    this.tipoSolicitacaoId,
    this.tipoSolicitacaoNome,
    this.areaTecnicaId,
    this.areaTecnicaNome,
    required this.dataAgendada,
    this.duracaoEstimadaHoras,
    required this.status,
    this.responsavelTecnicoId,
    this.responsavelTecnicoNome,
    this.fornecedor,
    this.telefoneFornecedor,
    this.custoEstimado,
    this.observacoes,
    this.respondidoPorMoradorId,
    this.respondidoPorMoradorNome,
    this.dataResposta,
    this.motivoRecusa,
    this.dataInicioReal,
    this.dataConclusao,
    this.custoReal,
    this.custoMaoObra,
    this.custoMaterial,
    this.relatorioExecucao,
    this.notaFiscal,
    this.fotosAntes,
    this.fotosDepois,
    this.avaliacaoMorador,
    this.comentarioAvaliacao,
    this.itemApartamentoId,
    this.itemApartamentoNome,
    this.itemApartamentoCodigoPatrimonio,
    this.criadoEm,
    this.criadoPorId,
    this.criadoPorNome,
    this.atualizadoEm,
    this.atualizadoPorId,
    this.atualizadoPorNome,
  });

  factory AgendamentoMaintenanceDto.fromJson(Map<String, dynamic> json) {
    return AgendamentoMaintenanceDto(
      id: json['id'] ?? '',
      apartamentoId: json['apartamentoId'] ?? '',
      numeroApartamento: json['apartamentoNumero']?.toString() ?? json['numeroApartamento']?.toString(),
      blocoApartamento: json['apartamentoBloco']?.toString() ?? json['blocoApartamento']?.toString(),
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ??
          json['Descricao'] ??
          json['descricaoManutencao'] ??
          json['descricaoServico'] ??
          json['observacoes'] ??
          json['Observacoes'],
      tipo: json['tipo']?.toString(),
      tipoSolicitacaoId: json['tipoSolicitacaoId'],
      tipoSolicitacaoNome: json['tipoSolicitacaoNome'],
      areaTecnicaId: json['areaTecnicaId'],
      areaTecnicaNome: json['areaTecnicaNome'],
      dataAgendada: parseBackendDateTimeToLocal(json['dataAgendada']),
      duracaoEstimadaHoras: json['duracaoEstimadaHoras'],
      status: json['status'] ?? 'PendenteAceitacao',
      responsavelTecnicoId: json['responsavelTecnicoId'],
      responsavelTecnicoNome: json['responsavelTecnicoNome'],
      fornecedor: json['fornecedor'],
      telefoneFornecedor: json['telefoneFornecedor'],
      custoEstimado: _parseDoubleValue(json['custoEstimado']),
      observacoes: json['observacoes'],
      respondidoPorMoradorId: json['respondidoPorMoradorId'],
      respondidoPorMoradorNome: json['respondidoPorMoradorNome'],
      dataResposta: tryParseBackendDateTimeToLocal(json['dataResposta']),
      motivoRecusa: json['motivoRecusa'],
      dataInicioReal: tryParseBackendDateTimeToLocal(json['dataInicioReal']),
      dataConclusao: tryParseBackendDateTimeToLocal(json['dataConclusao']),
      custoReal: _parseDoubleValue(json['custoReal']),
      custoMaoObra: _parseDoubleValue(
        json['custoMaoObra'] ?? json['CustoMaoObra'],
      ),
      custoMaterial: _parseDoubleValue(
        json['custoMaterial'] ?? json['CustoMaterial'],
      ),
      relatorioExecucao: json['relatorioExecucao'],
      notaFiscal: json['notaFiscal'],
      fotosAntes: json['fotosAntes'],
      fotosDepois: json['fotosDepois'],
      avaliacaoMorador: json['avaliacaoMorador'],
      comentarioAvaliacao: json['comentarioAvaliacao'],
      itemApartamentoId: json['itemApartamentoId'],
      itemApartamentoNome: json['itemApartamentoNome'],
      itemApartamentoCodigoPatrimonio: json['itemApartamentoCodigoPatrimonio'],
      criadoEm: tryParseBackendDateTimeToLocal(json['criadoEm']),
      criadoPorId: json['criadoPorId'],
      criadoPorNome: json['criadoPorNome'],
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
      atualizadoPorId: json['atualizadoPorId'],
      atualizadoPorNome: json['atualizadoPorNome'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'apartamentoId': apartamentoId,
    'titulo': titulo,
    'descricao': descricao,
    'tipo': tipo,
    'tipoSolicitacaoId': tipoSolicitacaoId,
    'areaTecnicaId': areaTecnicaId,
    'dataAgendada': toBackendUtcIsoString(dataAgendada),
    'duracaoEstimadaHoras': duracaoEstimadaHoras,
    'status': status,
    'responsavelTecnicoId': responsavelTecnicoId,
    'fornecedor': fornecedor,
    'telefoneFornecedor': telefoneFornecedor,
    'custoEstimado': custoEstimado,
    'observacoes': observacoes,
    'respondidoPorMoradorId': respondidoPorMoradorId,
    'dataResposta': dataResposta != null ? toBackendUtcIsoString(dataResposta!) : null,
    'motivoRecusa': motivoRecusa,
    'dataInicioReal': dataInicioReal != null ? toBackendUtcIsoString(dataInicioReal!) : null,
    'dataConclusao': dataConclusao != null ? toBackendUtcIsoString(dataConclusao!) : null,
    'custoReal': custoReal,
    'custoMaoObra': custoMaoObra,
    'custoMaterial': custoMaterial,
    'relatorioExecucao': relatorioExecucao,
    'notaFiscal': notaFiscal,
    'fotosAntes': fotosAntes,
    'fotosDepois': fotosDepois,
    'avaliacaoMorador': avaliacaoMorador,
    'comentarioAvaliacao': comentarioAvaliacao,
    'itemApartamentoId': itemApartamentoId,
  };

  // Métodos auxiliares para controle de estado
  bool get isPendenteAceitacao => status == 'PendenteAceitacao';
  bool get isAceito => status == 'Aceito';
  bool get isRecusado => status == 'Recusado';
  bool get isConfirmado => status == 'Confirmado';
  bool get isEmAndamento => status == 'EmAndamento';
  bool get isConcluido => status == 'Concluido';
  bool get isCancelado => status == 'Cancelado';
  
  bool get podeSerEditado => isPendenteAceitacao || isAceito;
  bool get podeSerConfirmado => isAceito;
  bool get podeSerIniciado => isConfirmado;
  bool get podeSerConcluido => isEmAndamento;
  bool get podeSerCancelado => !isConcluido && !isCancelado;
  
  String get displayApartamento => 'Apto $numeroApartamento - $blocoApartamento';
  String get displayStatus => _formatarStatus(status);
  
  static String _formatarStatus(String status) {
    switch (status) {
      case 'PendenteAceitacao': return 'Pendente Aceitação';
      case 'Aceito': return 'Aceito';
      case 'Recusado': return 'Recusado';
      case 'Confirmado': return 'Confirmado';
      case 'EmAndamento': return 'Em Andamento';
      case 'Concluido': return 'Concluído';
      case 'Cancelado': return 'Cancelado';
      default: return status;
    }
  }
}

class RespostaAgendamentoDto {
  final bool aceitar;
  final String? motivoRecusa;

  RespostaAgendamentoDto({required this.aceitar, this.motivoRecusa});

  Map<String, dynamic> toJson() => {'aceitar': aceitar, 'motivoRecusa': motivoRecusa};
}

class AvaliacaoAgendamentoDto {
  final int avaliacao;
  final String comentario;

  AvaliacaoAgendamentoDto({required this.avaliacao, required this.comentario});

  Map<String, dynamic> toJson() => {'avaliacao': avaliacao, 'comentario': comentario};
}

/// Request para criar novo agendamento de manutenção geral
class CriarManutencaoGeralRequest {
  final String apartamentoId;
  final String titulo;
  final String? descricao;
  final String? tipo; // ManutencaoTipo
  final String? tipoSolicitacaoId;
  final String? areaTecnicaId;
  final DateTime dataAgendada;
  final int? duracaoEstimadaHoras;
  final String? responsavelTecnicoId;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final double? custoEstimado;
  final String? observacoes;
  final String? itemApartamentoId;

  CriarManutencaoGeralRequest({
    required this.apartamentoId,
    required this.titulo,
    this.descricao,
    this.tipo,
    this.tipoSolicitacaoId,
    this.areaTecnicaId,
    required this.dataAgendada,
    this.duracaoEstimadaHoras,
    this.responsavelTecnicoId,
    this.fornecedor,
    this.telefoneFornecedor,
    this.custoEstimado,
    this.observacoes,
    this.itemApartamentoId,
  });

  Map<String, dynamic> toJson() => {
    'apartamentoId': apartamentoId,
    'titulo': titulo,
    'descricao': descricao,
    'tipo': tipo,
    'tipoSolicitacaoId': tipoSolicitacaoId,
    'areaTecnicaId': areaTecnicaId,
    'dataAgendada': toBackendUtcIsoString(dataAgendada),
    'duracaoEstimadaHoras': duracaoEstimadaHoras,
    'responsavelTecnicoId': responsavelTecnicoId,
    'fornecedor': fornecedor,
    'telefoneFornecedor': telefoneFornecedor,
    'custoEstimado': custoEstimado,
    'observacoes': observacoes,
    'itemApartamentoId': itemApartamentoId,
  };
}

/// Request para responder agendamento (aceitar/recusar)
class ResponderManutencaoGeralRequest {
  final bool aceitar;
  final String? motivoRecusa;

  ResponderManutencaoGeralRequest({
    required this.aceitar,
    this.motivoRecusa,
  });

  Map<String, dynamic> toJson() => {
    'aceitar': aceitar,
    'motivoRecusa': motivoRecusa,
  };
}

/// Request para concluir manutenção geral
class ConcluirManutencaoGeralRequest {
  final double? custoReal;
  final String? relatorioExecucao;
  final String? notaFiscal;
  final String? fotosAntes;
  final String? fotosDepois;

  ConcluirManutencaoGeralRequest({
    this.custoReal,
    this.relatorioExecucao,
    this.notaFiscal,
    this.fotosAntes,
    this.fotosDepois,
  });

  Map<String, dynamic> toJson() => {
    'custoReal': custoReal,
    'relatorioExecucao': relatorioExecucao,
    'notaFiscal': notaFiscal,
    'fotosAntes': fotosAntes,
    'fotosDepois': fotosDepois,
  };
}
