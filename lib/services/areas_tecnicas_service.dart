import '../dto/area_tecnica_dto.dart';
import 'api_service.dart';

/// Serviço de áreas técnicas
/// Consome /api/AreasTecnicas do backend
class AreasTecnicasService {
  final ApiService _api = ApiService();

  /// Lista todas as áreas técnicas
  /// GET /api/AreasTecnicas
  Future<List<AreaTecnicaDto>> listar() async {
    return _api.request<List<AreaTecnicaDto>>(
      'AreasTecnicas',
      method: 'GET',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AreaTecnicaDto.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['data'] ?? [];
          if (items is List) {
            return items.map((e) => AreaTecnicaDto.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
        return [];
      },
    );
  }

  /// Lista apenas áreas técnicas ativas
  Future<List<AreaTecnicaDto>> listarAtivas() async {
    final todas = await listar();
    return todas.where((a) => a.ativo).toList();
  }

  /// Obtém área técnica por ID
  /// GET /api/AreasTecnicas/{id}
  Future<AreaTecnicaDto> obterPorId(String id) async {
    return _api.request<AreaTecnicaDto>(
      'AreasTecnicas/$id',
      method: 'GET',
      fromJson: (json) => AreaTecnicaDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Cria nova área técnica
  /// POST /api/AreasTecnicas
  Future<AreaTecnicaDto> criar({
    required String nome,
    String? descricao,
  }) async {
    return _api.request<AreaTecnicaDto>(
      'AreasTecnicas',
      method: 'POST',
      body: {
        'nome': nome,
        'descricao': descricao,
      },
      fromJson: (json) => AreaTecnicaDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Atualiza área técnica
  /// PUT /api/AreasTecnicas/{id}
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
      'AreasTecnicas/$id',
      method: 'PUT',
      body: body,
      fromJson: (_) {},
    );
  }

  /// Exclui área técnica
  /// DELETE /api/AreasTecnicas/{id}
  Future<void> excluir(String id) async {
    await _api.request<void>(
      'AreasTecnicas/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }
}
