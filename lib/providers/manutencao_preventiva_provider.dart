import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dtos_complementares.dart';
import '../utils/app_date_time.dart';

class ManutencaoPreventivaProvider extends ChangeNotifier {
  List<ManutencaoPreventivaDto> _manutencoes = [];
  ManutencaoPreventivaDto? _manutencaoAtual;
  List<HistoricoManutencaoPreventivaDto> _historicos = [];
  DashboardManutencoesPreventivasDto? _dashboardManutencoes;

  int _pageNumber = 1;
  final int _pageSize = 100; // Carrega tudo de uma vez
  final int _totalItems = 0;

  /// Cache TTL: evita refetch desnecessário se dados têm menos de 60 segundos
  DateTime? _lastLoaded;
  static const _cacheTtl = Duration(seconds: 60);

  // Granular loading flags — evita rebuild global para toda operação
  bool _isLoadingLista = false;
  bool _isLoadingDetalhe = false;
  bool _isLoadingHistorico = false;
  bool _isLoadingDashboard = false;
  bool _isSaving = false;
  String? _erro;

  // Getters
  List<ManutencaoPreventivaDto> get manutencoes => _manutencoes;
  ManutencaoPreventivaDto? get manutencaoAtual => _manutencaoAtual;
  List<HistoricoManutencaoPreventivaDto> get historicos => _historicos;
  DashboardManutencoesPreventivasDto? get dashboardManutencoes => _dashboardManutencoes;
  int get pageNumber => _pageNumber;
  int get pageSize => _pageSize;
  int get totalItems => _totalItems;

  /// isLoading=true se QUALQUER operação estiver em andamento (compatibilidade com código legado)
  bool get isLoading => _isLoadingLista || _isLoadingDetalhe || _isLoadingHistorico || _isLoadingDashboard || _isSaving;
  bool get isLoadingLista => _isLoadingLista;
  bool get isLoadingDetalhe => _isLoadingDetalhe;
  bool get isLoadingHistorico => _isLoadingHistorico;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isSaving => _isSaving;
  String? get erro => _erro;

  /// true se já existe dados carregados (permite background refresh)
  bool get hasData => _manutencoes.isNotEmpty;

  /// Carrega lista de manutenções preventivas
  /// [forceRefresh] ignora o cache TTL e força refetch
  Future<void> carregarManutencoes({
    int page = 1,
    String? tipo,
    String? frequencia,
    bool? ativa,
    bool? vencidas,
    bool forceRefresh = false,
  }) async {
    // Se dados são recentes e não é força, usa cache silenciosamente
    final isFresh = _lastLoaded != null && DateTime.now().difference(_lastLoaded!) < _cacheTtl;
    if (!forceRefresh && isFresh && _manutencoes.isNotEmpty) return;

    _isLoadingLista = true;
    _erro = null;
    _pageNumber = page;
    // Não limpa _manutencoes aqui — dados antigos ficam visíveis durante o background refresh
    notifyListeners();

    try {
      final queryParams = <String, String>{'PageNumber': page.toString(), 'PageSize': _pageSize.toString()};
      if (tipo != null) queryParams['tipo'] = tipo;
      if (frequencia != null) queryParams['frequencia'] = frequencia;
      if (ativa != null) queryParams['ativa'] = ativa.toString();
      if (vencidas != null) queryParams['vencidas'] = vencidas.toString();

      final url = 'manutencoes?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      _manutencoes = await ApiService().request<List<ManutencaoPreventivaDto>>(
        url,
        method: 'GET',
        fromJson: (json) {
          // Backend retorna { items: [...], total: 0, pageNumber: 1, ... }
          if (json is Map<String, dynamic>) {
            final items = json['items'] as List? ?? [];
            return items.map((item) => ManutencaoPreventivaDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          // Fallback para lista direta
          if (json is List) {
            return json.map((item) => ManutencaoPreventivaDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
      _lastLoaded = DateTime.now();
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar manutenções: ${e.toString()}';
      _manutencoes = [];
    } finally {
      _isLoadingLista = false;
      notifyListeners();
    }
  }

  /// Carrega detalhes de uma manutenção específica
  Future<void> carregarManutencao(String id) async {
    _isLoadingDetalhe = true;
    _erro = null;
    notifyListeners();

    try {
      _manutencaoAtual = await ApiService().request<ManutencaoPreventivaDto>(
        'manutencoes/$id',
        method: 'GET',
        fromJson: (json) => ManutencaoPreventivaDto.fromJson(json as Map<String, dynamic>),
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar manutenção: ${e.toString()}';
      _manutencaoAtual = null;
    } finally {
      _isLoadingDetalhe = false;
      notifyListeners();
    }
  }

  /// Cria nova manutenção preventiva
  Future<String?> criarManutencao(CriarManutencaoPreventivaRequest request) async {
    _isSaving = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await ApiService().request<Map<String, dynamic>>(
        'manutencoes',
        method: 'POST',
        body: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final novaId = resultado['id'] as String?;
      _isSaving = false;
      notifyListeners();
      await carregarManutencoes(forceRefresh: true); // Recarrega lista separadamente
      _erro = null;
      return novaId;
    } on Exception catch (e) {
      _erro = 'Erro ao criar manutenção: ${e.toString()}';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Atualiza manutenção existente
  Future<bool> atualizarManutencao(
    String id, {
    String? titulo,
    String? descricao,
    String? tipo,
    String? frequencia,
    DateTime? proximaManutencao,
    double? custoEstimado,
    String? fornecedor,
    String? telefoneFornecedor,
    int? diasAlerta,
    String? responsavelId,
    bool? ativa,
    String? observacoes,
  }) async {
    _isSaving = true;
    _erro = null;
    notifyListeners();

    try {
      await ApiService().request<bool>(
        'manutencoes/$id',
        method: 'PUT',
        body: {
          'titulo': ?titulo,
          'descricao': ?descricao,
          'tipo': ?tipo,
          'frequencia': ?frequencia,
          if (proximaManutencao != null) 'proximaManutencao': toBackendUtcIsoString(proximaManutencao),
          'custoEstimado': ?custoEstimado,
          'fornecedor': ?fornecedor,
          'telefoneFornecedor': ?telefoneFornecedor,
          'diasAlerta': ?diasAlerta,
          'responsavelId': ?responsavelId,
          'ativa': ?ativa,
          'observacoes': ?observacoes,
        },
        fromJson: (json) => json == true,
      );

      _isSaving = false;
      notifyListeners();
      await carregarManutencao(id); // Recarrega detalhes separadamente
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao atualizar manutenção: ${e.toString()}';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Edita manutenção com DTO completo
  Future<bool> editarManutencao(String id, EditarManutencaoPreventivaRequest request) async {
    return await atualizarManutencao(
      id,
      titulo: request.titulo,
      descricao: request.descricao,
      tipo: request.tipo,
      frequencia: request.frequencia,
      proximaManutencao: request.proximaManutencao,
      custoEstimado: request.custoEstimado,
      fornecedor: request.fornecedor,
      telefoneFornecedor: request.telefoneFornecedor,
      diasAlerta: request.diasAlerta,
      responsavelId: request.responsavelId,
      ativa: request.ativa,
      observacoes: request.observacoes,
    );
  }

  /// Registra execução de uma manutenção
  Future<bool> registrarExecucao(String manutencaoId, RegistrarExecucaoManutencaoRequest request) async {
    _isSaving = true;
    _erro = null;
    notifyListeners();

    try {
      await ApiService().request<Map<String, dynamic>?>(
        'manutencoes/$manutencaoId/executar',
        method: 'POST',
        body: request.toJson(),
        fromJson: (json) {
          if (json is Map<String, dynamic>) return json;
          return null;
        },
      );

      _isSaving = false;
      notifyListeners();
      await carregarManutencao(manutencaoId); // Recarrega detalhes após salvar
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao registrar execução: ${e.toString()}';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Carrega histórico de execuções
  Future<void> carregarHistorico(String manutencaoId) async {
    _isLoadingHistorico = true;
    _erro = null;
    notifyListeners();

    try {
      _historicos = await ApiService().request<List<HistoricoManutencaoPreventivaDto>>(
        'manutencoes/$manutencaoId/historico',
        method: 'GET',
        fromJson: (json) {
          List<dynamic> items = const [];
          if (json is List) {
            items = json;
          } else if (json is Map<String, dynamic>) {
            final rawItems =
                json['items'] ?? json['historicos'] ?? json['dados'] ?? json['data'];
            if (rawItems is List) {
              items = rawItems;
            }
          }
          return items
              .map(
                (item) => HistoricoManutencaoPreventivaDto.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        },
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar histórico: ${e.toString()}';
      _historicos = [];
    } finally {
      _isLoadingHistorico = false;
      notifyListeners();
    }
  }
  Future<void> carregarDashboard() async {
    _isLoadingDashboard = true;
    _erro = null;
    notifyListeners();

    try {
      _dashboardManutencoes = await ApiService().request<DashboardManutencoesPreventivasDto>(
        'manutencoes/dashboard',
        method: 'GET',
        fromJson: (json) => DashboardManutencoesPreventivasDto.fromJson(json as Map<String, dynamic>),
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar dashboard: ${e.toString()}';
      _dashboardManutencoes = null;
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  /// Deleta uma manutenção preventiva
  Future<bool> deletarManutencao(String id) async {
    _isSaving = true;
    _erro = null;
    notifyListeners();

    try {
      await ApiService().request<bool>(
        'manutencoes/$id',
        method: 'DELETE',
        fromJson: (json) => json == true,
      );

      _manutencoes.removeWhere((m) => m.id == id);
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao deletar manutenção: ${e.toString()}';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Filtra manutenções vencidas
  List<ManutencaoPreventivaDto> get manutencoesvencidas => _manutencoes.where((m) => m.vencida).toList();

  /// Filtra manutenções com alerta
  List<ManutencaoPreventivaDto> get manutencoesComAlerta => _manutencoes.where((m) => m.alerta).toList();

  /// Filtra manutenções próximas (próximos 7 dias)
  List<ManutencaoPreventivaDto> get manutencoesPrincipais =>
      _manutencoes.where((m) => m.diasFaltantes >= 0 && m.diasFaltantes <= 7 && m.ativa).toList()
        ..sort((a, b) => a.diasFaltantes.compareTo(b.diasFaltantes));

  /// Busca apartamentos disponíveis para seleção
  Future<List<Map<String, String>>> buscarApartamentosDisponiveis() async {
    try {
      final response = await ApiService().request<List<dynamic>>(
        'apartamentos?disponivel=true',
        method: 'GET',
        fromJson: (json) => json as List<dynamic>,
      );

      return response.map((apt) {
        final apartamento = apt as Map<String, dynamic>;
        return {
          'id': apartamento['id'].toString(),
          'numero': apartamento['numero'].toString(),
          'bloco': apartamento['bloco'].toString(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Reset all state (used on logout)
  void reset() {
    _manutencoes = [];
    _manutencaoAtual = null;
    _historicos = [];
    _dashboardManutencoes = null;
    _pageNumber = 1;
    _lastLoaded = null;
    _isLoadingLista = false;
    _isLoadingDetalhe = false;
    _isLoadingHistorico = false;
    _isLoadingDashboard = false;
    _isSaving = false;
    _erro = null;
    notifyListeners();
  }
}
