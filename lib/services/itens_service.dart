import 'dart:typed_data';
import '../dto/item_apartamento_dto.dart';
import '../dto/item_estado_enums.dart';
import 'api_service.dart';

/// Serviço de gestão de itens patrimoniais
/// Consome /api/itens do backend
class ItensService {
  final ApiService _api = ApiService();

  // ==========================================
  // CRUD BÁSICO
  // ==========================================

  /// Cria novo item patrimonial
  /// POST /api/itens
  Future<ItemApartamentoDto> criarItem(CriarItemRequest request) async {
    return _api.request<ItemApartamentoDto>(
      'itens',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => ItemApartamentoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lista itens com paginação e filtros
  /// GET /api/itens?estado=0&tipo=Mobiliario&q=cadeira&page=1&pageSize=20
  Future<PagedResultItens> listarItens({
    int? estado,
    int? statusOperacional,
    String? tipo,
    String? apartamentoId,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    
    if (estado != null) params['estado'] = estado.toString();
    if (statusOperacional != null) params['statusOperacional'] = statusOperacional.toString();
    if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
    if (apartamentoId != null && apartamentoId.isNotEmpty) params['apartamentoId'] = apartamentoId;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    return _api.request<PagedResultItens>(
      'itens?$queryString',
      method: 'GET',
      fromJson: (json) => PagedResultItens.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Obtém item por ID
  /// GET /api/itens/{id}
  Future<ItemApartamentoDto> obterPorId(String id) async {
    return _api.request<ItemApartamentoDto>(
      'itens/$id',
      method: 'GET',
      fromJson: (json) => ItemApartamentoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Obtém item por código de patrimônio (ideal para scan QR)
  /// GET /api/itens/patrimonio/{codigo}
  Future<ItemApartamentoDto> obterPorCodigo(String codigo) async {
    final codigoEncoded = Uri.encodeComponent(codigo.trim());
    return _api.request<ItemApartamentoDto>(
      'itens/patrimonio/$codigoEncoded',
      method: 'GET',
      fromJson: (json) => ItemApartamentoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Atualiza item existente
  /// PUT /api/itens/{id}
  Future<ItemApartamentoDto> atualizarItem(String id, AtualizarItemRequest request) async {
    return _api.request<ItemApartamentoDto>(
      'itens/$id',
      method: 'PUT',
      body: request.toJson(),
      fromJson: (json) => ItemApartamentoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Exclui item
  /// DELETE /api/itens/{id}
  Future<void> excluirItem(String id) async {
    await _api.request<void>(
      'itens/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  // ==========================================
  // LISTAGENS ESPECÍFICAS
  // ==========================================

  /// Lista itens disponíveis (não alocados, estado OK)
  /// GET /api/itens/disponiveis
  Future<List<ItemSearchResultDto>> listarDisponiveis() async {
    return _api.request<List<ItemSearchResultDto>>(
      'itens/disponiveis',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  /// Lista itens de um apartamento
  /// GET /api/itens/apartamento/{aptId}
  Future<List<ItemSearchResultDto>> listarPorApartamento(String apartamentoId) async {
    return _api.request<List<ItemSearchResultDto>>(
      'itens/apartamento/$apartamentoId',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  /// Lista itens em manutenção
  /// GET /api/itens/em-manutencao
  Future<List<ItemSearchResultDto>> listarEmManutencao() async {
    return _api.request<List<ItemSearchResultDto>>(
      'itens/em-manutencao',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  /// Lista itens nunca alocados
  /// GET /api/itens/nunca-alocados
  Future<List<ItemSearchResultDto>> listarNuncaAlocados() async {
    return _api.request<List<ItemSearchResultDto>>(
      'itens/nunca-alocados',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  // ==========================================
  // ESTATÍSTICAS
  // ==========================================

  /// Obtém estatísticas de itens
  /// GET /api/itens/estatisticas
  Future<AtivosEstatisticas> obterEstatisticas() async {
    return _api.request<AtivosEstatisticas>(
      'itens/estatisticas',
      method: 'GET',
      fromJson: (json) => AtivosEstatisticas.fromJson(json as Map<String, dynamic>),
    );
  }

  // ==========================================
  // ALOCAÇÃO
  // ==========================================

  /// Aloca item a um apartamento
  /// POST /api/itens/{id}/alocar
  Future<void> alocarItem(String itemId, String apartamentoId) async {
    await _api.request<void>(
      'itens/$itemId/alocar',
      method: 'POST',
      body: {'apartamentoId': apartamentoId},
      fromJson: (_) {},
    );
  }

  /// Desaloca item
  /// POST /api/itens/{id}/desalocar
  Future<void> desalocarItem(String itemId) async {
    await _api.request<void>(
      'itens/$itemId/desalocar',
      method: 'POST',
      fromJson: (_) {},
    );
  }

  // ==========================================
  // ESTADO
  // ==========================================

  /// Altera estado físico do item
  /// PUT /api/itens/{id}/estado
  Future<void> alterarEstado(String itemId, EstadoFisicoItem novoEstado, {String? motivo}) async {
    final body = <String, dynamic>{'novoEstado': novoEstado.valor};
    if (motivo != null && motivo.isNotEmpty) body['motivo'] = motivo;
    await _api.request<void>(
      'itens/$itemId/estado',
      method: 'PUT',
      body: body,
      fromJson: (_) {},
    );
  }

  // ==========================================
  // HISTÓRICO
  // ==========================================

  /// Obtém histórico completo do item
  /// GET /api/itens/{id}/historico
  Future<HistoricoItemDto> obterHistorico(String itemId) async {
    return _api.request<HistoricoItemDto>(
      'itens/$itemId/historico',
      method: 'GET',
      fromJson: (json) => HistoricoItemDto.fromJson(json as Map<String, dynamic>),
    );
  }

  // ==========================================
  // QR CODE
  // ==========================================

  /// Obtém QR Code do item (retorna SVG bytes)
  /// GET /api/itens/{id}/qrcode
  Future<Uint8List> obterQrCode(String itemId) async {
    return _api.request<Uint8List>(
      'itens/$itemId/qrcode',
      method: 'GET',
      fromJson: (data) {
        if (data is Uint8List) return data;
        if (data is List) return Uint8List.fromList(data.cast<int>());
        return Uint8List(0);
      },
    );
  }
}

/// Resultado paginado de itens
class PagedResultItens {
  final List<ItemSearchResultDto> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedResultItens({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResultItens.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] ?? json['data'] ?? [];
    final List<ItemSearchResultDto> items = (itemsList as List)
        .map((e) => ItemSearchResultDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final total = json['totalCount'] ?? json['total'] ?? items.length;
    final pageSize = json['pageSize'] ?? 20;
    
    return PagedResultItens(
      items: items,
      totalCount: total,
      page: json['page'] ?? json['pageNumber'] ?? 1,
      pageSize: pageSize,
      totalPages: json['totalPages'] ?? (total / pageSize).ceil(),
    );
  }

  bool get hasMore => page < totalPages;
}
