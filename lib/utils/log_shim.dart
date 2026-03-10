import 'app_logger.dart';

/// Lightweight shim to replace ad-hoc prints across the codebase.
/// Usage: replace `print(...)` or `debugPrint(...)` with `printLog(...)`.
void printLog(Object? message) {
  final s = message?.toString() ?? '';
  // Heuristic routing
  final lower = s.toLowerCase();
  if (lower.contains('erro') || lower.contains('error') || lower.contains('exception') || lower.contains('fail')) {
    AppLogger.error('Auto', s);
  } else if (s.contains('✅') || lower.contains('sucesso') || lower.contains('created') || lower.contains('criado')) {
    AppLogger.info('Auto', s);
  } else {
    AppLogger.debug('Auto', s);
  }
}

/// Backwards-compatible alias for debugPrint usages.
void debugPrintLog(String? message) => printLog(message);
