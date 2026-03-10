import 'package:flutter/foundation.dart';
import '../dto/item_movimentacao_dto.dart';
import '../services/api_service.dart';

class ItemMovimentacaoProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<MovimentacaoDto> _historico = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MovimentacaoDto> get historico => _historico;

  /// Busca histórico de um item
  Future<void> loadHistorico(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await _api.getHistoricoMovimentacao(itemId);
      _historico = (raw).map((e) => MovimentacaoDto.fromJson(e as Map<String, dynamic>)).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar histórico: ${e.toString()}';
      _historico = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Transferir item
  Future<bool> transferir(TransferirItemRequest req) async {
    try {
      final authOk = await _api.ensureAuthenticated(forceRevalidate: true);
      if (!authOk) {
        _errorMessage = 'Sessão expirada. Faça login novamente.';
        notifyListeners();
        return false;
      }
      await _api.transferirItemApartamento(req.toJson());
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao transferir: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Atualizar estado do item
  Future<bool> atualizarEstado(AtualizarEstadoItemRequest req) async {
    try {
      await _api.atualizarEstadoItemApartamento(req.toJson());
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar estado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
