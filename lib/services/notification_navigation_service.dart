import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/models.dart';

typedef BoolResolver = bool Function();

class NotificationNavigationService {
  NotificationNavigationService._internal();
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  BoolResolver? _isMoradorResolver;
  BoolResolver? _canNavigateResolver;
  bool _initialized = false;
  String? _pendingPayload;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'owany_notifications',
    'Owany Notifications',
    description: 'Notificacoes do aplicativo Owany',
    importance: Importance.high,
  );
  static const WindowsInitializationSettings _windowsSettings =
      WindowsInitializationSettings(
    appName: 'Owany',
    appUserModelId: 'Com.Owany.App',
    guid: '5e437140-2c45-41c8-a623-f07095ac96d4',
  );

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required BoolResolver isMorador,
    required BoolResolver canNavigate,
  }) async {
    _navigatorKey = navigatorKey;
    _isMoradorResolver = isMorador;
    _canNavigateResolver = canNavigate;

    if (_initialized) {
      tryProcessPending();
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(
      android: androidSettings,
      windows: _windowsSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handlePayload(response.payload);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      _pendingPayload = launchPayload;
    }

    _initialized = true;
    tryProcessPending();
  }

  Future<void> showFromNotificacao(Notificacao n) async {
    if (!_initialized) return;
    final payload = _payloadFromNotificacao(n);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: n.id.hashCode,
      title: n.titulo,
      body: n.mensagem,
      notificationDetails: details,
      payload: payload,
    );
  }

  bool navigateFromNotificacao(Notificacao notificacao) {
    final payload = _payloadFromNotificacao(notificacao);
    if (payload == null || payload.isEmpty) return false;
    _handlePayload(payload);
    return true;
  }

  void tryProcessPending() {
    if (_pendingPayload == null || _pendingPayload!.isEmpty) return;
    if (!_canNavigate()) return;
    final payload = _pendingPayload!;
    _pendingPayload = null;
    _navigateFromPayload(payload);
  }

  void handleExternalPayload(String? payload) {
    _handlePayload(payload);
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    if (!_canNavigate()) {
      _pendingPayload = payload.trim();
      return;
    }
    _navigateFromPayload(payload.trim());
  }

  bool _canNavigate() => _canNavigateResolver?.call() ?? false;

  bool _isMorador() => _isMoradorResolver?.call() ?? false;

  void _navigateFromPayload(String payload) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingPayload = payload;
      return;
    }

    final parsed = _parsePayload(payload);
    if (parsed == null || parsed.route.isEmpty) return;
    navigator.pushNamed(parsed.route, arguments: parsed.arguments);
  }

  _ParsedNotificationRoute? _parsePayload(String payload) {
    if (payload.startsWith('{') && payload.endsWith('}')) {
      final map = _decodeMap(payload);
      if (map != null) return _parseMapPayload(map);
    }

    final sep = payload.indexOf('_');
    if (sep <= 0 || sep >= payload.length - 1) return null;

    final type = payload.substring(0, sep).toLowerCase();
    final id = payload.substring(sep + 1).trim();
    if (id.isEmpty) return null;

    switch (type) {
      case 'solicitacao':
      case 'solicitacoes':
        return _ParsedNotificationRoute(
          route: '/solicitacoes-detalhe',
          arguments: {'solicitacaoId': id},
        );
      case 'comentario':
        // Formato comentário: comentario_{solicitacaoId}_{comentarioId}
        final parts = id.split('_');
        if (parts.length >= 2) {
          return _ParsedNotificationRoute(
            route: '/solicitacoes-detalhe',
            arguments: {
              'solicitacaoId': parts[0],
              'comentarioId': parts[1],
            },
          );
        }
        return _ParsedNotificationRoute(
          route: '/solicitacoes-detalhe',
          arguments: {'solicitacaoId': id},
        );
      case 'agendamento':
      case 'agendamentos':
        return _ParsedNotificationRoute(
          route: _isMorador() ? '/responder-agendamento' : '/agendamento-detalhes',
          arguments: id,
        );
      case 'apartamento':
      case 'apartamentos':
        return _ParsedNotificationRoute(
          route: '/apartamentos-detalhe',
          arguments: id,
        );
      case 'manutencao':
      case 'preventiva':
      case 'manutencaopreventiva':
        return _ParsedNotificationRoute(
          route: '/manutencoes-preventivas-detalhes',
          arguments: id,
        );
      case 'morador':
      case 'moradores':
        return _ParsedNotificationRoute(
          route: '/moradores-detalhe',
          arguments: id,
        );
      case 'usuario':
      case 'usuarios':
        return _ParsedNotificationRoute(
          route: '/usuarios-detalhe',
          arguments: id,
        );
      case 'notificacao':
      case 'notificacoes':
        return _ParsedNotificationRoute(route: '/notificacoes');
      case 'ativo':
      case 'ativos':
      case 'patrimonio':
        return _ParsedNotificationRoute(
          route: '/patrimonio-detalhe',
          arguments: id,
        );
      case 'relatorio':
      case 'relatorios':
        return _ParsedNotificationRoute(route: '/relatorios');
      default:
        return null;
    }
  }

  _ParsedNotificationRoute? _parseMapPayload(Map<String, dynamic> data) {
    final routeToken = _readFirst(
      data,
      const ['route', 'rota', 'targetRoute', 'screen', 'pagina', 'tipo'],
    );
    if (routeToken == null) return null;

    final route = _normalizeRoute(routeToken);
    if (route == null) return null;

    String? readId(List<String> keys) => _readFirst(data, keys);

    switch (route) {
      case '/agendamento-detalhes':
      case '/responder-agendamento':
        final id = readId(const ['agendamentoId', 'id', 'entityId', 'entidadeId']);
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/manutencoes-preventivas-detalhes':
        final id = readId(
          const ['manutencaoId', 'manutencaoPreventivaId', 'id', 'entityId'],
        );
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/apartamentos-detalhe':
        final id = readId(const ['apartamentoId', 'id', 'entityId', 'entidadeId']);
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/solicitacoes-detalhe':
      case '/solicitacao-detalhes':
        final solicitacaoId = readId(
          const ['solicitacaoId', 'id', 'entityId', 'entidadeId'],
        );
        if (solicitacaoId == null) return null;
        final comentarioId = readId(const ['comentarioId', 'commentId']);
        return _ParsedNotificationRoute(
          route: route,
          arguments: {
            'solicitacaoId': solicitacaoId,
            if (comentarioId != null && comentarioId.isNotEmpty)
              'comentarioId': comentarioId,
          },
        );
      case '/moradores-detalhe':
        final id = readId(const ['moradorId', 'usuarioId', 'id', 'entityId']);
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/usuarios-detalhe':
        final id = readId(const ['usuarioId', 'id', 'entityId', 'entidadeId']);
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/patrimonio-detalhe':
        final id = readId(const ['codigo', 'codigoPatrimonio', 'ativoId', 'id', 'entityId']);
        return id == null ? null : _ParsedNotificationRoute(route: route, arguments: id);
      case '/notificacoes':
      case '/relatorios':
        return _ParsedNotificationRoute(route: route);
      default:
        return _ParsedNotificationRoute(route: route);
    }
  }

  Map<String, dynamic>? _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _readFirst(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final direct = data[key];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      for (final entry in data.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase() &&
            entry.value != null &&
            entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }
    return null;
  }

  String? _normalizeRoute(String token) {
    if (token.startsWith('/')) {
      switch (token) {
        case '/solicitacao-detalhes':
          return '/solicitacoes-detalhe';
        case '/manutencao-detalhes':
          return '/manutencoes-preventivas-detalhes';
        default:
          return token;
      }
    }
    final normalized = token.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (normalized.contains('agendamento')) {
      return _isMorador() ? '/responder-agendamento' : '/agendamento-detalhes';
    }
    if (normalized.contains('solicit')) return '/solicitacoes-detalhe';
    if (normalized.contains('apartamento')) return '/apartamentos-detalhe';
    if (normalized.contains('manutencao') || normalized.contains('preventiva')) {
      return '/manutencoes-preventivas-detalhes';
    }
    if (normalized.contains('notificacao')) return '/notificacoes';
    if (normalized.contains('morador')) return '/moradores-detalhe';
    if (normalized.contains('usuario')) return '/usuarios-detalhe';
    if (normalized.contains('ativo') || normalized.contains('patrimonio')) {
      return '/patrimonio-detalhe';
    }
    if (normalized.contains('relatorio')) return '/relatorios';
    return null;
  }

  String? _payloadFromNotificacao(Notificacao n) {
    // Agendamento has highest priority
    if (n.agendamentoId != null && n.agendamentoId!.isNotEmpty) {
      return 'agendamento_${n.agendamentoId}';
    }
    // Apartamento
    if (n.apartamentoId != null && n.apartamentoId!.isNotEmpty) {
      return 'apartamento_${n.apartamentoId}';
    }
    // Solicitação (with optional comentário)
    if (n.solicitacaoId != null && n.solicitacaoId!.isNotEmpty) {
      final tipo = (n.tipoRaw ?? '').toLowerCase();
      final isManut = tipo.contains('manutencao') || tipo.contains('preventiva');
      if (isManut) {
        return 'manutencao_${n.solicitacaoId}';
      }
      // Include comentarioId if available for deep navigation to comment
      if (n.comentarioId != null && n.comentarioId!.isNotEmpty) {
        return 'comentario_${n.solicitacaoId}_${n.comentarioId}';
      }
      return 'solicitacao_${n.solicitacaoId}';
    }
    // Default fallback - go to notifications list
    return 'notificacao_${n.id}';
  }
}

class _ParsedNotificationRoute {
  final String route;
  final Object? arguments;

  _ParsedNotificationRoute({
    required this.route,
    this.arguments,
  });
}
