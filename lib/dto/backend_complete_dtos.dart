/// =====================================================================
/// BACKEND COMPLETE DTOs - Mapeamento completo da API
/// Todos os DTOs necessários para comunicação com backend
/// =====================================================================
library;

import '../utils/app_date_time.dart';

// ==================== MANUTENÇÕES PREVENTIVAS ====================

class ManutencaoPreventivaBkendDto {
  final String id;
  final String titulo;
  final String? descricao;
  final String tipo;
  final String frequencia;
  final DateTime proximaManutencao;
  final DateTime? ultimaManutencao;
  final int diasAlerta;
  final double? custoEstimado;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final bool ativa;
  final int totalExecucoes;

  ManutencaoPreventivaBkendDto({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.tipo,
    required this.frequencia,
    required this.proximaManutencao,
    this.ultimaManutencao,
    required this.diasAlerta,
    this.custoEstimado,
    this.fornecedor,
    this.telefoneFornecedor,
    required this.ativa,
    required this.totalExecucoes,
  });

  factory ManutencaoPreventivaBkendDto.fromJson(Map<String, dynamic> json) {
    return ManutencaoPreventivaBkendDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      tipo: json['tipo'] ?? 'Outras',
      frequencia: json['frequencia'] ?? 'Mensal',
      proximaManutencao: parseBackendDateTimeToLocal(json['proximaManutencao']),
      ultimaManutencao: tryParseBackendDateTimeToLocal(json['ultimaManutencao']),
      diasAlerta: json['diasAlerta'] ?? 7,
      custoEstimado: json['custoEstimado']?.toDouble(),
      fornecedor: json['fornecedor'],
      telefoneFornecedor: json['telefoneFornecedor'],
      ativa: json['ativa'] ?? true,
      totalExecucoes: json['totalExecucoes'] ?? 0,
    );
  }
}

class ManutencacaoExecutadaResponseDto {
  final String historicoId;
  final DateTime proximaManutencao;

  ManutencacaoExecutadaResponseDto({required this.historicoId, required this.proximaManutencao});

  factory ManutencacaoExecutadaResponseDto.fromJson(Map<String, dynamic> json) {
    return ManutencacaoExecutadaResponseDto(
      historicoId: json['historicoId'] ?? '',
      proximaManutencao: parseBackendDateTimeToLocal(json['proximaManutencao']),
    );
  }
}

// ==================== ÁREAS COMUNS ====================

class AreaComumBkendDto {
  final String id;
  final String nome;
  final String? descricao;
  final int capacidade;
  final double valorHora;
  final bool requerAprovacao;
  final bool ativa;
  final String? horarioAbertura;
  final String? horarioFechamento;
  final String? foto;

  AreaComumBkendDto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.capacidade,
    required this.valorHora,
    required this.requerAprovacao,
    required this.ativa,
    this.horarioAbertura,
    this.horarioFechamento,
    this.foto,
  });

  factory AreaComumBkendDto.fromJson(Map<String, dynamic> json) {
    return AreaComumBkendDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      capacidade: json['capacidade'] ?? 0,
      valorHora: (json['valorHora'] ?? 0).toDouble(),
      requerAprovacao: json['requerAprovacao'] ?? false,
      ativa: json['ativa'] ?? true,
      horarioAbertura: json['horarioAbertura'],
      horarioFechamento: json['horarioFechamento'],
      foto: json['foto'],
    );
  }
}

class AreaComumDetalhesBkendDto extends AreaComumBkendDto {
  final String? regras;
  final List<ReservaAreaComumBkendDto>? reservas;

  AreaComumDetalhesBkendDto({
    required super.id,
    required super.nome,
    super.descricao,
    required super.capacidade,
    required super.valorHora,
    required super.requerAprovacao,
    required super.ativa,
    super.horarioAbertura,
    super.horarioFechamento,
    super.foto,
    this.regras,
    this.reservas,
  });

  factory AreaComumDetalhesBkendDto.fromJson(Map<String, dynamic> json) {
    return AreaComumDetalhesBkendDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      capacidade: json['capacidade'] ?? 0,
      valorHora: (json['valorHora'] ?? 0).toDouble(),
      requerAprovacao: json['requerAprovacao'] ?? false,
      ativa: json['ativa'] ?? true,
      horarioAbertura: json['horarioAbertura'],
      horarioFechamento: json['horarioFechamento'],
      foto: json['foto'],
      regras: json['regras'],
      reservas: (json['reservas'] as List<dynamic>?)?.map((item) => ReservaAreaComumBkendDto.fromJson(item)).toList(),
    );
  }
}

// ==================== RESERVAS ÁREA COMUM ====================

class ReservaAreaComumBkendDto {
  final String id;
  final String nomeArea;
  final DateTime dataReserva;
  final String horaInicio;
  final String horaFim;
  final String status;
  final String nomeMorador;
  final String apartamento;
  final double? valorCobrado;
  final DateTime? dataPagamento;
  final int? avaliacaoMorador;
  final String? comentarioAvaliacao;
  final DateTime criadoEm;

  ReservaAreaComumBkendDto({
    required this.id,
    required this.nomeArea,
    required this.dataReserva,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
    required this.nomeMorador,
    required this.apartamento,
    this.valorCobrado,
    this.dataPagamento,
    this.avaliacaoMorador,
    this.comentarioAvaliacao,
    required this.criadoEm,
  });

  factory ReservaAreaComumBkendDto.fromJson(Map<String, dynamic> json) {
    return ReservaAreaComumBkendDto(
      id: json['id'] ?? '',
      nomeArea: json['nomeArea'] ?? '',
      dataReserva: parseBackendDateTimeToLocal(json['dataReserva']),
      horaInicio: json['horaInicio'] ?? '',
      horaFim: json['horaFim'] ?? '',
      status: json['status'] ?? 'Pendente',
      nomeMorador: json['nomeMorador'] ?? '',
      apartamento: json['apartamento'] ?? '',
      valorCobrado: json['valorCobrado']?.toDouble(),
      dataPagamento: tryParseBackendDateTimeToLocal(json['dataPagamento']),
      avaliacaoMorador: json['avaliacaoMorador'],
      comentarioAvaliacao: json['comentarioAvaliacao'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }
}

// ==================== NOTIFICAÇÕES ====================

class NotificacaoBkendDto {
  final String id;
  final String titulo;
  final String mensagem;
  final String tipo;
  final String prioridade;
  final bool lida;
  final String? link;
  final DateTime criadoEm;

  NotificacaoBkendDto({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.prioridade,
    required this.lida,
    this.link,
    required this.criadoEm,
  });

  factory NotificacaoBkendDto.fromJson(Map<String, dynamic> json) {
    return NotificacaoBkendDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      tipo: json['tipo'] ?? 'Sistema',
      prioridade: json['prioridade'] ?? 'Normal',
      lida: json['lida'] ?? false,
      link: json['link'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }
}
