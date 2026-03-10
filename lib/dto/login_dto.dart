import '../models/models.dart';
import '../utils/app_date_time.dart';
import '../utils/app_logger.dart';

// ======================================================
// API RESPONSE WRAPPER
// ======================================================
class ApiResponse<T> {
  final bool sucesso;
  final String mensagem;
  final T? data;
  final String? erro;

  ApiResponse({
    required this.sucesso,
    required this.mensagem,
    this.data,
    this.erro,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse<T>(
      sucesso: json['sucesso'] ?? false,
      mensagem: (json['mensagem'] ?? '').toString(),
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null,
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }

  @override
  String toString() => 'ApiResponse(sucesso: $sucesso, mensagem: $mensagem, erro: $erro)';
}

// ======================================================
// LOGIN RESULT
// ======================================================
class LoginResult {
  final bool sucesso;
  final String token;
  final Usuario usuario;
  final String? erro;

  LoginResult({
    required this.sucesso,
    required this.token,
    required this.usuario,
    this.erro,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      sucesso: json['sucesso'] ?? true,
      token: (json['token'] ?? '').toString(),
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>? ?? {}),
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sucesso': sucesso,
      'token': token,
      'usuario': usuario.toJson(),
      'erro': erro,
    };
  }

  @override
  String toString() => 'LoginResult(sucesso: $sucesso, token: ${token.substring(0, 20)}..., usuario: ${usuario.nome})';
}

// ======================================================
// REQUEST OTP RESPONSE
// ======================================================
class RequestOtpResponse {
  final bool sucesso;
  final String mensagem;
  final String? otpId;
  final String? erro;

  RequestOtpResponse({
    required this.sucesso,
    required this.mensagem,
    this.otpId,
    this.erro,
  });

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) {
    return RequestOtpResponse(
      sucesso: json['sucesso'] ?? false,
      mensagem: (json['mensagem'] ?? '').toString(),
      otpId: json['data'] != null ? (json['data'] ?? '').toString() : null,
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }
}

// ======================================================
// VALIDATE OTP RESPONSE
// ======================================================
class ValidateOtpResponse {
  final bool sucesso;
  final String mensagem;
  final String? validationToken;
  final String? erro;

  ValidateOtpResponse({
    required this.sucesso,
    required this.mensagem,
    this.validationToken,
    this.erro,
  });

  factory ValidateOtpResponse.fromJson(Map<String, dynamic> json) {
    return ValidateOtpResponse(
      sucesso: json['sucesso'] ?? false,
      mensagem: (json['mensagem'] ?? '').toString(),
      validationToken: json['data'] != null ? (json['data'] ?? '').toString() : null,
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }
}

// ======================================================
// RESET PASSWORD RESPONSE
// ======================================================
class ResetPasswordResponse {
  final bool sucesso;
  final String mensagem;
  final String? data;
  final String? erro;

  ResetPasswordResponse({
    required this.sucesso,
    required this.mensagem,
    this.data,
    this.erro,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      sucesso: json['sucesso'] ?? false,
      mensagem: (json['mensagem'] ?? '').toString(),
      data: json['data'] != null ? (json['data'] ?? '').toString() : null,
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }
}

// ======================================================
// REFRESH TOKEN RESPONSE
// ======================================================
class RefreshTokenResponse {
  final bool sucesso;
  final String mensagem;
  final LoginResult? data;
  final String? erro;

  RefreshTokenResponse({
    required this.sucesso,
    required this.mensagem,
    this.data,
    this.erro,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      sucesso: json['sucesso'] ?? false,
      mensagem: (json['mensagem'] ?? '').toString(),
      data: json['data'] != null
          ? LoginResult.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      erro: json['erro'] != null ? (json['erro'] ?? '').toString() : null,
    );
  }
}

// ======================================================
// BACKEND AUTH DTOs - Conformidade com API Documentation
// ======================================================

/// DTO para resposta de login (conforme backend docs)
class LoginResponse {
  final String token;
  final String usuarioId;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String role;
  final String expiracao;
  final String? refreshToken;
  final DateTime? ultimoLoginEm;

  LoginResponse({
    required this.token,
    required this.usuarioId,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.role,
    required this.expiracao,
    this.refreshToken,
    this.ultimoLoginEm,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final ultimoLoginRaw = usuario?['ultimoLoginEm'] ?? json['ultimoLoginEm'];
    
    // Extract role - NO DEFAULT, fail if missing
    final role = json['role'] ?? usuario?['tipo'] ?? '';
    if (role.isEmpty) {
      AppLogger.error('LoginDTO', '[ERROR] Login response missing role/tipo field! Full JSON: $json');
      throw ArgumentError('Backend did not return user role in login response');
    }
    
    return LoginResponse(
      token: json['token'] ?? '',
      usuarioId: json['usuarioId'] ?? json['id'] ?? usuario?['id'] ?? '',
      nome: json['nome'] ?? usuario?['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? usuario?['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? usuario?['telefone'] ?? '',
      role: role,
      expiracao: json['expiracao'] ?? DateTime.now().add(Duration(days: 7)).toIso8601String(),
      refreshToken: json['refreshToken'],
      ultimoLoginEm: ultimoLoginRaw != null
          ? tryParseBackendDateTimeToLocal(ultimoLoginRaw.toString())
          : null,
    );
  }
}

/// DTO para resposta de "Esqueci a Senha"
class EsqueceuSenhaResponseDto {
  final String telefone;
  final String expiraEm;

  EsqueceuSenhaResponseDto({
    required this.telefone,
    required this.expiraEm,
  });

  factory EsqueceuSenhaResponseDto.fromJson(Map<String, dynamic> json) {
    return EsqueceuSenhaResponseDto(
      telefone: json['telefone'] ?? json['data']?['telefone'] ?? '',
      expiraEm: json['expiraEm'] ?? json['data']?['expiraEm'] ?? '',
    );
  }
}

/// DTO para verificação de token
class TokenVerificationDto {
  final String usuarioId;
  final String nome;
  final String role;
  final String expira;

  TokenVerificationDto({
    required this.usuarioId,
    required this.nome,
    required this.role,
    required this.expira,
  });

  factory TokenVerificationDto.fromJson(Map<String, dynamic> json) {
    return TokenVerificationDto(
      usuarioId: json['usuarioId'] ?? '',
      nome: json['nome'] ?? '',
      role: json['role'] ?? 'Morador',
      expira: json['expira'] ?? '',
    );
  }
}






