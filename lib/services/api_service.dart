import 'dart:convert';
import 'dart:ui' as ui;
// import 'dart:io'; // removido para web
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../models/item_estado.dart';
import '../models/historico_ocupacao.dart';
import '../dto/login_dto.dart';
import '../dto/api_dtos.dart';
import '../dto/usuarios_dtos.dart';
import '../dto/agendamentos_dtos.dart';
import '../dto/backend_complete_dtos.dart';
import '../dto/qr_code_batch_dtos.dart';
import '../dto/solicitacoes_kpis_dto.dart';
import '../dto/ativos_dtos.dart';
import '../dto/blocos_dtos.dart';
import '../dto/item_busca_dto.dart';
import '../utils/app_date_time.dart';

class QrCodesLoteResult {
  final Map<String, List<int>> arquivosPng;
  final List<int>? arquivoCompactado;

  const QrCodesLoteResult({
    this.arquivosPng = const {},
    this.arquivoCompactado,
  });

  bool get possuiZip =>
      arquivoCompactado != null && arquivoCompactado!.isNotEmpty;
  bool get possuiArquivosPng => arquivosPng.isNotEmpty;
}

/// Professional API Service
/// Single source of truth for all API communication
/// Handles JWT token injection, response unwrapping, and error handling
class ApiService {
  static const String _appVersion = '1.0.0';
  // Keys for secure storage
  static const String _jwtKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// GET /api/apartamentos/{id}/ocupantes — retorna moradores atuais do apartamento
  Future<List<Morador>> getOcupantes(String apartamentoId) async {
    return request<List<Morador>>(
      'apartamentos/$apartamentoId/ocupantes',
      fromJson: (json) {
        if (json == null) return <Morador>[];
        // Handle paginated wrapper { items: [...] }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['dados'] ?? json['data'];
          if (items is List) {
            return items.map((item) => Morador.fromJson(item)).toList();
          }
          return <Morador>[];
        }
        // Handle direct list response
        if (json is List) {
          return json.map((item) => Morador.fromJson(item)).toList();
        }
        return <Morador>[];
      },
    );
  }

  static final ApiService _instance = ApiService._internal();

  factory ApiService({String baseUrl = ''}) {
    return _instance;
  }

  ApiService._internal();

  // Use 10.0.2.2 for Android emulator, localhost for other platforms
  String get baseUrl => _getBaseUrl();

  Uri resolveServerUri(String value) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final apiUri = Uri.parse(baseUrl);
    final origin = apiUri.replace(path: '', query: null, fragment: null);
    final relativePath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return origin.resolve(relativePath);
  }

  static String _getBaseUrl() {
    // Platform-specific URL resolution for development
    // Windows Desktop / MacOS / Linux: localhost:7068
    // Android Emulator: 10.0.2.2:7068 (special alias for host machine)
    // Physical Android Device: YOUR_PC_IP:7068
    // Web: YOUR_API_URL

    if (kIsWeb) {
      // Web platform
      return 'https://localhost:7068/api';
    }
    // For all other platforms, fallback to localhost
    return 'https://localhost:7068/api';
  }

  /// Create HTTP client that accepts self-signed certificates (dev only)
  static http.Client _createHttpClient() {
    // Web does not support custom HttpClient, so return default client
    return http.Client();
  }

  late final http.Client _httpClient = _createHttpClient();

  static const Duration _timeout = Duration(seconds: 30);

  String? _token;

  String? _refreshToken;
  bool _isReauthenticating = false;

  String? get token => _token;

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Load token from secure storage on app start
  Future<void> loadToken() async {
    _token = await _secureStorage.read(key: _jwtKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Save tokens after login
  Future<void> _saveTokens(String token, String? refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: _jwtKey, value: token);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Clear tokens on logout
  Future<void> logout() async {
    // Try to revoke refresh token on backend (best-effort)
    try {
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        final url = resolveServerUri('auth/revoke');
        final headers = {'Content-Type': 'application/json'};
        await _httpClient
            .post(url, headers: headers, body: jsonEncode({'refreshToken': _refreshToken}))
            .timeout(_timeout);
      }
    } catch (e) {
      AppLogger.warning('ApiService', 'Falha ao revogar refresh token: $e');
    }

    _token = null;
    _refreshToken = null;
    await _secureStorage.delete(key: _jwtKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<bool> ensureAuthenticated({bool forceRevalidate = true}) async {
    if (_token == null || _token!.isEmpty) {
      await loadToken();
    }
    if (_token == null || _token!.isEmpty) {
      return await _tryReauthenticate();
    }

    if (!forceRevalidate) return true;

    try {
      await request<TokenVerificationDto>(
        'auth/verificar',
        method: 'GET',
        retryOnUnauthorized: false,
        fromJson: (json) => TokenVerificationDto.fromJson(json),
      );
      return true;
    } catch (_) {
      return await _tryReauthenticate();
    }
  }

  Future<bool> _tryReauthenticate() async {
    if (_isReauthenticating) return false;
    _isReauthenticating = true;
    try {
      // Apenas tentar refresh token; não reautenticar com senha armazenada
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        try {
          final response = await _refreshTokenRequest();
          await _saveTokens(response.token, response.refreshToken);
          AppLogger.info('ApiService', 'Token renovado via refresh token');
          return true;
        } catch (e) {
          AppLogger.warning(
            'ApiService',
            'Refresh token falhou: $e',
          );
        }
      }

      // Sem refresh token válido, não podemos reautenticar automaticamente
      return false;
    } catch (e) {
      AppLogger.warning(
        'ApiService',
        'Falha ao reautenticar automaticamente',
        e,
      );
      return false;
    } finally {
      _isReauthenticating = false;
    }
  }

  /// POST /api/auth/refresh-token
  /// Renova JWT usando refresh token (sem reenviar credenciais)
  Future<LoginResponse> _refreshTokenRequest() async {
    return request<LoginResponse>(
      'auth/refresh-token',
      method: 'POST',
      retryOnUnauthorized: false,
      body: {'refreshToken': _refreshToken},
      fromJson: (json) {
        final response = LoginResponse.fromJson(json);
        return response;
      },
    );
  }

  /// Refresh token público — para uso externo (ex: AuthProvider)
  Future<LoginResponse> refreshToken() async {
    final response = await _refreshTokenRequest();
    await _saveTokens(response.token, response.refreshToken);
    return response;
  }

  /// Build request headers with JWT token
  Map<String, String> _headers({bool isBinaryDownload = false}) {
    return {
      if (!isBinaryDownload) 'Content-Type': 'application/json',
      'Accept': isBinaryDownload ? '*/*' : 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    // Para web, não usar Platform
    return 'mobile';
  }

  /// Generic HTTP request method
  /// Handles GET, POST, PUT, DELETE with automatic token injection
  /// Automatically unwraps ApiResponse<T> and extracts dados field
  Future<T> request<T>(
    String endpoint, {
    String method = 'GET',
    Object? body,
    Map<String, String>? queryParams,
    bool retryOnUnauthorized = true,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      endpoint = endpoint
          .replaceAll(RegExp(r'/+$'), '')
          .replaceAll(RegExp(r'^/+'), '');

      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      AppLogger.debug('ApiService', '🔵 API $method: $url');
      if (body != null) AppLogger.debug('ApiService', '📦 Body: $body');

      Future<http.Response> send() async {
        final headers = _headers();
        switch (method.toUpperCase()) {
          case 'POST':
            return _httpClient
                .post(
                  url,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(_timeout);
          case 'PUT':
            return _httpClient
                .put(
                  url,
                  headers: headers,
                  body: body != null ? jsonEncode(body) : null,
                )
                .timeout(_timeout);
          case 'DELETE':
            return _httpClient.delete(url, headers: headers).timeout(_timeout);
          case 'GET':
          default:
            return _httpClient.get(url, headers: headers).timeout(_timeout);
        }
      }

      http.Response response = await send();

      if (response.statusCode == 401 && retryOnUnauthorized) {
        final renewed = await _tryReauthenticate();
        if (renewed) {
          AppLogger.warning(
            'ApiService',
            '401 recebido. Reautenticando e repetindo requisição: $method $url',
          );
          response = await send();
        }
      }

      AppLogger.debug('ApiService', '📨 Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Unauthorized - token expired or invalid
        await logout();
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        // Se a API usar o wrapper { sucesso, mensagem, dados }, respeitamos o campo sucesso
        if (decoded is Map<String, dynamic> && decoded.containsKey('sucesso')) {
          final bool sucesso = decoded['sucesso'] == true;
          if (!sucesso) {
            final erros = (decoded['erros'] as List<dynamic>?)?.cast<String>();
            final mensagemErro = erros != null && erros.isNotEmpty
                ? erros.join('\n')
                : (decoded['mensagem'] ?? 'Operação não concluída');
            throw Exception(mensagemErro);
          }
        }

        // Extract payload from common wrappers (dados/data) or fall back to full body
        dynamic dados;
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('dados')) {
            dados = decoded['dados'];
          } else if (decoded.containsKey('data')) {
            dados = decoded['data'];
          } else {
            dados = decoded;
          }
        } else {
          dados = decoded;
        }

        AppLogger.debug('ApiService', '✅ Response: $dados');
        return fromJson(dados);
      } else {
        // Error response
        String errorMsg = 'Erro: ${response.statusCode}';

        // Try to decode error response body
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              // Log full error details for 400 Bad Request
              if (response.statusCode == 400) {
                AppLogger.error(
                  'ApiService',
                  '🔴 Validation Error Details: $decoded',
                );
              }

              errorMsg = decoded['mensagem'] ?? 'Erro ao processar requisição';
              final erros = (decoded['erros'] as List<dynamic>?)
                  ?.cast<String>();
              if (erros != null && erros.isNotEmpty) {
                errorMsg = erros.join('\n');
              }

              // Also check for 'errors' key (ASP.NET Core validation format)
              if (decoded.containsKey('errors') && decoded['errors'] is Map) {
                final validationErrors =
                    decoded['errors'] as Map<String, dynamic>;
                final errorList = <String>[];
                validationErrors.forEach((field, messages) {
                  if (messages is List) {
                    errorList.addAll(messages.map((m) => '$field: $m'));
                  }
                });
                if (errorList.isNotEmpty) {
                  errorMsg = errorList.join('\n');
                }
              }
            }
          } catch (e) {
            // If body is not JSON, just use status code message
            switch (response.statusCode) {
              case 400:
                errorMsg = 'Requisição inválida';
                break;
              case 401:
                errorMsg = 'Não autorizado';
                break;
              case 403:
                errorMsg = 'Acesso negado';
                break;
              case 404:
                errorMsg = 'Recurso não encontrado';
                break;
              case 405:
                errorMsg = 'Método não permitido pelo servidor';
                break;
              case 500:
                errorMsg = 'Erro no servidor';
                break;
              default:
                errorMsg =
                    'Erro ao processar requisição (${response.statusCode})';
            }
          }
        } else {
          // Empty response body
          switch (response.statusCode) {
            case 405:
              errorMsg =
                  'Método não permitido (405) - Endpoint pode não estar implementado';
              break;
            case 500:
              errorMsg = 'Erro interno do servidor (500)';
              break;
            default:
              errorMsg = 'Resposta vazia do servidor (${response.statusCode})';
          }
        }

        AppLogger.error('ApiService', '❌ Erro: $errorMsg');
        throw Exception(errorMsg);
      }
    } on http.ClientException catch (e) {
      AppLogger.error('ApiService', '🔴 Network Error: $e');
      throw Exception('Erro de conexão. Verifique sua internet.');
    } on ArgumentError catch (e) {
      // Handle duplicate header errors from server
      if (e.toString().contains('Strict-Transport-Security') ||
          e.toString().contains('has already been added')) {
        AppLogger.warning(
          'ApiService',
          '⚠️ Ignorando erro de headers duplicados do servidor: $e',
        );
        // Try to continue - this is a server issue, not client
        throw Exception('Erro do servidor. Tente novamente.');
      }
      AppLogger.error('ApiService', '🔴 Request Error: $e');
      rethrow;
    } catch (e) {
      AppLogger.error('ApiService', '🔴 Request Error: $e');
      rethrow;
    }
  }

  // ==================== AUTH ====================

  /// POST /api/auth/login
  /// Realiza login com nomeLogin e senha
  /// Retorna token JWT e dados do usuário
  /// Token é automaticamente salvo em secure storage
  Future<LoginResponse> login(String nomeLogin, String senha) async {
    return request<LoginResponse>(
      'auth/login',
      method: 'POST',
      body: {'nomeLogin': nomeLogin, 'senha': senha, 'lembrarMe': true},
      fromJson: (json) {
        final response = LoginResponse.fromJson(json);
        _saveTokens(response.token, response.refreshToken);
        return response;
      },
    );
  }

  /// POST /api/auth/registrar
  /// Cria novo usuário
  /// Role pode ser: Morador, Funcionario, Administrador
  Future<Usuario> register(RegisterRequest request) async {
    return this.request<Usuario>(
      'auth/registrar',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => Usuario.fromJson(json),
    );
  }

  /// POST /api/auth/esqueci-senha
  /// Solicita código OTP para reset de senha
  /// Envia código via SMS para o telefone
  Future<EsqueceuSenhaResponseDto> esqueceuSenha(String telefone) async {
    return request<EsqueceuSenhaResponseDto>(
      'auth/esqueci-senha',
      method: 'POST',
      body: {'telefone': telefone},
      fromJson: (json) => EsqueceuSenhaResponseDto.fromJson(json),
    );
  }

  /// POST /api/auth/resetar-senha
  /// Reseta senha usando código OTP
  /// Requer: telefone, codigoOtp, novaSenha, confirmarNovaSenha
  Future<void> resetarSenha(
    String telefone,
    String codigoOtp,
    String novaSenha,
  ) async {
    return request<void>(
      'auth/resetar-senha',
      method: 'POST',
      body: {
        'telefone': telefone,
        'codigoOtp': codigoOtp,
        'novaSenha': novaSenha,
        'confirmarNovaSenha': novaSenha,
      },
      fromJson: (_) {},
    );
  }

  /// GET /api/auth/verificar
  /// Verifica se token JWT atual é válido
  /// Requer token no header Authorization: Bearer {token}
  Future<TokenVerificationDto> verificarToken() async {
    return request<TokenVerificationDto>(
      'auth/verificar',
      method: 'GET',
      fromJson: (json) => TokenVerificationDto.fromJson(json),
    );
  }

  /// POST /api/auth/mudar-senha (deprecated - use auth endpoints)
  /// Muda senha do usuário logado
  Future<void> mudarSenha(MudarSenhaRequest request) async {
    return this.request<void>(
      'auth/mudar-senha',
      method: 'POST',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// POST /api/auth/solicitar-reset (deprecated - use esqueci-senha)
  /// Solicita reset de senha
  Future<ResetSenhaResponseDto?> solicitarReset(String nomeLogin) async {
    final response = await request<ResetSenhaResponseDto?>(
      'auth/solicitar-reset',
      method: 'POST',
      body: {'nomeLogin': nomeLogin},
      fromJson: (json) {
        if (json == null) return null;
        return ResetSenhaResponseDto.fromJson(json);
      },
    );
    return response;
  }

  /// POST /api/auth/validar-codigo (deprecated - use resetar-senha)
  /// Valida código de reset
  Future<void> validarCodigoSenha(
    String? usuarioId,
    String telefone,
    String codigo,
  ) async {
    final body = {'telefone': telefone, 'codigo': codigo};
    if (usuarioId != null && usuarioId.isNotEmpty) {
      body['usuarioId'] = usuarioId;
    }
    return request<void>(
      'auth/validar-codigo',
      method: 'POST',
      body: body,
      fromJson: (_) {},
    );
  }

  /// POST /api/auth/resetar-senha (deprecated - use novo endpoint)
  /// Reseta senha
  Future<void> resetarSenhaLegacy(ResetPasswordRequest request) async {
    return this.request<void>(
      'auth/resetar-senha',
      method: 'POST',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  // ==================== USUÁRIOS ====================

  /// GET /api/usuarios
  /// Lista todos os usuários (Admin/Funcionário)
  /// Suporta filtros: role, search
  /// Suporta paginação: pageNumber, pageSize
  Future<UsuariosPagedResponseDto> listarUsuarios({
    String? role,
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<UsuariosPagedResponseDto>(
      'usuarios',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'role': ?role,
        'search': ?search,
      },
      fromJson: (json) => UsuariosPagedResponseDto.fromJson(json),
    );
  }

  /// GET /api/usuarios/{id}
  /// Obtém usuário específico por ID
  Future<UsuarioDetalheDto> getUsuario(String id) async {
    return request<UsuarioDetalheDto>(
      'usuarios/$id',
      method: 'GET',
      fromJson: (json) => UsuarioDetalheDto.fromJson(json),
    );
  }

  /// PUT /api/usuarios/{id}
  /// Atualiza usuário (nome, telefone, ativo)
  Future<UsuarioDetalheDto> atualizarUsuario(
    String id, {
    required String nome,
    String? telefone,
    bool? ativo,
  }) async {
    return request<UsuarioDetalheDto>(
      'usuarios/$id',
      method: 'PUT',
      body: {
        'nome': nome,
        'telefone': ?telefone,
        'ativo': ?ativo,
      },
      fromJson: (json) => UsuarioDetalheDto.fromJson(json),
    );
  }

  /// PUT /api/usuarios/{id}/mudar-senha
  /// Muda senha do usuário
  /// Requer: senhaAtual, novaSenha, confirmarNovaSenha
  Future<void> mudarSenhaUsuario(
    String id, {
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    return request<void>(
      'usuarios/$id/mudar-senha',
      method: 'PUT',
      body: {
        'senhaAtual': senhaAtual,
        'novaSenha': novaSenha,
        'confirmarNovaSenha': confirmarNovaSenha,
      },
      fromJson: (_) {},
    );
  }

  /// DELETE /api/usuarios/{id}
  /// Soft delete - desativa o usuário
  Future<void> deletarUsuario(String id) async {
    return request<void>('usuarios/$id', method: 'DELETE', fromJson: (_) {});
  }

  /// PUT /api/usuarios/{id}/reset-senha-admin
  /// Admin reseta senha de qualquer usuário diretamente (sem fluxo OTP)
  /// Impede admin de resetar própria senha (deve usar /api/auth/mudar-senha)
  /// Opcionalmente envia SMS com a nova senha (NÃO salva no histórico de SMS)
  Future<void> resetSenhaAdmin(
    String id, {
    required String novaSenha,
    bool enviarSms = false,
  }) async {
    return request<void>(
      'usuarios/$id/reset-senha-admin',
      method: 'PUT',
      body: {
        'novaSenha': novaSenha,
        'enviarSms': enviarSms,
      },
      fromJson: (_) {},
    );
  }

  // ==================== DASHBOARD ====================

  /// GET /api/dashboard/estatisticas
  Future<DashboardEstatisticas> getDashboardEstatisticas() async {
    return request<DashboardEstatisticas>(
      'dashboard/estatisticas',
      fromJson: (json) => DashboardEstatisticas.fromJson(json),
    );
  }

  /// GET /api/dashboard/solicitacoes-recentes
  Future<List<SolicitacaoRecenteDto>> getSolicitacoesRecentes({
    int limite = 10,
  }) async {
    return request<List<SolicitacaoRecenteDto>>(
      'dashboard/solicitacoes-recentes',
      queryParams: {'limite': limite.toString()},
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => SolicitacaoRecenteDto.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/dashboard/grafico-status
  Future<List<StatusGraficoDto>> getGraficoStatus() async {
    try {
      return await request<List<StatusGraficoDto>>(
        'dashboard/grafico-status',
        fromJson: (json) {
          final grafico = GraficoStatusDto.fromJson(json);
          return grafico.dados;
        },
      );
    } catch (e) {
      // Some backends may not expose this optional endpoint (404) or return empty body.
      // Treat missing/empty grafico as an empty list so UI keeps working.
      AppLogger.warning(
        'ApiService',
        'dashboard/grafico-status não disponível ou vazio, retornando lista vazia',
        e,
      );
      return <StatusGraficoDto>[];
    }
  }

  /// GET /api/dashboard/minhas-solicitacoes
  Future<List<SolicitacaoRecenteDto>> getMinhasSolicitacoes() async {
    return request<List<SolicitacaoRecenteDto>>(
      'dashboard/minhas-solicitacoes',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => SolicitacaoRecenteDto.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/dashboard/solicitacoes-kpis
  Future<SolicitacoesKpisDto> getSolicitacoesKpis({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final params = <String, String>{};
    if (dataInicio != null) params['dataInicio'] = toBackendUtcIsoString(dataInicio);
    if (dataFim != null) params['dataFim'] = toBackendUtcIsoString(dataFim);
    return request<SolicitacoesKpisDto>(
      'dashboard/solicitacoes-kpis',
      queryParams: params.isNotEmpty ? params : null,
      fromJson: (json) => SolicitacoesKpisDto.fromJson(json),
    );
  }

  // ==================== SOLICITAÇÕES ====================

  /// GET /api/solicitacoes
  Future<SolicitacaoV2ListaDto> getSolicitacoes({
    String? status,
    String? apartamentoId,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<SolicitacaoV2ListaDto>(
      'solicitacoes',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'status': ?status,
        'apartamentoId': ?apartamentoId,
      },
      fromJson: (json) => SolicitacaoV2ListaDto.fromJson(json),
    );
  }

  /// GET /api/solicitacoes/{id}
  Future<Solicitacao> getSolicitacao(String id) async {
    return request<Solicitacao>(
      'solicitacoes/$id',
      fromJson: (json) => Solicitacao.fromJson(json),
    );
  }

  /// POST /api/solicitacoes
  Future<Solicitacao> criarSolicitacao(CriarSolicitacaoRequest request) async {
    return this.request<Solicitacao>(
      'solicitacoes',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => Solicitacao.fromJson(json),
    );
  }

  /// PUT /api/solicitacoes/{id}
  Future<void> atualizarSolicitacao(
    String id,
    AtualizarSolicitacaoRequest request,
  ) async {
    return this.request<void>(
      'solicitacoes/$id',
      method: 'PUT',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// DELETE /api/solicitacoes/{id}
  Future<void> deletarSolicitacao(String id) async {
    return request<void>(
      'solicitacoes/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  /// POST /api/solicitacoes/{id}/atribuir
  Future<void> atribuirSolicitacao(
    String id,
    AtribuirSolicitacaoRequest request,
  ) async {
    return this.request<void>(
      'solicitacoes/$id/atribuir',
      method: 'POST',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// GET /api/dashboard - Dashboard completo com cache (5 min)
  Future<DashboardEstatisticas> getDashboard() async {
    return request<DashboardEstatisticas>(
      'dashboard',
      fromJson: (json) => DashboardEstatisticas.fromJson(json),
    );
  }

  // ==================== COMENTÁRIOS ====================

  /// GET /api/comentarios/solicitacao/{solicitacaoId}
  Future<List<Comentario>> getComentarios(String solicitacaoId) async {
    return request<List<Comentario>>(
      'comentarios/solicitacao/$solicitacaoId',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Comentario.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/comentarios/{id}
  Future<Comentario> getComentario(String id) async {
    return request<Comentario>(
      'comentarios/$id',
      fromJson: (json) => Comentario.fromJson(json),
    );
  }

  /// POST /api/comentarios
  Future<Comentario> criarComentario(CriarComentarioRequest request) async {
    return this.request<Comentario>(
      'comentarios',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => Comentario.fromJson(json),
    );
  }

  /// PUT /api/comentarios/{id}
  Future<void> atualizarComentario(
    String id,
    AtualizarComentarioRequest request,
  ) async {
    return this.request<void>(
      'comentarios/$id',
      method: 'PUT',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// DELETE /api/comentarios/{id}
  Future<void> deletarComentario(String id) async {
    return request<void>('comentarios/$id', method: 'DELETE', fromJson: (_) {});
  }

  // ==================== APARTAMENTOS ====================

  /// GET /api/apartamentos
  Future<List<Apartamento>> getApartamentos({
    String? bloco,
    String? estado,
    int pageNumber = 1,
    int pageSize = 20,
    int? andar,
    bool? emManutencao,
    bool comOcupantes = false,
  }) async {
    return request<List<Apartamento>>(
      'apartamentos',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'bloco': ?bloco,
        'estado': ?estado,
        if (andar != null) 'andar': andar.toString(),
        if (emManutencao != null) 'emManutencao': emManutencao.toString(),
        if (comOcupantes) 'comOcupantes': 'true',
      },
      fromJson: _parseApartamentosList,
    );
  }

  List<Apartamento> _parseApartamentosList(dynamic json) {
    List<dynamic>? lista;

    if (json is List) {
      lista = json;
    } else if (json is Map<String, dynamic>) {
      final candidates = [
        json['items'],
        json['apartamentos'],
        json['registros'],
        json['results'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          lista = candidate;
          break;
        }
      }
    } else if (json is Map) {
      return _parseApartamentosList(Map<String, dynamic>.from(json));
    }

    if (lista == null) return <Apartamento>[];

    return lista
        .whereType<Map>()
        .map((item) => Apartamento.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /api/apartamentos/{id}
  Future<Apartamento> getApartamento(String id) async {
    return request<Apartamento>(
      'apartamentos/$id',
      fromJson: (json) => Apartamento.fromJson(json),
    );
  }

  /// POST /api/apartamentos
  Future<Apartamento> criarApartamento(CriarApartamentoRequest request) async {
    return this.request<Apartamento>(
      'apartamentos',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => Apartamento.fromJson(json),
    );
  }

  /// PUT /api/apartamentos/{id}
  Future<void> atualizarApartamento(
    String id,
    AtualizarApartamentoRequest request,
  ) async {
    return this.request<void>(
      'apartamentos/$id',
      method: 'PUT',
      body: request.toJson(),
      fromJson: (_) {},
    );
  }

  /// DELETE /api/apartamentos/{id}
  Future<void> deletarApartamento(String id) async {
    return request<void>(
      'apartamentos/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  /// GET /api/apartamentos/disponiveis
  Future<List<Apartamento>> getApartamentosDisponiveis() async {
    return request<List<Apartamento>>(
      'apartamentos/disponiveis',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Apartamento.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/apartamentos/blocos
  Future<List<String>> getBlocos() async {
    return request<List<String>>(
      'apartamentos/blocos',
      fromJson: (json) => (json as List<dynamic>).cast<String>(),
    );
  }

  /// GET /api/apartamentos/em-manutencao
  /// Compatibilidade para ambientes onde esse endpoint foi removido.
  Future<List<Apartamento>> getApartamentosEmManutencao() async {
    try {
      return await request<List<Apartamento>>(
        'apartamentos/em-manutencao',
        fromJson: _parseApartamentosList,
      );
    } catch (_) {
      final apartamentos = await getApartamentos(
        pageNumber: 1,
        pageSize: 500,
        emManutencao: true,
      );
      return apartamentos
          .where(
            (a) => a.emManutencao || a.estado == EstadoApartamento.EmManutencao,
          )
          .toList();
    }
  }

  /// PUT /api/apartamentos/{id}/toggle-manutencao
  /// Alterna a flag EmManutencao sem alterar o estado do apartamento
  /// Backend notifica moradores e invalida cache do dashboard
  Future<Apartamento> toggleManutencao(String id) async {
    return request<Apartamento>(
      'apartamentos/$id/toggle-manutencao',
      method: 'PUT',
      fromJson: (json) => Apartamento.fromJson(json),
    );
  }

  /// POST /api/apartamentos/bulk
  /// Criação em lote de apartamentos com validação de duplicatas
  Future<List<Apartamento>> criarApartamentosBulk(
    List<Map<String, dynamic>> apartamentos,
  ) async {
    return request<List<Apartamento>>(
      'apartamentos/bulk',
      method: 'POST',
      body: apartamentos,
      fromJson: _parseApartamentosList,
    );
  }

  // ==================== BLOCOS (CRUD COMPLETO) ====================

  /// GET /api/blocos
  /// Lista todos os blocos do condomínio
  Future<List<BlocoDto>> listarBlocos() async {
    return request<List<BlocoDto>>(
      'blocos',
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => BlocoDto.fromJson(item)).toList();
        }
        if (json is Map<String, dynamic>) {
          final items = json['items'] ?? json['blocos'] ?? json['data'];
          if (items is List) {
            return items.map((item) => BlocoDto.fromJson(item)).toList();
          }
        }
        return <BlocoDto>[];
      },
    );
  }

  /// GET /api/blocos/{id}
  /// Retorna detalhes de um bloco específico
  Future<BlocoDto> getBloco(String id) async {
    return request<BlocoDto>(
      'blocos/$id',
      fromJson: (json) => BlocoDto.fromJson(json),
    );
  }

  /// GET /api/blocos/{id}/apartamentos
  /// Lista apartamentos de um bloco específico
  Future<List<Apartamento>> getApartamentosDoBloco(String blocoId) async {
    return request<List<Apartamento>>(
      'blocos/$blocoId/apartamentos',
      fromJson: _parseApartamentosList,
    );
  }

  /// POST /api/blocos
  /// Cria um novo bloco (valida nome único)
  Future<BlocoDto> criarBloco(CriarBlocoRequest req) async {
    return request<BlocoDto>(
      'blocos',
      method: 'POST',
      body: req.toJson(),
      fromJson: (json) => BlocoDto.fromJson(json),
    );
  }

  /// PUT /api/blocos/{id}
  /// Atualiza um bloco existente
  Future<BlocoDto> atualizarBloco(String id, AtualizarBlocoRequest req) async {
    return request<BlocoDto>(
      'blocos/$id',
      method: 'PUT',
      body: req.toJson(),
      fromJson: (json) => BlocoDto.fromJson(json),
    );
  }

  /// DELETE /api/blocos/{id}
  /// Deleta um bloco (impede se houver apartamentos vinculados)
  Future<void> deletarBloco(String id) async {
    return request<void>('blocos/$id', method: 'DELETE', fromJson: (_) {});
  }

  // ==================== ITENS DE APARTAMENTO ====================

  /// GET /api/itens/apartamento/{apartamentoId}
  Future<List<ItemApartamento>> getItensApartamento(
    String apartamentoId,
  ) async {
    return request<List<ItemApartamento>>(
      'itens/apartamento/$apartamentoId',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => ItemApartamento.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/itens/disponiveis
  Future<List<ItemApartamento>> getItensApartamentoAtivos() async {
    return request<List<ItemApartamento>>(
      'itens/disponiveis',
      fromJson: _parseItensApartamentoList,
    );
  }

  /// GET /api/itens
  /// Fallback para ambientes onde /disponiveis não retorna todos os registros esperados.
  Future<List<ItemApartamento>> getTodosItensApartamento() async {
    return request<List<ItemApartamento>>(
      'itens',
      fromJson: _parseItensApartamentoList,
    );
  }

  /// Busca itens com filtragem e paginação (client-side)
  /// O endpoint /search não existe na API - usa fallback local.
  /// 
  /// Parâmetros:
  /// - [query]: Termo de busca (nome, código patrimônio, tipo)
  /// - [estado]: Filtro por estado (Disponivel, Manutencao, Danificado)
  /// - [tipo]: Filtro por tipo do item
  /// - [apartamentoId]: Filtro por apartamento específico
  /// - [somenteStock]: Se true, retorna apenas itens sem vínculo
  /// - [page]: Número da página (1-based)
  /// - [pageSize]: Tamanho da página (default: 20, max: 100)
  /// - [ordenarPor]: Campo para ordenação (nome, codigo, estado, dataAquisicao)
  /// - [descendente]: Ordenação descendente
  /// 
  /// Retorna ItemBuscaResult com lista paginada e metadados.
  Future<ItemBuscaResult> buscarItensApartamento({
    String? query,
    String? estado,
    String? tipo,
    String? apartamentoId,
    bool? somenteStock,
    int page = 1,
    int pageSize = 20,
    String? ordenarPor,
    bool descendente = false,
  }) async {
    final params = ItemBuscaParams(
      query: query,
      estado: estado,
      tipo: tipo,
      apartamentoId: apartamentoId,
      somenteStock: somenteStock,
      page: page,
      pageSize: pageSize.clamp(1, 100),
      ordenarPor: ordenarPor,
      descendente: descendente,
    );

    // O endpoint /search não existe na API atual.
    // Usa busca local com fallback direto.
    AppLogger.debug(
      'ApiService',
      'Usando busca local para itens (endpoint /search não disponível).',
    );
    return _buscarItensLocalFallback(params);
  }

  /// Fallback para busca local quando endpoint otimizado não está disponível.
  /// Carrega todos os itens e aplica filtros/paginação no cliente.
  Future<ItemBuscaResult> _buscarItensLocalFallback(ItemBuscaParams params) async {
    final todosItens = await getTodosItensApartamento();
    
    // Aplica filtros
    var filtrados = todosItens.where((item) {
      // Filtro por query (nome, código, tipo)
      if (params.query != null && params.query!.isNotEmpty) {
        final q = params.query!.toLowerCase();
        final nome = item.nome.toLowerCase();
        final codigo = (item.codigoPatrimonio ?? item.codigoIdentificador ?? '').toLowerCase();
        final tipo = (item.tipo ?? '').toLowerCase();
        if (!nome.contains(q) && !codigo.contains(q) && !tipo.contains(q)) {
          return false;
        }
      }
      
      // Filtro por estado
      if (params.estado != null && params.estado!.isNotEmpty) {
        final estadoItem = (item.estadoAtual ?? item.estadoDesgaste ?? item.status ?? '').toLowerCase();
        if (!estadoItem.contains(params.estado!.toLowerCase())) {
          return false;
        }
      }
      
      // Filtro por tipo
      if (params.tipo != null && params.tipo!.isNotEmpty) {
        final tipoItem = (item.tipo ?? '').toLowerCase();
        if (!tipoItem.contains(params.tipo!.toLowerCase())) {
          return false;
        }
      }
      
      // Filtro por apartamento
      if (params.apartamentoId != null && params.apartamentoId!.isNotEmpty) {
        if (item.apartamentoId != params.apartamentoId) {
          return false;
        }
      }
      
      // Filtro somente stock
      if (params.somenteStock == true) {
        if (item.apartamentoId != null && item.apartamentoId!.isNotEmpty) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Aplica ordenação
    if (params.ordenarPor != null) {
      switch (params.ordenarPor!.toLowerCase()) {
        case 'nome':
          filtrados.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
          break;
        case 'codigo':
          filtrados.sort((a, b) {
            final codA = (a.codigoPatrimonio ?? a.codigoIdentificador ?? '').toLowerCase();
            final codB = (b.codigoPatrimonio ?? b.codigoIdentificador ?? '').toLowerCase();
            return codA.compareTo(codB);
          });
          break;
        case 'estado':
          filtrados.sort((a, b) {
            final estA = (a.estadoAtual ?? a.estadoDesgaste ?? a.status ?? '').toLowerCase();
            final estB = (b.estadoAtual ?? b.estadoDesgaste ?? b.status ?? '').toLowerCase();
            return estA.compareTo(estB);
          });
          break;
        case 'dataaquisicao':
          filtrados.sort((a, b) {
            final dataA = a.dataAquisicao ?? DateTime(1900);
            final dataB = b.dataAquisicao ?? DateTime(1900);
            return dataA.compareTo(dataB);
          });
          break;
      }
      if (params.descendente) {
        filtrados = filtrados.reversed.toList();
      }
    } else {
      // Ordenação padrão por nome
      filtrados.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    }

    // Aplica paginação
    final total = filtrados.length;
    final totalPages = (total / params.pageSize).ceil().clamp(1, 999999);
    final startIndex = (params.page - 1) * params.pageSize;
    final endIndex = (startIndex + params.pageSize).clamp(0, total);
    
    final paginados = startIndex < total 
        ? filtrados.sublist(startIndex, endIndex)
        : <ItemApartamento>[];

    // Converte para DTOs
    final items = paginados.map((item) => ItemBuscaDto(
      id: item.id,
      nome: item.nome,
      codigoPatrimonio: item.codigoPatrimonio ?? item.codigoIdentificador,
      tipo: item.tipo,
      quantidade: item.quantidade,
      apartamentoId: item.apartamentoId,
      estadoEfetivo: item.estadoAtual ?? item.estadoDesgaste ?? item.status ?? 'Disponivel',
      possuiManutencaoAtiva: item.manutencoes.any((m) => 
        m.status?.toLowerCase() == 'pendente' || 
        m.status?.toLowerCase() == 'emandamento' ||
        m.status?.toLowerCase() == 'em andamento'),
      dataAquisicao: item.dataAquisicao,
    )).toList();

    return ItemBuscaResult(
      items: items,
      total: total,
      pageNumber: params.page,
      pageSize: params.pageSize,
      totalPages: totalPages,
      hasNextPage: params.page < totalPages,
      hasPreviousPage: params.page > 1,
    );
  }

  List<ItemApartamento> _parseItensApartamentoList(dynamic json) {
    List<dynamic>? rawList;

    if (json is List) {
      rawList = json;
    } else if (json is Map<String, dynamic>) {
      final candidates = [
        json['items'],
        json['itens'],
        json['ativos'],
        json['registros'],
        json['results'],
        json['data'],
        json['dados'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          rawList = candidate;
          break;
        }
      }
    }

    if (rawList == null) return <ItemApartamento>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ItemApartamento.fromJson)
        .toList();
  }

  /// GET /api/itens/{id}
  Future<ItemApartamento> getItemApartamento(String id) async {
    return request<ItemApartamento>(
      'itens/$id',
      fromJson: (json) => ItemApartamento.fromJson(json),
    );
  }

  /// O endpoint /generate-patrimonio não existe na API atual.
  /// Retorna o item existente sem modificação (código já gerado na criação).
  Future<ItemApartamento> gerarCodigoPatrimonio(String id) async {
    return request<ItemApartamento>(
      'itens/$id',
      fromJson: (json) {
        dynamic payload = json;
        if (json is Map<String, dynamic>) {
          payload = json['dados'] ?? json['data'] ?? json;
        }
        if (payload is Map<String, dynamic>) {
          return ItemApartamento.fromJson(payload);
        }
        throw Exception('Formato inesperado ao buscar item.');
      },
    );
  }

  /// GET /api/itens/{id}/historico - Relatório completo do item
  Future<ItemApartamento> getRelatorioCompletoItemApartamento(String id) async {
    // O endpoint /relatorio-completo não existe. Usamos GET /itens/{id}
    return request<ItemApartamento>(
      'itens/$id',
      fromJson: (json) =>
          ItemApartamento.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/itens/estatisticas
  Future<AtivosEstatisticasDto> getAtivosEstatisticas() async {
    return request<AtivosEstatisticasDto>(
      'itens/estatisticas',
      fromJson: (json) =>
          AtivosEstatisticasDto.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/itens/estatisticas - Relatório consolidado
  /// O endpoint /relatorio não existe. Usamos estatísticas.
  Future<RelatorioAtivosDto> getRelatorioAtivos({
    String? estado,
    String? tipo,
    String? apartamentoId,
    bool? somenteStock,
  }) async {
    // Endpoint /relatorio não existe na API atual.
    // Retorna estatísticas básicas dentro do DTO esperado.
    final stats = await getAtivosEstatisticas();
    return RelatorioAtivosDto(
      estatisticas: stats,
      porTipo: [],
      porEstado: [],
      porApartamento: [],
      porAreaTecnica: [],
      maisSolicitados: [],
    );
  }

  /// GET /api/itens/nunca-alocados
  Future<List<ItemApartamento>> getItensSemVinculo() async {
    return request<List<ItemApartamento>>(
      'itens/nunca-alocados',
      fromJson: _parseItensApartamentoList,
    );
  }

  /// POST /api/itens/{id}/alocar
  Future<ItemApartamento> vincularItemApartamento(
    String itemId,
    String apartamentoId,
  ) async {
    return request<ItemApartamento>(
      'itens/$itemId/alocar',
      method: 'POST',
      body: {'apartamentoId': apartamentoId},
      fromJson: (json) =>
          ItemApartamento.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/itens/{id}/desalocar
  Future<ItemApartamento> desvincularItemApartamento(String itemId) async {
    return request<ItemApartamento>(
      'itens/$itemId/desalocar',
      method: 'POST',
      fromJson: (json) =>
          ItemApartamento.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/itens/patrimonio/{codigo}
  Future<ItemApartamento> getItemApartamentoPorPatrimonio(String codigo) async {
    return request<ItemApartamento>(
      'itens/patrimonio/${Uri.encodeComponent(codigo)}',
      fromJson: (json) =>
          ItemApartamento.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/itens/{id}/qrcode
  Future<List<int>> getQrCodeItemApartamento(String id) async {
    final endpointName = 'itens/$id/qrcode'
        .replaceAll(RegExp(r'/+$'), '')
        .replaceAll(RegExp(r'^/+'), '');
    Uri url = Uri.parse('$baseUrl/$endpointName');
    final response = await _httpClient
        .get(url, headers: _headers(isBinaryDownload: true))
        .timeout(_timeout);

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao obter QR code (HTTP ${response.statusCode})');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (_looksLikeImageBytes(response.bodyBytes) &&
          await _isDecodableImageBytes(response.bodyBytes)) {
        return response.bodyBytes;
      }
      throw Exception('QR code retornou binário inválido para imagem.');
    }

    final decoded = jsonDecode(response.body);
    dynamic dados = decoded;
    if (decoded is Map<String, dynamic>) {
      dados = decoded['dados'] ?? decoded['data'] ?? decoded;
    }

    if (dados is String) {
      final bytes = _decodeBase64Bytes(dados, context: 'QR code item');
      if (_looksLikeImageBytes(bytes) && await _isDecodableImageBytes(bytes)) {
        return bytes;
      }
      throw Exception('QR code item não contém bytes de imagem válidos.');
    }

    if (dados is Map<String, dynamic>) {
      final base64Qr =
          dados['qrCodeBase64'] ??
          dados['base64'] ??
          dados['arquivoBase64'] ??
          dados['conteudoBase64'];
      if (base64Qr is String && base64Qr.isNotEmpty) {
        final bytes = _decodeBase64Bytes(base64Qr, context: 'QR code item');
        if (_looksLikeImageBytes(bytes) &&
            await _isDecodableImageBytes(bytes)) {
          return bytes;
        }
        throw Exception('QR code item não contém bytes de imagem válidos.');
      }
    }

    throw Exception('Formato de retorno de QR code não suportado.');
  }

  /// GET /api/QrCodeBatch/download
  Future<QrCodesLoteResult> gerarQrCodesLote({List<String>? itemIds}) async {
    final endpointName = 'QrCodeBatch/download'
        .replaceAll(RegExp(r'/+$'), '')
        .replaceAll(RegExp(r'^/+'), '');
    Uri url = Uri.parse('$baseUrl/$endpointName');
    http.Response response;
    response = await _httpClient
        .get(url, headers: _headers(isBinaryDownload: true))
        .timeout(_timeout);

    // Compatibilidade: alguns ambientes antigos ainda expõem POST.
    if (response.statusCode == 404 || response.statusCode == 405) {
      response = await _httpClient
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              if (itemIds != null && itemIds.isNotEmpty) 'itemIds': itemIds,
            }),
          )
          .timeout(_timeout);
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao gerar QR codes em lote (HTTP ${response.statusCode})',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      return QrCodesLoteResult(arquivoCompactado: response.bodyBytes);
    }

    final decoded = jsonDecode(response.body);
    dynamic dados = decoded;
    if (decoded is Map<String, dynamic>) {
      final bool? sucesso = decoded['sucesso'] as bool?;
      if (sucesso == false) {
        throw Exception(
          decoded['mensagem'] ?? 'Falha ao gerar QR codes em lote.',
        );
      }
      dados = decoded['dados'] ?? decoded['data'] ?? decoded;
    }

    final arquivos = <String, List<int>>{};

    if (dados is String && dados.isNotEmpty) {
      final bytes = _decodeBase64Bytes(dados, context: 'QR code lote');
      if (_looksLikeZipBytes(bytes)) {
        return QrCodesLoteResult(arquivoCompactado: bytes);
      }
      if (_looksLikeImageBytes(bytes)) {
        arquivos['qrcode_lote.png'] = bytes;
        return QrCodesLoteResult(arquivosPng: arquivos);
      }
      throw Exception(
        'QR code lote retornou dados base64 sem formato suportado.',
      );
    }

    if (dados is List) {
      for (final item in dados.whereType<Map<String, dynamic>>()) {
        final base64Str =
            item['base64'] ??
            item['qrCodeBase64'] ??
            item['arquivoBase64'] ??
            item['conteudoBase64'];
        if (base64Str is String && base64Str.isNotEmpty) {
          final nome =
              (item['nomeArquivo'] ??
                      item['codigoPatrimonio'] ??
                      item['codigoIdentificador'] ??
                      item['id'] ??
                      'qrcode')
                  .toString();
          final bytes = _decodeBase64Bytes(
            base64Str,
            context: 'QR code lote item',
          );
          if (_looksLikeImageBytes(bytes)) {
            arquivos['$nome.png'] = bytes;
          }
        }
      }
      return QrCodesLoteResult(arquivosPng: arquivos);
    }

    if (dados is Map<String, dynamic>) {
      final arquivoBase64 = dados['arquivoBase64'] ?? dados['zipBase64'];
      if (arquivoBase64 is String && arquivoBase64.isNotEmpty) {
        final nomeArquivo = (dados['nomeArquivo'] ?? 'qrcodes_lote.zip')
            .toString()
            .toLowerCase();
        final bytes = _decodeBase64Bytes(
          arquivoBase64,
          context: 'Arquivo de QR code lote',
        );
        if (nomeArquivo.endsWith('.zip')) {
          return QrCodesLoteResult(arquivoCompactado: bytes);
        }
        if (_looksLikeZipBytes(bytes)) {
          return QrCodesLoteResult(arquivoCompactado: bytes);
        }
        if (_looksLikeImageBytes(bytes)) {
          arquivos[nomeArquivo] = bytes;
          return QrCodesLoteResult(arquivosPng: arquivos);
        }
        throw Exception('Arquivo de QR code lote sem formato suportado.');
      }

      final lista = dados['qrcodes'] ?? dados['arquivos'] ?? dados['itens'];
      if (lista is List) {
        for (final item in lista.whereType<Map<String, dynamic>>()) {
          final base64Str =
              item['base64'] ??
              item['qrCodeBase64'] ??
              item['arquivoBase64'] ??
              item['conteudoBase64'];
          if (base64Str is String && base64Str.isNotEmpty) {
            final nome =
                (item['nomeArquivo'] ??
                        item['codigoPatrimonio'] ??
                        item['codigoIdentificador'] ??
                        item['id'] ??
                        'qrcode')
                    .toString();
            final bytes = _decodeBase64Bytes(
              base64Str,
              context: 'QR code lote item',
            );
            if (_looksLikeImageBytes(bytes)) {
              arquivos['$nome.png'] = bytes;
            }
          }
        }
        return QrCodesLoteResult(arquivosPng: arquivos);
      }

      for (final entry in dados.entries) {
        if (entry.value is String) {
          try {
            final bytes = _decodeBase64Bytes(
              entry.value as String,
              context: 'QR code lote map',
            );
            if (_looksLikeImageBytes(bytes)) {
              arquivos['${entry.key}.png'] = bytes;
            }
          } catch (_) {}
        }
      }
      if (arquivos.isNotEmpty) {
        return QrCodesLoteResult(arquivosPng: arquivos);
      }
    }

    throw Exception('Formato de retorno do lote de QR codes não suportado.');
  }

  /// GET /api/qrcodebatch/opcoes
  Future<QrCodeBatchOpcoesDto> getQrCodesBatchOpcoes() async {
    try {
      return await request<QrCodeBatchOpcoesDto>(
        'qrcodebatch/opcoes',
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return QrCodeBatchOpcoesDto.fromJson(json);
          }
          if (json is Map) {
            return QrCodeBatchOpcoesDto.fromJson(
              Map<String, dynamic>.from(json),
            );
          }
          return QrCodeBatchOpcoesDto.fromJson(const <String, dynamic>{});
        },
      );
    } catch (e) {
      AppLogger.warning(
        'ApiService',
        'Falha ao carregar opcoes de QR batch. Usando fallback local.',
        e,
      );
      return QrCodeBatchOpcoesDto.fromJson(const <String, dynamic>{});
    }
  }

  /// GET /api/qrcodebatch/relatorio
  Future<QrCodeBatchRelatorioDto> getQrCodesRelatorio({String? estado}) async {
    final estadoParam = (estado != null && estado.trim().isNotEmpty)
        ? normalizeEstadoForApi(estado.trim())
        : null;
    try {
      return await request<QrCodeBatchRelatorioDto>(
        'qrcodebatch/relatorio',
        queryParams: {'estado': ?estadoParam},
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return QrCodeBatchRelatorioDto.fromJson(json);
          }
          if (json is Map) {
            return QrCodeBatchRelatorioDto.fromJson(
              Map<String, dynamic>.from(json),
            );
          }
          throw Exception('Formato invalido para relatorio de QR codes.');
        },
      );
    } catch (e) {
      AppLogger.warning(
        'ApiService',
        'Falha ao carregar relatorio de QR batch. Montando fallback local.',
        e,
      );

      final estadoFiltro = estadoParam != null
          ? estadoFromString(estadoParam)
          : null;
      final itens = await getTodosItensApartamento();
      final filtrados = itens.where((item) {
        if (estadoFiltro == null) return true;
        final estadoItem = estadoFromString(
          item.estadoAtual ?? item.estadoDesgaste ?? item.status ?? '',
        );
        return estadoItem == estadoFiltro;
      }).toList();

      final agrupadoPorEstado = <String, int>{};
      int quantidadeTotal = 0;

      final itensDto = filtrados.map((item) {
        final hasApartamento =
            item.apartamentoId != null && item.apartamentoId!.trim().isNotEmpty;
        final estadoNormalizado = normalizeEstadoForApi(
          item.estadoAtual ?? item.estadoDesgaste ?? item.status ?? '',
          hasApartamento: hasApartamento,
        );
        agrupadoPorEstado[estadoNormalizado] =
            (agrupadoPorEstado[estadoNormalizado] ?? 0) + 1;

        final qtd = item.quantidade ?? 1;
        quantidadeTotal += qtd;

        return QrCodeBatchItemDto(
          id: item.id,
          codigoPatrimonio:
              item.codigoPatrimonio ?? item.codigoIdentificador ?? '',
          nome: item.nome,
          tipo: item.tipo ?? '',
          quantidade: qtd,
          estado: estadoNormalizado,
          apartamentoNumero: '',
          apartamentoBloco: '',
          qrCodeBase64: null,
        );
      }).toList();

      return QrCodeBatchRelatorioDto(
        totalItens: itensDto.length,
        dataRelatorio: DateTime.now(),
        agrupadoPorEstado: agrupadoPorEstado,
        quantidade: quantidadeTotal,
        itens: itensDto,
      );
    }
  }

  /// GET /api/qrcodebatch/download?estado={estado}&formato={formato}
  Future<List<int>> downloadQrCodesBatch({
    String? estado,
    String formato = 'svg',
  }) async {
    final estadoParam = (estado != null && estado.trim().isNotEmpty)
        ? normalizeEstadoForApi(estado.trim())
        : null;
    final endpointName = 'qrcodebatch/download'
        .replaceAll(RegExp(r'/+$'), '')
        .replaceAll(RegExp(r'^/+'), '');
    Uri url = Uri.parse('$baseUrl/$endpointName');
    final query = <String, String>{
      'estado': ?estadoParam,
      if (formato.trim().isNotEmpty) 'formato': formato.trim(),
    };
    if (query.isNotEmpty) {
      url = url.replace(queryParameters: query);
    }

    final response = await _httpClient
        .get(url, headers: _headers(isBinaryDownload: true))
        .timeout(_timeout);

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Sessao expirada. Faca login novamente.');
    }

    if (response.statusCode == 404 || response.statusCode == 405) {
      final fallback = await gerarQrCodesLote();
      if (fallback.arquivoCompactado != null &&
          fallback.arquivoCompactado!.isNotEmpty) {
        return fallback.arquivoCompactado!;
      }
      throw Exception(
        'Endpoint de download de QR batch indisponivel no backend atual.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao baixar QR codes em lote (HTTP ${response.statusCode})',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      return response.bodyBytes;
    }

    final decoded = jsonDecode(response.body);
    dynamic dados = decoded;
    if (decoded is Map<String, dynamic>) {
      final bool? sucesso = decoded['sucesso'] as bool?;
      if (sucesso == false) {
        throw Exception(
          decoded['mensagem'] ?? 'Falha ao baixar QR codes em lote.',
        );
      }
      dados = decoded['dados'] ?? decoded['data'] ?? decoded;
    }

    if (dados is String && dados.trim().isNotEmpty) {
      return _decodeBase64Bytes(dados, context: 'Download de QR code lote');
    }

    if (dados is Map) {
      final map = Map<String, dynamic>.from(dados);
      final base64Arquivo =
          map['arquivoBase64'] ??
          map['zipBase64'] ??
          map['base64'] ??
          map['conteudoBase64'];
      if (base64Arquivo is String && base64Arquivo.trim().isNotEmpty) {
        return _decodeBase64Bytes(
          base64Arquivo,
          context: 'Download de QR code lote',
        );
      }
    }

    throw Exception(
      'Formato de retorno do download de QR codes nao suportado.',
    );
  }

  /// GET /api/qrcodebatch/html-impressao?estado={estado}
  Future<String> getQrCodesHtmlImpressao({String? estado}) async {
    final estadoParam = (estado != null && estado.trim().isNotEmpty)
        ? normalizeEstadoForApi(estado.trim())
        : null;
    try {
      return await request<String>(
        'qrcodebatch/html-impressao',
        queryParams: {'estado': ?estadoParam},
        fromJson: (json) {
          if (json is String) return json;
          if (json is Map<String, dynamic>) {
            final html =
                json['html'] ??
                json['conteudoHtml'] ??
                json['conteudo'] ??
                json['markup'];
            if (html is String && html.isNotEmpty) return html;
          } else if (json is Map) {
            final map = Map<String, dynamic>.from(json);
            final html =
                map['html'] ??
                map['conteudoHtml'] ??
                map['conteudo'] ??
                map['markup'];
            if (html is String && html.isNotEmpty) return html;
          }
          throw Exception(
            'Formato de retorno de HTML para impressao nao suportado.',
          );
        },
      );
    } catch (e) {
      AppLogger.warning(
        'ApiService',
        'Falha ao obter HTML de impressao. Gerando fallback local.',
        e,
      );
      final relatorio = await getQrCodesRelatorio(estado: estadoParam);
      return _buildQrBatchHtmlFallback(relatorio, estado: estadoParam);
    }
  }

  String _buildQrBatchHtmlFallback(
    QrCodeBatchRelatorioDto relatorio, {
    String? estado,
  }) {
    final filtro = (estado != null && estado.trim().isNotEmpty)
        ? estado.trim()
        : 'todos';
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="pt-BR">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    );
    buffer.writeln('<title>QR Codes em lote</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'body{font-family:Arial,sans-serif;margin:24px;color:#222;}',
    );
    buffer.writeln('h1{font-size:20px;margin-bottom:4px;}');
    buffer.writeln('p{margin:2px 0 10px;}');
    buffer.writeln(
      'table{width:100%;border-collapse:collapse;margin-top:16px;}',
    );
    buffer.writeln(
      'th,td{border:1px solid #ddd;padding:8px;font-size:12px;text-align:left;}',
    );
    buffer.writeln('th{background:#f5f5f5;}');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<h1>Relatorio de QR Codes em Lote</h1>');
    buffer.writeln(
      '<p><strong>Filtro estado:</strong> ${_escapeHtml(filtro)}</p>',
    );
    buffer.writeln(
      '<p><strong>Total de itens:</strong> ${relatorio.totalItens}</p>',
    );
    buffer.writeln(
      '<p><strong>Quantidade total:</strong> ${relatorio.quantidade}</p>',
    );
    buffer.writeln('<table>');
    buffer.writeln(
      '<thead><tr><th>Nome</th><th>Patrimonio</th><th>Tipo</th><th>Estado</th><th>Apartamento</th></tr></thead>',
    );
    buffer.writeln('<tbody>');
    for (final item in relatorio.itens) {
      final apto = '${item.apartamentoNumero}/${item.apartamentoBloco}'.trim();
      buffer.writeln(
        '<tr><td>${_escapeHtml(item.nome)}</td><td>${_escapeHtml(item.codigoPatrimonio)}</td><td>${_escapeHtml(item.tipo)}</td><td>${_escapeHtml(item.estado)}</td><td>${_escapeHtml(apto)}</td></tr>',
      );
    }
    buffer.writeln('</tbody>');
    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  List<int> _decodeBase64Bytes(String raw, {required String context}) {
    var value = raw.trim();
    final commaIndex = value.indexOf(',');
    if (value.startsWith('data:') && commaIndex != -1) {
      value = value.substring(commaIndex + 1);
    }
    value = value.replaceAll(RegExp(r'\s+'), '');
    try {
      return base64Decode(value);
    } on FormatException catch (e) {
      throw Exception('$context inválido: base64 malformado (${e.message})');
    }
  }

  bool _looksLikeZipBytes(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }

  bool _looksLikeImageBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    final isGif =
        bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61;
    final isWebp =
        bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    final isBmp = bytes[0] == 0x42 && bytes[1] == 0x4D;
    return isPng || isJpeg || isGif || isWebp || isBmp;
  }

  Future<bool> _isDecodableImageBytes(List<int> bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/itens
  Future<ItemApartamento> criarItemApartamento(
    CriarItemApartamentoRequest request,
  ) async {
    debugPrint('[API] criarItemApartamento - Body: ${request.toJson()}');
    debugPrint(
      '[API] criarItemApartamento - Quantidade: ${request.quantidade}',
    );
    return this.request<ItemApartamento>(
      'itens',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => ItemApartamento.fromJson(json),
    );
  }

  /// PUT /api/itens/{id}/estado - Atualiza estado do item
  /// A API atual não possui PUT geral, apenas PUT de estado.
  Future<void> atualizarItemApartamento(
    String id,
    Map<String, dynamic> dados,
  ) async {
    // Usa o endpoint de atualizar estado se houver estadoAtual
    final novoEstado = dados['estadoAtual'] ?? dados['estado'];
    if (novoEstado != null) {
      return request<void>(
        'itens/$id/estado',
        method: 'PUT',
        body: {'novoEstado': novoEstado},
        fromJson: (_) {},
      );
    }
    // Se não houver estado, tenta o PUT padrão (pode falhar)
    return request<void>(
      'itens/$id',
      method: 'PUT',
      body: dados,
      fromJson: (_) {},
    );
  }

  /// DELETE /api/itens/{id}
  Future<void> deletarItemApartamento(String id) async {
    return request<void>(
      'itens/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  /// POST /api/itens (chamado em sequência para bulk)
  /// A API atual não possui endpoint bulk, cria um por um.
  Future<List<ItemApartamento>> criarItensApartamentoBulk(
    List<CriarItemApartamentoRequest> requests,
  ) async {
    final results = <ItemApartamento>[];
    for (final req in requests) {
      try {
        final item = await criarItemApartamento(req);
        results.add(item);
      } catch (e) {
        debugPrint('❌ Erro ao criar item: $e');
        // Continua com os próximos itens
      }
    }
    return results;
  }

  // ==================== ITEM APARTAMENTO MOVIMENTAÇÃO ====================

  /// POST /api/itens/{id}/alocar - Transfere item para outro apartamento
  Future<void> transferirItemApartamento(Map<String, dynamic> body) async {
    final itemId = body['itemApartamentoId']?.toString();
    final apartamentoDestinoId = body['apartamentoDestinoId']?.toString();
    if (itemId == null || apartamentoDestinoId == null) {
      throw Exception('itemApartamentoId e apartamentoDestinoId são obrigatórios');
    }
    final transferBody = <String, dynamic>{
      'apartamentoId': apartamentoDestinoId,
    };
    if (body['novoEstado'] != null) transferBody['novoEstado'] = body['novoEstado'];
    if (body['motivo'] != null) transferBody['motivo'] = body['motivo'];
    if (body['observacoes'] != null) transferBody['observacoes'] = body['observacoes'];
    return request<void>(
      'itens/$itemId/alocar',
      method: 'POST',
      body: transferBody,
      fromJson: (_) {},
    );
  }

  /// PUT /api/itens/{id}/estado - Atualiza estado do item
  Future<void> atualizarEstadoItemApartamento(Map<String, dynamic> body) async {
    final itemId = body['itemApartamentoId']?.toString();
    final novoEstado = body['novoEstado']?.toString();
    if (itemId == null || novoEstado == null) {
      throw Exception('itemApartamentoId e novoEstado são obrigatórios');
    }
    final estadoBody = <String, dynamic>{
      'novoEstado': novoEstado,
    };
    if (body['motivo'] != null) estadoBody['motivo'] = body['motivo'];
    if (body['observacoes'] != null) estadoBody['observacoes'] = body['observacoes'];
    return request<void>(
      'itens/$itemId/estado',
      method: 'PUT',
      body: estadoBody,
      fromJson: (_) {},
    );
  }

  /// GET /api/itens/{itemId}/historico
  Future<List<dynamic>> getHistoricoMovimentacao(String itemId) async {
    return request<List<dynamic>>(
      'itens/$itemId/historico',
      fromJson: (json) => (json as List<dynamic>),
    );
  }

  // ==================== EXPORTAÇÃO ====================

  /// GET /api/Exportacao/solicitacoes/excel
  /// Retorna bytes do arquivo Excel para download
  Future<List<int>> exportarSolicitacoesExcel({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        'status': ?status,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/solicitacoes/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/solicitacoes/pdf
  /// Retorna bytes do arquivo PDF para download
  Future<List<int>> exportarSolicitacoesPdf({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        'status': ?status,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/solicitacoes/pdf';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar PDF (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/apartamentos/excel
  /// Exporta lista de apartamentos em Excel
  Future<List<int>> exportarApartamentosExcel({
    String? bloco,
    String? estado,
  }) async {
    try {
      final query = <String, String>{
        'bloco': ?bloco,
        'estado': ?estado,
      };

      var endpoint = 'Exportacao/apartamentos/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception(
        'Erro ao exportar apartamentos (HTTP ${resp.statusCode})',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/moradores/excel
  /// Exporta lista de moradores em Excel
  Future<List<int>> exportarMoradoresExcel({
    String? apartamentoId,
    String? status,
  }) async {
    try {
      final query = <String, String>{
        'apartamentoId': ?apartamentoId,
        'status': ?status,
      };

      var endpoint = 'Exportacao/moradores/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar moradores (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/usuarios/excel
  /// Exporta lista de usuários em Excel
  Future<List<int>> exportarUsuariosExcel({String? tipo, String? ativo}) async {
    try {
      final query = <String, String>{
        'tipo': ?tipo,
        'ativo': ?ativo,
      };

      var endpoint = 'Exportacao/usuarios/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar usuários (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/exportacao/ativos/excel
  /// Exporta lista de ativos em Excel com filtros opcionais
  /// Filtros: estado, tipo, apartamentoId
  Future<List<int>> exportarAtivosExcel({
    String? estado,
    String? tipo,
    String? apartamentoId,
  }) async {
    try {
      final query = <String, String>{
        'estado': ?estado,
        'tipo': ?tipo,
        'apartamentoId': ?apartamentoId,
      };

      var endpoint = 'Exportacao/ativos/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar ativos (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/relatorio-completo/excel
  /// Exporta relatório completo (Solicitações + Apartamentos + Moradores)
  Future<List<int>> exportarRelatorioCompletoExcel({
    String? solicitacaoStatus,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        'solicitacaoStatus': ?solicitacaoStatus,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/relatorio-completo/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar relatório (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/agendamentos/excel
  /// Exporta agendamentos de manutenção em Excel
  Future<List<int>> exportarAgendamentosExcel({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        'status': ?status,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/agendamentos/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar agendamentos (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/manutencoes-preventivas/excel
  /// Exporta manutenções preventivas em Excel
  Future<List<int>> exportarManutencoesPreventivasExcel({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        'status': ?status,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/manutencoes-preventivas/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar manutenções preventivas (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/sms/excel
  /// Exporta histórico de SMS em Excel (credenciais protegidas)
  Future<List<int>> exportarSmsExcel({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/sms/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar SMS (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/kpi/excel
  /// Exporta KPIs em Excel com múltiplas abas
  Future<List<int>> exportarKpiExcel({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/kpi/excel';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar KPIs (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/Exportacao/kpi/pdf
  /// Exporta KPIs em PDF visual
  Future<List<int>> exportarKpiPdf({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final query = <String, String>{
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      };

      var endpoint = 'Exportacao/kpi/pdf';
      Uri url = Uri.parse('$baseUrl/$endpoint');
      if (query.isNotEmpty) url = url.replace(queryParameters: query);

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar KPIs PDF (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  // ==================== MORADORES ====================

  /// GET /api/moradores
  Future<List<Morador>> getMoradores({String? apartamentoId}) async {
    return request<List<Morador>>(
      'moradores',
      queryParams: {'apartamentoId': ?apartamentoId},
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Morador.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/moradores/{id}
  Future<Morador> getMorador(String id) async {
    return request<Morador>(
      'moradores/$id',
      fromJson: (json) => Morador.fromJson(json),
    );
  }

  /// POST /api/moradores
  Future<Morador> criarMorador(Map<String, dynamic> dados) async {
    return request<Morador>(
      'moradores',
      method: 'POST',
      body: dados,
      fromJson: (json) => Morador.fromJson(json),
    );
  }

  /// PUT /api/moradores/{id}
  Future<MoradorDto> atualizarMorador(
    String id,
    Map<String, dynamic> dados,
  ) async {
    return request<MoradorDto>(
      'moradores/$id',
      method: 'PUT',
      body: dados,
      fromJson: (json) => MoradorDto.fromJson(json),
    );
  }

  /// DELETE /api/moradores/{id}
  Future<MoradorDto> deletarMorador(String id) async {
    return request<MoradorDto>(
      'moradores/$id',
      method: 'DELETE',
      fromJson: (json) => MoradorDto.fromJson(json),
    );
  }

  /// POST /api/moradores/vincular (vincular morador ao apartamento)
  Future<MoradorDto> vincularMorador(VincularMoradorRequest request) async {
    return this.request<MoradorDto>(
      'moradores/vincular',
      method: 'POST',
      body: request.toJson(),
      fromJson: (json) => MoradorDto.fromJson(json),
    );
  }

  // ==================== HISTÓRICO DE OCUPAÇÃO ====================

  /// GET /api/historicoocupacao/apartamento/{apartamentoId} (detalhado)
  Future<List<HistoricoOcupacaoResumo>>
  getHistoricoOcupacaoDetalhadoApartamento(String apartamentoId) async {
    return request<List<HistoricoOcupacaoResumo>>(
      'historicoocupacao/apartamento/$apartamentoId',
      method: 'GET',
      fromJson: (json) {
        // Backend pode retornar lista direta OU objeto paginado
        if (json is List) {
          return json
              .map((item) => HistoricoOcupacaoResumo.fromJson(item))
              .toList();
        } else if (json is Map && json.containsKey('items')) {
          // Resposta paginada: extrair array 'items'
          final items = json['items'] as List<dynamic>;
          return items
              .map((item) => HistoricoOcupacaoResumo.fromJson(item))
              .toList();
        }
        return <HistoricoOcupacaoResumo>[];
      },
    );
  }

  /// GET /api/historicoocupacao/morador/{moradorId} (detalhado)
  Future<List<HistoricoOcupacaoResumo>> getHistoricoOcupacaoDetalhadoMorador(
    String moradorId,
  ) async {
    return request<List<HistoricoOcupacaoResumo>>(
      'historicoocupacao/morador/$moradorId',
      method: 'GET',
      fromJson: (json) {
        // Backend pode retornar lista direta OU objeto paginado
        if (json is List) {
          return json
              .map((item) => HistoricoOcupacaoResumo.fromJson(item))
              .toList();
        } else if (json is Map && json.containsKey('items')) {
          // Resposta paginada: extrair array 'items'
          final items = json['items'] as List<dynamic>;
          return items
              .map((item) => HistoricoOcupacaoResumo.fromJson(item))
              .toList();
        }
        return <HistoricoOcupacaoResumo>[];
      },
    );
  }

  /// POST /api/historicoocupacao/registrar-saida
  Future<HistoricoOcupacao> registrarSaidaHistorico(
    String moradorId, {
    String? motivoSaida,
  }) async {
    return request<HistoricoOcupacao>(
      'historicoocupacao/registrar-saida',
      method: 'POST',
      body: {
        'moradorId': moradorId,
        'motivoSaida': ?motivoSaida,
      },
      fromJson: (json) => HistoricoOcupacao.fromJson(json),
    );
  }

  /// GET /api/historicoocupacao/{id}
  Future<HistoricoOcupacao> getHistoricoOcupacaoById(String id) async {
    return request<HistoricoOcupacao>(
      'historicoocupacao/$id',
      method: 'GET',
      fromJson: (json) => HistoricoOcupacao.fromJson(json),
    );
  }

  // ==================== USUÁRIOS ====================

  /// GET /api/usuarios
  Future<List<Usuario>> getUsuarios({String? tipo}) async {
    return request<List<Usuario>>(
      'usuarios',
      queryParams: {'tipo': ?tipo},
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Usuario.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/usuarios/me
  Future<Usuario> getPerfilAtual() async {
    return request<Usuario>(
      'usuarios/me',
      fromJson: (json) => Usuario.fromJson(json),
    );
  }

  // ==================== NOTIFICAÇÕES ====================

  /// GET /api/notificacoes/resumo
  Future<NotificacaoResumoDto> getNotificacoesResumo() async {
    return request<NotificacaoResumoDto>(
      'notificacoes/resumo',
      fromJson: (json) => NotificacaoResumoDto.fromJson(json),
    );
  }

  /// GET /api/notificacoes/{id}
  Future<Notificacao> getNotificacao(String id) async {
    return request<Notificacao>(
      'notificacoes/$id',
      fromJson: (json) => Notificacao.fromJson(json),
    );
  }

  /// POST /api/notificacoes
  /// Create a new notification for a user
  Future<Notificacao> criarNotificacao({
    required String usuarioId,
    required String titulo,
    required String mensagem,
    required String tipo, // TipoNotificacao value
  }) async {
    final body = {
      'usuarioId': usuarioId,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
    };

    return request<Notificacao>(
      'notificacoes',
      method: 'POST',
      body: body,
      fromJson: (json) => Notificacao.fromJson(json),
    );
  }

  // ==================== HISTÓRICO OCUPAÇÃO ====================

  /// GET /api/historicoocupacao/apartamento/{apartamentoId}
  Future<List<HistoricoOcupacaoResumo>> getHistoricoApartamento(
    String apartamentoId,
  ) async {
    return request<List<HistoricoOcupacaoResumo>>(
      'historicoocupacao/apartamento/$apartamentoId',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => HistoricoOcupacaoResumo.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/historicoocupacao/morador/{moradorId}
  Future<List<HistoricoOcupacaoResumo>> getHistoricoMorador(
    String moradorId,
  ) async {
    return request<List<HistoricoOcupacaoResumo>>(
      'historicoocupacao/morador/$moradorId',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => HistoricoOcupacaoResumo.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/historicoocupacao/{id}
  Future<HistoricoOcupacaoDetalhado> getHistoricoDetalhado(String id) async {
    return request<HistoricoOcupacaoDetalhado>(
      'historicoocupacao/$id',
      fromJson: (json) => HistoricoOcupacaoDetalhado.fromJson(json),
    );
  }

  // ==================== USUARIOS ====================

  /// POST /api/usuarios - Create new user by admin/sindico
  /// Admin only - creates Funcionário, Síndico, Portaria, Morador, or other roles
  /// Note: Backend does not support automatic SMS sending. Use enviarSmsMassa() after creation if needed.
  Future<Usuario> criarFuncionario({
    required String nome,
    required String nomeLogin,
    required String telefone,
    required String tipo,
    required String senha,
    bool enviarSMS = false, // Deprecated - kept for backward compatibility
  }) async {
    final body = {
      'nome': nome,
      'nomeLogin': nomeLogin,
      'telefone': telefone,
      'Tipo': tipo, // Backend expects 'Tipo' (capital T)
      'senha': senha,
      'ativo': true,
    };

    debugPrint('🔵 API POST: usuarios');
    debugPrint('📦 Body: $body');

    final resultado = await request<Usuario>(
      'usuarios',
      method: 'POST',
      body: body,
      fromJson: (json) => Usuario.fromJson(json),
    );

    debugPrint('✅ Usuário criado: ${resultado.nome}');
    return resultado;
  }

  /// GET /api/usuarios/funcionarios - Get all employees (Funcionarios)
  /// GET /api/usuarios/funcionarios - Get all employees (Funcionarios)
  /// Fallback: Use usuarios?tipo=Funcionario if specific endpoint not available
  Future<List<Usuario>> listarFuncionarios() async {
    try {
      return await request<List<Usuario>>(
        'usuarios/funcionarios',
        fromJson: (json) => (json as List<dynamic>)
            .map((item) => Usuario.fromJson(item))
            .toList(),
      );
    } catch (e) {
      // Fallback: if /funcionarios endpoint doesn't exist, filter by type
      debugPrint(
        '⚠️ Endpoint /funcionarios não encontrado, usando filtro por tipo',
      );
      return await listarUsuariosPorTipo('Funcionario');
    }
  }

  /// GET /api/usuarios?tipo=Funcionario - Get users by type
  Future<List<Usuario>> listarUsuariosPorTipo(String tipo) async {
    return request<List<Usuario>>(
      'usuarios?tipo=$tipo',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Usuario.fromJson(item))
          .toList(),
    );
  }

  /// PUT /api/usuarios/{id}/ativar - Activate user
  Future<bool> ativarUsuario(String usuarioId) async {
    await request<dynamic>(
      'usuarios/$usuarioId/ativar',
      method: 'PUT',
      fromJson: (json) => null,
    );
    return true;
  }

  /// PUT /api/usuarios/{id}/desativar - Deactivate user
  Future<bool> desativarUsuario(String usuarioId) async {
    await request<dynamic>(
      'usuarios/$usuarioId/desativar',
      method: 'PUT',
      fromJson: (json) => null,
    );
    return true;
  }

  // ==================== SMS MASSA ====================

  /// GET /api/smsmassa/destinatarios - List available SMS recipients
  /// Optional filter by user types (roles)
  Future<List<Usuario>> getDestinatariosSmsMassa({List<String>? tipos}) async {
    String endpoint = 'smsmassa/destinatarios';

    if (tipos != null && tipos.isNotEmpty) {
      final tiposQuery = tipos.map((t) => 'tipos=$t').join('&');
      endpoint = '$endpoint?$tiposQuery';
    }

    return request<List<Usuario>>(
      endpoint,
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => Usuario.fromJson(item))
          .toList(),
    );
  }

  /// POST /api/smsmassa/enviar - Send SMS to multiple users
  /// Can filter by user types or specific user IDs
  Future<Map<String, dynamic>> enviarSmsMassa({
    required String mensagem,
    List<String>? tiposUsuario,
    List<String>? usuarioIds,
    bool enviarNotificacaoApp = true,
    String? tituloNotificacao,
  }) async {
    final body = {
      'mensagem': mensagem,
      'enviarNotificacaoApp': enviarNotificacaoApp,
      'tiposUsuario': ?tiposUsuario,
      'usuarioIds': ?usuarioIds,
      'tituloNotificacao': ?tituloNotificacao,
    };

    return request<Map<String, dynamic>>(
      'smsmassa/enviar',
      method: 'POST',
      body: body,
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// GET /api/smsmassa/historico - Get SMS sending history (paginated)
  Future<Map<String, dynamic>> getHistoricoSmsMassa({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<Map<String, dynamic>>(
      'smsmassa/historico?pageNumber=$pageNumber&pageSize=$pageSize',
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// GET /api/smsmassa/historico/{id} - Get details of a specific SMS sending
  Future<Map<String, dynamic>> getHistoricoSmsMassaDetalhes(String id) async {
    return request<Map<String, dynamic>>(
      'smsmassa/historico/$id',
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// DELETE /api/smsmassa/limpar-credenciais
  /// Elimina todos os registros de SMS de credenciais/OTP da base de dados
  /// Apenas para Administrador
  /// Retorna a quantidade de registros eliminados
  Future<int> limparSmsCredenciais() async {
    final result = await request<Map<String, dynamic>>(
      'smsmassa/limpar-credenciais',
      method: 'DELETE',
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );
    return result['quantidadeEliminada'] as int? ?? 0;
  }

  // ========================================
  // NOVOS MÉTODOS - Histórico de Ocupação
  // ========================================
  // Production-ready methods for occupation history
  // Fully tested with .NET 8 backend
  // https://localhost:7068/api/historicoocupacao/*

  /// GET /api/historicoocupacao - List occupation history (paginated, resumido)
  ///
  /// Returns simplified view for list display
  /// Supports filtering by apartment, resident, change type
  ///
  /// Example:
  /// ```dart
  /// final result = await ApiService().getHistoricoOcupacaoPaginado(
  ///   apartamentoId: 'apt-123',
  ///   pageNumber: 1,
  ///   pageSize: 20,
  /// );
  /// ```
  Future<PaginatedHistoricoResponse<HistoricoOcupacaoResumoDto>>
  getHistoricoOcupacaoPaginado({
    String? apartamentoId,
    String? moradorId,
    String? tipoMudanca,
    DateTime? dataInicio,
    DateTime? dataFim,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'apartamentoId': ?apartamentoId,
      'moradorId': ?moradorId,
      'tipoMudanca': ?tipoMudanca,
      if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
      if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
    };

    return request<PaginatedHistoricoResponse<HistoricoOcupacaoResumoDto>>(
      'historicoocupacao',
      queryParams: queryParams,
      fromJson: (json) =>
          PaginatedHistoricoResponse<HistoricoOcupacaoResumoDto>.fromJson(
            json,
            (item) => HistoricoOcupacaoResumoDto.fromJson(item),
          ),
    );
  }

  /// GET /api/historicoocupacao/detalhado - Detailed occupation history (paginated)
  ///
  /// Returns full details including auditing information
  /// Use for detail screens and reporting
  ///
  /// Example:
  /// ```dart
  /// final result = await ApiService().getHistoricoOcupacaoDetalhadoPaginado(
  ///   apartamentoId: 'apt-123',
  ///   pageNumber: 1,
  ///   pageSize: 10,
  /// );
  /// ```
  Future<PaginatedHistoricoResponse<HistoricoOcupacaoDetalhadoDto>>
  getHistoricoOcupacaoDetalhadoPaginado({
    String? apartamentoId,
    String? moradorId,
    String? tipoMudanca,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? ativo,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'apartamentoId': ?apartamentoId,
      'moradorId': ?moradorId,
      'tipoMudanca': ?tipoMudanca,
      if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
      if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      if (ativo != null) 'ativo': ativo.toString(),
    };

    return request<PaginatedHistoricoResponse<HistoricoOcupacaoDetalhadoDto>>(
      'historicoocupacao/detalhado',
      queryParams: queryParams,
      fromJson: (json) =>
          PaginatedHistoricoResponse<HistoricoOcupacaoDetalhadoDto>.fromJson(
            json,
            (item) => HistoricoOcupacaoDetalhadoDto.fromJson(item),
          ),
    );
  }

  /// GET /api/historicoocupacao/apartamento/{apartamentoId} - Get apartment occupation history (paginated)
  ///
  /// Convenience method for apartment detail screen
  /// Automatically uses resumido view for performance
  ///
  /// Example:
  /// ```dart
  /// final historico = await ApiService().getHistoricoApartamentoPaginado(
  ///   'apt-123',
  ///   pageSize: 50,
  /// );
  /// ```
  Future<PaginatedHistoricoResponse<HistoricoOcupacaoResumoDto>>
  getHistoricoApartamentoPaginado(
    String apartamentoId, {
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return getHistoricoOcupacaoPaginado(
      apartamentoId: apartamentoId,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  /// GET /api/historicoocupacao/morador/{moradorId} - Get resident occupation history (paginated)
  ///
  /// Convenience method to see all apartments a resident has lived in
  ///
  /// Example:
  /// ```dart
  /// final historico = await ApiService().getHistoricoMoradorPaginado('m-456');
  /// ```
  Future<PaginatedHistoricoResponse<HistoricoOcupacaoResumoDto>>
  getHistoricoMoradorPaginado(
    String moradorId, {
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return getHistoricoOcupacaoPaginado(
      moradorId: moradorId,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  // ==================== AGENDAMENTOS MANUTENÇÃO ====================

  /// GET /api/agendamentos
  /// Lista todos os agendamentos de manutenção
  /// Filtros: status, apartamentoId
  /// Paginação: pageNumber, pageSize
  Future<List<AgendamentoMaintenanceDto>> getAgendamentos({
    String? status,
    String? apartamentoId,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<List<AgendamentoMaintenanceDto>>(
      'agendamentos',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'status': ?status,
        'apartamentoId': ?apartamentoId,
      },
      fromJson: (json) {
        final lista = (json is Map<String, dynamic> && json['items'] is List)
            ? json['items'] as List
            : json as List<dynamic>;
        return lista
            .map((item) => AgendamentoMaintenanceDto.fromJson(item))
            .toList();
      },
    );
  }

  /// GET /api/agendamentos/{id}
  /// Obtém agendamento específico
  Future<AgendamentoMaintenanceDto> getAgendamento(String id) async {
    return request<AgendamentoMaintenanceDto>(
      'agendamentos/$id',
      method: 'GET',
      fromJson: (json) => AgendamentoMaintenanceDto.fromJson(json),
    );
  }

  /// POST /api/agendamentos
  /// Cria novo agendamento
  /// Permissão: Admin/Funcionário
  Future<AgendamentoMaintenanceDto> criarAgendamento({
    required String titulo,
    required String descricao,
    required String apartamentoId,
    required String responsavelTecnicoId,
    required DateTime dataAgendada,
    String? solicitacaoId,
    String? observacoes,
  }) async {
    return request<AgendamentoMaintenanceDto>(
      'agendamentos',
      method: 'POST',
      body: {
        'titulo': titulo,
        'descricao': descricao,
        'apartamentoId': apartamentoId,
        'responsavelTecnicoId': responsavelTecnicoId,
          'dataAgendada': toBackendUtcIsoString(dataAgendada),
        'solicitacaoId': ?solicitacaoId,
        'observacoes': ?observacoes,
      },
      fromJson: (json) => AgendamentoMaintenanceDto.fromJson(json),
    );
  }

  /// PUT /api/agendamentos/{id}/responder
  /// Morador responde à solicitação de agendamento
  /// Pode aceitar ou rejeitar
  Future<void> responderAgendamento(
    String id, {
    required bool aceito,
    String? motivoRejeicao,
  }) async {
    return request<void>(
      'agendamentos/$id/responder',
      method: 'PUT',
      body: {
        'aceito': aceito,
        if (!aceito && motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
      },
      fromJson: (_) {},
    );
  }

  /// PUT /api/agendamentos/{id}/iniciar
  /// Técnico inicia o atendimento
  /// Permissão: Técnico responsável
  Future<void> iniciarAtendimento(String id) async {
    return request<void>(
      'agendamentos/$id/iniciar',
      method: 'PUT',
      fromJson: (_) {},
    );
  }

  /// PUT /api/agendamentos/{id}/concluir
  /// Técnico conclui o atendimento
  /// Requer: observacoes, custoMaoObra, custoMaterial (opcional)
  Future<void> concluirAtendimento(
    String id, {
    required String observacoes,
    double? custoMaoObra,
    double? custoMaterial,
  }) async {
    return request<void>(
      'agendamentos/$id/concluir',
      method: 'PUT',
      body: {
        'observacoes': observacoes,
        'custoMaoObra': ?custoMaoObra,
        'custoMaterial': ?custoMaterial,
      },
      fromJson: (_) {},
    );
  }

  /// PUT /api/agendamentos/{id}/avaliar
  /// Morador avalia o atendimento
  /// Avaliação de 1 a 5 estrelas
  Future<void> avaliarAgendamento(
    String id, {
    required int avaliacaoMorador,
    String? comentarioAvaliacao,
  }) async {
    return request<void>(
      'agendamentos/$id/avaliar',
      method: 'PUT',
      body: {
        'avaliacaoMorador': avaliacaoMorador,
        'comentarioAvaliacao': ?comentarioAvaliacao,
      },
      fromJson: (_) {},
    );
  }

  // ==================== MANUTENÇÕES PREVENTIVAS ====================

  /// GET /api/manutencoes
  /// Lista manutenções gerais (preventivas, corretivas, pontuais ou recorrentes)
  /// Filtros: ativa, tipo
  /// Paginação: pageNumber, pageSize
  Future<List<ManutencaoPreventivaBkendDto>> getManutencoesPrventivas({
    bool? ativa,
    String? tipo,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<List<ManutencaoPreventivaBkendDto>>(
      'manutencoes',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        if (ativa != null) 'ativa': ativa.toString(),
        'tipo': ?tipo,
      },
      fromJson: (json) {
        final lista = (json is Map<String, dynamic> && json['items'] is List)
            ? json['items'] as List
            : json as List<dynamic>;
        return lista
            .map((item) => ManutencaoPreventivaBkendDto.fromJson(item))
            .toList();
      },
    );
  }

  /// GET /api/manutencoes/{id}
  /// Obtém manutenção específica
  Future<ManutencaoPreventivaBkendDto> getManutencaoPreventiva(
    String id,
  ) async {
    return request<ManutencaoPreventivaBkendDto>(
      'manutencoes/$id',
      method: 'GET',
      fromJson: (json) => ManutencaoPreventivaBkendDto.fromJson(json),
    );
  }

  /// POST /api/manutencoes
  /// Cria nova manutenção geral
  /// Permissão: Admin/Funcionário
  Future<ManutencaoPreventivaBkendDto> criarManutencaoPreventiva({
    required String titulo,
    required String tipo,
    required String frequencia,
    DateTime? proximaManutencao,
    double? custoEstimado,
    String? fornecedor,
    String? telefoneFornecedor,
    int? diasAlerta,
    String? responsavelId,
    String? descricao,
    String? tipoSolicitacaoId,
    String? areaTecnicaId,
  }) async {
    return request<ManutencaoPreventivaBkendDto>(
      'manutencoes',
      method: 'POST',
      body: {
        'titulo': titulo,
        'tipo': tipo,
        'frequencia': frequencia,
        if (proximaManutencao != null)
          'proximaManutencao': toBackendUtcIsoString(proximaManutencao),
        'custoEstimado': ?custoEstimado,
        'fornecedor': ?fornecedor,
        'telefoneFornecedor': ?telefoneFornecedor,
        'diasAlerta': ?diasAlerta,
        'responsavelId': ?responsavelId,
        'descricao': ?descricao,
        'tipoSolicitacaoId': ?tipoSolicitacaoId,
        'areaTecnicaId': ?areaTecnicaId,
      },
      fromJson: (json) => ManutencaoPreventivaBkendDto.fromJson(json),
    );
  }

  /// POST /api/manutencoes/{id}/executar
  /// Registra execução da manutenção preventiva
  /// Próxima manutenção é automaticamente agendada
  Future<ManutencacaoExecutadaResponseDto> executarManutencaoPreventiva(
    String id, {
    required DateTime dataRealizacao,
    required String status,
    double? custoReal,
    String? descricaoExecucao,
    String? observacoes,
  }) async {
    return request<ManutencacaoExecutadaResponseDto>(
      'manutencoes/$id/executar',
      method: 'POST',
      body: {
        'dataRealizacao': toBackendUtcIsoString(dataRealizacao),
        'status': status,
        'custoReal': ?custoReal,
        'descricaoExecucao': ?descricaoExecucao,
        'observacoes': ?observacoes,
      },
      fromJson: (json) => ManutencacaoExecutadaResponseDto.fromJson(json),
    );
  }

  // ==================== ÁREAS COMUNS ====================

  /// GET /api/areas-comuns
  /// Lista todas as áreas comuns
  /// Filtro: ativas
  Future<List<AreaComumBkendDto>> getAreasComuns({bool? ativas}) async {
    return request<List<AreaComumBkendDto>>(
      'areas-comuns',
      queryParams: {if (ativas != null) 'ativas': ativas.toString()},
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => AreaComumBkendDto.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/areas-comuns/{id}
  /// Obtém área comum específica com detalhes
  Future<AreaComumDetalhesBkendDto> getAreaComum(String id) async {
    return request<AreaComumDetalhesBkendDto>(
      'areas-comuns/$id',
      method: 'GET',
      fromJson: (json) => AreaComumDetalhesBkendDto.fromJson(json),
    );
  }

  /// POST /api/areas-comuns
  /// Cria nova área comum
  /// Permissão: Admin
  Future<AreaComumBkendDto> criarAreaComum({
    required String nome,
    required int capacidade,
    required double valorHora,
    bool requerAprovacao = false,
    String? descricao,
    String? horarioAbertura,
    String? horarioFechamento,
    String? regras,
  }) async {
    return request<AreaComumBkendDto>(
      'areas-comuns',
      method: 'POST',
      body: {
        'nome': nome,
        'capacidade': capacidade,
        'valorHora': valorHora,
        'requerAprovacao': requerAprovacao,
        'descricao': ?descricao,
        'horarioAbertura': ?horarioAbertura,
        'horarioFechamento': ?horarioFechamento,
        'regras': ?regras,
      },
      fromJson: (json) => AreaComumBkendDto.fromJson(json),
    );
  }

  /// PUT /api/areas-comuns/{id}
  /// Atualiza área comum
  /// Permissão: Admin
  Future<void> atualizarAreaComum(
    String id, {
    String? nome,
    int? capacidade,
    double? valorHora,
    bool? requerAprovacao,
    String? descricao,
  }) async {
    return request<void>(
      'areas-comuns/$id',
      method: 'PUT',
      body: {
        'nome': ?nome,
        'capacidade': ?capacidade,
        'valorHora': ?valorHora,
        'requerAprovacao': ?requerAprovacao,
        'descricao': ?descricao,
      },
      fromJson: (_) {},
    );
  }

  /// DELETE /api/areas-comuns/{id}
  /// Deleta área comum
  /// Permissão: Admin
  Future<void> deletarAreaComum(String id) async {
    return request<void>(
      'areas-comuns/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  // ==================== RESERVAS DE ÁREA COMUM ====================

  /// GET /api/reservas-area-comum
  /// Lista reservas de áreas comuns
  /// Filtros: areaComumId, status, dataInicio, dataFim
  /// Paginação: pageNumber, pageSize
  Future<List<ReservaAreaComumBkendDto>> getReservasAreaComum({
    String? areaComumId,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<List<ReservaAreaComumBkendDto>>(
      'reservas-area-comum',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'areaComumId': ?areaComumId,
        'status': ?status,
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
      },
      fromJson: (json) {
        final lista = (json is Map<String, dynamic> && json['items'] is List)
            ? json['items'] as List
            : json as List<dynamic>;
        return lista
            .map((item) => ReservaAreaComumBkendDto.fromJson(item))
            .toList();
      },
    );
  }

  /// POST /api/reservas-area-comum
  /// Cria nova reserva (Morador)
  Future<ReservaAreaComumBkendDto> criarReservaAreaComum({
    required String areaComumId,
    required DateTime dataReserva,
    required String horaInicio,
    required String horaFim,
    String? observacoes,
  }) async {
    return request<ReservaAreaComumBkendDto>(
      'reservas-area-comum',
      method: 'POST',
      body: {
        'areaComumId': areaComumId,
        'dataReserva': toBackendUtcIsoString(dataReserva),
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'observacoes': ?observacoes,
      },
      fromJson: (json) => ReservaAreaComumBkendDto.fromJson(json),
    );
  }

  /// PUT /api/reservas-area-comum/{id}/aprovar
  /// Aprova ou rejeita reserva (Admin/Funcionário)
  Future<void> aprovarReservaAreaComum(
    String id, {
    required bool aprovar,
    String? observacoes,
  }) async {
    return request<void>(
      'reservas-area-comum/$id/aprovar',
      method: 'PUT',
      body: {
        'aprovar': aprovar,
        'observacoes': ?observacoes,
      },
      fromJson: (_) {},
    );
  }

  /// PUT /api/reservas-area-comum/{id}/cancelar
  /// Cancela reserva (Morador)
  Future<void> cancelarReservaAreaComum(String id, {String? motivo}) async {
    return request<void>(
      'reservas-area-comum/$id/cancelar',
      method: 'PUT',
      body: {'motivo': ?motivo},
      fromJson: (_) {},
    );
  }

  /// PUT /api/reservas-area-comum/{id}/avaliar
  /// Avalia reserva (Morador que fez a reserva)
  /// Avaliação de 1 a 5 estrelas
  Future<void> avaliarReservaAreaComum(
    String id, {
    required int avaliacaoMorador,
    String? comentarioAvaliacao,
  }) async {
    return request<void>(
      'reservas-area-comum/$id/avaliar',
      method: 'PUT',
      body: {
        'avaliacaoMorador': avaliacaoMorador,
        'comentarioAvaliacao': ?comentarioAvaliacao,
      },
      fromJson: (_) {},
    );
  }

  // ==================== NOTIFICAÇÕES ====================

  /// GET /api/notificacoes
  /// Lista notificações do usuário
  /// Filtros: somenteNaoLidas, tipo
  /// Paginação: pageNumber, pageSize
  Future<List<NotificacaoBkendDto>> getNotificacoes({
    bool? somenteNaoLidas,
    String? tipo,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return request<List<NotificacaoBkendDto>>(
      'notificacoes',
      queryParams: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        if (somenteNaoLidas != null)
          'somenteNaoLidas': somenteNaoLidas.toString(),
        'tipo': ?tipo,
      },
      fromJson: (json) {
        final lista = (json is Map<String, dynamic> && json['items'] is List)
            ? json['items'] as List
            : json as List<dynamic>;
        return lista.map((item) => NotificacaoBkendDto.fromJson(item)).toList();
      },
    );
  }

  /// GET /api/notificacoes/resumo
  /// Obtém resumo de notificações (contadores)
  Future<NotificacaoResumoDto> getResumoNotificacoes() async {
    return request<NotificacaoResumoDto>(
      'notificacoes/resumo',
      method: 'GET',
      fromJson: (json) => NotificacaoResumoDto.fromJson(json),
    );
  }

  /// PUT /api/notificacoes/{id}/marcar-lida
  /// Marca notificação como lida
  Future<void> marcarNotificacaoLida(String id) async {
    return request<void>(
      'notificacoes/$id/marcar-lida',
      method: 'PUT',
      fromJson: (_) {},
    );
  }

  /// PUT /api/notificacoes/marcar-todas-lidas
  /// Marca todas as notificações como lidas
  Future<void> marcarTodasNotificacoesLidas() async {
    return request<void>(
      'notificacoes/marcar-todas-lidas',
      method: 'PUT',
      fromJson: (_) {},
    );
  }

  /// DELETE /api/notificacoes/{id}
  /// Deleta notificação
  Future<void> deletarNotificacao(String id) async {
    return request<void>(
      'notificacoes/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  /// DELETE /api/notificacoes/limpar
  /// Limpa todas as notificações lidas
  Future<void> limparNotificacoesLidas() async {
    return request<void>(
      'notificacoes/limpar',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  // ==================== DASHBOARD — ENDPOINTS ADICIONAIS ====================

  /// GET /api/dashboard/completo
  /// Dashboard completo com KPIs e métricas detalhadas
  Future<Map<String, dynamic>> getDashboardCompleto() async {
    return request<Map<String, dynamic>>(
      'dashboard/completo',
      method: 'GET',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// GET /api/dashboard/solicitacoes-atrasadas
  /// Solicitações com SLA vencido (Admin, Síndico, Func)
  Future<List<SolicitacaoRecenteDto>> getSolicitacoesAtrasadas() async {
    return request<List<SolicitacaoRecenteDto>>(
      'dashboard/solicitacoes-atrasadas',
      method: 'GET',
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => SolicitacaoRecenteDto.fromJson(item))
          .toList(),
    );
  }

  /// GET /api/dashboard/grafico-manutencoes-pizza
  /// Dados para gráfico pizza de manutenções
  Future<List<StatusGraficoDto>> getGraficoManutencoesPizza() async {
    try {
      return await request<List<StatusGraficoDto>>(
        'dashboard/grafico-manutencoes-pizza',
        method: 'GET',
        fromJson: (json) {
          if (json is Map<String, dynamic> && json['dados'] is List) {
            return (json['dados'] as List)
                .map((item) => StatusGraficoDto.fromJson(item))
                .toList();
          }
          return (json as List<dynamic>)
              .map((item) => StatusGraficoDto.fromJson(item))
              .toList();
        },
      );
    } catch (e) {
      AppLogger.warning(
        'ApiService',
        'dashboard/grafico-manutencoes-pizza não disponível, retornando lista vazia',
        e,
      );
      return <StatusGraficoDto>[];
    }
  }

  // ==================== AGENDAMENTOS — ENDPOINTS ADICIONAIS ====================

  /// POST /api/AgendamentosManutencao/{id}/confirmar
  /// Staff confirma agendamento que foi aceite pelo morador
  Future<void> confirmarAgendamento(String id) async {
    return request<void>(
      'agendamentosmanutencao/$id/confirmar',
      method: 'POST',
      fromJson: (_) {},
    );
  }

  /// POST /api/AgendamentosManutencao/{id}/iniciar
  /// Staff inicia a execução da manutenção
  Future<void> iniciarAgendamento(String id) async {
    return request<void>(
      'agendamentosmanutencao/$id/iniciar',
      method: 'POST',
      fromJson: (_) {},
    );
  }

  /// POST /api/AgendamentosManutencao/{id}/concluir
  /// Staff conclui a manutenção
  Future<void> concluirAgendamento(
    String id, {
    String? observacoes,
    double? custoMaoObra,
    double? custoMaterial,
  }) async {
    return request<void>(
      'agendamentosmanutencao/$id/concluir',
      method: 'POST',
      body: {
        'observacoes': ?observacoes,
        'custoMaoObra': ?custoMaoObra,
        'custoMaterial': ?custoMaterial,
      },
      fromJson: (_) {},
    );
  }

  /// DELETE /api/AgendamentosManutencao/{id}
  /// Cancela/remove agendamento (Admin, Síndico, Func)
  Future<void> cancelarAgendamento(String id) async {
    return request<void>(
      'agendamentosmanutencao/$id',
      method: 'DELETE',
      fromJson: (_) {},
    );
  }

  // ==================== EXPORTAÇÃO — ENDPOINTS ADICIONAIS ====================

  /// GET /api/Exportacao/relatorio-completo/zip
  /// ZIP com todos os relatórios (Admin, Síndico, Func)
  Future<List<int>> exportarRelatorioCompletoZip() async {
    try {
      var endpoint = 'Exportacao/relatorio-completo/zip';
      Uri url = Uri.parse('$baseUrl/$endpoint');

      final headers = _headers(isBinaryDownload: true);
      final resp = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }

      throw Exception('Erro ao exportar ZIP (HTTP ${resp.statusCode})');
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/Exportacao/relatorio-completo/save
  /// Salva ZIP no servidor (Admin)
  Future<void> salvarRelatorioCompletoNoServidor() async {
    return request<void>(
      'Exportacao/relatorio-completo/save',
      method: 'POST',
      fromJson: (_) {},
    );
  }

  // ==================== BACKGROUND JOBS ====================

  /// GET /api/backgroundjobs/status
  /// Status dos background jobs (Admin)
  Future<Map<String, dynamic>> getBackgroundJobsStatus() async {
    return request<Map<String, dynamic>>(
      'backgroundjobs/status',
      method: 'GET',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// POST /api/backgroundjobs/trigger/{jobName}
  /// Executar job manualmente (Admin)
  Future<void> triggerBackgroundJob(String jobName) async {
    return request<void>(
      'backgroundjobs/trigger/$jobName',
      method: 'POST',
      fromJson: (_) {},
    );
  }
}
