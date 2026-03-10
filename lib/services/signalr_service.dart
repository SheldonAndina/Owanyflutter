import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../utils/app_logger.dart';
import 'api_service.dart';

/// Serviço SignalR para notificações e atualizações em tempo real.
///
/// Conecta-se ao hub `/hubs/notificacoes` com JWT e escuta eventos como:
/// - `NovaNotificacao`: Notificações gerais
/// - `NovoComentario`: Comentários em solicitações
/// - `AgendamentoAtualizado`: Atualizações de agendamentos
/// - `SolicitacaoAtribuida`: Quando responsável é atribuído
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  bool _isConnecting = false;
  bool _isConnected = false;

  /// Stream controller para notificações gerais
  final _notificacaoController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller para comentários em tempo real
  final _comentarioController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller para atualizações de agendamentos
  final _agendamentoController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller para atribuições de solicitações
  final _atribuicaoController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream que emite cada notificação recebida via SignalR
  Stream<Map<String, dynamic>> get onNovaNotificacao => _notificacaoController.stream;

  /// Stream que emite cada comentário novo
  Stream<Map<String, dynamic>> get onNovoComentario => _comentarioController.stream;

  /// Stream que emite atualizações de agendamentos
  Stream<Map<String, dynamic>> get onAgendamentoAtualizado => _agendamentoController.stream;

  /// Stream que emite atribuições de solicitações
  Stream<Map<String, dynamic>> get onSolicitacaoAtribuida => _atribuicaoController.stream;

  /// Stream controller para mudanças de dados (DataChanged)
  final _dataChangedController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream que emite eventos DataChanged (entidade criada/atualizada/removida)
  Stream<Map<String, dynamic>> get onDataChanged => _dataChangedController.stream;

  bool get isConnected => _isConnected;

  /// Obtém a URL base do hub (sem `/api`)
  String get _hubUrl {
    // apiService.baseUrl = 'https://localhost:7068/api'
    // Hub URL = 'https://localhost:7068/hubs/notificacoes'
    final apiBase = ApiService().baseUrl;
    final baseWithoutApi = apiBase.replaceAll(RegExp(r'/api$'), '');
    return '$baseWithoutApi/hubs/notificacoes';
  }

  /// Conecta ao hub SignalR com o token JWT atual
  Future<void> conectar() async {
    if (_isConnected || _isConnecting) return;

    final token = ApiService().token;
    if (token == null || token.isEmpty) {
      AppLogger.warning('SignalRService', 'Token JWT ausente — não é possível conectar ao hub');
      return;
    }

    _isConnecting = true;

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => ApiService().token ?? '',
              skipNegotiation: false,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [2000, 5000, 10000, 30000],
          )
          .build();

      // Escutar eventos
      _hubConnection!.on('NovaNotificacao', _onNovaNotificacao);
      _hubConnection!.on('NovoComentario', _onNovoComentario);
      _hubConnection!.on('AgendamentoAtualizado', _onAgendamentoAtualizado);
      _hubConnection!.on('SolicitacaoAtribuida', _onSolicitacaoAtribuida);
      _hubConnection!.on('DataChanged', _onDataChanged);

      // Callbacks de estado
      _hubConnection!.onclose(({Exception? error}) {
        _isConnected = false;
        AppLogger.info('SignalRService', 'Conexão SignalR fechada${error != null ? ': $error' : ''}');
      });

      _hubConnection!.onreconnecting(({Exception? error}) {
        _isConnected = false;
        AppLogger.info('SignalRService', 'Reconectando SignalR...');
      });

      _hubConnection!.onreconnected(({String? connectionId}) {
        _isConnected = true;
        AppLogger.info('SignalRService', 'SignalR reconectado: $connectionId');
      });

      await _hubConnection!.start();
      _isConnected = true;
      AppLogger.info('SignalRService', 'Conectado ao hub SignalR: $_hubUrl');
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao conectar SignalR: $e');
      _isConnected = false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Handler para nova notificação
  void _onNovaNotificacao(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final data = _extractMapData(arguments[0]);
      if (data != null) {
        AppLogger.info('SignalRService', 'Nova notificação recebida: ${data['titulo']}');
        _notificacaoController.add(data);
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao processar notificação: $e');
    }
  }

  /// Handler para novo comentário
  void _onNovoComentario(List<Object?>? arguments) {
    AppLogger.info('SignalRService', '📥 _onNovoComentario chamado com arguments: $arguments');
    if (arguments == null || arguments.isEmpty) {
      AppLogger.warning('SignalRService', '⚠️ arguments nulo ou vazio');
      return;
    }
    try {
      final data = _extractMapData(arguments[0]);
      if (data != null) {
        AppLogger.info('SignalRService', '✓ Novo comentário recebido - solicitacaoId: ${data['solicitacaoId']}, texto: ${data['texto']?.toString().substring(0, 20)}...');
        _comentarioController.add(data);
      } else {
        AppLogger.warning('SignalRService', '⚠️ _extractMapData retornou null');
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao processar comentário: $e');
    }
  }

  /// Handler para agendamento atualizado
  void _onAgendamentoAtualizado(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final data = _extractMapData(arguments[0]);
      if (data != null) {
        AppLogger.info('SignalRService', 'Agendamento atualizado: ${data['agendamentoId']}');
        _agendamentoController.add(data);
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao processar agendamento: $e');
    }
  }

  /// Handler para solicitação atribuída
  void _onSolicitacaoAtribuida(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final data = _extractMapData(arguments[0]);
      if (data != null) {
        AppLogger.info('SignalRService', 'Solicitação atribuída ao usuário: ${data['usuarioId']}');
        _atribuicaoController.add(data);
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao processar atribuição: $e');
    }
  }

  /// Handler para mudanças de dados (DataChanged)
  void _onDataChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final data = _extractMapData(arguments[0]);
      if (data != null) {
        AppLogger.info('SignalRService',
            'DataChanged: ${data['entidade']}/${data['acao']} id=${data['id']}');
        _dataChangedController.add(data);
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao processar DataChanged: $e');
    }
  }

  /// Extrai Map data de forma segura
  Map<String, dynamic>? _extractMapData(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Entra no grupo de uma solicitação para receber comentários em tempo real
  Future<void> entrarNoGrupoDaSolicitacao(String solicitacaoId) async {
    AppLogger.info('SignalRService', '🔄 Tentando entrar no grupo: $solicitacaoId (conectado: $_isConnected)');
    
    if (!_isConnected || _hubConnection == null) {
      AppLogger.warning('SignalRService', '⚠️ Hub não conectado. Tentando reconectar...');
      await conectar();
      if (!_isConnected) {
        AppLogger.error('SignalRService', '✗ Não foi possível conectar ao hub');
        return;
      }
    }

    try {
      await _hubConnection!.invoke('EntrarNaSolicitacao', args: [solicitacaoId]);
      AppLogger.info('SignalRService', '✓ Entrou no grupo da solicitação: $solicitacaoId');
    } catch (e) {
      AppLogger.error('SignalRService', '✗ Erro ao entrar no grupo: $e');
    }
  }

  /// Sai do grupo de uma solicitação
  Future<void> sairDoGrupoDaSolicitacao(String solicitacaoId) async {
    if (!_isConnected || _hubConnection == null) {
      AppLogger.warning('SignalRService', 'Hub não conectado. Não é possível sair do grupo.');
      return;
    }

    try {
      await _hubConnection!.invoke('SairDaSolicitacao', args: [solicitacaoId]);
      AppLogger.info('SignalRService', 'Saiu do grupo da solicitação: $solicitacaoId');
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao sair do grupo: $e');
    }
  }

  /// Desconecta do hub
  Future<void> desconectar() async {
    try {
      if (_hubConnection != null) {
        _hubConnection!.off('NovaNotificacao');
        _hubConnection!.off('NovoComentario');
        _hubConnection!.off('AgendamentoAtualizado');
        _hubConnection!.off('SolicitacaoAtribuida');
        _hubConnection!.off('DataChanged');
        await _hubConnection!.stop();
        _hubConnection = null;
      }
    } catch (e) {
      AppLogger.error('SignalRService', 'Erro ao desconectar SignalR: $e');
    }
    _isConnected = false;
    _isConnecting = false;
    AppLogger.info('SignalRService', 'SignalR desconectado');
  }

  /// Libera recursos
  void dispose() {
    desconectar();
    _notificacaoController.close();
    _comentarioController.close();
    _agendamentoController.close();
    _atribuicaoController.close();
    _dataChangedController.close();
  }
}
