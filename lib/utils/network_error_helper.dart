class NetworkErrorHelper {
  static const List<String> _offlineMarkers = [
    'erro de conexão',
    'erro de conexao',
    'sem conexão',
    'sem conexao',
    'connection refused',
    'connection reset',
    'connection aborted',
    'connection closed',
    'failed host lookup',
    'socketexception',
    'handshakeexception',
    'network is unreachable',
    'timed out',
    'timeout',
    'unable to connect',
    'server unavailable',
    '503',
    '502',
    'no route to host',
  ];

  static bool isServerOffline(dynamic error) {
    final text = (error ?? '').toString().toLowerCase();
    if (text.isEmpty) return false;
    return _offlineMarkers.any(text.contains);
  }

  static String offlineTitle() => 'Servidor indisponível';

  static String offlineMessage() =>
      'Não foi possível comunicar com o servidor no momento. Verifique a conexão e tente novamente.';
}

