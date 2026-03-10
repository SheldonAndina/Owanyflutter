/// =====================================================================
/// DASHBOARD DTOs
/// Representam dados de KPIs e dashboard
/// =====================================================================
library;

import 'ativos_dtos.dart';
import '../utils/app_date_time.dart';

class DashboardCompletoDto {
  final DashboardKpisDto kpis;
  final List<SolicitacaoResumoDto> solicitacoesRecentes;
  final List<AgendamentoResumoDto> agendamentosProximos;
  final List<ReservaAreaResumoDto> reservasEmAberto;
  final OcupacaoStatsDto ocupacao;
  final AlertasDto alertas;
  final DashboardAtivosDto? ativos;

  DashboardCompletoDto({
    required this.kpis,
    required this.solicitacoesRecentes,
    required this.agendamentosProximos,
    required this.reservasEmAberto,
    required this.ocupacao,
    required this.alertas,
    this.ativos,
  });

  factory DashboardCompletoDto.fromJson(Map<String, dynamic> json) {
    return DashboardCompletoDto(
      kpis: DashboardKpisDto.fromJson(json['kpis'] ?? {}),
      solicitacoesRecentes:
          (json['solicitacoesRecentes'] as List<dynamic>?)?.map((s) => SolicitacaoResumoDto.fromJson(s)).toList() ?? [],
      agendamentosProximos:
          (json['agendamentosProximos'] as List<dynamic>?)?.map((a) => AgendamentoResumoDto.fromJson(a)).toList() ?? [],
      reservasEmAberto:
          (json['reservasEmAberto'] as List<dynamic>?)?.map((r) => ReservaAreaResumoDto.fromJson(r)).toList() ?? [],
      ocupacao: OcupacaoStatsDto.fromJson(json['ocupacao'] ?? {}),
      alertas: AlertasDto.fromJson(json['alertas'] ?? {}),
      ativos: json['ativos'] != null ? DashboardAtivosDto.fromJson(json['ativos']) : null,
    );
  }
}

class DashboardKpisDto {
  final int totalSolicitacoes;
  final int solicitacoesPendentes;
  final int solicitacoesEmAndamento;
  final int solicitacoesVencidas;
  final double tempoMedioResolucao; // em horas
  final int totalAgendamentos;
  final int agendamentosHoje;
  final int taxaOcupacao; // percentual
  final int areasComunsDisponiveis;
  final int reservasAreasPendentes;
  final double satisfacaoMedia; // 0-5

  DashboardKpisDto({
    required this.totalSolicitacoes,
    required this.solicitacoesPendentes,
    required this.solicitacoesEmAndamento,
    required this.solicitacoesVencidas,
    required this.tempoMedioResolucao,
    required this.totalAgendamentos,
    required this.agendamentosHoje,
    required this.taxaOcupacao,
    required this.areasComunsDisponiveis,
    required this.reservasAreasPendentes,
    required this.satisfacaoMedia,
  });

  factory DashboardKpisDto.fromJson(Map<String, dynamic> json) {
    return DashboardKpisDto(
      totalSolicitacoes: json['totalSolicitacoes'] ?? 0,
      solicitacoesPendentes: json['solicitacoesPendentes'] ?? 0,
      solicitacoesEmAndamento: json['solicitacoesEmAndamento'] ?? 0,
      solicitacoesVencidas: json['solicitacoesVencidas'] ?? 0,
      tempoMedioResolucao: (json['tempoMedioResolucao'] ?? 0).toDouble(),
      totalAgendamentos: json['totalAgendamentos'] ?? 0,
      agendamentosHoje: json['agendamentosHoje'] ?? 0,
      taxaOcupacao: json['taxaOcupacao'] ?? 0,
      areasComunsDisponiveis: json['areasComunsDisponiveis'] ?? 0,
      reservasAreasPendentes: json['reservasAreasPendentes'] ?? 0,
      satisfacaoMedia: (json['satisfacaoMedia'] ?? 0).toDouble(),
    );
  }
}

class SolicitacaoResumoDto {
  final String id;
  final String titulo;
  final String status;
  final String apartamento;
  final DateTime criadoEm;

  SolicitacaoResumoDto({
    required this.id,
    required this.titulo,
    required this.status,
    required this.apartamento,
    required this.criadoEm,
  });

  factory SolicitacaoResumoDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoResumoDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      status: json['status'] ?? '',
      apartamento: json['apartamento'] ?? '',
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }
}

class AgendamentoResumoDto {
  final String id;
  final String titulo;
  final DateTime dataAgendada;
  final String apartamento;
  final String status;

  AgendamentoResumoDto({
    required this.id,
    required this.titulo,
    required this.dataAgendada,
    required this.apartamento,
    required this.status,
  });

  factory AgendamentoResumoDto.fromJson(Map<String, dynamic> json) {
    return AgendamentoResumoDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      dataAgendada: parseBackendDateTimeToLocal(json['dataAgendada']),
      apartamento: json['apartamento'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class ReservaAreaResumoDto {
  final String id;
  final String area;
  final DateTime dataInicio;
  final String morador;
  final String status;

  ReservaAreaResumoDto({
    required this.id,
    required this.area,
    required this.dataInicio,
    required this.morador,
    required this.status,
  });

  factory ReservaAreaResumoDto.fromJson(Map<String, dynamic> json) {
    return ReservaAreaResumoDto(
      id: json['id'] ?? '',
      area: json['area'] ?? '',
      dataInicio: parseBackendDateTimeToLocal(json['dataInicio']),
      morador: json['morador'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class OcupacaoStatsDto {
  final int totalApartamentos;
  final int apartamentosOcupados;
  final int apartamentosDisponiveis;
  final int apartamentosEmManutencao;
  final int apartamentosComAusencia;

  OcupacaoStatsDto({
    required this.totalApartamentos,
    required this.apartamentosOcupados,
    required this.apartamentosDisponiveis,
    required this.apartamentosEmManutencao,
    required this.apartamentosComAusencia,
  });

  factory OcupacaoStatsDto.fromJson(Map<String, dynamic> json) {
    return OcupacaoStatsDto(
      totalApartamentos: json['totalApartamentos'] ?? 0,
      apartamentosOcupados: json['apartamentosOcupados'] ?? 0,
      apartamentosDisponiveis: json['apartamentosDisponiveis'] ?? 0,
      apartamentosEmManutencao: json['apartamentosEmManutencao'] ?? 0,
      apartamentosComAusencia: json['apartamentosComAusencia'] ?? 0,
    );
  }
}

class AlertasDto {
  final List<AlertaDto> criticos;
  final List<AlertaDto> avisos;
  final List<AlertaDto> informativos;

  AlertasDto({required this.criticos, required this.avisos, required this.informativos});

  factory AlertasDto.fromJson(Map<String, dynamic> json) {
    return AlertasDto(
      criticos: (json['criticos'] as List<dynamic>?)?.map((a) => AlertaDto.fromJson(a)).toList() ?? [],
      avisos: (json['avisos'] as List<dynamic>?)?.map((a) => AlertaDto.fromJson(a)).toList() ?? [],
      informativos: (json['informativos'] as List<dynamic>?)?.map((a) => AlertaDto.fromJson(a)).toList() ?? [],
    );
  }
}

class AlertaDto {
  final String id;
  final String titulo;
  final String descricao;
  final String tipo; // Critico, Aviso, Informativo
  final DateTime data;

  AlertaDto({required this.id, required this.titulo, required this.descricao, required this.tipo, required this.data});

  factory AlertaDto.fromJson(Map<String, dynamic> json) {
    return AlertaDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      tipo: json['tipo'] ?? 'Informativo',
      data: parseBackendDateTimeToLocal(json['data']),
    );
  }
}
