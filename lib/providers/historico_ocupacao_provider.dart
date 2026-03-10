import '../models/models.dart';
import '../models/historico_ocupacao.dart';
import '../services/api_service.dart';
import '../utils/app_logger.dart';
import 'base_provider.dart';

enum FiltroPeriodo { ultimos30Dias, ultimos6Meses, ultimos12Meses, todos }

/// HistoricoOcupacaoProvider manages occupation history state
class HistoricoOcupacaoProvider extends BaseProvider {
  final ApiService _apiService = ApiService();

  List<HistoricoOcupacaoResumo> _historicoApartamento = [];
  List<HistoricoOcupacaoResumo> _historicoMorador = [];
  List<HistoricoOcupacao> _historicosDetalhados = [];
  List<HistoricoOcupacaoResumo> _eventosDetalhados = [];
  HistoricoOcupacaoDetalhado? _historicoAtual;
  FiltroPeriodo _filtroPeriodo = FiltroPeriodo.todos;
  
  // Cache para nomes de moradores e executores (id -> nome)
  final Map<String, String> _nomesMoradoresCache = {};
  final Map<String, String> _nomesExecutoresCache = {};

  // Getters
  List<HistoricoOcupacaoResumo> get historicoApartamento => _historicoApartamento;
  List<HistoricoOcupacaoResumo> get historicoMorador => _historicoMorador;
  List<HistoricoOcupacao> get historicosDetalhados => _historicosDetalhados;
  HistoricoOcupacaoDetalhado? get historicoAtual => _historicoAtual;
  FiltroPeriodo get filtroPeriodo => _filtroPeriodo;

  /// Lista filtrada por período selecionado
  List<HistoricoOcupacao> get historicosFiltrados {
    final inicio = _dataInicioFiltro();
    if (inicio == null) return List<HistoricoOcupacao>.from(_historicosDetalhados);

    return _historicosDetalhados.where((h) {
      final fim = h.dataSaida ?? DateTime.now();
      return fim.isAfter(inicio);
    }).toList();
  }

  /// Lista históricos ativos (moradores ainda ocupando)
  List<HistoricoOcupacao> get historicosAtivos => historicosFiltrados.where((h) => h.estaAtivo).toList();

  /// Eventos sem agregação (histórico completo)
  List<HistoricoOcupacaoResumo> get eventosFiltrados {
    final inicio = _dataInicioFiltro();
    if (inicio == null) {
      return List<HistoricoOcupacaoResumo>.from(_eventosDetalhados)
        ..sort((a, b) => b.dataMovimentacao.compareTo(a.dataMovimentacao));
    }

    final filtrados = _eventosDetalhados.where((e) => e.dataMovimentacao.isAfter(inicio)).toList();
    filtrados.sort((a, b) => b.dataMovimentacao.compareTo(a.dataMovimentacao));
    return filtrados;
  }

  /// Lista históricos inativos (moradores que já saíram)
  List<HistoricoOcupacao> get historicosInativos => historicosFiltrados.where((h) => !h.estaAtivo).toList();

  void definirFiltro(FiltroPeriodo filtro) {
    _filtroPeriodo = filtro;
    notifyListeners();
  }

  /// Load apartment occupation history (detailed model) - SEM PAGINAÇÃO
  Future<void> carregarHistoricoDetalhadoApartamento(String apartamentoId) async {
    await executeOperation(() async {
      AppLogger.info('HistoricoOcupacao', 'Carregando histórico detalhado do apartamento: $apartamentoId');

      try {
        // Usa endpoint sem paginação que retorna TODOS os registros diretamente
        var eventos = await _apiService.getHistoricoOcupacaoDetalhadoApartamento(apartamentoId);
        
        // Resolve os nomes dos moradores e executores se o backend não os retornou
        _eventosDetalhados = await _resolverNomesEventos(eventos);
        
        _historicosDetalhados = _agruparEventos(_eventosDetalhados);

        AppLogger.info('HistoricoOcupacao', '✅ Carregados ${_historicosDetalhados.length} registros do apartamento');
        AppLogger.info('HistoricoOcupacao', '✅ Carregados ${_eventosDetalhados.length} eventos detalhados');
      } catch (e) {
        _historicosDetalhados = [];
        _eventosDetalhados = [];
        AppLogger.error('HistoricoOcupacao', '❌ Erro ao carregar histórico: $e');
        rethrow;
      }

      if (_historicosDetalhados.isEmpty) {
        AppLogger.warning('HistoricoOcupacao', '⚠️ Nenhum registro retornado para apartamento: $apartamentoId');
      }

      notifyListeners();

      // Ordena por data de entrada decrescente (mais recente primeiro)
      _historicosDetalhados.sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));
    });
  }

  /// Load resident occupation history (detailed model) - SEM PAGINAÇÃO
  Future<void> carregarHistoricoDetalhadoMorador(String moradorId) async {
    await executeOperation(() async {
      AppLogger.info('HistoricoOcupacao', 'Carregando histórico detalhado do morador: $moradorId');

      try {
        // Usa endpoint sem paginação que retorna TODOS os registros diretamente
        var eventos = await _apiService.getHistoricoOcupacaoDetalhadoMorador(moradorId);
        
        // Resolve os nomes dos moradores e executores se o backend não os retornou
        _eventosDetalhados = await _resolverNomesEventos(eventos);
        
        _historicosDetalhados = _agruparEventos(_eventosDetalhados);

        AppLogger.info('HistoricoOcupacao', '✅ Carregados ${_historicosDetalhados.length} registros do morador');
        AppLogger.info('HistoricoOcupacao', '✅ Carregados ${_eventosDetalhados.length} eventos detalhados');
      } catch (e) {
        _historicosDetalhados = [];
        _eventosDetalhados = [];
        AppLogger.error('HistoricoOcupacao', '❌ Erro ao carregar histórico: $e');
        rethrow;
      }

      if (_historicosDetalhados.isEmpty) {
        AppLogger.warning('HistoricoOcupacao', '⚠️ Nenhum registro retornado para morador: $moradorId');
      }

      notifyListeners();

      _historicosDetalhados.sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));
    });
  }
  
  /// Resolve os nomes dos moradores e executores e retorna eventos atualizados
  Future<List<HistoricoOcupacaoResumo>> _resolverNomesEventos(List<HistoricoOcupacaoResumo> eventos) async {
    if (eventos.isEmpty) return eventos;
    
    // Coleta IDs únicos para resolver
    final moradorIdsParaResolver = <String>{};
    final executorIdsParaResolver = <String>{};
    
    for (final evento in eventos) {
      // Morador
      if (evento.moradorId.isNotEmpty && evento.nomeMorador.isEmpty) {
        if (!_nomesMoradoresCache.containsKey(evento.moradorId)) {
          moradorIdsParaResolver.add(evento.moradorId);
        }
      }
      // Executor
      if (evento.executadoPorId.isNotEmpty && evento.nomeExecutor.isEmpty) {
        if (!_nomesExecutoresCache.containsKey(evento.executadoPorId)) {
          executorIdsParaResolver.add(evento.executadoPorId);
        }
      }
    }
    
    AppLogger.info('HistoricoOcupacao', 
      'Resolvendo nomes: ${moradorIdsParaResolver.length} moradores, ${executorIdsParaResolver.length} executores');
    
    // Busca os nomes em paralelo
    final futures = <Future>[];
    for (final id in moradorIdsParaResolver) {
      futures.add(_buscarNomeMorador(id));
    }
    for (final id in executorIdsParaResolver) {
      futures.add(_buscarNomeExecutor(id));
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    
    AppLogger.info('HistoricoOcupacao', 
      'Cache: ${_nomesMoradoresCache.length} moradores, ${_nomesExecutoresCache.length} executores');
    
    // Cria novos eventos com os nomes resolvidos
    return eventos.map((evento) {
      String nomeMorador = evento.nomeMorador;
      String nomeExecutor = evento.nomeExecutor;
      
      // Resolve nome do morador
      if (nomeMorador.isEmpty && evento.moradorId.isNotEmpty) {
        nomeMorador = _nomesMoradoresCache[evento.moradorId] ?? 'Residente';
      }
      
      // Resolve nome do executor
      if (nomeExecutor.isEmpty && evento.executadoPorId.isNotEmpty) {
        nomeExecutor = _nomesExecutoresCache[evento.executadoPorId] ?? 'Sistema';
      }
      
      // Retorna cópia com nomes atualizados
      return evento.copyWith(
        nomeMorador: nomeMorador,
        nomeExecutor: nomeExecutor,
      );
    }).toList();
  }
  
  /// Busca o nome de um morador pelo ID e adiciona ao cache
  Future<void> _buscarNomeMorador(String moradorId) async {
    try {
      final morador = await _apiService.getMorador(moradorId);
      _nomesMoradoresCache[moradorId] = morador.nome.isNotEmpty ? morador.nome : 'Residente';
      AppLogger.debug('HistoricoOcupacao', 'Morador resolvido: ${morador.nome} para ID $moradorId');
    } catch (e) {
      _nomesMoradoresCache[moradorId] = 'Residente';
      AppLogger.warning('HistoricoOcupacao', 'Falha ao resolver morador $moradorId: $e');
    }
  }
  
  /// Busca o nome de um executor (usuário) pelo ID e adiciona ao cache
  Future<void> _buscarNomeExecutor(String executorId) async {
    try {
      final usuario = await _apiService.getUsuario(executorId);
      _nomesExecutoresCache[executorId] = usuario.nome.isNotEmpty 
          ? usuario.nome 
          : 'Administrador';
      AppLogger.debug('HistoricoOcupacao', 'Executor resolvido: ${usuario.nome} para ID $executorId');
    } catch (e) {
      _nomesExecutoresCache[executorId] = 'Administrador';
      AppLogger.warning('HistoricoOcupacao', 'Falha ao resolver executor $executorId: $e');
    }
  }
  
  /// Obtém o nome do morador do cache ou usa fallback
  String _obterNomeMorador(String moradorId, String nomeFallback) {
    if (nomeFallback.isNotEmpty) return nomeFallback;
    if (_nomesMoradoresCache.containsKey(moradorId)) return _nomesMoradoresCache[moradorId]!;
    return 'Residente';
  }

  /// Registra a saída de um morador usando moradorId
  Future<bool> registrarSaida(String moradorId, {String? motivo}) async {
    if (moradorId.trim().isEmpty) {
      AppLogger.warning('HistoricoOcupacao', 'Tentativa de registrar saída com moradorId vazio');
      setError('Morador inválido para registrar saída.');
      return false;
    }
    try {
      final atualizado = await _apiService.registrarSaidaHistorico(moradorId, motivoSaida: motivo);

      // Atualiza o histórico na lista local (procura pelo moradorId do histórico ativo)
      final index = _historicosDetalhados.indexWhere((h) => h.moradorId == moradorId && h.estaAtivo);
      if (index != -1) {
        _historicosDetalhados[index] = atualizado;
        notifyListeners();
      }

      AppLogger.info('HistoricoOcupacao', 'Saída registrada com sucesso para morador: $moradorId');
      return true;
    } catch (e) {
      AppLogger.error('HistoricoOcupacao', 'Erro ao registrar saída: $e');
      setError('Erro ao registrar saída: $e');
      return false;
    }
  }

  /// Load apartment occupation history (original resumo model)
  Future<void> carregarHistoricoApartamento(String apartamentoId) async {
    await executeOperation(() async {
      AppLogger.info('HistoricoOcupacao', 'Carregando histórico do apartamento: $apartamentoId');
      _historicoApartamento = await _apiService.getHistoricoApartamento(apartamentoId);
      AppLogger.debug('HistoricoOcupacao', 'Carregados ${_historicoApartamento.length} registros');
    });
  }

  /// Load resident occupation history (original resumo model)
  Future<void> carregarHistoricoMorador(String moradorId) async {
    await executeOperation(() async {
      AppLogger.info('HistoricoOcupacao', 'Carregando histórico do morador: $moradorId');
      _historicoMorador = await _apiService.getHistoricoMorador(moradorId);
      AppLogger.debug('HistoricoOcupacao', 'Carregados ${_historicoMorador.length} registros');
    });
  }

  /// Load detailed history record
  Future<void> carregarHistoricoDetalhado(String id) async {
    await executeOperation(() async {
      AppLogger.info('HistoricoOcupacao', 'Carregando histórico: $id');
      _historicoAtual = await _apiService.getHistoricoDetalhado(id);
      AppLogger.debug('HistoricoOcupacao', 'Histórico carregado');
    });
  }

  /// Calcula estatísticas do histórico
  Map<String, dynamic> get estatisticas {
    final filtrados = historicosFiltrados;

    if (filtrados.isEmpty) {
      return {'total': 0, 'ativos': 0, 'inativos': 0, 'mediaOcupacao': 0};
    }

    final ativos = historicosAtivos.length;
    final inativos = historicosInativos.length;

    // Calcula média de dias de ocupação (apenas para inativos)
    final diasTotais = historicosInativos.fold<int>(0, (sum, h) => sum + h.diasOcupacao);
    final mediaOcupacao = inativos > 0 ? diasTotais / inativos : 0;

    return {'total': filtrados.length, 'ativos': ativos, 'inativos': inativos, 'mediaOcupacao': mediaOcupacao.round()};
  }

  DateTime? _dataInicioFiltro() {
    final agora = DateTime.now();
    switch (_filtroPeriodo) {
      case FiltroPeriodo.ultimos30Dias:
        return agora.subtract(const Duration(days: 30));
      case FiltroPeriodo.ultimos6Meses:
        return DateTime(agora.year, agora.month - 6, agora.day);
      case FiltroPeriodo.ultimos12Meses:
        return DateTime(agora.year - 1, agora.month, agora.day);
      case FiltroPeriodo.todos:
        return null;
    }
  }

  /// Clear error message
  @override
  void clearError() {
    super.clearError();
  }

  List<HistoricoOcupacao> _agruparEventos(List<HistoricoOcupacaoResumo> eventos) {
    if (eventos.isEmpty) return [];

    final agrupados = <String, List<HistoricoOcupacaoResumo>>{};
    for (final evento in eventos) {
      final chave = _chaveAgrupamento(evento);
      agrupados.putIfAbsent(chave, () => []).add(evento);
    }

    final resultados = <HistoricoOcupacao>[];

    for (final entry in agrupados.entries) {
      final lista = entry.value..sort((a, b) => a.dataMovimentacao.compareTo(b.dataMovimentacao));
      final ultimo = lista.last;

      final entradas = lista.where(_isEntradaEvento).toList();
      final entrada = entradas.isNotEmpty ? entradas.last : lista.first;

      final saidas = lista
          .where((e) => _isSaidaEvento(e) && e.dataMovimentacao.isAfter(entrada.dataMovimentacao))
          .toList();
      final saida = saidas.isNotEmpty ? saidas.last : null;

      final estaAtivo = !_isSaidaEvento(ultimo);
      final dataSaida = estaAtivo ? null : (saida?.dataMovimentacao ?? ultimo.dataMovimentacao);

      // Usa o moradorId real do backend se disponível
      final moradorIdReal = entrada.moradorId.isNotEmpty 
          ? entrada.moradorId 
          : ultimo.moradorId;
      
      // Resolve o nome do morador do cache ou do evento
      final nomeMoradorResolvido = _obterNomeMorador(
        moradorIdReal, 
        entrada.nomeMorador.isNotEmpty ? entrada.nomeMorador : ultimo.nomeMorador
      );

      resultados.add(
        HistoricoOcupacao(
          id: entrada.id,
          moradorId: moradorIdReal,
          nomeMorador: nomeMoradorResolvido,
          apartamentoId: entrada.apartamentoId.isNotEmpty ? entrada.apartamentoId : ultimo.apartamentoId,
          numeroApartamento: entrada.numeroApartamento.isNotEmpty
              ? entrada.numeroApartamento
              : ultimo.numeroApartamento,
          blocoApartamento: entrada.blocoApartamento.isNotEmpty ? entrada.blocoApartamento : ultimo.blocoApartamento,
          dataEntrada: entrada.dataMovimentacao,
          dataSaida: dataSaida,
          motivoSaida: saida?.observacoes,
          criadoEm: entrada.criadoEm,
        ),
      );
    }

    resultados.sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));
    return resultados;
  }

  bool _isEntradaEvento(HistoricoOcupacaoResumo evento) {
    final tipo = _normalizarTipo(evento.tipoMovimentacao);
    if (tipo == 'entrada') return true;
    if (tipo == 'transferencia') {
      // Em transferência, verifica se este apartamento é o destino
      if (evento.apartamentoDestinoId != null && evento.apartamentoDestinoId!.isNotEmpty) {
        return evento.apartamentoDestinoId == evento.apartamentoId;
      }
      // Fallback para numero do apartamento
      if (evento.numeroApartamentoDestino != null && evento.numeroApartamentoDestino!.isNotEmpty) {
        return evento.numeroApartamentoDestino == evento.numeroApartamento;
      }
      return true;
    }
    return false;
  }

  bool _isSaidaEvento(HistoricoOcupacaoResumo evento) {
    final tipo = _normalizarTipo(evento.tipoMovimentacao);
    if (tipo == 'saida') return true;
    if (tipo == 'transferencia') {
      // Em transferência, verifica se este apartamento é a origem
      if (evento.apartamentoOrigemId != null && evento.apartamentoOrigemId!.isNotEmpty) {
        return evento.apartamentoOrigemId == evento.apartamentoId;
      }
      // Fallback para numero do apartamento
      if (evento.numeroApartamentoOrigem != null && evento.numeroApartamentoOrigem!.isNotEmpty) {
        return evento.numeroApartamentoOrigem == evento.numeroApartamento;
      }
    }
    return false;
  }

  String _normalizarTipo(String tipo) {
    var t = tipo.toLowerCase().trim();
    t = t
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
    return t;
  }

  String _chaveAgrupamento(HistoricoOcupacaoResumo evento) {
    // Prioriza moradorId para agrupamento preciso
    if (evento.moradorId.isNotEmpty) {
      return '${evento.moradorId}@${evento.apartamentoId}';
    }
    
    // Fallback: agrupa por nome + apartamento
    final nome = evento.nomeMorador.trim().toLowerCase();
    final apt = '${evento.numeroApartamento}-${evento.blocoApartamento}'.toLowerCase();
    
    // Se o nome estiver vazio, usa uma chave única baseada no ID do evento
    if (nome.isEmpty) {
      return 'sem-nome-$apt-${evento.id}';
    }
    
    return '$nome@$apt';
  }
}
