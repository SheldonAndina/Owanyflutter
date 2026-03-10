import 'package:flutter/material.dart';
import '../dto/api_dtos.dart';
import '../dto/solicitacoes_kpis_dto.dart';
import '../services/api_service.dart';

/// DashboardProvider manages dashboard/statistics state
class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardEstatisticas? _estatisticas;
  SolicitacoesKpisDto? _solicitacoesKpis;
  List<SolicitacaoRecenteDto> _solicitacoesRecentes = [];
  List<SolicitacaoRecenteDto> _minhasSolicitacoes = [];
  List<SolicitacaoRecenteDto> _solicitacoesAtrasadas = [];
  List<StatusGraficoDto> _graficoStatus = [];
  List<StatusGraficoDto> _graficoManutencoesPizza = [];
  Map<String, dynamic>? _dashboardCompleto;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardEstatisticas? get estatisticas => _estatisticas;
  SolicitacoesKpisDto? get solicitacoesKpis => _solicitacoesKpis;
  List<SolicitacaoRecenteDto> get solicitacoesRecentes => _solicitacoesRecentes;
  List<SolicitacaoRecenteDto> get minhasSolicitacoes => _minhasSolicitacoes;
  List<SolicitacaoRecenteDto> get solicitacoesAtrasadas => _solicitacoesAtrasadas;
  List<StatusGraficoDto> get graficoStatus => _graficoStatus;
  List<StatusGraficoDto> get graficoManutencoesPizza => _graficoManutencoesPizza;
  Map<String, dynamic>? get dashboardCompleto => _dashboardCompleto;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load dashboard statistics
  Future<void> carregarEstatisticas() async {
    if (_isLoading) return; // Guard against duplicate requests
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _estatisticas = await _apiService.getDashboardEstatisticas();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recent solicitations
  Future<void> carregarSolicitacoesRecentes({int limite = 10}) async {
    try {
      _solicitacoesRecentes = await _apiService.getSolicitacoesRecentes(limite: limite);
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  /// Load my solicitations
  Future<void> carregarMinhasSolicitacoes() async {
    try {
      _minhasSolicitacoes = await _apiService.getMinhasSolicitacoes();
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  /// Load status chart data
  Future<void> carregarGraficoStatus() async {
    try {
      _graficoStatus = await _apiService.getGraficoStatus();
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  /// Refresh all dashboard data at once
  Future<void> atualizarTudo({int limiteSolicitacoes = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Execute all requests in parallel
      final results = await Future.wait([
        _apiService.getDashboardEstatisticas(),
        _apiService.getSolicitacoesRecentes(limite: limiteSolicitacoes),
        _apiService.getMinhasSolicitacoes(),
        _apiService.getGraficoStatus(),
      ]);

      _estatisticas = results[0] as DashboardEstatisticas;
      _solicitacoesRecentes = results[1] as List<SolicitacaoRecenteDto>;
      _minhasSolicitacoes = results[2] as List<SolicitacaoRecenteDto>;
      _graficoStatus = results[3] as List<StatusGraficoDto>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load solicitations KPIs
  Future<void> carregarSolicitacoesKpis({DateTime? dataInicio, DateTime? dataFim}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _solicitacoesKpis = await _apiService.getSolicitacoesKpis(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load dashboard completo com KPIs
  Future<void> carregarDashboardCompleto() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardCompleto = await _apiService.getDashboardCompleto();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load solicitações atrasadas (SLA vencido) — Admin, Síndico, Func
  Future<void> carregarSolicitacoesAtrasadas() async {
    try {
      _solicitacoesAtrasadas = await _apiService.getSolicitacoesAtrasadas();
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  /// Load gráfico de manutenções pizza
  Future<void> carregarGraficoManutencoesPizza() async {
    try {
      _graficoManutencoesPizza = await _apiService.getGraficoManutencoesPizza();
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString().replaceAll('Exception: ', '');
      return msg;
    }
    return 'Erro ao carregar dashboard';
  }

  /// Reset all state (used on logout)
  void reset() {
    _estatisticas = null;
    _solicitacoesKpis = null;
    _solicitacoesRecentes = [];
    _minhasSolicitacoes = [];
    _solicitacoesAtrasadas = [];
    _graficoStatus = [];
    _graficoManutencoesPizza = [];
    _dashboardCompleto = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
