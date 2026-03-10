import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../models/dtos_complementares.dart';
import '../../providers/manutencao_preventiva_provider.dart';

// =============================================================
// MANUTENÇÃO ALERTAS SCREEN — PREMIUM PRO VERSION 2.0
// Features: Glassmorphism, Staggered Animations, Advanced Stats
// Mirrors ApartmentsScreen visual language exactly
// =============================================================

class ManutencaoAlertasScreen extends StatefulWidget {
  const ManutencaoAlertasScreen({super.key});

  @override
  State<ManutencaoAlertasScreen> createState() =>
      _ManutencaoAlertasScreenState();
}

class _ManutencaoAlertasScreenState extends State<ManutencaoAlertasScreen>
    with TickerProviderStateMixin {
  String _filtro = 'todas';

  late AnimationController _headerAnimController;
  late AnimationController _statsAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

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

    Future.microtask(() => _load());
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _statsAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _load({bool forceReload = false}) async {
    _headerAnimController.reset();
    _statsAnimController.reset();
    final provider = context.read<ManutencaoPreventivaProvider>();
    // Evita reload desnecessário se já temos dados (ex: voltar à tela)
    if (!forceReload && provider.manutencoes.isNotEmpty) {
      _headerAnimController.forward();
      _statsAnimController.forward();
      return;
    }
    await provider.carregarManutencoes();
    if (mounted) {
      _headerAnimController.forward();
      _statsAnimController.forward();
    }
  }

  // ── categorisation ────────────────────────────────────────────────────────

  List<ManutencaoPreventivaDto> _vencidas(List<ManutencaoPreventivaDto> all) =>
      all.where((m) => m.vencida).toList();

  List<ManutencaoPreventivaDto> _emAlerta(List<ManutencaoPreventivaDto> all) =>
      all.where((m) => m.alerta && !m.vencida).toList();

  List<ManutencaoPreventivaDto> _proximas(List<ManutencaoPreventivaDto> all) =>
      all
          .where((m) =>
              !m.vencida && !m.alerta && m.ativa && m.diasFaltantes <= 30)
          .toList();

  List<ManutencaoPreventivaDto> _normais(List<ManutencaoPreventivaDto> all) =>
      all
          .where((m) =>
              !m.vencida && !m.alerta && m.ativa && m.diasFaltantes > 30)
          .toList();

  // ── list content builder ──────────────────────────────────────────────────

  List<Widget> _buildContent({
    required AppLocalizations l10n,
    required List<ManutencaoPreventivaDto> vencidas,
    required List<ManutencaoPreventivaDto> emAlerta,
    required List<ManutencaoPreventivaDto> proximas,
    required List<ManutencaoPreventivaDto> normais,
    required List<ManutencaoPreventivaDto> all,
  }) {
    final widgets = <Widget>[];
    int sectionIndex = 0;

    void section(
      String title,
      String subtitle,
      Color color,
      IconData icon,
      List<ManutencaoPreventivaDto> list,
      String emptyMsg,
    ) {
      if (list.isNotEmpty) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
        widgets.add(_SectionHeader(
          title: title,
          subtitle: subtitle,
          color: color,
          icon: icon,
          count: list.length,
        ));
        widgets.add(const SizedBox(height: 10));
        for (int i = 0; i < list.length; i++) {
          widgets.add(TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + ((sectionIndex + i) * 40)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              final clamped = value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: clamped, child: child),
              );
            },
            child: _PremiumMaintenanceCard(manutencao: list[i]),
          ));
        }
        sectionIndex += list.length;
        widgets.add(const SizedBox(height: 4));
      } else if (_filtro != 'todas') {
        widgets.add(_EmptyState(message: emptyMsg));
      }
    }

    switch (_filtro) {
      case 'vencidas':
        section(l10n.mp_alerts_overdue, l10n.mp_alerts_overdue_subtitle,
            OwanyTheme.error, Icons.warning_rounded, vencidas,
            l10n.mp_alerts_none_overdue);
        break;
      case 'alertas':
        section(l10n.mp_alerts_in_alert, l10n.mp_alerts_in_alert_subtitle,
            OwanyTheme.warning, Icons.notification_important_rounded, emAlerta,
            l10n.mp_alerts_none_in_alert);
        break;
      case 'proximas':
        section(l10n.mp_alerts_upcoming, l10n.mp_alerts_upcoming_subtitle,
            OwanyTheme.primaryOrange, Icons.schedule_rounded, proximas,
            l10n.mp_alerts_none_upcoming);
        break;
      default:
        if (all.isEmpty) {
          widgets.add(_EmptyState(message: l10n.mp_alerts_none_registered));
          break;
        }
        if (vencidas.isNotEmpty)
          section(l10n.mp_alerts_overdue, l10n.mp_alerts_overdue_subtitle,
              OwanyTheme.error, Icons.warning_rounded, vencidas, '');
        if (emAlerta.isNotEmpty)
          section(
              l10n.mp_alerts_in_alert,
              l10n.mp_alerts_in_alert_subtitle,
              OwanyTheme.warning,
              Icons.notification_important_rounded,
              emAlerta,
              '');
        if (proximas.isNotEmpty)
          section(
              l10n.mp_alerts_upcoming,
              l10n.mp_alerts_upcoming_subtitle,
              OwanyTheme.primaryOrange,
              Icons.schedule_rounded,
              proximas,
              '');
        if (normais.isNotEmpty)
          section(l10n.mp_alerts_planned, l10n.mp_alerts_planned_subtitle,
              OwanyTheme.success, Icons.check_circle_rounded, normais, '');
    }

    return widgets;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ManutencaoPreventivaProvider>();
    final all = provider.manutencoes;

    final vencidas = _vencidas(all);
    final emAlerta = _emAlerta(all);
    final proximas = _proximas(all);
    final normais = _normais(all);

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _GlassAppBar(scrollOffset: _scrollOffset, l10n: l10n),
      ),
      body: provider.isLoadingLista
          ? _PremiumSkeletonLoader()
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await _load(forceReload: true);
              },
              color: OwanyTheme.primaryOrange,
              backgroundColor: OwanyTheme.cardColor(context),
              strokeWidth: 3,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // Space for glass app bar
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),

                  // ── Premium Dashboard ──
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: SlideTransition(
                        position: _headerSlideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _PremiumDashboard(
                            vencidas: vencidas.length,
                            alertas: emAlerta.length,
                            proximas: proximas.length,
                            normais: normais.length,
                            l10n: l10n,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Filter Bar ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _PremiumFilterBar(
                        selected: _filtro,
                        onSelect: (v) {
                          setState(() => _filtro = v);
                          HapticFeedback.selectionClick();
                        },
                        l10n: l10n,
                        vencidas: vencidas.length,
                        alertas: emAlerta.length,
                        proximas: proximas.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Counter row ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Row(
                        children: [
                          Text(
                            '${_countForFilter(vencidas, emAlerta, proximas, normais, all)} ${_labelForFilter(l10n)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OwanyTheme.textMutedColor(context),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          if (_filtro != 'todas')
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _filtro = 'todas');
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

                  // ── Content ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: Builder(
                      builder: (context) {
                        final contentWidgets = _buildContent(
                          l10n: l10n,
                          vencidas: vencidas,
                          emAlerta: emAlerta,
                          proximas: proximas,
                          normais: normais,
                          all: all,
                        );
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => contentWidgets[index],
                            childCount: contentWidgets.length,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int _countForFilter(
    List<ManutencaoPreventivaDto> vencidas,
    List<ManutencaoPreventivaDto> alertas,
    List<ManutencaoPreventivaDto> proximas,
    List<ManutencaoPreventivaDto> normais,
    List<ManutencaoPreventivaDto> all,
  ) {
    switch (_filtro) {
      case 'vencidas':
        return vencidas.length;
      case 'alertas':
        return alertas.length;
      case 'proximas':
        return proximas.length;
      default:
        return all.length;
    }
  }

  String _labelForFilter(AppLocalizations l10n) {
    switch (_filtro) {
      case 'vencidas':
        return l10n.mp_alerts_overdue.toLowerCase();
      case 'alertas':
        return l10n.mp_alerts_alerts.toLowerCase();
      case 'proximas':
        return l10n.mp_alerts_upcoming.toLowerCase();
      default:
        return 'manutenções';
    }
  }
}

// =============================================================
// GLASS MORPHISM APP BAR
// =============================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final AppLocalizations l10n;

  const _GlassAppBar({required this.scrollOffset, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange
                    .withValues(alpha: 0.8 + (opacity * 0.2)),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.build_circle_rounded,
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.mp_alerts_title,
                        style: TextStyle(
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        l10n.mp_alerts_hero_subtitle,
                        style: TextStyle(
                          color: OwanyTheme.adaptiveTextOverlay(context)
                              .withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
// PREMIUM DASHBOARD WITH CIRCULAR STATS
// =============================================================

class _PremiumDashboard extends StatelessWidget {
  final int vencidas;
  final int alertas;
  final int proximas;
  final int normais;
  final AppLocalizations l10n;

  const _PremiumDashboard({
    required this.vencidas,
    required this.alertas,
    required this.proximas,
    required this.normais,
    required this.l10n,
  });

  int get total => vencidas + alertas + proximas + normais;
  int get urgent => vencidas + alertas;

  double _pct(int v) => total == 0 ? 0 : v / total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
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
                // ── Header row ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.mp_alerts_hero_title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.mp_alerts_hero_subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: OwanyTheme.adaptiveTextOverlay(context)
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: OwanyTheme.adaptiveOverlay(context,
                              opacity: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          Text(
                            l10n.mp_alerts_assets_label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: OwanyTheme.adaptiveTextOverlay(context)
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Circular stats row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AnimatedCircularStat(
                      label: l10n.mp_alerts_overdue,
                      value: vencidas,
                      percent: _pct(vencidas),
                      color: OwanyTheme.error,
                      delay: 0,
                    ),
                    _AnimatedCircularStat(
                      label: l10n.mp_alerts_alerts,
                      value: alertas,
                      percent: _pct(alertas),
                      color: OwanyTheme.warning,
                      delay: 100,
                    ),
                    _AnimatedCircularStat(
                      label: l10n.mp_alerts_upcoming,
                      value: proximas,
                      percent: _pct(proximas),
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      delay: 200,
                    ),
                    _AnimatedCircularStat(
                      label: l10n.mp_alerts_planned,
                      value: normais,
                      percent: _pct(normais),
                      color: OwanyTheme.success,
                      delay: 300,
                    ),
                  ],
                ),

                // ── Urgent alert banner ──
                if (urgent > 0) ...[
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: OwanyTheme.error.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: OwanyTheme.error.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded,
                            size: 16, color: OwanyTheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.mp_alerts_urgent_items(urgent),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: OwanyTheme.error,
                            ),
                          ),
                        ),
                      ],
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

// =============================================================
// ANIMATED CIRCULAR STAT — mirrors ApartmentsScreen exactly
// =============================================================

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
  State<_AnimatedCircularStat> createState() =>
      _AnimatedCircularStatState();
}

class _AnimatedCircularStatState extends State<_AnimatedCircularStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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
          width: 68,
          height: 68,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              return CustomPaint(
                painter: _CirclePainter(
                  percent: widget.percent * _anim.value,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    '${(widget.percent * 100 * _anim.value).round()}%',
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.value}',
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context)
                .withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    const stroke = 7.0;
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

// =============================================================
// PREMIUM FILTER BAR
// =============================================================

class _PremiumFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final AppLocalizations l10n;
  final int vencidas;
  final int alertas;
  final int proximas;

  const _PremiumFilterBar({
    required this.selected,
    required this.onSelect,
    required this.l10n,
    required this.vencidas,
    required this.alertas,
    required this.proximas,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('todas', l10n.mp_list_filter_all, Icons.grid_view_rounded, null, null),
      ('vencidas', l10n.mp_alerts_overdue, Icons.warning_rounded,
          OwanyTheme.error, vencidas),
      ('alertas', l10n.mp_alerts_alerts,
          Icons.notification_important_rounded, OwanyTheme.warning, alertas),
      ('proximas', l10n.mp_alerts_upcoming, Icons.schedule_rounded,
          OwanyTheme.primaryOrange, proximas),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((e) {
          final (key, label, icon, color, count) = e.value;
          final isActive = selected == key;
          final chipColor = color ?? OwanyTheme.primaryOrange;

          return Padding(
            padding:
                EdgeInsets.only(right: e.key < filters.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(key),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(colors: [
                            chipColor,
                            chipColor.withValues(alpha: 0.8)
                          ])
                        : null,
                    color: isActive ? null : OwanyTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? chipColor
                          : OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.3),
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: chipColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 14,
                          color: isActive
                              ? OwanyTheme.white
                              : OwanyTheme.textMutedColor(context)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? OwanyTheme.white
                              : OwanyTheme.textPrimary(context),
                        ),
                      ),
                      if (count != null && count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.25)
                                : chipColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  isActive ? Colors.white : chipColor,
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
        }).toList(),
      ),
    );
  }
}

// =============================================================
// SECTION HEADER
// =============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: OwanyTheme.textMutedColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM MAINTENANCE CARD
// =============================================================

class _PremiumMaintenanceCard extends StatefulWidget {
  final ManutencaoPreventivaDto manutencao;

  const _PremiumMaintenanceCard({required this.manutencao});

  @override
  State<_PremiumMaintenanceCard> createState() =>
      _PremiumMaintenanceCardState();
}

class _PremiumMaintenanceCardState extends State<_PremiumMaintenanceCard> {
  bool _isHovered = false;

  Color get _statusColor {
    if (widget.manutencao.vencida) return OwanyTheme.error;
    if (widget.manutencao.alerta) return OwanyTheme.warning;
    if (widget.manutencao.diasFaltantes <= 30) return OwanyTheme.primaryOrange;
    return OwanyTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.manutencao;
    final sc = _statusColor;

    final localDesc = (m.localDescricao ?? '').trim();
    final isGeral = localDesc.toLowerCase().contains('geral') ||
        localDesc.toLowerCase().contains('condomínio') ||
        localDesc.toLowerCase().contains('condominio');
    final destinoCor = isGeral ? OwanyTheme.primaryOrange : OwanyTheme.info;
    final destinoLabel = isGeral
        ? l10n.mp_alerts_general_condo
        : localDesc.isNotEmpty
            ? localDesc
            : l10n.mp_alerts_apartment;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
            context,
            '/manutencoes-preventivas-detalhes',
            arguments: m.id,
          );
        },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_isHovered ? 1.015 : 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: OwanyTheme.cardColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered
                      ? OwanyTheme.borderColor(context).withValues(alpha: 0.5)
                      : OwanyTheme.borderColor(context).withValues(alpha: 0.25),
                  width: _isHovered ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? OwanyTheme.textMutedColor(context)
                            .withValues(alpha: 0.1)
                        : OwanyTheme.textMutedColor(context)
                            .withValues(alpha: 0.04),
                    blurRadius: _isHovered ? 12 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Left accent stripe
                        Container(
                          width: 5,
                          decoration: BoxDecoration(
                            color: sc,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                          ),
                        ),

                        // Content
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + days badge
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.titulo,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: OwanyTheme.textPrimary(
                                              context),
                                          letterSpacing: -0.2,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Days badge — gradient version
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: sc.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: sc.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '${m.diasFaltantes.abs()}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: sc,
                                              letterSpacing: -0.5,
                                              height: 1,
                                            ),
                                          ),
                                          Text(
                                            m.vencida
                                                ? l10n.mp_alerts_overdue_suffix
                                                : l10n.mp_list_days_suffix,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: sc.withValues(alpha: 0.7),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Status + Destination + tipo chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    // Status badge with gradient
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: sc.withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sc.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        m.vencida
                                            ? l10n.mp_alerts_overdue
                                            : m.alerta
                                                ? l10n.mp_alerts_in_alert
                                                : m.diasFaltantes <= 30
                                                    ? l10n.mp_alerts_upcoming
                                                    : l10n.mp_alerts_planned,
                                        style: TextStyle(
                                          color: sc,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    _GradientChip(
                                      label: destinoLabel,
                                      color: destinoCor,
                                      icon: isGeral
                                          ? Icons.apartment_rounded
                                          : Icons.home_rounded,
                                    ),
                                    _OutlineChip(label: m.tipo),
                                    _OutlineChip(label: m.frequencia),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Divider
                                Container(
                                  height: 1,
                                  color: OwanyTheme.borderColor(context)
                                      .withValues(alpha: 0.2),
                                ),

                                const SizedBox(height: 12),

                                // Detail items row
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 8,
                                  children: [
                                    _DetailItem(
                                      icon: Icons.schedule_rounded,
                                      label: l10n.mp_alerts_next,
                                      value: DateFormat('dd/MM/yyyy')
                                          .format(m.proximaManutencao),
                                    ),
                                    _DetailItem(
                                      icon: Icons.attach_money_rounded,
                                      label: l10n.mp_alerts_cost,
                                      value:
                                          'MZN ${(m.custoEstimado ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
                                    ),
                                    if (m.responsavelNome != null &&
                                        m.responsavelNome!.isNotEmpty)
                                      _DetailItem(
                                        icon: Icons.person_rounded,
                                        label: l10n.mp_responsible,
                                        value: m.responsavelNome!,
                                      ),
                                  ],
                                ),
                              ],
                            ),
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
// SMALL REUSABLE CHIP WIDGETS
// =============================================================

class _GradientChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _GradientChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final String label;

  const _OutlineChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: OwanyTheme.textMutedColor(context),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// =============================================================
// DETAIL ITEM (bottom row of card)
// =============================================================

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(icon, size: 13, color: OwanyTheme.primaryOrange),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: OwanyTheme.textMutedColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================
// EMPTY STATE
// =============================================================

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: OwanyTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: OwanyTheme.success.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 40, color: OwanyTheme.success),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

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
          const SizedBox(height: 140),

          // Dashboard skeleton
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          const SizedBox(height: 20),

          // Filter bar skeleton
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 20),

          // Card skeletons
          ...List.generate(
            4,
            (index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 80)),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 140,
                decoration: BoxDecoration(
                  color: OwanyTheme.textMutedColor(context)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
