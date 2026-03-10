/// =====================================================================
/// ITEM APARTAMENTO DTOs COMPLETOS
/// DTOs para gestão completa de itens patrimoniais
/// Baseado na especificação do backend .NET 8
/// =====================================================================
library;

import 'package:flutter/material.dart';
import 'item_estado_enums.dart';
import 'item_apartamento_movimentacao_dtos.dart';

/// Item patrimonial completo (para detalhes)
import '../utils/app_date_time.dart';

class ItemApartamentoDto {
  final String id;
  final String codigoPatrimonio;
  final String nome;
  final String? descricao;
  final String? tipo;
  final String estadoFisico;         // "Disponivel", "Danificado", etc.
  final String statusOperacional;    // "EmStock", "EmUso", etc.
  final int quantidade;
  final double? valorEstimado;
  final DateTime? dataAquisicao;
  final DateTime? dataEntrada;       // Data de entrada no condomínio
  final DateTime criadoEm;
  final String? observacoes;
  final String? apartamentoAlocadoId;
  final String? apartamentoAlocadoNumero;
  final String? apartamentoAlocadoBloco;
  final bool possuiManutencaoAtiva;

  ItemApartamentoDto({
    required this.id,
    required this.codigoPatrimonio,
    required this.nome,
    this.descricao,
    this.tipo,
    required this.estadoFisico,
    required this.statusOperacional,
    this.quantidade = 1,
    this.valorEstimado,
    this.dataAquisicao,
    this.dataEntrada,
    required this.criadoEm,
    this.observacoes,
    this.apartamentoAlocadoId,
    this.apartamentoAlocadoNumero,
    this.apartamentoAlocadoBloco,
    this.possuiManutencaoAtiva = false,
  });

  factory ItemApartamentoDto.fromJson(Map<String, dynamic> json) => ItemApartamentoDto(
    id: json['id']?.toString() ?? '',
    codigoPatrimonio: json['codigoPatrimonio']?.toString() ?? '',
    nome: json['nome']?.toString() ?? '',
    descricao: json['descricao']?.toString(),
    tipo: json['tipo']?.toString(),
    estadoFisico: json['estadoFisico']?.toString() ?? 'Disponivel',
    statusOperacional: json['statusOperacional']?.toString() ?? 'EmStock',
    quantidade: json['quantidade'] as int? ?? 1,
    valorEstimado: (json['valorEstimado'] as num?)?.toDouble(),
    dataAquisicao: json['dataAquisicao'] != null 
        ? tryParseBackendDateTimeToLocal(json['dataAquisicao'].toString()) 
        : null,
    dataEntrada: json['dataEntrada'] != null 
        ? tryParseBackendDateTimeToLocal(json['dataEntrada'].toString()) 
        : null,
    criadoEm: json['criadoEm'] != null 
        ? parseBackendDateTimeToLocal(json['criadoEm'].toString()) 
        : DateTime.now(),
    observacoes: json['observacoes']?.toString(),
    apartamentoAlocadoId: json['apartamentoAlocadoId']?.toString(),
    apartamentoAlocadoNumero: json['apartamentoAlocadoNumero']?.toString(),
    apartamentoAlocadoBloco: json['apartamentoAlocadoBloco']?.toString(),
    possuiManutencaoAtiva: json['possuiManutencaoAtiva'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigoPatrimonio': codigoPatrimonio,
    'nome': nome,
    'descricao': descricao,
    'tipo': tipo,
    'estadoFisico': estadoFisico,
    'statusOperacional': statusOperacional,
    'quantidade': quantidade,
    'valorEstimado': valorEstimado,
    'dataAquisicao': dataAquisicao != null ? toBackendUtcIsoString(dataAquisicao!) : null,
    'dataEntrada': dataEntrada != null ? toBackendUtcIsoString(dataEntrada!) : null,
    'criadoEm': toBackendUtcIsoString(criadoEm),
    'observacoes': observacoes,
    'apartamentoAlocadoId': apartamentoAlocadoId,
    'apartamentoAlocadoNumero': apartamentoAlocadoNumero,
    'apartamentoAlocadoBloco': apartamentoAlocadoBloco,
    'possuiManutencaoAtiva': possuiManutencaoAtiva,
  };

  /// Localização formatada
  String get localizacaoFormatada {
    if (apartamentoAlocadoId == null || apartamentoAlocadoId!.isEmpty) {
      return 'Em Stock';
    }
    final bloco = apartamentoAlocadoBloco?.isNotEmpty == true 
        ? ' - Bloco $apartamentoAlocadoBloco' 
        : '';
    return 'Apt $apartamentoAlocadoNumero$bloco';
  }

  /// Verifica se item está em stock
  bool get emStock => apartamentoAlocadoId == null || apartamentoAlocadoId!.isEmpty;

  /// Estado físico como enum
  EstadoFisicoItem get estadoFisicoEnum => EstadoFisicoItemExtension.fromString(estadoFisico);
  
  /// Status operacional como enum
  StatusOperacionalItem get statusOperacionalEnum => StatusOperacionalItemExtension.fromString(statusOperacional);
}

/// Resultado de busca de itens (projeção otimizada)
class ItemSearchResultDto {
  final String id;
  final String nome;
  final String codigoPatrimonio;
  final String tipo;
  final String estadoFisico;
  final String statusOperacional;
  final DateTime? dataAquisicao;
  final String? apartamentoAlocadoId;
  final String? apartamentoInfo;     // "Bloco A - Apt 101"
  final bool possuiManutencaoAtiva;

  ItemSearchResultDto({
    required this.id,
    required this.nome,
    required this.codigoPatrimonio,
    required this.tipo,
    required this.estadoFisico,
    required this.statusOperacional,
    this.dataAquisicao,
    this.apartamentoAlocadoId,
    this.apartamentoInfo,
    required this.possuiManutencaoAtiva,
  });

  factory ItemSearchResultDto.fromJson(Map<String, dynamic> json) => ItemSearchResultDto(
    id: json['id']?.toString() ?? '',
    nome: json['nome']?.toString() ?? '',
    codigoPatrimonio: json['codigoPatrimonio']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? 'Outros',
    estadoFisico: json['estadoFisico']?.toString() ?? 'Disponivel',
    statusOperacional: json['statusOperacional']?.toString() ?? 'EmStock',
    dataAquisicao: json['dataAquisicao'] != null 
        ? tryParseBackendDateTimeToLocal(json['dataAquisicao'].toString()) 
        : null,
    apartamentoAlocadoId: json['apartamentoAlocadoId']?.toString(),
    apartamentoInfo: json['apartamentoInfo']?.toString(),
    possuiManutencaoAtiva: json['possuiManutencaoAtiva'] as bool? ?? false,
  );

  /// Localização formatada
  String get localizacaoFormatada => apartamentoInfo ?? 'Em Stock';

  /// Estado físico como enum
  EstadoFisicoItem get estadoFisicoEnum => EstadoFisicoItemExtension.fromString(estadoFisico);
  
  /// Status operacional como enum
  StatusOperacionalItem get statusOperacionalEnum => StatusOperacionalItemExtension.fromString(statusOperacional);
}

/// Alocação de item a apartamento
class AlocacaoItemDto {
  final String id;
  final String itemId;
  final String itemNome;
  final String codigoPatrimonio;
  final String apartamentoId;
  final String apartamentoNumero;
  final String apartamentoBloco;
  final DateTime? dataAlocacao;
  final DateTime? dataFim;
  final String? usuarioNome;
  final String? motivo;
  final String? observacoes;

  AlocacaoItemDto({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.codigoPatrimonio,
    required this.apartamentoId,
    required this.apartamentoNumero,
    required this.apartamentoBloco,
    this.dataAlocacao,
    this.dataFim,
    this.usuarioNome,
    this.motivo,
    this.observacoes,
  });

  factory AlocacaoItemDto.fromJson(Map<String, dynamic> json) => AlocacaoItemDto(
    id: json['id']?.toString() ?? '',
    itemId: json['itemId']?.toString() ?? '',
    itemNome: json['itemNome']?.toString() ?? '',
    codigoPatrimonio: json['codigoPatrimonio']?.toString() ?? '',
    apartamentoId: json['apartamentoId']?.toString() ?? '',
    apartamentoNumero: json['apartamentoNumero']?.toString() ?? '',
    apartamentoBloco: json['apartamentoBloco']?.toString() ?? '',
    dataAlocacao: json['dataAlocacao'] != null 
        ? tryParseBackendDateTimeToLocal(json['dataAlocacao'].toString())
        : json['dataInicio'] != null 
            ? tryParseBackendDateTimeToLocal(json['dataInicio'].toString())
            : null,
    dataFim: json['dataFim'] != null 
        ? tryParseBackendDateTimeToLocal(json['dataFim'].toString()) 
        : null,
    usuarioNome: json['usuarioNome']?.toString() ?? json['alocadoPorNome']?.toString(),
    motivo: json['motivo']?.toString(),
    observacoes: json['observacoes']?.toString(),
  );

  /// Verifica se a alocação está ativa
  bool get ativa => dataFim == null;

  /// Localização formatada
  String get localizacaoFormatada => 'Apt $apartamentoNumero - Bloco $apartamentoBloco';
}

/// Mudança de estado do item
class MudancaEstadoItemDto {
  final String id;
  final String? estadoAnterior;
  final String? novoEstado;
  final String estadoNovo; // Alias para novoEstado
  final DateTime? dataMudanca;
  final String? usuarioNome;
  final String? motivo;

  MudancaEstadoItemDto({
    required this.id,
    this.estadoAnterior,
    this.novoEstado,
    this.dataMudanca,
    this.usuarioNome,
    this.motivo,
  }) : estadoNovo = novoEstado ?? '';

  factory MudancaEstadoItemDto.fromJson(Map<String, dynamic> json) {
    final novoEstado = json['novoEstado']?.toString() ?? json['estadoNovo']?.toString() ?? '';
    return MudancaEstadoItemDto(
      id: json['id']?.toString() ?? '',
      estadoAnterior: json['estadoAnterior']?.toString(),
      novoEstado: novoEstado,
      dataMudanca: json['dataMudanca'] != null 
          ? tryParseBackendDateTimeToLocal(json['dataMudanca'].toString())
          : json['data'] != null 
              ? tryParseBackendDateTimeToLocal(json['data'].toString())
              : null,
      usuarioNome: json['usuarioNome']?.toString(),
      motivo: json['motivo']?.toString(),
    );
  }

  /// Estado anterior como enum
  EstadoFisicoItem get estadoAnteriorEnum => EstadoFisicoItemExtension.fromString(estadoAnterior ?? '');
  
  /// Estado novo como enum
  EstadoFisicoItem get estadoNovoEnum => EstadoFisicoItemExtension.fromString(novoEstado ?? '');
}

/// Histórico completo do item
class HistoricoItemDto {
  final List<AlocacaoItemDto> alocacoes;
  final List<MudancaEstadoItemDto> mudancasEstado;
  final List<SolicitacaoResumoItemDto> solicitacoes;

  HistoricoItemDto({
    required this.alocacoes,
    required this.mudancasEstado,
    this.solicitacoes = const [],
  });

  factory HistoricoItemDto.fromJson(Map<String, dynamic> json) => HistoricoItemDto(
    alocacoes: (json['alocacoes'] as List<dynamic>?)
        ?.map((e) => AlocacaoItemDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    mudancasEstado: (json['mudancasEstado'] as List<dynamic>?)
        ?.map((e) => MudancaEstadoItemDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    solicitacoes: (json['solicitacoes'] as List<dynamic>?)
        ?.map((e) => SolicitacaoResumoItemDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  /// Total de movimentações
  int get totalMovimentacoes => alocacoes.length + mudancasEstado.length;
  
  /// Total de solicitações vinculadas
  int get totalSolicitacoes => solicitacoes.length;
}

/// Estatísticas de ativos (dashboard)
class AtivosEstatisticas {
  final int total;
  final int disponiveis;
  final int emManutencao;
  final int danificados;
  final int emUso;
  final int emStock;
  final int inutilizados;
  final int extraviados;

  AtivosEstatisticas({
    required this.total,
    required this.disponiveis,
    required this.emManutencao,
    required this.danificados,
    required this.emUso,
    required this.emStock,
    required this.inutilizados,
    required this.extraviados,
  });

  factory AtivosEstatisticas.fromJson(Map<String, dynamic> json) => AtivosEstatisticas(
    total: json['total'] ?? 0,
    disponiveis: json['disponiveis'] ?? 0,
    emManutencao: json['emManutencao'] ?? 0,
    danificados: json['danificados'] ?? 0,
    emUso: json['emUso'] ?? 0,
    emStock: json['emStock'] ?? 0,
    inutilizados: json['inutilizados'] ?? 0,
    extraviados: json['extraviados'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'disponiveis': disponiveis,
    'emManutencao': emManutencao,
    'danificados': danificados,
    'emUso': emUso,
    'emStock': emStock,
    'inutilizados': inutilizados,
    'extraviados': extraviados,
  };
}

// ==========================================
// REQUEST DTOs
// ==========================================

/// Request para criar item
class CriarItemRequest {
  final String nome;
  final String? descricao;
  final String tipo;
  final DateTime? dataAquisicao;

  CriarItemRequest({
    required this.nome,
    this.descricao,
    required this.tipo,
    this.dataAquisicao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
    'tipo': tipo,
    if (dataAquisicao != null) 'dataAquisicao': toBackendUtcIsoString(dataAquisicao!),
  };
}

/// Request para alocar item a apartamento
class AlocarItemRequest {
  final String apartamentoId;

  AlocarItemRequest({required this.apartamentoId});

  Map<String, dynamic> toJson() => {'apartamentoId': apartamentoId};
}

/// Request para alterar estado físico do item
class AlterarEstadoRequest {
  final int novoEstado;

  AlterarEstadoRequest({required this.novoEstado});

  Map<String, dynamic> toJson() => {'novoEstado': novoEstado};
}

/// Request para atualizar item existente
class AtualizarItemRequest {
  final String nome;
  final String? descricao;
  final String? tipo;
  final int? quantidade;
  final double? valorEstimado;
  final int? estadoFisico;
  final int? statusOperacional;
  final DateTime? dataAquisicao;
  final DateTime? dataEntrada;
  final String? observacoes;

  AtualizarItemRequest({
    required this.nome,
    this.descricao,
    this.tipo,
    this.quantidade,
    this.valorEstimado,
    this.estadoFisico,
    this.statusOperacional,
    this.dataAquisicao,
    this.dataEntrada,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'nome': nome};
    if (descricao != null) json['descricao'] = descricao;
    if (tipo != null) json['tipo'] = tipo;
    if (quantidade != null) json['quantidade'] = quantidade;
    if (valorEstimado != null) json['valorEstimado'] = valorEstimado;
    if (estadoFisico != null) json['estadoFisico'] = estadoFisico;
    if (statusOperacional != null) json['statusOperacional'] = statusOperacional;
    if (dataAquisicao != null) json['dataAquisicao'] = toBackendUtcIsoString(dataAquisicao!);
    if (dataEntrada != null) json['dataEntrada'] = toBackendUtcIsoString(dataEntrada!);
    if (observacoes != null) json['observacoes'] = observacoes;
    return json;
  }
}

// ==========================================
// HELPERS DE COR E ÍCONE
// ==========================================

/// Obtém cor para estado físico
Color getCorEstadoFisico(String estado) {
  switch (estado.toLowerCase()) {
    case 'disponivel':
      return Colors.green;
    case 'danificado':
      return Colors.orange;
    case 'emmanutencao':
    case 'em manutencao':
    case 'em_manutencao':
      return Colors.blue;
    case 'inutilizado':
      return Colors.grey;
    case 'extraviado':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Obtém cor para status operacional
Color getCorStatusOperacional(String status) {
  switch (status.toLowerCase()) {
    case 'emstock':
    case 'em_stock':
      return Colors.teal;
    case 'emuso':
    case 'em_uso':
      return Colors.green;
    case 'danificado':
      return Colors.orange;
    case 'emmanutencao':
    case 'em_manutencao':
      return Colors.blue;
    case 'inutilizado':
      return Colors.grey;
    case 'extraviado':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Obtém ícone para tipo de item
IconData getIconeTipoItem(String? tipo) {
  switch (tipo?.toLowerCase()) {
    case 'mobiliario':
    case 'mobiliário':
      return Icons.chair;
    case 'eletrodomestico':
    case 'eletrodoméstico':
      return Icons.kitchen;
    case 'climatizacao':
    case 'climatização':
      return Icons.ac_unit;
    case 'eletronico':
    case 'eletrônico':
      return Icons.devices;
    case 'iluminacao':
    case 'iluminação':
      return Icons.lightbulb;
    case 'hidraulica':
    case 'hidráulica':
      return Icons.plumbing;
    case 'eletrica':
    case 'elétrica':
      return Icons.electrical_services;
    default:
      return Icons.inventory_2;
  }
}
