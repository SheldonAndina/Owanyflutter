import '../dto/tipo_solicitacao_dto.dart';
import 'api_service.dart';

/// Serviço de tipos de solicitação (categorias de manutenção)
/// Consome /api/TiposSolicitacao do backend
class TiposSolicitacaoService {
  final ApiService _api = ApiService();

  /// Lista todos os tipos de solicitação
  /// GET /api/TiposSolicitacao
  Future<List<TipoSolicitacaoDto>> listar() async {
    return _api.request<List<TipoSolicitacaoDto>>(
      'TiposSolicitacao',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => TipoSolicitacaoDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => TipoSolicitacaoDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  /// Lista apenas tipos de solicitação ativos
  Future<List<TipoSolicitacaoDto>> listarAtivos() async {
    final todos = await listar();
    return todos.where((t) => t.ativo).toList();
  }

  /// Obtém tipo de solicitação por ID
  /// GET /api/TiposSolicitacao/{id}
  Future<TipoSolicitacaoDto> obterPorId(String id) async {
    return _api.request<TipoSolicitacaoDto>(
      'TiposSolicitacao/$id',
      method: 'GET',
      fromJson: (json) => TipoSolicitacaoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Cria novo tipo de solicitação
  /// POST /api/TiposSolicitacao
  Future<TipoSolicitacaoDto> criar({
    required String nome,
    String? descricao,
  }) async {
    return _api.request<TipoSolicitacaoDto>(
      'TiposSolicitacao',
      method: 'POST',
      body: {
        'nome': nome,
        'descricao': descricao,
      },
      fromJson: (json) => TipoSolicitacaoDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Atualiza tipo de solicitação
  /// PUT /api/TiposSolicitacao/{id}
  Future<void> atualizar(String id, {
    String? nome,
    String? descricao,
    bool? ativo,
  }) async {
    final body = <String, dynamic>{};
    if (nome != null) body['nome'] = nome;
    if (descricao != null) body['descricao'] = descricao;
    if (ativo != null) body['ativo'] = ativo;

    await _api.request<void>(
      'TiposSolicitacao/$id',
      method: 'PUT',
      body: body,
      fromJson: (_) {},
    );
  }

  /// Exclui tipo de solicitação
  /// DELETE /api/TiposSolicitacao/{id}
  Future<void> excluir(String id) async {
    await _api.request<void>(
      'TiposSolicitacao/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }
}
