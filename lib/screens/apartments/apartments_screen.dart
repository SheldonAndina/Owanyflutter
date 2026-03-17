import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../generated_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../theme/owany_theme.dart';
import '../../providers/apartamentos_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../utils/app_logger.dart';
import '../../utils/network_error_helper.dart';

// =============================================================
// APARTMENTS SCREEN â€” PREMIUM PRO VERSION 2.0
// Features: Glassmorphism, Staggered Animations, Advanced Stats
// =============================================================

class ApartmentsScreen extends StatefulWidget {
  const ApartmentsScreen({super.key});

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  
  late AnimationController _headerAnimController;
  late AnimationController _statsAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  String _blocoFilter = 'todos';
  EstadoApartamento? _estadoFilter;
  bool _isGridView = true;
  bool _showExtendedStats = false;
  final _scrollOffset = ValueNotifier<double>(0);
  List<Apartamento>? _filteredCache;
  List<Apartamento>? _cachedSource;
  int _cachedSourceLength = -1;
  String? _cachedSourceFirstId;
  String? _cachedSourceLastId;
  String _cachedQuery = '';
  String _cachedBlocoFilter = 'todos';
  EstadoApartamento? _cachedEstadoFilter;
  List<Apartamento>? _searchIndexSource;
  int _searchIndexLength = -1;
  String? _searchIndexFirstId;
  String? _searchIndexLastId;
  Map<String, String> _searchIndex = {};

  @override
  void initState() {
    super.initState();
    
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _statsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));
    
    _scrollController.addListener(_onScroll);
    
    Future.microtask(() {
      _carregarDadosComPermissao();
      _headerAnimController.forward();
      _statsAnimController.forward();
    });
  }

  Future<void> _carregarDadosComPermissao({bool forceRefresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final apartamentosProvider = context.read<ApartamentosProvider>();
    final solicitacoesProvider = context.read<SolicitacoesProvider>();
    
    // RBAC: Controle de acesso por perfil
    if (authProvider.isMorador || authProvider.isVisitante) {
      // Morador/Visitante só vê seu apartamento
      final apartamentoId = authProvider.apartamentoIdDoMorador;
      if (apartamentoId != null && apartamentoId.isNotEmpty) {
        AppLogger.info('Apartments', '🔒 Morador carregando APENAS apartamento: $apartamentoId');
        await Future.wait([
          apartamentosProvider.carregarApartamentoPorId(apartamentoId),
          // solicitar histórico do morador em qualquer apartamento (carregar todas as páginas)
          solicitacoesProvider.loadSolicitacoes(
            apartamentoId: apartamentoId,
            refresh: forceRefresh,
            carregarTodas: true,
            incluirHistorico: true,
          ),
        ]);
      } else {
        // Morador sem apartamento vinculado - não carrega nada
        AppLogger.warning('Apartments', '⚠️ Morador sem apartamento vinculado');
        apartamentosProvider.limparDados();
        solicitacoesProvider.limparDados();
      }
    } else if (authProvider.isPortaria) {
      // Portaria vê apartamentos mas não solicitações
      AppLogger.info('Apartments', '🔒 Portaria carregando apartamentos');
      await apartamentosProvider.carregarApartamentos();
    } else if (authProvider.isStaff) {
      // Staff (Admin/Síndico/Funcionário) vê tudo
      AppLogger.info('Apartments', '✅ Staff carregando todos os dados');
      await Future.wait([
        apartamentosProvider.carregarApartamentos(),
        solicitacoesProvider.loadSolicitacoes(
          refresh: forceRefresh,
          carregarTodas: true,
        ),
      ]);
    } else {
      // Outros roles - acesso mínimo
      AppLogger.warning('Apartments', '⚠️ Role sem permissão para apartamentos');
    }
  }
  
  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    _debounce?.cancel();
    _headerAnimController.dispose();
    _statsAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        HapticFeedback.selectionClick();
        _invalidateFilteredCache();
        setState(() {});
      }
    });
  }

  Color _estadoColor(EstadoApartamento estado) {
    switch (estado) {
      case EstadoApartamento.Disponivel:
        return OwanyTheme.success;
      case EstadoApartamento.Ocupado:
        return OwanyTheme.primaryOrange;
      case EstadoApartamento.EmManutencao:
        return OwanyTheme.warning;
      case EstadoApartamento.Inativo:
        return OwanyTheme.error;
    }
  }

  List<Apartamento> _filtrar(List<Apartamento> lista) {
    final q = _searchController.text.toLowerCase().trim();
    final length = lista.length;
    final firstId = length > 0 ? lista.first.id : null;
    final lastId = length > 0 ? lista.last.id : null;

    final canUseCache =
        identical(_cachedSource, lista) &&
        _cachedSourceLength == length &&
        _cachedSourceFirstId == firstId &&
        _cachedSourceLastId == lastId &&
        _cachedQuery == q &&
        _cachedBlocoFilter == _blocoFilter &&
        _cachedEstadoFilter == _estadoFilter &&
        _filteredCache != null;
    if (canUseCache) return _filteredCache!;

    if (q.isNotEmpty &&
        (!identical(_searchIndexSource, lista) ||
            _searchIndexLength != length ||
            _searchIndexFirstId != firstId ||
            _searchIndexLastId != lastId)) {
      _searchIndexSource = lista;
      _searchIndexLength = length;
      _searchIndexFirstId = firstId;
      _searchIndexLastId = lastId;
      _searchIndex = {
        for (final a in lista)
          a.id: [
            a.nome,
            a.numero,
            a.bloco,
          ].map((e) => e.toLowerCase()).join('|'),
      };
    }

    final filtered = lista.where((a) {
      final matchBusca = q.isEmpty ||
          (_searchIndex[a.id] ?? '').contains(q);

      final matchBloco = _blocoFilter == 'todos' ||
          a.bloco.toLowerCase() == _blocoFilter;
      final matchEstado = _estadoFilter == null || a.estado == _estadoFilter;

      return matchBusca && matchBloco && matchEstado;
    }).toList();

    _cachedSource = lista;
    _cachedSourceLength = length;
    _cachedSourceFirstId = firstId;
    _cachedSourceLastId = lastId;
    _cachedQuery = q;
    _cachedBlocoFilter = _blocoFilter;
    _cachedEstadoFilter = _estadoFilter;
    _filteredCache = filtered;

    return filtered;
  }

  void _invalidateFilteredCache() {
    _filteredCache = null;
  }
  
  void _showFilterModal(BuildContext context, List<String> blocos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterModal(
        blocos: blocos,
        blocoAtual: _blocoFilter,
        estadoAtual: _estadoFilter,
        onApply: (bloco, estado) {
          setState(() {
            _blocoFilter = bloco;
            _estadoFilter = estado;
            _invalidateFilteredCache();
          });
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  /// FAB só para Admin/Síndico - podem criar apartamentos
  Widget? _buildFabIfAllowed() {
    final userType = context.watch<AuthProvider>().usuarioAtual?.tipo;
    if (userType == UsuarioTipo.Administrador || userType == UsuarioTipo.Sindico) {
      return FloatingActionButton(
        heroTag: 'apartments_fab',
        onPressed: () => Navigator.pushNamed(context, '/apartamentos-novo'),
        backgroundColor: OwanyTheme.primaryOrange,
        child: const Icon(Icons.add_rounded, color: OwanyTheme.white),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (_, value, __) => _GlassAppBar(
            scrollOffset: value,
            onSearch: () {},
          ),
        ),
      ),
      body: Consumer<ApartamentosProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return _PremiumSkeletonLoader();
          }
          if (provider.errorMessage != null) {
            return _ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.carregarApartamentos,
            );
          }
          final apartamentos = provider.apartamentos;
          if (apartamentos.isEmpty) {
            return EmptyApartamentos(
              onAddNew: () => Navigator.pushNamed(context, '/apartamentos-novo'),
            );
          }
          final total = apartamentos.length;
          final ocupados = apartamentos.where((a) => a.estado == EstadoApartamento.Ocupado).length;
          final disponiveis = apartamentos.where((a) => a.estado == EstadoApartamento.Disponivel).length;
          
          // Calcula apartamentos em manutenção baseado nas solicitações em andamento/analise
          // (solução temporária até o backend atualizar o campo emManutencao automaticamente)
          final solicitacoesProvider = context.watch<SolicitacoesProvider>();
          final solicitacoesAtivas = solicitacoesProvider.solicitacoes
              .where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise')
              .toList();
          
          // Contar apartamentos únicos com solicitações em andamento
          final aptosComManutencao = <String>{};
          for (final sol in solicitacoesAtivas) {
            aptosComManutencao.add('${sol.blocoApartamento}-${sol.numeroApartamento}');
          }
          final manutencao = aptosComManutencao.length;
          final totalMoradores = apartamentos.fold<int>(0, (sum, a) => sum + a.quantidadeMoradores);
          final mediaMoradores = total > 0 ? totalMoradores / total : 0.0;
          final taxaOcupacao = total > 0 ? (ocupados / total) * 100 : 0.0;
          final blocos = <String>{...apartamentos.map((e) => e.bloco.toLowerCase())}.toList()..sort();
          final filtrados = _filtrar(apartamentos);
          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _carregarDadosComPermissao(forceRefresh: true);
            },
            color: OwanyTheme.primaryOrange,
            backgroundColor: OwanyTheme.cardColor(context),
            strokeWidth: 3,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 140)),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _PremiumDashboard(
                          total: total,
                          ocupados: ocupados,
                          disponiveis: disponiveis,
                          manutencao: manutencao,
                          totalMoradores: totalMoradores,
                          mediaMoradores: mediaMoradores,
                          taxaOcupacao: taxaOcupacao,
                          showExtended: _showExtendedStats,
                          onToggleExtended: () {
                            setState(() => _showExtendedStats = !_showExtendedStats);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PremiumSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      isGrid: _isGridView,
                      onToggleView: () {
                        setState(() => _isGridView = !_isGridView);
                        HapticFeedback.selectionClick();
                      },
                      onFilterTap: () => _showFilterModal(context, blocos),
                      hasActiveFilters: _blocoFilter != 'todos' || _estadoFilter != null,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_blocoFilter != 'todos' || _estadoFilter != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ActiveFiltersRow(
                        bloco: _blocoFilter,
                        estado: _estadoFilter,
                        onClearBloco: () {
                          setState(() => _blocoFilter = 'todos');
                          HapticFeedback.lightImpact();
                        },
                        onClearEstado: () {
                          setState(() => _estadoFilter = null);
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          '${filtrados.length} ${filtrados.length == 1 ? AppLocalizations.of(context)!.apartment : AppLocalizations.of(context)!.apartments_list_title}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: OwanyTheme.textMutedColor(context),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        if (_searchController.text.isNotEmpty || _blocoFilter != 'todos' || _estadoFilter != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _blocoFilter = 'todos';
                                _estadoFilter = null;
                              });
                              HapticFeedback.mediumImpact();
                            },
                            icon: Icon(Icons.clear_all, size: 18),
                            label: Text(AppLocalizations.of(context)!.apartments_clear_all),
                            style: TextButton.styleFrom(foregroundColor: OwanyTheme.primaryOrange),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (filtrados.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: AppLocalizations.of(context)!.apartments_no_results,
                        subtitle: AppLocalizations.of(context)!.apartments_no_results_subtitle,
                        actionLabel: AppLocalizations.of(context)!.apartments_add_new,
                        onAction: () => Navigator.pushNamed(context, '/apartamentos-novo'),
                      ),
                    ),
                  )
                else if (_isGridView)
                  _buildAnimatedGrid(filtrados, aptosComManutencao)
                else
                  _buildAnimatedList(filtrados, aptosComManutencao),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      // FAB só para Admin/Síndico - podem criar apartamentos
      floatingActionButton: _buildFabIfAllowed(),
    );
  }
  
  Widget _buildAnimatedGrid(List<Apartamento> apartamentos, Set<String> aptosEmManutencao) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final apt = apartamentos[index];
            final emManutencaoAtiva = apt.emManutencao || 
                aptosEmManutencao.contains('${apt.bloco}-${apt.numero}');
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: clamped,
                    child: child,
                  ),
                );
              },
              child: _PremiumApartmentCard(
                apartamento: apt,
                color: _estadoColor(apt.estado),
                index: index,
                emManutencaoAtiva: emManutencaoAtiva,
              ),
            );
          },
          childCount: apartamentos.length,
        ),
      ),
    );
  }
  
  Widget _buildAnimatedList(List<Apartamento> apartamentos, Set<String> aptosEmManutencao) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final apt = apartamentos[index];
            final emManutencaoAtiva = apt.emManutencao || 
                aptosEmManutencao.contains('${apt.bloco}-${apt.numero}');
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + (index * 30)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: clamped,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PremiumApartmentListTile(
                  apartamento: apt,
                  color: _estadoColor(apt.estado),
                  emManutencaoAtiva: emManutencaoAtiva,
                ),
              ),
            );
          },
          childCount: apartamentos.length,
        ),
      ),
    );
  }
}

// =============================================================
// GLASS MORPHISM APP BAR
// =============================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final VoidCallback onSearch;

  const _GlassAppBar({required this.scrollOffset, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);
    
    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange.withValues(alpha: 0.8 + (opacity * 0.2)),
                OwanyTheme.accent.withValues(alpha: 0.7 + (opacity * 0.3)),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.apartments_list_title,
                            style: TextStyle(
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.apartments_complete_management,
                            style: TextStyle(
                              color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM DASHBOARD WITH EXTENDED STATS
// =============================================================

class _PremiumDashboard extends StatelessWidget {
  final int total;
  final int ocupados;
  final int disponiveis;
  final int manutencao;
  final int totalMoradores;
  final double mediaMoradores;
  final double taxaOcupacao;
  final bool showExtended;
  final VoidCallback onToggleExtended;

  const _PremiumDashboard({
    required this.total,
    required this.ocupados,
    required this.disponiveis,
    required this.manutencao,
    required this.totalMoradores,
    required this.mediaMoradores,
    required this.taxaOcupacao,
    required this.showExtended,
    required this.onToggleExtended,
  });

  double _pct(int v) => total == 0 ? 0 : v / total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange,
                OwanyTheme.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      OwanyTheme.adaptiveOverlay(context, opacity: 0.1),
                      OwanyTheme.adaptiveOverlay(context, opacity: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Main Stats Row (wrap on narrow screens to avoid overflow)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 360;
                        final stats = [
                          _AnimatedCircularStat(
                            label: AppLocalizations.of(context)!.apartments_list_occupied,
                            value: ocupados,
                            percent: _pct(ocupados),
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            delay: 0,
                          ),
                          _AnimatedCircularStat(
                            label: AppLocalizations.of(context)!.apartments_list_available,
                            value: disponiveis,
                            percent: _pct(disponiveis),
                            color: OwanyTheme.success,
                            delay: 100,
                          ),
                          _AnimatedCircularStat(
                            label: AppLocalizations.of(context)!.apartments_list_maintenance,
                            value: manutencao,
                            percent: _pct(manutencao),
                            color: OwanyTheme.warning,
                            delay: 200,
                          ),
                        ];
                        if (isNarrow) {
                          return Wrap(
                            alignment: WrapAlignment.spaceAround,
                            spacing: 16,
                            runSpacing: 16,
                            children: stats,
                          );
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: stats,
                        );
                      },
                    ),
                    
                    if (showExtended) ...[
                      SizedBox(height: 24),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Extended Stats
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.groups_rounded,
                              label: AppLocalizations.of(context)!.apartments_total_residents,
                              value: totalMoradores.toString(),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.person_outline_rounded,
                              label: AppLocalizations.of(context)!.apartments_avg_per_apt,
                              value: mediaMoradores.toStringAsFixed(1),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _TaxaOcupacaoBar(percent: taxaOcupacao),
                    ],
                    
                    SizedBox(height: 16),
                    
                    // Toggle Button
                    InkWell(
                      onTap: onToggleExtended,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              showExtended ? AppLocalizations.of(context)!.apartments_see_less : AppLocalizations.of(context)!.apartments_see_more_stats,
                              style: TextStyle(
                                color: OwanyTheme.adaptiveTextOverlay(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              showExtended 
                                  ? Icons.expand_less 
                                  : Icons.expand_more,
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedCircularStat extends StatefulWidget {
  final String label;
  final int value;
  final double percent;
  final Color color;
  final int delay;

  const _AnimatedCircularStat({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.delay,
  });

  @override
  State<_AnimatedCircularStat> createState() => _AnimatedCircularStatState();
}

class _AnimatedCircularStatState extends State<_AnimatedCircularStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CirclePainter(
                  percent: widget.percent * _animation.value,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    '${(widget.percent * 100 * _animation.value).round()}%',
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          '${widget.value}',
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percent;
  final Color color;

  _CirclePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final bg = Paint()
      ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaxaOcupacaoBar extends StatelessWidget {
  final double percent;

  const _TaxaOcupacaoBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.apartments_occupancy_rate,
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: percent / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: OwanyTheme.textPrimary(context).withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    OwanyTheme.textPrimary(context),
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM SEARCH BAR
// =============================================================

class _PremiumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isGrid;
  final VoidCallback onToggleView;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const _PremiumSearchBar({
    required this.controller,
    required this.onChanged,
    required this.isGrid,
    required this.onToggleView,
    required this.onFilterTap,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.apartments_search_hint,
                hintStyle: TextStyle(
                  color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // View Toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleView,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: 20,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Filter Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasActiveFilters
                      ? OwanyTheme.primaryOrange
                      : OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilters
                      ? OwanyTheme.adaptiveTextOverlay(context)
                      : OwanyTheme.primaryOrange,
                  size: 20,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

// =============================================================
// ACTIVE FILTERS ROW
// =============================================================

class _ActiveFiltersRow extends StatelessWidget {
  final String bloco;
  final EstadoApartamento? estado;
  final VoidCallback onClearBloco;
  final VoidCallback onClearEstado;

  const _ActiveFiltersRow({
    required this.bloco,
    required this.estado,
    required this.onClearBloco,
    required this.onClearEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (bloco != 'todos')
          _FilterChipActive(
            label: AppLocalizations.of(context)!.apartments_block_label(bloco.toUpperCase()),
            onRemove: onClearBloco,
          ),
        if (estado != null)
          _FilterChipActive(
            label: estado!.toPortuguese(),
            onRemove: onClearEstado,
          ),
      ],
    );
  }
}

class _FilterChipActive extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipActive({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: OwanyTheme.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: OwanyTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM APARTMENT CARD (GRID)
// =============================================================

class _PremiumApartmentCard extends StatefulWidget {
  final Apartamento apartamento;
  final Color color;
  final int index;
  final bool emManutencaoAtiva;

  const _PremiumApartmentCard({
    required this.apartamento,
    required this.color,
    required this.index,
    this.emManutencaoAtiva = false,
  });

  @override
  State<_PremiumApartmentCard> createState() => _PremiumApartmentCardState();
}

class _PremiumApartmentCardState extends State<_PremiumApartmentCard> {
  bool _isHovered = false;

  /// Constroi badge de moradores — mostra nomes se ocupado, senão mostra contagem
  Widget _buildMoradoresBadgeCard(BuildContext context) {
    final apt = widget.apartamento;
    final isOcupado = apt.estado == EstadoApartamento.Ocupado;
    final temMoradores = apt.moradores != null && apt.moradores!.isNotEmpty;

    if (isOcupado && temMoradores) {
      final nomes = apt.moradores!
          .map((m) => m.nome.split(' ').first)
          .take(2)
          .join(', ');
      final extra = apt.moradores!.length > 2
          ? ' +${apt.moradores!.length - 2}'
          : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 14, color: OwanyTheme.primaryOrange),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                '$nomes$extra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: OwanyTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: contagem numérica
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_rounded, size: 14, color: OwanyTheme.primaryOrange),
          SizedBox(width: 4),
          Text(
            '${apt.quantidadeMoradores}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: OwanyTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            '/apartamentos-detalhe',
            arguments: widget.apartamento.id,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.03 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.cardColor(context),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.5)
                    : OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.3)
                      : OwanyTheme.textMutedColor(context).withValues(alpha: 0.05),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.05,
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 100,
                        color: widget.color,
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.color,
                                    widget.color.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.color.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.apartamento.estado.toPortuguese(),
                                style: TextStyle(
                                  color: OwanyTheme.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (widget.emManutencaoAtiva) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: OwanyTheme.warning,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.construction_rounded,
                                  size: 12,
                                  color: OwanyTheme.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Apartment Number
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.apartamento.numero,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: widget.color,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        // Name
                        Text(
                          widget.apartamento.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: OwanyTheme.textPrimary(context),
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                        // Bloco
                        Text(
                          AppLocalizations.of(context)!.apartments_block_label(widget.apartamento.bloco),
                          style: TextStyle(
                            color: OwanyTheme.textMutedColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Moradores — mostra nomes para ocupados
                        _buildMoradoresBadgeCard(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM APARTMENT LIST TILE
// =============================================================

class _PremiumApartmentListTile extends StatelessWidget {
  final Apartamento apartamento;
  final Color color;
  final bool emManutencaoAtiva;

  const _PremiumApartmentListTile({
    required this.apartamento,
    required this.color,
    this.emManutencaoAtiva = false,
  });

  /// Constroi badge de moradores — mostra nomes se ocupado, senão mostra contagem
  Widget _buildMoradoresBadgeList(BuildContext context) {
    final isOcupado = apartamento.estado == EstadoApartamento.Ocupado;
    final temMoradores = apartamento.moradores != null && apartamento.moradores!.isNotEmpty;

    if (isOcupado && temMoradores) {
      final nomes = apartamento.moradores!
          .map((m) => m.nome.split(' ').first)
          .take(3)
          .join(', ');
      final extra = apartamento.moradores!.length > 3
          ? ' +${apartamento.moradores!.length - 3}'
          : '';
      return Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.person_rounded, size: 18, color: OwanyTheme.primaryOrange),
            SizedBox(height: 4),
            Text(
              '$nomes$extra',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: OwanyTheme.primaryOrange,
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: contagem numérica
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.people_rounded, size: 20, color: OwanyTheme.primaryOrange),
          SizedBox(height: 4),
          Text(
            '${apartamento.quantidadeMoradores}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: OwanyTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            '/apartamentos-detalhe',
            arguments: apartamento.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Number Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    apartamento.numero,
                    style: TextStyle(
                      color: OwanyTheme.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apartamento.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            apartamento.estado.toPortuguese(),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (emManutencaoAtiva)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: OwanyTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.construction_rounded,
                                  size: 10,
                                  color: OwanyTheme.warning,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.apartments_list_maintenance,
                                  style: TextStyle(
                                    color: OwanyTheme.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          AppLocalizations.of(context)!.apartments_block_label(apartamento.bloco),
                          style: TextStyle(
                            color: OwanyTheme.textMutedColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Moradores Badge — mostra nomes para ocupados
              _buildMoradoresBadgeList(context),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ADVANCED FILTER MODAL
// =============================================================

class _AdvancedFilterModal extends StatefulWidget {
  final List<String> blocos;
  final String blocoAtual;
  final EstadoApartamento? estadoAtual;
  final Function(String bloco, EstadoApartamento? estado) onApply;

  const _AdvancedFilterModal({
    required this.blocos,
    required this.blocoAtual,
    required this.estadoAtual,
    required this.onApply,
  });

  @override
  State<_AdvancedFilterModal> createState() => _AdvancedFilterModalState();
}

class _AdvancedFilterModalState extends State<_AdvancedFilterModal> {
  late String _selectedBloco;
  late EstadoApartamento? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _selectedBloco = widget.blocoAtual;
    _selectedEstado = widget.estadoAtual;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: OwanyTheme.primaryOrange,
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.apartments_advanced_filters,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Blocos Section
                  Text(
                    AppLocalizations.of(context)!.apartments_block,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterOptionChip(
                        label: AppLocalizations.of(context)!.common_all,
                        isSelected: _selectedBloco == 'todos',
                        onTap: () {
                          setState(() => _selectedBloco = 'todos');
                          HapticFeedback.selectionClick();
                        },
                      ),
                      ...widget.blocos.map(
                        (b) => _FilterOptionChip(
                          label: AppLocalizations.of(context)!.apartments_block_label(b.toUpperCase()),
                          isSelected: _selectedBloco == b,
                          onTap: () {
                            setState(() => _selectedBloco = b);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Estado Section
                  Text(
                    AppLocalizations.of(context)!.common_status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterOptionChip(
                        label: AppLocalizations.of(context)!.common_all,
                        isSelected: _selectedEstado == null,
                        onTap: () {
                          setState(() => _selectedEstado = null);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: AppLocalizations.of(context)!.apartments_list_available,
                        icon: Icons.check_circle_outline,
                        color: OwanyTheme.success,
                        isSelected: _selectedEstado == EstadoApartamento.Disponivel,
                        onTap: () {
                          setState(() => _selectedEstado = EstadoApartamento.Disponivel);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: AppLocalizations.of(context)!.apartments_list_occupied,
                        icon: Icons.home,
                        color: OwanyTheme.primaryOrange,
                        isSelected: _selectedEstado == EstadoApartamento.Ocupado,
                        onTap: () {
                          setState(() => _selectedEstado = EstadoApartamento.Ocupado);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: AppLocalizations.of(context)!.apartments_list_maintenance,
                        icon: Icons.build,
                        color: OwanyTheme.warning,
                        isSelected: _selectedEstado == EstadoApartamento.EmManutencao,
                        onTap: () {
                          setState(() => _selectedEstado = EstadoApartamento.EmManutencao);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBloco = 'todos';
                              _selectedEstado = null;
                            });
                            HapticFeedback.lightImpact();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.apartments_clear,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(_selectedBloco, _selectedEstado);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OwanyTheme.primaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.apartments_apply_filters,
                            style: TextStyle(
                              color: OwanyTheme.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OwanyTheme.primaryOrange;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [chipColor, chipColor.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected ? null : OwanyTheme.textMutedColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? chipColor : OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? OwanyTheme.white : chipColor,
                ),
                SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? OwanyTheme.white : OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// (local FAB removed) The app should use a single global FAB from `main.dart`.

// =============================================================
// PREMIUM SKELETON LOADER
// =============================================================

class _PremiumSkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 140),
          
          // Dashboard Skeleton
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Search Skeleton
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Grid Skeletons
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: 6,
            itemBuilder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ERROR STATE
// =============================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final offline = NetworkErrorHelper.isServerOffline(message);
    final title = offline
        ? NetworkErrorHelper.offlineTitle()
        : AppLocalizations.of(context)!.apartments_error_title;
    final detail = offline ? NetworkErrorHelper.offlineMessage() : message;
    final icon = offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded;
    final accent = offline ? OwanyTheme.warning : OwanyTheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: accent,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: OwanyTheme.textMutedColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: OwanyTheme.white),
              label: Text(
                AppLocalizations.of(context)!.common_retry,
                style: TextStyle(
                  color: OwanyTheme.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



















