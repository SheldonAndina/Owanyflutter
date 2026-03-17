// ============================================================================
// MAINTENANCE LIST SCREEN - PREMIUM PRO VERSION 3.0
// Features: Glassmorphism header, animated arc dashboard, shimmer loader,
//           rich cards with urgency stripe, infinite scroll, export button
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/file_download_helper.dart';
import '../../utils/app_logger.dart';
import '../../services/api_service.dart';
import '../../utils/network_error_helper.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../dto/solicitacoes_v2_dtos.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums.dart';
import '../../widgets/primary_button.dart';

String _getWindowsCompatibleTimestamp() {
  final now = DateTime.now();
  return now.toIso8601String().replaceAll(':', '-');
}

class MaintenanceListScreenV2 extends StatefulWidget {
  const MaintenanceListScreenV2({super.key});

  @override
  State<MaintenanceListScreenV2> createState() =>
      _MaintenanceListScreenV2State();
}

class _MaintenanceListScreenV2State extends State<MaintenanceListScreenV2>
    with TickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  String? _statusFilter;
  bool _apenasMinhas = false;
  final _scrollOffset = ValueNotifier<double>(0);
  String _searchQuery = '';
  final _searchController = TextEditingController();
  List<SolicitacaoListaDto>? _filteredCache;
  List<SolicitacaoListaDto>? _cachedSource;
  int _cachedSourceLength = -1;
  String? _cachedSourceFirstId;
  String? _cachedSourceLastId;
  String _cachedSearchQuery = '';
  List<SolicitacaoListaDto>? _searchIndexSource;
  int _searchIndexLength = -1;
  String? _searchIndexFirstId;
  String? _searchIndexLastId;
  Map<String, String> _searchIndex = {};

  // Controla quais grupos (por status) estão expandidos
  final Map<String, bool> _expandedStatus = {};

  final _scrollController = ScrollController();
  late SolicitacoesProvider _provider;

  // ── animations ─────────────────────────────────────────────────────────────
  late AnimationController _headerAnimController;
  late AnimationController _pulseController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _pulseAnimation;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _headerFadeAnimation =
        CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic);
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _provider = context.read<SolicitacoesProvider>();
    _scrollController.addListener(_onScroll);

    Future.microtask(() async {
      await _carregarSolicitacoesComPermissao();
      if (mounted) _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    _searchController.dispose();
    _headerAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (_provider.hasNextPage && !_provider.isLoading) {
        _provider.loadNextPage();
      }
    }
  }

  void _invalidateFilteredCache() {
    _filteredCache = null;
  }

  Future<void> _carregarSolicitacoesComPermissao({bool forceRefresh = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.isVisitante || auth.isPortaria) {
      _provider.limparDados();
      return;
    }
    if (auth.isMorador) {
      final id = auth.apartamentoIdDoMorador;
      if (id != null && id.isNotEmpty) {
        await _provider.loadSolicitacoes(
          apartamentoId: id,
          verTodas: false,
          refresh: forceRefresh,
          carregarTodas: true,
        );
      } else {
        _provider.limparDados();
      }
    } else if (_apenasMinhas && (auth.isFuncionario || auth.isGestor)) {
      await _provider.loadSolicitacoes(
        responsavelId: auth.usuarioAtual?.id,
        verTodas: false,
        refresh: forceRefresh,
        carregarTodas: true,
      );
    } else if (auth.isStaff) {
      await _provider.loadSolicitacoes(
        verTodas: true,
        refresh: forceRefresh,
        carregarTodas: true,
      );
    } else {
      _provider.limparDados();
    }
  }

  void _toggleMinhasSolicitacoes(bool value) {
    setState(() => _apenasMinhas = value);
    _invalidateFilteredCache();
    HapticFeedback.selectionClick();
    final auth = context.read<AuthProvider>();
    if (value) {
      // Filtrar apenas as solicitações do funcionário
      _provider.loadSolicitacoes(
        status: _statusFilter,
        responsavelId: auth.usuarioAtual?.id,
        verTodas: false,
        refresh: true,
        carregarTodas: true,
      );
    } else {
      // Mostrar TODAS as solicitações novamente
      _provider.loadSolicitacoes(
        status: _statusFilter,
        verTodas: true,
        refresh: true,
        carregarTodas: true,
      );
    }
  }

  void _applyStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    _invalidateFilteredCache();
    HapticFeedback.selectionClick();
    final auth = context.read<AuthProvider>();
    _provider.loadSolicitacoes(
      status: status,
      responsavelId: _apenasMinhas ? auth.usuarioAtual?.id : null,
      verTodas: !_apenasMinhas,
      refresh: true,
      carregarTodas: true,
    );
  }

  // ── status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Pendente':      return OwanyTheme.warning;
      case 'EmAndamento':   return OwanyTheme.info;
      case 'EmAnalise':     return OwanyTheme.primaryBlue;
      case 'Aguardando':    return OwanyTheme.accentDark;
      case 'Concluido':     return OwanyTheme.success;
      case 'Cancelado':     return OwanyTheme.error;
      case 'Rejeitado':     return const Color(0xFF9333EA);
      default:              return OwanyTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pendente':      return Icons.schedule_rounded;
      case 'EmAndamento':   return Icons.autorenew_rounded;
      case 'EmAnalise':     return Icons.search_rounded;
      case 'Aguardando':    return Icons.hourglass_top_rounded;
      case 'Concluido':     return Icons.check_circle_rounded;
      case 'Cancelado':     return Icons.cancel_rounded;
      case 'Rejeitado':     return Icons.block_rounded;
      default:              return Icons.help_rounded;
    }
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Pendente':      return l10n.maintenance_status_pending;
      case 'EmAndamento':   return l10n.maintenance_status_in_progress;
      case 'EmAnalise':     return l10n.maintenance_status_em_analise;
      case 'Aguardando':    return l10n.maintenance_status_aguardando;
      case 'Concluido':     return l10n.maintenance_status_completed;
      case 'Cancelado':     return l10n.maintenance_status_cancelled;
      case 'Rejeitado':     return l10n.maintenance_status_rejeitado;
      default:              return status;
    }
  }

  bool _isOverdue(SolicitacaoListaDto s) {
    if (s.prazoLimite == null) return false;
    if (s.status == 'Concluido' || s.status == 'Cancelado' || s.status == 'Rejeitado') {
      return false;
    }
    return DateTime.now().isAfter(s.prazoLimite!);
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l10n.maintenance_time_minutes_ago(diff.inMinutes);
    if (diff.inHours < 24) return l10n.maintenance_time_hours_ago(diff.inHours);
    if (diff.inDays == 1) return l10n.maintenance_yesterday;
    if (diff.inDays < 7) return l10n.maintenance_time_days_ago(diff.inDays);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ── export ─────────────────────────────────────────────────────────────────

  Future<void> _exportarSolicitacoes() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Text(l10n.maintenance_exporting),
        ]),
        duration: const Duration(seconds: 30),
      ));

      final bytes =
          await ApiService().exportarSolicitacoesExcel(status: _statusFilter);
      final fileName = 'solicitacoes_${_getWindowsCompatibleTimestamp()}.xlsx';

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        await FileDownloadHelper.saveFileWithPicker(
          context,
          fileBytes: bytes,
          fileName: fileName,
          fileExtension: 'xlsx',
        );
      }
    } catch (e, st) {
      AppLogger.error('MaintenanceList', '❌ Erro ao exportar', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.maintenance_export_error(e.toString())),
          backgroundColor: OwanyTheme.error,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (_, value, __) => _GlassAppBar(
            scrollOffset: value,
            onExport: context.read<AuthProvider>().isStaff
                ? _exportarSolicitacoes
                : null,
          ),
        ),
      ),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.solicitacoes.isEmpty) {
            return const _ShimmerLoader();
          }
          if (provider.errorMessage != null && provider.solicitacoes.isEmpty) {
            return _buildErrorState(provider);
          }
          if (provider.solicitacoes.isEmpty) {
            return _buildEmptyState();
          }

          final listaCompleta = provider.solicitacoes;
          final length = listaCompleta.length;
          final firstId = length > 0 ? listaCompleta.first.id : null;
          final lastId = length > 0 ? listaCompleta.last.id : null;
          // Aplicar busca textual local (com cache)
          final canUseCache =
              identical(_cachedSource, listaCompleta) &&
              _cachedSourceLength == length &&
              _cachedSourceFirstId == firstId &&
              _cachedSourceLastId == lastId &&
              _cachedSearchQuery == _searchQuery &&
              _filteredCache != null;
          final lista = canUseCache
              ? _filteredCache!
              : _searchQuery.isEmpty
                  ? listaCompleta
                  : (() {
                      if (!identical(_searchIndexSource, listaCompleta) ||
                          _searchIndexLength != length ||
                          _searchIndexFirstId != firstId ||
                          _searchIndexLastId != lastId) {
                        _searchIndexSource = listaCompleta;
                        _searchIndexLength = length;
                        _searchIndexFirstId = firstId;
                        _searchIndexLastId = lastId;
                        _searchIndex = {
                          for (final s in listaCompleta)
                            s.id: [
                              s.titulo,
                              s.status,
                              s.numeroApartamento,
                              s.blocoApartamento,
                              s.nomeUsuarioCriador,
                              s.nomeResponsavel ?? '',
                              s.tipoSolicitacaoNome ?? '',
                              s.id,
                            ].map((e) => e.toLowerCase()).join('|'),
                        };
                      }
                      final q = _searchQuery.toLowerCase();
                      return listaCompleta
                          .where((s) => (_searchIndex[s.id] ?? '').contains(q))
                          .toList();
                    })();
          if (!canUseCache) {
            _cachedSource = listaCompleta;
            _cachedSourceLength = length;
            _cachedSourceFirstId = firstId;
            _cachedSourceLastId = lastId;
            _cachedSearchQuery = _searchQuery;
            _filteredCache = lista;
          }
          final pendentes = lista.where((s) => s.status == 'Pendente').length;
          final emAndamento = lista
              .where((s) => s.status == 'EmAndamento')
              .length;
          final emAnalise = lista
              .where((s) => s.status == 'EmAnalise')
              .length;
          final concluidas = lista.where((s) => s.status == 'Concluido').length;
          final urgentes = lista
              .where((s) =>
                  s.status != 'Concluido' &&
                  s.status != 'Cancelado' &&
                  s.prazoLimite != null &&
                  DateTime.now().isAfter(s.prazoLimite!))
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _carregarSolicitacoesComPermissao(forceRefresh: true);
            },
            color: OwanyTheme.primaryOrange,
            backgroundColor: OwanyTheme.cardColor(context),
            strokeWidth: 3,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── AppBar space ──
                const SliverToBoxAdapter(child: SizedBox(height: 140)),

                // ── Animated dashboard ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _PremiumDashboard(
                          total: lista.length,
                          pendentes: pendentes,
                          emAndamento: emAndamento,
                          emAnalise: emAnalise,
                          concluidas: concluidas,
                          urgentes: urgentes,
                          pulseAnimation: _pulseAnimation,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Sticky filter header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FilterHeader(
                      statusFilter: _statusFilter,
                      apenasMinhas: _apenasMinhas,
                      onStatusChange: _applyStatusFilter,
                      onToggleMinhas: _toggleMinhasSolicitacoes,
                      total: lista.length,
                      searchController: _searchController,
                      onSearchChanged: (q) {
                        _searchQuery = q;
                        _invalidateFilteredCache();
                        setState(() {});
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Lista agrupada por status com cabeçalhos expansíveis ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Para cada status definido abaixo, renderizamos um bloco
                      for (final status in [
                        'Pendente',
                        'EmAndamento',
                        'EmAnalise',
                        'Aguardando',
                        'Concluido',
                        'Cancelado',
                        'Rejeitado',
                      ])
                        _buildStatusGroup(status, lista),

                      // Footer de carregamento (após os grupos)
                      if (provider.hasNextPage) _buildLoadingFooter(),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Renderiza um bloco de solicitações para um `status` específico, com
  // cabeçalho que permite expandir/colapsar.
  Widget _buildStatusGroup(String status, List<SolicitacaoListaDto> lista) {
    final items = lista.where((s) => s.status == status).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final isExpanded = _expandedStatus[status] ?? false;
    final color = _statusColor(status);
    final label = _statusLabel(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expandedStatus[status] = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(_statusIcon(status), color: color, size: 18),
                  const SizedBox(width: 10),
                  Text('$label', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(width: 8),
                  Text('(${items.length})', style: TextStyle(color: OwanyTheme.textMuted)),
                ]),
                Transform.rotate(
                  angle: isExpanded ? 0 : -math.pi / 2,
                  child: Icon(Icons.chevron_left_rounded, color: OwanyTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isExpanded)
          ...items.map((sol) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PremiumSolicitacaoCard(
                  solicitacao: sol,
                  statusColor: _statusColor(sol.status),
                  statusIcon: _statusIcon(sol.status),
                  statusLabel: _statusLabel(sol.status),
                  isOverdue: _isOverdue(sol),
                  dateLabel: _formatDate(sol.criadoEm),
                  pulseAnimation: _pulseAnimation,
                ),
              )),
      ],
    );
  }

  Widget _buildLoadingFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: OwanyTheme.primaryOrange, strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                  OwanyTheme.accent.withValues(alpha: 0.05),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handyman_rounded,
                  size: 60, color: OwanyTheme.primaryOrange),
            ),
            const SizedBox(height: 22),
            Text(l10n.maintenance_empty,
                style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(l10n.maintenance_empty_subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: 14,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SolicitacoesProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final offline = NetworkErrorHelper.isServerOffline(provider.errorMessage);
    final accent = offline ? OwanyTheme.warning : OwanyTheme.error;
    final icon = offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded;
    final title = offline
        ? NetworkErrorHelper.offlineTitle()
        : l10n.maintenance_error_loading;
    final detail = offline
        ? NetworkErrorHelper.offlineMessage()
        : (provider.errorMessage ?? l10n.items_unknown_error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 62, color: accent),
            ),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 28),
            PrimaryButton.primary(
              text: l10n.maintenance_try_again,
              onPressed: () => _carregarSolicitacoesComPermissao(),
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// GLASS APP BAR
// =============================================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final VoidCallback? onExport;

  const _GlassAppBar({required this.scrollOffset, this.onExport});

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange.withValues(alpha: 0.85 + opacity * 0.15),
                OwanyTheme.accent.withValues(alpha: 0.75 + opacity * 0.25),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                  color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.construction_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.maintenance_title,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          l10n.apartments_complete_management,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context)
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Export button
                  if (onExport != null)
                    GestureDetector(
                      onTap: onExport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text(
                              'Excel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
      ),
    );
  }
}

// =============================================================================
// PREMIUM DASHBOARD (circular arcs + urgency pulse)
// =============================================================================

class _PremiumDashboard extends StatelessWidget {
  final int total, pendentes, emAndamento, emAnalise, concluidas, urgentes;
  final Animation<double> pulseAnimation;

  const _PremiumDashboard({
    required this.total,
    required this.pendentes,
    required this.emAndamento,
    required this.emAnalise,
    required this.concluidas,
    required this.urgentes,
    required this.pulseAnimation,
  });

  double _pct(int v) => total == 0 ? 0 : v / total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.08),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.03),
                ],
              ),
            ),
            child: Column(
              children: [
                // Circular arc stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ArcStat(
                      label: l10n.maintenance_pending_count,
                      value: pendentes,
                      percent: _pct(pendentes),
                      color: OwanyTheme.error,
                      delay: 0,
                    ),
                    _ArcStat(
                      label: l10n.maintenance_in_progress_count,
                      value: emAndamento,
                      percent: _pct(emAndamento),
                      color: OwanyTheme.warning,
                      delay: 120,
                    ),
                    _ArcStat(
                      label: l10n.maintenance_status_in_analysis,
                      value: emAnalise,
                      percent: _pct(emAnalise),
                      color: const Color(0xFF7C3AED),
                      delay: 240,
                    ),
                  ],
                ),

                if (urgentes > 0) ...[
                  const SizedBox(height: 16),
                  Container(height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (_, child) =>
                        Transform.scale(scale: pulseAnimation.value, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: OwanyTheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: OwanyTheme.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '$urgentes solicitaç${urgentes == 1 ? 'ão' : 'ões'} em atraso',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcStat extends StatefulWidget {
  final String label;
  final int value;
  final double percent;
  final Color color;
  final int delay;

  const _ArcStat({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.delay,
  });

  @override
  State<_ArcStat> createState() => _ArcStatState();
}

class _ArcStatState extends State<_ArcStat> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _ArcPainter(
                  percent: widget.percent * _anim.value, color: widget.color),
              child: Center(
                child: Text(
                  '${(widget.percent * 100 * _anim.value).round()}%',
                  style: TextStyle(
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Text(
            '${(widget.value * _anim.value).round()}',
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.label,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double percent;
  final Color color;
  _ArcPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final bg = Paint()
      ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.55)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * percent, false, fg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// =============================================================================
// FILTER HEADER (search + chips + toggle)
// =============================================================================

class _FilterHeader extends StatelessWidget {
  final String? statusFilter;
  final bool apenasMinhas;
  final ValueChanged<String?> onStatusChange;
  final ValueChanged<bool> onToggleMinhas;
  final int total;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _FilterHeader({
    required this.statusFilter,
    required this.apenasMinhas,
    required this.onStatusChange,
    required this.onToggleMinhas,
    required this.total,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuarioAtual;
    final showToggle = usuario?.tipo == UsuarioTipo.Funcionario || auth.isGestor;

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.maintenance_search_hint,
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: OwanyTheme.textMutedColor(context)),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: OwanyTheme.textMutedColor(context)),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: OwanyTheme.textMutedColor(context).withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: OwanyTheme.primaryOrange, width: 1.5),
                ),
              ),
              style: TextStyle(fontSize: 14, color: OwanyTheme.textPrimary(context)),
            ),
          ),

          // ── Count pill ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_rounded,
                          size: 15, color: OwanyTheme.primaryOrange),
                      const SizedBox(width: 6),
                      Text(
                        l10n.maintenance_total_label(total),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.filter_list_rounded,
                    size: 16,
                    color: OwanyTheme.textMutedColor(context)),
                const SizedBox(width: 6),
                Text(
                  l10n.maintenance_filter_by_status,
                  style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Status chips ──
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip2(
                  label: l10n.maintenance_all,
                  icon: Icons.all_inclusive_rounded,
                  isActive: statusFilter == null,
                  onTap: () => onStatusChange(null),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_pending,
                  icon: Icons.schedule_rounded,
                  color: OwanyTheme.warning,
                  isActive: statusFilter == 'Pendente',
                  onTap: () => onStatusChange('Pendente'),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_in_progress,
                  icon: Icons.autorenew_rounded,
                  color: OwanyTheme.info,
                  isActive: statusFilter == 'EmAndamento',
                  onTap: () => onStatusChange('EmAndamento'),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_em_analise,
                  icon: Icons.search_rounded,
                  color: OwanyTheme.primaryBlue,
                  isActive: statusFilter == 'EmAnalise',
                  onTap: () => onStatusChange('EmAnalise'),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_completed,
                  icon: Icons.check_circle_rounded,
                  color: OwanyTheme.success,
                  isActive: statusFilter == 'Concluido',
                  onTap: () => onStatusChange('Concluido'),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_cancelled,
                  icon: Icons.cancel_rounded,
                  color: OwanyTheme.error,
                  isActive: statusFilter == 'Cancelado',
                  onTap: () => onStatusChange('Cancelado'),
                ),
                const SizedBox(width: 8),
                _FilterChip2(
                  label: l10n.maintenance_status_rejeitado,
                  icon: Icons.block_rounded,
                  color: const Color(0xFF9333EA),
                  isActive: statusFilter == 'Rejeitado',
                  onTap: () => onStatusChange('Rejeitado'),
                ),
              ],
            ),
          ),

          // ── Minhas toggle ──
          if (showToggle) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: _MinhasToggle(
                value: apenasMinhas,
                onChanged: onToggleMinhas,
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _FilterChip2 extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip2({
    required this.label,
    required this.icon,
    this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OwanyTheme.primaryOrange;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [chipColor, chipColor.withValues(alpha: 0.75)])
              : null,
          color: isActive
              ? null
              : OwanyTheme.textMutedColor(context).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? chipColor
                : OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : chipColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : OwanyTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinhasToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MinhasToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(colors: [
                  OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                  OwanyTheme.accent.withValues(alpha: 0.05),
                ])
              : null,
          color: value ? null : OwanyTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? OwanyTheme.primaryOrange.withValues(alpha: 0.35)
                : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                value ? Icons.person_rounded : Icons.people_rounded,
                key: ValueKey(value),
                size: 18,
                color: value
                    ? OwanyTheme.primaryOrange
                    : OwanyTheme.textMutedColor(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value
                    ? l10n.maintenance_my_requests
                    : l10n.maintenance_all_requests,
                style: TextStyle(
                  color: value
                      ? OwanyTheme.primaryOrange
                      : OwanyTheme.textMutedColor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor:
                  OwanyTheme.primaryOrange.withValues(alpha: 0.5),
              activeThumbColor: OwanyTheme.primaryOrange,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM SOLICITATION CARD
// =============================================================================

class _PremiumSolicitacaoCard extends StatefulWidget {
  final SolicitacaoListaDto solicitacao;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final bool isOverdue;
  final String dateLabel;
  final Animation<double> pulseAnimation;

  const _PremiumSolicitacaoCard({
    required this.solicitacao,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.isOverdue,
    required this.dateLabel,
    required this.pulseAnimation,
  });

  @override
  State<_PremiumSolicitacaoCard> createState() =>
      _PremiumSolicitacaoCardState();
}

class _PremiumSolicitacaoCardState extends State<_PremiumSolicitacaoCard> {
  bool _pressed = false;

  Widget _buildAvatarInitials(String nome) {
    final parts = nome.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : nome.substring(0, nome.length >= 2 ? 2 : 1).toUpperCase();
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: OwanyTheme.primaryOrange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sol = widget.solicitacao;
    final color = widget.statusColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          '/solicitacoes-detalhe',
          arguments: {'solicitacaoId': sol.id},
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OwanyTheme.borderColor(context).withValues(alpha: _pressed ? 0.5 : 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.textMutedColor(context).withValues(alpha: _pressed ? 0.1 : 0.04),
                blurRadius: _pressed ? 12 : 6,
                offset: Offset(0, _pressed ? 4 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ── Status left stripe (minimal) ──
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  // ── Card body ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Row 1: icon circle + title + status badge ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(widget.statusIcon,
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            sol.titulo,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: OwanyTheme.textPrimary(
                                                  context),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Status badge (improved contrast)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: color.withValues(alpha: 0.45),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            widget.statusLabel,
                                            style: TextStyle(
                                              color: color.withValues(alpha: 0.95),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
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

                          const SizedBox(height: 10),

                          // ── Row 2: apt + deadline + overdue ──
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            children: [
                              _MetaBadge(
                                icon: Icons.apartment_rounded,
                                label: l10n.maintenance_apt_block(
                                    sol.numeroApartamento,
                                    sol.blocoApartamento),
                              ),
                              if (sol.prazoLimite != null)
                                _DeadlineBadge(
                                  prazo: sol.prazoLimite!,
                                  atrasada: widget.isOverdue,
                                ),
                              if (widget.isOverdue)
                                _MetaBadge(
                                  icon: Icons.warning_amber_rounded,
                                  label: l10n.maintenance_overdue,
                                  color: OwanyTheme.error,
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Row 3: creator + responsible ──
                          Row(
                            children: [
                              _buildAvatarInitials(sol.nomeUsuarioCriador),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  l10n.maintenance_created_by(
                                      sol.nomeUsuarioCriador),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: OwanyTheme.textMutedColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (sol.nomeResponsavel != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.primaryOrange
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.engineering_rounded,
                                          size: 12,
                                          color: OwanyTheme.primaryOrange),
                                      const SizedBox(width: 4),
                                      Text(
                                        sol.nomeResponsavel!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: OwanyTheme.primaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: OwanyTheme.borderColor(context).withValues(alpha: 0.2),
                            ),
                          ),

                          // ── Row 4: date + counters + arrow ──
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 13,
                                  color: OwanyTheme.textMutedColor(context)
                                      .withValues(alpha: 0.6)),
                              Text(
                                widget.dateLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OwanyTheme.textMutedColor(context)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              if (sol.quantidadeComentarios > 0)
                                _CounterBadge(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    count: sol.quantidadeComentarios),
                              if (sol.quantidadeAnexos > 0)
                                _CounterBadge(
                                    icon: Icons.attach_file_rounded,
                                    count: sol.quantidadeAnexos),
                              Icon(Icons.chevron_right_rounded,
                                  size: 20,
                                  color: OwanyTheme.textMutedColor(context)
                                      .withValues(alpha: 0.5)),
                            ],
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
    );
  }
}

// =============================================================================
// MICRO WIDGETS
// =============================================================================

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? OwanyTheme.textMutedColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: c)),
        ],
      ),
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final DateTime prazo;
  final bool atrasada;

  const _DeadlineBadge({required this.prazo, required this.atrasada});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(prazo);
    final isSoon = !atrasada && prazo.isAfter(now) && prazo.difference(now).inHours <= 24;
    final color = atrasada ? OwanyTheme.error : (isSoon ? OwanyTheme.warning : OwanyTheme.textMutedColor(context));
    final label = atrasada
        ? 'Atrasada — ${_relativeFromDiff(diff)}'
        : (isSoon ? 'Prazo hoje' : '${prazo.day.toString().padLeft(2, '0')}/${prazo.month.toString().padLeft(2, '0')}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(atrasada ? Icons.error_outline_rounded : Icons.event_rounded,
              size: 14, color: color.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _relativeFromDiff(Duration diff) {
    if (diff.inDays >= 1) return '${diff.inDays} dias atrás';
    if (diff.inHours >= 1) return '${diff.inHours}h atrás';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m atrás';
    return 'agora';
  }
}

class _CounterBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  const _CounterBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.6)),
        const SizedBox(width: 3),
        Text('$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
            )),
      ],
    );
  }
}

// =============================================================================
// SHIMMER LOADER
// =============================================================================

class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader();

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _block(double h, {double? w, double radius = 14}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.09),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.22),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.09),
            ],
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 140),
          _block(170, radius: 28),
          const SizedBox(height: 20),
          _block(140, radius: 24),
          const SizedBox(height: 20),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _block(120, radius: 22),
            ),
          ),
        ],
      ),
    );
  }
}
