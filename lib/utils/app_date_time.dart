DateTime parseBackendDateTimeToLocal(
  dynamic raw, {
  DateTime? fallback,
}) {
  final fallbackValue = fallback ?? DateTime.now();
  if (raw == null) return fallbackValue;

  final value = raw.toString().trim();
  if (value.isEmpty) return fallbackValue;

  final normalized = value.replaceFirst(' ', 'T');
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
  final toParse = hasTimezone ? normalized : '${normalized}Z';

  try {
    return DateTime.parse(toParse).toLocal();
  } catch (_) {
    return DateTime.tryParse(normalized)?.toLocal() ?? fallbackValue;
  }
}

DateTime? tryParseBackendDateTimeToLocal(dynamic raw) {
  if (raw == null) return null;

  final value = raw.toString().trim();
  if (value.isEmpty) return null;

  final normalized = value.replaceFirst(' ', 'T');
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
  final toParse = hasTimezone ? normalized : '${normalized}Z';

  try {
    return DateTime.parse(toParse).toLocal();
  } catch (_) {
    return DateTime.tryParse(normalized)?.toLocal();
  }
}

String toBackendUtcIsoString(DateTime value) => value.toUtc().toIso8601String();
