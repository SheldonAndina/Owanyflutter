import 'dart:async';
import 'package:flutter/foundation.dart';
import '../dto/api_dtos.dart';
import '../dto/item_busca_dto.dart';
import '../models/item_estado.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../dto/item_apartamento_movimentacao_dtos.dart';
import '../utils/app_date_time.dart';
import '../utils/app_logger.dart';
import 'base_provider.dart';

/// ApartamentosProvider manages apartments and their items state
class ApartamentosProvider extends BaseProvider {
  static const Duration _todosItensCacheTtl = Duration(minutes: 3);
  static const Duration _apartamentosCacheTtl = Duration(minutes: 2);

  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  StreamSubscription<Map<String, dynamic>>? _dataChangedSubscription;

  // Apartamentos
  List<Apartamento> _apartamentos = [];
  List<Apartamento> _apartamentosDisponiveis = [];
  List<String> _blocos = [];
  Apartamento? _apartamentoAtual;
  List<ItemApartamento> _itensApartamento = [];
  // Guard to avoid applying stale async responses when multiple loads overlap
  String? _currentLoadingApartamentoId;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _apartamentosLoadedAt;
  bool _apartamentosComMoradores = false;

  // Gestão de ativos (todos os itens de todos apartamentos)
  List<ItemApartamento>? _todosItens;
  List<ItemApartamento>? get todosItens => _todosItens;
  DateTime? _todosItensLoadedAt;
  Future<void>? _carregarTodosItensFuture;
  final Map<String, List<ItemApartamentoMovimentacaoHistoricoDto>>
  _historicoMovimentacaoCache = {};

  // Busca otimizada (server-side com paginação)
  ItemBuscaResult? _resultadoBusca;
  ItemBuscaResult? get resultadoBusca => _resultadoBusca;
  ItemBuscaParams _ultimosBuscaParams = const ItemBuscaParams();
  bool _buscandoItens = false;
  bool get buscandoItens => _buscandoItens;
  String? _buscaError;
  String? get buscaError => _buscaError;
  Timer? _debounceTimer;

  /// Busca otimizada de itens com debounce (server-side).
  /// Ideal para campos de busca - evita requisições excessivas.
  /// 
  /// [query] Termo de busca (nome, código, tipo)
  /// [estado] Filtro por estado
  /// [tipo] Filtro por tipo
  /// [apartamentoId] Filtro por apartamento
  /// [somenteStock] Somente itens sem vínculo
  /// [page] Página (1-based)
  /// [pageSize] Tamanho da página
  /// [ordenarPor] Campo de ordenação
  /// [descendente] Ordenação descendente
  /// [debounceMs] Delay do debounce (0 = sem debounce)
  Future<void> buscarItens({
    String? query,
    String? estado,
    String? tipo,
    String? apartamentoId,
    bool? somenteStock,
    int page = 1,
    int pageSize = 20,
    String? ordenarPor,
    bool descendente = false,
    int debounceMs = 300,
  }) async {
    final params = ItemBuscaParams(
      query: query,
      estado: estado,
      tipo: tipo,
      apartamentoId: apartamentoId,
      somenteStock: somenteStock,
      page: page,
      pageSize: pageSize,
      ordenarPor: ordenarPor,
      descendente: descendente,
    );

    // Se tiver debounce configurado, cancela timer anterior e aguarda
    if (debounceMs > 0) {
      _debounceCancel();
      _debounceTimer = Timer(Duration(milliseconds: debounceMs), () {
        _executarBusca(params);
      });
    } else {
      await _executarBusca(params);
    }
  }

  void _debounceCancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _executarBusca(ItemBuscaParams params) async {
    _ultimosBuscaParams = params;
    _buscandoItens = true;
    _buscaError = null;
    notifyListeners();

    try {
      _resultadoBusca = await _apiService.buscarItensApartamento(
        query: params.query,
        estado: params.estado,
        tipo: params.tipo,
        apartamentoId: params.apartamentoId,
        somenteStock: params.somenteStock,
        page: params.page,
        pageSize: params.pageSize,
        ordenarPor: params.ordenarPor,
        descendente: params.descendente,
      );
      AppLogger.info(
        'ApartamentosProvider',
        'Busca concluída: ${_resultadoBusca?.total ?? 0} resultados (página ${params.page})',
      );
    } catch (e) {
      _buscaError = 'Erro na busca: ${e.toString()}';
      AppLogger.error('ApartamentosProvider', 'Erro ao buscar itens', e);
    } finally {
      _buscandoItens = false;
      notifyListeners();
    }
  }

  /// Carrega próxima página de resultados (mantém filtros atuais)
  Future<void> carregarProximaPagina() async {
    if (_resultadoBusca == null || !_resultadoBusca!.hasNextPage) return;
    await buscarItens(
      query: _ultimosBuscaParams.query,
      estado: _ultimosBuscaParams.estado,
      tipo: _ultimosBuscaParams.tipo,
      apartamentoId: _ultimosBuscaParams.apartamentoId,
      somenteStock: _ultimosBuscaParams.somenteStock,
      page: _ultimosBuscaParams.page + 1,
      pageSize: _ultimosBuscaParams.pageSize,
      ordenarPor: _ultimosBuscaParams.ordenarPor,
      descendente: _ultimosBuscaParams.descendente,
      debounceMs: 0,
    );
  }

  /// Carrega página anterior de resultados
  Future<void> carregarPaginaAnterior() async {
    if (_resultadoBusca == null || !_resultadoBusca!.hasPreviousPage) return;
    await buscarItens(
      query: _ultimosBuscaParams.query,
      estado: _ultimosBuscaParams.estado,
      tipo: _ultimosBuscaParams.tipo,
      apartamentoId: _ultimosBuscaParams.apartamentoId,
      somenteStock: _ultimosBuscaParams.somenteStock,
      page: _ultimosBuscaParams.page - 1,
      pageSize: _ultimosBuscaParams.pageSize,
      ordenarPor: _ultimosBuscaParams.ordenarPor,
      descendente: _ultimosBuscaParams.descendente,
      debounceMs: 0,
    );
  }

  /// Limpa resultados da busca
  void limparBusca() {
    _debounceCancel();
    _resultadoBusca = null;
    _buscaError = null;
    _ultimosBuscaParams = const ItemBuscaParams();
    notifyListeners();
  }

  /// Carregar todos os itens de todos apartamentos
  Future<void> carregarTodosItens({bool forceRefresh = false}) async {
    if (!forceRefresh && _isTodosItensCacheFresh()) {
      return;
    }

    if (_carregarTodosItensFuture != null) {
      await _carregarTodosItensFuture;
      return;
    }

    final future = _carregarTodosItensInternal(forceRefresh: forceRefresh);
    _carregarTodosItensFuture = future;
    try {
      await future;
    } finally {
      _carregarTodosItensFuture = null;
    }
  }

  Future<void> _carregarTodosItensInternal({required bool forceRefresh}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Neste ambiente o endpoint /itemapartamento/ativos retorna 404.
      // Primeiro tenta /itemapartamento (mais eficiente). Só cai para
      // agregação por apartamento quando realmente necessário.
      List<ItemApartamento> todos = [];
      try {
        todos = await _apiService.getTodosItensApartamento();
      } catch (e) {
        AppLogger.warning(
          'ApartamentosProvider',
          'Falha ao carregar /itemapartamento. Tentando agregacao por apartamento.',
          e,
        );
      }

      List<ItemApartamento> porApartamento = const <ItemApartamento>[];
      if (todos.isEmpty) {
        porApartamento = await _carregarItensPorApartamento();
      }

      final Map<String, ItemApartamento> porId = {
        for (final item in [...todos, ...porApartamento]) item.id: item,
      };

      _todosItens = porId.values.toList()
        ..sort((a, b) {
          final codA = (a.codigoPatrimonio ?? a.codigoIdentificador ?? '')
              .toLowerCase();
          final codB = (b.codigoPatrimonio ?? b.codigoIdentificador ?? '')
              .toLowerCase();
          return codA.compareTo(codB);
        });

      AppLogger.info(
        'ApartamentosProvider',
        'Ativos carregados: ${_todosItens?.length ?? 0} '
            '(todos=${todos.length}, porApartamento=${porApartamento.length})',
      );
      _todosItensLoadedAt = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar ativos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isTodosItensCacheFresh() {
    if (_todosItens == null || _todosItensLoadedAt == null) return false;
    return DateTime.now().difference(_todosItensLoadedAt!) <
        _todosItensCacheTtl;
  }

  void _invalidateTodosItensCache({bool clearData = false}) {
    _todosItensLoadedAt = null;
    if (clearData) {
      _todosItens = null;
    }
  }

  Future<List<ItemApartamento>> _carregarItensPorApartamento() async {
    try {
      var apartamentos = _apartamentos;
      if (apartamentos.isEmpty) {
        apartamentos = await _apiService.getApartamentos(
          pageNumber: 1,
          pageSize: 500,
        );
        if (apartamentos.isNotEmpty) {
          _apartamentos = apartamentos;
        }
      }

      if (apartamentos.isEmpty) return <ItemApartamento>[];

      final resultados = await Future.wait(
        apartamentos.map((a) async {
          try {
            return await _apiService.getItensApartamento(a.id);
          } catch (_) {
            return <ItemApartamento>[];
          }
        }),
      );

      return resultados.expand((e) => e).toList();
    } catch (_) {
      return <ItemApartamento>[];
    }
  }

  bool _isManutencaoOuDanificado(String? estado) {
    return isEstadoManutencaoOuDanificado(estado);
  }

  /// Atualizar código identificador do item
  Future<bool> atualizarCodigoIdentificador(
    String itemId,
    String codigo,
  ) async {
    try {
      ItemApartamento? itemBase;
      for (final item in (_todosItens ?? const <ItemApartamento>[])) {
        if (item.id == itemId) {
          itemBase = item;
          break;
        }
      }

      // Backend atual não possui /itemapartamento/{id}/codigo (404),
      // então atualiza direto no endpoint geral.
      await _apiService.atualizarItemApartamento(itemId, {
        if (itemBase?.nome != null) 'nome': itemBase!.nome,
        if (itemBase?.descricao != null) 'descricao': itemBase!.descricao,
        if (itemBase?.tipo != null) 'tipo': itemBase!.tipo,
        if (itemBase?.quantidade != null) 'quantidade': itemBase!.quantidade,
        'estadoAtual':
            (itemBase?.estadoAtual ??
            itemBase?.estadoDesgaste ??
            itemBase?.status ??
            estadoToString(ItemEstado.Disponivel)),
        if (itemBase?.dataAquisicao != null)
          'dataAquisicao': toBackendUtcIsoString(itemBase!.dataAquisicao!),
        if (itemBase?.dataEntradaNoApto != null)
          'dataEntradaNoApto': toBackendUtcIsoString(itemBase!.dataEntradaNoApto!),
        'codigoPatrimonio': codigo,
      });

      // Valida persistência no backend para evitar falso sucesso na UI.
      final itensAtualizados = await _apiService.getTodosItensApartamento();
      ItemApartamento? atualizado;
      for (final item in itensAtualizados) {
        if (item.id == itemId) {
          atualizado = item;
          break;
        }
      }
      final codigoAtual =
          (atualizado?.codigoPatrimonio ??
                  atualizado?.codigoIdentificador ??
                  '')
              .trim();
      if (codigoAtual.isEmpty ||
          codigoAtual.toLowerCase() != codigo.trim().toLowerCase()) {
        _errorMessage =
            'Backend não retornou o código de patrimônio após atualização. Verifique UpdateItem/DTO no servidor.';
        notifyListeners();
        return false;
      }

      // Atualiza localmente
      if (_todosItens != null) {
        final idx = _todosItens!.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          _todosItens![idx] = _todosItens![idx].copyWith(
            codigoPatrimonio: codigo,
            codigoIdentificador: codigo,
          );
        }
      }
      if (_apartamentoAtual?.itens != null) {
        final idx = _apartamentoAtual!.itens!.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          final novosItens = List<ItemApartamento>.from(
            _apartamentoAtual!.itens!,
          );
          novosItens[idx] = novosItens[idx].copyWith(
            codigoIdentificador: codigo,
            codigoPatrimonio: codigo,
          );
          _apartamentoAtual = _apartamentoAtual!.copyWith(itens: novosItens);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar código: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Getters
  List<Apartamento> get apartamentos => _apartamentos;
  List<Apartamento> get apartamentosDisponiveis => _apartamentosDisponiveis;
  List<String> get blocos => _blocos;
  Apartamento? get apartamentoAtual => _apartamentoAtual;
  List<ItemApartamento> get itensApartamento => _itensApartamento;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  /// Limpa todos os dados do provider (usado quando morador não tem apartamento vinculado)
  void limparDados() {
    _apartamentos = [];
    _apartamentosDisponiveis = [];
    _apartamentoAtual = null;
    _itensApartamento = [];
    _invalidateTodosItensCache(clearData: true);
    _carregarTodosItensFuture = null;
    _errorMessage = null;
    _apartamentosLoadedAt = null;
    _apartamentosComMoradores = false;
    notifyListeners();
  }

  /// Load a single apartment by ID and set it as the only apartment in the list
  /// Used for moradores who can only see their own apartment
  Future<void> carregarApartamentoPorId(String id) async {
    await executeOperation(() async {
      AppLogger.info(
        'ApartamentosProvider',
        'Carregando apartamento único (morador): $id',
      );
      final apartamento = await _apiService.getApartamento(id);
      var apartamentoComMoradores = apartamento;
      try {
        var moradores = await _apiService.getOcupantes(id);
        if (moradores.isEmpty) {
          moradores = await _apiService.getMoradores(apartamentoId: id);
        }
        if (moradores.isNotEmpty) {
          apartamentoComMoradores = apartamento.copyWith(
            moradores: moradores,
            quantidadeMoradores: moradores.length,
          );
        }
      } catch (e) {
        AppLogger.debug(
          'ApartamentosProvider',
          'Falha ao enriquecer apartamento com moradores: $e',
        );
      }

      _apartamentos = [apartamentoComMoradores];
      _apartamentoAtual = apartamentoComMoradores;
      AppLogger.debug(
        'ApartamentosProvider',
        'Carregado apartamento: ${apartamentoComMoradores.numero}/${apartamentoComMoradores.bloco}',
      );
    });
  }

  /// Load all apartments
  ///
  /// [comMoradores] — quando true, enriquece apartamentos ocupados com
  /// nomes dos moradores em background (via batch /moradores).
  /// Use false no dashboard para evitar chamadas extras desnecessárias.
  Future<void> carregarApartamentos({
    String? bloco,
    String? estado,
    int pageNumber = 1,
    int pageSize = 20,
    int? andar,
    bool? emManutencao,
    bool forceRefresh = false,
    bool comMoradores = true,
  }) async {
    // Cache TTL: skip reload if data is fresh and no filters applied
    // Force reload if moradores are requested but cache was loaded without them
    if (!forceRefresh &&
        bloco == null &&
        estado == null &&
        andar == null &&
        emManutencao == null &&
        _apartamentos.isNotEmpty &&
        _apartamentosLoadedAt != null &&
        DateTime.now().difference(_apartamentosLoadedAt!) < _apartamentosCacheTtl &&
        (!comMoradores || _apartamentosComMoradores)) {
      AppLogger.debug('ApartamentosProvider', 'Cache válido — ignorando recarga');
      return;
    }
    await executeOperation(() async {
      AppLogger.info(
        'ApartamentosProvider',
        'Carregando apartamentos (bloco: $bloco, estado: $estado, andar: $andar, emManutencao: $emManutencao, page: $pageNumber/$pageSize, comOcupantes: $comMoradores)',
      );
      _apartamentos = await _apiService.getApartamentos(
        bloco: bloco,
        estado: estado,
        pageNumber: pageNumber,
        pageSize: pageSize,
        andar: andar,
        emManutencao: emManutencao,
        comOcupantes: comMoradores,
      );
      AppLogger.debug(
        'ApartamentosProvider',
        'Carregados ${_apartamentos.length} apartamentos',
      );
      _apartamentosLoadedAt = DateTime.now();
      _apartamentosComMoradores = comMoradores;
    });
  }

  /// Load only apartments in maintenance
  Future<void> carregarApartamentosEmManutencao() async {
    await executeOperation(() async {
      AppLogger.info(
        'ApartamentosProvider',
        'Carregando apartamentos em manutenção',
      );
      _apartamentos = await _apiService.getApartamentosEmManutencao();
      AppLogger.debug(
        'ApartamentosProvider',
        'Carregados ${_apartamentos.length} apartamentos em manutenção',
      );
    });
  }

  /// Load a single apartment with items and residents
  Future<void> carregarApartamento(String id) async {
    await executeOperation(() async {
      AppLogger.info('ApartamentosProvider', 'Carregando apartamento: $id');
      // mark this id as the currently-loading apartment to avoid race conditions
      final loadingId = id;
      _currentLoadingApartamentoId = loadingId;

      // Load apartment meta first but defer assigning to _apartamentoAtual
      final meta = await _apiService.getApartamento(id);
      try {
        // Load items
        final itens = await _apiService.getItensApartamento(id);
        _itensApartamento = itens;

        // Load ocupantes (preferred authoritative source)
        var moradores = await _apiService.getOcupantes(id);

        // If /ocupantes returns empty, fallback to /moradores?apartamentoId={id}
        if (moradores.isEmpty) {
          AppLogger.debug(
            'ApartamentosProvider',
            'O endpoint /ocupantes retornou vazio, tentando /moradores?apartamentoId=$id',
          );
          final fallback = await _apiService.getMoradores(apartamentoId: id);
          if (fallback.isNotEmpty) moradores = fallback;
        }

        // If another load started after this one, ignore these results
        if (_currentLoadingApartamentoId != loadingId) {
          AppLogger.debug(
            'ApartamentosProvider',
            'Resposta antiga ignorada para apartamento: $id',
          );
          return;
        }

        // Atomically assign apartamentoAtual once we have all parts
        _apartamentoAtual = meta.copyWith(
          itens: itens.isNotEmpty ? itens : null,
          moradores: moradores.isNotEmpty ? moradores : null,
          quantidadeMoradores: moradores.length,
        );

        // Update apartments list entry if present (keep immutable updates)
        final idx = _apartamentos.indexWhere(
          (a) => a.id == _apartamentoAtual!.id,
        );
        if (idx != -1) {
          _apartamentos[idx] = _apartamentos[idx].copyWith(
            itens: itens.isNotEmpty ? itens : null,
            moradores: moradores.isNotEmpty ? moradores : null,
            quantidadeMoradores: moradores.length,
          );
        }
      } catch (e) {
        AppLogger.debug(
          'ApartamentosProvider',
          'Erro ao carregar itens/moradores: $e',
        );
        // Continue even if items/moradores fail; assign meta as fallback
        // Only assign if this is still the current load
        if (_currentLoadingApartamentoId == loadingId) {
          _apartamentoAtual = meta;
        }
      }
      // Clear guard and notify listeners if this load is the active one
      if (_currentLoadingApartamentoId == loadingId) {
        AppLogger.debug(
          'ApartamentosProvider',
          'Apartamento carregado: ${_apartamentoAtual?.numero}',
        );
        _currentLoadingApartamentoId = null;
        notifyListeners();
      } else {
        AppLogger.debug(
          'ApartamentosProvider',
          'Carregamento interrompido/obsoleto para: $id',
        );
      }
    });
  }

  /// Create apartment
  Future<bool> criarApartamento({
    required String nome,
    required String numero,
    required String bloco,
    required int andar,
    required String estado,
    required int quartos,
    required int banheiros,
    double? areaMetrosQuadrados,
    String? descricao,
    String? observacoes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CriarApartamentoRequest(
        nome: nome,
        numero: numero,
        bloco: bloco,
        andar: andar,
        estado: estado,
        quartos: quartos,
        banheiros: banheiros,
        areaMetrosQuadrados: areaMetrosQuadrados,
        descricao: descricao,
        observacoes: observacoes,
      );

      final novo = await _apiService.criarApartamento(request);
      _apartamentos.add(novo);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update apartment
  Future<bool> atualizarApartamento(
    String id, {
    required String nome,
    required String numero,
    required String bloco,
    required int andar,
    String? estado,
    String? descricao,
    int? quartos,
    int? banheiros,
    double? areaMetrosQuadrados,
    String? observacoes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = AtualizarApartamentoRequest(
        nome: nome,
        numero: numero,
        bloco: bloco,
        andar: andar,
        estado: estado,
        descricao: descricao,
        quartos: quartos,
        banheiros: banheiros,
        areaMetrosQuadrados: areaMetrosQuadrados,
        observacoes: observacoes,
      );

      await _apiService.atualizarApartamento(id, request);

      // Reload to get updated data
      await carregarApartamento(id);
      await carregarApartamentos();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete apartment
  Future<bool> deletarApartamento(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletarApartamento(id);
      _apartamentos.removeWhere((a) => a.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load available apartments
  Future<void> carregarApartamentosDisponiveis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _apartamentosDisponiveis = await _apiService.getApartamentosDisponiveis();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load building blocks/sectors
  Future<void> carregarBlocos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _blocos = await _apiService.getBlocos();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load items for an apartment
  Future<void> carregarItensApartamento(String apartamentoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _itensApartamento = await _apiService.getItensApartamento(apartamentoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create apartment item
  Future<bool> criarItemApartamento({
    String? apartamentoId,
    required String nome,
    required String descricao,
    String? tipo,
    int? quantidade,
    double? valorEstimado,
    String? status,
    String? codigoIdentificador,
    String? estadoDesgaste,
    DateTime? dataAquisicao,
    DateTime? dataEntradaNoApto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CriarItemApartamentoRequest(
        apartamentoId: apartamentoId,
        nome: nome,
        descricao: descricao,
        tipo: tipo,
        quantidade: quantidade,
        valorEstimado: valorEstimado,
        codigoPatrimonio: codigoIdentificador,
        estadoAtual: estadoDesgaste ?? status,
        dataAquisicao: dataAquisicao,
        dataEntradaNoApto: dataEntradaNoApto,
      );

      final novoItem = await _apiService.criarItemApartamento(request);
      _itensApartamento.add(novoItem);
      _todosItens = [...?_todosItens, novoItem];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update apartment item
  Future<bool> atualizarItemApartamento(
    String id, {
    required String nome,
    required String descricao,
    String? tipo,
    int? quantidade,
    double? valorEstimado,
    String? status,
    String? codigoIdentificador,
    String? estadoDesgaste,
    DateTime? dataAquisicao,
    DateTime? dataEntradaNoApto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // AtualizarItemApartamentoDto: Nome, Descricao, Tipo, Quantidade, EstadoAtual, DataAquisicao, DataEntradaNoApto
      // CodigoPatrimonio is server-generated and immutable — never send it in update
      final estadoFinal = estadoDesgaste ?? status;
      final dados = {
        'nome': nome,
        'descricao': descricao,
        'tipo': ?tipo,
        'quantidade': ?quantidade,
        'estadoAtual': ?estadoFinal,
        if (dataAquisicao != null)
          'dataAquisicao': toBackendUtcIsoString(dataAquisicao),
        if (dataEntradaNoApto != null)
          'dataEntradaNoApto': toBackendUtcIsoString(dataEntradaNoApto),
      };

      await _apiService.atualizarItemApartamento(id, dados);

      // Update local item
      final index = _itensApartamento.indexWhere((item) => item.id == id);
      if (index >= 0 && _itensApartamento[index].apartamentoId != null) {
        await carregarItensApartamento(_itensApartamento[index].apartamentoId!);
      }
      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete apartment item
  Future<bool> deletarItemApartamento(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletarItemApartamento(id);
      _itensApartamento.removeWhere((item) => item.id == id);
      _todosItens?.removeWhere((item) => item.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Vincular item ao apartamento (move de stock para apartamento)
  Future<bool> vincularItemApartamento(
    String itemId,
    String apartamentoId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final itemAtualizado = await _apiService.vincularItemApartamento(
        itemId,
        apartamentoId,
      );
      final estadoAtual =
          itemAtualizado.estadoAtual ??
          itemAtualizado.estadoDesgaste ??
          itemAtualizado.status;
      if (!_isManutencaoOuDanificado(estadoAtual)) {
        try {
          await _apiService.atualizarEstadoItemApartamento({
            'itemApartamentoId': itemId,
            'novoEstado': estadoToString(ItemEstado.Disponivel),
            'motivo': 'VinculoApartamento',
            'observacoes': 'AtualizacaoAutomaticaEstado',
          });
        } catch (_) {}
      }

      // Atualiza item na lista local
      final index = _todosItens?.indexWhere((i) => i.id == itemId) ?? -1;
      if (index >= 0) {
        _todosItens![index] = itemAtualizado;
      }

      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Desvincular item do apartamento (move para stock)
  Future<bool> desvincularItemApartamento(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final itemAtualizado = await _apiService.desvincularItemApartamento(
        itemId,
      );
      final estadoAtual =
          itemAtualizado.estadoAtual ??
          itemAtualizado.estadoDesgaste ??
          itemAtualizado.status;
      if (!_isManutencaoOuDanificado(estadoAtual)) {
        try {
          await _apiService.atualizarEstadoItemApartamento({
            'itemApartamentoId': itemId,
            'novoEstado': estadoToString(ItemEstado.EmStock),
            'motivo': 'DesvinculoApartamento',
            'observacoes': 'AtualizacaoAutomaticaEstado',
          });
        } catch (_) {}
      }

      // Atualiza item na lista local
      final index = _todosItens?.indexWhere((i) => i.id == itemId) ?? -1;
      if (index >= 0) {
        _todosItens![index] = itemAtualizado;
      }

      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create multiple items at once
  Future<bool> criarItensApartamentoBulk(
    String apartamentoId,
    List<Map<String, String>> itens,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requests = itens
          .map(
            (item) => CriarItemApartamentoRequest(
              apartamentoId: apartamentoId,
              nome: item['nome']!,
              descricao: item['descricao'] ?? '',
            ),
          )
          .toList();

      final novosItens = await _apiService.criarItensApartamentoBulk(requests);
      _itensApartamento.addAll(novosItens);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('não encontrado')) {
      return 'Apartamento não encontrado.';
    } else if (msg.contains('já existe')) {
      return 'Esse apartamento já existe.';
    } else if (msg.contains('Permission')) {
      return 'Você não tem permissão para esta ação.';
    }
    return msg;
  }

  /// Adiciona um novo item ao apartamento
  Future<bool> adicionarItemApartamento(
    String apartamentoId,
    String nome,
    String descricao, {
    String? tipo,
    int? quantidade,
    double? valorEstimado,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.criarItemApartamento(
        CriarItemApartamentoRequest(
          apartamentoId: apartamentoId,
          nome: nome,
          descricao: descricao.isEmpty ? null : descricao,
          tipo: tipo,
          quantidade: quantidade,
          valorEstimado: valorEstimado,
          status: status,
        ),
      );
      await carregarItensApartamento(apartamentoId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove um item do apartamento
  Future<bool> removerItemApartamento(
    String apartamentoId,
    String itemId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletarItemApartamento(itemId);
      await carregarItensApartamento(apartamentoId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Transferir item de apartamento
  Future<bool> transferirItemApartamento(
    TransferirItemApartamentoRequest request,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final authOk = await _apiService.ensureAuthenticated(
        forceRevalidate: true,
      );
      if (!authOk) {
        _errorMessage = 'Sessão expirada. Faça login novamente.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _apiService.transferirItemApartamento(request.toJson());
      _historicoMovimentacaoCache.remove(request.itemApartamentoId);
      await getHistoricoMovimentacao(
        request.itemApartamentoId,
        updateState: false,
        forceRefresh: true,
      );
      await carregarItensApartamento(request.apartamentoDestinoId);
      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao transferir item: ${_formatError(e)}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Atualizar estado de item de apartamento
  Future<bool> atualizarEstadoItemApartamento(
    AtualizarEstadoItemApartamentoRequest request,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.atualizarEstadoItemApartamento(request.toJson());
      _historicoMovimentacaoCache.remove(request.itemApartamentoId);
      await getHistoricoMovimentacao(
        request.itemApartamentoId,
        updateState: false,
        forceRefresh: true,
      );
      await carregarItensApartamento(_apartamentoAtual?.id ?? '');
      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar estado: ${_formatError(e)}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Buscar histórico de movimentação de item
  Future<List<ItemApartamentoMovimentacaoHistoricoDto>>
  getHistoricoMovimentacao(
    String itemApartamentoId, {
    bool updateState = false,
    bool forceRefresh = false,
  }) async {
    if (itemApartamentoId.isEmpty) {
      debugPrint('[Provider] getHistoricoMovimentacao ignorado: id vazio');
      return [];
    }
    if (updateState) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      if (!forceRefresh &&
          _historicoMovimentacaoCache.containsKey(itemApartamentoId)) {
        final cached =
            _historicoMovimentacaoCache[itemApartamentoId] ??
            <ItemApartamentoMovimentacaoHistoricoDto>[];
        if (updateState) {
          _isLoading = false;
          notifyListeners();
        }
        return cached;
      }

      // Tentar endpoint relatorio-completo primeiro
      List<ItemApartamentoMovimentacaoHistoricoDto> historico = [];
      bool relatorioOk = false;
      try {
        debugPrint(
          '[Provider] GET itemapartamento/$itemApartamentoId/relatorio-completo',
        );
        final relatorio = await _apiService.request(
          'itemapartamento/$itemApartamentoId/relatorio-completo',
          fromJson: (json) => json,
        );

        if (relatorio is Map<String, dynamic>) {
          debugPrint('[Provider] Chaves relatorio: ${relatorio.keys.toList()}');
          if (relatorio['movimentacoes'] != null) {
            final movList = relatorio['movimentacoes'] as List;
            debugPrint('[Provider] movimentacoes count: ${movList.length}');
            historico = movList
                .map((e) {
                  try {
                    return ItemApartamentoMovimentacaoHistoricoDto.fromJson(
                      e as Map<String, dynamic>,
                    );
                  } catch (parseErr) {
                    debugPrint(
                      '[Provider] Erro parsing movimentação: $parseErr | JSON: $e',
                    );
                    return null;
                  }
                })
                .whereType<ItemApartamentoMovimentacaoHistoricoDto>()
                .toList();
          } else {
            debugPrint('[Provider] movimentacoes é null no relatorio');
          }
          relatorioOk = true;
        } else {
          debugPrint(
            '[Provider] Resposta relatorio não é Map: ${relatorio.runtimeType}',
          );
        }
      } catch (e) {
        debugPrint(
          '[Provider] Erro relatorio-completo: $e — tentando endpoint historico',
        );
      }

      // Fallback: endpoint dedicado de histórico
      if (!relatorioOk || historico.isEmpty) {
        try {
          debugPrint(
            '[Provider] GET itemapartamentomovimentacao/$itemApartamentoId/historico',
          );
          final resp = await _apiService.request(
            'itemapartamentomovimentacao/$itemApartamentoId/historico',
            fromJson: (json) => json,
          );
          if (resp is List) {
            historico = resp
                .map((e) {
                  try {
                    return ItemApartamentoMovimentacaoHistoricoDto.fromJson(
                      e as Map<String, dynamic>,
                    );
                  } catch (parseErr) {
                    debugPrint(
                      '[Provider] Erro parsing historico item: $parseErr',
                    );
                    return null;
                  }
                })
                .whereType<ItemApartamentoMovimentacaoHistoricoDto>()
                .toList();
            debugPrint(
              '[Provider] historico endpoint count: ${historico.length}',
            );
          }
        } catch (e2) {
          debugPrint('[Provider] Erro endpoint historico: $e2');
        }
      }

      _historicoMovimentacaoCache[itemApartamentoId] = historico;
      if (updateState) {
        _isLoading = false;
        notifyListeners();
      }
      return historico;
    } catch (e) {
      if (updateState) {
        _errorMessage = 'Erro ao buscar histórico: ${_formatError(e)}';
        _isLoading = false;
        notifyListeners();
      }
      return [];
    }
  }

  Future<ItemApartamento?> getRelatorioCompletoItem(String itemId) async {
    try {
      return await _apiService.getRelatorioCompletoItemApartamento(itemId);
    } catch (e) {
      _errorMessage = 'Erro ao carregar relatório completo: ${_formatError(e)}';
      notifyListeners();
      return null;
    }
  }

  Future<List<int>?> getQrCodeItem(String itemId) async {
    try {
      return await _apiService.getQrCodeItemApartamento(itemId);
    } catch (e) {
      _errorMessage = 'Erro ao obter QR code: ${_formatError(e)}';
      notifyListeners();
      return null;
    }
  }

  Future<ItemApartamento?> buscarItemPorPatrimonio(String codigo) async {
    final c = codigo.trim();
    if (c.isEmpty) return null;
    try {
      return await _apiService.getItemApartamentoPorPatrimonio(c);
    } catch (e) {
      // Fallback local para ambientes sem endpoint /patrimonio/{codigo}
      final local = _todosItens?.firstWhere((item) {
        final cod = (item.codigoPatrimonio ?? item.codigoIdentificador ?? '')
            .trim()
            .toLowerCase();
        return cod.isNotEmpty && cod == c.toLowerCase();
      }, orElse: () => ItemApartamento(id: '', nome: ''));

      if (local != null && local.id.isNotEmpty) {
        return local;
      }

      _errorMessage = 'Erro ao buscar ativo por código: ${_formatError(e)}';
      notifyListeners();
      return null;
    }
  }

  Future<QrCodesLoteResult?> gerarQrCodesEmLote({List<String>? itemIds}) async {
    try {
      return await _apiService.gerarQrCodesLote(itemIds: itemIds);
    } catch (e) {
      _errorMessage = 'Erro ao gerar QR codes em lote: ${_formatError(e)}';
      notifyListeners();
      return null;
    }
  }

  Future<ItemApartamento?> gerarCodigoPatrimonio(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final atualizado = await _apiService.gerarCodigoPatrimonio(itemId);
      _invalidateTodosItensCache();
      await carregarTodosItens(forceRefresh: true);
      _isLoading = false;
      notifyListeners();
      return atualizado;
    } catch (e) {
      _errorMessage = 'Erro ao gerar código de patrimônio: ${_formatError(e)}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // REAL-TIME SYNC — DataChanged
  // ===========================================================================

  /// Inicia a escuta de eventos DataChanged para apartamentos.
  /// Quando [apartamentoIdRestrito] é informado, recarrega apenas esse apartamento.
  /// Útil para Morador/Visitante para evitar carregar a lista global.
  void inicializarRealtimeSync({String? apartamentoIdRestrito}) {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = _signalRService.onDataChanged.listen((data) {
      final entidade = data['entidade']?.toString() ?? '';
      if (entidade == 'Apartamento') {
        final acao = data['acao']?.toString() ?? '';
        final eventoApartamentoId = data['id']?.toString();
        final possuiRestricao =
            apartamentoIdRestrito != null && apartamentoIdRestrito.isNotEmpty;

        if (possuiRestricao) {
          if (eventoApartamentoId != null &&
              eventoApartamentoId.isNotEmpty &&
              eventoApartamentoId != apartamentoIdRestrito) {
            AppLogger.debug(
              'ApartamentosProvider',
              'DataChanged ignorado para apto $eventoApartamentoId (restrito ao apto $apartamentoIdRestrito)',
            );
            return;
          }

          AppLogger.info(
            'ApartamentosProvider',
            'DataChanged recebido: $entidade/$acao — recarregando apartamento restrito $apartamentoIdRestrito',
          );
          carregarApartamentoPorId(apartamentoIdRestrito);
          return;
        }

        AppLogger.info(
          'ApartamentosProvider',
          'DataChanged recebido: $entidade/$acao — recarregando apartamentos',
        );
        carregarApartamentos();
      }
    });
    if (apartamentoIdRestrito != null && apartamentoIdRestrito.isNotEmpty) {
      AppLogger.info(
        'ApartamentosProvider',
        'Escutando DataChanged (Apartamento) em modo restrito: $apartamentoIdRestrito',
      );
    } else {
      AppLogger.info(
        'ApartamentosProvider',
        'Escutando DataChanged (Apartamento)',
      );
    }
  }

  /// Para a escuta de eventos em tempo real.
  void pararRealtimeSync() {
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = null;
  }

  /// PUT /api/apartamentos/{id}/toggle-manutencao
  /// Alterna a flag EmManutencao sem alterar o estado do apartamento
  Future<bool> toggleManutencao(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apartamentoAtualizado = await _apiService.toggleManutencao(id);
      // Atualiza localmente
      final idx = _apartamentos.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _apartamentos[idx] = apartamentoAtualizado;
      }
      if (_apartamentoAtual?.id == id) {
        _apartamentoAtual = apartamentoAtualizado;
      }
      AppLogger.info(
        'ApartamentosProvider',
        'Toggle manutenção: ${apartamentoAtualizado.numero} → emManutencao=${apartamentoAtualizado.emManutencao}',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao alternar manutenção: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// POST /api/apartamentos/bulk
  /// Criação em lote de apartamentos com validação de duplicatas
  Future<List<Apartamento>> criarApartamentosBulk(
    List<Map<String, dynamic>> dados,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novos = await _apiService.criarApartamentosBulk(dados);
      _apartamentos.addAll(novos);
      AppLogger.info(
        'ApartamentosProvider',
        'Criados ${novos.length} apartamentos em lote',
      );
      _isLoading = false;
      notifyListeners();
      return novos;
    } catch (e) {
      _errorMessage = 'Erro na criação em lote: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// GET /api/exportacao/ativos/excel
  /// Exporta ativos em Excel com filtros opcionais
  Future<List<int>> exportarAtivosExcel({
    String? estado,
    String? tipo,
    String? apartamentoId,
  }) async {
    return _apiService.exportarAtivosExcel(
      estado: estado,
      tipo: tipo,
      apartamentoId: apartamentoId,
    );
  }

  /// Reset all state (used on logout)
  @override
  void reset() {
    pararRealtimeSync();
    _apartamentos = [];
    _apartamentosDisponiveis = [];
    _blocos = [];
    _apartamentoAtual = null;
    _itensApartamento = [];
    _invalidateTodosItensCache(clearData: true);
    _carregarTodosItensFuture = null;
    _historicoMovimentacaoCache.clear();
    _currentLoadingApartamentoId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
