import 'package:flutter/material.dart';
import 'app_formatter.dart';
import 'app_validator.dart';

/// String extensions for common operations
extension StringExtensions on String {
  /// Check if string is empty or whitespace
  bool get isBlank => isEmpty || trim().isEmpty;

  /// Check if string is not empty
  bool get isNotBlank => isNotEmpty && trim().isNotEmpty;

  /// Capitalize first letter
  String get capitalized => AppFormatter.capitalize(this);

  /// Capitalize each word
  String get capitalizedWords => AppFormatter.capitalizeWords(this);

  /// Remove special characters
  String get removedSpecialChars => AppFormatter.removeSpecialChars(this);

  /// Get initials
  String get initials => AppFormatter.getInitials(this);

  /// Truncate with ellipsis
  String truncate(int length) => AppFormatter.truncate(this, length);

  /// Format as phone
  String get formattedPhone => AppFormatter.formatPhone(this);

  /// Format as CPF
  String get formattedCPF => AppFormatter.formatCPF(this);

  /// Format as CNPJ
  String get formattedCNPJ => AppFormatter.formatCNPJ(this);

  /// Validate email
  String? get emailError => AppValidator.validateEmail(this);

  /// Validate phone
  String? get phoneError => AppValidator.validatePhone(this);

  /// Validate URL
  String? get urlError => AppValidator.validateUrl(this);

  /// Check if is valid email
  bool get isValidEmail => AppValidator.validateEmail(this) == null;

  /// Check if is valid phone
  bool get isValidPhone => AppValidator.validatePhone(this) == null;

  /// Check if is valid URL
  bool get isValidUrl => AppValidator.validateUrl(this) == null;

  /// Convert to integer or null
  int? toIntOrNull() => int.tryParse(this);

  /// Convert to double or null
  double? toDoubleOrNull() => double.tryParse(this);

  /// Convert to boolean
  bool toBool() {
    final lower = toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'sim';
  }

  /// Remove all spaces
  String removeSpaces() => replaceAll(' ', '');

  /// Keep only numeric characters
  String onlyNumbers() => replaceAll(RegExp(r'\D'), '');

  /// Replace multiple occurrences
  String replaceMultiple(Map<String, String> replacements) {
    String result = this;
    replacements.forEach((oldValue, newValue) {
      result = result.replaceAll(oldValue, newValue);
    });
    return result;
  }

  /// Check if contains all strings
  bool containsAll(List<String> strings) {
    return strings.every((s) => contains(s));
  }

  /// Check if contains any string
  bool containsAny(List<String> strings) {
    return strings.any((s) => contains(s));
  }

  /// Reverse string
  String reverse() => split('').reversed.join('');

  /// Check if is palindrome
  bool get isPalindrome => this == reverse();

  /// Count occurrences of character
  int countOccurrences(String char) {
    return RegExp(RegExp.escape(char)).allMatches(this).length;
  }

  /// Repeat string n times
  String repeatTimes(int times) => this * times;

  /// Split by multiple delimiters
  List<String> splitByMultiple(List<String> delimiters) {
    if (delimiters.isEmpty) return [this];

    String pattern = delimiters.map(RegExp.escape).join('|');
    return split(RegExp(pattern));
  }

  /// Get first character
  String? get firstChar => isEmpty ? null : this[0];

  /// Get last character
  String? get lastChar => isEmpty ? null : this[length - 1];

  /// Limit to specified length
  String limit(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength) + suffix;
  }

  /// Color as hex string (with # prefix)
  /// Example: "#FF5733".toColor()
  Color? toColor() {
    String hexString = replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    try {
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Check if matches regex pattern
  bool matchesRegex(String pattern) {
    try {
      return RegExp(pattern).hasMatch(this);
    } catch (e) {
      return false;
    }
  }
}

/// DateTime extensions for common operations
extension DateTimeExtensions on DateTime {
  /// Format using AppFormatter
  String get formatted => AppFormatter.formatDate(this);

  /// Format with time
  String get formattedWithTime => AppFormatter.formatDateTime(this);

  /// Format just time
  String get formattedTime => AppFormatter.formatTime(this);

  /// Relative time (ago)
  String get relativeTime => AppFormatter.formatRelativeTime(this);

  /// Check if is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Check if is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if is past
  bool get isPast => isBefore(DateTime.now());

  /// Check if is future
  bool get isFuture => isAfter(DateTime.now());

  /// Get age in years
  int get ageInYears {
    final today = DateTime.now();
    int age = today.year - year;
    if (today.month < month || (today.month == month && today.day < day)) {
      age--;
    }
    return age;
  }

  /// Start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// End of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Start of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// End of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Start of year
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  /// End of year
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  /// Get day of week as string
  String get dayOfWeekName {
    const days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }

  /// Get month name
  String get monthName {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }

  /// Add months
  DateTime addMonths(int months) {
    return DateTime(year, month + months, day);
  }

  /// Subtract months
  DateTime subtractMonths(int months) {
    return addMonths(-months);
  }

  /// Is same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Days between this and another date
  int daysBetween(DateTime other) {
    return difference(other).inDays.abs();
  }
}

/// List extensions for common operations
extension ListExtensions<T> on List<T> {
  /// Check if list is not empty
  bool get isNotEmpty => length > 0;

  /// Get or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Last or null
  T? get lastOrNull => isEmpty ? null : last;

  /// First or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    if (size <= 0) return [];
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Remove duplicates
  List<T> removeDuplicates() {
    return toSet().toList();
  }

  /// Filter not null
  List<T> whereNotNull() {
    return where((item) => item != null).toList();
  }

  /// Find index of element or -1
  int findIndex(bool Function(T) predicate) {
    for (int i = 0; i < length; i++) {
      if (predicate(this[i])) {
        return i;
      }
    }
    return -1;
  }

  /// Flatten nested lists
  List<T> flatten() {
    final result = <T>[];
    for (final item in this) {
      if (item is List<T>) {
        result.addAll(item.flatten());
      } else {
        result.add(item);
      }
    }
    return result;
  }

  /// Join with separator and optional last separator
  String joinWith(String separator, {String? lastSeparator}) {
    if (isEmpty) return '';
    if (length == 1) return this[0].toString();

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(this[i]);
      if (i < length - 1) {
        if (i == length - 2 && lastSeparator != null) {
          buffer.write(lastSeparator);
        } else {
          buffer.write(separator);
        }
      }
    }
    return buffer.toString();
  }
}

/// Map extensions for common operations
extension MapExtensions<K, V> on Map<K, V> {
  /// Get or null
  V? getOrNull(K key) {
    return containsKey(key) ? this[key] : null;
  }

  /// Get with default value
  V getOrDefault(K key, V defaultValue) {
    return containsKey(key) ? this[key]! : defaultValue;
  }

  /// Transform values
  Map<K, U> mapValues<U>(U Function(V) transformer) {
    final result = <K, U>{};
    forEach((key, value) {
      result[key] = transformer(value);
    });
    return result;
  }

  /// Filter by keys
  Map<K, V> filterByKeys(bool Function(K) predicate) {
    final result = <K, V>{};
    forEach((key, value) {
      if (predicate(key)) {
        result[key] = value;
      }
    });
    return result;
  }

  /// Filter by values
  Map<K, V> filterByValues(bool Function(V) predicate) {
    final result = <K, V>{};
    forEach((key, value) {
      if (predicate(value)) {
        result[key] = value;
      }
    });
    return result;
  }

  /// Merge with another map
  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }

  /// Invert keys and values
  Map<V, K> invert() {
    final result = <V, K>{};
    forEach((key, value) {
      result[value] = key;
    });
    return result;
  }
}

/// Nullable extensions
extension NullableExtensions<T> on T? {
  /// Execute function if not null
  R? let<R>(R Function(T) fn) {
    if (this == null) return null;
    return fn(this as T);
  }

  /// Execute function if null
  T? ifNull(T Function() fn) {
    if (this == null) return fn();
    return this;
  }

  /// Return value or default
  T orDefault(T defaultValue) {
    return this ?? defaultValue;
  }

  /// Check if is null
  bool get isNull => this == null;

  /// Check if is not null
  bool get isNotNull => this != null;
}
