// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme/owany_theme.dart';
import '../../models/dtos_complementares.dart';
import '../../providers/manutencao_preventiva_provider.dart';
import '../../providers/language_provider.dart';
import '../../generated_l10n/app_localizations.dart';

// =============================================================
// MANUTENCAO PREVENTIVA DETALHES — PREMIUM PRO VERSION 2.0
// Features: Glass AppBar, Staggered Animations, Gradient Cards,
//           Premium Tabs, Timeline — mirrors ApartmentsScreen
// =============================================================

class ManutencaoPreventivaDetalhesScreen extends StatefulWidget {
  final String manutencaoId;

  const ManutencaoPreventivaDetalhesScreen({
    super.key,
    required this.manutencaoId,
  });

  @override
  State<ManutencaoPreventivaDetalhesScreen> createState() =>
      _ManutencaoPreventivaDetalhesScreenState();
}

class _ManutencaoPreventivaDetalhesScreenState
    extends State<ManutencaoPreventivaDetalhesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final _scrollOffset = ValueNotifier<double>(0);
  final _scrollCtrl = ScrollController();

  String _historicoFiltro = 'todos';

  static final FilteringTextInputFormatter _moneyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'));

  double? _parseMzn(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final sanitized = text.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (sanitized.isEmpty) return null;
    final hasComma = sanitized.contains(',');
    final hasDot = sanitized.contains('.');
    String normalized = sanitized;
    if (hasComma && hasDot) {
      normalized = sanitized.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      normalized = sanitized.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  /// Returns true when the maintenance is one-time (pontual) and already has
  /// at least one execution recorded – meaning it should NOT be concluded again.
  bool _isPontualJaConcluida(ManutencaoPreventivaDto m) {
    final freq = m.frequencia.trim().toLowerCase();
    final isPontual = freq.isEmpty || freq == 'pontual';
    return isPontual && m.totalExecucoes > 0;
  }

  /// Simple locale helper – returns [pt] for Portuguese, [en] for English.
  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));
    _contentFade = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _scrollCtrl.addListener(() {
      if (mounted) {
        _scrollOffset.value = _scrollCtrl.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ManutencaoPreventivaProvider>();
        provider.carregarManutencao(widget.manutencaoId);
        provider.carregarHistorico(widget.manutencaoId);
        _headerAnimController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _contentAnimController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    _scrollCtrl.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  // ── AppBar opacity ────────────────────────────────────────────────────────

  double _appBarOpacity(double offset) => (offset / 100).clamp(0.0, 1.0);

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManutencaoPreventivaProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, _) {
        final manutencao = provider.manutencaoAtual;

        // Loading state
        if (provider.isLoading && manutencao == null) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _buildGlassAppBar(context, opacity: 0),
            body: _PremiumSkeletonLoader(),
          );
        }

        // Error / not found state
        if (manutencao == null) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _buildGlassAppBar(context, opacity: 1),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: OwanyTheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded,
                        size: 48, color: OwanyTheme.error),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.erro ??
                        AppLocalizations.of(context)!.mp_not_found,
                    style: TextStyle(
                        fontSize: 16,
                        color: OwanyTheme.textMutedColor(context)),
                  ),
                ],
              ),
            ),
          );
        }

        final statusColor = manutencao.vencida
            ? OwanyTheme.error
            : manutencao.alerta
                ? OwanyTheme.warning
                : OwanyTheme.success;

        return ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (_, offset, __) => Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: OwanyTheme.backgroundColor(context),
            appBar: _buildGlassAppBar(
              context,
              opacity: _appBarOpacity(offset),
              statusColor: statusColor,
            ),
            body: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
              // Space for glass app bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),

              // ── Status Hero Banner ──
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _PremiumStatusHero(
                        manutencao: manutencao,
                        statusColor: statusColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Premium Tab Bar ──
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _PremiumTabBar(
                      controller: _tabController,
                      context: context,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Tab Content ──
              SliverFillRemaining(
                hasScrollBody: true,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInformacoes(context, manutencao, statusColor),
                        _buildHistorico(
                          context,
                          manutencao,
                          provider.historicos,
                          erro: provider.erro,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Glass App Bar ─────────────────────────────────────────────────────────

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    required double opacity,
    Color? statusColor,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.primaryOrange
                      .withValues(alpha: 0.75 + (opacity * 0.2)),
                  OwanyTheme.accent.withValues(alpha: 0.65 + (opacity * 0.3)),
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
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.build_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.mp_details_title,
                            style: TextStyle(
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Detalhes e histórico',
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
                    if (statusColor != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Activo',
                              style: TextStyle(
                                color:
                                    OwanyTheme.adaptiveTextOverlay(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
      ),
    );
  }

  // ── Informações tab ───────────────────────────────────────────────────────

  Widget _buildInformacoes(
    BuildContext context,
    ManutencaoPreventivaDto manutencao,
    Color statusColor,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General info card
          _buildPremiumSection(
            context,
            title: l10n.mp_info_general,
            icon: Icons.info_outline_rounded,
            color: OwanyTheme.primaryOrange,
            children: [
              _PremiumDetailRow(
                  label: l10n.mp_title, value: manutencao.titulo),
              _PremiumDetailRow(
                  label: l10n.mp_type, value: manutencao.tipo),
              _PremiumDetailRow(
                  label: l10n.mp_frequency, value: manutencao.frequencia),
              _PremiumDetailRow(
                label: l10n.mp_status,
                value: manutencao.ativa
                    ? l10n.mp_active
                    : l10n.mp_inactive,
                valueColor:
                    manutencao.ativa ? OwanyTheme.success : OwanyTheme.error,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Schedule card
          _buildPremiumSection(
            context,
            title: l10n.mp_schedule,
            icon: Icons.calendar_today_rounded,
            color: OwanyTheme.info,
            children: [
              _PremiumDetailRow(
                label: l10n.mp_next_maintenance,
                value: _formatarData(manutencao.proximaManutencao),
              ),
              _PremiumDetailRow(
                label: l10n.mp_last_maintenance,
                value: manutencao.ultimaManutencao != null
                    ? _formatarData(manutencao.ultimaManutencao!)
                    : l10n.mp_never_executed,
              ),
              _PremiumDetailRow(
                label: l10n.mp_total_executions,
                value: '${manutencao.totalExecucoes}',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Costs & supplier
          _buildPremiumSection(
            context,
            title: l10n.mp_costs_supplier,
            icon: Icons.attach_money_rounded,
            color: OwanyTheme.success,
            children: [
              _PremiumDetailRow(
                label: l10n.mp_estimated_cost,
                value: _formatMzn(manutencao.custoEstimado ?? 0.0),
              ),
              _PremiumDetailRow(
                label: l10n.mp_supplier,
                value: manutencao.fornecedor ?? l10n.common_not_available,
              ),
              _PremiumDetailRow(
                label: l10n.mp_phone,
                value: manutencao.telefoneFornecedor ??
                    l10n.common_not_available,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsible
          _buildPremiumSection(
            context,
            title: l10n.mp_responsible,
            icon: Icons.person_rounded,
            color: OwanyTheme.warning,
            children: [
              _PremiumDetailRow(
                label: l10n.mp_name,
                value: manutencao.responsavelNome ?? l10n.mp_not_assigned,
              ),
              _PremiumDetailRow(
                  label: l10n.mp_created_by,
                  value: manutencao.criadoPorNome),
              if (manutencao.atualizadoPorNome != null)
                _PremiumDetailRow(
                  label: l10n.mp_last_update,
                  value: _formatarData(
                      manutencao.atualizadoEm ?? DateTime.now()),
                ),
            ],
          ),

          // Description
          if (manutencao.descricao != null &&
              manutencao.descricao!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildTextCard(
              context,
              title: l10n.mp_description,
              text: manutencao.descricao!,
              icon: Icons.description_rounded,
              color: OwanyTheme.primaryOrange,
            ),
          ],

          // Observations
          if (manutencao.observacoes != null &&
              manutencao.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildTextCard(
              context,
              title: l10n.mp_notes,
              text: manutencao.observacoes!,
              icon: Icons.sticky_note_2_rounded,
              color: OwanyTheme.warning,
              accentBg: true,
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _GradientButton(
                  label: l10n.mp_edit,
                  icon: Icons.edit_rounded,
                  gradient: const LinearGradient(
                    colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/manutencoes-preventivas-editar',
                    arguments: manutencao.id,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isPontualJaConcluida(manutencao)
                    ? _GradientButton(
                        label: _tx('Já concluída', 'Already completed'),
                        icon: Icons.check_circle_rounded,
                        gradient: LinearGradient(
                          colors: [
                            OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
                            OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
                          ],
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_tx(
                              'Manutenção pontual já foi concluída. Não é possível registrar nova execução.',
                              'One-time maintenance already completed. Cannot register another execution.',
                            )),
                            backgroundColor: OwanyTheme.warning,
                          ));
                        },
                      )
                    : _GradientButton(
                        label: l10n.mp_conclude,
                        icon: Icons.check_rounded,
                        gradient: LinearGradient(
                          colors: [
                            OwanyTheme.success,
                            OwanyTheme.success.withValues(alpha: 0.8),
                          ],
                        ),
                        onTap: () => _showConcluirDialog(context, manutencao),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Histórico tab ─────────────────────────────────────────────────────────

  Widget _buildHistorico(
    BuildContext context,
    ManutencaoPreventivaDto manutencao,
    List<HistoricoManutencaoPreventivaDto> historicos, {
    String? erro,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final historicosOrdenados = [...historicos]
      ..sort((a, b) => b.dataRealizacao.compareTo(a.dataRealizacao));
    final historicosFiltrados = historicosOrdenados.where((item) {
      switch (_historicoFiltro) {
        case 'concluidas':
          return _isConcluida(item);
        case 'canceladas':
          return _isCancelada(item);
        case 'andamento':
          return _isEmAndamento(item);
        default:
          return true;
      }
    }).toList();

    if (historicosOrdenados.isEmpty) {
      final houveErro = erro != null && erro.trim().isNotEmpty;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_rounded,
                    size: 48,
                    color: OwanyTheme.textMutedColor(context)),
              ),
              const SizedBox(height: 20),
              Text(
                houveErro ? erro : l10n.mp_history_empty,
                style: TextStyle(
                  fontSize: 16,
                  color: OwanyTheme.textMutedColor(context),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (houveErro) ...[
                const SizedBox(height: 16),
                _GradientButton(
                  label: l10n.common_refresh,
                  icon: Icons.refresh_rounded,
                  gradient: const LinearGradient(
                      colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
                  onTap: () => context
                      .read<ManutencaoPreventivaProvider>()
                      .carregarHistorico(widget.manutencaoId),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline summary
          _buildTimelineSummary(context, manutencao, l10n),
          const SizedBox(height: 20),

          const SizedBox(height: 12),

          // Conclude button (disabled for pontual already concluded)
          if (_isPontualJaConcluida(manutencao))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: OwanyTheme.success),
                  const SizedBox(width: 8),
                  Text(
                    _tx('Manutenção pontual já concluída', 'One-time maintenance completed'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            )
          else
            _GradientButton(
              label: l10n.mp_conclude_execution,
              icon: Icons.check_rounded,
              gradient: LinearGradient(
                colors: [OwanyTheme.success, OwanyTheme.success.withValues(alpha: 0.8)],
              ),
              fullWidth: true,
              onTap: () => _showConcluirDialog(context, manutencao),
            ),

        if (historicosOrdenados.isNotEmpty) ...[
          const SizedBox(height: 24),

            // Section header
            _PremiumSectionHeader(
              title: l10n.mp_detailed_history,
              icon: Icons.history_rounded,
              color: OwanyTheme.primaryOrange,
            ),
            const SizedBox(height: 12),

            // History items with stagger
          ...historicosFiltrados.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 250 + (index * 50)),
                curve: Curves.easeOut,
                builder: (ctx, value, child) => Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: Opacity(
                      opacity: value.clamp(0.0, 1.0), child: child),
                ),
                child: _buildHistoricoItem(context, item, l10n),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Timeline summary ──────────────────────────────────────────────────────

  Widget _buildTimelineSummary(
    BuildContext context,
    ManutencaoPreventivaDto manutencao,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Column(
            children: [
              Text(
                l10n.mp_last_executions,
                style: TextStyle(
                  color:
                      OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimelineStat(
                      icon: Icons.check_circle_rounded,
                      label: l10n.mp_last_execution,
                      value: manutencao.ultimaExecucao != null
                          ? _formatarDataShort(manutencao.ultimaExecucao!)
                          : l10n.mp_never_executed,
                      color: OwanyTheme.success,
                      overlayContext: context,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                  ),
                  Expanded(
                    child: _TimelineStat(
                      icon: Icons.schedule_rounded,
                      label: l10n.mp_next_execution,
                      value: _formatarDataShort(manutencao.proximaManutencao),
                      color: Colors.white,
                      overlayContext: context,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                  ),
                  Expanded(
                    child: _TimelineStat(
                      icon: Icons.repeat_rounded,
                      label: l10n.mp_total_executions,
                      value: '${manutencao.totalExecucoes}×',
                      color: Colors.white,
                      overlayContext: context,
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

  // ── History item card ─────────────────────────────────────────────────────

  Widget _buildHistoricoItem(
    BuildContext context,
    HistoricoManutencaoPreventivaDto item,
    AppLocalizations l10n,
  ) {
    final statusLabel = _statusDisplayLabel(item.status, l10n);
    final statusColor = _statusColor(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Accent stripe + header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                statusColor.withValues(alpha: 0.08),
                statusColor.withValues(alpha: 0.02),
              ]),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      statusColor,
                      statusColor.withValues(alpha: 0.8),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OwanyTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: OwanyTheme.borderColor(context)),
                  ),
                  child: Text(
                    _formatarDataShort(item.dataRealizacao),
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.textMutedColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.descricaoExecucao != null &&
                    item.descricaoExecucao!.isNotEmpty) ...[
                  Text(
                    item.descricaoExecucao!,
                    style: TextStyle(
                      fontSize: 14,
                      color: OwanyTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 14,
                          color: OwanyTheme.primaryOrange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.realizadoPorNome,
                        style: TextStyle(
                          fontSize: 12,
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.custoReal != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OwanyTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: OwanyTheme.success
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          _formatMzn(item.custoReal!),
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    ],
                  ),
                if (item.realizadoPorId != null &&
                    item.realizadoPorId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color:
                              OwanyTheme.primaryBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.badge_rounded,
                            size: 14, color: OwanyTheme.primaryBrown),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          'ID Responsável: ${item.realizadoPorId!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OwanyTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: OwanyTheme.borderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow(
                        context,
                        _tx('Realizado em', 'Executed on'),
                        _formatarData(item.dataRealizacao),
                      ),
                      _buildMetaRow(
                        context,
                        _tx('Criado em', 'Created on'),
                        _formatarData(item.criadoEm),
                      ),
                      // IDs removed from UI (maintenance/execution IDs not shown)
                    ],
                  ),
                ),
                if (item.observacoes != null &&
                    item.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OwanyTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: OwanyTheme.borderColor(context)),
                    ),
                    child: Text(
                      item.observacoes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (item.notaFiscal != null &&
                    item.notaFiscal!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: OwanyTheme.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            size: 14, color: OwanyTheme.info),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.mp_invoice_label}: ${item.notaFiscal!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.fotosAntes != null &&
                    item.fotosAntes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: OwanyTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.photo_camera_back_outlined,
                            size: 14, color: OwanyTheme.warning),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fotos antes (${item.fotosAntes!.length})',
                              style: TextStyle(
                                fontSize: 12,
                                color: OwanyTheme.textMutedColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ...item.fotosAntes!.map((url) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: SelectableText(
                                url,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OwanyTheme.info,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 5,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.fotosDepois != null &&
                    item.fotosDepois!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: OwanyTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.photo_camera_front_outlined,
                            size: 14, color: OwanyTheme.success),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fotos depois (${item.fotosDepois!.length})',
                              style: TextStyle(
                                fontSize: 12,
                                color: OwanyTheme.textMutedColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ...item.fotosDepois!.map((url) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: SelectableText(
                                url,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OwanyTheme.info,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 5,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.solicitacaoId != null &&
                    item.solicitacaoId!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.link_rounded,
                            size: 14, color: OwanyTheme.primaryOrange),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          'Solicitação: ${item.solicitacaoId!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(HistoricoManutencaoPreventivaDto item) {
    final code = item.statusCodigo;
    if (code == 2) return OwanyTheme.success;
    if (code == 1) return OwanyTheme.error;
    if (code == 0) return OwanyTheme.warning;
    final statusLower = item.status.toLowerCase();
    if (statusLower.contains('concl')) return OwanyTheme.success;
    if (statusLower.contains('cancel')) return OwanyTheme.error;
    if (statusLower.contains('andamento')) return OwanyTheme.warning;
    return OwanyTheme.info;
  }

  String _statusDisplayLabel(String status, AppLocalizations l10n) {
    final normalized = status.trim();
    if (normalized.isEmpty) return _tx('Desconhecido', 'Unknown');
    final lower = normalized.toLowerCase();
    if (lower.contains('concl')) return l10n.mp_status_concluida;
    if (lower.contains('cancel')) return l10n.mp_status_cancelada;
    if (lower.contains('andamento') || lower.contains('progress')) {
      return l10n.mp_status_em_andamento;
    }
    return normalized;
  }

  bool _isConcluida(HistoricoManutencaoPreventivaDto item) {
    if (item.statusCodigo == 2) return true;
    final lower = item.status.toLowerCase();
    return lower.contains('concl');
  }

  bool _isCancelada(HistoricoManutencaoPreventivaDto item) {
    if (item.statusCodigo == 1) return true;
    final lower = item.status.toLowerCase();
    return lower.contains('cancel');
  }

  bool _isEmAndamento(HistoricoManutencaoPreventivaDto item) {
    if (item.statusCodigo == 0) return true;
    final lower = item.status.toLowerCase();
    return lower.contains('andamento') || lower.contains('progress');
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: OwanyTheme.textMutedColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 11,
                color: OwanyTheme.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // (History summary and filters removed per request)

  // ── Premium section builder ───────────────────────────────────────────────

  Widget _buildPremiumSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with gradient stripe
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.03),
              ]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children.asMap().entries.map((e) {
                return Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1) ...[
                      const SizedBox(height: 2),
                      Divider(
                        color: OwanyTheme.borderColor(context)
                            .withValues(alpha: 0.5),
                        height: 20,
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(
    BuildContext context, {
    required String title,
    required String text,
    required IconData icon,
    required Color color,
    bool accentBg = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accentBg ? color.withValues(alpha: 0.06) : OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: OwanyTheme.textPrimary(context),
                    )),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentBg
                  ? color.withValues(alpha: 0.08)
                  : OwanyTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withValues(alpha: accentBg ? 0.25 : 0.15)),
            ),
            child: Text(text,
                style: TextStyle(
                  fontSize: 13,
                  color: accentBg ? color : OwanyTheme.textMutedColor(context),
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }

  // ── Conclude Dialog ───────────────────────────────────────────────────────

  Future<void> _showConcluirDialog(
    BuildContext context,
    ManutencaoPreventivaDto manutencao,
  ) async {
    final rootContext = context;
    final descricaoController = TextEditingController();
    final custoController = TextEditingController();
    final comentarioController = TextEditingController();
    final notaFiscalController = TextEditingController();

    String statusSelecionado = 'Concluida';
    DateTime dataSelecionada = DateTime.now();

    HapticFeedback.mediumImpact();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;

            Color _statusBtnColor() {
              if (statusSelecionado == 'Cancelada') return OwanyTheme.error;
              if (statusSelecionado == 'EmAndamento') return OwanyTheme.warning;
              return OwanyTheme.success;
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor: OwanyTheme.cardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                OwanyTheme.primaryOrange,
                                OwanyTheme.accent,
                              ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: OwanyTheme.primaryOrange
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              l10n.mp_register_execution,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: OwanyTheme.textPrimary(context),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Status
                      _DialogFieldLabel(label: l10n.mp_execution_status),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: OwanyTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: OwanyTheme.borderColor(context)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: statusSelecionado,
                          dropdownColor: OwanyTheme.cardColor(context),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: InputBorder.none,
                          ),
                          items: [
                            _statusDropdownItem('Concluida',
                                l10n.mp_status_concluida,
                                Icons.check_circle_rounded,
                                OwanyTheme.success),
                            _statusDropdownItem('EmAndamento',
                                l10n.mp_status_em_andamento,
                                Icons.autorenew_rounded, OwanyTheme.warning),
                            _statusDropdownItem('Cancelada',
                                l10n.mp_status_cancelada,
                                Icons.cancel_rounded, OwanyTheme.error),
                          ],
                          onChanged: (val) =>
                              setState(() => statusSelecionado = val!),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date picker
                      _DialogFieldLabel(label: l10n.mp_execution_date),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataSelecionada,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: ColorScheme.light(
                                      primary: OwanyTheme.primaryOrange),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setState(() => dataSelecionada = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: OwanyTheme.surfaceColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: OwanyTheme.borderColor(context)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.primaryOrange
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.calendar_today_rounded,
                                      size: 16,
                                      color: OwanyTheme.primaryOrange),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(dataSelecionada),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: OwanyTheme.textPrimary(context),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18,
                                    color:
                                        OwanyTheme.textMutedColor(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _DialogFieldLabel(label: l10n.mp_done_what),
                      const SizedBox(height: 8),
                      _PremiumTextField(
                          controller: descricaoController,
                          hint: l10n.mp_done_hint,
                          minLines: 2, maxLines: 4),
                      const SizedBox(height: 16),

                      // Comments
                      _DialogFieldLabel(label: l10n.mp_additional_comments),
                      const SizedBox(height: 8),
                      _PremiumTextField(
                          controller: comentarioController,
                          hint: l10n.mp_comments_hint,
                          minLines: 2, maxLines: 3),
                      const SizedBox(height: 16),

                      // Cost
                      _DialogFieldLabel(label: l10n.mp_real_cost_optional),
                      const SizedBox(height: 8),
                      _PremiumTextField(
                        controller: custoController,
                        hint: l10n.mp_cost_hint,
                        prefixText: l10n.mp_currency_prefix,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_moneyInputFormatter],
                      ),
                      const SizedBox(height: 16),

                      // Invoice
                      _DialogFieldLabel(label: l10n.mp_invoice),
                      const SizedBox(height: 8),
                      _PremiumTextField(
                          controller: notaFiscalController,
                          hint: l10n.mp_invoice_hint),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(
                                    color: OwanyTheme.borderColor(context)),
                              ),
                              child: Text(l10n.common_cancel,
                                  style: TextStyle(
                                    color:
                                        OwanyTheme.textMutedColor(context),
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  _statusBtnColor(),
                                  _statusBtnColor()
                                      .withValues(alpha: 0.8),
                                ]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _statusBtnColor()
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setState(() => isSaving = true);

                                        final custoTexto =
                                            custoController.text.trim();
                                        final custo =
                                            _parseMzn(custoTexto);
                                        if (custoTexto.isNotEmpty &&
                                            custo == null) {
                                          if (mounted) {
                                            setState(
                                                () => isSaving = false);
                                          }
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                                    rootContext)
                                                .showSnackBar(
                                              OwanyTheme.snackBar(
                                                'Informe um custo válido em MZN.',
                                                type: SnackBarType.error,
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final request =
                                            RegistrarExecucaoManutencaoRequest(
                                          dataRealizacao:
                                              dataSelecionada,
                                          status: statusSelecionado,
                                          custoReal: custo,
                                          descricaoExecucao: descricaoController
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : descricaoController.text
                                                  .trim(),
                                          observacoes: comentarioController
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : comentarioController.text
                                                  .trim(),
                                          notaFiscal: notaFiscalController
                                                  .text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : notaFiscalController.text
                                                  .trim(),
                                        );

                                        final provider = rootContext
                                            .read<ManutencaoPreventivaProvider>();
                                        final sucesso =
                                            await provider
                                                .registrarExecucao(
                                          manutencao.id,
                                          request,
                                        );

                                        if (!rootContext.mounted) return;

                                        if (sucesso) {
                                          await provider
                                              .carregarManutencao(
                                                  manutencao.id);
                                          await provider
                                              .carregarHistorico(
                                                  manutencao.id);
                                          if (rootContext.mounted) {
                                            Navigator.pop(context);
                                          }
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                                    rootContext)
                                                .showSnackBar(
                                              OwanyTheme.snackBar(
                                                l10n.mp_execution_saved,
                                                type: SnackBarType.success,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            setState(
                                                () => isSaving = false);
                                          }
                                          if (rootContext.mounted) {
                                            ScaffoldMessenger.of(
                                                    rootContext)
                                                .showSnackBar(
                                              OwanyTheme.snackBar(
                                                provider.erro ??
                                                    l10n.mp_execution_error,
                                                type: SnackBarType.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(l10n.mp_save_execution,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  DropdownMenuItem<String> _statusDropdownItem(
      String value, String label, IconData icon, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  // ── Formatters ────────────────────────────────────────────────────────────

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy • HH:mm').format(data);
  }

  String _formatarDataShort(DateTime data) {
    return DateFormat('dd/MM/yy').format(data);
  }

  String _formatMzn(double valor) {
    final formatter = NumberFormat.currency(locale: 'pt_PT', symbol: '', decimalDigits: 2);
    return 'MZN ${formatter.format(valor).trim()}';
  }
}

// =============================================================
// PREMIUM STATUS HERO CARD
// =============================================================

class _PremiumStatusHero extends StatefulWidget {
  final ManutencaoPreventivaDto manutencao;
  final Color statusColor;

  const _PremiumStatusHero({
    required this.manutencao,
    required this.statusColor,
  });

  @override
  State<_PremiumStatusHero> createState() => _PremiumStatusHeroState();
}

class _PremiumStatusHeroState extends State<_PremiumStatusHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.manutencao;
    final color = widget.statusColor;
    final daysLabel = m.vencida
        ? l10n.mp_status_overdue
        : '${m.diasFaltantes} ${l10n.common_days}';

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _anim,
                          builder: (_, __) {
                            final pct = (m.diasFaltantes <= 0
                                ? 1.0
                                : 1.0 -
                                    (m.diasFaltantes / 30.0)
                                        .clamp(0.0, 1.0));
                            return CustomPaint(
                              painter: _CirclePainter(
                                percent: pct * _anim.value,
                                color: color,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      m.vencida ? '!' : '${m.diasFaltantes}',
                                      style: TextStyle(
                                        color: OwanyTheme.textPrimary(context),
                                        fontWeight: FontWeight.w900,
                                        fontSize: m.vencida ? 26 : 20,
                                        height: 1,
                                      ),
                                    ),
                                    if (!m.vencida)
                                      Text(
                                        'dias',
                                        style: TextStyle(
                                          color: OwanyTheme.textMutedColor(context),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.titulo,
                              style: TextStyle(
                                color: OwanyTheme.textPrimary(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    daysLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.category_rounded,
                                  size: 12,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${m.tipo} • ${m.frequencia}',
                                    style: TextStyle(
                                      color: OwanyTheme.textMutedColor(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// CIRCLE PAINTER
// =============================================================

class _CirclePainter extends CustomPainter {
  final double percent;
  final Color color;

  _CirclePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: 0.5)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

// =============================================================
// PREMIUM TAB BAR
// =============================================================

class _PremiumTabBar extends StatelessWidget {
  final TabController controller;
  final BuildContext context;

  const _PremiumTabBar({required this.controller, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: OwanyTheme.textMutedColor(context),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.apartments_detailed_info),
          Tab(text: AppLocalizations.of(context)!.common_history),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM SECTION HEADER (standalone)
// =============================================================

class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _PremiumSectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: OwanyTheme.textPrimary(context),
              letterSpacing: -0.2,
            )),
      ],
    );
  }
}

// =============================================================
// PREMIUM DETAIL ROW
// =============================================================

class _PremiumDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PremiumDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? OwanyTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// TIMELINE STAT
// =============================================================

class _TimelineStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final BuildContext overlayContext;

  const _TimelineStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.overlayContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: OwanyTheme.adaptiveOverlay(overlayContext, opacity: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(overlayContext),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center),
        Text(label,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(overlayContext)
                  .withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// =============================================================
// GRADIENT BUTTON
// =============================================================

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}

// =============================================================
// DIALOG FIELD LABEL
// =============================================================

class _DialogFieldLabel extends StatelessWidget {
  final String label;

  const _DialogFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: OwanyTheme.textMutedColor(context),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

// =============================================================
// PREMIUM TEXT FIELD
// =============================================================

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
          fontSize: 13, color: OwanyTheme.textPrimary(context)),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: TextStyle(
            color: OwanyTheme.textMutedColor(context),
            fontSize: 13),
        filled: true,
        fillColor: OwanyTheme.surfaceColor(context),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OwanyTheme.borderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: OwanyTheme.borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: OwanyTheme.primaryOrange, width: 1.5),
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM SKELETON LOADER
// =============================================================

class _PremiumSkeletonLoader extends StatefulWidget {
  @override
  State<_PremiumSkeletonLoader> createState() =>
      _PremiumSkeletonLoaderState();
}

class _PremiumSkeletonLoaderState extends State<_PremiumSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final opacity = 0.3 + (_ctrl.value * 0.35);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 130, 20, 40),
          child: Column(
            children: [
              _skeletonBox(height: 120, opacity: opacity,
                  radius: 24,
                  gradient: true),
              const SizedBox(height: 16),
              _skeletonBox(height: 44, opacity: opacity, radius: 16),
              const SizedBox(height: 16),
              ...List.generate(3, (i) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _skeletonBox(
                        height: 110,
                        opacity: opacity * (1 - i * 0.07),
                        radius: 20),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonBox({
    required double height,
    required double opacity,
    double radius = 12,
    bool gradient = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient
            ? LinearGradient(
                colors: [
                  OwanyTheme.primaryOrange.withValues(alpha: opacity),
                  OwanyTheme.accent.withValues(alpha: opacity * 0.7),
                ],
              )
            : null,
        color: gradient
            ? null
            : OwanyTheme.textMutedColor(context).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
