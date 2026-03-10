import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../dto/item_apartamento_dto.dart';
import '../dto/item_estado_enums.dart';
import '../services/itens_service.dart';

/// Provider de gestão de itens patrimoniais
/// Gerencia estado e operações de /api/itens
class ItensProvider extends ChangeNotifier {
  final ItensService _service = ItensService();

  // Estado
  List<ItemSearchResultDto> _itens = [];
  ItemApartamentoDto? _itemAtual;
  HistoricoItemDto? _historicoAtual;
  AtivosEstatisticas? _estatisticas;
  Uint8List? _qrCodeAtual;
  
  bool _isLoading = false;
  String? _erro;
  
  // Paginação
  int _paginaAtual = 1;
  int _totalPaginas = 1;
  int _totalItens = 0;
  final int _itensPorPagina = 20;
  bool _hasMore = false;

  // Filtros ativos
  int? _filtroEstado;
  int? _filtroStatusOperacional;
  String? _filtroTipo;
  String? _filtroApartamentoId;
  String? _filtroQuery;

  // Getters
  List<ItemSearchResultDto> get itens => _itens;
  ItemApartamentoDto? get itemAtual => _itemAtual;
  HistoricoItemDto? get historicoAtual => _historicoAtual;
  AtivosEstatisticas? get estatisticas => _estatisticas;
  Uint8List? get qrCodeAtual => _qrCodeAtual;
  bool get isLoading => _isLoading;
  String? get erro => _erro;
  int get paginaAtual => _paginaAtual;
  int get totalPaginas => _totalPaginas;
  int get totalItens => _totalItens;
  bool get hasMore => _hasMore;

  /// Carrega lista de itens com filtros
  Future<void> carregarItens({
    int? estado,
    int? statusOperacional,
    String? tipo,
    String? apartamentoId,
    String? query,
    int pagina = 1,
    bool reset = false,
  }) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _erro = null;
    
    if (reset || pagina == 1) {
      _itens = [];
      _paginaAtual = 1;
    }
    
    // Salva filtros
    _filtroEstado = estado ?? _filtroEstado;
    _filtroStatusOperacional = statusOperacional ?? _filtroStatusOperacional;
    _filtroTipo = tipo ?? _filtroTipo;
    _filtroApartamentoId = apartamentoId ?? _filtroApartamentoId;
    _filtroQuery = query ?? _filtroQuery;

    notifyListeners();

    try {
      final resultado = await _service.listarItens(
        estado: _filtroEstado,
        statusOperacional: _filtroStatusOperacional,
        tipo: _filtroTipo,
        apartamentoId: _filtroApartamentoId,
        query: _filtroQuery,
        page: pagina,
        pageSize: _itensPorPagina,
      );

      if (pagina == 1) {
        _itens = resultado.items;
      } else {
        _itens = [..._itens, ...resultado.items];
      }

      _paginaAtual = resultado.page;
      _totalPaginas = resultado.totalPages;
      _totalItens = resultado.totalCount;
      _hasMore = resultado.hasMore;
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar itens: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega próxima página (infinite scroll)
  Future<void> carregarMais() async {
    if (!_hasMore || _isLoading) return;
    await carregarItens(pagina: _paginaAtual + 1);
  }

  /// Limpa filtros e recarrega
  Future<void> limparFiltros() async {
    _filtroEstado = null;
    _filtroStatusOperacional = null;
    _filtroTipo = null;
    _filtroApartamentoId = null;
    _filtroQuery = null;
    await carregarItens(pagina: 1, reset: true);
  }

  /// Busca item por código de patrimônio (QR scan)
  Future<void> buscarPorCodigo(String codigo) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _itemAtual = await _service.obterPorCodigo(codigo);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Item não encontrado: ${e.toString()}';
      _itemAtual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega detalhes de um item
  Future<void> carregarItem(String id) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _itemAtual = await _service.obterPorId(id);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar item: ${e.toString()}';
      _itemAtual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega item pelo código de patrimônio (útil para QR e deep links)
  Future<void> carregarItemPorCodigo(String codigo) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _itemAtual = await _service.obterPorCodigo(codigo);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar item: ${e.toString()}';
      _itemAtual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria novo item
  Future<ItemApartamentoDto?> criarItem({
    required String nome,
    String? descricao,
    required String tipo,
    DateTime? dataAquisicao,
  }) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final item = await _service.criarItem(CriarItemRequest(
        nome: nome,
        descricao: descricao,
        tipo: tipo,
        dataAquisicao: dataAquisicao,
      ));
      
      // Recarrega lista
      await carregarItens(pagina: 1, reset: true);
      _erro = null;
      return item;
    } on Exception catch (e) {
      _erro = 'Erro ao criar item: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Exclui item
  Future<bool> excluirItem(String id) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await _service.excluirItem(id);
      
      // Remove da lista local
      _itens.removeWhere((i) => i.id == id);
      if (_itemAtual?.id == id) {
        _itemAtual = null;
      }
      
      _erro = null;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao excluir item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aloca item a apartamento 
  Future<bool> alocarItem(String itemId, String apartamentoId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await _service.alocarItem(itemId, apartamentoId);
      
      // Recarrega item atual se for o mesmo
      if (_itemAtual?.id == itemId) {
        await carregarItem(itemId);
      }
      
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao alocar item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Desaloca item
  Future<bool> desalocarItem(String itemId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      await _service.desalocarItem(itemId);
      
      // Recarrega item atual se for o mesmo
      if (_itemAtual?.id == itemId) {
        await carregarItem(itemId);
      }
      
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao desalocar item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Altera estado físico do item
  Future<bool> alterarEstado(String itemId, int novoStatusOperacional, {String? motivo}) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final novoEstado = EstadoFisicoItemExtension.fromInt(novoStatusOperacional);
      await _service.alterarEstado(itemId, novoEstado, motivo: motivo);
      
      // Recarrega item atual se for o mesmo
      if (_itemAtual?.id == itemId) {
        await carregarItem(itemId);
      }
      
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao alterar estado: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atualiza dados do item
  Future<bool> atualizarItem(String itemId, AtualizarItemRequest request) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      final itemAtualizado = await _service.atualizarItem(itemId, request);
      
      // Atualiza item no cache
      if (_itemAtual?.id == itemId) {
        _itemAtual = itemAtualizado;
      }
      
      // Atualiza na lista
      final index = _itens.indexWhere((i) => i.id == itemId);
      if (index >= 0) {
        _itens[index] = ItemSearchResultDto(
          id: itemAtualizado.id,
          codigoPatrimonio: itemAtualizado.codigoPatrimonio,
          nome: itemAtualizado.nome,
          tipo: itemAtualizado.tipo ?? 'Outros',
          estadoFisico: itemAtualizado.estadoFisico,
          statusOperacional: itemAtualizado.statusOperacional,
          apartamentoInfo: itemAtualizado.apartamentoAlocadoNumero != null 
              ? 'Bloco ${itemAtualizado.apartamentoAlocadoBloco ?? ''} - Apt ${itemAtualizado.apartamentoAlocadoNumero}'
              : null,
          possuiManutencaoAtiva: itemAtualizado.possuiManutencaoAtiva,
        );
      }
      
      _erro = null;
      return true;
    } on Exception catch (e) {
      _erro = 'Erro ao atualizar item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega histórico do item
  Future<void> carregarHistorico(String itemId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _historicoAtual = await _service.obterHistorico(itemId);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar histórico: ${e.toString()}';
      _historicoAtual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega estatísticas de itens
  Future<void> carregarEstatisticas() async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _estatisticas = await _service.obterEstatisticas();
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar estatísticas: ${e.toString()}';
      _estatisticas = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega QR Code do item
  Future<void> carregarQrCode(String itemId) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _qrCodeAtual = await _service.obterQrCode(itemId);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Erro ao carregar QR Code: ${e.toString()}';
      _qrCodeAtual = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega itens disponíveis (para dropdowns de alocação)
  Future<List<ItemSearchResultDto>> carregarDisponiveis() async {
    try {
      return await _service.listarDisponiveis();
    } on Exception {
      return [];
    }
  }

  /// Carrega itens de um apartamento específico
  Future<List<ItemSearchResultDto>> carregarPorApartamento(String apartamentoId) async {
    try {
      return await _service.listarPorApartamento(apartamentoId);
    } on Exception {
      return [];
    }
  }

  /// Carrega itens em manutenção
  Future<List<ItemSearchResultDto>> carregarEmManutencao() async {
    try {
      return await _service.listarEmManutencao();
    } on Exception {
      return [];
    }
  }

  /// Limpa item atual
  void limparItemAtual() {
    _itemAtual = null;
    _historicoAtual = null;
    _qrCodeAtual = null;
    notifyListeners();
  }

  /// Limpa erro
  void limparErro() {
    _erro = null;
    notifyListeners();
  }
}
