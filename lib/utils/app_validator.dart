import '../constants/app_constants.dart';

/// Professional validation utility
class AppValidator {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final regex = RegExp(AppConstants.regexEmail);
    if (!regex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Validate phone format
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(AppConstants.regexPhone).hasMatch(cleaned)) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Senha deve ter no mínimo ${AppConstants.minPasswordLength} caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um número';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordMatch(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != original) {
      return 'Senhas não correspondem';
    }
    return null;
  }

  /// Validate name format
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.length < AppConstants.minNameLength) {
      return 'Nome deve ter no mínimo ${AppConstants.minNameLength} caracteres';
    }
    if (value.length > AppConstants.maxNameLength) {
      return 'Nome não pode ter mais de ${AppConstants.maxNameLength} caracteres';
    }
    return null;
  }

  /// Validate generic required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Validate numeric field
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    if (!RegExp(AppConstants.regexNumeric).hasMatch(value)) {
      return '$fieldName deve conter apenas números';
    }
    return null;
  }

  /// Validate CPF format (simplified)
  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL é obrigatória';
    }
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'URL inválida';
    }
  }

  /// Check if value meets minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    if (value.length < minLength) {
      return '$fieldName deve ter no mínimo $minLength caracteres';
    }
    return null;
  }

  /// Check if value meets maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    if (value.length > maxLength) {
      return '$fieldName não pode ter mais de $maxLength caracteres';
    }
    return null;
  }
}
