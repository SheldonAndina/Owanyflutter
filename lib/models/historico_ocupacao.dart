import 'package:flutter/material.dart';
import '../utils/app_date_time.dart';

/// Modelos de Histórico de Ocupação do Apartamento
/// Rastreiam entrada/saída de moradores e mudanças de estado
///
/// Estrutura:
/// - HistoricoOcupacaoResumoDto: Visão simplificada (listar) - NOVO
/// - HistoricoOcupacaoDetalhadoDto: Visão completa (detalhe) - NOVO
/// - HistoricoOcupacaoResumo: Legado (compatibilidade)
/// - HistoricoOcupacaoDetalhado: Legado (compatibilidade)

// ========================================
// NOVOS DTOs - Backend Integration Layer
// ========================================

/// Resumo de histórico de ocupação (view simplificada) - DTO Backend
///
/// Uso: Exibir em listas, histórico compacto
///
/// Exemplo JSON:
/// ```json
/// {
///   "id": "h-123",
///   "apartamentoId": "apt-1",
///   "apartamentoNumero": "102",
///   "apartamentoBloco": "A",
///   "moradorId": "m-456",
///   "moradorNome": "João Silva",
///   "tipoMudanca": "Entrada",
///   "dataEfetiva": "2026-01-20T10:30:00Z",
///   "responsavelNome": "Admin System",
///   "observacoes": "Entrada confirmada"
/// }
/// ```
class HistoricoOcupacaoResumoDto {
  final String id;
  final String apartamentoId;
  final String apartamentoNumero;
  final String apartamentoBloco;
  final String moradorId;
  final String moradorNome;
  final String tipoMudanca; // "Entrada" | "Saída" | "Mudança de Quarto" | "Revisão"
  final DateTime dataEfetiva;
  final String? responsavelNome;
  final String? observacoes;

  HistoricoOcupacaoResumoDto({
    required this.id,
    required this.apartamentoId,
    required this.apartamentoNumero,
    required this.apartamentoBloco,
    required this.moradorId,
    required this.moradorNome,
    required this.tipoMudanca,
    required this.dataEfetiva,
    this.responsavelNome,
    this.observacoes,
  });

  factory HistoricoOcupacaoResumoDto.fromJson(Map<String, dynamic> json) {
    return HistoricoOcupacaoResumoDto(
      id: json['id'] as String? ?? '',
      apartamentoId: json['apartamentoId'] as String? ?? '',
      // Support both camelCase and PascalCase from backend
      apartamentoNumero:
          json['apartamentoNumero'] as String? ??
          json['numeroApartamento'] as String? ??
          json['NumeroApartamento'] as String? ??
          '',
      apartamentoBloco:
          json['apartamentoBloco'] as String? ??
          json['blocoApartamento'] as String? ??
          json['BlocoApartamento'] as String? ??
          '',
      moradorId: json['moradorId'] as String? ?? '',
      // Support various naming conventions from backend
      moradorNome:
          json['moradorNome'] as String? ?? json['nomeMorador'] as String? ?? json['NomeMorador'] as String? ?? '',
      // Handle tipoMudanca or tipoMovimentacao
      tipoMudanca:
          json['tipoMudanca'] as String? ??
          json['tipoMovimentacao'] as String? ??
          json['TipoMovimentacao'] as String? ??
          'Entrada',
      // Parse DateTime - support multiple field names and formats
      dataEfetiva: _parseDateTime(
        json['dataEfetiva'] ??
            json['dataMovimentacao'] ??
            json['DataMovimentacao'] ??
            toBackendUtcIsoString(DateTime.now()),
      ),
      responsavelNome:
          json['responsavelNome'] as String? ?? json['nomeExecutor'] as String? ?? json['NomeExecutor'] as String?,
      observacoes: json['observacoes'] as String?,
    );
  }

  /// Helper to safely parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return parseBackendDateTimeToLocal(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartamentoId': apartamentoId,
      'apartamentoNumero': apartamentoNumero,
      'apartamentoBloco': apartamentoBloco,
      'moradorId': moradorId,
      'moradorNome': moradorNome,
      'tipoMudanca': tipoMudanca,
      'dataEfetiva': toBackendUtcIsoString(dataEfetiva),
      'responsavelNome': responsavelNome,
      'observacoes': observacoes,
    };
  }

  @override
  String toString() => 'HistoricoResumoDto(id: $id, morador: $moradorNome, tipo: $tipoMudanca)';
}

/// Histórico detalhado com metadados completos - DTO Backend
///
/// Uso: Tela de detalhes, auditoria, relatórios
class HistoricoOcupacaoDetalhadoDto {
  final String id;
  final String apartamentoId;
  final String apartamentoNumero;
  final String apartamentoBloco;
  final int apartamentoAndar;
  final String? apartamentoEstado;
  final String moradorId;
  final String moradorNome;
  final String? moradorTelefone;
  final String? usuarioId;
  final String? usuarioNome;
  final String? usuarioTipo;
  final String tipoMudanca; // Entrada, Saída, Mudança de Quarto, Revisão
  final DateTime dataEfetiva;
  final DateTime dataRegistro;
  final DateTime? dataTermino;
  final String? motivo;
  final String? observacoes;
  final String? documentoReferencia;
  final String? contatoEmergencia;
  final bool ativo;

  HistoricoOcupacaoDetalhadoDto({
    required this.id,
    required this.apartamentoId,
    required this.apartamentoNumero,
    required this.apartamentoBloco,
    required this.apartamentoAndar,
    this.apartamentoEstado,
    required this.moradorId,
    required this.moradorNome,
    this.moradorTelefone,
    this.usuarioId,
    this.usuarioNome,
    this.usuarioTipo,
    required this.tipoMudanca,
    required this.dataEfetiva,
    required this.dataRegistro,
    this.dataTermino,
    this.motivo,
    this.observacoes,
    this.documentoReferencia,
    this.contatoEmergencia,
    required this.ativo,
  });

  factory HistoricoOcupacaoDetalhadoDto.fromJson(Map<String, dynamic> json) {
    return HistoricoOcupacaoDetalhadoDto(
      id: json['id'] as String? ?? '',
      apartamentoId: json['apartamentoId'] as String? ?? '',
      apartamentoNumero: json['apartamentoNumero'] as String? ?? json['numeroApartamento'] as String? ?? '',
      apartamentoBloco: json['apartamentoBloco'] as String? ?? json['blocoApartamento'] as String? ?? '',
      apartamentoAndar: (json['apartamentoAndar'] as int?) ?? 0,
      apartamentoEstado: json['apartamentoEstado'] as String?,
      moradorId: json['moradorId'] as String? ?? '',
      moradorNome: json['moradorNome'] as String? ?? json['nomeMorador'] as String? ?? '',
      moradorTelefone: json['moradorTelefone'] as String?,
      usuarioId: json['usuarioId'] as String?,
      usuarioNome: json['usuarioNome'] as String?,
      usuarioTipo: json['usuarioTipo'] as String?,
      tipoMudanca: json['tipoMudanca'] as String? ?? json['tipoMovimentacao'] as String? ?? 'Entrada',
      dataEfetiva: HistoricoOcupacaoResumoDto._parseDateTime(json['dataEfetiva'] ?? json['dataMovimentacao']),
      dataRegistro: HistoricoOcupacaoResumoDto._parseDateTime(json['dataRegistro'] ?? json['dataMovimentacao']),
      dataTermino: json['dataTermino'] != null ? HistoricoOcupacaoResumoDto._parseDateTime(json['dataTermino']) : null,
      motivo: json['motivo'] as String?,
      observacoes: json['observacoes'] as String?,
      documentoReferencia: json['documentoReferencia'] as String?,
      contatoEmergencia: json['contatoEmergencia'] as String?,
      ativo: (json['ativo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apartamentoId': apartamentoId,
      'apartamentoNumero': apartamentoNumero,
      'apartamentoBloco': apartamentoBloco,
      'apartamentoAndar': apartamentoAndar,
      'apartamentoEstado': apartamentoEstado,
      'moradorId': moradorId,
      'moradorNome': moradorNome,
      'moradorTelefone': moradorTelefone,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'usuarioTipo': usuarioTipo,
      'tipoMudanca': tipoMudanca,
      'dataEfetiva': toBackendUtcIsoString(dataEfetiva),
      'dataRegistro': toBackendUtcIsoString(dataRegistro),
      'dataTermino': dataTermino != null ? toBackendUtcIsoString(dataTermino!) : null,
      'motivo': motivo,
      'observacoes': observacoes,
      'documentoReferencia': documentoReferencia,
      'contatoEmergencia': contatoEmergencia,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'HistoricoDetalhadoDto(id: $id, morador: $moradorNome, ativo: $ativo)';
}

// ========================================
// MODELOS LEGADOS - Compatibilidade
// ========================================

/// Resumo do Histórico de Ocupação
class HistoricoOcupacaoResumo {
  final String id;
  final String tipoMovimentacao; // "Entrada", "Saida", "Transferencia"
  final DateTime dataMovimentacao;
  final DateTime criadoEm;
  
  // IDs do banco (sempre presentes)
  final String moradorId;
  final String apartamentoId;
  final String? apartamentoOrigemId;
  final String? apartamentoDestinoId;
  final String executadoPorId;
  
  // Nomes resolvidos via JOIN (podem estar vazios se backend não resolver)
  final String nomeMorador;
  final String numeroApartamento;
  final String blocoApartamento;
  final String? numeroApartamentoOrigem;
  final String? blocoApartamentoOrigem;
  final String? numeroApartamentoDestino;
  final String? blocoApartamentoDestino;
  final String nomeExecutor;
  final String? observacoes;

  HistoricoOcupacaoResumo({
    required this.id,
    required this.tipoMovimentacao,
    required this.dataMovimentacao,
    required this.criadoEm,
    required this.moradorId,
    required this.apartamentoId,
    this.apartamentoOrigemId,
    this.apartamentoDestinoId,
    required this.executadoPorId,
    required this.nomeMorador,
    required this.numeroApartamento,
    required this.blocoApartamento,
    this.numeroApartamentoOrigem,
    this.blocoApartamentoOrigem,
    this.numeroApartamentoDestino,
    this.blocoApartamentoDestino,
    required this.nomeExecutor,
    this.observacoes,
  });

  factory HistoricoOcupacaoResumo.fromJson(Map<String, dynamic> json) {
    // Parse nomeMorador with fallbacks for different backend naming conventions
    final nomeMorador = json['nomeMorador'] as String? ??
        json['NomeMorador'] as String? ??
        json['nome_morador'] as String? ??
        json['nomeResidente'] as String? ??
        json['NomeResidente'] as String? ??
        json['residenteNome'] as String? ??
        json['moradorNome'] as String? ??
        json['MoradorNome'] as String? ??
        '';

    // Parse IDs (critical for grouping and actions)
    final moradorId = json['moradorId'] as String? ?? 
        json['MoradorId'] as String? ?? 
        '';
    final apartamentoId = json['apartamentoId'] as String? ?? 
        json['ApartamentoId'] as String? ?? 
        '';
    final executadoPorId = json['executadoPorId'] as String? ?? 
        json['ExecutadoPorId'] as String? ?? 
        '';
    
    // Parse dates
    final dataMovimentacao = tryParseBackendDateTimeToLocal(
        json['dataMovimentacao'] as String? ?? 
        json['DataMovimentacao'] as String? ?? 
        '') ?? DateTime.now();
    final criadoEm = tryParseBackendDateTimeToLocal(
        json['criadoEm'] as String? ?? 
        json['CriadoEm'] as String? ?? 
        '') ?? dataMovimentacao;

    return HistoricoOcupacaoResumo(
      id: json['id'] as String? ?? json['Id'] as String? ?? '',
      tipoMovimentacao: json['tipoMovimentacao'] as String? ?? json['TipoMovimentacao'] as String? ?? 'Entrada',
      dataMovimentacao: dataMovimentacao,
      criadoEm: criadoEm,
      moradorId: moradorId,
      apartamentoId: apartamentoId,
      apartamentoOrigemId: json['apartamentoOrigemId'] as String? ?? json['ApartamentoOrigemId'] as String?,
      apartamentoDestinoId: json['apartamentoDestinoId'] as String? ?? json['ApartamentoDestinoId'] as String?,
      executadoPorId: executadoPorId,
      nomeMorador: nomeMorador,
      numeroApartamento: json['numeroApartamento'] as String? ?? json['NumeroApartamento'] as String? ?? '',
      blocoApartamento: json['blocoApartamento'] as String? ?? json['BlocoApartamento'] as String? ?? '',
      numeroApartamentoOrigem: json['numeroApartamentoOrigem'] as String? ?? json['NumeroApartamentoOrigem'] as String?,
      blocoApartamentoOrigem: json['blocoApartamentoOrigem'] as String? ?? json['BlocoApartamentoOrigem'] as String?,
      numeroApartamentoDestino: json['numeroApartamentoDestino'] as String? ?? json['NumeroApartamentoDestino'] as String?,
      blocoApartamentoDestino: json['blocoApartamentoDestino'] as String? ?? json['BlocoApartamentoDestino'] as String?,
      nomeExecutor: json['nomeExecutor'] as String? ?? json['NomeExecutor'] as String? ?? '',
      observacoes: json['observacoes'] as String? ?? json['Observacoes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipoMovimentacao': tipoMovimentacao,
      'dataMovimentacao': toBackendUtcIsoString(dataMovimentacao),
      'criadoEm': toBackendUtcIsoString(criadoEm),
      'moradorId': moradorId,
      'apartamentoId': apartamentoId,
      'apartamentoOrigemId': apartamentoOrigemId,
      'apartamentoDestinoId': apartamentoDestinoId,
      'executadoPorId': executadoPorId,
      'nomeMorador': nomeMorador,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
      'numeroApartamentoOrigem': numeroApartamentoOrigem,
      'blocoApartamentoOrigem': blocoApartamentoOrigem,
      'numeroApartamentoDestino': numeroApartamentoDestino,
      'blocoApartamentoDestino': blocoApartamentoDestino,
      'nomeExecutor': nomeExecutor,
      'observacoes': observacoes,
    };
  }
  
  /// Cria uma cópia com campos modificados (para resolver nomes client-side)
  HistoricoOcupacaoResumo copyWith({
    String? id,
    String? tipoMovimentacao,
    DateTime? dataMovimentacao,
    DateTime? criadoEm,
    String? moradorId,
    String? apartamentoId,
    String? apartamentoOrigemId,
    String? apartamentoDestinoId,
    String? executadoPorId,
    String? nomeMorador,
    String? numeroApartamento,
    String? blocoApartamento,
    String? numeroApartamentoOrigem,
    String? blocoApartamentoOrigem,
    String? numeroApartamentoDestino,
    String? blocoApartamentoDestino,
    String? nomeExecutor,
    String? observacoes,
  }) {
    return HistoricoOcupacaoResumo(
      id: id ?? this.id,
      tipoMovimentacao: tipoMovimentacao ?? this.tipoMovimentacao,
      dataMovimentacao: dataMovimentacao ?? this.dataMovimentacao,
      criadoEm: criadoEm ?? this.criadoEm,
      moradorId: moradorId ?? this.moradorId,
      apartamentoId: apartamentoId ?? this.apartamentoId,
      apartamentoOrigemId: apartamentoOrigemId ?? this.apartamentoOrigemId,
      apartamentoDestinoId: apartamentoDestinoId ?? this.apartamentoDestinoId,
      executadoPorId: executadoPorId ?? this.executadoPorId,
      nomeMorador: nomeMorador ?? this.nomeMorador,
      numeroApartamento: numeroApartamento ?? this.numeroApartamento,
      blocoApartamento: blocoApartamento ?? this.blocoApartamento,
      numeroApartamentoOrigem: numeroApartamentoOrigem ?? this.numeroApartamentoOrigem,
      blocoApartamentoOrigem: blocoApartamentoOrigem ?? this.blocoApartamentoOrigem,
      numeroApartamentoDestino: numeroApartamentoDestino ?? this.numeroApartamentoDestino,
      blocoApartamentoDestino: blocoApartamentoDestino ?? this.blocoApartamentoDestino,
      nomeExecutor: nomeExecutor ?? this.nomeExecutor,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  // Helpers
  bool get isEntrada => tipoMovimentacao == 'Entrada';
  bool get isSaida => tipoMovimentacao == 'Saida';
  bool get isTransferencia => tipoMovimentacao == 'Transferencia';

  Color get tipoColor {
    switch (tipoMovimentacao) {
      case 'Entrada':
        return const Color(0xFF7BA57E);
      case 'Saida':
        return const Color(0xFFE85D46);
      case 'Transferencia':
        return const Color(0xFF5B9BD5);
      default:
        return const Color(0xFF6B5E54);
    }
  }

  IconData get tipoIcon {
    switch (tipoMovimentacao) {
      case 'Entrada':
        return Icons.login_rounded;
      case 'Saida':
        return Icons.logout_rounded;
      case 'Transferencia':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String get descricao {
    if (isTransferencia && numeroApartamentoOrigem != null && numeroApartamentoDestino != null) {
      return 'Transfer: $numeroApartamentoOrigem/$blocoApartamentoOrigem → $numeroApartamentoDestino/$blocoApartamentoDestino';
    } else if (isEntrada) {
      return 'Entrada em $numeroApartamento/$blocoApartamento';
    } else {
      return 'Saída de $numeroApartamento/$blocoApartamento';
    }
  }
}

/// Histórico de Ocupação Detalhado
/// Campos adicionais específicos para detalhamento que não estão no resumo
class HistoricoOcupacaoDetalhado extends HistoricoOcupacaoResumo {
  final String telefoneMorador;
  final String nomeLoginMorador;

  HistoricoOcupacaoDetalhado({
    required super.id,
    required super.tipoMovimentacao,
    required super.dataMovimentacao,
    required super.criadoEm,
    required super.moradorId,
    required super.apartamentoId,
    super.apartamentoOrigemId,
    super.apartamentoDestinoId,
    required super.executadoPorId,
    required super.nomeMorador,
    required super.numeroApartamento,
    required super.blocoApartamento,
    super.numeroApartamentoOrigem,
    super.blocoApartamentoOrigem,
    super.numeroApartamentoDestino,
    super.blocoApartamentoDestino,
    required super.nomeExecutor,
    super.observacoes,
    required this.telefoneMorador,
    required this.nomeLoginMorador,
  });

  factory HistoricoOcupacaoDetalhado.fromJson(Map<String, dynamic> json) {
    // Parse dates
    final dataMovimentacao = tryParseBackendDateTimeToLocal(
        json['dataMovimentacao'] as String? ?? 
        json['DataMovimentacao'] as String? ?? 
        '') ?? DateTime.now();
    final criadoEm = tryParseBackendDateTimeToLocal(
        json['criadoEm'] as String? ?? 
        json['CriadoEm'] as String? ?? 
        '') ?? dataMovimentacao;

    return HistoricoOcupacaoDetalhado(
      id: json['id'] as String? ?? json['Id'] as String? ?? '',
      tipoMovimentacao: json['tipoMovimentacao'] as String? ?? json['TipoMovimentacao'] as String? ?? 'Entrada',
      dataMovimentacao: dataMovimentacao,
      criadoEm: criadoEm,
      apartamentoId: json['apartamentoId'] as String? ?? json['ApartamentoId'] as String? ?? '',
      moradorId: json['moradorId'] as String? ?? json['MoradorId'] as String? ?? '',
      nomeMorador: json['nomeMorador'] as String? ?? json['NomeMorador'] as String? ?? '',
      telefoneMorador: json['telefoneMorador'] as String? ?? json['TelefoneMorador'] as String? ?? '',
      nomeLoginMorador: json['nomeLoginMorador'] as String? ?? json['NomeLoginMorador'] as String? ?? '',
      numeroApartamento: json['numeroApartamento'] as String? ?? json['NumeroApartamento'] as String? ?? '',
      blocoApartamento: json['blocoApartamento'] as String? ?? json['BlocoApartamento'] as String? ?? '',
      apartamentoOrigemId: json['apartamentoOrigemId'] as String? ?? json['ApartamentoOrigemId'] as String?,
      numeroApartamentoOrigem: json['numeroApartamentoOrigem'] as String? ?? json['NumeroApartamentoOrigem'] as String?,
      blocoApartamentoOrigem: json['blocoApartamentoOrigem'] as String? ?? json['BlocoApartamentoOrigem'] as String?,
      apartamentoDestinoId: json['apartamentoDestinoId'] as String? ?? json['ApartamentoDestinoId'] as String?,
      numeroApartamentoDestino: json['numeroApartamentoDestino'] as String? ?? json['NumeroApartamentoDestino'] as String?,
      blocoApartamentoDestino: json['blocoApartamentoDestino'] as String? ?? json['BlocoApartamentoDestino'] as String?,
      executadoPorId: json['executadoPorId'] as String? ?? json['ExecutadoPorId'] as String? ?? '',
      nomeExecutor: json['nomeExecutor'] as String? ?? json['NomeExecutor'] as String? ?? '',
      observacoes: json['observacoes'] as String? ?? json['Observacoes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'telefoneMorador': telefoneMorador,
      'nomeLoginMorador': nomeLoginMorador,
    };
  }
}

// ========================================
// EXTENSÕES E HELPERS
// ========================================

/// Extensão para tipos de mudança - UI helpers
extension TipoMudancaHelper on String {
  /// Retorna ícone apropriado para o tipo de mudança
  IconData get icone {
    switch (this) {
      case 'Entrada':
        return Icons.login_rounded;
      case 'Saída':
        return Icons.logout_rounded;
      case 'Mudança de Quarto':
        return Icons.swap_horiz_rounded;
      case 'Revisão':
        return Icons.fact_check_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  /// Retorna cor temática para o tipo de mudança
  Color get color {
    switch (this) {
      case 'Entrada':
        return const Color(0xFF7BA57E); // Verde (success)
      case 'Saída':
        return const Color(0xFFE85D46); // Vermelho (error)
      case 'Mudança de Quarto':
        return const Color(0xFF5B9BD5); // Azul (info)
      case 'Revisão':
        return const Color(0xFFD9A85C); // Amarelo (warning)
      default:
        return const Color(0xFF6B5E54); // Cinza (textSecondary)
    }
  }

  /// Retorna descrição textual em português
  String get descricao {
    switch (this) {
      case 'Entrada':
        return 'Entrada no apartamento';
      case 'Saída':
        return 'Saída do apartamento';
      case 'Mudança de Quarto':
        return 'Mudança de quarto/apartamento';
      case 'Revisão':
        return 'Revisão de ocupação';
      default:
        return this;
    }
  }

  /// Verifica se é tipo de entrada
  bool get isEntrada => this == 'Entrada';

  /// Verifica se é tipo de saída
  bool get isSaida => this == 'Saída';

  /// Verifica se é tipo de mudança
  bool get isMudanca => this == 'Mudança de Quarto';
}

/// Filtros para histórico - Query Builder
class HistoricoFiltro {
  final String? apartamentoId;
  final String? moradorId;
  final String? tipoMudanca;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool? ativo;
  final int pageNumber;
  final int pageSize;

  HistoricoFiltro({
    this.apartamentoId,
    this.moradorId,
    this.tipoMudanca,
    this.dataInicio,
    this.dataFim,
    this.ativo,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  /// Converte para parâmetros de query para API
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'pageNumber': pageNumber, 'pageSize': pageSize};
    if (apartamentoId != null) params['apartamentoId'] = apartamentoId;
    if (moradorId != null) params['moradorId'] = moradorId;
    if (tipoMudanca != null) params['tipoMudanca'] = tipoMudanca;
    if (dataInicio != null) params['dataInicio'] = toBackendUtcIsoString(dataInicio!);
    if (dataFim != null) params['dataFim'] = toBackendUtcIsoString(dataFim!);
    if (ativo != null) params['ativo'] = ativo;
    return params;
  }

  /// Cria nova instância com parâmetros atualizados
  HistoricoFiltro copyWith({
    String? apartamentoId,
    String? moradorId,
    String? tipoMudanca,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativo,
    int? pageNumber,
    int? pageSize,
  }) {
    return HistoricoFiltro(
      apartamentoId: apartamentoId ?? this.apartamentoId,
      moradorId: moradorId ?? this.moradorId,
      tipoMudanca: tipoMudanca ?? this.tipoMudanca,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      ativo: ativo ?? this.ativo,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() =>
      'HistoricoFiltro(apt: $apartamentoId, morador: $moradorId, tipo: $tipoMudanca, page: $pageNumber/$pageSize)';
}

/// Resposta paginada para histórico
///
/// Padrão de paginação Owany
///
/// Exemplo JSON:
/// ```json
/// {
///   "items": [...],
///   "totalItems": 150,
///   "pageNumber": 1,
///   "pageSize": 20,
///   "totalPages": 8
/// }
/// ```
class PaginatedHistoricoResponse<T> {
  final List<T> items;
  final int totalItems;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  PaginatedHistoricoResponse({
    required this.items,
    required this.totalItems,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedHistoricoResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final itemsList =
        (json['items'] as List?)?.map((item) {
          // Handle both Map and already-parsed objects
          if (item is Map<String, dynamic>) {
            return item;
          }
          return item as Map<String, dynamic>;
        }).toList() ??
        [];

    return PaginatedHistoricoResponse(
      items: itemsList.map(fromJsonT).toList(),
      // Support both "total" (from backend) and "totalItems" (legacy)
      totalItems: json['totalItems'] ?? json['total'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'items': items.map(toJsonT).toList(),
      'totalItems': totalItems,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalPages': totalPages,
    };
  }

  /// Verifica se há próxima página
  bool get hasNextPage => pageNumber < totalPages;

  /// Verifica se há página anterior
  bool get hasPreviousPage => pageNumber > 1;

  /// Retorna número de página anterior
  int get previousPageNumber => hasPreviousPage ? pageNumber - 1 : pageNumber;

  /// Retorna número de página próxima
  int get nextPageNumber => hasNextPage ? pageNumber + 1 : pageNumber;

  @override
  String toString() => 'PaginatedResponse(items: ${items.length}, total: $totalItems, page: $pageNumber/$totalPages)';
}
