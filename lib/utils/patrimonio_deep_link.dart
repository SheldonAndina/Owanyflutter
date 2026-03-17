import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralizes QR/deep-link URL generation and parsing for patrimonio details.
class PatrimonioDeepLink {
  static const String _defaultHost = 'app.seudominio.com';

  static String get _configuredScheme {
    const value = String.fromEnvironment('PUBLIC_APP_SCHEME', defaultValue: '');
    if (value.trim().isNotEmpty) return value.trim().toLowerCase();
    if (kIsWeb && Uri.base.scheme.trim().isNotEmpty) {
      return Uri.base.scheme.trim().toLowerCase();
    }
    return 'https';
  }

  static String get _configuredHost {
    const value = String.fromEnvironment('PUBLIC_APP_HOST', defaultValue: '');
    if (value.trim().isNotEmpty) return value.trim();
    if (kIsWeb && Uri.base.host.trim().isNotEmpty) {
      return Uri.base.host.trim();
    }
    return _defaultHost;
  }

  static int? get _configuredPort {
    const value = String.fromEnvironment('PUBLIC_APP_PORT', defaultValue: '');
    if (value.trim().isNotEmpty) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0) return parsed;
    }

    if (kIsWeb && Uri.base.hasPort) {
      final p = Uri.base.port;
      if (p > 0 && p != 80 && p != 443) {
        return p;
      }
    }

    return null;
  }

  static Uri buildUri(String codigoPatrimonio) {
    final code = codigoPatrimonio.trim();
    if (code.isEmpty) {
      throw ArgumentError('codigoPatrimonio nao pode ser vazio');
    }

    return Uri(
      scheme: _configuredScheme,
      host: _configuredHost,
      port: _configuredPort,
      pathSegments: ['patrimonio', code],
    );
  }

  static String buildUrl(String codigoPatrimonio) {
    return buildUri(codigoPatrimonio).toString();
  }

  /// Returns QR payload always as URL if [rawOrCode] is a patrimonio code.
  /// Keeps incoming external URLs unchanged.
  static String buildQrPayload(String rawOrCode) {
    final raw = rawOrCode.trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return raw;
    }

    final codigo = extractCodigo(raw, allowStandaloneCode: true);
    if (codigo == null || codigo.isEmpty) return raw;

    return buildUrl(codigo);
  }

  static String? extractCodigoFromUri(Uri uri) {
    final query = _fromQuery(uri.queryParameters);
    if (query != null) return query;

    final segs = uri.pathSegments.where((e) => e.trim().isNotEmpty).toList();
    if (segs.isEmpty) return null;

    for (var i = 0; i < segs.length; i++) {
      if (_isPatrimonioSegment(segs[i]) && i + 1 < segs.length) {
        return Uri.decodeComponent(segs[i + 1].trim());
      }
    }

    if (uri.hasScheme && uri.host.isNotEmpty && segs.length == 1) {
      final only = Uri.decodeComponent(segs.first.trim());
      if (only.isNotEmpty && !_isPatrimonioSegment(only)) {
        return only;
      }
    }

    return null;
  }

  static String? extractCodigo(String raw, {bool allowStandaloneCode = true}) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final inlineMatch = RegExp(
      r'^(patrimonio|patrimonios)[:\s]+(.+)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (inlineMatch != null) {
      final code = inlineMatch.group(2)?.trim();
      if (code != null && code.isNotEmpty) {
        return code;
      }
    }

    final uri = Uri.tryParse(value);
    if (uri != null) {
      final fromUri = extractCodigoFromUri(uri);
      if (fromUri != null && fromUri.isNotEmpty) {
        return fromUri;
      }
    }

    if (!allowStandaloneCode) return null;

    // Handle values that were scanned with surrounding text.
    final tokens = value
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty);
    final tokenList = tokens.toList();
    for (var i = 0; i < tokenList.length; i++) {
      final token = tokenList[i];
      final tokenUri = Uri.tryParse(token);
      if (tokenUri != null) {
        final fromToken = extractCodigoFromUri(tokenUri);
        if (fromToken != null && fromToken.isNotEmpty) {
          return fromToken;
        }
      }
      if (_isPatrimonioSegment(token) && i + 1 < tokenList.length) {
        final next = tokenList[i + 1].trim();
        if (next.isNotEmpty) return next;
      }
    }

    return value;
  }

  static String? _fromQuery(Map<String, String> query) {
    const keys = ['codigo', 'code', 'patrimonio', 'id'];
    for (final key in keys) {
      final value = query[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static bool _isPatrimonioSegment(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'patrimonio' || normalized == 'patrimonios';
  }
}
