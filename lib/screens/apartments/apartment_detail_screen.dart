import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../generated_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/maintenance_list_screen_com_filtro.dart';
import '../../theme/owany_theme.dart';
import '../../providers/apartamentos_provider.dart';
import '../../dto/api_dtos.dart';
import '../../models/enums.dart';
import '../../models/item_estado.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/vincular_morador_dialog.dart';
import '../../providers/moradores_provider.dart';
import '../../providers/historico_ocupacao_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import 'historico_ocupacao_detalhado_screen.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';
// =====================================================================
// ðŸ¢ APARTMENT DETAIL SCREEN â€” MOBILE-FIRST OPTIMIZED VERSION
// =====================================================================
// Improvements:
// ❌¨ Mobile-first responsive design
// âš¡ Performance optimizations (reduced animations)
// ðŸ“± Better touch targets (min 48x48)
// ðŸŽ¯ Simplified navigation for mobile
// ðŸ’¾ Lazy loading for better performance
// ðŸ”„ Pull-to-refresh gesture
// ðŸ“Š Condensed info cards for mobile
// ðŸŽ¨ Adaptive layouts based on screen size
// =====================================================================

class ApartmentDetailScreen extends StatefulWidget {
  final String apartamentoId;

  const ApartmentDetailScreen({required this.apartamentoId, super.key});

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen>
    with TickerProviderStateMixin {
  // =====================================================================
  // OPTIMIZED ANIMATION CONTROLLERS (reduced from 8 to 3)
  // =====================================================================
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _fabController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _headerOpacity;
  late Animation<double> _fabScale;

  // =====================================================================
  // STATE MANAGEMENT
  // =====================================================================
  final Map<String, Future<List<SolicitacaoV2Resumo>>>
  _solicitacoesApartamentoCache = {};

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Fade animation (600ms - reduced)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Header animation (800ms - reduced)
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );

    // FAB animation (300ms - reduced)
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeOut));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() {
      if (mounted) {
        context.read<ApartamentosProvider>().carregarApartamento(
          widget.apartamentoId,
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =====================================================================
  // PULL TO REFRESH
  // =====================================================================
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      await context.read<ApartamentosProvider>().carregarApartamento(
        widget.apartamentoId,
      );
      if (mounted) {
        _showFeedback(
          AppLocalizations.of(context)!.apartments_data_updated,
          SnackBarType.success,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // =====================================================================
  // DATA LOADING METHODS
  // =====================================================================

  Future<List<SolicitacaoV2Resumo>> _getSolicitacoesApartamento(
    String apartamentoId,
  ) {
    return _solicitacoesApartamentoCache.putIfAbsent(apartamentoId, () async {
      try {
        // Usa endpoint dedicado com filtro role-based no backend:
        // Morador: vê só as que criou
        // Funcionário: vê as que criou ou é responsável
        // Admin/Síndico: vê todas do apartamento
        final items = await ApiService().request<List<SolicitacaoV2Resumo>>(
          'apartamentos/$apartamentoId/solicitacoes',
          method: 'GET',
          fromJson: (json) {
            if (json is List) {
              return json
                  .map(
                    (item) => SolicitacaoV2Resumo.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
            }
            return [];
          },
        );
        return items;
      } catch (e) {
        AppLogger.error(
          'ApartmentDetailScreen',
          'Erro ao carregar solicitações: $e',
        );
        return [];
      }
    });
  }

  // =====================================================================
  // BUILD METHOD â€” MOBILE-FIRST OPTIMIZED
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userType = auth.usuarioAtual?.tipo;
    // Editar/criar apartamento = Admin + Síndico (backend: Administrador,Sindico)
    final canEdit =
        userType == UsuarioTipo.Administrador ||
        userType == UsuarioTipo.Sindico;
    // canManage = pode editar apartamento (para FAB/ações)
    final canManage = canEdit;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: Consumer<ApartamentosProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildOptimizedSkeleton();
          }

          if (provider.apartamentos.isEmpty &&
              provider.apartamentoAtual == null) {
            return _buildEmptyState();
          }

          final apartamento =
              provider.apartamentoAtual != null &&
                  provider.apartamentoAtual!.id == widget.apartamentoId
              ? provider.apartamentoAtual!
              : provider.apartamentos.firstWhere(
                  (a) => a.id == widget.apartamentoId,
                  orElse: () => provider.apartamentos.first,
                );

          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= 600;

          return Stack(
            children: [
              // ===== MAIN CONTENT WITH REFRESH =====
              RefreshIndicator(
                onRefresh: _handleRefresh,
                color: OwanyTheme.primaryOrange,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Compact AppBar
                    _buildCompactAppBar(apartamento, canManage, provider),

                    // Content
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero Header (compact)
                              _buildCompactHeroHeader(apartamento),

                              const SizedBox(height: 20),

                              // Quick Stats Grid
                              _buildQuickStatsGrid(apartamento),

                              const SizedBox(height: 20),

                              // Quick Actions
                              _buildQuickActionsGrid(
                                apartamento,
                                canManage,
                                isTablet,
                              ),

                              const SizedBox(height: 24),

                              // Info Section (collapsible on mobile)
                              _buildInfoSection(apartamento, isTablet),

                              const SizedBox(height: 20),

                              // Residents Section
                              _buildResidentsSection(apartamento),

                              const SizedBox(height: 20),

                              // Items Section
                              _buildItemsSection(apartamento),

                              const SizedBox(height: 20),

                              // Item Movement History Section (Admin, Sindico, Funcionario only)
                              if ((apartamento.itens?.isNotEmpty ?? false) &&
                                  userType != UsuarioTipo.Morador &&
                                  userType != UsuarioTipo.Visitante)
                                _buildItemMovementHistorySection(apartamento),

                              if ((apartamento.itens?.isNotEmpty ?? false) &&
                                  userType != UsuarioTipo.Morador &&
                                  userType != UsuarioTipo.Visitante)
                                const SizedBox(height: 20),

                              // History Section (Solicitações - visible to all users)
                              _buildHistorySection(apartamento),

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== FLOATING ACTION BUTTON =====
              if (canManage) _buildOptimizedFAB(context, apartamento),
            ],
          );
        },
      ),
    );
  }

  // =====================================================================
  // COMPACT APP BAR (Mobile Optimized)
  // =====================================================================

  Widget _buildCompactAppBar(
    Apartamento apartamento,
    bool canManage,
    ApartamentosProvider provider,
  ) {
    final isScrolled = _scrollOffset > 20;

    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: isScrolled
          ? OwanyTheme.primaryOrange
          : OwanyTheme.primaryOrange.withValues(alpha: 0.9),
      elevation: isScrolled ? 4 : 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: OwanyTheme.adaptiveTextOverlay(context),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isScrolled ? 1.0 : 0.0,
        child: Text(
          apartamento.nome,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        if (canManage)
          IconButton(
            icon: Icon(
              Icons.edit_rounded,
              color: OwanyTheme.adaptiveTextOverlay(context),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                '/apartamentos-editar',
                arguments: apartamento.id,
              );
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange,
                OwanyTheme.primaryOrange.withValues(alpha: 0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
          alignment: Alignment.bottomLeft,
          child: FadeTransition(
            opacity: _headerOpacity,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isScrolled ? 0.0 : 1.0,
              child: Text(
                apartamento.numero,
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // COMPACT HERO HEADER
  // =====================================================================

  Widget _buildCompactHeroHeader(Apartamento apartamento) {
    return Hero(
      tag: 'apt-${apartamento.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.cardColor(context),
                OwanyTheme.cardColor(context).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apartamento.nome,
                          style: TextStyle(
                            color: OwanyTheme.textPrimary(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusBadge(apartamento.estado),
                            if (apartamento.emManutencao) ...[
                              const SizedBox(width: 8),
                              _buildMaintenanceBadge(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OwanyTheme.primaryOrange,
                          OwanyTheme.primaryOrange.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      apartamento.numero,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.apartments_block_floor_display(
                      apartamento.bloco,
                      apartamento.andar,
                    ),
                    style: TextStyle(
                      color: OwanyTheme.textMutedColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // QUICK STATS GRID (Mobile Optimized)
  // =====================================================================

  Widget _buildQuickStatsGrid(Apartamento apartamento) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_rounded,
            label: AppLocalizations.of(context)!.common_residents,
            value: '${apartamento.quantidadeMoradores}',
            color: OwanyTheme.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_rounded,
            label: AppLocalizations.of(context)!.apartments_items,
            value: '${apartamento.itens?.length ?? 0}',
            color: OwanyTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: _getEstadoIcon(apartamento.estado),
            label: 'Status',
            value: _getEstadoShort(apartamento.estado),
            color: _getEstadoColor(apartamento.estado),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // QUICK ACTIONS GRID
  // =====================================================================

  Widget _buildQuickActionsGrid(
    Apartamento apartamento,
    bool canManage,
    bool isTablet,
  ) {
    final actions = _buildActionsList(apartamento, canManage);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionCard(_ActionData action) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              action.color.withValues(alpha: 0.1),
              action.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 32),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: OwanyTheme.textPrimary(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // INFO SECTION (Expandable)
  // =====================================================================

  Widget _buildInfoSection(Apartamento apartamento, bool isTablet) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      initiallyExpanded: isTablet,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: OwanyTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.apartments_detailed_info,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      children: [
        _buildInfoRow(
          Icons.numbers_rounded,
          AppLocalizations.of(context)!.apartments_number,
          apartamento.numero,
        ),
        _buildInfoRow(
          Icons.apartment_rounded,
          AppLocalizations.of(context)!.apartments_block,
          apartamento.bloco,
        ),
        _buildInfoRow(
          Icons.layers_rounded,
          AppLocalizations.of(context)!.apartments_floor,
          '${apartamento.andar}º',
        ),
        _buildInfoRow(
          Icons.toggle_on_rounded,
          AppLocalizations.of(context)!.apartments_state,
          apartamento.estado.toPortuguese(),
        ),
        if (apartamento.descricao?.isNotEmpty ?? false) ...[
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwanyTheme.softOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: OwanyTheme.textMutedColor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    apartamento.descricao!,
                    style: TextStyle(
                      fontSize: 13,
                      color: OwanyTheme.textMutedColor(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: OwanyTheme.primaryOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: OwanyTheme.textPrimary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // RESIDENTS SECTION (Simplified)
  // =====================================================================

  Widget _buildResidentsSection(Apartamento apartamento) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OwanyTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: OwanyTheme.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.common_residents,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: OwanyTheme.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${apartamento.quantidadeMoradores}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: OwanyTheme.info,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // History button only for Admin, Sindico, Funcionario
                if (context.read<AuthProvider>().usuarioAtual?.tipo !=
                        UsuarioTipo.Morador &&
                    context.read<AuthProvider>().usuarioAtual?.tipo !=
                        UsuarioTipo.Visitante)
                  IconButton(
                    icon: const Icon(Icons.history_rounded, size: 20),
                    color: OwanyTheme.primaryOrange,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoricoOcupacaoDetalhadoScreen(
                            apartamentoId: apartamento.id,
                            titulo:
                                '${apartamento.numero}/${apartamento.bloco}',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (apartamento.moradores?.isEmpty ?? true)
            _buildEmptyResidentsState()
          else
            ...apartamento.moradores!.map((morador) {
              return _buildResidentTile(morador, apartamento);
            }),
        ],
      ),
    );
  }

  Widget _buildResidentTile(Morador morador, Apartamento apartamento) {
    final nomeExibicao = morador.nome.trim().isNotEmpty
        ? morador.nome.trim()
        : (morador.nomeUsuario?.trim().isNotEmpty ?? false)
        ? morador.nomeUsuario!.trim()
        : AppLocalizations.of(context)!.common_resident;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: OwanyTheme.info,
        child: Text(
          (nomeExibicao.isNotEmpty) ? nomeExibicao[0].toUpperCase() : '?',
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        nomeExibicao,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: OwanyTheme.textPrimary(context),
        ),
      ),
      subtitle: morador.usuarioId != null
          ? Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: OwanyTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: OwanyTheme.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.apartments_linked,
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onSelected: (value) {
          HapticFeedback.lightImpact();
          if (value == 'trocar') {
            _trocarMorador(morador, apartamento);
          }
          if (value == 'disponibilizar') {
            _desvincularMorador(morador, apartamento);
          }
          if (value == 'registrar_saida') {
            _registrarSaidaDireto(morador, apartamento);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'trocar',
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 18),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.apartments_swap),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'registrar_saida',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 18),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.apartments_register_exit),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'disponibilizar',
            child: Row(
              children: [
                Icon(Icons.person_remove_rounded, size: 18),
                SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.apartments_make_available),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResidentsState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.apartments_no_residents,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ITEMS SECTION (Simplified)
  // =====================================================================

  Widget _buildItemsSection(Apartamento apartamento) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OwanyTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: OwanyTheme.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.apartments_items,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: OwanyTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${apartamento.itens?.length ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: OwanyTheme.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ...existing code...
              ],
            ),
          ),
          if (apartamento.itens?.isEmpty ?? true)
            _buildEmptyItemsState()
          else
            ...apartamento.itens!.map((item) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _corEstadoItem(
                      item.status ?? 'Disponivel',
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: _corEstadoItem(item.status ?? 'Disponivel'),
                    size: 20,
                  ),
                ),
                title: Text(
                  item.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.descricao?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.descricao!,
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (item.ultimaMovimentacao != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Movido: ${_formatarDataCurta(item.ultimaMovimentacao!)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: OwanyTheme.textMutedColor(
                              context,
                            ).withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.apartments_no_items,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // ITEM MOVEMENT HISTORY SECTION
  // =====================================================================

  Widget _buildItemMovementHistorySection(Apartamento apartamento) {
    final itemsComMovimentacao =
        apartamento.itens
            ?.where((item) => item.ultimaMovimentacao != null)
            .toList() ??
        [];

    if (itemsComMovimentacao.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OwanyTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.move_up_rounded,
                    color: OwanyTheme.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Histórico de Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (itemsComMovimentacao.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/historico-itens');
                    },
                    child: Text(AppLocalizations.of(context)!.common_view_all),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: itemsComMovimentacao
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: OwanyTheme.backgroundColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: OwanyTheme.textPrimary(
                              context,
                            ).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (item.codigoIdentificador?.isNotEmpty ??
                                      false)
                                    Text(
                                      'Cód: ${item.codigoIdentificador}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: OwanyTheme.primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatarDataCurta(
                                      item.ultimaMovimentacao!,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: OwanyTheme.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _corEstadoItem(
                                  item.status ?? 'Disponivel',
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                estadoToUiLabel(
                                  estadoFromString(item.status ?? 'Disponivel'),
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _corEstadoItem(
                                    item.status ?? 'Disponivel',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // HISTORY SECTION (Simplified)
  // =====================================================================

  Widget _buildHistorySection(Apartamento apartamento) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<List<SolicitacaoV2Resumo>>(
        future: _getSolicitacoesApartamento(apartamento.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final solicitacoes = snapshot.data ?? [];
          final total = solicitacoes.length;
          final concluidas = solicitacoes
              .where((s) => s.status == 'Concluido')
              .length;
          final pendentes = solicitacoes
              .where((s) => s.status == 'Pendente')
              .length;
          final emAndamento = solicitacoes
              .where((s) => s.status == 'EmAndamento')
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: OwanyTheme.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.history_title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (total > 0)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MaintenanceListScreenComFiltroApartamento(
                                    apartamentoId: apartamento.id,
                                  ),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.dashboard_view_all,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHistoryStatMini(
                        AppLocalizations.of(context)!.common_total,
                        total.toString(),
                        OwanyTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHistoryStatMini(
                        AppLocalizations.of(
                          context,
                        )!.maintenance_list_in_progress,
                        emAndamento.toString(),
                        OwanyTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHistoryStatMini(
                        AppLocalizations.of(context)!.maintenance_list_pending,
                        pendentes.toString(),
                        OwanyTheme.info,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildHistoryStatMini(
                        AppLocalizations.of(
                          context,
                        )!.maintenance_list_completed,
                        concluidas.toString(),
                        OwanyTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryStatMini(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // OPTIMIZED FAB (Simplified) - Only shown when canManage is true
  // =====================================================================

  Widget _buildOptimizedFAB(BuildContext context, Apartamento apartamento) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showActionBottomSheet(context, apartamento);
          },
          backgroundColor: OwanyTheme.primaryOrange,
          icon: Icon(
            Icons.more_horiz_rounded,
            color: OwanyTheme.adaptiveTextOverlay(context),
          ),
          label: Text(
            AppLocalizations.of(context)!.common_actions,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context, Apartamento apartamento) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: OwanyTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: OwanyTheme.info),
                title: Text(AppLocalizations.of(context)!.apartments_edit),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/apartamentos-editar',
                    arguments: apartamento.id,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  apartamento.estado == EstadoApartamento.EmManutencao
                      ? Icons.check_circle_rounded
                      : Icons.home_repair_service_rounded,
                  color: apartamento.estado == EstadoApartamento.EmManutencao
                      ? OwanyTheme.success
                      : OwanyTheme.warning,
                ),
                title: Text(
                  apartamento.estado == EstadoApartamento.EmManutencao
                      ? AppLocalizations.of(context)!.apartments_mark_available
                      : AppLocalizations.of(
                          context,
                        )!.apartments_mark_maintenance,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleEstado(apartamento);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // =====================================================================
  // STATUS BADGE
  // =====================================================================

  Widget _buildStatusBadge(EstadoApartamento estado) {
    final color = _getEstadoColor(estado);
    final icon = _getEstadoIcon(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            estado.toPortuguese(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de manutenção automática (baseado em solicitações em andamento)
  Widget _buildMaintenanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OwanyTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 14, color: OwanyTheme.warning),
          const SizedBox(width: 6),
          Text(
            'Em Manutenção',
            style: TextStyle(
              color: OwanyTheme.warning,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // OPTIMIZED SKELETON
  // =====================================================================

  Widget _buildOptimizedSkeleton() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          backgroundColor: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSkeletonBox(height: 120),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSkeletonBox(height: 100)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonBox(height: 100)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSkeletonBox(height: 100)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSkeletonBox(height: 200),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // =====================================================================
  // EMPTY STATE
  // =====================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment_rounded,
            size: 80,
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.apartments_not_found,
            style: TextStyle(
              fontSize: 18,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton.primary(
            text: AppLocalizations.of(context)!.action_back,
            onPressed: () => Navigator.pop(context),
            icon: Icons.arrow_back_rounded,
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // HELPER METHODS
  // =====================================================================

  List<_ActionData> _buildActionsList(Apartamento apartamento, bool canManage) {
    final actions = <_ActionData>[];

    if (canManage) {
      actions.add(
        _ActionData(
          icon: Icons.inventory_2_rounded,
          label: AppLocalizations.of(context)!.apartments_manage_items,
          subtitle: AppLocalizations.of(context)!.apartments_add_or_remove,
          color: OwanyTheme.warning,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/apartamentos-itens',
              arguments: {'id': apartamento.id, 'nome': apartamento.nome},
            );
          },
        ),
      );
    }

    if (canManage) {
      actions.add(
        _ActionData(
          icon: Icons.person_add_alt_1_rounded,
          label: AppLocalizations.of(context)!.apartments_assign_resident,
          subtitle: AppLocalizations.of(context)!.apartments_link_resident,
          color: OwanyTheme.success,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => VincularMoradorDialog(
                apartamentoId: apartamento.id,
                onSuccess: () {
                  context.read<ApartamentosProvider>().carregarApartamento(
                    apartamento.id,
                  );
                },
              ),
            );
          },
        ),
      );
    }

    // History action only for Admin, Sindico, Funcionario
    final auth = context.read<AuthProvider>();
    final userTipo = auth.usuarioAtual?.tipo;
    if (userTipo != UsuarioTipo.Morador && userTipo != UsuarioTipo.Visitante) {
      actions.add(
        _ActionData(
          icon: Icons.history_rounded,
          label: AppLocalizations.of(context)!.apartments_view_history,
          subtitle: AppLocalizations.of(context)!.apartments_entries_exits,
          color: OwanyTheme.primaryOrange,
          onTap: () {
            // Navega para a mesma página de solicitações do apartamento
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MaintenanceListScreenComFiltroApartamento(
                  apartamentoId: apartamento.id,
                ),
              ),
            );
          },
        ),
      );
    }

    return actions;
  }

  void _showFeedback(String message, SnackBarType type) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(OwanyTheme.snackBar(message, type: type));
  }

  Future<void> _toggleEstado(Apartamento apartamento) async {
    final prov = context.read<ApartamentosProvider>();

    final novoEstado = apartamento.estado == EstadoApartamento.EmManutencao
        ? 'Disponivel'
        : 'Manutencao';

    await prov.atualizarApartamento(
      apartamento.id,
      nome: apartamento.nome,
      numero: apartamento.numero,
      bloco: apartamento.bloco,
      andar: apartamento.andar,
      estado: novoEstado,
      descricao: apartamento.descricao,
    );

    if (!mounted) return;

    _showFeedback(
      novoEstado == 'Manutencao'
          ? AppLocalizations.of(context)!.apartments_in_maintenance
          : AppLocalizations.of(context)!.apartments_available,
      novoEstado == 'Manutencao' ? SnackBarType.warning : SnackBarType.success,
    );
  }

  Future<void> _desvincularMorador(
    Morador morador,
    Apartamento apartamento,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? OwanyTheme.darkSurface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.apartments_make_available_question,
        ),
        content: Text(
          AppLocalizations.of(
            context,
          )!.apartments_remove_resident_confirm(morador.nome),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: OwanyTheme.error),
            child: Text(AppLocalizations.of(context)!.apartments_remove),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dados = {
        'id': morador.id,
        'nome': morador.nome,
        'usuarioId': morador.usuarioId,
        'apartamentoId': null,
      };

      await context.read<MoradoresProvider>().atualizarMorador(
        morador.id,
        dados,
      );

      if (!mounted) return;

      _showFeedback(
        AppLocalizations.of(context)!.apartments_resident_available_success,
        SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        AppLocalizations.of(
          context,
        )!.apartments_error_make_available(e.toString()),
        SnackBarType.error,
      );
    }
  }

  Future<void> _registrarSaidaDireto(
    Morador morador,
    Apartamento apartamento,
  ) async {
    if (morador.id.trim().isEmpty) {
      if (mounted) {
        _showFeedback(
          AppLocalizations.of(context)!.apartments_exit_invalid_resident,
          SnackBarType.error,
        );
      }
      return;
    }

    final motivoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? OwanyTheme.darkSurface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: OwanyTheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.apartments_register_exit,
                style: TextStyle(
                  color: OwanyTheme.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.apartments_confirm_exit(morador.nome),
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.apartments_exit_reason,
                hintText: AppLocalizations.of(
                  context,
                )!.apartments_exit_reason_hint,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? OwanyTheme.darkSurface
                    : OwanyTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: OwanyTheme.primaryOrange,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton.secondary(
            text: AppLocalizations.of(context)!.common_cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 8),
          PrimaryButton.error(
            text: AppLocalizations.of(context)!.apartments_confirm_exit_button,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<HistoricoOcupacaoProvider>();
      final sucesso = await provider.registrarSaida(
        morador.id,
        motivo: motivoController.text.isNotEmpty ? motivoController.text : null,
      );

      if (sucesso && mounted) {
        _showFeedback(
          AppLocalizations.of(context)!.apartments_exit_success,
          SnackBarType.success,
        );
        await context.read<ApartamentosProvider>().carregarApartamento(
          apartamento.id,
        );
      } else if (mounted) {
        _showFeedback(
          AppLocalizations.of(context)!.apartments_exit_error,
          SnackBarType.error,
        );
      }
    }

    motivoController.dispose();
  }

  void _trocarMorador(Morador morador, Apartamento apartamento) {
    showDialog(
      context: context,
      builder: (_) => VincularMoradorDialog(
        apartamentoId: apartamento.id,
        moradorAtualId: morador.id,
        onSuccess: () {
          context.read<ApartamentosProvider>().carregarApartamento(
            apartamento.id,
          );
        },
      ),
    );
  }

  Color _getEstadoColor(EstadoApartamento estado) {
    switch (estado) {
      case EstadoApartamento.Ocupado:
        return OwanyTheme.success;
      case EstadoApartamento.Disponivel:
        return OwanyTheme.info;
      case EstadoApartamento.EmManutencao:
        return OwanyTheme.warning;
      case EstadoApartamento.Inativo:
        return OwanyTheme.error;
    }
  }

  IconData _getEstadoIcon(EstadoApartamento estado) {
    switch (estado) {
      case EstadoApartamento.Ocupado:
        return Icons.home_rounded;
      case EstadoApartamento.Disponivel:
        return Icons.check_circle_rounded;
      case EstadoApartamento.EmManutencao:
        return Icons.build_circle_rounded;
      case EstadoApartamento.Inativo:
        return Icons.block_rounded;
    }
  }

  Color _corEstadoItem(String status) {
    switch (estadoFromString(status)) {
      case ItemEstado.Disponivel:
        return OwanyTheme.success;
      case ItemEstado.EmUso:
        return OwanyTheme.primaryBlue;
      case ItemEstado.EmStock:
        return OwanyTheme.info;
      case ItemEstado.Manutencao:
        return OwanyTheme.warning;
      case ItemEstado.Danificado:
        return OwanyTheme.error;
      case ItemEstado.Inutilizado:
        return OwanyTheme.gray;
      case ItemEstado.Extraviado:
        return OwanyTheme.purple;
      case ItemEstado.Desconhecido:
        return OwanyTheme.warning;
    }
  }

  String _formatarDataCurta(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      return 'Hoje';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return 'Há ${diferenca.inDays} dias';
    } else if (diferenca.inDays < 30) {
      final semanas = (diferenca.inDays / 7).floor();
      return 'Há $semanas sem';
    } else {
      return '${data.day}/${data.month}';
    }
  }

  String _getEstadoShort(EstadoApartamento estado) {
    switch (estado) {
      case EstadoApartamento.Ocupado:
        return 'Ocu';
      case EstadoApartamento.Disponivel:
        return 'Disp';
      case EstadoApartamento.EmManutencao:
        return 'Man';
      case EstadoApartamento.Inativo:
        return 'Inat';
    }
  }
}

// =====================================================================
// DATA CLASSES
// =====================================================================

class _ActionData {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ActionData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

// =====================================================================
// QR CODE HELPER - TODO: Integrate with item click handler
// =====================================================================

// void _mostrarQRCodeItem(BuildContext context, ItemApartamento item) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text('QR Code - ${item.nome}'),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (item.codigoIdentificador?.isNotEmpty ?? false) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: QrImage(
//                   data: item.codigoIdentificador!,
//                   size: 200.0,
//                 ),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Código: ${item.codigoIdentificador}',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 item.nome,
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ] else
//               Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Text('Este item não possui código identificador'),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text('Fechar'),
//         ),
//       ],
//     ),
//   );
// }
