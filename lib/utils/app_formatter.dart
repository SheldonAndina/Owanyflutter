import 'package:intl/intl.dart';

/// Professional formatting utilities
class AppFormatter {
  /// Format date to Brazilian format (dd/MM/yyyy)
  static String formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date and time to Brazilian format (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--/--/---- --:--';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Format time (HH:mm)
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format relative time (e.g., "há 2 horas")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'data desconhecida';

    // Ensure we're comparing in the same timezone (local)
    // Backend often sends UTC, so convert to local time
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    // Handle negative differences (future dates or clock skew)
    if (difference.isNegative) {
      return 'agora mesmo';
    }

    if (difference.inSeconds < 60) {
      return 'agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays}d';
    } else {
      return formatDate(localDateTime);
    }
  }

  /// Format phone number (XX) XXXXX-XXXX
  static String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 11) return phone;
    return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 7)}-${cleaned.substring(7)}';
  }

  /// Format CPF (XXX.XXX.XXX-XX)
  static String formatCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '';
    final cleaned = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 11) return cpf;
    return '${cleaned.substring(0, 3)}.${cleaned.substring(3, 6)}.${cleaned.substring(6, 9)}-${cleaned.substring(9)}';
  }

  /// Format CNPJ (XX.XXX.XXX/XXXX-XX)
  static String formatCNPJ(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) return '';
    final cleaned = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 14) return cnpj;
    return '${cleaned.substring(0, 2)}.${cleaned.substring(2, 5)}.${cleaned.substring(5, 8)}/${cleaned.substring(8, 12)}-${cleaned.substring(12)}';
  }

  /// Format currency (MZN)
  static String formatCurrency(double? value) {
    if (value == null) return 'MZN 0,00';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'MZN ').format(value);
  }

  /// Format percentage
  static String formatPercentage(double? value) {
    if (value == null) return '0%';
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Format number with thousand separator
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat('#,##0', 'pt_BR').format(value);
  }

  /// Capitalize first letter
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeWords(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, int length) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }

  /// Remove special characters
  static String removeSpecialChars(String? text) {
    if (text == null) return '';
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Get initials from name (max 2 chars)
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  /// Sanitize file name
  static String sanitizeFileName(String? fileName) {
    if (fileName == null || fileName.isEmpty) return 'file';
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Format duration (mm:ss or hh:mm:ss)
  static String formatDuration(Duration? duration) {
    if (duration == null) return '00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format file size (B, KB, MB, GB)
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';

    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else if (bytes < gb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / gb).toStringAsFixed(2)} GB';
    }
  }
}
