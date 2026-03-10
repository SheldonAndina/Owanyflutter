import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../utils/app_exception.dart';

/// Base mixin para todos os providers
/// Fornece métodos padrão para logging, error handling, loading states
mixin BaseProviderMixin {
  String get _tag => 'Provider';

  /// Log a debug message
  void log(String message) {
    AppLogger.debug(_tag, message);
  }

  /// Log an info message
  void logInfo(String message) {
    AppLogger.info(_tag, message);
  }

  /// Log a warning message
  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      AppLogger.warning(_tag, '$message: $error');
    } else {
      AppLogger.warning(_tag, message);
    }
  }

  /// Log an error message
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      AppLogger.error(_tag, '$message: $error');
    } else {
      AppLogger.error(_tag, message);
    }
  }

  /// Format error message for user display
  String formatErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is Exception) {
      return ExceptionHandler.handleException(error);
    } else {
      return 'Erro desconhecido';
    }
  }

  /// Safely execute async operation with automatic logging
  Future<T?> safeExecute<T>(Future<T> Function() operation, {String? operationName}) async {
    try {
      if (operationName != null) log('Iniciando: $operationName');
      final result = await operation();
      if (operationName != null) log('Sucesso: $operationName');
      return result;
    } on AppException catch (e, stackTrace) {
      logError('${operationName ?? 'Operação'} falhou', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      logError('${operationName ?? 'Operação'} falhou (inesperado)', e, stackTrace);
      return null;
    }
  }

  /// Check if error is auth related (401, 403)
  bool isAuthError(dynamic error) {
    return error is UnauthorizedException || error is ForbiddenException;
  }

  /// Check if error is network related
  bool isNetworkError(dynamic error) {
    return error is NetworkException || error is NoInternetException || error is TimeoutException;
  }

  /// Check if error is validation related
  bool isValidationError(dynamic error) {
    return error is ValidationException;
  }
}

/// Enhanced ChangeNotifier with base provider functionality
abstract class BaseProvider extends ChangeNotifier with BaseProviderMixin {
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Set loading state
  @protected
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Set error message
  @protected
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// Set error from exception
  @protected
  void setErrorFromException(dynamic error) {
    final message = formatErrorMessage(error);
    setError(message);
  }

  /// Clear error message
  @protected
  void clearError() {
    setError(null);
  }

  /// Reset provider state
  @protected
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Execute operation with automatic state management
  @protected
  Future<T?> executeOperation<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    String? operationName,
    bool clearErrorBefore = true,
    bool skipIfLoading = true,
  }) async {
    // Guard: prevent duplicate concurrent requests
    if (skipIfLoading && _isLoading) {
      log('${operationName ?? 'Operação'} ignorada — já em carregamento');
      return null;
    }
    try {
      if (clearErrorBefore) clearError();
      if (showLoading) setLoading(true);

      if (operationName != null) log('Executando: $operationName');
      final result = await operation();

      clearError();
      log('${operationName ?? 'Operação'} sucedida');
      return result;
    } on AppException catch (e, stackTrace) {
      logError('${operationName ?? 'Operação'} falhou', e, stackTrace);
      setErrorFromException(e);
      return null;
    } catch (e, stackTrace) {
      logError('${operationName ?? 'Operação'} falhou', e, stackTrace);
      setErrorFromException(e);
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }
}

/// Paginated data provider mixin
mixin PaginationMixin {
  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void setPageSize(int size) {
    _pageSize = size;
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
  }

  void incrementPage() {
    _currentPage++;
  }

  void setHasMore(bool value) {
    _hasMore = value;
  }

  void setIsLoadingMore(bool value) {
    _isLoadingMore = value;
  }
}

/// Cache mixin for providers
mixin CacheMixin<T> {
  DateTime? _lastCacheTime;
  Duration _cacheDuration = const Duration(minutes: 30);
  T? _cachedData;

  bool get isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!).inMilliseconds < _cacheDuration.inMilliseconds;
  }

  T? get cachedData => isCacheValid ? _cachedData : null;

  void updateCache(T data) {
    _cachedData = data;
    _lastCacheTime = DateTime.now();
  }

  void invalidateCache() {
    _cachedData = null;
    _lastCacheTime = null;
  }

  void setCacheDuration(Duration duration) {
    _cacheDuration = duration;
  }
}
