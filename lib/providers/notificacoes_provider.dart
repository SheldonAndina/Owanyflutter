import 'dart:async';
import 'package:flutter/material.dart';
import '../dto/api_dtos.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../services/api_service.dart';
import '../services/notification_navigation_service.dart';
import '../services/signalr_service.dart';
import '../utils/app_logger.dart';

/// NotificacoesProvider manages notifications state
/// Integra SignalR para receber notificações em tempo real.
class NotificacoesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  StreamSubscription<Map<String, dynamic>>? _signalRSubscription;
  StreamSubscription<Map<String, dynamic>>? _dataChangedSubscription;
  StreamSubscription<Map<String, dynamic>>? _comentarioSubscription;
  StreamSubscription<Map<String, dynamic>>? _agendamentoSubscription;

  List<Notificacao> _notificacoes = [];
  List<Notificacao> _notificacoesNaoLidas = [];
  Notificacao? _notificacaoAtual;
  NotificacaoResumoDto? _resumo;
  bool _isLoading = false;
  String? _errorMessage;
  int _totalNaoLidas = 0;
  
  /// Set de IDs processados para evitar duplicatas persistentemente
  final Set<String> _idsProcessados = {};
  DateTime? _ultimoIncrementoLocalEm;
  static const Duration _janelaConsistenciaResumo = Duration(seconds: 15);

  // Getters
  List<Notificacao> get notificacoes => _notificacoes;
  List<Notificacao> get notificacoesNaoLidas => _notificacoesNaoLidas;
  Notificacao? get notificacaoAtual => _notificacaoAtual;
  NotificacaoResumoDto? get resumo => _resumo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalNaoLidas => _totalNaoLidas;
  bool get signalRConectado => _signalRService.isConnected;

  dynamic _readField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key];
      final expected = key.toLowerCase();
      for (final entry in data.entries) {
        if (entry.key.toLowerCase() == expected) {
          return entry.value;
        }
      }
    }
    return null;
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    final value = _readField(data, keys);
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime _readDateTime(Map<String, dynamic> data, List<String> keys) {
    final value = _readField(data, keys);
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal() ?? DateTime.now();
  }

  String? _extractUuidFromText(String text) {
    if (text.isEmpty) return null;
    final regex = RegExp(
      r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
    );
    return regex.firstMatch(text)?.group(0);
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
      if (last.isNotEmpty) {
        final uuidLast = _extractUuidFromText(last);
        if (uuidLast != null) return uuidLast;
        if (looksLikeId(last)) return last;
      }
    }

    return looksLikeId(value) ? value : null;
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

    final segments = value.split('/').where((s) => s.trim().isNotEmpty).toList();
    for (var i = 0; i < segments.length - 1; i++) {
      final key = segments[i].toLowerCase();
      final next = segments[i + 1];
      if (key.contains('solicit')) {
        solicitacaoId ??= _normalizeEntityId(next);
      } else if (key.contains('coment')) {
        comentarioId ??= _normalizeEntityId(next);
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

  Future<void> _sincronizarResumoSilencioso() async {
    try {
      final resumoAtualizado = await _apiService.getNotificacoesResumo();
      _resumo = resumoAtualizado;
      final backendCount = resumoAtualizado.totalNaoLidas;
      final localCount = _totalNaoLidas;
      final dentroDaJanela = _ultimoIncrementoLocalEm != null &&
          DateTime.now().difference(_ultimoIncrementoLocalEm!) <=
              _janelaConsistenciaResumo;

      _totalNaoLidas = (dentroDaJanela && backendCount < localCount)
          ? localCount
          : backendCount;
      notifyListeners();
    } catch (e) {
      AppLogger.warning(
        'NotificacoesProvider',
        'Falha ao sincronizar resumo silenciosamente: $e',
      );
    }
  }

  void _sincronizarResumoComRetentativa() {
    unawaited(_sincronizarResumoSilencioso());
    unawaited(Future<void>.delayed(const Duration(seconds: 2), () async {
      await _sincronizarResumoSilencioso();
    }));
  }

  // =====================================================================
  // SIGNALR — TEMPO REAL
  // =====================================================================

  /// Conecta ao hub SignalR e começa a escutar notificações.
  /// Chame após login bem-sucedido.
  Future<void> conectarSignalR() async {
    await _signalRService.conectar();
    _signalRSubscription?.cancel();
    _signalRSubscription = _signalRService.onNovaNotificacao.listen(_onNotificacaoRecebida);
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = _signalRService.onDataChanged.listen(_onDataChangedRecebido);
    _comentarioSubscription?.cancel();
    _comentarioSubscription = _signalRService.onNovoComentario.listen(_onNovoComentarioRecebido);
    _agendamentoSubscription?.cancel();
    _agendamentoSubscription = _signalRService.onAgendamentoAtualizado.listen(_onAgendamentoAtualizadoRecebido);
    AppLogger.info('NotificacoesProvider', 'Escutando notificações SignalR');
  }

  /// Desconecta do hub SignalR. Chame no logout.
  Future<void> desconectarSignalR() async {
    _signalRSubscription?.cancel();
    _signalRSubscription = null;
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = null;
    _comentarioSubscription?.cancel();
    _comentarioSubscription = null;
    _agendamentoSubscription?.cancel();
    _agendamentoSubscription = null;
    _idsProcessados.clear(); // Limpar IDs ao desconectar
    await _signalRService.desconectar();
  }

  /// Handler para DataChanged recebido via push direcionado (ex: responsável de solicitação).
  /// Recarrega o resumo para atualizar o badge de não lidas.
  void _onDataChangedRecebido(Map<String, dynamic> data) {
    final entidade = _readString(data, const ['entidade'], fallback: '');
    final acao = _readString(data, const ['acao'], fallback: '');
    AppLogger.info('NotificacoesProvider',
        'DataChanged recebido: $entidade/$acao — atualizando badge');
    // Recarrega apenas o resumo (leve) para atualizar contagem de não lidas
    _sincronizarResumoComRetentativa();
  }

  /// Quando chega um novo comentário em tempo real, sincroniza badge.
  /// Em alguns fluxos o backend pode enviar Comentario/DataChanged sem NovaNotificacao.
  void _onNovoComentarioRecebido(Map<String, dynamic> data) {
    AppLogger.info(
      'NotificacoesProvider',
      'NovoComentario recebido via SignalR — sincronizando badge',
    );
    _sincronizarResumoComRetentativa();
  }

  /// Quando agendamento é atualizado, sincroniza badge de notificações.
  void _onAgendamentoAtualizadoRecebido(Map<String, dynamic> data) {
    AppLogger.info(
      'NotificacoesProvider',
      'AgendamentoAtualizado recebido via SignalR — sincronizando badge',
    );
    _sincronizarResumoComRetentativa();
  }

  /// Handler para notificação recebida em tempo real.
  void _onNotificacaoRecebida(Map<String, dynamic> data) {
    try {
      final idNotificacao = _readString(
        data,
        const ['id', 'notificacaoId'],
      );
      final notificationId = idNotificacao.isNotEmpty
          ? idNotificacao
          : 'local-${DateTime.now().microsecondsSinceEpoch}';

      // Deduplicação por ID (preferencial)
      if (idNotificacao.isNotEmpty && _idsProcessados.contains(idNotificacao)) {
        AppLogger.info('NotificacoesProvider',
            'Notificação já processada (id): $idNotificacao');
        return;
      }

      final rawTipo = _readString(data, const ['tipo'], fallback: 'Sistema');
      final rawLink = _readString(
        data,
        const ['link', 'entidadeRelacionadaId', 'solicitacaoId'],
      );
      final tipoContexto = '$rawTipo $rawLink'.trim();
      final parsedIds = _extractSolicitacaoComentarioIds(rawLink);
      final link = _normalizeEntityId(rawLink);
      final tipoLower = rawTipo.toLowerCase();
      String? solicId;
      String? agendId;
      String? comentarioId = _normalizeEntityId(
            _readString(data, const ['comentarioId']),
          ) ??
          parsedIds['comentarioId'];
      String? aptoId =
          _normalizeEntityId(_readString(data, const ['apartamentoId']));
      if (tipoLower.contains('agendamento')) {
        agendId =
            _normalizeEntityId(_readString(data, const ['agendamentoId'])) ??
                link;
      } else if (tipoLower.contains('apartamento')) {
        aptoId ??= link;
      } else {
        solicId = _normalizeEntityId(_readString(data, const ['solicitacaoId'])) ??
            parsedIds['solicitacaoId'] ??
            link;
      }
      final novaNotificacao = Notificacao(
        id: notificationId,
        usuarioId: _readString(data, const ['usuarioId']),
        titulo: _readString(data, const ['titulo']),
        mensagem: _readString(data, const ['mensagem']),
        tipo: parseTipoNotificacao(rawTipo),
        tipoRaw: tipoContexto.isNotEmpty ? tipoContexto : rawTipo,
        lida: false,
        criadoEm: _readDateTime(data, const ['criadoEm']),
        solicitacaoId: solicId,
        comentarioId: comentarioId,
        agendamentoId: agendId,
        apartamentoId: aptoId,
      );

      // Prevent duplicates - check if notification already exists in list by ID
      final existeNotificacao = idNotificacao.isNotEmpty &&
          _notificacoes.any((n) => n.id == idNotificacao);
      if (existeNotificacao) {
        _idsProcessados.add(idNotificacao);
        AppLogger.info('NotificacoesProvider',
            'Notificação duplicada ignorada (lista): ${novaNotificacao.id}');
        return;
      }

      // Adicionar ID ao set e inserir notificação
      if (idNotificacao.isNotEmpty) {
        _idsProcessados.add(idNotificacao);
      }
      _notificacoes.insert(0, novaNotificacao);
      _totalNaoLidas = _notificacoes.where((n) => !n.lida).length;
      _ultimoIncrementoLocalEm = DateTime.now();
      _notificacoesNaoLidas = _notificacoes.where((n) => !n.lida).toList();
      notifyListeners();
      unawaited(
        NotificationNavigationService().showFromNotificacao(novaNotificacao),
      );
      _sincronizarResumoComRetentativa();

      AppLogger.info('NotificacoesProvider',
          'Notificação em tempo real recebida: ${novaNotificacao.titulo}');
    } catch (e) {
      AppLogger.error('NotificacoesProvider',
          'Erro ao processar notificação SignalR: $e');
      // Fallback: recarregar todas as notificações
      carregarNotificacoes();
    }
  }

  /// Load all notifications (UPDATED - using backend-compliant method)
  Future<void> carregarNotificacoes({
    bool? somenteNaoLidas,
    String? tipo,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notificacoesBackend = await _apiService.getNotificacoes(
        somenteNaoLidas: somenteNaoLidas,
        tipo: tipo,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      
      // Convert NotificacaoBkendDto to Notificacao model, removing duplicates
      final Set<String> idsVistos = {};
      final notificacoesUnicas = <Notificacao>[];
      
      for (final dto in notificacoesBackend) {
        // Skip if already seen by ID
        if (idsVistos.contains(dto.id)) continue;
        idsVistos.add(dto.id);
        
        // Adicionar ao set global de IDs processados
        _idsProcessados.add(dto.id);
        
        final tipoLower = dto.tipo.toLowerCase();
        final tipoContexto = '${dto.tipo} ${dto.link ?? ''}'.trim();
        final parsedIds = _extractSolicitacaoComentarioIds(dto.link);
        final normalizedLink = _normalizeEntityId(dto.link);
        String? solicId;
        String? agendId;
        String? aptoId;
        String? comentarioId = parsedIds['comentarioId'];
        if (tipoLower.contains('agendamento')) {
          agendId = normalizedLink;
        } else if (tipoLower.contains('apartamento')) {
          aptoId = normalizedLink;
        } else {
          solicId = parsedIds['solicitacaoId'] ?? normalizedLink;
        }
        notificacoesUnicas.add(Notificacao(
          id: dto.id,
          usuarioId: '', // Not provided by backend DTO
          titulo: dto.titulo,
          mensagem: dto.mensagem,
          tipo: parseTipoNotificacao(dto.tipo),
          tipoRaw: tipoContexto.isNotEmpty ? tipoContexto : dto.tipo,
          lida: dto.lida,
          criadoEm: dto.criadoEm,
          solicitacaoId: solicId,
          comentarioId: comentarioId,
          agendamentoId: agendId,
          apartamentoId: aptoId,
        ));
      }
      
      _notificacoes = notificacoesUnicas;
      
      // Contar não lidas
      _totalNaoLidas = _notificacoes.where((n) => !n.lida).length;
      _notificacoesNaoLidas = _notificacoes.where((n) => !n.lida).toList();
      _ultimoIncrementoLocalEm = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a single notification
  Future<void> carregarNotificacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificacaoAtual = await _apiService.getNotificacao(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notifications summary
  Future<void> carregarResumo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resumo = await _apiService.getNotificacoesResumo();
      _totalNaoLidas = _resumo?.totalNaoLidas ?? 0;
      _ultimoIncrementoLocalEm = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> marcarComoLida(String id) async {
    try {
      await _apiService.marcarNotificacaoLida(id);
      
      // Update local list
      final index = _notificacoes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final old = _notificacoes[index];
        _notificacoes[index] = Notificacao(
          id: old.id,
          usuarioId: old.usuarioId,
          titulo: old.titulo,
          mensagem: old.mensagem,
          tipo: old.tipo,
          tipoRaw: old.tipoRaw,
          lida: true,
          criadoEm: old.criadoEm,
          solicitacaoId: old.solicitacaoId,
          comentarioId: old.comentarioId,
          agendamentoId: old.agendamentoId,
          apartamentoId: old.apartamentoId,
          nomeRemetente: old.nomeRemetente,
        );
      }
      
      _totalNaoLidas = _notificacoes.where((n) => !n.lida).length;
      _notificacoesNaoLidas = _notificacoes.where((n) => !n.lida).toList();
      _ultimoIncrementoLocalEm = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> marcarTodasComoLidas() async {
    try {
      await _apiService.marcarTodasNotificacoesLidas();
      
      // Update all to read
      _notificacoes = _notificacoes.map((n) => Notificacao(
        id: n.id,
        usuarioId: n.usuarioId,
        titulo: n.titulo,
        mensagem: n.mensagem,
        tipo: n.tipo,
        tipoRaw: n.tipoRaw,
        lida: true,
        criadoEm: n.criadoEm,
        solicitacaoId: n.solicitacaoId,
        comentarioId: n.comentarioId,
        agendamentoId: n.agendamentoId,
        apartamentoId: n.apartamentoId,
        nomeRemetente: n.nomeRemetente,
      )).toList();
      
      _totalNaoLidas = 0;
      _notificacoesNaoLidas = [];
      _ultimoIncrementoLocalEm = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deletarNotificacao(String id) async {
    try {
      await _apiService.deletarNotificacao(id);
      
      // Remove from local list
      _notificacoes.removeWhere((n) => n.id == id);
      _totalNaoLidas = _notificacoes.where((n) => !n.lida).length;
      _notificacoesNaoLidas = _notificacoes.where((n) => !n.lida).toList();
      _ultimoIncrementoLocalEm = null;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gerar notificação de novo comentário
  Future<void> gerarNotificacaoComentario({
    required String solicitacaoId,
    required String solicitacaoTitulo,
    required String mensagem,
    required String usuarioAutorId,
    required String usuarioAutorNome,
    required bool ehInterno,
    required List<String> usuariosParaNotificar,
  }) async {
    if (ehInterno) return; // Comentários internos não geram notificação

    for (final usuarioId in usuariosParaNotificar) {
      if (usuarioId == usuarioAutorId) continue; // Não notifica o autor

      try {
        await _apiService.criarNotificacao(
          usuarioId: usuarioId,
          titulo: 'Novo comentário: $solicitacaoTitulo',
          mensagem: mensagem.length > 50 ? '${mensagem.substring(0, 50)}...' : mensagem,
          tipo: 'NovoComentario',
        );
      } catch (e) {
        AppLogger.error('NotificacoesProvider', 'Erro ao criar notificação de comentário: $e');
      }
    }
  }

  /// Gerar notificação de mudança de status
  Future<void> gerarNotificacaoStatusAlterado({
    required String solicitacaoId,
    required String solicitacaoTitulo,
    required String statusAnterior,
    required String statusNovo,
    required String usuarioAlteradorId,
    required String usuarioAlteradorNome,
    required List<String> usuariosParaNotificar,
  }) async {
    for (final usuarioId in usuariosParaNotificar) {
      if (usuarioId == usuarioAlteradorId) continue; // Não notifica o autor da mudança

      try {
        await _apiService.criarNotificacao(
          usuarioId: usuarioId,
          titulo: '$solicitacaoTitulo - Status alterado',
          mensagem: '$statusAnterior → $statusNovo',
          tipo: 'MudancaStatus',
        );
      } catch (e) {
        AppLogger.error('NotificacoesProvider', 'Erro ao criar notificação de status: $e');
      }
    }
  }

  /// Gerar notificação de atribuição de responsável
  Future<void> gerarNotificacaoAtribuicao({
    required String solicitacaoId,
    required String solicitacaoTitulo,
    required String novoResponsavelId,
    required String usuarioQueAtribuiuNome,
  }) async {
    try {
      await _apiService.criarNotificacao(
        usuarioId: novoResponsavelId,
        titulo: 'Nova atribuição: $solicitacaoTitulo',
        mensagem: 'Você foi designado como responsável',
        tipo: 'AtribuicaoResponsavel',
      );
    } catch (e) {
      AppLogger.error('NotificacoesProvider', 'Erro ao criar notificação de atribuição: $e');
    }
  }

  /// Gerar notificação de alteração de prazo
  Future<void> gerarNotificacaoAlteracaoPrazo({
    required String solicitacaoId,
    required String solicitacaoTitulo,
    required DateTime? novoPrazo,
    required String usuarioQueAlterouNome,
    required List<String> usuariosParaNotificar,
  }) async {
    for (final usuarioId in usuariosParaNotificar) {
      try {
        final mensagem = novoPrazo != null
            ? 'Novo prazo: ${novoPrazo.day}/${novoPrazo.month}/${novoPrazo.year}'
            : 'Prazo removido';

        await _apiService.criarNotificacao(
          usuarioId: usuarioId,
          titulo: 'Prazo alterado: $solicitacaoTitulo',
          mensagem: mensagem,
          tipo: 'AlteracaoPrazo',
        );
      } catch (e) {
        AppLogger.error('NotificacoesProvider', 'Erro ao criar notificação de prazo: $e');
      }
    }
  }

  /// Gerar notificação de abertura de solicitação
  Future<void> gerarNotificacaoAbertura({
    required String solicitacaoId,
    required String solicitacaoTitulo,
    required String moradorId,
    required String moradorNome,
    required String adminId,
  }) async {
    // Notifica morador
    try {
      await _apiService.criarNotificacao(
        usuarioId: moradorId,
        titulo: 'Solicitação recebida: $solicitacaoTitulo',
        mensagem: 'Sua solicitação foi registrada no sistema',
        tipo: 'AberturaSolicitacao',
      );
    } catch (e) {
      AppLogger.error('NotificacoesProvider', 'Erro ao notificar morador: $e');
    }

    // Notifica admin
    try {
      await _apiService.criarNotificacao(
        usuarioId: adminId,
        titulo: 'Nova solicitação criada',
        mensagem: '$solicitacaoTitulo - $moradorNome',
        tipo: 'NovasolicitacaoCriada',
      );
    } catch (e) {
      AppLogger.error('NotificacoesProvider', 'Erro ao notificar admin: $e');
    }
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString().replaceAll('Exception: ', '');
      return msg;
    }
    return 'Erro ao processar notificações';
  }
}







