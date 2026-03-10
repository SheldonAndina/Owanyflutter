# 📱 GUIA COMPLETO DE INTEGRAÇÃO - FLUTTER + OWANY API

> Nota de compatibilidade (Owany App atual): Este projeto usa `lib/services/api_service.dart` com o pacote `http` (não `dio`) e faz a injeção automática do token JWT e o desembrulho do wrapper `{ sucesso, mensagem, dados, erros }`. Você pode usar este guia como referência arquitetural. Onde o guia usa `Dio`/interceptors, mapeie para o `ApiService().request<T>()` já existente. Para solicitações v1, ajuste os endpoints conforme a API disponível.

```
┌─────────────────────────────────────────────────────────────────┐
│                    🎯 GUIA PARA EQUIPE FLUTTER                   │
│                                                                 │
│         Como integrar o app Flutter com a API Owany            │
│         Todos os endpoints, exemplos e modelos Dart            │
│                                                                 │
│         ✅ Autenticação JWT                                     │
│         ✅ Paginação                                            │
│         ✅ Upload de arquivos                                   │
│         ✅ Tratamento de erros                                  │
│         ✅ Modelos Dart completos                               │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 ÍNDICE

1. [Configuração Inicial](#1-configuração-inicial)
2. [Autenticação](#2-autenticação)
3. [Apartamentos](#3-apartamentos)
4. [Moradores](#4-moradores)
5. [Solicitações de Manutenção](#5-solicitações-de-manutenção)
6. [Comentários](#6-comentários)
7. [Notificações](#7-notificações)
8. [Dashboard](#8-dashboard)
9. [Usuários](#9-usuários)
10. [Modelos Dart Completos](#10-modelos-dart-completos)
11. [Tratamento de Erros](#11-tratamento-de-erros)
12. [Boas Práticas](#12-boas-práticas)
13. [Notas Owany App](#13-notas-owany-app)
14. [Problema conhecido (500) e correção](#14-problema-conhecido-500-e-correção)

---

## 1. CONFIGURAÇÃO INICIAL

### 1.1 URLs Base

```dart
// lib/config/api_config.dart

class ApiConfig {
  // Desenvolvimento
  static const String devBaseUrl = 'https://localhost:7068';
  static const String devBaseUrlHttp = 'http://localhost:5083';
  
  // Produção (ajustar quando deploy)
  static const String prodBaseUrl = 'https://api.owany.com';
  
  // URL ativa
  static String get baseUrl {
    return const bool.fromEnvironment('dart.vm.product')
        ? prodBaseUrl
        : devBaseUrl;
  }
  
  // Endpoints
  static const String auth = '/api/auth';
  static const String usuarios = '/api/usuarios';
  static const String apartamentos = '/api/apartamentos';
  static const String moradores = '/api/moradores';
  static const String solicitacoes = '/api/v1/solicitacoes'; // Usar v1!
  static const String comentarios = '/api/comentarios';
  static const String notificacoes = '/api/notificacoes';
  static const String dashboard = '/api/dashboard';
  static const String itens = '/api/itemapartamento';
}
```

### 1.2 Interceptor HTTP (Adicionar Token Automaticamente)

```dart
// lib/services/api_interceptor.dart

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Adicionar token JWT em todas as requisições
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorErrorInterceptorHandler handler) async {
    // Se 401 (não autorizado), fazer logout
    if (err.response?.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      // Navegar para tela de login
    }
    
    super.onError(err, handler);
  }
}
```

### 1.3 Cliente HTTP Base

```dart
// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'api_interceptor.dart';
import '../config/api_config.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500, // Não lançar erro em 4xx
    ),
  )..interceptors.add(ApiInterceptor());

  static Dio get instance => _dio;
}
```

---

## 2. AUTENTICAÇÃO

### 2.1 Endpoints Disponíveis

```
POST   /api/auth/login              - Fazer login
POST   /api/auth/registrar          - Criar novo usuário
POST   /api/auth/mudar-senha        - Mudar senha (logado)
POST   /api/auth/solicitar-reset    - Solicitar reset de senha (por telefone)
POST   /api/auth/resetar-senha      - Resetar senha com OTP
```

### 2.2 Login

```dart
// lib/services/auth_service.dart

class AuthService {
  final Dio _dio = ApiClient.instance;

  Future<LoginResult> login(String nomeLogin, String senha) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.auth}/login',
        data: {
          'nomeLogin': nomeLogin,
          'senha': senha,
        },
      );

      if (response.statusCode == 200) {
        final result = LoginResult.fromJson(response.data['data']);
        
        // Salvar token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.token);
        await prefs.setString('refresh_token', result.refreshToken);
        await prefs.setString('user_id', result.usuario.id);
        await prefs.setString('user_name', result.usuario.nome);
        await prefs.setString('user_role', result.usuario.tipo);
        
        return result;
      } else {
        throw Exception(response.data['mensagem'] ?? 'Erro ao fazer login');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Usuário ou senha incorretos');
      }
      throw Exception('Erro de conexão: ${e.message}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }
}
```

### 2.3 Registrar Novo Usuário

```dart
Future<void> registrar({
  required String nome,
  required String nomeLogin,
  required String telefone,
  required String senha,
  required String confirmarSenha,
}) async {
  try {
    final response = await _dio.post(
      '${ApiConfig.auth}/registrar',
      data: {
        'nome': nome,
        'nomeLogin': nomeLogin,
        'telefone': telefone,
        'senha': senha,
        'confirmarSenha': confirmarSenha,
        'tipo': 'Morador', // Padrão
      },
    );

    if (response.statusCode != 201) {
      throw Exception(response.data['mensagem'] ?? 'Erro ao registrar');
    }
  } on DioException catch (e) {
    final errors = e.response?.data['erros'] as List<dynamic>?;
    throw Exception(errors?.join(', ') ?? 'Erro ao registrar');
  }
}
```

### 2.4 Mudar Senha (Logado)

```dart
Future<void> mudarSenha({
  required String senhaAtual,
  required String novaSenha,
  required String confirmarNovaSenha,
}) async {
  try {
    final response = await _dio.post(
      '${ApiConfig.auth}/mudar-senha',
      data: {
        'senhaAtual': senhaAtual,
        'novaSenha': novaSenha,
        'confirmarNovaSenha': confirmarNovaSenha,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(response.data['mensagem'] ?? 'Erro ao mudar senha');
    }
  } on DioException catch (e) {
    throw Exception(e.response?.data['mensagem'] ?? 'Erro ao mudar senha');
  }
}
```

### 2.5 Reset de Senha (Sem Login)

**Passo 1: Solicitar OTP**
```dart
Future<void> solicitarResetSenha(String telefone) async {
  try {
    final response = await _dio.post(
      '${ApiConfig.auth}/solicitar-reset',
      data: {'telefone': telefone},
    );

    if (response.statusCode != 200) {
      throw Exception(response.data['mensagem']);
    }
    
    // OTP enviado por SMS (em produção)
    // Em dev, aparece no log do backend
  } on DioException catch (e) {
    throw Exception(e.response?.data['mensagem'] ?? 'Erro ao solicitar reset');
  }
}
```

**Passo 2: Confirmar com OTP**
```dart
Future<void> resetarSenha({
  required String telefone,
  required String codigoOtp,
  required String novaSenha,
  required String confirmarNovaSenha,
}) async {
  try {
    final response = await _dio.post(
      '${ApiConfig.auth}/resetar-senha',
      data: {
        'telefone': telefone,
        'codigoOtp': codigoOtp,
        'novaSenha': novaSenha,
        'confirmarNovaSenha': confirmarNovaSenha,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception(e.response?.data['mensagem'] ?? 'Código inválido ou expirado');
  }
}
```

---

## 3. APARTAMENTOS

### 3.1 Endpoints Disponíveis

```
GET    /api/apartamentos                - Listar todos (com paginação)
GET    /api/apartamentos/{id}           - Obter detalhes de um
POST   /api/apartamentos                - Criar novo (Admin/Funcionário)
PUT    /api/apartamentos/{id}           - Atualizar (Admin/Funcionário)
DELETE /api/apartamentos/{id}           - Deletar (Admin)
```

### 3.2 Listar Apartamentos (com Paginação)

```dart
// lib/services/apartamentos_service.dart

class ApartamentosService {
  final Dio _dio = ApiClient.instance;

  Future<PaginatedResponse<Apartamento>> listarApartamentos({
    int pageNumber = 1,
    int pageSize = 20,
    String? bloco,
    String? estado,
  }) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (bloco != null) 'bloco': bloco,
        if (estado != null) 'estado': estado,
      };

      final response = await _dio.get(
        ApiConfig.apartamentos,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedResponse<Apartamento>.fromJson(
          response.data['data'],
          (json) => Apartamento.fromJson(json),
        );
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar apartamentos: ${e.message}');
    }
  }

  Future<ApartamentoDetalhado> obterApartamento(String id) async {
    try {
      final response = await _dio.get('${ApiConfig.apartamentos}/$id');

      if (response.statusCode == 200) {
        return ApartamentoDetalhado.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar apartamento: ${e.message}');
    }
  }
}
```

### 3.3 Criar Apartamento (Admin)

```dart
Future<Apartamento> criarApartamento({
  required String nome,
  required String numero,
  required int andar,
  required String bloco,
  String? descricao,
}) async {
  try {
    final response = await _dio.post(
      ApiConfig.apartamentos,
      data: {
        'nome': nome,
        'numero': numero,
        'andar': andar,
        'bloco': bloco,
        'descricao': descricao,
        'estado': 'Disponivel',
      },
    );

    if (response.statusCode == 201) {
      return Apartamento.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception('Erro ao criar apartamento: ${e.response?.data['mensagem']}');
  }
}
```

---

## 4. MORADORES

### 4.1 Endpoints Disponíveis

```
GET    /api/moradores              - Listar todos
GET    /api/moradores/{id}         - Obter um morador
POST   /api/moradores              - Criar morador (vincular usuário a apartamento)
DELETE /api/moradores/{id}         - Remover morador (Admin)
```

### 4.2 Listar Moradores

```dart
// lib/services/moradores_service.dart

class MoradoresService {
  final Dio _dio = ApiClient.instance;

  Future<List<Morador>> listarMoradores({String? apartamentoId}) async {
    try {
      final queryParams = apartamentoId != null 
          ? {'apartamentoId': apartamentoId} 
          : <String, dynamic>{};

      final response = await _dio.get(
        ApiConfig.moradores,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Morador.fromJson(json)).toList();
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar moradores: ${e.message}');
    }
  }

  Future<MoradorDetalhado> obterMorador(String id) async {
    try {
      final response = await _dio.get('${ApiConfig.moradores}/$id');

      if (response.statusCode == 200) {
        return MoradorDetalhado.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar morador: ${e.message}');
    }
  }
}
```

### 4.3 Criar Morador

```dart
Future<Morador> criarMorador({
  required String nome,
  required String usuarioId,
  required String apartamentoId,
}) async {
  try {
    final response = await _dio.post(
      ApiConfig.moradores,
      data: {
        'nome': nome,
        'usuarioId': usuarioId,
        'apartamentoId': apartamentoId,
      },
    );

    if (response.statusCode == 201) {
      return Morador.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception('Erro ao criar morador: ${e.response?.data['mensagem']}');
  }
}
```

---

## 5. SOLICITAÇÕES DE MANUTENÇÃO

### 5.1 Endpoints Disponíveis (USAR V1!)

```
GET    /api/v1/solicitacoes              - Listar (com paginação e filtros)
GET    /api/v1/solicitacoes/{id}         - Obter detalhes completos
POST   /api/v1/solicitacoes              - Criar nova solicitação
PUT    /api/v1/solicitacoes/{id}         - Atualizar status/responsável
DELETE /api/v1/solicitacoes/{id}         - Deletar (Admin)
```

### 5.2 Listar Solicitações (com Filtros)

```dart
// lib/services/solicitacoes_service.dart

class SolicitacoesService {
  final Dio _dio = ApiClient.instance;

  Future<PaginatedResponse<SolicitacaoResumo>> listarSolicitacoes({
    int pageNumber = 1,
    int pageSize = 20,
    String? status,
    String? apartamentoId,
    String? moradorId,
  }) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (status != null) 'status': status,
        if (apartamentoId != null) 'apartamentoId': apartamentoId,
        if (moradorId != null) 'moradorId': moradorId,
      };

      final response = await _dio.get(
        ApiConfig.solicitacoes,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedResponse<SolicitacaoResumo>.fromJson(
          response.data['data'],
          (json) => SolicitacaoResumo.fromJson(json),
        );
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar solicitações: ${e.message}');
    }
  }

  Future<SolicitacaoDetalhada> obterSolicitacao(String id) async {
    try {
      final response = await _dio.get('${ApiConfig.solicitacoes}/$id');

      if (response.statusCode == 200) {
        return SolicitacaoDetalhada.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar solicitação: ${e.message}');
    }
  }
}
```

### 5.3 Criar Solicitação

```dart
Future<SolicitacaoResumo> criarSolicitacao({
  required String titulo,
  required String descricao,
  required String moradorId,
  required String apartamentoId,
  DateTime? prazoLimite,
}) async {
  try {
    final response = await _dio.post(
      ApiConfig.solicitacoes,
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'moradorId': moradorId,
        'apartamentoId': apartamentoId,
        'prazoLimite': prazoLimite?.toIso8601String(),
      },
    );

    if (response.statusCode == 201) {
      return SolicitacaoResumo.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception('Erro ao criar solicitação: ${e.response?.data['mensagem']}');
  }
}
```

### 5.4 Atualizar Status

```dart
Future<void> atualizarStatus({
  required String solicitacaoId,
  required String novoStatus,
  String? responsavelId,
}) async {
  try {
    final response = await _dio.put(
      '${ApiConfig.solicitacoes}/$solicitacaoId',
      data: {
        'status': novoStatus,
        if (responsavelId != null) 'responsavelId': responsavelId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception('Erro ao atualizar status: ${e.response?.data['mensagem']}');
  }
}
```

### 5.5 Upload de Anexo

```dart
Future<void> adicionarAnexo({
  required String solicitacaoId,
  required File arquivo,
}) async {
  try {
    final formData = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(
        arquivo.path,
        filename: arquivo.path.split('/').last,
      ),
      'solicitacaoId': solicitacaoId,
    });

    final response = await _dio.post(
      '${ApiConfig.solicitacoes}/$solicitacaoId/anexos',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    if (response.statusCode != 201) {
      throw Exception(response.data['mensagem']);
    }
  } on DioException catch (e) {
    throw Exception('Erro ao enviar anexo: ${e.message}');
  }
}
```

---

## 6. COMENTÁRIOS

### 6.1 Endpoints Disponíveis

```
POST   /api/comentarios                  - Criar comentário
GET    /api/comentarios/{id}             - Obter um comentário
DELETE /api/comentarios/{id}             - Deletar (criador ou admin)
```

### 6.2 Adicionar Comentário

```dart
// lib/services/comentarios_service.dart

class ComentariosService {
  final Dio _dio = ApiClient.instance;

  Future<Comentario> adicionarComentario({
    required String solicitacaoId,
    required String texto,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.comentarios,
        data: {
          'solicitacaoId': solicitacaoId,
          'texto': texto,
        },
      );

      if (response.statusCode == 201) {
        return Comentario.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao adicionar comentário: ${e.response?.data['mensagem']}');
    }
  }

  Future<void> deletarComentario(String id) async {
    try {
      final response = await _dio.delete('${ApiConfig.comentarios}/$id');

      if (response.statusCode != 200) {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao deletar comentário: ${e.message}');
    }
  }
}
```

---

## 7. NOTIFICAÇÕES

### 7.1 Endpoints Disponíveis

```
GET    /api/notificacoes                        - Listar minhas notificações
GET    /api/notificacoes/{id}                   - Obter uma notificação
PUT    /api/notificacoes/{id}/marcar-lida      - Marcar como lida
PUT    /api/notificacoes/marcar-todas-lidas    - Marcar todas como lidas
DELETE /api/notificacoes/{id}                   - Deletar notificação
```

### 7.2 Listar Notificações

```dart
// lib/services/notificacoes_service.dart

class NotificacoesService {
  final Dio _dio = ApiClient.instance;

  Future<List<Notificacao>> listarNotificacoes({bool? apenasNaoLidas}) async {
    try {
      final queryParams = apenasNaoLidas != null
          ? {'apenasNaoLidas': apenasNaoLidas}
          : <String, dynamic>{};

      final response = await _dio.get(
        ApiConfig.notificacoes,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Notificacao.fromJson(json)).toList();
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar notificações: ${e.message}');
    }
  }

  Future<void> marcarComoLida(String id) async {
    try {
      final response = await _dio.put('${ApiConfig.notificacoes}/$id/marcar-lida');

      if (response.statusCode != 200) {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao marcar como lida: ${e.message}');
    }
  }

  Future<void> marcarTodasComoLidas() async {
    try {
      final response = await _dio.put('${ApiConfig.notificacoes}/marcar-todas-lidas');

      if (response.statusCode != 200) {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao marcar todas como lidas: ${e.message}');
    }
  }
}
```

---

## 8. DASHBOARD

### 8.1 Endpoints Disponíveis

```
GET    /api/dashboard                    - Estatísticas gerais
GET    /api/dashboard/minhas-solicitacoes - Minhas solicitações (morador)
```

### 8.2 Obter Estatísticas

```dart
// lib/services/dashboard_service.dart

class DashboardService {
  final Dio _dio = ApiClient.instance;

  Future<DashboardStats> obterEstatisticas() async {
    try {
      final response = await _dio.get(ApiConfig.dashboard);

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar estatísticas: ${e.message}');
    }
  }

  Future<MinhasSolicitacoes> obterMinhasSolicitacoes() async {
    try {
      final response = await _dio.get('${ApiConfig.dashboard}/minhas-solicitacoes');

      if (response.statusCode == 200) {
        return MinhasSolicitacoes.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar minhas solicitações: ${e.message}');
    }
  }
}
```

---

## 9. USUÁRIOS

### 9.1 Endpoints Disponíveis

```
GET    /api/usuarios                    - Listar todos (Admin/Funcionário)
GET    /api/usuarios/{id}               - Obter um usuário
GET    /api/usuarios/me                 - Obter meu perfil
PUT    /api/usuarios/{id}               - Atualizar usuário
DELETE /api/usuarios/{id}               - Deletar (soft delete)
```

### 9.2 Obter Perfil

```dart
// lib/services/usuarios_service.dart

class UsuariosService {
  final Dio _dio = ApiClient.instance;

  Future<Usuario> obterMeuPerfil() async {
    try {
      final response = await _dio.get('${ApiConfig.usuarios}/me');

      if (response.statusCode == 200) {
        return Usuario.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao buscar perfil: ${e.message}');
    }
  }

  Future<void> atualizarPerfil({
    required String id,
    String? nome,
    String? telefone,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConfig.usuarios}/$id',
        data: {
          if (nome != null) 'nome': nome,
          if (telefone != null) 'telefone': telefone,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['mensagem']);
      }
    } on DioException catch (e) {
      throw Exception('Erro ao atualizar perfil: ${e.response?.data['mensagem']}');
    }
  }
}
```

---

## 10. MODELOS DART COMpletos

### 10.1 Resposta Padrão da API

```dart
// lib/models/api_response.dart

class ApiResponse<T> {
  final bool sucesso;
  final String? mensagem;
  final T? data;
  final List<String>? erros;

  ApiResponse({
    required this.sucesso,
    this.mensagem,
    this.data,
    this.erros,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      sucesso: json['sucesso'] ?? false,
      mensagem: json['mensagem'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      erros: json['erros'] != null
          ? List<String>.from(json['erros'])
          : null,
    );
  }
}
```

### 10.2 Paginação

```dart
// lib/models/paginated_response.dart

class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}
```

### 10.3 Login Result

```dart
// lib/models/login_result.dart

class LoginResult {
  final String token;
  final String refreshToken;
  final DateTime expiracao;
  final Usuario usuario;

  LoginResult({
    required this.token,
    required this.refreshToken,
    required this.expiracao,
    required this.usuario,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'],
      refreshToken: json['refreshToken'],
      expiracao: DateTime.parse(json['expiracao']),
      usuario: Usuario.fromJson(json['usuario']),
    );
  }
}
```

### 10.4 Usuário

```dart
// lib/models/usuario.dart

class Usuario {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String tipo; // Administrador, Funcionario, Morador, etc.
  final bool ativo;
  final DateTime? ultimoLoginEm;
  final MoradorInfo? moradorInfo;

  Usuario({
    required this.id,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.tipo,
    required this.ativo,
    this.ultimoLoginEm,
    this.moradorInfo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      nomeLogin: json['nomeLogin'],
      telefone: json['telefone'],
      tipo: json['tipo'],
      ativo: json['ativo'] ?? true,
      ultimoLoginEm: json['ultimoLoginEm'] != null
          ? DateTime.parse(json['ultimoLoginEm'])
          : null,
      moradorInfo: json['moradorInfo'] != null
          ? MoradorInfo.fromJson(json['moradorInfo'])
          : null,
    );
  }

  bool get isAdmin => tipo == 'Administrador';
  bool get isFuncionario => tipo == 'Funcionario';
  bool get isMorador => tipo == 'Morador';
}

class MoradorInfo {
  final String moradorId;
  final String apartamentoId;
  final String numeroApartamento;
  final String blocoApartamento;

  MoradorInfo({
    required this.moradorId,
    required this.apartamentoId,
    required this.numeroApartamento,
    required this.blocoApartamento,
  });

  factory MoradorInfo.fromJson(Map<String, dynamic> json) {
    return MoradorInfo(
      moradorId: json['moradorId'],
      apartamentoId: json['apartamentoId'],
      numeroApartamento: json['numeroApartamento'],
      blocoApartamento: json['blocoApartamento'],
    );
  }
}
```

### 10.5 Apartamento

```dart
// lib/models/apartamento.dart

class Apartamento {
  final String id;
  final String nome;
  final String numero;
  final int andar;
  final String bloco;
  final String estado; // Disponivel, Ocupado, EmManutencao, Inativo
  final int quantidadeMoradores;

  Apartamento({
    required this.id,
    required this.nome,
    required this.numero,
    required this.andar,
    required this.bloco,
    required this.estado,
    required this.quantidadeMoradores,
  });

  factory Apartamento.fromJson(Map<String, dynamic> json) {
    return Apartamento(
      id: json['id'],
      nome: json['nome'],
      numero: json['numero'],
      andar: json['andar'],
      bloco: json['bloco'],
      estado: json['estado'],
      quantidadeMoradores: json['quantidadeMoradores'] ?? 0,
    );
  }

  bool get isDisponivel => estado == 'Disponivel';
  bool get isOcupado => estado == 'Ocupado';
}

class ApartamentoDetalhado extends Apartamento {
  final String? descricao;
  final List<Morador> moradores;
  final List<ItemApartamento> itens;

  ApartamentoDetalhado({
    required String id,
    required String nome,
    required String numero,
    required int andar,
    required String bloco,
    required String estado,
    required int quantidadeMoradores,
    this.descricao,
    required this.moradores,
    required this.itens,
  }) : super(
          id: id,
          nome: nome,
          numero: numero,
          andar: andar,
          bloco: bloco,
          estado: estado,
          quantidadeMoradores: quantidadeMoradores,
        );

  factory ApartamentoDetalhado.fromJson(Map<String, dynamic> json) {
    return ApartamentoDetalhado(
      id: json['id'],
      nome: json['nome'],
      numero: json['numero'],
      andar: json['andar'],
      bloco: json['bloco'],
      estado: json['estado'],
      quantidadeMoradores: json['quantidadeMoradores'] ?? 0,
      descricao: json['descricao'],
      moradores: (json['moradores'] as List?)
              ?.map((m) => Morador.fromJson(m))
              .toList() ??
          [],
      itens: (json['itens'] as List?)
              ?.map((i) => ItemApartamento.fromJson(i))
              .toList() ??
          [],
    );
  }
}
```

### 10.6 Solicitação de Manutenção

```dart
// lib/models/solicitacao.dart

class SolicitacaoResumo {
  final String id;
  final String titulo;
  final String status;
  final String nomeUsuarioCriador;
  final String? nomeResponsavel;
  final String numeroApartamento;
  final String blocoApartamento;
  final DateTime criadoEm;
  final DateTime? prazoLimite;
  final int quantidadeComentarios;
  final int quantidadeAnexos;

  SolicitacaoResumo({
    required this.id,
    required this.titulo,
    required this.status,
    required this.nomeUsuarioCriador,
    this.nomeResponsavel,
    required this.numeroApartamento,
    required this.blocoApartamento,
    required this.criadoEm,
    this.prazoLimite,
    required this.quantidadeComentarios,
    required this.quantidadeAnexos,
  });

  factory SolicitacaoResumo.fromJson(Map<String, dynamic> json) {
    return SolicitacaoResumo(
      id: json['id'],
      titulo: json['titulo'],
      status: json['status'],
      nomeUsuarioCriador: json['nomeUsuarioCriador'],
      nomeResponsavel: json['nomeResponsavel'],
      numeroApartamento: json['numeroApartamento'],
      blocoApartamento: json['blocoApartamento'],
      criadoEm: DateTime.parse(json['criadoEm']),
      prazoLimite: json['prazoLimite'] != null
          ? DateTime.parse(json['prazoLimite'])
          : null,
      quantidadeComentarios: json['quantidadeComentarios'] ?? 0,
      quantidadeAnexos: json['quantidadeAnexos'] ?? 0,
    );
  }

  bool get isPendente => status == 'Pendente';
  bool get isEmAndamento => status == 'EmAndamento';
  bool get isConcluido => status == 'Concluido';
  bool get isCancelado => status == 'Cancelado';

  Color get statusColor {
    switch (status) {
      case 'Pendente':
        return Colors.orange;
      case 'EmAndamento':
        return Colors.blue;
      case 'Concluido':
        return Colors.green;
      case 'Cancelado':
      case 'Rejeitado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class SolicitacaoDetalhada extends SolicitacaoResumo {
  final String descricao;
  final String moradorNome;
  final List<Comentario> comentarios;
  final List<HistoricoStatus> historico;
  final List<Anexo> anexos;

  SolicitacaoDetalhada({
    required String id,
    required String titulo,
    required String status,
    required String nomeUsuarioCriador,
    String? nomeResponsavel,
    required String numeroApartamento,
    required String blocoApartamento,
    required DateTime criadoEm,
    DateTime? prazoLimite,
    required int quantidadeComentarios,
    required int quantidadeAnexos,
    required this.descricao,
    required this.moradorNome,
    required this.comentarios,
    required this.historico,
    required this.anexos,
  }) : super(
          id: id,
          titulo: titulo,
          status: status,
          nomeUsuarioCriador: nomeUsuarioCriador,
          nomeResponsavel: nomeResponsavel,
          numeroApartamento: numeroApartamento,
          blocoApartamento: blocoApartamento,
          criadoEm: criadoEm,
          prazoLimite: prazoLimite,
          quantidadeComentarios: quantidadeComentarios,
          quantidadeAnexos: quantidadeAnexos,
        );

  factory SolicitacaoDetalhada.fromJson(Map<String, dynamic> json) {
    return SolicitacaoDetalhada(
      id: json['id'],
      titulo: json['titulo'],
      status: json['status'],
      nomeUsuarioCriador: json['nomeUsuarioCriador'],
      nomeResponsavel: json['nomeResponsavel'],
      numeroApartamento: json['numeroApartamento'],
      blocoApartamento: json['blocoApartamento'],
      criadoEm: DateTime.parse(json['criadoEm']),
      prazoLimite: json['prazoLimite'] != null
          ? DateTime.parse(json['prazoLimite'])
          : null,
      quantidadeComentarios: json['quantidadeComentarios'] ?? 0,
      quantidadeAnexos: json['quantidadeAnexos'] ?? 0,
      descricao: json['descricao'] ?? '',
      moradorNome: json['moradorNome'] ?? '',
      comentarios: (json['comentarios'] as List?)
              ?.map((c) => Comentario.fromJson(c))
              .toList() ??
          [],
      historico: (json['historico'] as List?)
              ?.map((h) => HistoricoStatus.fromJson(h))
              .toList() ??
          [],
      anexos: (json['anexos'] as List?)
              ?.map((a) => Anexo.fromJson(a))
              .toList() ??
          [],
    );
  }
}
```

### 10.7 Comentário

```dart
// lib/models/comentario.dart

class Comentario {
  final String id;
  final String texto;
  final String nomeUsuario;
  final DateTime criadoEm;

  Comentario({
    required this.id,
    required this.texto,
    required this.nomeUsuario,
    required this.criadoEm,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      texto: json['texto'],
      nomeUsuario: json['nomeUsuario'],
      criadoEm: DateTime.parse(json['criadoEm']),
    );
  }
}
```

### 10.8 Notificação

```dart
// lib/models/notificacao.dart

class Notificacao {
  final String id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime criadoEm;

  Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      titulo: json['titulo'],
      mensagem: json['mensagem'],
      lida: json['lida'] ?? false,
      criadoEm: DateTime.parse(json['criadoEm']),
    );
  }
}
```

---

## 11. TRATAMENTO DE ERROS

### 11.1 Padrão de Resposta de Erro

```dart
// lib/utils/error_handler.dart

class ErrorHandler {
  static String getErrorMessage(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      
      // Se tiver mensagem específica
      if (data is Map && data['mensagem'] != null) {
        return data['mensagem'];
      }
      
      // Se tiver lista de erros
      if (data is Map && data['erros'] != null) {
        final erros = List<String>.from(data['erros']);
        return erros.join('\n');
      }
      
      // Erros por código HTTP
      switch (e.response!.statusCode) {
        case 400:
          return 'Dados inválidos. Verifique os campos.';
        case 401:
          return 'Sessão expirada. Faça login novamente.';
        case 403:
          return 'Você não tem permissão para esta ação.';
        case 404:
          return 'Recurso não encontrado.';
        case 500:
          return 'Erro no servidor. Tente novamente mais tarde.';
        default:
          return 'Erro ao processar requisição.';
      }
    }
    
    // Erros de conexão
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão excedido. Verifique sua internet.';
    }
    
    if (e.type == DioExceptionType.connectionError) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    
    return 'Erro inesperado. Tente novamente.';
  }

  static void showError(BuildContext context, dynamic error) {
    String message;
    
    if (error is DioException) {
      message = getErrorMessage(error);
    } else if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else {
      message = error.toString();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
```

---

## 12. BOAS PRÁTICAS

### 12.1 Provider Pattern (Estado)

```dart
// lib/providers/solicitacoes_provider.dart

import 'package:flutter/material.dart';
import '../models/solicitacao.dart';
import '../services/solicitacoes_service.dart';

class SolicitacoesProvider extends ChangeNotifier {
  final SolicitacoesService _service = SolicitacoesService();
  
  List<SolicitacaoResumo> _solicitacoes = [];
  bool _isLoading = false;
  String? _error;
  
  int _currentPage = 1;
  bool _hasMore = true;
  
  List<SolicitacaoResumo> get solicitacoes => _solicitacoes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> carregarSolicitacoes({
    String? status,
    bool refresh = false,
  }) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _solicitacoes.clear();
      _hasMore = true;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.listarSolicitacoes(
        pageNumber: _currentPage,
        pageSize: 20,
        status: status,
      );

      if (refresh) {
        _solicitacoes = response.items;
      } else {
        _solicitacoes.addAll(response.items);
      }
      
      _hasMore = response.hasNextPage;
      _currentPage++;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({String? status}) async {
    await carregarSolicitacoes(status: status, refresh: true);
  }
}
```

### 12.2 Widget de Lista com Paginação

```dart
// lib/widgets/solicitacoes_list.dart

class SolicitacoesList extends StatefulWidget {
  final String? status;

  const SolicitacoesList({Key? key, this.status}) : super(key: key);

  @override
  State<SolicitacoesList> createState() => _SolicitacoesListState();
}

class _SolicitacoesListState extends State<SolicitacoesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Carregar dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitacoesProvider>().carregarSolicitacoes(
        status: widget.status,
        refresh: true,
      );
    });
    
    // Adicionar listener de scroll para paginação
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider = context.read<SolicitacoesProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.carregarSolicitacoes(status: widget.status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SolicitacoesProvider>(
      builder: (context, provider, child) {
        if (provider.error != null && provider.solicitacoes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.error!),
                ElevatedButton(
                  onPressed: () => provider.refresh(status: widget.status),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (provider.solicitacoes.isEmpty && !provider.isLoading) {
          return const Center(
            child: Text('Nenhuma solicitação encontrada'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(status: widget.status),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.solicitacoes.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.solicitacoes.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final solicitacao = provider.solicitacoes[index];
              return SolicitacaoCard(solicitacao: solicitacao);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### 12.3 Verificar Permissões por Role

```dart
// lib/utils/permissions.dart

class Permissions {
  static bool canCreateSolicitacao(String role) {
    return ['Morador', 'Funcionario', 'Administrador'].contains(role);
  }

  static bool canDeleteSolicitacao(String role) {
    return role == 'Administrador';
  }

  static bool canUpdateStatus(String role) {
    return ['Funcionario', 'Administrador'].contains(role);
  }

  static bool canViewAllUsers(String role) {
    return ['Funcionario', 'Administrador'].contains(role);
  }

  static bool canCreateApartamento(String role) {
    return ['Funcionario', 'Administrador'].contains(role);
  }
}
```

---

## 13. Notas Owany App

- Este app já possui `ApiService().request<T>()` para tratar baseUrl `https://localhost:7068/api`, injeção de token e extração de `dados`. Prefira usar os services existentes em `lib/services/api_service.dart`.
- Endpoints atuais usam rotas como `'solicitacoes'` (sem `v1`) no app. Se o backend exigir `v1`, ajuste o endpoint no `ApiService` (ou crie wrappers específicos).
- Tema: use sempre `OwanyTheme` para cores/estilos.
- Providers: Estado via Provider (ver `lib/providers/*`).

## 14. Problema conhecido (500) e correção

- Erro atual ao chamar `GET /api/itemapartamento/apartamento/{id}`: 500 com mensagem do EF Core sobre projeção contendo referência a método de instância `ItemApartamentoController.MapItemToDto`.
- Correção no backend: tornar o método de mapeamento `MapItemToDto` `static` ou projetar inline no `Select` para evitar capturar a instância do controller. Referência: https://go.microsoft.com/fwlink/?linkid=2103067.
- Lado cliente: enquanto o backend não for corrigido, a tela de Itens exibe estado de erro amigável com ação de "Tentar Novamente" e detalhes.

---

**Status**: ✅ Pronto para uso  
**Versão da API**: v1 (ajuste conforme disponível)  
**Última atualização**: 2026-02-14

🎉 **Boa sorte com o desenvolvimento!**
