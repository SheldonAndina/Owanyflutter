// ============================================================================
// MANAGE RESIDENTS SCREEN – PREMIUM PRO v4.0
// Features:
//   • Mesh-gradient glass app bar with shimmer sweep
//   • Animated stats dashboard (arc + counters)
//   • Frosted glass search bar with animated focus ring
//   • Apartment filter chips: colored gradient pills
//   • Apartment group headers: glassmorphism gradient cards
//   • Morador cards: gradient avatar, press animation, gradient divider
//   • Shimmer skeleton loader
//   • Empty / error states with radial glow
//   • FAB with gradient + shadow
// ============================================================================

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../providers/apartamentos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/moradores_provider.dart';
import '../../providers/usuarios_provider.dart';

class ManageResidentsScreen extends StatefulWidget {
  const ManageResidentsScreen({super.key});

  @override
  State<ManageResidentsScreen> createState() => _ManageResidentsScreenState();
}

class _ManageResidentsScreenState extends State<ManageResidentsScreen>
    with TickerProviderStateMixin {

  // ── state ──────────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query      = '';
  String? _filtroApt;
  double _scrollOffset = 0;

  final _scrollCtrl = ScrollController();

  // ── animations ─────────────────────────────────────────────────────────────
  late AnimationController _introCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _introFade;
  late Animation<Offset> _introSlide;
  late Animation<double> _shimmerAnim;
  late Animation<double> _pulseAnim;

  bool _searchFocused = false;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _introCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _shimmerCtrl= AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);

    _introFade  = CurvedAnimation(parent: _introCtrl,  curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _introSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _introCtrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)));
    _shimmerAnim= CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
    _pulseAnim  = Tween<double>(begin: 0.84, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _searchFocus.addListener(() => setState(() => _searchFocused = _searchFocus.hasFocus));
    _scrollCtrl.addListener(() => setState(() => _scrollOffset = _scrollCtrl.offset));

    Future.microtask(() async {
      await Future.wait([
        context.read<ApartamentosProvider>().carregarApartamentos(),
        context.read<MoradoresProvider>().carregarMoradores(),
        context.read<UsuariosProvider>().carregarUsuarios(),
      ]);
      if (mounted) _introCtrl.forward();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    _introCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p.first[0]}${p.last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context)!;
    final isGestor= context.watch<AuthProvider>().isGestor;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(116),
        child: _GlassAppBar(
          scrollOffset: _scrollOffset,
          shimmerAnim: _shimmerAnim,
        ),
      ),
      // Morador é criado ao cadastrar um usuário — botão removido
      body: Consumer3<MoradoresProvider, UsuariosProvider, ApartamentosProvider>(
        builder: (ctx, moradoresProv, usuariosProv, aptProv, _) {
          final loading = moradoresProv.isLoading ||
              usuariosProv.isLoading ||
              aptProv.isLoading;

          if (loading) return const _ShimmerLoader();

          // ── Combine data ──
          final combined = moradoresProv.moradores.map((m) {
            final usuario = m.usuarioId != null
                ? usuariosProv.usuarios
                    .cast<dynamic>()
                    .firstWhere((u) => u.id == m.usuarioId, orElse: () => null)
                : null;
            final apt = m.apartamentoId != null
                ? aptProv.apartamentos
                    .cast<dynamic>()
                    .firstWhere((a) => a.id == m.apartamentoId, orElse: () => null)
                : null;
            return {'morador': m, 'usuario': usuario, 'apartamento': apt};
          }).toList();

          // ── Filter ──
          final filtered = combined.where((item) {
            final m   = item['morador'] as dynamic;
            final u   = item['usuario'];
            final apt = item['apartamento'];
            if (_filtroApt != null && m.apartamentoId != _filtroApt) return false;
            if (_query.isNotEmpty) {
              final q = _query.toLowerCase();
              return m.nome.toLowerCase().contains(q) ||
                  (u?.telefone?.toLowerCase().contains(q) ?? false) ||
                  (apt?.nome?.toLowerCase().contains(q) ?? false) ||
                  (apt?.numero?.toLowerCase().contains(q) ?? false) ||
                  (apt?.bloco?.toLowerCase().contains(q) ?? false);
            }
            return true;
          }).toList();

          // ── Sort flat list by apt block/number, then proprietario first, then name ──
          filtered.sort((a, b) {
            final aptA = a['apartamento'];
            final aptB = b['apartamento'];
            // sem apartamento goes last
            if (aptA == null && aptB != null) return 1;
            if (aptA != null && aptB == null) return -1;
            if (aptA != null && aptB != null) {
              final bc = (aptA.bloco ?? '').compareTo(aptB.bloco ?? '');
              if (bc != 0) return bc;
              final nc = (aptA.numero ?? '').compareTo(aptB.numero ?? '');
              if (nc != 0) return nc;
            }
            final mA = a['morador'] as dynamic;
            final mB = b['morador'] as dynamic;
            final pA = mA.proprietario == true ? 0 : 1;
            final pB = mB.proprietario == true ? 0 : 1;
            if (pA != pB) return pA.compareTo(pB);
            return (mA.nome as String).compareTo(mB.nome as String);
          });

          // ── Dashboard stats ──
          final total       = combined.length;
          final proprietarios = combined.where((i) => (i['morador'] as dynamic).proprietario == true).length;
          final comConta    = combined.where((i) => i['usuario'] != null).length;
          final semConta    = total - comConta;

          return RefreshIndicator(
            color: OwanyTheme.primaryOrange,
            backgroundColor: OwanyTheme.cardColor(context),
            strokeWidth: 3,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await Future.wait([
                moradoresProv.carregarMoradores(),
                usuariosProv.carregarUsuarios(),
                aptProv.carregarApartamentos(),
              ]);
            },
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [

                // ── AppBar clearance ──
                const SliverToBoxAdapter(child: SizedBox(height: 136)),

                // ── Dashboard ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _introFade,
                    child: SlideTransition(
                      position: _introSlide,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _Dashboard(
                          total: total,
                          proprietarios: proprietarios,
                          comConta: comConta,
                          semConta: semConta,
                          pulseAnim: _pulseAnim,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Search + filter panel ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SearchPanel(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      focused: _searchFocused,
                      query: _query,
                      filtroApt: _filtroApt,
                      apartamentos: aptProv.apartamentos,
                      totalFiltrado: filtered.length,
                      totalGeral: total,
                      onQueryChanged: (v) => setState(() => _query = v.toLowerCase()),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      onAptFilter: (id) => setState(() =>
                          _filtroApt = _filtroApt == id ? null : id),
                      onClearApt: () => setState(() => _filtroApt = null),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Resident groups ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      hasFilter: _query.isNotEmpty || _filtroApt != null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx2, i) {
                          final item = filtered[i];
                          final m    = item['morador'] as dynamic;
                          final u    = item['usuario'];
                          final apt  = item['apartamento'];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 280 + (i * 55).clamp(0, 500)),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, child) => Transform.translate(
                              offset: Offset(0, 24 * (1 - v)),
                              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MoradorCard(
                                morador: m,
                                usuario: u,
                                apartamento: apt,
                                onTap: () => Navigator.pushNamed(
                                  context, '/moradores-detalhe', arguments: m.id as String),
                                initials: _initials,
                              ),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }


}

// =============================================================================
// GLASS APP BAR
// =============================================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final Animation<double> shimmerAnim;

  const _GlassAppBar({required this.scrollOffset, required this.shimmerAnim});

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context)!;
    final prog = (scrollOffset / 120).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedBuilder(
          animation: shimmerAnim,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.42, 0.58, 1.0],
                colors: [
                  OwanyTheme.primaryOrange.withValues(alpha: 0.88 + prog * 0.12),
                  OwanyTheme.accent.withValues(alpha: 0.78 + prog * 0.22),
                  Color.lerp(
                    OwanyTheme.accent,
                    Colors.white,
                    (math.sin(shimmerAnim.value * math.pi * 2) * 0.5 + 0.5) * 0.13,
                  )!.withValues(alpha: 0.82),
                  OwanyTheme.primaryOrange.withValues(alpha: 0.90),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12 + prog * 0.08)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.people_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.residents_directory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.apartments_complete_management,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
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
      ),
    );
  }
}

// =============================================================================
// DASHBOARD
// =============================================================================

class _Dashboard extends StatelessWidget {
  final int total, proprietarios, comConta, semConta;
  final Animation<double> pulseAnim;

  const _Dashboard({
    required this.total,
    required this.proprietarios,
    required this.comConta,
    required this.semConta,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.42),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Donut ring (total)
                    _DonutRing(value: comConta, total: total),
                    const SizedBox(width: 20),
                    // Mini bars column
                    Expanded(
                      child: Column(
                        children: [
                          _MiniBar(
                            label: l.residents_owner_full,
                            value: proprietarios,
                            total: total,
                            color: OwanyTheme.warning,
                            delay: 0,
                          ),
                          const SizedBox(height: 10),
                          _MiniBar(
                            label: l.residents_with_account,
                            value: comConta,
                            total: total,
                            color: OwanyTheme.success,
                            delay: 100,
                          ),
                          const SizedBox(height: 10),
                          _MiniBar(
                            label: l.residents_no_account,
                            value: semConta,
                            total: total,
                            color: OwanyTheme.error,
                            delay: 200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (semConta > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.25),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: pulseAnim.value, child: child),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: OwanyTheme.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: OwanyTheme.warning.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: OwanyTheme.warning.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_off_rounded,
                              size: 17, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$semConta morador${semConta == 1 ? '' : 'es'} sem conta vinculada',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
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

// ── Donut ring ────────────────────────────────────────────────────────────────

class _DonutRing extends StatefulWidget {
  final int value, total;
  const _DonutRing({required this.value, required this.total});
  @override
  State<_DonutRing> createState() => _DonutRingState();
}

class _DonutRingState extends State<_DonutRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total == 0 ? 0.0 : widget.value / widget.total;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final v = pct * _a.value;
        return SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _DonutPainter(percent: v),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(v * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'c/ conta',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${widget.total} total',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  _DonutPainter({required this.percent});
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final c = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    canvas.drawCircle(c, r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.17)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2, 2 * math.pi * percent, false,
      Paint()
        ..shader = const LinearGradient(colors: [Colors.white, Color(0xFFFFE0B2)])
            .createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ── Mini bar row ──────────────────────────────────────────────────────────────

class _MiniBar extends StatefulWidget {
  final String label;
  final int value, total;
  final Color color;
  final int delay;
  const _MiniBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.delay,
  });
  @override
  State<_MiniBar> createState() => _MiniBarState();
}

class _MiniBarState extends State<_MiniBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total == 0 ? 0.0 : widget.value / widget.total;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('${(widget.value * _a.value).round()}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct * _a.value,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH PANEL
// =============================================================================

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String query;
  final String? filtroApt;
  final List<dynamic> apartamentos;
  final int totalFiltrado, totalGeral;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onAptFilter;
  final VoidCallback onClearApt;

  const _SearchPanel({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.query,
    required this.filtroApt,
    required this.apartamentos,
    required this.totalFiltrado,
    required this.totalGeral,
    required this.onQueryChanged,
    required this.onClear,
    required this.onAptFilter,
    required this.onClearApt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilter = query.isNotEmpty || filtroApt != null;

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: OwanyTheme.backgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: focused
                      ? OwanyTheme.primaryOrange
                      : OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                  width: focused ? 2 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: l.residents_search_hint,
                  hintStyle: TextStyle(
                      color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.55),
                      fontSize: 14),
                  prefixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      focused ? Icons.search_rounded : Icons.search_outlined,
                      key: ValueKey(focused),
                      color: focused
                          ? OwanyTheme.primaryOrange
                          : OwanyTheme.textMutedColor(context),
                      size: 20,
                    ),
                  ),
                  suffixIcon: query.isNotEmpty
                      ? GestureDetector(
                          onTap: onClear,
                          child: Icon(Icons.close_rounded,
                              color: OwanyTheme.textMutedColor(context), size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                ),
                onChanged: onQueryChanged,
              ),
            ),
          ),

          // ── Count row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      OwanyTheme.primaryOrange.withValues(alpha: 0.14),
                      OwanyTheme.accent.withValues(alpha: 0.07),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 13, color: OwanyTheme.primaryOrange),
                      const SizedBox(width: 5),
                      Text(
                        l.residents_count(totalFiltrado),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: OwanyTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 8),
                  Text(
                    l.residents_of_total(totalGeral),
                    style: TextStyle(
                      fontSize: 12,
                      color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Apt filter chips ──
          if (apartamentos.isNotEmpty) ...[
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _AptChip(
                    label: l.residents_all,
                    icon: Icons.all_inclusive_rounded,
                    active: filtroApt == null,
                    onTap: onClearApt,
                  ),
                  ...apartamentos.map((apt) {
                    final label = '${apt.numero} · ${apt.bloco}';
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _AptChip(
                        label: label,
                        icon: Icons.apartment_rounded,
                        active: filtroApt == apt.id,
                        onTap: () => onAptFilter(apt.id as String),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AptChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AptChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [OwanyTheme.primaryOrange, OwanyTheme.accent])
              : null,
          color: active
              ? null
              : OwanyTheme.textMutedColor(context).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? OwanyTheme.primaryOrange
                : OwanyTheme.textMutedColor(context).withValues(alpha: 0.18),
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.28),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: active ? Colors.white : OwanyTheme.primaryOrange),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: active ? Colors.white : OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                )),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MORADOR CARD
// =============================================================================

class _MoradorCard extends StatefulWidget {
  final dynamic morador;
  final dynamic usuario;
  final dynamic apartamento;
  final VoidCallback onTap;
  final String Function(String) initials;

  const _MoradorCard({
    required this.morador,
    required this.usuario,
    this.apartamento,
    required this.onTap,
    required this.initials,
  });

  @override
  State<_MoradorCard> createState() => _MoradorCardState();
}

class _MoradorCardState extends State<_MoradorCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l           = AppLocalizations.of(context)!;
    final m           = widget.morador;
    final u           = widget.usuario;
    final apt         = widget.apartamento;
    final isProp      = m.proprietario == true;
    final accentColor = isProp ? OwanyTheme.warning : OwanyTheme.info;
    final noAccount   = u == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.cardColor(context),
                accentColor.withValues(alpha: _pressed ? 0.07 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: _pressed ? 0.5 : 0.2),
              width: _pressed ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _pressed ? 0.2 : 0.06),
                blurRadius: _pressed ? 20 : 8,
                offset: Offset(0, _pressed ? 8 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [

                // ── Gradient avatar ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isProp
                              ? [OwanyTheme.warning, const Color(0xFFFFB300)]
                              : [OwanyTheme.primaryOrange, OwanyTheme.accent],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials(m.nome as String),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isProp)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: OwanyTheme.cardColor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: OwanyTheme.warning.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 15, color: OwanyTheme.warning),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Name + role badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.nome as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: OwanyTheme.textPrimary(context),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoleBadge(
                            label: isProp
                                ? l.residents_owner_full
                                : l.residents_tenant,
                            color: accentColor,
                            icon: isProp
                                ? Icons.star_rounded
                                : Icons.person_rounded,
                          ),
                        ],
                      ),

                      // ── Apartment info ──
                      if (apt != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.apartment_rounded, size: 13,
                                color: OwanyTheme.primaryOrange.withValues(alpha: 0.7)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${apt.nome ?? ''} · ${l.residents_apt_label(apt.numero ?? '')} · ${l.residents_block_label(apt.bloco ?? '')} · ${l.residents_floor_label(apt.andar ?? 0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.home_work_outlined, size: 13,
                                color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.6)),
                            const SizedBox(width: 5),
                            Text(
                              l.residents_group_no_apartment,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Gradient divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            OwanyTheme.borderColor(context).withValues(alpha: 0.45),
                            Colors.transparent,
                          ]),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Detail chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          if (u?.telefone != null &&
                              (u.telefone as String).isNotEmpty)
                            _DetailChip(
                              icon: Icons.phone_rounded,
                              label: u.telefone as String,
                              color: OwanyTheme.success,
                            ),
                          if (u?.nomeLogin != null &&
                              (u.nomeLogin as String).isNotEmpty)
                            _DetailChip(
                              icon: Icons.alternate_email_rounded,
                              label: u.nomeLogin as String,
                              color: OwanyTheme.info,
                            ),
                          if (m.dataEntrada != null)
                            _DetailChip(
                              icon: Icons.calendar_today_rounded,
                              label: l.morador_since_date(
                                  DateFormat('dd/MM/yy').format(m.dataEntrada!)),
                              color: OwanyTheme.textMuted,
                            ),
                          if (noAccount)
                            _DetailChip(
                              icon: Icons.person_off_outlined,
                              label: l.residents_no_account,
                              color: OwanyTheme.error,
                              filled: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Chevron circle ──
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 16, color: accentColor),
                ),
              ],
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

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _RoleBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.72)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              )),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: filled ? 0.3 : 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
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
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _block(double h, {double? w, double r = 14}) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        height: h, width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            colors: [
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.07),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.18),
              OwanyTheme.textMutedColor(context).withValues(alpha: 0.07),
            ],
            stops: [
              (_a.value - 0.35).clamp(0.0, 1.0),
              _a.value.clamp(0.0, 1.0),
              (_a.value + 0.35).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 155, 20, 20),
      child: Column(
        children: [
          _block(170, r: 28),
          const SizedBox(height: 20),
          _block(130, r: 24),
          const SizedBox(height: 20),
          _block(50, r: 18),
          const SizedBox(height: 12),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _block(90, r: 20),
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final icon  = hasFilter ? Icons.search_off_rounded : Icons.people_outline_rounded;
    final title = hasFilter ? l.residents_not_found : l.residents_none_registered;
    final sub   = hasFilter ? l.residents_adjust_filters : null;
    final color = hasFilter ? OwanyTheme.info : OwanyTheme.primaryOrange;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      color.withValues(alpha: 0.14),
                      color.withValues(alpha: 0.0),
                    ]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      color.withValues(alpha: 0.13),
                      color.withValues(alpha: 0.05),
                    ]),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, size: 54, color: color),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: OwanyTheme.textPrimary(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                )),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: OwanyTheme.textMutedColor(context),
                      fontSize: 14, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}