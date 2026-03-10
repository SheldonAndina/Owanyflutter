import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dtos_complementares.dart';

class HistoricoStatusProvider extends ChangeNotifier {
  List<HistoricoStatusDto> _historicoCompleto = [];
  List<HistoricoStatusListaDto> _historicoLista = [];

  bool _isLoading = false;
  String? _erro;

  // Getters
  List<HistoricoStatusDto> get historicoCompleto => _historicoCompleto;
  List<HistoricoStatusListaDto> get historicoLista => _historicoLista;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  /// Carrega histórico completo de uma solicitação
  Future<void> carregarHistoricoCompleto(String solicitacaoId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _historicoCompleto = await ApiService().request<List<HistoricoStatusDto>>(
        'solicitacoes/$solicitacaoId/historico-status',
        method: 'GET',
        fromJson: (json) =>
            (json as List).map((item) => HistoricoStatusDto.fromJson(item as Map<String, dynamic>)).toList(),
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar histórico: ${e.toString()}';
      _historicoCompleto = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega histórico simplificado
  Future<void> carregarHistoricoLista(String solicitacaoId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _historicoLista = await ApiService().request<List<HistoricoStatusListaDto>>(
        'solicitacoes/$solicitacaoId/status-historia',
        method: 'GET',
        fromJson: (json) =>
            (json as List).map((item) => HistoricoStatusListaDto.fromJson(item as Map<String, dynamic>)).toList(),
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar histórico: ${e.toString()}';
      _historicoLista = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtém último status
  String? get ultimoStatus => _historicoLista.isNotEmpty ? _historicoLista.last.status : null;

  /// Filtra histórico por status
  List<HistoricoStatusDto> porStatus(String status) => _historicoCompleto.where((h) => h.status == status).toList();

  /// Filtra histórico por usuário
  List<HistoricoStatusDto> porUsuario(String usuarioId) =>
      _historicoCompleto.where((h) => h.usuarioId == usuarioId).toList();
}
