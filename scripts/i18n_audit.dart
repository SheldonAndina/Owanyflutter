import 'dart:io';

final _ignoredPathTokens = <String>[
  '.intl_backup.dart',
  '/generated_l10n/',
  r'\generated_l10n\',
];

final _ignoredFileNames = <String>{
  'app_localizations.dart',
  'app_localizations_en.dart',
  'app_localizations_pt.dart',
};

final _hardcodedPatterns = <RegExp>[
  RegExp(r"Text\(\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"labelText:\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"hintText:\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"tooltip:\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"title:\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"subtitle:\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"snackBar\(\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
  RegExp(r"SnackBar\([^)]*Text\(\s*'[^']*[A-Za-zÀ-ÿ][^']*'"),
];

void main() {
  final projectRoot = Directory.current.path;
  final ptArb = File('$projectRoot/lib/l10n/app_pt.arb');
  final enArb = File('$projectRoot/lib/l10n/app_en.arb');

  final arbErrors = _validateArbKeys(ptArb, enArb);
  final hardcoded = _scanHardcodedStrings(Directory('$projectRoot/lib'));

  if (arbErrors.isNotEmpty) {
    stdout.writeln('ARB consistency errors:');
    for (final err in arbErrors) {
      stdout.writeln('- $err');
    }
  }

  if (hardcoded.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('Hardcoded UI strings found (${hardcoded.length}):');
    for (final issue in hardcoded) {
      stdout.writeln('- ${issue.path}:${issue.line}: ${issue.preview}');
    }
  }

  if (arbErrors.isNotEmpty || hardcoded.isNotEmpty) {
    exitCode = 1;
    return;
  }

  stdout.writeln('i18n audit passed.');
}

List<String> _validateArbKeys(File ptArb, File enArb) {
  if (!ptArb.existsSync() || !enArb.existsSync()) {
    return ['ARB files not found in lib/l10n'];
  }

  final ptKeys = _extractArbDataKeys(ptArb.readAsStringSync());
  final enKeys = _extractArbDataKeys(enArb.readAsStringSync());

  final missingInEn = ptKeys.difference(enKeys).toList()..sort();
  final missingInPt = enKeys.difference(ptKeys).toList()..sort();

  final errors = <String>[];
  if (missingInEn.isNotEmpty) {
    errors.add('Missing keys in app_en.arb: ${missingInEn.join(', ')}');
  }
  if (missingInPt.isNotEmpty) {
    errors.add('Missing keys in app_pt.arb: ${missingInPt.join(', ')}');
  }
  return errors;
}

Set<String> _extractArbDataKeys(String content) {
  final keyRegex = RegExp(r'"([^"]+)":');
  final keys = <String>{};
  for (final m in keyRegex.allMatches(content)) {
    final key = m.group(1)!;
    if (key.startsWith('@')) continue;
    keys.add(key);
  }
  return keys;
}

List<_Issue> _scanHardcodedStrings(Directory libDir) {
  final issues = <_Issue>[];
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final normalized = file.path.replaceAll('\\', '/');
    if (_ignoredPathTokens.any(normalized.contains)) continue;
    final name = normalized.split('/').last;
    if (_ignoredFileNames.contains(name)) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      if (trimmed.startsWith('//')) continue;
      if (trimmed.startsWith('///')) continue;
      if (trimmed.startsWith('*')) continue;
      if (trimmed.contains('AppLocalizations.of(context)!')) continue;

      final matched = _hardcodedPatterns.any((r) => r.hasMatch(line));
      if (!matched) continue;

      issues.add(_Issue(
        path: normalized,
        line: i + 1,
        preview: trimmed.length > 140 ? '${trimmed.substring(0, 140)}...' : trimmed,
      ));
    }
  }

  return issues;
}

class _Issue {
  final String path;
  final int line;
  final String preview;

  _Issue({
    required this.path,
    required this.line,
    required this.preview,
  });
}
