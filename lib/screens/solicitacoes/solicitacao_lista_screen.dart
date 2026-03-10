import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:owany_app/generated_l10n/app_localizations.dart';
import 'package:owany_app/providers/solicitacoes_provider.dart';
import 'package:owany_app/providers/auth_provider.dart';
import 'package:owany_app/models/enums.dart';
import 'package:owany_app/theme/owany_theme.dart';
import 'package:owany_app/dto/solicitacoes_v2_dtos.dart';
import 'package:owany_app/utils/network_error_helper.dart';

// =============================================================
// SOLICITAÇÕES SCREEN – PREMIUM PRO VERSION 3.0
// Features: Circular Arc Stats, Priority Badges, Shimmer Loader,
//           Urgency Indicator, Rich Cards, Advanced Glassmorphism
// =============================================================

class SolicitacaoListaScreen extends StatefulWidget {
  const SolicitacaoListaScreen({super.key});

  @override
  State<SolicitacaoListaScreen> createState() => _SolicitacaoListaScreenState();
}

class _SolicitacaoListaScreenState extends State<SolicitacaoListaScreen>
    with TickerProviderStateMixin {
  String _filtroStatus = 'todas';
  // Padrão = 'minhas' para funcionários, admins/síndicos sempre veem todas
  String _filtroVisao = 'minhas';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _headerAnimController;
  late AnimationController _pulseController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _pulseAnimation;

  double _scrollOffset = 0;
  bool _showExtendedDashboard = false;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      String? apartamentoIdArg;
      if (routeArgs is Map && routeArgs['apartamentoId'] is String) {
        apartamentoIdArg = routeArgs['apartamentoId'] as String?;
      }

      final auth = context.read<AuthProvider>();

      String? apartamentoIdParam;
      String? responsavelIdParam;
      // Admin/Síndico sempre vê todas; Funcionário usa o filtro (default: minhas)
      final isGestor = auth.isAdmin || auth.isSindico;
      final verTodasParam = isGestor || (auth.isFuncionario && _filtroVisao == 'todas');

      if (apartamentoIdArg != null && apartamentoIdArg.isNotEmpty) {
        apartamentoIdParam = apartamentoIdArg;
      } else if (auth.isMorador) {
        apartamentoIdParam = auth.apartamentoIdDoMorador;
      } else if (auth.isFuncionario && !verTodasParam) {
        // Funcionário vendo só as dele
        responsavelIdParam = auth.usuarioAtual?.id;
      }

      context.read<SolicitacoesProvider>().loadSolicitacoes(
            apartamentoId: apartamentoIdParam,
            responsavelId: responsavelIdParam,
            verTodas: verTodasParam,
            refresh: true,
            carregarTodas: true,
          );

      _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<SolicitacaoListaDto> _filtrarSolicitacoes(List<SolicitacaoListaDto> lista) {
    var resultado = lista;

    // Filtro "minhas" só se aplica a funcionários (admins/síndicos sempre veem todas)
    final auth = context.read<AuthProvider>();
    final isFuncionarioSemGestao = auth.isFuncionario && !auth.isAdmin && !auth.isSindico;
    if (isFuncionarioSemGestao && _filtroVisao == 'minhas') {
      final userId = auth.usuarioAtual?.id;
      resultado = resultado
          .where((s) => s.responsavelId != null && s.responsavelId == userId)
          .toList();
    }

    if (_filtroStatus == 'pendentes') {
      resultado = resultado.where((s) => s.status == 'Pendente').toList();
    } else if (_filtroStatus == 'andamento') {
      resultado = resultado
          .where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise')
          .toList();
    } else if (_filtroStatus == 'concluidas') {
      resultado = resultado.where((s) => s.status == 'Concluido').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      resultado = resultado
          .where((s) =>
              s.titulo.toLowerCase().contains(q) ||
              s.numeroApartamento.toLowerCase().contains(q) ||
              s.blocoApartamento.toLowerCase().contains(q) ||
              s.nomeUsuarioCriador.toLowerCase().contains(q) ||
              (s.nomeResponsavel?.toLowerCase().contains(q) ?? false) ||
              (s.tipoSolicitacaoNome?.toLowerCase().contains(q) ?? false) ||
              s.id.toLowerCase().contains(q))
          .toList();
    }

    resultado.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return resultado;
  }

  Color _corStatus(String status) {
    if (status == 'Concluido') return OwanyTheme.success;
    if (status == 'EmAndamento') return OwanyTheme.warning;
    if (status == 'EmAnalise') return const Color(0xFF7C3AED);
    return OwanyTheme.error;
  }

  IconData _iconeStatus(String status) {
    if (status == 'Concluido') return Icons.check_circle_rounded;
    if (status == 'EmAndamento') return Icons.build_rounded;
    if (status == 'EmAnalise') return Icons.manage_search_rounded;
    return Icons.schedule_rounded;
  }

  String _traduzirStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'Concluido') return l10n.maintenance_status_completed;
    if (status == 'EmAndamento') return l10n.maintenance_status_in_progress;
    if (status == 'EmAnalise') return l10n.maintenance_status_in_analysis;
    if (status == 'Pendente') return l10n.maintenance_status_pending;
    return status;
  }

  /// Urgency: 0=normal, 1=medium (3-7 days), 2=high (>7 days)
  int _urgencia(SolicitacaoListaDto sol) {
    if (sol.status == 'Concluido') return 0;
    final dias = DateTime.now().difference(sol.criadoEm).inDays;
    if (dias > 7) return 2;
    if (dias > 3) return 1;
    return 0;
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);
    final l10n = AppLocalizations.of(context)!;
    if (diferenca.inMinutes < 60) return l10n.time_ago_minutes(diferenca.inMinutes);
    if (diferenca.inHours < 24) return l10n.time_ago_hours(diferenca.inHours);
    if (diferenca.inDays == 1) return l10n.time_yesterday;
    if (diferenca.inDays < 7) return l10n.time_ago_days(diferenca.inDays);
    return '${data.day}/${data.month}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _GlassAppBar(scrollOffset: _scrollOffset),
      ),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const _ShimmerLoader();

          if (provider.errorMessage != null) {
            return _ErrorState(
              message: provider.errorMessage!,
              onRetry: () {
                final auth = context.read<AuthProvider>();
                String? aptId;
                String? respId;
                final verTodasFlag = _filtroVisao == 'todas';
                if (!verTodasFlag) {
                  if (auth.isMorador) aptId = auth.apartamentoIdDoMorador;
                  if (auth.isFuncionario) respId = auth.usuarioAtual?.id;
                }
                provider.loadSolicitacoes(
                  apartamentoId: aptId,
                  responsavelId: respId,
                  verTodas: verTodasFlag,
                  refresh: true,
                  carregarTodas: true,
                );
              },
            );
          }

          final todas = provider.solicitacoes;
          final pendentes = todas.where((s) => s.status == 'Pendente').length;
          final emAndamento = todas
              .where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise')
              .length;
          final concluidas = todas.where((s) => s.status == 'Concluido').length;
          final urgentes = todas
              .where((s) =>
                  s.status != 'Concluido' &&
                  DateTime.now().difference(s.criadoEm).inDays > 7)
              .length;
          final filtradas = _filtrarSolicitacoes(todas);

          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              final auth = context.read<AuthProvider>();
              String? aptId;
              String? respId;
              // Admin/Síndico sempre vê todas; funcionário usa o toggle
              final isGestor = auth.isAdmin || auth.isSindico;
              final verTodasFlag = isGestor || _filtroVisao == 'todas';
              if (!verTodasFlag) {
                if (auth.isMorador) aptId = auth.apartamentoIdDoMorador;
                if (auth.isFuncionario) respId = auth.usuarioAtual?.id;
              }

              await provider.loadSolicitacoes(
                apartamentoId: aptId,
                responsavelId: respId,
                verTodas: verTodasFlag,
                refresh: true,
                carregarTodas: true,
              );
            },
            color: OwanyTheme.primaryOrange,
            backgroundColor: OwanyTheme.cardColor(context),
            strokeWidth: 3,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 140)),

                // ── Dashboard ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _PremiumDashboard(
                          total: todas.length,
                          pendentes: pendentes,
                          emAndamento: emAndamento,
                          concluidas: concluidas,
                          urgentes: urgentes,
                          showExtended: _showExtendedDashboard,
                          pulseAnimation: _pulseAnimation,
                          onToggle: () {
                            setState(() =>
                                _showExtendedDashboard = !_showExtendedDashboard);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Search ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PremiumSearchBar(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Visão Toggle (apenas para funcionários) ──
                if (context.watch<AuthProvider>().isFuncionario &&
                    !context.watch<AuthProvider>().isAdmin &&
                    !context.watch<AuthProvider>().isSindico)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _VisaoToggle(
                        visaoAtual: _filtroVisao,
                        onChanged: (v) {
                          setState(() => _filtroVisao = v);
                          HapticFeedback.selectionClick();
                          final auth = context.read<AuthProvider>();
                          String? respId;
                          final verTodasFlag = v == 'todas';
                          if (!verTodasFlag) {
                            respId = auth.usuarioAtual?.id;
                          }

                          context.read<SolicitacoesProvider>().loadSolicitacoes(
                                responsavelId: respId,
                                verTodas: verTodasFlag,
                                refresh: true,
                                carregarTodas: true,
                              );
                        },
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Status chips with live counts ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatusChipsRow(
                      filtroAtual: _filtroStatus,
                      pendentes: pendentes,
                      emAndamento: emAndamento,
                      concluidas: concluidas,
                      onChanged: (v) {
                        setState(() => _filtroStatus = v);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Count pill + Clear ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filtradas.length} ${l10n.maintenance_list_title}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: OwanyTheme.primaryOrange,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_searchQuery.isNotEmpty || _filtroStatus != 'todas')
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _filtroStatus = 'todas';
                              });
                              HapticFeedback.mediumImpact();
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: Text(l10n.apartments_clear_all),
                            style: TextButton.styleFrom(
                                foregroundColor: OwanyTheme.primaryOrange),
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── List / Empty ──
                if (filtradas.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      filtroStatus: _filtroStatus,
                      searchQuery: _searchQuery,
                    ),
                  )
                else
                  _buildAnimatedList(filtradas),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFabIfAllowed(),
    );
  }

  Widget _buildAnimatedList(List<SolicitacaoListaDto> solicitacoes) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sol = solicitacoes[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + (index * 45)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final c = value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: Opacity(opacity: c, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PremiumSolicitacaoCard(
                  solicitacao: sol,
                  cor: _corStatus(sol.status),
                  icone: _iconeStatus(sol.status),
                  statusLabel: _traduzirStatus(sol.status),
                  dataLabel: _formatarData(sol.criadoEm),
                  urgencia: _urgencia(sol),
                  pulseAnimation: _pulseAnimation,
                ),
              ),
            );
          },
          childCount: solicitacoes.length,
        ),
      ),
    );
  }

  Widget? _buildFabIfAllowed() {
    final userType = context.watch<AuthProvider>().usuarioAtual?.tipo;
    if (userType != UsuarioTipo.Administrador &&
        userType != UsuarioTipo.Sindico &&
        userType != UsuarioTipo.Funcionario &&
        userType != UsuarioTipo.Morador) {
      return null;
    }
    return FloatingActionButton.extended(
      heroTag: 'solicitacoes_fab',
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/solicitacao-criar');
      },
      backgroundColor: OwanyTheme.primaryOrange,
      icon: const Icon(Icons.add_rounded, color: OwanyTheme.white),
      label: Text(
        AppLocalizations.of(context)!.maintenance_list_title,
        style: const TextStyle(
            color: OwanyTheme.white, fontWeight: FontWeight.w700),
      ),
      elevation: 6,
    );
  }
}

// =============================================================
// GLASS APP BAR
// =============================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  const _GlassAppBar({required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
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
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          l10n.maintenance_list_title,
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
// PREMIUM DASHBOARD  (circular arcs, extended stats, toggle)
// =============================================================

class _PremiumDashboard extends StatelessWidget {
  final int total, pendentes, emAndamento, concluidas, urgentes;
  final bool showExtended;
  final Animation<double> pulseAnimation;
  final VoidCallback onToggle;

  const _PremiumDashboard({
    required this.total,
    required this.pendentes,
    required this.emAndamento,
    required this.concluidas,
    required this.urgentes,
    required this.showExtended,
    required this.pulseAnimation,
    required this.onToggle,
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
            blurRadius: 24,
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
                    _AnimatedCircularStat(
                      label: l10n.maintenance_pending_count,
                      value: pendentes,
                      percent: _pct(pendentes),
                      color: OwanyTheme.error,
                      delay: 0,
                    ),
                    _AnimatedCircularStat(
                      label: l10n.maintenance_in_progress_count,
                      value: emAndamento,
                      percent: _pct(emAndamento),
                      color: OwanyTheme.warning,
                      delay: 120,
                    ),
                    _AnimatedCircularStat(
                      label: l10n.maintenance_completed_count,
                      value: concluidas,
                      percent: _pct(concluidas),
                      color: OwanyTheme.success,
                      delay: 240,
                    ),
                  ],
                ),

                // Extended section
                if (showExtended) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        OwanyTheme.adaptiveOverlay(context, opacity: 0.35),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfoCard(
                          icon: Icons.list_alt_rounded,
                          label: 'Total',
                          value: total.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: pulseAnimation,
                          builder: (_, child) => Transform.scale(
                            scale: urgentes > 0 ? pulseAnimation.value : 1.0,
                            child: child,
                          ),
                          child: _MiniInfoCard(
                            icon: Icons.warning_amber_rounded,
                            label: 'Urgentes (+7d)',
                            value: urgentes.toString(),
                            accent: urgentes > 0 ? OwanyTheme.error : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ResolutionBar(concluidas: concluidas, total: total),
                ],

                const SizedBox(height: 16),

                // Toggle
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: OwanyTheme.adaptiveOverlay(context,
                              opacity: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showExtended
                              ? l10n.apartments_see_less
                              : l10n.apartments_see_more_stats,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
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
    );
  }
}

// ── Circular arc stat ──
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
          width: 82,
          height: 82,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _ArcPainter(
                  percent: widget.percent * _anim.value,
                  color: widget.color),
              child: Center(
                child: Text(
                  '${(widget.percent * 100 * _anim.value).round()}%',
                  style: TextStyle(
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
      ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..shader = LinearGradient(colors: [color, color.withValues(alpha: 0.55)])
          .createShader(Rect.fromCircle(center: center, radius: radius))
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

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _MiniInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? OwanyTheme.adaptiveTextOverlay(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent?.withValues(alpha: 0.4) ??
              OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: c, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context)
                      .withValues(alpha: 0.75),
                  fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ResolutionBar extends StatelessWidget {
  final int concluidas;
  final int total;

  const _ResolutionBar({required this.concluidas, required this.total});

  String _tx(BuildContext context, String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : concluidas / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_tx(context, 'Taxa de Resolução', 'Resolution Rate'),
                  style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: pct),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor:
                    OwanyTheme.adaptiveOverlay(context, opacity: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(
                    OwanyTheme.adaptiveTextOverlay(context)),
                minHeight: 8,
              ),
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

  const _PremiumSearchBar(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.maintenance_search_hint,
          hintStyle: TextStyle(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
              fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded,
              color: OwanyTheme.primaryOrange, size: 24),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: OwanyTheme.textMutedColor(context), size: 20),
                  onPressed: () => onChanged(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

// =============================================================
// VISÃO TOGGLE
// =============================================================

class _VisaoToggle extends StatelessWidget {
  final String visaoAtual;
  final ValueChanged<String> onChanged;

  const _VisaoToggle({required this.visaoAtual, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
              label: 'Minhas',
              icon: Icons.assignment_ind_rounded,
              isSelected: visaoAtual == 'minhas',
              onTap: () => onChanged('minhas')),
          _ToggleOption(
              label: 'Todas',
              icon: Icons.list_rounded,
              isSelected: visaoAtual == 'todas',
              onTap: () => onChanged('todas')),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [OwanyTheme.primaryOrange, OwanyTheme.accent])
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? OwanyTheme.white
                      : OwanyTheme.textMutedColor(context)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: isSelected
                        ? OwanyTheme.white
                        : OwanyTheme.textMutedColor(context),
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// STATUS CHIPS  (with live count badges)
// =============================================================

class _StatusChipsRow extends StatelessWidget {
  final String filtroAtual;
  final int pendentes, emAndamento, concluidas;
  final ValueChanged<String> onChanged;

  const _StatusChipsRow({
    required this.filtroAtual,
    required this.pendentes,
    required this.emAndamento,
    required this.concluidas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PremiumChip(
              label: l10n.maintenance_all,
              isSelected: filtroAtual == 'todas',
              onTap: () => onChanged('todas')),
          const SizedBox(width: 8),
          _PremiumChip(
              label: l10n.maintenance_pending_count,
              icon: Icons.schedule_rounded,
              color: OwanyTheme.error,
              count: pendentes,
              isSelected: filtroAtual == 'pendentes',
              onTap: () => onChanged('pendentes')),
          const SizedBox(width: 8),
          _PremiumChip(
              label: l10n.maintenance_status_in_progress,
              icon: Icons.build_rounded,
              color: OwanyTheme.warning,
              count: emAndamento,
              isSelected: filtroAtual == 'andamento',
              onTap: () => onChanged('andamento')),
          const SizedBox(width: 8),
          _PremiumChip(
              label: l10n.maintenance_completed_count,
              icon: Icons.check_circle_rounded,
              color: OwanyTheme.success,
              count: concluidas,
              isSelected: filtroAtual == 'concluidas',
              onTap: () => onChanged('concluidas')),
        ],
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _PremiumChip({
    required this.label,
    this.icon,
    this.color,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OwanyTheme.primaryOrange;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [chipColor, chipColor.withValues(alpha: 0.75)])
              : null,
          color: isSelected
              ? null
              : OwanyTheme.textMutedColor(context).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : OwanyTheme.textMutedColor(context).withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isSelected ? OwanyTheme.white : chipColor),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                  color: isSelected
                      ? OwanyTheme.white
                      : OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OwanyTheme.white.withValues(alpha: 0.25)
                      : chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                      color: isSelected ? OwanyTheme.white : chipColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM SOLICITAÇÃO CARD  (rich, with urgency stripe + badges)
// =============================================================

class _PremiumSolicitacaoCard extends StatefulWidget {
  final SolicitacaoListaDto solicitacao;
  final Color cor;
  final IconData icone;
  final String statusLabel;
  final String dataLabel;
  final int urgencia; // 0=normal 1=medium 2=high
  final Animation<double> pulseAnimation;

  const _PremiumSolicitacaoCard({
    required this.solicitacao,
    required this.cor,
    required this.icone,
    required this.statusLabel,
    required this.dataLabel,
    required this.urgencia,
    required this.pulseAnimation,
  });

  @override
  State<_PremiumSolicitacaoCard> createState() =>
      _PremiumSolicitacaoCardState();
}

class _PremiumSolicitacaoCardState extends State<_PremiumSolicitacaoCard> {
  bool _pressed = false;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  Color get _urgencyColor {
    if (widget.urgencia == 2) return OwanyTheme.error;
    if (widget.urgencia == 1) return OwanyTheme.warning;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final sol = widget.solicitacao;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/solicitacao-detalhes',
            arguments: sol.id);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: OwanyTheme.borderColor(context)
                  .withValues(alpha: _pressed ? 0.5 : 0.25),
              width: _pressed ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.textMutedColor(context)
                    .withValues(alpha: _pressed ? 0.1 : 0.04),
                blurRadius: _pressed ? 12 : 6,
                offset: Offset(0, _pressed ? 4 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Urgency left stripe (animated pulse for high urgency)
                if (widget.urgencia > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: widget.pulseAnimation,
                      builder: (_, __) => Opacity(
                        opacity: widget.urgencia == 2
                            ? widget.pulseAnimation.value
                            : 0.6,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _urgencyColor,
                                _urgencyColor.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      widget.urgencia > 0 ? 20 : 16, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status circle
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: widget.cor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.cor.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(widget.icone,
                            color: widget.cor, size: 22),
                      ),

                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + high-urgency icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    sol.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          OwanyTheme.textPrimary(context),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                if (widget.urgencia == 2) ...[
                                  const SizedBox(width: 6),
                                  AnimatedBuilder(
                                    animation: widget.pulseAnimation,
                                    builder: (_, __) => Transform.scale(
                                      scale: widget.pulseAnimation.value,
                                      child: Icon(
                                          Icons.priority_high_rounded,
                                          color: OwanyTheme.error,
                                          size: 18),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 7),

                            // Meta badges: apt, bloco, date
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _MetaBadge(
                                    icon: Icons.apartment_rounded,
                                    label:
                                        'Apt ${sol.numeroApartamento}'),
                                if (sol.blocoApartamento.isNotEmpty)
                                  _MetaBadge(
                                      icon: Icons.domain_rounded,
                                      label:
                                          'Bloco ${sol.blocoApartamento}'),
                                _MetaBadge(
                                    icon: Icons.access_time_rounded,
                                    label: widget.dataLabel,
                                    muted: true),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Status + attention badges
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      widget.cor,
                                      widget.cor.withValues(alpha: 0.7),
                                    ]),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.cor
                                            .withValues(alpha: 0.28),
                                        blurRadius: 7,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.statusLabel,
                                    style: const TextStyle(
                                      color: OwanyTheme.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                if (widget.urgencia == 1) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: OwanyTheme.warning
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: OwanyTheme.warning
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons.hourglass_top_rounded,
                                            size: 11,
                                            color: OwanyTheme.warning),
                                        const SizedBox(width: 4),
                                        Text(_tx('Atenção', 'Attention'),
                                            style: TextStyle(
                                                color: OwanyTheme.warning,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded,
                          color: OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.35),
                          size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _MetaBadge(
      {required this.icon, required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? Colors.transparent
            : OwanyTheme.primaryOrange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: muted
                  ? OwanyTheme.textMutedColor(context)
                  : OwanyTheme.primaryOrange),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                color: muted
                    ? OwanyTheme.textMutedColor(context)
                    : OwanyTheme.primaryOrange,
              )),
        ],
      ),
    );
  }
}

// =============================================================
// SHIMMER SKELETON LOADER  (gradient sweep animation)
// =============================================================

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

  Widget _block(double h, {double? w, double radius = 12}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.10),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.22),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.10),
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
          _block(56, radius: 20),
          const SizedBox(height: 12),
          _block(50, radius: 16),
          const SizedBox(height: 12),
          _block(44, radius: 20),
          const SizedBox(height: 20),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _block(110, radius: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// EMPTY STATE
// =============================================================

class _EmptyState extends StatelessWidget {
  final String filtroStatus;
  final String searchQuery;

  const _EmptyState(
      {required this.filtroStatus, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
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
                  OwanyTheme.accent.withValues(alpha: 0.06),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.inbox_outlined,
                size: 60,
                color: OwanyTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 22),
            Text(l10n.maintenance_empty,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context))),
            const SizedBox(height: 8),
            Text(
              filtroStatus == 'todas'
                  ? l10n.maintenance_empty_create_hint
                  : l10n.maintenance_empty_filter_hint,
              style: TextStyle(
                  fontSize: 14, color: OwanyTheme.textMutedColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final offline = NetworkErrorHelper.isServerOffline(message);
    final accent = offline ? OwanyTheme.warning : OwanyTheme.error;
    final icon =
        offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded;
    final title = offline
        ? NetworkErrorHelper.offlineTitle()
        : l10n.maintenance_error_loading;
    final detail = offline ? NetworkErrorHelper.offlineMessage() : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 62, color: accent),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context))),
            const SizedBox(height: 12),
            Text(detail,
                style: TextStyle(
                    fontSize: 14,
                    color: OwanyTheme.textMutedColor(context)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: OwanyTheme.white),
              label: Text(l10n.common_retry,
                  style: const TextStyle(
                      color: OwanyTheme.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
