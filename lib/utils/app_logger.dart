import 'package:flutter/foundation.dart';

/// Log levels for structured logging
enum LogLevel { debug, info, warning, error, critical }

/// Professional logging utility
/// Use this instead of print() for production-ready logging
class AppLogger {
  static final List<LogEntry> _logs = [];
  static const int maxLogSize = 1000;
  static bool debugMode = !kReleaseMode;

  /// Log debug message (only in debug mode)
  static void debug(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (debugMode) {
      _log(LogLevel.debug, tag, message, error, stackTrace);
    }
  }

  /// Log info message
  static void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Log warning message
  static void warning(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  /// Log error message
  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  /// Log critical error
  static void critical(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, tag, message, error, stackTrace);
  }

  /// Internal log method
  static void _log(LogLevel level, String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now();
    final entry = LogEntry(
      timestamp: timestamp,
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);

    // Keep logs size manageable
    if (_logs.length > maxLogSize) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    if (debugMode) {
      _printLog(entry);
    }
  }

  /// Print log to console
  static void _printLog(LogEntry entry) {
    final levelString = entry.level.toString().split('.').last.toUpperCase();
    final timeString = _formatTime(entry.timestamp);

    final buffer = StringBuffer();
    buffer.writeln('[$timeString] [$levelString] [${entry.tag}]');
    buffer.writeln('  Message: ${entry.message}');

    if (entry.error != null) {
      buffer.writeln('  Error: ${entry.error}');
    }
    if (entry.stackTrace != null) {
      buffer.writeln('  StackTrace:\n${entry.stackTrace}');
    }

    debugPrint(buffer.toString());
  }

  /// Format timestamp for log display
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}.${dateTime.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get all logs
  static List<LogEntry> getLogs() => List.from(_logs);

  /// Clear all logs
  static void clearLogs() => _logs.clear();

  /// Export logs as formatted string
  static String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== APP LOGS ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('');

    for (final entry in _logs) {
      buffer.writeln(_formatLogEntry(entry));
    }

    return buffer.toString();
  }

  /// Format single log entry
  static String _formatLogEntry(LogEntry entry) {
    final buffer = StringBuffer();
    final timeString = _formatTime(entry.timestamp);
    final levelString = entry.level.toString().split('.').last.toUpperCase();

    buffer.write('[$timeString] [$levelString] [${entry.tag}] ${entry.message}');
    if (entry.error != null) {
      buffer.write(' | Error: ${entry.error}');
    }

    return buffer.toString();
  }

  /// Get logs for specific tag
  static List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  /// Get logs for specific level
  static List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get errors and critical logs
  static List<LogEntry> getErrorLogs() {
    return _logs.where((log) => log.level == LogLevel.error || log.level == LogLevel.critical).toList();
  }
}

/// Log entry data structure
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => '$timestamp [$level] [$tag] $message';
}
