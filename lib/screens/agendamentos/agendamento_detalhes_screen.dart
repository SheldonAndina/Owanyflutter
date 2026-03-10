import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../dto/agendamentos_dtos.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../providers/agendamentos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/agendamentos/agendamento_ui_kit.dart';
import '../../screens/agendamentos/editar_agendamento_screen.dart';
import '../../theme/owany_theme.dart';

// =============================================================
// AGENDAMENTO DETALHES SCREEN – PREMIUM PRO VERSION 3.0
// Features: Glassmorphism hero, animated circular progress,
//           shimmer loader, urgency pulse, rich cards, wide layout
// =============================================================

class AgendamentoDetalhesScreen extends StatefulWidget {
  final String agendamentoId;

  const AgendamentoDetalhesScreen({
    required this.agendamentoId,
    super.key,
  });

  @override
  State<AgendamentoDetalhesScreen> createState() =>
      _AgendamentoDetalhesScreenState();
}

class _AgendamentoDetalhesScreenState
    extends State<AgendamentoDetalhesScreen> with TickerProviderStateMixin {
  // ── animation controllers ─────────────────────────────────────────────────
  late AnimationController _heroAnimController;
  late AnimationController _pulseController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _pulseAnimation;

  // ── helpers ──────────────────────────────────────────────────────────────
  static final FilteringTextInputFormatter _moneyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'));

  DateTime _dateOnly(DateTime v) => DateTime(v.year, v.month, v.day);

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

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

  double? _resolvedRealCost(AgendamentoMaintenanceDto a) {
    final real = a.custoReal;
    if (real != null) return real;
    final mao = a.custoMaoObra;
    final mat = a.custoMaterial;
    if (mao == null && mat == null) return null;
    return (mao ?? 0) + (mat ?? 0);
  }

  int _calculateRemainingDays(AgendamentoMaintenanceDto a) {
    if (a.isConcluido || a.isCancelado || a.isRecusado) return 0;
    final createdAt = a.criadoEm ?? DateTime.now();
    final endAt = a.dataConclusao ?? a.dataAgendada;
    final totalDays = _dateOnly(endAt).difference(_dateOnly(createdAt)).inDays;
    final elapsedDays =
        _dateOnly(DateTime.now()).difference(_dateOnly(createdAt)).inDays;
    if (totalDays <= 0) {
      return _dateOnly(endAt).difference(_dateOnly(DateTime.now())).inDays;
    }
    return totalDays - elapsedDays;
  }

  String _remainingDaysLabel(AgendamentoMaintenanceDto a) {
    final d = _calculateRemainingDays(a);
    if (d > 0) return _tx('$d dia(s)', '$d day(s)');
    if (d == 0) return _tx('Hoje', 'Today');
    return _tx('${d.abs()} dia(s) em atraso', '${d.abs()} day(s) overdue');
  }

  Color _remainingDaysColor(AgendamentoMaintenanceDto a) {
    final d = _calculateRemainingDays(a);
    if (d < 0) return OwanyTheme.error;
    if (d == 0) return OwanyTheme.warning;
    return OwanyTheme.success;
  }

  bool _isOverdue(AgendamentoMaintenanceDto a) =>
      _calculateRemainingDays(a) < 0 && !a.isConcluido && !a.isCancelado;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _heroFadeAnimation = CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOutCubic,
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeOutCubic,
    ));
    _pulseAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context
            .read<AgendamentosProvider>()
            .carregarAgendamento(widget.agendamentoId);
        if (mounted) _heroAnimController.forward();
      } catch (e) {
        if (kDebugMode) print('Erro ao carregar agendamento: $e');
      }
    });
  }

  @override
  void dispose() {
    _heroAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _reloadAll() async {
    final p = context.read<AgendamentosProvider>();
    await p.carregarAgendamento(widget.agendamentoId);
    await p.carregarAgendamentos();
  }

  Future<void> _reply(AgendamentoMaintenanceDto a, bool accept) async {
    final l10n = AppLocalizations.of(context)!;
    String? reason;
    if (!accept) {
      final ctrl = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => _PremiumDialog(
          title: _tx('Motivo da recusa', 'Decline reason'),
          icon: Icons.do_not_disturb_on_rounded,
          iconColor: OwanyTheme.error,
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: OwanyTheme.adaptiveInputDecoration(
              context,
              label: _tx('Explique o motivo', 'Explain the reason'),
              icon: Icons.edit_note_rounded,
            ),
          ),
          actions: [
            _DialogBtn(label: l10n.common_cancel, onTap: () => Navigator.pop(ctx)),
            _DialogBtn(
              label: _tx('Enviar', 'Send'),
              filled: true,
              color: OwanyTheme.error,
              onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
            ),
          ],
        ),
      );
      if (reason == null || reason.isEmpty) return;
    }

    final ok = await context
        .read<AgendamentosProvider>()
        .responderAgendamento(a.id, aceitar: accept, motivoRecusa: reason);
    if (!mounted) return;
    _showSnack(
      ok
          ? (accept
              ? _tx('Agendamento confirmado.', 'Schedule confirmed.')
              : _tx('Resposta enviada.', 'Response sent.'))
          : _tx('Falha ao responder.', 'Failed to submit response.'),
      ok ? SnackBarType.success : SnackBarType.error,
    );
    if (ok) _reloadAll();
  }

  Future<void> _finish(AgendamentoMaintenanceDto a) async {
    final l10n = AppLocalizations.of(context)!;
    final obs = TextEditingController(text: a.observacoes ?? '');
    final mao = TextEditingController(
      text: a.custoMaoObra != null ? a.custoMaoObra!.toStringAsFixed(2) : '',
    );
    final mat = TextEditingController(
      text: a.custoMaterial != null ? a.custoMaterial!.toStringAsFixed(2) : '',
    );

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: _tx('Concluir agendamento', 'Finish schedule'),
        icon: Icons.task_alt_rounded,
        iconColor: OwanyTheme.success,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: obs,
              maxLines: 3,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: l10n.agendamentos_notes_field,
                icon: Icons.sticky_note_2_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mao,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_moneyInputFormatter],
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: _tx('Custo mão de obra (MZN)', 'Labor cost (MZN)'),
                icon: Icons.engineering_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mat,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_moneyInputFormatter],
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: _tx('Custo material (MZN)', 'Material cost (MZN)'),
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        actions: [
          _DialogBtn(label: l10n.common_cancel, onTap: () => Navigator.pop(ctx, false)),
          _DialogBtn(
            label: _tx('Concluir', 'Finish'),
            filled: true,
            color: OwanyTheme.success,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (go != true) return;

    final custoMaoObra = _parseMzn(mao.text);
    final custoMaterial = _parseMzn(mat.text);
    if ((mao.text.trim().isNotEmpty && custoMaoObra == null) ||
        (mat.text.trim().isNotEmpty && custoMaterial == null)) {
      _showSnack(
        _tx('Informe valores válidos para custos em MZN.',
            'Provide valid cost values in MZN.'),
        SnackBarType.error,
      );
      return;
    }

    final ok = await context.read<AgendamentosProvider>().concluirAgendamento(
          a.id,
          observacoes: obs.text.trim().isEmpty ? null : obs.text.trim(),
          custoMaoObra: custoMaoObra,
          custoMaterial: custoMaterial,
        );
    if (!mounted) return;
    _showSnack(
        ok ? _tx('Agendamento concluído.', 'Schedule finished.')
            : _tx('Falha ao concluir.', 'Failed to finish.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _reloadAll();
  }

  Future<void> _cancel(AgendamentoMaintenanceDto a) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: _tx('Cancelar agendamento', 'Cancel schedule'),
        icon: Icons.cancel_rounded,
        iconColor: OwanyTheme.error,
        content: Text(
          _tx(
            'Deseja cancelar "${a.titulo}"?\nEsta ação não pode ser desfeita.',
            'Do you want to cancel "${a.titulo}"?\nThis action cannot be undone.',
          ),
          style: OwanyTheme.bodyStyle(context),
        ),
        actions: [
          _DialogBtn(label: _tx('Não', 'No'), onTap: () => Navigator.pop(ctx, false)),
          _DialogBtn(
            label: _tx('Cancelar agend.', 'Cancel sched.'),
            filled: true,
            color: OwanyTheme.error,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (go != true) return;
    final ok = await context.read<AgendamentosProvider>().cancelarAgendamento(a.id);
    if (!mounted) return;
    _showSnack(ok ? _tx('Agendamento cancelado.', 'Schedule canceled.')
            : _tx('Falha ao cancelar.', 'Failed to cancel.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _confirm(AgendamentoMaintenanceDto a) async {
    final ok = await context.read<AgendamentosProvider>().confirmarAgendamento(a.id);
    if (!mounted) return;
    _showSnack(ok ? _tx('Agendamento confirmado.', 'Schedule confirmed.')
            : _tx('Falha ao confirmar.', 'Failed to confirm.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _reloadAll();
  }

  Future<void> _start(AgendamentoMaintenanceDto a) async {
    final ok = await context.read<AgendamentosProvider>().iniciarAgendamento(a.id);
    if (!mounted) return;
    _showSnack(ok ? _tx('Agendamento iniciado.', 'Schedule started.')
            : _tx('Falha ao iniciar.', 'Failed to start.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _reloadAll();
  }

  Future<void> _openEdit(AgendamentoMaintenanceDto a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditarAgendamentoScreen(agendamento: a)),
    );
    if (!mounted) return;
    await _reloadAll();
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    _showSnack(
      _tx('ID copiado para a área de transferência.',
          'ID copied to clipboard.'),
      SnackBarType.info,
    );
  }

  void _showSnack(String msg, SnackBarType type) =>
      ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(msg, type: type));

  String _fieldOrNotInformed(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppLocalizations.of(context)!.common_not_informed;
    return trimmed;
  }

  // ── timeline builder ──────────────────────────────────────────────────────

  List<AgendamentoTimelineStep> _buildTimeline(AgendamentoMaintenanceDto a) {
    final key = AgendamentoStatusHelper.statusKey(a.status);
    final done = AgendamentoStatusHelper.isDone(a);
    final inProgress = key.contains('emandamento') ||
        key.contains('iniciado') ||
        key.contains('execucao');
    final confirmed = key.contains('confirmado') || key.contains('aceito');
    final scheduled = key.contains('agendado') ||
        key.contains('pendente') ||
        confirmed ||
        inProgress ||
        done;
    final started = inProgress || done;
    final finished = key.contains('concluido') || key.contains('avaliado');
    final canceled = key.contains('cancelado') || key.contains('recusado');

    return [
      AgendamentoTimelineStep(
        title: _tx('Criado', 'Created'),
        subtitle: a.criadoEm != null
            ? AgendamentoStatusHelper.fullDate(a.criadoEm!)
            : _tx('Data não informada', 'Date not informed'),
        icon: Icons.add_task_rounded,
        done: true,
        current: false,
      ),
      AgendamentoTimelineStep(
        title: _tx('Agendado', 'Scheduled'),
        subtitle: AgendamentoStatusHelper.fullDate(a.dataAgendada),
        icon: Icons.event_note_rounded,
        done: scheduled,
        current: !scheduled && !canceled,
      ),
      AgendamentoTimelineStep(
        title: _tx('Confirmado', 'Confirmed'),
        subtitle: confirmed
            ? _tx('Confirmação registada', 'Confirmation registered')
            : _tx('Aguardando confirmação', 'Waiting confirmation'),
        icon: Icons.check_circle_outline_rounded,
        done: confirmed || started || finished,
        current: !confirmed && !started && !finished && !canceled,
      ),
      AgendamentoTimelineStep(
        title: _tx('Execução', 'Execution'),
        subtitle: a.dataInicioReal != null
            ? _tx('Iniciado em ${AgendamentoStatusHelper.fullDate(a.dataInicioReal!)}',
                'Started at ${AgendamentoStatusHelper.fullDate(a.dataInicioReal!)}')
            : (inProgress ? _tx('Em execução', 'In progress') : _tx('Não iniciado', 'Not started')),
        icon: Icons.play_circle_outline_rounded,
        done: started,
        current: inProgress,
      ),
      AgendamentoTimelineStep(
        title: canceled ? _tx('Cancelado', 'Canceled') : _tx('Concluído', 'Finished'),
        subtitle: canceled
            ? (a.motivoRecusa?.trim().isNotEmpty == true
                ? a.motivoRecusa!
                : _tx('Fluxo encerrado', 'Flow closed'))
            : (a.dataConclusao != null
                ? _tx(
                    'Concluído em ${AgendamentoStatusHelper.fullDate(a.dataConclusao!)}',
                    'Finished at ${AgendamentoStatusHelper.fullDate(a.dataConclusao!)}',
                  )
                : (finished
                    ? _tx('Concluído', 'Finished')
                    : _tx('Pendente de conclusão', 'Pending completion'))),
        icon: canceled ? Icons.cancel_rounded : Icons.task_alt_rounded,
        done: finished || canceled,
        current: !finished && !canceled && started,
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Glass hero card — full-bleed gradient header
  Widget _buildHeroCard(AgendamentoMaintenanceDto a) {
    final meta = AgendamentoStatusHelper.meta(context, a.status);
    final isOverdue = _isOverdue(a);
    final isToday = AgendamentoStatusHelper.isToday(a);
    final isNext7 = AgendamentoStatusHelper.isNext7Days(a);
    final desc = (a.descricao ?? '').trim();

    return FadeTransition(
      opacity: _heroFadeAnimation,
      child: SlideTransition(
        position: _heroSlideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(26),
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
            borderRadius: BorderRadius.circular(26),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: meta.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(26),
                        bottomLeft: Radius.circular(26),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: meta.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: meta.color.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Icon(meta.icon, color: meta.color, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.titulo,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: OwanyTheme.textPrimary(context),
                                        letterSpacing: -0.4,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 12,
                                          color: OwanyTheme.textMutedColor(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            AgendamentoStatusHelper.apartmentLabel(
                                              a,
                                              fallback: AppLocalizations.of(context)!
                                                  .agendamentos_general_condo,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  OwanyTheme.textMutedColor(context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _GlassIconBtn(
                                icon: Icons.copy_rounded,
                                tooltip: _tx('Copiar ID', 'Copy ID'),
                                onTap: () => _copyId(a.id),
                              ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: meta.color.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: OwanyTheme.textPrimary(context),
                                  fontWeight: FontWeight.w500,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _GlassIdChip(id: a.id),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AgendamentoStatusPill(meta: meta),
                              AgendamentoTimePill(agendamento: a),
                              if (isOverdue)
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (_, child) => Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: child,
                                  ),
                                  child: _GlassBadge(
                                    label: _tx('Atrasado', 'Overdue'),
                                    color: OwanyTheme.error,
                                    icon: Icons.warning_amber_rounded,
                                  ),
                                ),
                              if (isToday)
                                _GlassBadge(
                                  label: _tx('Hoje', 'Today'),
                                  color: OwanyTheme.warning,
                                  icon: Icons.today_rounded,
                                ),
                              if (isNext7)
                                _GlassBadge(
                                  label: _tx('Próximo', 'Upcoming'),
                                  color: OwanyTheme.info,
                                  icon: Icons.event_available_rounded,
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
          ),
        ),
      ),
    );
  }

  /// Animated circular progress card
  Widget _buildProgressCard(AgendamentoMaintenanceDto a) {
    final steps = _buildTimeline(a);
    final doneCount = steps.where((s) => s.done).length;
    final total = steps.length;
    final progress = total > 0 ? doneCount / total : 0.0;
    final meta = AgendamentoStatusHelper.meta(context, a.status);

    return _GlassCard(
      borderColor: meta.color.withValues(alpha: 0.25),
      child: Row(
        children: [
          // Animated circular arc
          _AnimatedProgressArc(
            progress: progress,
            color: meta.color,
            size: 64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso do agendamento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$doneCount de $total etapas concluídas',
                  style: TextStyle(
                    fontSize: 12,
                    color: OwanyTheme.textMutedColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: OwanyTheme.borderColor(context),
                      valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(AgendamentoMaintenanceDto a) {
    return AgendamentoSectionCard(
      title: _tx('Linha do tempo', 'Timeline'),
      subtitle: _tx('Acompanhe o progresso operacional', 'Track operational progress'),
      icon: Icons.alt_route_rounded,
      children: [AgendamentoTimeline(steps: _buildTimeline(a))],
    );
  }

  Widget _buildMainInfoCard(AgendamentoMaintenanceDto a) {
    final hasAreaTecnica = (a.areaTecnicaNome ?? '').trim().isNotEmpty ||
        (a.areaTecnicaId ?? '').trim().isNotEmpty;
    final daysColor = _remainingDaysColor(a);

    return _PremiumSectionCard(
      title: _tx('Informações principais', 'Main information'),
      subtitle: _tx('Dados gerais do agendamento', 'General schedule data'),
      icon: Icons.info_outline_rounded,
      accentColor: OwanyTheme.info,
      children: [
        _RichInfoLine(
          label: _tx('Data agendada', 'Scheduled date'),
          value: AgendamentoStatusHelper.fullDate(a.dataAgendada),
          icon: Icons.event_rounded,
        ),
        if (a.duracaoEstimadaHoras != null)
          _RichInfoLine(
            label: _tx('Duração estimada', 'Estimated duration'),
            value: _tx('${a.duracaoEstimadaHoras} hora(s)',
                '${a.duracaoEstimadaHoras} hour(s)'),
            icon: Icons.timer_outlined,
          ),
        _RichInfoLine(
          label: _tx('Responsável', 'Responsible'),
          value: a.responsavelTecnicoNome ??
              a.responsavelTecnicoId ??
              AppLocalizations.of(context)!.common_not_informed,
          icon: Icons.person_outline_rounded,
        ),
        if (hasAreaTecnica)
          _RichInfoLine(
            label: _tx('Área técnica', 'Technical area'),
            value: (a.areaTecnicaNome ?? '').trim().isNotEmpty
                ? a.areaTecnicaNome!
                : (a.areaTecnicaId ?? AppLocalizations.of(context)!.common_not_informed),
            icon: Icons.engineering_rounded,
          ),
        _RichInfoLine(
          label: _tx('Dias restantes', 'Days remaining'),
          value: _remainingDaysLabel(a),
          icon: Icons.hourglass_top_rounded,
          valueColor: daysColor,
          iconAccentColor: daysColor,
        ),
        if ((a.itemApartamentoNome ?? '').trim().isNotEmpty)
          _RichInfoLine(
            label: _tx('Item', 'Item'),
            value: a.itemApartamentoNome!,
            icon: Icons.handyman_rounded,
          ),
        if ((a.itemApartamentoCodigoPatrimonio ?? '').trim().isNotEmpty)
          _RichInfoLine(
            label: _tx('Património', 'Asset code'),
            value: a.itemApartamentoCodigoPatrimonio!,
            icon: Icons.qr_code_rounded,
          ),
        _RichInfoLine(
          label: _tx('Status', 'Status'),
          value: a.displayStatus,
          icon: Icons.flag_rounded,
        ),
        if ((a.tipo ?? '').trim().isNotEmpty)
          _RichInfoLine(
            label: _tx('Tipo', 'Type'),
            value: a.tipo!,
            icon: Icons.category_outlined,
          ),
        if ((a.tipoSolicitacaoNome ?? '').trim().isNotEmpty)
          _RichInfoLine(
            label: _tx('Tipo de solicitação', 'Request type'),
            value: a.tipoSolicitacaoNome!,
            icon: Icons.sell_outlined,
          ),
      ],
    );
  }

  Widget _buildTechnicalRefsCard(AgendamentoMaintenanceDto a) {
    return _PremiumSectionCard(
      title: _tx('Referências técnicas', 'Technical references'),
      subtitle: _tx('Dados de referência do registo', 'Record reference data'),
      icon: Icons.badge_outlined,
      accentColor: OwanyTheme.primaryOrange,
      children: [
        _RichInfoLine(
          label: _tx('ID do registo', 'Record ID'),
          value: a.id,
          icon: Icons.fingerprint_rounded,
        ),
        _RichInfoLine(
          label: _tx('Apartamento', 'Apartment'),
          value: AgendamentoStatusHelper.apartmentLabel(a),
          icon: Icons.apartment_rounded,
        ),
        _RichInfoLine(
          label: _tx('Responsável técnico', 'Technical responsible'),
          value: _fieldOrNotInformed(a.responsavelTecnicoNome),
          icon: Icons.engineering_rounded,
        ),
        _RichInfoLine(
          label: _tx('Item vinculado', 'Linked item'),
          value: _fieldOrNotInformed(a.itemApartamentoNome),
          icon: Icons.inventory_2_outlined,
        ),
        _RichInfoLine(
          label: _tx('Tipo de solicitação', 'Request type'),
          value: _fieldOrNotInformed(a.tipoSolicitacaoNome),
          icon: Icons.sell_outlined,
        ),
        _RichInfoLine(
          label: _tx('Área técnica', 'Technical area'),
          value: _fieldOrNotInformed(a.areaTecnicaNome),
          icon: Icons.room_service_outlined,
        ),
        _RichInfoLine(
          label: _tx('Respondido por (morador)', 'Answered by (resident)'),
          value: _fieldOrNotInformed(a.respondidoPorMoradorNome),
          icon: Icons.person_pin_outlined,
        ),
      ],
    );
  }

  Widget _buildAuditCard(AgendamentoMaintenanceDto a) {
    final hasAudit = a.criadoEm != null ||
        (a.criadoPorId ?? '').trim().isNotEmpty ||
        a.atualizadoEm != null ||
        (a.atualizadoPorId ?? '').trim().isNotEmpty;
    if (!hasAudit) return const SizedBox.shrink();

    return _PremiumSectionCard(
      title: _tx('Auditoria', 'Audit'),
      subtitle: _tx('Criação e atualização do registo', 'Record creation and updates'),
      icon: Icons.history_toggle_off_rounded,
      accentColor: OwanyTheme.textSecondary,
      children: [
        if (a.criadoEm != null)
          _RichInfoLine(
            label: _tx('Criado em', 'Created at'),
            value: AgendamentoStatusHelper.fullDate(a.criadoEm!),
            icon: Icons.event_note_rounded,
          ),
        _RichInfoLine(
          label: _tx('Criado por', 'Created by'),
          value: _fieldOrNotInformed(a.criadoPorNome ?? a.criadoPorId),
          icon: Icons.person_add_alt_1_rounded,
        ),
        if (a.atualizadoEm != null)
          _RichInfoLine(
            label: _tx('Atualizado em', 'Updated at'),
            value: AgendamentoStatusHelper.fullDate(a.atualizadoEm!),
            icon: Icons.update_rounded,
          ),
        _RichInfoLine(
          label: _tx('Atualizado por', 'Updated by'),
          value: _fieldOrNotInformed(a.atualizadoPorNome ?? a.atualizadoPorId),
          icon: Icons.manage_accounts_rounded,
        ),
      ],
    );
  }

  Widget _buildFinanceCard(AgendamentoMaintenanceDto a) {
    final hasEstimate = a.custoEstimado != null;
    final realCost = _resolvedRealCost(a);
    final hasReal = realCost != null;
    final hasLabor = a.custoMaoObra != null;
    final hasMaterial = a.custoMaterial != null;
    final hasFornecedor = (a.fornecedor ?? '').trim().isNotEmpty;
    final hasPhone = (a.telefoneFornecedor ?? '').trim().isNotEmpty;

    if (!hasEstimate && !hasReal && !hasLabor && !hasMaterial && !hasFornecedor && !hasPhone) {
      return const SizedBox.shrink();
    }

    String fmt(double v) => 'MZN ${v.toStringAsFixed(2)}';

    return _PremiumSectionCard(
      title: _tx('Fornecedor e custos', 'Supplier and costs'),
      subtitle: _tx('Informações comerciais do atendimento', 'Commercial attendance info'),
      icon: Icons.payments_outlined,
      accentColor: OwanyTheme.success,
      children: [
        if (hasFornecedor)
          _RichInfoLine(
            label: _tx('Fornecedor', 'Supplier'),
            value: a.fornecedor!,
            icon: Icons.store_mall_directory_outlined,
          ),
        if (hasPhone)
          _RichInfoLine(
            label: AppLocalizations.of(context)!.common_phone,
            value: a.telefoneFornecedor!,
            icon: Icons.phone_outlined,
          ),
        if (hasEstimate || hasReal) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasEstimate)
                Expanded(
                  child: _GlassCostChip(
                    label: _tx('Estimado', 'Estimated'),
                    value: fmt(a.custoEstimado!),
                    color: OwanyTheme.info,
                    icon: Icons.ssid_chart_rounded,
                  ),
                ),
              if (hasEstimate && hasReal) const SizedBox(width: 10),
              if (hasReal)
                Expanded(
                  child: _GlassCostChip(
                    label: _tx('Real', 'Actual'),
                    value: fmt(realCost),
                    color: OwanyTheme.success,
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
            ],
          ),
        ],
        if (hasLabor)
          _RichInfoLine(
            label: 'CustoMaoObra',
            value: fmt(a.custoMaoObra!),
            icon: Icons.engineering_outlined,
          ),
        if (hasMaterial)
          _RichInfoLine(
            label: 'CustoMaterial',
            value: fmt(a.custoMaterial!),
            icon: Icons.inventory_2_outlined,
          ),
        if (a.custoReal != null)
          _RichInfoLine(
            label: 'CustoReal',
            value: fmt(a.custoReal!),
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
  }

  Widget _buildExecutionCard(AgendamentoMaintenanceDto a) {
    final hasStart = a.dataInicioReal != null;
    final hasEnd = a.dataConclusao != null;
    final hasReport = (a.relatorioExecucao ?? '').trim().isNotEmpty;
    final hasInvoice = (a.notaFiscal ?? '').trim().isNotEmpty;
    final hasObs = (a.observacoes ?? '').trim().isNotEmpty;
    final hasFotosAntes = (a.fotosAntes ?? '').trim().isNotEmpty;
    final hasFotosDepois = (a.fotosDepois ?? '').trim().isNotEmpty;

    if (!hasStart && !hasEnd && !hasReport && !hasInvoice && !hasObs && !hasFotosAntes && !hasFotosDepois) {
      return const SizedBox.shrink();
    }

    return _PremiumSectionCard(
      title: _tx('Execução e observações', 'Execution and notes'),
      subtitle: _tx('Histórico de trabalho registado', 'Recorded work history'),
      icon: Icons.work_history_rounded,
      accentColor: OwanyTheme.warning,
      children: [
        if (hasStart)
          _RichInfoLine(
            label: _tx('Início real', 'Actual start'),
            value: AgendamentoStatusHelper.fullDate(a.dataInicioReal!),
            icon: Icons.play_circle_outline_rounded,
          ),
        if (hasEnd)
          _RichInfoLine(
            label: _tx('Conclusão', 'Completion'),
            value: AgendamentoStatusHelper.fullDate(a.dataConclusao!),
            icon: Icons.task_alt_rounded,
          ),
        if (hasObs)
          _RichInfoLine(
            label: AppLocalizations.of(context)!.agendamentos_notes_field,
            value: a.observacoes!,
            icon: Icons.sticky_note_2_outlined,
          ),
        if (hasReport)
          _RichInfoLine(
            label: _tx('Relatório', 'Report'),
            value: a.relatorioExecucao!,
            icon: Icons.description_outlined,
          ),
        if (hasInvoice)
          _RichInfoLine(
            label: _tx('Nota fiscal', 'Invoice'),
            value: a.notaFiscal!,
            icon: Icons.receipt_long_rounded,
          ),
        if (hasFotosAntes)
          _RichInfoLine(
            label: 'FotosAntes',
            value: a.fotosAntes!,
            icon: Icons.photo_camera_back_outlined,
          ),
        if (hasFotosDepois)
          _RichInfoLine(
            label: 'FotosDepois',
            value: a.fotosDepois!,
            icon: Icons.photo_camera_front_outlined,
          ),
      ],
    );
  }

  Widget _buildResidentFeedbackCard(AgendamentoMaintenanceDto a) {
    final hasAnswer = a.dataResposta != null ||
        (a.respondidoPorMoradorNome ?? '').trim().isNotEmpty;
    final hasReason = (a.motivoRecusa ?? '').trim().isNotEmpty;
    final hasRating = a.avaliacaoMorador != null;
    final hasComment = (a.comentarioAvaliacao ?? '').trim().isNotEmpty;

    if (!hasAnswer && !hasReason && !hasRating && !hasComment) {
      return const SizedBox.shrink();
    }

    return _PremiumSectionCard(
      title: _tx('Resposta do morador', 'Resident response'),
      subtitle: _tx('Feedback e aceite do atendimento', 'Attendance feedback and acceptance'),
      icon: Icons.rate_review_outlined,
      accentColor: const Color(0xFF7C3AED),
      children: [
        if (hasAnswer)
          _RichInfoLine(
            label: _tx('Respondido por', 'Answered by'),
            value: a.respondidoPorMoradorNome ??
                a.respondidoPorMoradorId ??
                AppLocalizations.of(context)!.common_resident,
            icon: Icons.person_rounded,
          ),
        if (a.dataResposta != null)
          _RichInfoLine(
            label: _tx('Data resposta', 'Response date'),
            value: AgendamentoStatusHelper.fullDate(a.dataResposta!),
            icon: Icons.calendar_today_rounded,
          ),
        if (hasReason)
          _RichInfoLine(
            label: _tx('Motivo recusa', 'Decline reason'),
            value: a.motivoRecusa!,
            icon: Icons.report_gmailerrorred_rounded,
            valueColor: OwanyTheme.error,
          ),
        if (hasRating) ...[
          const SizedBox(height: 10),
          _AnimatedStarRating(rating: a.avaliacaoMorador!),
          const SizedBox(height: 6),
        ],
        if (hasComment)
          _RichInfoLine(
            label: _tx('Comentário', 'Comment'),
            value: a.comentarioAvaliacao!,
            icon: Icons.chat_bubble_outline_rounded,
          ),
      ],
    );
  }

  // ── bottom action bar ─────────────────────────────────────────────────────

  Widget _buildBottomActions(AgendamentoMaintenanceDto a) {
    final isStaff = context.read<AuthProvider>().isStaff;
    final isMorador = context.read<AuthProvider>().isMorador;

    final canConfirm = isStaff && AgendamentoStatusHelper.canConfirm(a.status);
    final canStart = isStaff && AgendamentoStatusHelper.canStart(a.status);
    final canFinish = isStaff && AgendamentoStatusHelper.canFinish(a.status);
    final canCancel = isStaff && AgendamentoStatusHelper.canCancel(a.status);
    final canReply = isMorador && AgendamentoStatusHelper.canReply(a.status);

    if (!canConfirm && !canStart && !canFinish && !canCancel && !canReply) {
      return const SizedBox.shrink();
    }

    final actions = <Widget>[
      if (canConfirm)
        _PremiumActionBtn(
          label: AppLocalizations.of(context)!.common_confirm,
          icon: Icons.check_circle_rounded,
          color: OwanyTheme.success,
          onTap: () => _confirm(a),
        ),
      if (canStart)
        _PremiumActionBtn(
          label: _tx('Iniciar', 'Start'),
          icon: Icons.play_circle_rounded,
          color: OwanyTheme.info,
          onTap: () => _start(a),
        ),
      if (canFinish)
        _PremiumActionBtn(
          label: _tx('Concluir', 'Finish'),
          icon: Icons.task_alt_rounded,
          color: OwanyTheme.success,
          filled: true,
          onTap: () => _finish(a),
        ),
      if (canCancel)
        _PremiumActionBtn(
          label: AppLocalizations.of(context)!.common_cancel,
          icon: Icons.cancel_outlined,
          color: OwanyTheme.error,
          onTap: () => _cancel(a),
        ),
      if (canReply) ...[
        _PremiumActionBtn(
          label: _tx('Aceitar', 'Accept'),
          icon: Icons.check_rounded,
          color: OwanyTheme.success,
          filled: true,
          onTap: () => _reply(a, true),
        ),
        _PremiumActionBtn(
          label: _tx('Recusar', 'Decline'),
          icon: Icons.close_rounded,
          color: OwanyTheme.error,
          onTap: () => _reply(a, false),
        ),
      ],
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context).withValues(alpha: 0.92),
            border: Border(
                top: BorderSide(color: OwanyTheme.borderColor(context))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    actions[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(AppLocalizations l10n, bool isStaff) {
    return AppBar(
      backgroundColor: OwanyTheme.cardColor(context),
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.agendamentos_schedule,
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            _tx('Detalhes completos', 'Full details'),
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
      iconTheme: IconThemeData(color: OwanyTheme.textPrimary(context)),
      actions: [
        IconButton(
          onPressed: _reloadAll,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: l10n.common_update,
        ),
        Consumer<AgendamentosProvider>(
          builder: (context, provider, _) {
            final a = provider.agendamentoSelecionado;
            if (!isStaff || a == null) return const SizedBox.shrink();
            final canEdit = AgendamentoStatusHelper.canEdit(a.status);
            final canFinish = AgendamentoStatusHelper.canFinish(a.status);
            final canCancel = AgendamentoStatusHelper.canCancel(a.status);
            if (!canEdit && !canFinish && !canCancel) {
              return const SizedBox.shrink();
            }
            return PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'editar' && canEdit) await _openEdit(a);
                if (v == 'concluir' && canFinish) await _finish(a);
                if (v == 'cancelar' && canCancel) await _cancel(a);
              },
              icon: Icon(Icons.more_vert_rounded,
                  color: OwanyTheme.textPrimary(context)),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                if (canEdit)
                  PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        const Icon(Icons.edit_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.common_edit),
                      ])),
                if (canFinish)
                  PopupMenuItem(
                      value: 'concluir',
                      child: Row(children: [
                        const Icon(Icons.task_alt_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(_tx('Concluir', 'Finish')),
                      ])),
                if (canCancel)
                  PopupMenuItem(
                      value: 'cancelar',
                      child: Row(children: [
                        const Icon(Icons.cancel_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.common_cancel),
                      ])),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStaff = context.read<AuthProvider>().isStaff;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: _buildAppBar(l10n, isStaff),
      body: Consumer<AgendamentosProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.agendamentoSelecionado == null) {
            return const _ShimmerLoader();
          }

          final a = provider.agendamentoSelecionado;
          if (a == null) {
            return AgendamentoEmptyState(
              title: l10n.agendamentos_not_found,
              subtitle: _tx(
                  'O item pode ter sido removido ou você não possui acesso.',
                  'The item may have been removed or you do not have access.'),
              onReload: _reloadAll,
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadAll,
            color: OwanyTheme.primaryOrange,
            child: isWide ? _buildWideLayout(a) : _buildNarrowLayout(a),
          );
        },
      ),
      bottomNavigationBar: Consumer<AgendamentosProvider>(
        builder: (context, provider, _) {
          final a = provider.agendamentoSelecionado;
          if (a == null) return const SizedBox.shrink();
          return _buildBottomActions(a);
        },
      ),
    );
  }

  Widget _buildNarrowLayout(AgendamentoMaintenanceDto a) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeroCard(a),
        const SizedBox(height: 16),
        _buildProgressCard(a),
        const SizedBox(height: 16),
        _buildTimelineCard(a),
        const SizedBox(height: 16),
        _buildMainInfoCard(a),
        const SizedBox(height: 16),
        _buildTechnicalRefsCard(a),
        const SizedBox(height: 16),
        _buildFinanceCard(a),
        const SizedBox(height: 16),
        _buildExecutionCard(a),
        const SizedBox(height: 16),
        _buildResidentFeedbackCard(a),
        const SizedBox(height: 16),
        _buildAuditCard(a),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWideLayout(AgendamentoMaintenanceDto a) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(a),
                const SizedBox(height: 16),
                _buildProgressCard(a),
                const SizedBox(height: 16),
                _buildMainInfoCard(a),
                const SizedBox(height: 16),
                _buildTechnicalRefsCard(a),
                const SizedBox(height: 16),
                _buildFinanceCard(a),
                const SizedBox(height: 16),
                _buildExecutionCard(a),
                const SizedBox(height: 16),
                _buildResidentFeedbackCard(a),
                const SizedBox(height: 16),
                _buildAuditCard(a),
                const SizedBox(height: 32),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 320, minWidth: 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimelineCard(a),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM LOCAL WIDGETS
// =============================================================

// ── Glass card wrapper ────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _GlassCard({
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: borderColor ?? OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Premium section card with colored accent header ───────────

class _PremiumSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _PremiumSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent header stripe
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: OwanyTheme.surfaceColor(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: accentColor.withValues(alpha: 0.9), width: 3),
                bottom: BorderSide(color: OwanyTheme.borderColor(context)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rich info line with colored icon bg ───────────────────────

class _RichInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? iconAccentColor;

  const _RichInfoLine({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconAccentColor ?? OwanyTheme.primaryOrange;
    final valColor = valueColor ?? OwanyTheme.textPrimary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: OwanyTheme.textMutedColor(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated circular progress arc ───────────────────────────

class _AnimatedProgressArc extends StatefulWidget {
  final double progress;
  final Color color;
  final double size;

  const _AnimatedProgressArc({
    required this.progress,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedProgressArc> createState() => _AnimatedProgressArcState();
}

class _AnimatedProgressArcState extends State<_AnimatedProgressArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ArcPainter(
            percent: widget.progress * _anim.value,
            color: widget.color,
          ),
          child: Center(
            child: Text(
              '${(widget.progress * 100 * _anim.value).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double percent;
  final Color color;

  _ArcPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final bg = Paint()
      ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.18)
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ── Glass cost chip ───────────────────────────────────────────

class _GlassCostChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _GlassCostChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass bottom action button ────────────────────────────────

class _PremiumActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  const _PremiumActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_PremiumActionBtn> createState() => _PremiumActionBtnState();
}

class _PremiumActionBtnState extends State<_PremiumActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => {},
      onExit: (_) => {},
      child: GestureDetector(
        onTapDown: (_) {
          if (mounted) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _pressed = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _pressed = false);
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.filled
                ? LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.8)])
                : null,
            color: widget.filled ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: widget.filled
                ? null
                : Border.all(color: widget.color, width: 2),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.35),
                      blurRadius: _pressed ? 6 : 14,
                      offset: Offset(0, _pressed ? 2 : 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.filled ? Colors.white : widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.filled ? Colors.white : widget.color,
                  letterSpacing: 0.1,
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

// ── Glass badge (white overlay on colored hero) ───────────────

class _GlassBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _GlassBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass icon button (white on hero) ────────────────────────

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.copy_rounded, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Glass ID chip (white variant for hero) ────────────────────

class _GlassIdChip extends StatelessWidget {
  final String id;

  const _GlassIdChip({required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag_rounded, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            id,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated star rating ──────────────────────────────────────

class _AnimatedStarRating extends StatefulWidget {
  final int rating;

  const _AnimatedStarRating({required this.rating});

  @override
  State<_AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<_AnimatedStarRating>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < widget.rating;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (i * 80)),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 24,
              color: filled ? OwanyTheme.warning : OwanyTheme.borderColor(context),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          '${widget.rating}/5',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: OwanyTheme.warning,
          ),
        ),
      ],
    );
  }
}

// ── Shimmer skeleton loader ───────────────────────────────────

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _block(200, radius: 26), // hero
          const SizedBox(height: 16),
          _block(80, radius: 22), // progress
          const SizedBox(height: 16),
          _block(180, radius: 22), // timeline
          const SizedBox(height: 16),
          _block(220, radius: 22), // info
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _block(90, radius: 16)),
            const SizedBox(width: 12),
            Expanded(child: _block(90, radius: 16)),
          ]),
        ],
      ),
    );
  }
}

// ── Premium Dialog ────────────────────────────────────────────

class _PremiumDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget content;
  final List<Widget> actions;

  const _PremiumDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: OwanyTheme.cardColor(context),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      iconColor.withValues(alpha: 0.15),
                      iconColor.withValues(alpha: 0.06),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: iconColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: OwanyTheme.textPrimary(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((w) =>
                      Padding(padding: const EdgeInsets.only(left: 10), child: w))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? color;

  const _DialogBtn({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? OwanyTheme.primaryOrange;
    if (filled) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );
    }
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: OwanyTheme.textMutedColor(context),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
