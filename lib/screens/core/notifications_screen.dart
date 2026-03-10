import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notificacoes_provider.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_date_time.dart';
import '../../widgets/standard_glass_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAndMarkNotifications();
    });
  }

  Future<void> _loadAndMarkNotifications() async {
    final provider = context.read<NotificacoesProvider>();
    await provider.carregarNotificacoes();
    
    if (provider.totalNaoLidas > 0) {
      await provider.marcarTodasComoLidas();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.notifications_title,
        icon: Icons.notifications_rounded,
        showBackButton: false,
      ),
      body: Consumer<NotificacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notificacoes.isEmpty) {
            return _buildLoadingState();
          }

          if (provider.notificacoes.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregarNotificacoes(),
            color: OwanyTheme.primaryOrange,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notificacoes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = provider.notificacoes[index];
                return _NotificationCard(
                  notification: notif,
                  onTap: () => _handleNotificationTap(provider, notif),
                  onDelete: () => _handleNotificationDelete(provider, notif),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Try to extract a UUID from a free-text string (fallback when no explicit id provided)
  String? _extractUuidFromText(String text) {
    if (text.isEmpty) return null;
    final regex = RegExp(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  String? _readMapString(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        final value = data[key].toString().trim();
        if (value.isNotEmpty) return value;
      }
      for (final entry in data.entries) {
        if (entry.key.toString().toLowerCase() == key.toLowerCase() &&
            entry.value != null) {
          final value = entry.value.toString().trim();
          if (value.isNotEmpty) return value;
        }
      }
    }
    return null;
  }

  String? _normalizeEntityId(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;

    final uuid = _extractUuidFromText(value);
    if (uuid != null) return uuid;

    bool looksLikeId(String candidate) {
      if (candidate.length < 8) return false;
      if (!RegExp(r'[0-9]').hasMatch(candidate)) return false;
      return RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(candidate);
    }

    if (value.contains('?')) {
      value = value.split('?').first;
    }

    final parts = value.split('/').where((p) => p.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      final last = parts.last.trim();
      if (last.isNotEmpty && !last.contains('api')) {
        final uuidLast = _extractUuidFromText(last);
        if (uuidLast != null) return uuidLast;
        if (looksLikeId(last)) return last;
      }
    }

    return looksLikeId(value) ? value : null;
  }

  bool _containsAnyKeyword(String value, List<String> keywords) {
    final lower = value.toLowerCase();
    for (final keyword in keywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  bool _isMaintenanceContext(String text) {
    return _containsAnyKeyword(text, const [
      'manutencao',
      'manutenção',
      'manutencoes',
      'manutenções',
      'manutencaopreventiva',
      'manutencao_preventiva',
      'preventiva',
      'corretiva',
      '/manutencoes',
      'manutencoespreventivas',
    ]);
  }

  String? _extractEntityIdFromLink(
    String? raw,
    List<String> pathKeywords,
  ) {
    if (raw == null || raw.trim().isEmpty) return null;
    var value = raw.trim();
    if (value.contains('?')) {
      value = value.split('?').first;
    }

    final parts = value.split('/').where((p) => p.trim().isNotEmpty).toList();
    for (var i = 0; i < parts.length - 1; i++) {
      final key = parts[i].toLowerCase();
      if (pathKeywords.any((k) => key.contains(k))) {
        final id = _normalizeEntityId(parts[i + 1]);
        if (id != null && id.isNotEmpty) return id;
      }
    }

    return null;
  }

  Map<String, String?> _extractSolicitacaoComentarioIds(String? raw) {
    String? solicitacaoId;
    String? comentarioId;

    if (raw == null || raw.trim().isEmpty) {
      return {'solicitacaoId': null, 'comentarioId': null};
    }

    var value = raw.trim();
    if (value.contains('?')) {
      value = value.split('?').first;
    }

    final parts = value.split('/').where((p) => p.trim().isNotEmpty).toList();
    for (var i = 0; i < parts.length - 1; i++) {
      final key = parts[i].toLowerCase();
      final next = parts[i + 1];
      if (key.contains('solicit')) {
        final normalized = _normalizeEntityId(next);
        if (solicitacaoId == null || solicitacaoId.isEmpty) {
          solicitacaoId = normalized;
        }
      } else if (key.contains('coment')) {
        final normalized = _normalizeEntityId(next);
        if (comentarioId == null || comentarioId.isEmpty) {
          comentarioId = normalized;
        }
      }
    }

    final ids = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).allMatches(raw).map((m) => m.group(0)!).toList();

    if (solicitacaoId == null && ids.isNotEmpty) {
      solicitacaoId = ids.first;
    }
    if (comentarioId == null && ids.length > 1) {
      comentarioId = ids.last;
    }

    return {'solicitacaoId': solicitacaoId, 'comentarioId': comentarioId};
  }

  Map<String, dynamic>? _decodePayloadMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
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

  String? _extractJsonObject(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }

  String? _normalizeRouteFromToken(String? token, {required bool isMorador}) {
    if (token == null || token.trim().isEmpty) return null;
    final raw = token.trim();
    if (raw.startsWith('/')) return raw;

    final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    if (normalized.contains('agendamento')) {
      return isMorador ? '/responder-agendamento' : '/agendamento-detalhes';
    }
    if (normalized.contains('solicit')) return '/solicitacoes-detalhe';
    if (normalized.contains('apartamento')) return '/apartamentos-detalhe';
    if (normalized.contains('manutencao') || normalized.contains('preventiva')) {
      return '/manutencoes-preventivas-detalhes';
    }
    if (normalized.contains('notificacao')) return '/notificacoes';
    return null;
  }

  Object? _resolveArgsFromPayloadRoute(
    String route,
    Map<dynamic, dynamic> data,
  ) {
    String? readId(List<String> keys) => _normalizeEntityId(_readMapString(data, keys));

    switch (route) {
      case '/agendamento-detalhes':
      case '/responder-agendamento':
        return readId(const ['agendamentoId', 'id', 'entityId', 'entidadeId']);
      case '/manutencoes-preventivas-detalhes':
        return readId(
          const [
            'manutencaoId',
            'manutencaoPreventivaId',
            'id',
            'entityId',
            'entidadeId',
          ],
        );
      case '/apartamentos-detalhe':
        return readId(const ['apartamentoId', 'id', 'entityId', 'entidadeId']);
      case '/solicitacoes-detalhe':
        final solicitacaoId = readId(
          const ['solicitacaoId', 'id', 'entityId', 'entidadeId'],
        );
        if (solicitacaoId == null || solicitacaoId.isEmpty) return null;
        final comentarioId = readId(const ['comentarioId', 'commentId']);
        return {
          'solicitacaoId': solicitacaoId,
          if (comentarioId != null && comentarioId.isNotEmpty)
            'comentarioId': comentarioId,
        };
      default:
        return _readMapString(data, const ['arguments', 'id', 'entityId']);
    }
  }

  bool _tryNavigateFromModel(Notificacao notif) {
    debugPrint('notifications: _tryNavigateFromModel invoked for id=${notif.id}');
    final isMorador = context.read<AuthProvider>().isMorador;
    final tipoRaw = (notif.tipoRaw ?? '').toLowerCase();
    final mensagem = notif.mensagem.toLowerCase();
    final titulo = notif.titulo.toLowerCase();
    final maintenanceContext = _isMaintenanceContext('$tipoRaw $titulo $mensagem');

    final solicId = _normalizeEntityId(notif.solicitacaoId);
    final comentarioId = _normalizeEntityId(notif.comentarioId);
    final agendamentoId = _normalizeEntityId(notif.agendamentoId);
    final apartamentoId = _normalizeEntityId(notif.apartamentoId);
    debugPrint('notifications:model fields -> tipoRaw=$tipoRaw mensagem=${notif.mensagem} titulo=${notif.titulo} solicitacaoId=${notif.solicitacaoId} comentarioId=${notif.comentarioId} agendamentoId=${notif.agendamentoId} apartamentoId=${notif.apartamentoId}');

    if (agendamentoId != null && agendamentoId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        isMorador ? '/responder-agendamento' : '/agendamento-detalhes',
        arguments: agendamentoId,
      );
      debugPrint('notifications: navigating to ${isMorador ? '/responder-agendamento' : '/agendamento-detalhes'} with $agendamentoId');
      return true;
    }

    if (maintenanceContext && solicId != null && solicId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/manutencoes-preventivas-detalhes',
        arguments: solicId,
      );
      debugPrint('notifications: navigating to /manutencoes-preventivas-detalhes with $solicId');
      return true;
    }

    if (solicId != null && solicId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/solicitacoes-detalhe',
        arguments: {
          'solicitacaoId': solicId,
          if (comentarioId != null && comentarioId.isNotEmpty)
            'comentarioId': comentarioId,
        },
      );
      debugPrint('notifications: navigating to /solicitacoes-detalhe with solicitacaoId=$solicId comentarioId=$comentarioId');
      return true;
    }

    if (apartamentoId != null && apartamentoId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/apartamentos-detalhe',
        arguments: apartamentoId,
      );
      debugPrint('notifications: navigating to /apartamentos-detalhe with $apartamentoId');
      return true;
    }

    // If this looks like a solicitacao change but we couldn't find an ID,
    // dump the full notification model to help backend debugging.
    if (tipoRaw.contains('solicit') || tipoRaw.contains('statussolicit')) {
      try {
        debugPrint('notifications: full model json -> ${jsonEncode(notif.toJson())}');
      } catch (_) {
        debugPrint('notifications: full model toJson failed');
      }
    }

    return false;
  }


  bool _tryNavigateFromPayload(dynamic notif) {
    debugPrint('notifications: _tryNavigateFromPayload invoked, notifType=${notif.runtimeType}');
    final isMorador = context.read<AuthProvider>().isMorador;
    Map<dynamic, dynamic>? source;

    if (notif is Map) {
      source = notif;
    } else if (notif is Notificacao) {
      final candidates = [
        notif.solicitacaoId,
        notif.tipoRaw,
        notif.mensagem,
      ];

      for (final candidate in candidates) {
        final payloadMap =
            _decodePayloadMap(candidate) ??
            _decodePayloadMap(_extractJsonObject(candidate));
        if (payloadMap != null) {
          source = payloadMap;
          break;
        }
      }
    }

    if (source == null) {
      if (notif is Notificacao) {
        final candidates = [notif.solicitacaoId, notif.tipoRaw, notif.mensagem];
        debugPrint('notifications: no payload found in candidates -> $candidates');
      }
      return false;
    }

    final embeddedPayload = _decodePayloadMap(
      _readMapString(source, const ['payload', 'data']),
    );

    final merged = <dynamic, dynamic>{...source};
    if (embeddedPayload != null) {
      merged.addAll(embeddedPayload);
    }
    debugPrint('notifications: merged payload -> ${jsonEncode(merged)}');

    final route = _normalizeRouteFromToken(
      _readMapString(
            merged,
            const [
              'route',
              'rota',
              'targetRoute',
              'screen',
              'pagina',
              'tipoRota',
            ],
          ) ??
          _readMapString(merged, const ['tipo']),
      isMorador: isMorador,
    );

    if (route == null || route.isEmpty) return false;

    final args = _resolveArgsFromPayloadRoute(route, merged);
    if (route != '/notificacoes' &&
        (args == null || (args is String && args.isEmpty))) {
      return false;
    }

    Navigator.pushNamed(context, route, arguments: args);
    debugPrint('notifications: navigating to $route with args=$args');
    return true;
  }

  Future<void> _handleNotificationTap(
    NotificacoesProvider provider,
    dynamic notif,
  ) async {
    debugPrint('notifications: _handleNotificationTap called with notifType=${notif.runtimeType}');
    try {
      // mark as read
      final idForMark = (notif is Notificacao) ? notif.id : (notif['id'] ?? notif['Id'] ?? notif['notificationId']);
      final currentlyLida = (notif is Notificacao) ? notif.lida : (notif['lida'] ?? notif['read'] ?? false);
      if (idForMark != null && !currentlyLida) {
        await provider.marcarComoLida(idForMark);
      }

      if (notif is Notificacao && _tryNavigateFromModel(notif)) {
        return;
      }

      // Priority path: explicit payload with route/id
      if (_tryNavigateFromPayload(notif)) {
        return;
      }

      // Extract IDs from the Notificacao model or raw map
      String? solicId;
      String? agendamentoId;
      String? apartamentoId;
      String? manutencaoId;
      String? comentarioId;
      String? tipoRaw;
      String? link;
      String titulo = '';
      String mensagem = '';

      if (notif is Notificacao) {
        titulo = notif.titulo;
        mensagem = notif.mensagem;
        solicId = _normalizeEntityId(notif.solicitacaoId);
        agendamentoId = _normalizeEntityId(notif.agendamentoId);
        apartamentoId = _normalizeEntityId(notif.apartamentoId);
        comentarioId = _normalizeEntityId(notif.comentarioId);
        tipoRaw = notif.tipoRaw;
      } else if (notif is Map) {
        titulo = _readMapString(notif, const ['titulo']) ?? '';
        mensagem = _readMapString(notif, const ['mensagem']) ?? '';
        tipoRaw = _readMapString(notif, const ['tipo']) ?? '';
        link = _readMapString(
          notif,
          const [
            'solicitacaoId',
            'entidadeRelacionadaId',
            'link',
            'manutencaoId',
            'manutencaoPreventivaId',
          ],
        );
        final linkIds = _extractSolicitacaoComentarioIds(link);
        apartamentoId = _normalizeEntityId(
          _readMapString(notif, const ['apartamentoId']),
        );
        agendamentoId = _normalizeEntityId(
          _readMapString(notif, const ['agendamentoId']),
        );
        final comentarioFromField = _normalizeEntityId(
          _readMapString(notif, const ['comentarioId']),
        );
        comentarioId = comentarioFromField ?? linkIds['comentarioId'];

        final manutencaoFromField = _normalizeEntityId(
          _readMapString(
            notif,
            const ['manutencaoId', 'manutencaoPreventivaId'],
          ),
        );
        if (manutencaoFromField != null && manutencaoFromField.isNotEmpty) {
          manutencaoId = manutencaoFromField;
        } else {
          manutencaoId = _extractEntityIdFromLink(link, const ['manutencao', 'preventiva']);
        }

        // Route link to the correct field based on tipo
        final tipoLower = tipoRaw.toLowerCase();
        if (tipoLower.contains('agendamento')) {
          if (agendamentoId == null || agendamentoId.isEmpty) {
            agendamentoId = _normalizeEntityId(link);
          }
        } else if (tipoLower.contains('apartamento')) {
          if (apartamentoId == null || apartamentoId.isEmpty) {
            apartamentoId = _normalizeEntityId(link);
          }
        } else if (_isMaintenanceContext('$tipoRaw $titulo $mensagem $link')) {
          if (manutencaoId == null || manutencaoId.isEmpty) {
            final normalizedLinkForManut = _normalizeEntityId(link);
            if (normalizedLinkForManut != null && normalizedLinkForManut.isNotEmpty) {
              manutencaoId = normalizedLinkForManut;
            } else {
              manutencaoId = linkIds['solicitacaoId'];
            }
          }
        } else {
          final normalizedLink = _normalizeEntityId(link);
          if (normalizedLink != null && normalizedLink.isNotEmpty) {
            solicId = normalizedLink;
          } else {
            solicId = linkIds['solicitacaoId'];
          }
        }
      }

      if ((solicId == null || solicId.isEmpty) && notif is Map) {
        solicId = _normalizeEntityId(
          _readMapString(
            notif,
            const ['solicitacaoId', 'entidadeRelacionadaId', 'entityId', 'id'],
          ),
        );
      }

      final contextText = '$tipoRaw $titulo $mensagem $link'.toLowerCase();
      final hasSolicitacao = solicId != null && solicId.isNotEmpty;
      final isMaintenance = !hasSolicitacao && _isMaintenanceContext(contextText);
      if (isMaintenance && (manutencaoId == null || manutencaoId.isEmpty)) {
        manutencaoId = solicId;
      }

      // Fallback: infer from title/message if no explicit ID
      if (_allEmpty([solicId, agendamentoId, apartamentoId, manutencaoId])) {
        final extractedId = _extractUuidFromText(mensagem) ?? _extractUuidFromText(titulo);

        if (extractedId != null) {
          final tipoLower = contextText;
          final lowerContent = '$mensagem $titulo $link'.toLowerCase();
          if (tipoLower.contains('agendamento') || lowerContent.contains('agendamento')) {
            agendamentoId = extractedId;
          } else if (tipoLower.contains('apartamento') || lowerContent.contains('apartamento')) {
            apartamentoId = extractedId;
          } else if (_isMaintenanceContext(lowerContent)) {
            manutencaoId = extractedId;
          } else {
            solicId = extractedId;
          }
        }
      }

      if (!mounted) return;

      // Navigate based on entity type
      if (solicId != null && solicId.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/solicitacoes-detalhe',
          arguments: {
            'solicitacaoId': solicId,
            if (comentarioId != null && comentarioId.isNotEmpty)
              'comentarioId': comentarioId,
          },
        );
      } else if (agendamentoId != null && agendamentoId.isNotEmpty) {
        final isMorador = context.read<AuthProvider>().isMorador;
        Navigator.pushNamed(
          context,
          isMorador ? '/responder-agendamento' : '/agendamento-detalhes',
          arguments: agendamentoId,
        );
      } else if (manutencaoId != null && manutencaoId.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/manutencoes-preventivas-detalhes',
          arguments: manutencaoId,
        );
      } else if (apartamentoId != null && apartamentoId.isNotEmpty) {
        Navigator.pushNamed(context, '/apartamentos-detalhe', arguments: apartamentoId);
      } else {
        // Mostrar detalhes da notificação em um diálogo quando não há navegação
        _showNotificationDetailDialog(notif, titulo, mensagem, tipoRaw);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.notifications_error_mark,
          type: SnackBarType.error,
        ),
      );
    }
  }

  bool _allEmpty(List<String?> values) => values.every((v) => v == null || v.isEmpty);

  void _showNotificationDetailDialog(
    dynamic notif,
    String titulo,
    String mensagem,
    String? tipoRaw,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final criadoEm = notif is Notificacao
        ? notif.criadoEm
        : (notif is Map && notif['criadoEm'] != null)
            ? tryParseBackendDateTimeToLocal(notif['criadoEm'].toString())
            : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: OwanyTheme.cardColor(ctx),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: OwanyTheme.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo.isNotEmpty ? titulo : l10n.notifications_title,
                style: TextStyle(
                  color: OwanyTheme.textPrimary(ctx),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tipoRaw != null && tipoRaw.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tipoRaw.split(' ').first.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: OwanyTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                mensagem.isNotEmpty ? mensagem : l10n.notifications_none,
                style: TextStyle(
                  color: OwanyTheme.textPrimary(ctx),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (criadoEm != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: OwanyTheme.textMutedColor(ctx),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${criadoEm.day.toString().padLeft(2, '0')}/'
                      '${criadoEm.month.toString().padLeft(2, '0')}/'
                      '${criadoEm.year} às '
                      '${criadoEm.hour.toString().padLeft(2, '0')}:'
                      '${criadoEm.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.common_close,
              style: TextStyle(color: OwanyTheme.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleNotificationDelete(
    NotificacoesProvider provider,
    dynamic notif,
  ) async {
    try {
      await provider.deletarNotificacao(notif.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.notifications_removed,
          type: SnackBarType.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.notifications_error_remove,
          type: SnackBarType.error,
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: OwanyTheme.primaryOrange,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 64,
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.notifications_empty,
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.notifications_all_caught_up,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = (notification is Notificacao)
      ? _NotificationType.fromTipo(notification.tipo)
      : _NotificationType.fromString(notification.tipo?.toString() ?? '');
    final isUnread = !notification.lida;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? type.color.withValues(alpha: 0.03)
              : OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? type.color.withValues(alpha: 0.2)
                : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(type: type),
            const SizedBox(width: 12),
            Expanded(
              child: _NotificationContent(
                notification: notification,
                type: type,
                isUnread: isUnread,
              ),
            ),
            const SizedBox(width: 8),
            _DeleteButton(onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final _NotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        type.icon,
        color: type.color,
        size: 20,
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  final dynamic notification;
  final _NotificationType type;
  final bool isUnread;

  const _NotificationContent({
    required this.notification,
    required this.type,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NotificationTitle(
          title: notification.titulo,
          isUnread: isUnread,
          color: type.color,
        ),
        const SizedBox(height: 6),
        _NotificationMessage(message: notification.mensagem),
        const SizedBox(height: 8),
        _NotificationTimestamp(timestamp: notification.criadoEm),
      ],
    );
  }
}

class _NotificationTitle extends StatelessWidget {
  final String title;
  final bool isUnread;
  final Color color;

  const _NotificationTitle({
    required this.title,
    required this.isUnread,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: OwanyTheme.textPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isUnread) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  final String message;

  const _NotificationMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: OwanyTheme.textMutedColor(context),
        fontSize: 13,
        height: 1.35,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NotificationTimestamp extends StatelessWidget {
  final DateTime timestamp;

  const _NotificationTimestamp({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTimestamp(context, timestamp),
      style: TextStyle(
        color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
        fontSize: 11,
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime data) {
    final l10n = AppLocalizations.of(context)!;
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) return l10n.time_now;
    if (diferenca.inMinutes < 60) {
      return l10n.time_ago_minutes(diferenca.inMinutes);
    }
    if (diferenca.inHours < 24) {
      return l10n.time_ago_hours(diferenca.inHours);
    }
    if (diferenca.inDays < 7) {
      return l10n.time_ago_days(diferenca.inDays);
    }

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.close_rounded,
          color: OwanyTheme.error,
          size: 18,
        ),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        splashRadius: 20,
      ),
    );
  }
}

enum _NotificationType {
  maintenance(
    icon: Icons.build_rounded,
    color: OwanyTheme.primaryOrange,
    keywords: [
      'manutencao',
      'manutencaopreventiva',
      'maintenance',
      'repair',
      'reparo',
      'novasolicitacao',
      'novasolicitacaocriada',
      'aberturasolicitacao',
    ],
  ),
  warning(
    icon: Icons.warning_rounded,
    color: OwanyTheme.warning,
    keywords: ['aviso', 'warning', 'alert', 'alerta'],
  ),
  payment(
    icon: Icons.payment_rounded,
    color: OwanyTheme.success,
    keywords: ['pagamento', 'payment', 'cobranca', 'billing'],
  ),
  reservation(
    icon: Icons.event_rounded,
    color: OwanyTheme.info,
    keywords: ['reserva', 'reservation', 'booking', 'agendamento'],
  ),
  announcement(
    icon: Icons.campaign_rounded,
    color: OwanyTheme.primaryOrange,
    keywords: ['comunicado', 'announcement', 'aviso geral', 'sms', 'sms_massa', 'smsmassa'],
  ),
  security(
    icon: Icons.security_rounded,
    color: OwanyTheme.error,
    keywords: ['seguranca', 'security', 'acesso', 'access'],
  ),
  delivery(
    icon: Icons.local_shipping_rounded,
    color: OwanyTheme.info,
    keywords: ['entrega', 'delivery', 'encomenda', 'package'],
  ),
  visitor(
    icon: Icons.person_add_rounded,
    color: OwanyTheme.success,
    keywords: ['visitante', 'visitor', 'visita'],
  ),
  info(
    icon: Icons.info_rounded,
    color: OwanyTheme.info,
    keywords: ['info', 'informacao', 'information'],
  );

  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _NotificationType({
    required this.icon,
    required this.color,
    required this.keywords,
  });

  static _NotificationType fromString(String type) {
    final typeLower = type.toLowerCase();

    for (final notifType in _NotificationType.values) {
      for (final keyword in notifType.keywords) {
        if (typeLower.contains(keyword)) {
          return notifType;
        }
      }
    }

    return _NotificationType.info;
  }

  static _NotificationType fromTipo(TipoNotificacao tipo) {
    switch (tipo) {
      case TipoNotificacao.NovoComentario:
        return _NotificationType.info;
      case TipoNotificacao.AberturaSolicitacao:
      case TipoNotificacao.NovasolicitacaoCriada:
        return _NotificationType.maintenance;
      case TipoNotificacao.MudancaStatus:
        return _NotificationType.reservation;
      case TipoNotificacao.AtribuicaoResponsavel:
        return _NotificationType.maintenance;
      case TipoNotificacao.AlteracaoPrazo:
        return _NotificationType.warning;
      case TipoNotificacao.Aviso:
        return _NotificationType.warning;
      case TipoNotificacao.Sistema:
        return _NotificationType.announcement;
    }
  }
}
