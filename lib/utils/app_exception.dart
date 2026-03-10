import '../constants/app_constants.dart';
import 'app_logger.dart';

/// Custom exception types for better error handling
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({required this.message, this.code, this.originalError, this.stackTrace});

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException({super.message = 'Erro de conexão', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'NETWORK_ERROR', originalError: error);
}

/// Timeout exception
class TimeoutException extends AppException {
  TimeoutException({super.message = 'Conexão expirou', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'TIMEOUT', originalError: error);
}

/// HTTP error exceptions
class HttpException extends AppException {
  final int statusCode;

  HttpException({required this.statusCode, String? message, String? code, dynamic error, super.stackTrace})
    : super(message: message ?? _getDefaultMessage(statusCode), code: code ?? 'HTTP_$statusCode', originalError: error);

  static String _getDefaultMessage(int statusCode) {
    return AppConstants.errorMessages['$statusCode'] ?? 'Erro HTTP $statusCode';
  }
}

/// Unauthorized (401) exception
class UnauthorizedException extends HttpException {
  UnauthorizedException({String? message, String? code, super.error, super.stackTrace})
    : super(statusCode: 401, message: message ?? 'Não autorizado - faça login novamente', code: code ?? 'UNAUTHORIZED');
}

/// Forbidden (403) exception
class ForbiddenException extends HttpException {
  ForbiddenException({String? message, String? code, super.error, super.stackTrace})
    : super(statusCode: 403, message: message ?? 'Acesso negado', code: code ?? 'FORBIDDEN');
}

/// Not found (404) exception
class NotFoundException extends HttpException {
  NotFoundException({String? message, String? code, super.error, super.stackTrace})
    : super(statusCode: 404, message: message ?? 'Recurso não encontrado', code: code ?? 'NOT_FOUND');
}

/// Validation exception
class ValidationException extends AppException {
  final List<String>? errors;

  ValidationException({super.message = 'Dados inválidos', String? code, this.errors, dynamic error, super.stackTrace})
    : super(code: code ?? 'VALIDATION_ERROR', originalError: error);
}

/// No internet connection exception
class NoInternetException extends AppException {
  NoInternetException({super.message = 'Sem conexão com a internet', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'NO_INTERNET', originalError: error);
}

/// Parsing exception
class ParsingException extends AppException {
  ParsingException({super.message = 'Erro ao processar dados', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'PARSING_ERROR', originalError: error);
}

/// Storage exception
class StorageException extends AppException {
  StorageException({super.message = 'Erro ao acessar armazenamento', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'STORAGE_ERROR', originalError: error);
}

/// Authentication exception
class AuthenticationException extends AppException {
  AuthenticationException({super.message = 'Erro de autenticação', String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'AUTH_ERROR', originalError: error);
}

/// Generic app exception
class GenericException extends AppException {
  GenericException({required super.message, String? code, dynamic error, super.stackTrace})
    : super(code: code ?? 'GENERIC_ERROR', originalError: error);
}

/// Exception handler utility
class ExceptionHandler {
  static const String _tag = 'ExceptionHandler';

  /// Handle exception and return user-friendly message
  static String handleException(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error(_tag, 'Exception caught', error, stackTrace);

    if (error is AppException) {
      return error.message;
    } else if (error is FormatException) {
      return 'Erro ao processar dados';
    } else if (error is TypeError) {
      return 'Erro ao processar dados';
    } else if (error is NoSuchMethodError) {
      return 'Operação não disponível';
    } else {
      return 'Erro desconhecido: ${error.toString()}';
    }
  }

  /// Create appropriate exception from error response
  static AppException createException(int statusCode, String? message, {dynamic error, StackTrace? stackTrace}) {
    switch (statusCode) {
      case 400:
        return ValidationException(message: message ?? 'Requisição inválida', error: error, stackTrace: stackTrace);
      case 401:
        return UnauthorizedException(message: message, error: error, stackTrace: stackTrace);
      case 403:
        return ForbiddenException(message: message, error: error, stackTrace: stackTrace);
      case 404:
        return NotFoundException(message: message, error: error, stackTrace: stackTrace);
      case 409:
        return ValidationException(message: message ?? 'Conflito de dados', error: error, stackTrace: stackTrace);
      case 500:
      case 502:
      case 503:
        return GenericException(message: message ?? 'Erro no servidor', error: error, stackTrace: stackTrace);
      default:
        return HttpException(statusCode: statusCode, message: message, error: error, stackTrace: stackTrace);
    }
  }

  /// Safely execute async operation with error handling
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    void Function(AppException)? onError,
    String? tag,
  }) async {
    try {
      return await operation();
    } on AppException catch (e, stackTrace) {
      AppLogger.error(tag ?? _tag, e.message, e.originalError, stackTrace);
      onError?.call(e);
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(tag ?? _tag, 'Unexpected error', e, stackTrace);
      onError?.call(GenericException(message: 'Erro inesperado', error: e, stackTrace: stackTrace));
      return null;
    }
  }
}
