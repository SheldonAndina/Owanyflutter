/// =====================================================================
/// SOLICITAÇÕES REQUEST DTOs
/// DTOs para requisições de solicitações
/// =====================================================================
library;

import '../utils/app_date_time.dart';

/// DTO para atribuir responsável a uma solicitação
class AtribuirResponsavelRequest {
  final String solicitacaoId;
  final String responsavelId;
  final String? descricaoAtribuicao;

  AtribuirResponsavelRequest({
    required this.solicitacaoId,
    required this.responsavelId,
    this.descricaoAtribuicao,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'responsavelId': responsavelId,
    'descricaoAtribuicao': descricaoAtribuicao,
  };
}

/// DTO para definir prazo de uma solicitação
class DefinirPrazoRequest {
  final String solicitacaoId;
  final DateTime prazoLimite;
  final String? observacoes;

  DefinirPrazoRequest({
    required this.solicitacaoId,
    required this.prazoLimite,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'prazoLimite': toBackendUtcIsoString(prazoLimite),
    'observacoes': observacoes,
  };
}

/// DTO para alterar status de uma solicitação
class AlterarStatusSolicitacaoRequest {
  final String solicitacaoId;
  final String novoStatus;
  final String? observacoes;

  AlterarStatusSolicitacaoRequest({
    required this.solicitacaoId,
    required this.novoStatus,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'novoStatus': novoStatus,
    'observacoes': observacoes,
  };
}

/// DTO para adicionar comentário a uma solicitação
class NovoComentarioRequest {
  final String solicitacaoId;
  final String mensagem;
  final bool interno;

  NovoComentarioRequest({
    required this.solicitacaoId,
    required this.mensagem,
    this.interno = false,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'mensagem': mensagem,
    'interno': interno,
  };
}

/// DTO response para comentário
class ComentarioResponseDto {
  final String id;
  final String solicitacaoId;
  final String usuarioId;
  final String nomeUsuario;
  final String tipoUsuario;
  final String mensagem;
  final bool interno;
  final DateTime criadoEm;

  ComentarioResponseDto({
    required this.id,
    required this.solicitacaoId,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.tipoUsuario,
    required this.mensagem,
    required this.interno,
    required this.criadoEm,
  });

  factory ComentarioResponseDto.fromJson(Map<String, dynamic> json) {
    return ComentarioResponseDto(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      nomeUsuario: json['nomeUsuario'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      mensagem: json['mensagem'] ?? '',
      interno: json['interno'] ?? false,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'solicitacaoId': solicitacaoId,
    'usuarioId': usuarioId,
    'nomeUsuario': nomeUsuario,
    'tipoUsuario': tipoUsuario,
    'mensagem': mensagem,
    'interno': interno,
    'criadoEm': toBackendUtcIsoString(criadoEm),
  };
}
