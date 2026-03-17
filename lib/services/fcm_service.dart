import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import '../services/notification_navigation_service.dart';
import '../utils/app_logger.dart';

class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  bool _initialized = false;
  bool _listenersReady = false;
  String? _lastToken;

  bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_isSupportedPlatform()) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _lastToken = await messaging.getToken();
      if (_lastToken != null) {
        await _registerTokenIfAuthenticated(_lastToken!);
      }

      if (!_listenersReady) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          _lastToken = token;
          await _registerTokenIfAuthenticated(token);
        });
        _listenersReady = true;
      }

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }

      _initialized = true;
      AppLogger.info('FcmService', '✅ FCM inicializado');
    } catch (e) {
      AppLogger.warning('FcmService', 'Falha ao inicializar FCM: $e');
    }
  }

  Future<void> refreshTokenRegistration() async {
    if (!_isSupportedPlatform()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      _lastToken ??= await messaging.getToken();
      final token = _lastToken;
      if (token == null || token.isEmpty) return;
      await _registerTokenIfAuthenticated(token);
    } catch (e) {
      AppLogger.warning('FcmService', 'Falha ao registrar token FCM: $e');
    }
  }

  Future<void> _registerTokenIfAuthenticated(String token) async {
    if (token.isEmpty) return;
    final api = ApiService();
    if (api.token == null || api.token!.isEmpty) return;
    try {
      await api.registerDeviceToken(token);
      AppLogger.info('FcmService', '✅ Token FCM registrado no backend');
    } catch (e) {
      AppLogger.warning('FcmService', 'Falha ao registrar token FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Owany';
    final body = message.notification?.body ?? '';
    final payload = _extractPayload(message);
    NotificationNavigationService().showSimpleNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final payload = _extractPayload(message);
    if (payload != null && payload.isNotEmpty) {
      NotificationNavigationService().handleExternalPayload(payload);
    }
  }

  String? _extractPayload(RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty) {
      final payload = data['payload'];
      if (payload != null) return payload.toString();

      final hasRoute = data.containsKey('route') ||
          data.containsKey('rota') ||
          data.containsKey('targetRoute') ||
          data.containsKey('screen');
      if (hasRoute) {
        return jsonEncode(data);
      }

      final tipo = data['tipo'] ?? data['type'];
      final id = data['id'] ?? data['entityId'];
      if (tipo != null && id != null) {
        return '${tipo}_$id';
      }
    }
    return null;
  }
}
