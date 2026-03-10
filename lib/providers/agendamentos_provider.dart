import 'dart:async';
import 'package:flutter/foundation.dart';
import '../dto/agendamentos_dtos.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../utils/app_date_time.dart';
import '../utils/app_logger.dart';

/// Provider para gerenciar estado de agendamentos de manutenção
class AgendamentosProvider extends ChangeNotifier {
  List<AgendamentoMaintenanceDto> agendamentos = [];
  AgendamentoMaintenanceDto? agendamentoAtual;
  bool isLoading = false;
  String? erro;

  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  StreamSubscription<Map<String, dynamic>>? _dataChangedSubscription;
  StreamSubscription<Map<String, dynamic>>? _agendamentoAtualizadoSubscription;

  // Últimos filtros aplicados (usados em recarga real-time).
  String? _ultimoApartamentoId;
  int? _ultimoStatus;
  DateTime? _ultimaDataInicio;
  DateTime? _ultimaDataFim;
  int _ultimaPagina = 1;
  int _ultimoItensPorPagina = 20;

  // Getter para compatibilidade com telas antigas
  AgendamentoMaintenanceDto? get agendamentoSelecionado => agendamentoAtual;

  /// Limpa todos os dados (usado para RBAC e logout)
  void limparDados() {
    agendamentos = [];
    agendamentoAtual = null;
    erro = null;
    notifyListeners();
  }

  /// Carrega lista de agendamentos
  Future<void> carregarAgendamentos({
    String? apartamentoId,
    int? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    int pagina = 1,
    int itensPorPagina = 20,
  }) async {
    _ultimoApartamentoId = apartamentoId;
    _ultimoStatus = status;
    _ultimaDataInicio = dataInicio;
    _ultimaDataFim = dataFim;
    _ultimaPagina = pagina;
    _ultimoItensPorPagina = itensPorPagina;

    isLoading = true;
    erro = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        if (apartamentoId != null && apartamentoId.isNotEmpty) 'apartamentoId': apartamentoId,
        if (status != null) 'status': status.toString(),
        if (dataInicio != null) 'dataInicio': toBackendUtcIsoString(dataInicio),
        if (dataFim != null) 'dataFim': toBackendUtcIsoString(dataFim),
        'pagina': pagina.toString(),
        'itensPorPagina': itensPorPagina.toString(),
      };

      final query = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

      final response = await _apiService.request<List<AgendamentoMaintenanceDto>>(
        query.isNotEmpty ? 'agendamentosmanutencao?$query' : 'agendamentosmanutencao',
        method: 'GET',
        fromJson: (json) => (json as List).map((item) => AgendamentoMaintenanceDto.fromJson(item)).toList(),
      );

      agendamentos = response;
      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Carregados ${agendamentos.length} agendamentos');
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao carregar: $e');
    }
  }

  /// Carrega agendamento específico
  Future<void> carregarAgendamento(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.request<AgendamentoMaintenanceDto>(
        'agendamentosmanutencao/$id',
        method: 'GET',
        fromJson: (json) => AgendamentoMaintenanceDto.fromJson(json),
      );

      agendamentoAtual = response;
      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Agendamento carregado: $id');
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao carregar agendamento: $e');
    }
  }

  /// Cria novo agendamento
  Future<bool> criarAgendamento({
    required String apartamentoId,
    required String titulo,
    required String descricao,
    required DateTime dataAgendada,
    required int duracaoEstimadaHoras,
    required String responsavelTecnicoId,
    int? tipo,
    String? tipoSolicitacaoId,
    String? areaTecnicaId,
    String? itemApartamentoId,
    String? fornecedor,
    String? telefoneFornecedor,
    double? custoEstimado,
    String? observacoes,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {
        'apartamentoId': apartamentoId,
        'titulo': titulo,
        'descricao': descricao,
        'dataAgendada': toBackendUtcIsoString(dataAgendada),
        'duracaoEstimadaHoras': duracaoEstimadaHoras,
        'responsavelTecnicoId': responsavelTecnicoId,
        'tipo': ?tipo,
        'tipoSolicitacaoId': ?tipoSolicitacaoId,
        'areaTecnicaId': ?areaTecnicaId,
        'itemApartamentoId': ?itemApartamentoId,
        'fornecedor': fornecedor,
        'telefoneFornecedor': telefoneFornecedor,
        'custoEstimado': custoEstimado,
        'observacoes': observacoes,
      };

      final response = await _apiService.request<AgendamentoMaintenanceDto>(
        'agendamentosmanutencao',
        method: 'POST',
        body: body,
        fromJson: (json) => AgendamentoMaintenanceDto.fromJson(json),
      );

      agendamentos.add(response);

      // Backend agora lida com todas as notificações (in-app + SMS)
      // via NotificacaoService, então não é necessário enviar do Flutter.
      AppLogger.info('AgendamentosProvider',
          'Agendamento criado: ${response.id} — notificações gerenciadas pelo backend');

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao criar: $e');
      return false;
    }
  }

  /// Responde agendamento
  Future<bool> responderAgendamento(String id, {required bool aceitar, String? motivoRecusa}) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'aceitar': aceitar, 'motivoRecusa': motivoRecusa};

      await _apiService.request<void>(
        'agendamentosmanutencao/$id/responder',
        method: 'POST',
        body: body,
        fromJson: (json) {},
      );

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Resposta registrada para: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao responder: $e');
      return false;
    }
  }

  /// Avalia agendamento
  Future<bool> avaliarAgendamento(String id, int avaliacao, String comentario) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'avaliacao': avaliacao, 'comentario': comentario};

      await _apiService.request<void>(
        'agendamentosmanutencao/$id/avaliar',
        method: 'POST',
        body: body,
        fromJson: (json) {},
      );

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Avaliação registrada para: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao avaliar: $e');
      return false;
    }
  }

  /// Confirma agendamento (Admin, Síndico, Func)
  Future<bool> confirmarAgendamento(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      await _apiService.confirmarAgendamento(id);

      // Recarrega o agendamento atualizado
      await carregarAgendamento(id);

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Agendamento confirmado: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao confirmar: $e');
      return false;
    }
  }

  /// Inicia execução do agendamento (Admin, Síndico, Func)
  Future<bool> iniciarAgendamento(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      await _apiService.iniciarAgendamento(id);

      // Recarrega o agendamento atualizado
      await carregarAgendamento(id);

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Agendamento iniciado: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao iniciar: $e');
      return false;
    }
  }

  /// Conclui agendamento (Admin, Síndico, Func)
  Future<bool> concluirAgendamento(
    String id, {
    String? observacoes,
    double? custoMaoObra,
    double? custoMaterial,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _apiService.concluirAgendamento(
        id,
        observacoes: observacoes,
        custoMaoObra: custoMaoObra,
        custoMaterial: custoMaterial,
      );

      // Recarrega o agendamento atualizado
      await carregarAgendamento(id);

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Agendamento concluído: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao concluir: $e');
      return false;
    }
  }

  /// Cancela agendamento (Admin, Síndico, Func)
  Future<bool> cancelarAgendamento(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      await _apiService.cancelarAgendamento(id);

      // Remove da lista local
      agendamentos.removeWhere((a) => a.id == id);

      // Se era o agendamento aberto, limpa
      if (agendamentoAtual?.id == id) {
        agendamentoAtual = null;
      }

      isLoading = false;
      notifyListeners();

      AppLogger.info('AgendamentosProvider', 'Agendamento cancelado: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('AgendamentosProvider', 'Erro ao cancelar: $e');
      return false;
    }
  }

  /// Reset all state (used on logout)
  void reset() {
    pararRealtimeSync();
    agendamentos = [];
    agendamentoAtual = null;
    isLoading = false;
    erro = null;
    notifyListeners();
  }

  // ===========================================================================
  // REAL-TIME SYNC — DataChanged
  // ===========================================================================

  /// Inicia a escuta de eventos DataChanged para agendamentos.
  /// Chame após login / conectarSignalR.
  void inicializarRealtimeSync({String? apartamentoIdRestrito}) {
    if (apartamentoIdRestrito != null && apartamentoIdRestrito.isNotEmpty) {
      _ultimoApartamentoId = apartamentoIdRestrito;
    }

    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = _signalRService.onDataChanged.listen((data) {
      final entidade =
          data['entidade']?.toString() ?? data['Entidade']?.toString() ?? '';
      if (entidade.toLowerCase().contains('agendamento')) {
        final acao = data['acao']?.toString() ?? data['Acao']?.toString() ?? '';
        AppLogger.info('AgendamentosProvider',
            'DataChanged recebido: $entidade/$acao — recarregando agendamentos');
        carregarAgendamentos(
          apartamentoId: _ultimoApartamentoId,
          status: _ultimoStatus,
          dataInicio: _ultimaDataInicio,
          dataFim: _ultimaDataFim,
          pagina: _ultimaPagina,
          itensPorPagina: _ultimoItensPorPagina,
        );

        if (agendamentoAtual != null) {
          carregarAgendamento(agendamentoAtual!.id);
        }
      }
    });

    _agendamentoAtualizadoSubscription?.cancel();
    _agendamentoAtualizadoSubscription =
        _signalRService.onAgendamentoAtualizado.listen((data) {
      AppLogger.info(
        'AgendamentosProvider',
        'AgendamentoAtualizado recebido — recarregando dados visíveis',
      );
      carregarAgendamentos(
        apartamentoId: _ultimoApartamentoId,
        status: _ultimoStatus,
        dataInicio: _ultimaDataInicio,
        dataFim: _ultimaDataFim,
        pagina: _ultimaPagina,
        itensPorPagina: _ultimoItensPorPagina,
      );

      final idAtualizado = data['agendamentoId']?.toString() ??
          data['AgendamentoId']?.toString() ??
          data['id']?.toString() ??
          data['Id']?.toString();
      if (idAtualizado != null && idAtualizado.isNotEmpty) {
        if (agendamentoAtual == null || agendamentoAtual!.id == idAtualizado) {
          carregarAgendamento(idAtualizado);
        }
      } else if (agendamentoAtual != null) {
        carregarAgendamento(agendamentoAtual!.id);
      }
    });
    AppLogger.info('AgendamentosProvider', 'Escutando DataChanged (Agendamento)');
  }

  /// Para a escuta de eventos em tempo real.
  void pararRealtimeSync() {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = null;
    _agendamentoAtualizadoSubscription?.cancel();
    _agendamentoAtualizadoSubscription = null;
  }
}
