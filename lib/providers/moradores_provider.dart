import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../utils/app_logger.dart';
import 'base_provider.dart';
import 'apartamentos_provider.dart';

/// MoradoresProvider manages residents state
class MoradoresProvider extends BaseProvider {
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  final ApartamentosProvider? _apartamentosProvider;
  StreamSubscription<Map<String, dynamic>>? _dataChangedSubscription;

  MoradoresProvider([this._apartamentosProvider]);

  List<Morador> _moradores = [];
  Morador? _moradorAtual;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Morador> get moradores => _moradores;
  Morador? get moradorAtual => _moradorAtual;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  /// Load all residents (moradores)
  Future<void> carregarMoradores({String? apartamentoId}) async {
    await executeOperation(() async {
      AppLogger.info('MoradoresProvider', 'Carregando moradores (apt: $apartamentoId)');
      _moradores = await _apiService.getMoradores(apartamentoId: apartamentoId);
      AppLogger.debug('MoradoresProvider', 'Carregados ${_moradores.length} moradores');
    });
  }

  /// Load a single resident
  Future<void> carregarMorador(String id) async {
    await executeOperation(() async {
      AppLogger.info('MoradoresProvider', 'Carregando morador: $id');
      _moradorAtual = await _apiService.getMorador(id);
      AppLogger.debug('MoradoresProvider', 'Morador carregado');
    });
  }

  /// Create a new resident
  Future<Morador> criarMorador(Map<String, dynamic> dados) async {
    try {
      AppLogger.info('MoradoresProvider', 'Criando novo morador');
      final novoMorador = await _apiService.criarMorador(dados);
      _moradores.add(novoMorador);
      AppLogger.debug('MoradoresProvider', 'Morador criado com sucesso');

      // If the new morador is linked to an apartment, refresh that apartment
      final aptId = novoMorador.apartamentoId;
      if (_apartamentosProvider != null && aptId != null && aptId.isNotEmpty) {
        await _apartamentosProvider.carregarApartamento(aptId);
      }

      notifyListeners();
      return novoMorador;
    } catch (e) {
      AppLogger.error('MoradoresProvider', 'Erro ao criar morador: $e');
      setError(_formatError(e));
      rethrow;
    }
  }

  /// Update a resident
  Future<void> atualizarMorador(String id, Map<String, dynamic> dados) async {
    try {
      // Preserve previous apartmentId in case DTO doesn't include it
      String? previousApartamentoId;
      try {
        final existing = _moradores.firstWhere((m) => m.id == id);
        previousApartamentoId = existing.apartamentoId;
      } catch (_) {
        previousApartamentoId = null;
      }

      // Perform update and then fetch the updated morador to learn its apartment
      await _apiService.atualizarMorador(id, dados);

      final updatedMorador = await _apiService.getMorador(id);

      // Update local list entry if present
      final index = _moradores.indexWhere((m) => m.id == id);
      if (index != -1) {
        _moradores[index] = updatedMorador;
      }

      // If we have an ApartamentosProvider reference, refresh both previous and current apartments as needed
      final currentApartamentoId = updatedMorador.apartamentoId;
      if (_apartamentosProvider != null) {
        if (previousApartamentoId != null && previousApartamentoId.isNotEmpty) {
          await _apartamentosProvider.carregarApartamento(previousApartamentoId);
        }
        if (currentApartamentoId != null &&
            currentApartamentoId.isNotEmpty &&
            currentApartamentoId != previousApartamentoId) {
          await _apartamentosProvider.carregarApartamento(currentApartamentoId);
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a resident
  Future<void> deletarMorador(String id) async {
    try {
      // Capture apartmentId from local list before deletion
      String? previousApartamentoId;
      try {
        final existing = _moradores.firstWhere((m) => m.id == id);
        previousApartamentoId = existing.apartamentoId;
      } catch (_) {
        previousApartamentoId = null;
      }

      await _apiService.deletarMorador(id);

      // Remove from local list
      _moradores.removeWhere((m) => m.id == id);

      // Refresh apartment if reference available
      final targetAptId = previousApartamentoId;
      if (_apartamentosProvider != null && targetAptId != null && targetAptId.isNotEmpty) {
        await _apartamentosProvider.carregarApartamento(targetAptId);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // REAL-TIME SYNC — DataChanged
  // ===========================================================================

  /// Inicia a escuta de eventos DataChanged para moradores.
  /// Chame após login / conectarSignalR.
  void inicializarRealtimeSync() {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = _signalRService.onDataChanged.listen((data) {
      final entidade = data['entidade']?.toString() ?? '';
      if (entidade == 'Morador') {
        final acao = data['acao']?.toString() ?? '';
        AppLogger.info('MoradoresProvider',
            'DataChanged recebido: $entidade/$acao — recarregando moradores');
        carregarMoradores();
      }
    });
    AppLogger.info('MoradoresProvider', 'Escutando DataChanged (Morador)');
  }

  /// Para a escuta de eventos em tempo real.
  void pararRealtimeSync() {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = null;
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString().replaceAll('Exception: ', '');
      return msg;
    }
    return 'Erro ao processar moradores';
  }

  /// Reset all state (used on logout)
  @override
  void reset() {
    pararRealtimeSync();
    _moradores = [];
    _moradorAtual = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
