// ============================================================================
// SOLICITAÇÕES V2 - PROVIDER COM STATE MANAGEMENT
// Criado: 27/01/2026
// Status: ✅ PRONTO PARA PRODUÇÃO
// ============================================================================

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../dto/area_tecnica_dto.dart';
import '../dto/solicitacoes_kpis_dto.dart';
import '../dto/solicitacoes_v2_dtos.dart';
import '../services/solicitacoes_service.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../models/item_estado.dart';
import '../utils/app_date_time.dart';

class SolicitacoesProvider with ChangeNotifier {
  final SolicitacoesService _service;
  static const String _solicitacaoTagPrefix = 'solicitacao:';

  // Lista paginada
  List<SolicitacaoListaDto> _solicitacoes = [];
  int _currentPage = 1;
  int _pageSize = 100;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  // Solicitações vinculadas a um item
  List<SolicitacaoListaDto> _solicitacoesPorItem = [];
  bool _isLoadingSolicitacoesPorItem = false;
  String? _errorMessagePorItem;

  // Detalhes
  SolicitacaoDto? _solicitacaoAtual;
  List<ComentarioDto> _comentarios = [];
  List<AnexoDto> _anexos = [];
  ComentarioDto? _ultimoComentarioCriado;

  // Real-time comments
  String? _solicitacaoIdEmEscuta;
  StreamSubscription<Map<String, dynamic>>? _comentarioSubscription;
  StreamSubscription<Map<String, dynamic>>? _dataChangedSubscription;
  Timer? _realtimeDebounce;

  // Estado
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _successMessage;

  // Filtros
  String? _statusFilter;
  String? _apartamentoIdFilter;
  String? _responsavelIdFilter;
  bool _verTodasSolicitacoes = false;

  // KPIs do dashboard (carregados via endpoint dedicado)
  SolicitacoesKpisDto? _kpis;
  bool _isLoadingKpis = false;

  // Tipos de solicitação (sincronizado com backend)
  List<TipoSolicitacaoDto> _tipos = [];
  bool _isLoadingTipos = false;
  String? _erroTipos;

  // Áreas técnicas (sincronizado com backend)
  List<AreaTecnicaDto> _areas = [];
  bool _isLoadingAreas = false;
  String? _erroAreas;
  final Map<String, List<TipoSolicitacaoDto>> _tiposPorAreaCache = {};

  // Getters
  List<SolicitacaoListaDto> get solicitacoes => _solicitacoes;
  List<SolicitacaoListaDto> get solicitacoesPorItem => _solicitacoesPorItem;
  bool get isLoadingSolicitacoesPorItem => _isLoadingSolicitacoesPorItem;
  String? get errorMessagePorItem => _errorMessagePorItem;
  SolicitacaoDto? get solicitacaoAtual => _solicitacaoAtual;
  List<ComentarioDto> get comentarios => _comentarios;
  List<AnexoDto> get anexos => _anexos;
  ComentarioDto? get ultimoComentarioCriado => _ultimoComentarioCriado;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;

  String? get statusFilter => _statusFilter;
  String? get apartamentoIdFilter => _apartamentoIdFilter;
  String? get responsavelIdFilter => _responsavelIdFilter;
  bool get verTodasSolicitacoes => _verTodasSolicitacoes;
  SolicitacoesKpisDto? get kpis => _kpis;
  bool get isLoadingKpis => _isLoadingKpis;
  List<TipoSolicitacaoDto> get tiposSolicitacao => _tipos;
  bool get isLoadingTipos => _isLoadingTipos;
  String? get erroTipos => _erroTipos;
  List<AreaTecnicaDto> get areasTecnicas => _areas;
  bool get isLoadingAreas => _isLoadingAreas;
  String? get erroAreas => _erroAreas;

  SolicitacoesProvider(this._service);

  void _sortSolicitacoesByRecent() {
    _solicitacoes.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
  }

  bool _isTerminalStatus(String status) {
    final normalized = _normalizeToken(status);
    return normalized.contains('concluido') ||
        normalized.contains('cancelado') ||
        normalized.contains('rejeitado');
  }

  bool _isMaintenanceState(String? estado) {
    return estadoFromString(estado) == ItemEstado.Manutencao;
  }

  String _normalizeEstadoForApi(String? estado) {
    final e = estadoFromString(estado);
    return estadoToString(e);
  }

  String _buildSolicitacaoTag(String? solicitacaoId) {
    final id = solicitacaoId?.trim();
    if (id == null || id.isEmpty) return '${_solicitacaoTagPrefix}sem-id';
    return '$_solicitacaoTagPrefix$id';
  }

  Future<String> _resolverEstadoParaFinalizarItem({
    required String itemApartamentoId,
    required String solicitacaoId,
  }) async {
    try {
      final historicoRaw = await ApiService().getHistoricoMovimentacao(
        itemApartamentoId,
      );
      final tag = _normalizeToken(_buildSolicitacaoTag(solicitacaoId));
      Map<String, dynamic>? fallbackSolicitacao;

      for (final entry in historicoRaw.reversed) {
        if (entry is! Map<String, dynamic>) continue;
        final estadoNovo = _normalizeToken(
          entry['estadoNovo']?.toString() ??
              entry['novoEstado']?.toString() ??
              '',
        );
        if (!estadoNovo.contains('manutencao')) continue;

        final motivo = _normalizeToken(entry['motivo']?.toString() ?? '');
        final observacoes = _normalizeToken(
          entry['observacoes']?.toString() ?? '',
        );

        if (motivo.contains(tag) || observacoes.contains(tag)) {
          return _normalizeEstadoForApi(entry['estadoAnterior']?.toString());
        }

        if (fallbackSolicitacao == null &&
            (motivo.contains('solicitacao') ||
                observacoes.contains('solicitacao'))) {
          fallbackSolicitacao = entry;
        }
      }

      if (fallbackSolicitacao != null) {
        return _normalizeEstadoForApi(
          fallbackSolicitacao['estadoAnterior']?.toString(),
        );
      }
    } catch (e) {
      debugPrint(
        '[SolicitacoesProvider] Falha ao resolver estado anterior do item: $e',
      );
    }

    return estadoToString(ItemEstado.Disponivel);
  }

  Future<bool> _temOutraSolicitacaoAtivaParaItem({
    required String itemApartamentoId,
    required String solicitacaoIdAtual,
  }) async {
    final alvo = itemApartamentoId.trim();
    if (alvo.isEmpty) return false;

    final idsParaVerificar = <String>{};

    void adicionarResumo(Iterable<SolicitacaoListaDto> lista) {
      for (final s in lista) {
        if (s.id == solicitacaoIdAtual) continue;
        if (_isTerminalStatus(s.status)) continue;
        idsParaVerificar.add(s.id);
      }
    }

    // Reaproveita cache local primeiro
    adicionarResumo(_solicitacoes);

    Future<void> carregarPaginas(bool verTodas) async {
      try {
        var page = 1;
        var hasNext = true;
        while (hasNext) {
          final result = await _service.getSolicitacoes(
            pageNumber: page,
            pageSize: 100,
            verTodas: verTodas,
          );
          adicionarResumo(result.items);
          hasNext = result.hasNextPage;
          page++;
        }
      } catch (_) {
        // Falha ao listar não bloqueia o fluxo principal
      }
    }

    await carregarPaginas(true);
    await carregarPaginas(false);

    for (final id in idsParaVerificar) {
      try {
        final detalhe = await _service.getSolicitacao(id);
        if (_isTerminalStatus(detalhe.status)) continue;
        final itemIdDetalhe = detalhe.itemApartamentoId?.trim() ?? '';
        if (itemIdDetalhe.isNotEmpty && itemIdDetalhe == alvo) {
          return true;
        }
      } catch (_) {
        // Ignora erro pontual de detalhe e segue nos demais
      }
    }

    return false;
  }

  Future<void> _sincronizarEstadoItemComSolicitacao({
    required String? itemApartamentoId,
    required String statusSolicitacao,
    required String? solicitacaoId,
  }) async {
    final itemId = itemApartamentoId?.trim() ?? '';
    if (itemId.isEmpty) return;

    final api = ApiService();

    try {
      final item = await api.getItemApartamento(itemId);
      final estadoAtual =
          item.estadoAtual ?? item.estadoDesgaste ?? item.status ?? '';
      final statusTerminal = _isTerminalStatus(statusSolicitacao);

      if (!statusTerminal) {
        if (_isMaintenanceState(estadoAtual)) return;

        await api.atualizarEstadoItemApartamento({
          'itemApartamentoId': itemId,
          'novoEstado': estadoToString(ItemEstado.Manutencao),
          'motivo': 'SolicitacaoVinculada',
          'observacoes': _buildSolicitacaoTag(solicitacaoId),
        });
        return;
      }

      final solicitacaoAtualId = solicitacaoId?.trim() ?? '';
      if (solicitacaoAtualId.isNotEmpty) {
        final existeOutraAtiva = await _temOutraSolicitacaoAtivaParaItem(
          itemApartamentoId: itemId,
          solicitacaoIdAtual: solicitacaoAtualId,
        );
        if (existeOutraAtiva) {
          // Mantém o item em manutenção enquanto houver outra solicitação ativa vinculada.
          if (!_isMaintenanceState(estadoAtual)) {
            await api.atualizarEstadoItemApartamento({
              'itemApartamentoId': itemId,
              'novoEstado': estadoToString(ItemEstado.Manutencao),
              'motivo': 'SolicitacaoVinculada',
              'observacoes': _buildSolicitacaoTag(solicitacaoAtualId),
            });
          }
          return;
        }
      }
      // Se chegamos aqui, é um status terminal (concluído/cancelado/rejeitado)
      final statusNorm = _normalizeToken(statusSolicitacao);

      if (statusNorm.contains('concluid')) {
        if (!_isMaintenanceState(estadoAtual)) return;

        final estadoDestino = await _resolverEstadoParaFinalizarItem(
          itemApartamentoId: itemId,
          solicitacaoId: solicitacaoId ?? '',
        );

        await api.atualizarEstadoItemApartamento({
          'itemApartamentoId': itemId,
          'novoEstado': estadoDestino,
          'motivo': 'SolicitacaoFinalizada',
          'observacoes': _buildSolicitacaoTag(solicitacaoId),
        });
        return;
      }

      // Se a solicitação foi cancelada ou rejeitada, consideramos o item como disponível
      if (statusNorm.contains('cancel') || statusNorm.contains('rejeit')) {
        await api.atualizarEstadoItemApartamento({
          'itemApartamentoId': itemId,
          'novoEstado': estadoToString(ItemEstado.Disponivel),
          'motivo': 'SolicitacaoCanceladaOuRejeitada',
          'observacoes': _buildSolicitacaoTag(solicitacaoId),
        });
        return;
      }

      // Fallback: se não for um dos casos acima, tenta resolver por histórico
      if (!_isMaintenanceState(estadoAtual)) return;

      final estadoDestinoFallback = await _resolverEstadoParaFinalizarItem(
        itemApartamentoId: itemId,
        solicitacaoId: solicitacaoId ?? '',
      );

      await api.atualizarEstadoItemApartamento({
        'itemApartamentoId': itemId,
        'novoEstado': estadoDestinoFallback,
        'motivo': 'SolicitacaoFinalizada',
        'observacoes': _buildSolicitacaoTag(solicitacaoId),
      });
    } catch (e) {
      debugPrint(
        '[SolicitacoesProvider] Falha ao sincronizar estado do item: $e',
      );
    }
  }

  /// Limpa todos os dados do provider (usado quando morador não tem apartamento vinculado)
  void limparDados() {
    _solicitacoes = [];
    _solicitacaoAtual = null;
    _comentarios = [];
    _anexos = [];
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasNextPage = false;
    _hasPreviousPage = false;
    _statusFilter = null;
    _apartamentoIdFilter = null;
    _responsavelIdFilter = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Carrega tipos de solicitação do backend
  Future<void> loadTipos({bool refresh = false}) async {
    if (_isLoadingTipos) return;
    _isLoadingTipos = true;
    _erroTipos = null;
    if (refresh) _tipos = [];
    notifyListeners();
    try {
      final tipos = await ApiService().request<List<TipoSolicitacaoDto>>(
        'TiposSolicitacao',
        method: 'GET',
        fromJson: (json) {
          if (json == null) return <TipoSolicitacaoDto>[];
          if (json is List) {
            return json
                .map(
                  (e) => TipoSolicitacaoDto.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          }
          return <TipoSolicitacaoDto>[];
        },
      );
      _tipos = tipos;
    } catch (e) {
      _erroTipos = 'Erro ao carregar tipos: ${e.toString()}';
    } finally {
      _isLoadingTipos = false;
      notifyListeners();
    }
  }

  /// Carrega áreas técnicas do backend
  Future<void> loadAreas({bool refresh = false}) async {
    if (_isLoadingAreas) return;
    _isLoadingAreas = true;
    _erroAreas = null;
    if (refresh) {
      _areas = [];
      _tiposPorAreaCache.clear();
    }
    notifyListeners();
    try {
      final areas = await ApiService().request<List<AreaTecnicaDto>>(
        'AreasTecnicas',
        method: 'GET',
        fromJson: (json) {
          if (json == null) return <AreaTecnicaDto>[];
          if (json is List) {
            return json
                .map((e) => AreaTecnicaDto.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <AreaTecnicaDto>[];
        },
      );
      _areas = areas;
      if (refresh) {
        _tiposPorAreaCache.clear();
      }
    } catch (e) {
      _erroAreas = 'Erro ao carregar áreas: ${e.toString()}';
    } finally {
      _isLoadingAreas = false;
      notifyListeners();
    }
  }

  /// Retorna as áreas associadas a um tipo (se o backend retornar associação no tipo)
  /// Retorna todas as áreas (tipos e áreas são agora independentes)
  List<AreaTecnicaDto> getAreasForTipo(String tipoId) {
    return _areas; // Retorna todas as áreas independentemente do tipo
  }

  /// GET /api/areastecnicas/{id}
  Future<AreaTecnicaDto?> getAreaById(String areaId) async {
    try {
      return await ApiService().request<AreaTecnicaDto>(
        'AreasTecnicas/$areaId',
        method: 'GET',
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return AreaTecnicaDto.fromJson(json);
          }
          throw Exception('Resposta inválida ao buscar área técnica');
        },
      );
    } catch (e) {
      _erroAreas = 'Erro ao buscar área técnica: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// GET /api/tipossolicitacao/{id}
  Future<TipoSolicitacaoDto?> getTipoById(String tipoId) async {
    final id = tipoId.trim();
    if (id.isEmpty) return null;

    final fromCache = _tipos
        .where((t) => t.id.toLowerCase() == id.toLowerCase())
        .firstOrNull;
    if (fromCache != null) return fromCache;

    try {
      final tipo = await ApiService().request<TipoSolicitacaoDto>(
        'TiposSolicitacao/$id',
        method: 'GET',
        fromJson: (json) {
          if (json is Map<String, dynamic>) {
            return TipoSolicitacaoDto.fromJson(json);
          }
          throw Exception('Resposta inválida ao buscar tipo de solicitação');
        },
      );

      final existingIndex = _tipos.indexWhere(
        (t) => t.id.toLowerCase() == tipo.id.toLowerCase(),
      );
      if (existingIndex == -1) {
        _tipos.add(tipo);
      } else {
        _tipos[existingIndex] = tipo;
      }
      notifyListeners();
      return tipo;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/areastecnicas/{id}/tipos
  Future<List<TipoSolicitacaoDto>> getTiposByArea(
    String areaId, {
    bool refresh = false,
  }) async {
    if (!refresh && _tiposPorAreaCache.containsKey(areaId)) {
      return List<TipoSolicitacaoDto>.from(_tiposPorAreaCache[areaId]!);
    }

    try {
      final tipos = await ApiService().request<List<TipoSolicitacaoDto>>(
        'AreasTecnicas/$areaId/tipos',
        method: 'GET',
        fromJson: (json) {
          if (json == null) return <TipoSolicitacaoDto>[];

          if (json is List) {
            return json
                .whereType<Map<String, dynamic>>()
                .map(TipoSolicitacaoDto.fromJson)
                .toList();
          }

          if (json is Map<String, dynamic>) {
            final raw = json['items'] ?? json['tipos'] ?? json['dados'];
            if (raw is List) {
              return raw
                  .whereType<Map<String, dynamic>>()
                  .map(TipoSolicitacaoDto.fromJson)
                  .toList();
            }
          }

          return <TipoSolicitacaoDto>[];
        },
      );

      _tiposPorAreaCache[areaId] = tipos;
      return tipos;
    } catch (_) {
      return <TipoSolicitacaoDto>[];
    }
  }

  /// PUT /api/areastecnicas/{id}/tipos
  Future<bool> setTiposForArea(String areaId, List<String> tipoIds) async {
    try {
      await ApiService().request<void>(
        'AreasTecnicas/$areaId/tipos',
        method: 'PUT',
        body: tipoIds,
        fromJson: (_) {},
      );
      _tiposPorAreaCache.remove(areaId);
      return true;
    } catch (_) {
      // Compatibilidade: alguns backends aceitam objeto com tipoIds.
      try {
        await ApiService().request<void>(
          'AreasTecnicas/$areaId/tipos',
          method: 'PUT',
          body: {'tipoIds': tipoIds},
          fromJson: (_) {},
        );
        _tiposPorAreaCache.remove(areaId);
        return true;
      } catch (e) {
        _erroAreas = 'Erro ao definir tipos da área: ${e.toString()}';
        notifyListeners();
        return false;
      }
    }
  }

  /// Resolve áreas associadas ao tipo lendo /api/areastecnicas/{id}/tipos
  /// Tipos e áreas agora são completamente independentes

  /// Adiciona novo tipo via backend
  Future<TipoSolicitacaoDto?> adicionarTipo(
    String nome, {
    String? descricao,
  }) async {
    _isLoadingTipos = true;
    _erroTipos = null;
    notifyListeners();
    try {
      final novo = await ApiService().request<TipoSolicitacaoDto>(
        'TiposSolicitacao',
        method: 'POST',
        body: {
          'nome': nome,
          'descricao': ?descricao,
          'ativo': true,
        },
        fromJson: (json) => TipoSolicitacaoDto.fromJson(json),
      );
      _tipos.insert(0, novo);
      notifyListeners();
      return novo;
    } catch (e) {
      _erroTipos = 'Erro ao adicionar tipo: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isLoadingTipos = false;
      notifyListeners();
    }
  }

  /// Adiciona nova área técnica via backend
  Future<AreaTecnicaDto?> adicionarArea(
    String nome, {
    String? descricao,
  }) async {
    _isLoadingAreas = true;
    _erroAreas = null;
    notifyListeners();
    try {
      final novo = await ApiService().request<AreaTecnicaDto>(
        'AreasTecnicas',
        method: 'POST',
        body: {
          'nome': nome,
          'descricao': ?descricao,
          'ativo': true,
        },
        fromJson: (json) =>
            AreaTecnicaDto.fromJson(json as Map<String, dynamic>),
      );
      _areas.insert(0, novo);
      _tiposPorAreaCache.remove(novo.id);
      notifyListeners();
      return novo;
    } catch (e) {
      _erroAreas = 'Erro ao adicionar área: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isLoadingAreas = false;
      notifyListeners();
    }
  }

  /// Edita área técnica
  Future<bool> editarArea(AreaTecnicaDto area) async {
    _isLoadingAreas = true;
    _erroAreas = null;
    notifyListeners();
    try {
      final atualizado = await ApiService().request<AreaTecnicaDto>(
        'AreasTecnicas/${area.id}',
        method: 'PUT',
        body: area.toJson(),
        fromJson: (json) =>
            AreaTecnicaDto.fromJson(json as Map<String, dynamic>),
      );
      final idx = _areas.indexWhere((a) => a.id == area.id);
      if (idx != -1) _areas[idx] = atualizado;
      _tiposPorAreaCache.remove(area.id);
      notifyListeners();
      return true;
    } catch (e) {
      _erroAreas = 'Erro ao editar área: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoadingAreas = false;
      notifyListeners();
    }
  }

  /// Remove área técnica
  Future<bool> removerArea(String id) async {
    _isLoadingAreas = true;
    _erroAreas = null;
    notifyListeners();
    try {
      await ApiService().request<bool>(
        'AreasTecnicas/$id',
        method: 'DELETE',
        fromJson: (json) => json == true,
      );
      _areas.removeWhere((a) => a.id == id);
      _tiposPorAreaCache.remove(id);
      // Remove referência também nos tipos locais
      for (final t in _tipos) {
        t.areasTecnicas.removeWhere((a) => a.id == id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _erroAreas = 'Erro ao remover área: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoadingAreas = false;
      notifyListeners();
    }
  }

  /// Associa uma lista de áreas a um tipo (admin)
  // Tipos e áreas agora são autônomos - nenhuma associação necessária no frontend

  /// Edita tipo via backend
  Future<bool> editarTipo(TipoSolicitacaoDto tipo) async {
    _isLoadingTipos = true;
    _erroTipos = null;
    notifyListeners();
    try {
      final atualizado = await ApiService().request<TipoSolicitacaoDto>(
        'TiposSolicitacao/${tipo.id}',
        method: 'PUT',
        body: tipo.toJson(),
        fromJson: (json) => TipoSolicitacaoDto.fromJson(json),
      );
      final idx = _tipos.indexWhere((t) => t.id == tipo.id);
      if (idx != -1) _tipos[idx] = atualizado;
      notifyListeners();
      return true;
    } catch (e) {
      _erroTipos = 'Erro ao editar tipo: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoadingTipos = false;
      notifyListeners();
    }
  }

  /// Remove tipo via backend
  Future<bool> removerTipo(String id) async {
    _isLoadingTipos = true;
    _erroTipos = null;
    notifyListeners();
    try {
      await ApiService().request<bool>(
        'TiposSolicitacao/$id',
        method: 'DELETE',
        fromJson: (json) => json == true,
      );
      _tipos.removeWhere((tipo) => tipo.id == id);
      _tiposPorAreaCache.updateAll(
        (_, tipos) => tipos.where((t) => t.id != id).toList(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _erroTipos = 'Erro ao remover tipo: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoadingTipos = false;
      notifyListeners();
    }
  }

  // ========================================================================
  // MÉTODOS DE LISTAGEM
  // ========================================================================

  /// Carrega KPIs de solicitações via endpoint dedicado (1 chamada, retorno rápido).
  /// Ideal para o dashboard — evita carregar todas as páginas de solicitações.
  Future<void> carregarKpis() async {
    _isLoadingKpis = true;
    notifyListeners();

    try {
      _kpis = await ApiService().getSolicitacoesKpis();
    } catch (e) {
      // KPIs são informativos; se falhar, dashboard pode usar dados parciais
      debugPrint('[SolicitacoesProvider] Erro ao carregar KPIs: $e');
    } finally {
      _isLoadingKpis = false;
      notifyListeners();
    }
  }

  /// Carrega solicitações com paginação.
  ///
  /// [carregarTodas] — quando `true`, busca todas as páginas sequencialmente
  /// (necessário para telas de listagem que exibem/filtram todos os itens).
  /// Quando `false` (padrão), carrega apenas 1 página (ideal para dashboard).
  Future<void> loadSolicitacoes({
    String? status,
    String? apartamentoId,
    String? responsavelId,
    bool verTodas = false,
    bool refresh = false,
    bool carregarTodas = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _solicitacoes.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    _verTodasSolicitacoes = verTodas;
    notifyListeners();

    try {
      final result = await _service.getSolicitacoes(
        pageNumber: _currentPage,
        pageSize: _pageSize,
        status: status,
        apartamentoId: apartamentoId,
        responsavelId: responsavelId,
        verTodas: verTodas,
      );

      if (refresh || _currentPage == 1) {
        _solicitacoes = result.items;
      } else {
        _solicitacoes.addAll(result.items);
      }

      // Se carregarTodas, busca páginas restantes (para telas de listagem)
      if (carregarTodas && (refresh || _currentPage == 1) && result.hasNextPage) {
        var nextPage = result.pageNumber + 1;
        var hasNext = result.hasNextPage;
        while (hasNext) {
          final nextResult = await _service.getSolicitacoes(
            pageNumber: nextPage,
            pageSize: _pageSize,
            status: status,
            apartamentoId: apartamentoId,
            responsavelId: responsavelId,
            verTodas: verTodas,
          );
          _solicitacoes.addAll(nextResult.items);
          hasNext = nextResult.hasNextPage;
          nextPage = nextResult.pageNumber + 1;
        }
      }

      // Deduplicar por id para evitar itens repetidos em recargas
      if (_solicitacoes.isNotEmpty) {
        final seen = <String>{};
        _solicitacoes = _solicitacoes.where((s) => seen.add(s.id)).toList();
        _sortSolicitacoesByRecent();
      }

      _totalPages = result.totalPages;
      _totalItems = result.total;
      _hasNextPage = carregarTodas ? false : result.hasNextPage;
      _hasPreviousPage = result.hasPreviousPage;
      _statusFilter = status;
      _apartamentoIdFilter = apartamentoId;
      _responsavelIdFilter = responsavelId;

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar solicitações: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega próxima página
  Future<void> loadNextPage() async {
    if (!_hasNextPage || _isLoading) return;

    _currentPage++;
    await loadSolicitacoes(
      status: _statusFilter,
      apartamentoId: _apartamentoIdFilter,
      responsavelId: _verTodasSolicitacoes ? null : _responsavelIdFilter,
      verTodas: _verTodasSolicitacoes,
      refresh: false,
    );
  }

  /// Busca solicitações vinculadas a um item específico
  /// Usa o endpoint filtrado GET /api/Solicitacoes?itemApartamentoId={id}
  Future<void> loadSolicitacoesPorItem(
    String itemApartamentoId, {
    bool refresh = false,
  }) async {
    final alvo = itemApartamentoId.trim();
    if (alvo.isEmpty) {
      _solicitacoesPorItem.clear();
      notifyListeners();
      return;
    }

    if (refresh) {
      _solicitacoesPorItem.clear();
    }

    _isLoadingSolicitacoesPorItem = true;
    _errorMessagePorItem = null;
    notifyListeners();

    try {
      // Tenta endpoint filtrado (mais eficiente)
      final result = await _service.getSolicitacoesPorItem(alvo, pageSize: 100);
      _solicitacoesPorItem = result.items.toList();

      if (_solicitacoesPorItem.isNotEmpty) {
        _solicitacoesPorItem.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      }
    } catch (_) {
      // Fallback: busca todas e filtra localmente pelo itemApartamentoId
      try {
        final allResult = await _service.getSolicitacoes(
          pageNumber: 1,
          pageSize: 100,
          verTodas: true,
        );
        _solicitacoesPorItem = allResult.items
            .where((s) =>
                s.itemApartamentoId?.trim().toLowerCase() == alvo.toLowerCase())
            .toList();

        if (_solicitacoesPorItem.isNotEmpty) {
          _solicitacoesPorItem.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
        }
      } catch (e) {
        _errorMessagePorItem =
            'Erro ao carregar solicitações do item: ${e.toString()}';
        _solicitacoesPorItem.clear();
      }
    } finally {
      _isLoadingSolicitacoesPorItem = false;
      notifyListeners();
    }
  }

  /// Carrega página anterior
  Future<void> loadPreviousPage() async {
    if (!_hasPreviousPage || _isLoading || _currentPage <= 1) return;

    _currentPage--;
    await loadSolicitacoes(
      status: _statusFilter,
      apartamentoId: _apartamentoIdFilter,
      responsavelId: _verTodasSolicitacoes ? null : _responsavelIdFilter,
      verTodas: _verTodasSolicitacoes,
      refresh: false,
    );
  }

  /// Atualiza filtros e recarrega lista
  Future<void> setFilters({
    String? status,
    String? apartamentoId,
    String? responsavelId,
    bool verTodas = false,
  }) async {
    _statusFilter = status;
    _apartamentoIdFilter = apartamentoId;
    _responsavelIdFilter = verTodas ? null : responsavelId;
    _verTodasSolicitacoes = verTodas;
    await loadSolicitacoes(
      status: status,
      apartamentoId: apartamentoId,
      responsavelId: verTodas ? null : responsavelId,
      verTodas: verTodas,
      refresh: true,
    );
  }

  /// Limpa filtros
  Future<void> clearFilters() async {
    _statusFilter = null;
    _apartamentoIdFilter = null;
    _responsavelIdFilter = null;
    _verTodasSolicitacoes = false;
    await loadSolicitacoes(refresh: true);
  }

  /// Filtra solicitações onde o usuário atual é o responsável
  List<SolicitacaoListaDto> get minhasSolicitacoes {
    return _solicitacoes
        .where((s) => s.responsavelId != null && s.responsavelId!.isNotEmpty)
        .toList();
  }

  /// Filtra solicitações todas (exceto as que é responsável)
  List<SolicitacaoListaDto> get todasSolicitacoes {
    return _solicitacoes;
  }

  /// Carrega apenas as solicitações do usuário logado (como responsável)
  Future<void> loadMinhasSolicitacoes() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _solicitacoes.clear();
    notifyListeners();

    try {
      // Carrega todas as solicitações e filtra localmente
      final result = await _service.getSolicitacoes(
        pageNumber: 1,
        pageSize: 100, // Aumenta para pegar mais
      );

      _solicitacoes = result.items;
      _sortSolicitacoesByRecent();
      _totalItems = result.total;
      _currentPage = result.pageNumber;
      _pageSize = result.pageSize;
      _totalPages = result.totalPages;
      _hasNextPage = result.hasNextPage;
      _hasPreviousPage = result.hasPreviousPage;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar suas solicitações: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================================================
  // MÉTODOS DE PRAZO E RESPONSÁVEL
  // ========================================================================

  /// Define prazo limite para uma solicitação
  Future<bool> definirPrazoLimite(
    String solicitacaoId,
    DateTime prazoLimite, {
    String? observacoes,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'solicitacaoId': solicitacaoId,
        'prazoLimite': toBackendUtcIsoString(prazoLimite),
        'observacoes': ?observacoes,
      };

      await ApiService().request<bool>(
        'Solicitacoes/$solicitacaoId/prazo',
        method: 'PUT',
        body: body,
        fromJson: (json) => json == true,
      );

      // Recarrega para atualizar
      await loadSolicitacao(solicitacaoId);
      _successMessage = 'Prazo definido com sucesso!';
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao definir prazo: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Atribui responsável a uma solicitação
  Future<bool> atribuirResponsavel(
    String solicitacaoId,
    String responsavelId, {
    String? descricao,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'solicitacaoId': solicitacaoId,
        'responsavelId': responsavelId,
        'descricaoAtribuicao': ?descricao,
      };

      await ApiService().request<bool>(
        'Solicitacoes/$solicitacaoId/responsavel',
        method: 'PUT',
        body: body,
        fromJson: (json) => json == true,
      );

      // Recarrega a solicitação
      await loadSolicitacao(solicitacaoId);
      _successMessage = 'Responsável atribuído com sucesso!';
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atribuir responsável: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Altera status da solicitação para "Em andamento" e define responsável
  Future<bool> iniciarSolicitacao(
    String solicitacaoId,
    String responsavelId,
    DateTime? prazoLimite, {
    String? observacoes,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      SolicitacaoDto? solicitacaoBase;
      try {
        solicitacaoBase = await _service.getSolicitacao(solicitacaoId);
      } catch (_) {}

      final body = {
        'solicitacaoId': solicitacaoId,
        'novoStatus': 'Em andamento',
        'responsavelId': responsavelId,
        if (prazoLimite != null) 'prazoLimite': toBackendUtcIsoString(prazoLimite),
        'observacoes': ?observacoes,
      };

      await ApiService().request<bool>(
        'Solicitacoes/$solicitacaoId/iniciar',
        method: 'PUT',
        body: body,
        fromJson: (json) => json == true,
      );
      await _sincronizarEstadoItemComSolicitacao(
        itemApartamentoId: solicitacaoBase?.itemApartamentoId,
        statusSolicitacao: 'EmAndamento',
        solicitacaoId: solicitacaoId,
      );

      // Recarrega
      await loadSolicitacao(solicitacaoId);
      _successMessage = 'Solicitação iniciada!';
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao iniciar solicitação: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Getter para comentários públicos (visíveis para morador)
  List<ComentarioDto> get comentariosPublicos {
    return _comentarios.where((c) => !c.interno).toList();
  }

  /// Getter para comentários internos (só para staff)
  List<ComentarioDto> get comentariosInternos {
    return _comentarios.where((c) => c.interno).toList();
  }

  // ========================================================================
  // MÉTODOS DE DETALHES
  // ========================================================================

  /// Carrega detalhes completos de uma solicitação
  Future<void> loadSolicitacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _solicitacaoAtual = await _service.getSolicitacao(id);
      _comentarios = _solicitacaoAtual?.comentarios ?? [];
      _anexos = _solicitacaoAtual?.anexos ?? [];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar solicitação: ${e.toString()}';
      _solicitacaoAtual = null;
      _comentarios = [];
      _anexos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Entra no grupo de uma solicitação para escutar comentários em tempo real
  Future<void> entrarNoGrupoDaSolicitacao(String solicitacaoId) async {
    try {
      // Se já está escutando um grupo diferente, sair dele
      if (_solicitacaoIdEmEscuta != null &&
          _solicitacaoIdEmEscuta != solicitacaoId) {
        await sairDoGrupoDaSolicitacao();
      }

      _solicitacaoIdEmEscuta = solicitacaoId;

      // Verificar se SignalR está conectado
      final signalR = SignalRService();
      if (!signalR.isConnected) {
        print(
          '[SolicitacoesProvider] ⚠️ SignalR não conectado, tentando conectar...',
        );
        await signalR.conectar();
      }

      // Invoca o método no hub para registrar a conexão no group
      await signalR.entrarNoGrupoDaSolicitacao(solicitacaoId);

      // Escuta novos comentários
      _comentarioSubscription?.cancel();
      _comentarioSubscription = signalR.onNovoComentario.listen((data) {
        print(
          '[SolicitacoesProvider] 📥 Comentário recebido via SignalR: $data',
        );
        try {
          // Converte mapa para ComentarioDto
          final comentario = ComentarioDto.fromJson(data);
          print(
            '[SolicitacoesProvider] 📋 Comentário parseado: solicitacaoId=${comentario.solicitacaoId}, esperado=$solicitacaoId',
          );
          // Apenas adiciona se for da mesma solicitação
          if (comentario.solicitacaoId == solicitacaoId) {
            // Verificar se já não existe (evitar duplicatas)
            final existe = _comentarios.any((c) => c.id == comentario.id);
            if (!existe) {
              _comentarios.add(comentario);
              notifyListeners();
              print(
                '[SolicitacoesProvider] ✓ Novo comentário adicionado: ${comentario.id}',
              );
            } else {
              print(
                '[SolicitacoesProvider] ⚠️ Comentário já existe, ignorando: ${comentario.id}',
              );
            }
          }
        } catch (e) {
          print(
            '[SolicitacoesProvider] ✗ Erro ao processar comentário em tempo real: $e',
          );
        }
      });

      print(
        '[SolicitacoesProvider] ✓ Entrando no grupo de solicitação: $solicitacaoId, SignalR conectado: ${signalR.isConnected}',
      );
    } catch (e) {
      print('[SolicitacoesProvider] ✗ Erro ao entrar no grupo: $e');
    }
  }

  /// Sai do grupo da solicitação e para de escutar comentários
  Future<void> sairDoGrupoDaSolicitacao() async {
    if (_solicitacaoIdEmEscuta == null) return;

    try {
      final id = _solicitacaoIdEmEscuta;
      _solicitacaoIdEmEscuta = null;
      _comentarioSubscription?.cancel();
      _comentarioSubscription = null;

      await SignalRService().sairDoGrupoDaSolicitacao(id!);
      print('[SolicitacoesProvider] ✓ Saindo do grupo de solicitação: $id');
    } catch (e) {
      print('[SolicitacoesProvider] ✗ Erro ao sair do grupo: $e');
    }
  }

  /// Limpa detalhes atuais
  void clearSolicitacao() {
    _solicitacaoAtual = null;
    _comentarios = [];
    _anexos = [];
    _errorMessage = null;
    notifyListeners();
  }

  // ========================================================================
  // MÉTODOS DE CRIAÇÃO E ATUALIZAÇÃO
  // ========================================================================

  /// Cria nova solicitação
  Future<bool> criarSolicitacao(CriarSolicitacaoDto dto) async {
    _isCreating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final solicitacaoCriada = await _service.criarSolicitacao(dto);
      await _sincronizarEstadoItemComSolicitacao(
        itemApartamentoId: dto.itemApartamentoId,
        statusSolicitacao: 'Pendente',
        solicitacaoId: solicitacaoCriada.id,
      );
      _successMessage = 'Solicitação criada com sucesso!';
      // Recarrega em background (sem await) para não bloquear a tela
      loadSolicitacoes(refresh: true);
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao criar solicitação: ${e.toString()}';
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  /// Muda status de uma solicitação
  Future<bool> mudarStatus(String id, MudarStatusDto dto) async {
    _isUpdating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      SolicitacaoDto? solicitacaoBase;
      if (_solicitacaoAtual?.id == id) {
        solicitacaoBase = _solicitacaoAtual;
      }
      solicitacaoBase ??= await _service.getSolicitacao(id);

      await _service.mudarStatus(id, dto);
      await _sincronizarEstadoItemComSolicitacao(
        itemApartamentoId: solicitacaoBase.itemApartamentoId,
        statusSolicitacao: dto.novoStatus,
        solicitacaoId: id,
      );
      _successMessage = 'Status atualizado com sucesso!';

      // Recarrega detalhes se for a solicitação atual
      if (_solicitacaoAtual?.id == id) {
        await loadSolicitacao(id);
      }

      // Atualiza lista
      await loadSolicitacoes(
        status: _statusFilter,
        apartamentoId: _apartamentoIdFilter,
        refresh: true,
      );

      return true;
    } catch (e) {
      _errorMessage = 'Erro ao mudar status: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ========================================================================
  // MÉTODOS DE COMENTÁRIOS
  // ========================================================================

  /// Adiciona comentário
  Future<bool> adicionarComentario(String id, CriarComentarioDto dto) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comentario = await _service.adicionarComentario(id, dto);

      // Guarda último criado para uso na tela (upload de anexos)
      _ultimoComentarioCriado = comentario;

      // Adiciona à lista local
      _comentarios.add(comentario);

      // Atualiza solicitação atual se for a mesma
      if (_solicitacaoAtual?.id == id) {
        _solicitacaoAtual!.comentarios.add(comentario);
      }

      _successMessage = 'Comentário adicionado!';
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar comentário: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Carrega comentários (se não estiverem em detalhes)
  Future<void> loadComentarios(String id) async {
    try {
      _comentarios = await _service.getComentarios(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar comentários: ${e.toString()}';
    }
    notifyListeners();
  }

  // ========================================================================
  // MÉTODOS DE ANEXOS
  // ========================================================================

  /// Carrega anexos (se não estiverem em detalhes)
  Future<void> loadAnexos(String id) async {
    try {
      _anexos = await _service.getAnexos(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erro ao carregar anexos: ${e.toString()}';
    }
    notifyListeners();
  }

  /// Upload de anexo
  Future<bool> uploadAnexo(
    String id,
    List<int> fileBytes,
    String fileName,
  ) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final anexo = await _service.uploadAnexo(id, fileBytes, fileName);

      // Adiciona à lista local
      _anexos.add(anexo);

      // Atualiza solicitação atual se for a mesma
      if (_solicitacaoAtual?.id == id) {
        _solicitacaoAtual!.anexos.add(anexo);
      }

      _successMessage = 'Arquivo enviado com sucesso!';
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar arquivo: ${e.toString()}';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Upload de anexo em comentário
  Future<bool> uploadAnexoComentario(
    String solId,
    String comId,
    List<int> bytes,
    String nome,
  ) async {
    try {
      await _service.uploadAnexoComentario(solId, comId, bytes, nome);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao enviar anexo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Remove anexo de comentário
  Future<bool> removerAnexoComentario(
    String solId,
    String comId,
    String anexoId,
  ) async {
    try {
      await _service.removerAnexoComentario(solId, comId, anexoId);
      // Atualiza localmente
      for (final c in _comentarios) {
        if (c.id == comId) {
          c.anexos.removeWhere((a) => a.id == anexoId);
          break;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao remover anexo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Edita anexo de comentário (renomear e/ou substituir arquivo)
  Future<bool> editarAnexoComentario(
    String solId,
    String comId,
    String anexoId, {
    String? nomeArquivo,
    List<int>? bytes,
    String? fileName,
  }) async {
    try {
      final atualizado = await _service.editarAnexoComentario(
        solId,
        comId,
        anexoId,
        nomeArquivo: nomeArquivo,
        fileBytes: bytes,
        fileName: fileName,
      );
      // Atualiza localmente
      for (final c in _comentarios) {
        if (c.id == comId) {
          final idx = c.anexos.indexWhere((a) => a.id == anexoId);
          if (idx != -1) c.anexos[idx] = atualizado;
          break;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao editar anexo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ========================================================================
  // MÉTODOS DE GERENCIAMENTO DE ESTADO
  // ========================================================================

  /// Remover solicitação (Admin)
  Future<void> deletarSolicitacao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().deletarSolicitacao(id);

      // Remove da lista local
      _solicitacoes.removeWhere((s) => s.id == id);

      // Se era a solicitação aberta, limpa
      if (_solicitacaoAtual?.id == id) {
        _solicitacaoAtual = null;
      }

      _isLoading = false;
      _successMessage = 'Solicitação removida com sucesso';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao remover solicitação: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpa mensagens
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Reset all state (used on logout)
  void reset() {
    pararRealtimeSync();
    _solicitacoes = [];
    _currentPage = 1;
    _pageSize = 100;
    _totalPages = 1;
    _totalItems = 0;
    _hasNextPage = false;
    _hasPreviousPage = false;
    _solicitacaoAtual = null;
    _comentarios = [];
    _anexos = [];
    _isLoading = false;
    _isCreating = false;
    _isUpdating = false;
    _errorMessage = null;
    _successMessage = null;
    _statusFilter = null;
    _apartamentoIdFilter = null;
    _comentarioSubscription?.cancel();
    _comentarioSubscription = null;
    _solicitacaoIdEmEscuta = null;
    notifyListeners();
  }

  // ==========================================================================
  // REAL-TIME SYNC — DataChanged
  // ==========================================================================

  /// Inicia a escuta de eventos DataChanged para solicitações.
  /// Chame após login / conectarSignalR.
  void inicializarRealtimeSync() {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = SignalRService().onDataChanged.listen((data) {
      final entidade = data['entidade']?.toString() ?? '';
      if (entidade == 'Solicitacao') {
        final acao = data['acao']?.toString() ?? '';
        // Debounce: evita chamadas duplicadas dentro de 2s
        _realtimeDebounce?.cancel();
        _realtimeDebounce = Timer(const Duration(seconds: 2), () {
          if (!_isLoading) {
            print(
              '[SolicitacoesProvider] DataChanged recebido: $entidade/$acao — recarregando lista',
            );
            loadSolicitacoes(refresh: true, carregarTodas: true);
          }
        });
      }
    });
    print('[SolicitacoesProvider] Escutando DataChanged (Solicitacao)');
  }

  /// Para a escuta de eventos DataChanged.
  void pararRealtimeSync() {
    _realtimeDebounce?.cancel();
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = null;
  }

  @override
  String toString() =>
      'SolicitacoesProvider(solicitacoes: ${_solicitacoes.length}, page: $_currentPage/$_totalPages)';
}
