// ============================================================================
// SOLICITAÇÕES V1 - SERVICE COMPLETO
// Criado: 27/01/2026
// Atualizado: 27/01/2026 - Endpoints V1 validados contra Swagger
// Status: ✅ PRONTO PARA PRODUÇÃO
// ============================================================================
// NOTA: Use endpoints V1 (/api/Solicitacoes) - V2 endpoints retornam 404
// Todos os DTOs foram validados e batem perfeitamente com API V1
// ============================================================================

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dto/solicitacoes_v2_dtos.dart';
import 'api_service.dart';
import '../utils/http_client_factory.dart'
    if (dart.library.io) '../utils/http_client_factory_io.dart';

class SolicitacoesService {
  // ✅ ENDPOINTS V1 - Validados e funcional
  static String get baseUrl => '${ApiService().baseUrl}/Solicitacoes';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client httpClient;
  final String? token;

  SolicitacoesService({http.Client? httpClient, this.token})
      : httpClient = httpClient ?? createHttpClient();

  String? get _token => token ?? ApiService().token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Lista solicitações com paginação
  /// GET /api/Solicitacoes?pageNumber=1&pageSize=20&status=...&apartamentoId=...&responsavelId=...&verTodas=true
  Future<PagedResult<SolicitacaoListaDto>> getSolicitacoes({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
    String? apartamentoId,
    String? responsavelId,
    bool verTodas = false,
    bool incluirHistorico = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'status': ?status,
        'apartamentoId': ?apartamentoId,
        'responsavelId': ?responsavelId,
        'verTodas': verTodas.toString(),
      };

      // If caller explicitly requested history for a morador via apartamentos/{id}/solicitacoes
      if (incluirHistorico && apartamentoId != null && apartamentoId.trim().isNotEmpty) {
        final q = Map<String, String>.from(queryParams);
        q['incluirHistorico'] = 'true';
        // Build URL: {baseApi}/apartamentos/{id}/solicitacoes
        final apartamentosUrl = '${ApiService().baseUrl}/apartamentos/${apartamentoId.trim()}/solicitacoes';
        final uri = Uri.parse(apartamentosUrl).replace(queryParameters: q);
        final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;

          if (json['sucesso'] == true && json['data'] != null) {
            return PagedResult.fromJson(
              json['data'] as Map<String, dynamic>,
              (itemJson) => SolicitacaoListaDto.fromJson(itemJson),
            );
          }

          throw Exception(json['mensagem'] ?? 'Erro ao buscar solicitações');
        }

        throw Exception('Erro HTTP ${response.statusCode}');
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['data'] != null) {
          return PagedResult.fromJson(
            json['data'] as Map<String, dynamic>,
            (itemJson) => SolicitacaoListaDto.fromJson(itemJson),
          );
        }

        throw Exception(json['mensagem'] ?? 'Erro ao buscar solicitações');
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao buscar solicitações: $e');
    }
  }

  /// Busca detalhes completos de uma solicitação
  /// GET /api/Solicitacoes/{id}
  Future<SolicitacaoDto> getSolicitacao(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['dados'] != null) {
          return SolicitacaoDto.fromJson(json['dados'] as Map<String, dynamic>);
        }

        throw Exception(json['mensagem'] ?? 'Erro ao buscar solicitação');
      } else if (response.statusCode == 404) {
        throw Exception('Solicitação não encontrada');
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao buscar solicitação: $e');
    }
  }

  /// Cria nova solicitação
  /// POST /api/Solicitacoes
  Future<SolicitacaoDto> criarSolicitacao(CriarSolicitacaoDto dto) async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await httpClient.post(uri, headers: _headers, body: jsonEncode(dto.toJson())).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // Se sucesso é true, consideramos sucesso mesmo se dados é null
        if (json['sucesso'] == true) {
          // Se temos dados, retorna; senão, cria um mínimo
          if (json['dados'] != null) {
            return SolicitacaoDto.fromJson(json['dados'] as Map<String, dynamic>);
          } else {
            // Retorna um SolicitacaoDto mínimo para indicar sucesso
            return SolicitacaoDto(
              id: 'nova-${DateTime.now().millisecondsSinceEpoch}',
              titulo: dto.titulo,
              descricao: dto.descricao,
              moradorId: dto.moradorId ?? '',
              nomeMorador: 'Morador',
              apartamentoId: dto.apartamentoId ?? '',
              numeroApartamento: '',
              blocoApartamento: '',
              status: 'Pendente',
              usuarioCriadorId: 'unknown',
              nomeUsuarioCriador: 'Usuário',
              criadoEm: DateTime.now(),
              comentarios: [],
              historicoStatus: [],
              anexos: [],
            );
          }
        }

        throw Exception(json['mensagem'] ?? 'Erro ao criar solicitação');
      }

      // Trata erro 400 e outros - extrai mensagem do backend
      if (response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final mensagem = json['mensagem'] ?? json['erros']?.toString() ?? 'Erro desconhecido';
          throw Exception('$mensagem');
        } catch (e) {
          if (e is Exception && e.toString().contains('Erro')) rethrow;
        }
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Muda status da solicitação
  /// PUT /api/Solicitacoes/{id}/status
  Future<void> mudarStatus(String id, MudarStatusDto dto) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/status');
      final response = await httpClient.put(uri, headers: _headers, body: jsonEncode(dto.toJson())).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] != true) {
          throw Exception(json['mensagem'] ?? 'Erro ao mudar status');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao mudar status: $e');
    }
  }

  /// Adiciona comentário
  /// POST /api/Solicitacoes/{id}/comentarios
  Future<ComentarioDto> adicionarComentario(String id, CriarComentarioDto dto) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/comentarios');
      final response = await httpClient.post(uri, headers: _headers, body: jsonEncode(dto.toJson())).timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['dados'] != null) {
          return ComentarioDto.fromJson(json['dados'] as Map<String, dynamic>);
        }

        throw Exception(json['mensagem'] ?? 'Erro ao adicionar comentário');
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao adicionar comentário: $e');
    }
  }

  /// Lista comentários
  /// GET /api/Solicitacoes/{id}/comentarios
  Future<List<ComentarioDto>> getComentarios(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/comentarios');
      final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['dados'] != null) {
          return (json['dados'] as List<dynamic>)
              .map((c) => ComentarioDto.fromJson(c as Map<String, dynamic>))
              .toList();
        }

        return [];
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao buscar comentários: $e');
    }
  }

  /// Lista anexos
  /// GET /api/Solicitacoes/{id}/anexos
  Future<List<AnexoDto>> getAnexos(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/anexos');
      final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['dados'] != null) {
          return (json['dados'] as List<dynamic>).map((a) => AnexoDto.fromJson(a as Map<String, dynamic>)).toList();
        }

        return [];
      } else if (response.statusCode == 404) {
        return []; // Backend V2 não implementado
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao buscar anexos: $e');
    }
  }

  /// Busca solicitações vinculadas a um item de apartamento
  /// GET /api/Solicitacoes?itemApartamentoId={itemId}&pageSize=50
  Future<PagedResult<SolicitacaoListaDto>> getSolicitacoesPorItem(
    String itemApartamentoId, {
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'itemApartamentoId': itemApartamentoId,
        'pageNumber': '1',
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await httpClient.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['data'] != null) {
          return PagedResult.fromJson(
            json['data'] as Map<String, dynamic>,
            (itemJson) => SolicitacaoListaDto.fromJson(itemJson),
          );
        }

        throw Exception(json['mensagem'] ?? 'Erro ao buscar solicitações do item');
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao buscar solicitações do item: $e');
    }
  }

  /// Upload de anexo (multipart/form-data)
  /// POST /api/Solicitacoes/{id}/anexos
  Future<AnexoDto> uploadAnexo(String id, List<int> fileBytes, String fileName) async {
    try {
      final uri = Uri.parse('$baseUrl/$id/anexos');

      // Criar multipart request manualmente
      final request = http.MultipartRequest('POST', uri);

      // Adicionar headers de autenticação
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Adicionar arquivo
      request.files.add(http.MultipartFile.fromBytes('arquivo', fileBytes, filename: fileName));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['sucesso'] == true && json['dados'] != null) {
          return AnexoDto.fromJson(json['dados'] as Map<String, dynamic>);
        }

        throw Exception(json['mensagem'] ?? 'Erro ao enviar anexo');
      }

      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao enviar anexo: $e');
    }
  }

  /// Lista anexos de comentário
  /// GET /api/Solicitacoes/{solId}/comentarios/{comId}/anexos
  Future<List<AnexoComentarioDto>> listarAnexosComentario(
    String solId,
    String comId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/$solId/comentarios/$comId/anexos');
      final response = await httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['sucesso'] == true && json['dados'] != null) {
          return (json['dados'] as List<dynamic>)
              .map((a) => AnexoComentarioDto.fromJson(a as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao listar anexos do comentário: $e');
    }
  }

  /// Upload de anexo em comentário (multipart/form-data)
  /// POST /api/Solicitacoes/{solId}/comentarios/{comId}/anexos
  Future<AnexoComentarioDto> uploadAnexoComentario(
    String solId,
    String comId,
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/$solId/comentarios/$comId/anexos');
      final request = http.MultipartRequest('POST', uri);

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(
        http.MultipartFile.fromBytes('arquivo', fileBytes, filename: fileName),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['sucesso'] == true && json['dados'] != null) {
          return AnexoComentarioDto.fromJson(json['dados'] as Map<String, dynamic>);
        }
        throw Exception(json['mensagem'] ?? 'Erro ao enviar anexo do comentário');
      }
      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao enviar anexo do comentário: $e');
    }
  }

  /// Edita anexo de solicitação (renomear e/ou substituir arquivo)
  /// PUT /api/Solicitacoes/{solId}/anexos/{anexoId}
  Future<AnexoDto> editarAnexo(
    String solId,
    String anexoId, {
    String? nomeArquivo,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$solId/anexos/$anexoId');
      final request = http.MultipartRequest('PUT', uri);

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      if (nomeArquivo != null) {
        request.fields['nomeArquivo'] = nomeArquivo;
      }
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('arquivo', fileBytes, filename: fileName),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['sucesso'] == true && json['dados'] != null) {
          return AnexoDto.fromJson(json['dados'] as Map<String, dynamic>);
        }
        throw Exception(json['mensagem'] ?? 'Erro ao editar anexo');
      }
      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao editar anexo: $e');
    }
  }

  /// Edita anexo de comentário (renomear e/ou substituir arquivo)
  /// PUT /api/Solicitacoes/{solId}/comentarios/{comId}/anexos/{anexoId}
  Future<AnexoComentarioDto> editarAnexoComentario(
    String solId,
    String comId,
    String anexoId, {
    String? nomeArquivo,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$solId/comentarios/$comId/anexos/$anexoId');
      final request = http.MultipartRequest('PUT', uri);

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      if (nomeArquivo != null) {
        request.fields['nomeArquivo'] = nomeArquivo;
      }
      if (fileBytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('arquivo', fileBytes, filename: fileName),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['sucesso'] == true && json['dados'] != null) {
          return AnexoComentarioDto.fromJson(json['dados'] as Map<String, dynamic>);
        }
        throw Exception(json['mensagem'] ?? 'Erro ao editar anexo do comentário');
      }
      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao editar anexo do comentário: $e');
    }
  }

  /// Remove anexo de comentário
  /// DELETE /api/Solicitacoes/{solId}/comentarios/{comId}/anexos/{anexoId}
  Future<void> removerAnexoComentario(
    String solId,
    String comId,
    String anexoId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/$solId/comentarios/$comId/anexos/$anexoId');
      final response = await httpClient.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return;
      }
      throw Exception('Erro HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao remover anexo do comentário: $e');
    }
  }
}
