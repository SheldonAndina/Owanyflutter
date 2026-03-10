/// =====================================================================
/// AGENDAMENTOS (SCHEDULING) REQUEST DTOs
/// DTOs para requisições de agendamentos
/// =====================================================================
library;

import '../utils/app_date_time.dart';

/// Status de aceite de agendamento
class StatusAceiteAgendamento {
  static const String Pendente = 'Pendente';
  static const String Aceito = 'Aceito';
  static const String Rejeitado = 'Rejeitado';
}

/// DTO para aceitar um agendamento
class AceitarAgendamentoRequest {
  final String agendamentoId;
  final String? observacoes;

  AceitarAgendamentoRequest({
    required this.agendamentoId,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'agendamentoId': agendamentoId,
    'observacoes': observacoes,
  };
}

/// DTO para rejeitar um agendamento
class RejeitarAgendamentoRequest {
  final String agendamentoId;
  final String motivo;

  RejeitarAgendamentoRequest({
    required this.agendamentoId,
    required this.motivo,
  });

  Map<String, dynamic> toJson() => {
    'agendamentoId': agendamentoId,
    'motivo': motivo,
  };
}

/// DTO para criar um agendamento (morador)
class CriarAgendamentoMoradorRequest {
  final String solicitacaoId;
  final DateTime dataAgendada;
  final String? observacoes;

  CriarAgendamentoMoradorRequest({
    required this.solicitacaoId,
    required this.dataAgendada,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'dataAgendada': toBackendUtcIsoString(dataAgendada),
    'observacoes': observacoes,
  };
}

/// DTO para responder agendamento (morador aceita/rejeita)
class ResponderAgendamentoRequest {
  final String agendamentoId;
  final String resposta; // 'Aceito' ou 'Rejeitado'
  final String? observacoes;

  ResponderAgendamentoRequest({
    required this.agendamentoId,
    required this.resposta,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'agendamentoId': agendamentoId,
    'resposta': resposta,
    'observacoes': observacoes,
  };
}

/// DTO response para agendamento detalhado
class AgendamentoDetalheDto {
  final String id;
  final String titulo;
  final String descricao;
  final String apartamentoId;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final String? moradorId;
  final String? nomeMorador;
  final String? responsavelTecnicoId;
  final String? responsavelTecnicoNome;
  final DateTime dataAgendada;
  final int? duracaoEstimadaHoras;
  final String? status; // Pendente, Agendado, Concluído, Cancelado
  final String? statusAceite; // Pendente, Aceito, Rejeitado (para morador)
  final DateTime? dataAceite;
  final String? observacoesAceite;
  final String? motivoRejeicao;
  final String? fornecedor;
  final double? custoEstimado;
  final DateTime? dataInicioReal;
  final DateTime? dataConclusao;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  AgendamentoDetalheDto({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.apartamentoId,
    this.numeroApartamento,
    this.blocoApartamento,
    this.moradorId,
    this.nomeMorador,
    this.responsavelTecnicoId,
    this.responsavelTecnicoNome,
    required this.dataAgendada,
    this.duracaoEstimadaHoras,
    this.status,
    this.statusAceite,
    this.dataAceite,
    this.observacoesAceite,
    this.motivoRejeicao,
    this.fornecedor,
    this.custoEstimado,
    this.dataInicioReal,
    this.dataConclusao,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory AgendamentoDetalheDto.fromJson(Map<String, dynamic> json) {
    return AgendamentoDetalheDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      apartamentoId: json['apartamentoId'] ?? '',
      numeroApartamento: json['numeroApartamento']?.toString(),
      blocoApartamento: json['blocoApartamento']?.toString(),
      moradorId: json['moradorId'],
      nomeMorador: json['nomeMorador'],
      responsavelTecnicoId: json['responsavelTecnicoId'],
      responsavelTecnicoNome: json['responsavelTecnicoNome'],
      dataAgendada: parseBackendDateTimeToLocal(json['dataAgendada']),
      duracaoEstimadaHoras: json['duracaoEstimadaHoras'],
      status: json['status'],
      statusAceite: json['statusAceite'],
      dataAceite: tryParseBackendDateTimeToLocal(json['dataAceite']),
      observacoesAceite: json['observacoesAceite'],
      motivoRejeicao: json['motivoRejeicao'],
      fornecedor: json['fornecedor'],
      custoEstimado: json['custoEstimado'] != null ? (json['custoEstimado'] as num).toDouble() : null,
      dataInicioReal: tryParseBackendDateTimeToLocal(json['dataInicioReal']),
      dataConclusao: tryParseBackendDateTimeToLocal(json['dataConclusao']),
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descricao': descricao,
    'apartamentoId': apartamentoId,
    'numeroApartamento': numeroApartamento,
    'blocoApartamento': blocoApartamento,
    'moradorId': moradorId,
    'nomeMorador': nomeMorador,
    'responsavelTecnicoId': responsavelTecnicoId,
    'responsavelTecnicoNome': responsavelTecnicoNome,
    'dataAgendada': toBackendUtcIsoString(dataAgendada),
    'duracaoEstimadaHoras': duracaoEstimadaHoras,
    'status': status,
    'statusAceite': statusAceite,
    'dataAceite': dataAceite != null ? toBackendUtcIsoString(dataAceite!) : null,
    'observacoesAceite': observacoesAceite,
    'motivoRejeicao': motivoRejeicao,
    'fornecedor': fornecedor,
    'custoEstimado': custoEstimado,
    'dataInicioReal': dataInicioReal != null ? toBackendUtcIsoString(dataInicioReal!) : null,
    'dataConclusao': dataConclusao != null ? toBackendUtcIsoString(dataConclusao!) : null,
    'criadoEm': toBackendUtcIsoString(criadoEm),
    'atualizadoEm': atualizadoEm != null ? toBackendUtcIsoString(atualizadoEm!) : null,
  };
}

/// DTO para listar agendamentos com filtros
class ListarAgendamentosDto {
  final String id;
  final String titulo;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final DateTime dataAgendada;
  final String? status;
  final String? statusAceite;
  final String? nomeMorador;
  final String? responsavelTecnicoNome;

  ListarAgendamentosDto({
    required this.id,
    required this.titulo,
    this.numeroApartamento,
    this.blocoApartamento,
    required this.dataAgendada,
    this.status,
    this.statusAceite,
    this.nomeMorador,
    this.responsavelTecnicoNome,
  });

  factory ListarAgendamentosDto.fromJson(Map<String, dynamic> json) {
    return ListarAgendamentosDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      numeroApartamento: json['numeroApartamento']?.toString(),
      blocoApartamento: json['blocoApartamento']?.toString(),
      dataAgendada: parseBackendDateTimeToLocal(json['dataAgendada']),
      status: json['status'],
      statusAceite: json['statusAceite'],
      nomeMorador: json['nomeMorador'],
      responsavelTecnicoNome: json['responsavelTecnicoNome'],
    );
  }
}
