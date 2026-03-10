/// Professional Constants for the entire app
/// Single source of truth for app-wide configuration
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://localhost:7068/api';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Storage Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyAppTheme = 'app_theme';
  static const String keyLanguage = 'app_language';
  static const String keyLastSync = 'last_sync';

  // Cache Configuration
  static const Duration cacheDuration = Duration(minutes: 30);
  static const int maxCacheSize = 100;

  // Pagination
  static const int pageSize = 20;
  static const int maxPages = 100;

  // Delays
  static const Duration shortDelay = Duration(milliseconds: 300);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(seconds: 1);

  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int minNameLength = 3;
  static const int maxNameLength = 100;
  static const int phoneLength = 11;

  // Error Messages
  static const Map<String, String> errorMessages = {
    '400': 'Requisição inválida',
    '401': 'Não autorizado - faça login novamente',
    '403': 'Acesso negado',
    '404': 'Recurso não encontrado',
    '409': 'Conflito de dados',
    '500': 'Erro no servidor',
    'timeout': 'Conexão expirou',
    'no_internet': 'Sem conexão de internet',
    'unknown': 'Erro desconhecido',
  };

  // Endpoints
  static const String endpointLogin = 'auth/login';
  static const String endpointLogout = 'auth/logout';
  static const String endpointUsuarios = 'usuarios';
  static const String endpointMoradores = 'moradores';
  static const String endpointApartamentos = 'apartamentos';
  static const String endpointSolicitacoes = 'solicitacoes';

  // Regex Patterns
  static const String regexEmail = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String regexPhone = r'^\d{10,11}$';
  static const String regexNumeric = r'^\d+$';
  static const String regexAlphanumeric = r'^[a-zA-Z0-9]+$';
}
