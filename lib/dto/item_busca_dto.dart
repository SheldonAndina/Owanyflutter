/// =====================================================================
/// ITEM BUSCA DTOs
/// DTOs otimizados para busca e listagem paginada de itens/ativos
/// Projeção mínima para reduzir payload e melhorar performance
/// =====================================================================
library;

import '../models/item_estado.dart';

/// DTO otimizado para listagem de itens (projeção mínima)
/// Usado em buscas paginadas para reduzir payload
import '../utils/app_date_time.dart';

class ItemBuscaDto {
  final String id;
  final String nome;
  final String? codigoPatrimonio;
  final String? tipo;
  final int? quantidade;
  final String? apartamentoId;
  final String? apartamentoNumero;
  final String? apartamentoBloco;
  final String estadoEfetivo; // Calculado no backend: considera solicitações ativas
  final bool possuiManutencaoAtiva;
  final DateTime? dataAquisicao;

  ItemBuscaDto({
    required this.id,
    required this.nome,
    this.codigoPatrimonio,
    this.tipo,
    this.quantidade,
    this.apartamentoId,
    this.apartamentoNumero,
    this.apartamentoBloco,
    required this.estadoEfetivo,
    this.possuiManutencaoAtiva = false,
    this.dataAquisicao,
  });

  factory ItemBuscaDto.fromJson(Map<String, dynamic> json) {
    return ItemBuscaDto(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      codigoPatrimonio: json['codigoPatrimonio']?.toString(),
      tipo: json['tipo']?.toString(),
      quantidade: json['quantidade'] is num ? (json['quantidade'] as num).toInt() : null,
      apartamentoId: json['apartamentoId']?.toString(),
      apartamentoNumero: json['apartamentoNumero']?.toString() ?? json['numeroApartamento']?.toString(),
      apartamentoBloco: json['apartamentoBloco']?.toString() ?? json['blocoApartamento']?.toString(),
      estadoEfetivo: json['estadoEfetivo']?.toString() ?? json['estadoAtual']?.toString() ?? 'Disponivel',
      possuiManutencaoAtiva: json['possuiManutencaoAtiva'] as bool? ?? 
          json['temManutencaoAtiva'] as bool? ?? false,
      dataAquisicao: json['dataAquisicao'] != null 
          ? tryParseBackendDateTimeToLocal(json['dataAquisicao'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'codigoPatrimonio': codigoPatrimonio,
    'tipo': tipo,
    'quantidade': quantidade,
    'apartamentoId': apartamentoId,
    'apartamentoNumero': apartamentoNumero,
    'apartamentoBloco': apartamentoBloco,
    'estadoEfetivo': estadoEfetivo,
    'possuiManutencaoAtiva': possuiManutencaoAtiva,
    'dataAquisicao': dataAquisicao != null ? toBackendUtcIsoString(dataAquisicao!) : null,
  };

  /// Estado efetivo parseado como enum
  ItemEstado get estadoEnum => estadoFromString(estadoEfetivo);

  /// Localização formatada
  String get localizacaoFormatada {
    if (apartamentoNumero == null || apartamentoNumero!.isEmpty) {
      return 'Em Stock';
    }
    return apartamentoBloco?.isNotEmpty == true 
        ? 'Apt $apartamentoNumero - Bloco $apartamentoBloco'
        : 'Apt $apartamentoNumero';
  }

  /// Verifica se item está em stock
  bool get emStock => apartamentoId == null || apartamentoId!.isEmpty;

  @override
  String toString() => 'ItemBuscaDto(id: $id, nome: $nome, estado: $estadoEfetivo)';
}

/// Parâmetros de busca para endpoint de itens
class ItemBuscaParams {
  final String? query;
  final String? estado;
  final String? tipo;
  final String? apartamentoId;
  final bool? somenteStock;
  final int page;
  final int pageSize;
  final String? ordenarPor;
  final bool descendente;

  const ItemBuscaParams({
    this.query,
    this.estado,
    this.tipo,
    this.apartamentoId,
    this.somenteStock,
    this.page = 1,
    this.pageSize = 20,
    this.ordenarPor,
    this.descendente = false,
  });

  /// Converte para query string
  String toQueryString() {
    final params = <String, String>{};
    
    if (query != null && query!.isNotEmpty) {
      params['q'] = query!;
    }
    if (estado != null && estado!.isNotEmpty) {
      params['estado'] = estado!;
    }
    if (tipo != null && tipo!.isNotEmpty) {
      params['tipo'] = tipo!;
    }
    if (apartamentoId != null && apartamentoId!.isNotEmpty) {
      params['apartamentoId'] = apartamentoId!;
    }
    if (somenteStock == true) {
      params['somenteStock'] = 'true';
    }
    params['page'] = page.toString();
    params['pageSize'] = pageSize.toString();
    
    if (ordenarPor != null && ordenarPor!.isNotEmpty) {
      params['ordenarPor'] = ordenarPor!;
      if (descendente) {
        params['desc'] = 'true';
      }
    }

    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
  }

  ItemBuscaParams copyWith({
    String? query,
    String? estado,
    String? tipo,
    String? apartamentoId,
    bool? somenteStock,
    int? page,
    int? pageSize,
    String? ordenarPor,
    bool? descendente,
  }) {
    return ItemBuscaParams(
      query: query ?? this.query,
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      apartamentoId: apartamentoId ?? this.apartamentoId,
      somenteStock: somenteStock ?? this.somenteStock,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      ordenarPor: ordenarPor ?? this.ordenarPor,
      descendente: descendente ?? this.descendente,
    );
  }
}

/// Resultado paginado de busca de itens
class ItemBuscaResult {
  final List<ItemBuscaDto> items;
  final int total;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  ItemBuscaResult({
    required this.items,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ItemBuscaResult.fromJson(Map<String, dynamic> json) {
    // Tenta encontrar a lista de items em vários formatos possíveis do backend
    // Backend C# com System.Text.Json usa camelCase por padrão (Items → items)
    List<dynamic>? rawItems;
    final candidates = ['items', 'Items', 'itens', 'data', 'dados', 'results', 'registros'];
    
    for (final key in candidates) {
      if (json[key] is List) {
        rawItems = json[key] as List;
        break;
      }
    }

    // Se não encontrar em formato paginado, pode ser lista direta
    if (rawItems == null && json is List) {
      rawItems = json as List<dynamic>;
    }

    final items = (rawItems ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => ItemBuscaDto.fromJson(e))
        .toList();

    // Suporta variações de nomes do backend (camelCase e PascalCase)
    final total = json['total'] as int? 
        ?? json['totalCount'] as int? 
        ?? json['TotalCount'] as int? 
        ?? items.length;
    final pageNumber = json['pageNumber'] as int? 
        ?? json['page'] as int? 
        ?? json['Page'] as int? 
        ?? 1;
    final pageSize = json['pageSize'] as int? 
        ?? json['PageSize'] as int? 
        ?? json['size'] as int? 
        ?? 20;
    final totalPages = json['totalPages'] as int? 
        ?? json['TotalPages'] as int?
        ?? ((total / pageSize).ceil().clamp(1, 999999));

    return ItemBuscaResult(
      items: items,
      total: total,
      pageNumber: pageNumber,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNextPage: json['hasNextPage'] as bool? ?? json['HasNextPage'] as bool? ?? (pageNumber < totalPages),
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? json['HasPreviousPage'] as bool? ?? (pageNumber > 1),
    );
  }

  /// Resultado vazio
  factory ItemBuscaResult.empty() {
    return ItemBuscaResult(
      items: [],
      total: 0,
      pageNumber: 1,
      pageSize: 20,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() => 'ItemBuscaResult(total: $total, page: $pageNumber/$totalPages, items: ${items.length})';
}
