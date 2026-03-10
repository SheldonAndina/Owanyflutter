import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dtos_complementares.dart';

class SmsMassaProvider extends ChangeNotifier {
  List<DestinatarioSmsMassaDto> _destinatarios = [];
  List<HistoricoSmsMassaDto> _historico = [];
  bool _isLoading = false;
  String? _erro;
  int _smsEnviados = 0;

  // Getters
  List<DestinatarioSmsMassaDto> get destinatarios => _destinatarios;
  List<HistoricoSmsMassaDto> get historico => _historico;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  int get smsEnviados => _smsEnviados;

  /// Carrega lista de destinatários potenciais
  /// Endpoint: GET /api/smsmassa/destinatarios
  Future<void> carregarDestinatarios({List<String>? tiposUsuario}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      String url = 'smsmassa/destinatarios';
      if (tiposUsuario != null && tiposUsuario.isNotEmpty) {
        final tipos = tiposUsuario.map((t) => 'tipos=$t').join('&');
        url = '$url?$tipos';
      }

      _destinatarios = await ApiService().request<List<DestinatarioSmsMassaDto>>(
        url,
        method: 'GET',
        fromJson: (json) =>
            (json as List).map((item) => DestinatarioSmsMassaDto.fromJson(item as Map<String, dynamic>)).toList(),
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar destinatários: ${e.toString()}';
      _destinatarios = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envia SMS para múltiplos destinatários
  Future<ResultadoEnvioSmsMassaDto?> enviarSmsMassa({
    required String mensagem,
    required List<String> destinatarioIds,
    bool enviarNotificacao = true,
    String? tituloNotificacao,
  }) async {
    _isLoading = true;
    _erro = null;
    _smsEnviados = 0;
    notifyListeners();

    try {
      final request = EnviarSmsMassaRequest(
        mensagem: mensagem,
        usuarioIds: destinatarioIds,
        enviarNotificacaoApp: enviarNotificacao,
        tituloNotificacao: tituloNotificacao,
      );

      final resultado = await ApiService().request<ResultadoEnvioSmsMassaDto>(
        'smsmassa/enviar',
        method: 'POST',
        body: request.toJson(),
        fromJson: (json) => ResultadoEnvioSmsMassaDto.fromJson(json as Map<String, dynamic>),
      );

      _smsEnviados = resultado.smsEnviados;
      await carregarHistorico(); // Recarrega histórico
      _erro = null;
      return resultado;
    } on Exception catch (e) {
      _erro = 'Erro ao enviar SMS: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envia SMS para todos os usuários de um tipo específico
  /// Endpoint: POST /api/smsmassa/enviar
  Future<ResultadoEnvioSmsMassaDto?> enviarSmsTipoUsuario({
    required String mensagem,
    required List<String> tiposUsuario,
    bool enviarNotificacao = true,
    String? tituloNotificacao,
  }) async {
    _isLoading = true;
    _erro = null;
    _smsEnviados = 0;
    notifyListeners();

    try {
      final request = EnviarSmsMassaRequest(
        mensagem: mensagem,
        tiposUsuario: tiposUsuario,
        enviarNotificacaoApp: enviarNotificacao,
        tituloNotificacao: tituloNotificacao,
      );

      final resultado = await ApiService().request<ResultadoEnvioSmsMassaDto>(
        'smsmassa/enviar',
        method: 'POST',
        body: request.toJson(),
        fromJson: (json) => ResultadoEnvioSmsMassaDto.fromJson(json as Map<String, dynamic>),
      );

      _smsEnviados = resultado.smsEnviados;
      await carregarHistorico();
      _erro = null;
      return resultado;
    } on Exception catch (e) {
      _erro = 'Erro ao enviar SMS: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega histórico de envios
  /// Endpoint: GET /api/smsmassa/historico
  Future<void> carregarHistorico({int pageNumber = 1, int pageSize = 20}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final query = 'smsmassa/historico?pageNumber=$pageNumber&pageSize=$pageSize';

      _historico = await ApiService().request<List<HistoricoSmsMassaDto>>(
        query,
        method: 'GET',
        fromJson: (json) {
          // API retorna PaginatedResponse com campo items
          final map = json as Map<String, dynamic>;
          final items = map['items'] as List<dynamic>? ?? [];
          return items.map((item) => HistoricoSmsMassaDto.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar histórico: ${e.toString()}';
      _historico = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra destinatários ativos
  List<DestinatarioSmsMassaDto> get destinatariosAtivos => _destinatarios.where((d) => d.ativo).toList();

  /// Conta de destinatários por tipo
  Map<String, int> get destinatariosPorTipo {
    final map = <String, int>{};
    for (var d in _destinatarios) {
      map[d.tipo] = (map[d.tipo] ?? 0) + 1;
    }
    return map;
  }
}
