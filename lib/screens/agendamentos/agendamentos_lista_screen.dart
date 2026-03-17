// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'dart:math' as math;

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

/// Locale-aware text helper accessible from all widgets in this file.
String _txCtx(BuildContext context, String pt, String en) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code.startsWith('en') ? en : pt;
}

// =============================================================
// AGENDAMENTOS LISTA SCREEN — PREMIUM PRO VERSION 2.0
// Features: Glassmorphism AppBar, Staggered Animations,
//           Gradient Hero, Premium Cards — mirrors ApartmentsScreen
// =============================================================

enum _SortMode { prioridade, dataAsc, dataDesc, status }

class AgendamentosListaScreen extends StatefulWidget {
  const AgendamentosListaScreen({super.key});

  @override
  State<AgendamentosListaScreen> createState() =>
      _AgendamentosListaScreenState();
}

class _AgendamentosListaScreenState extends State<AgendamentosListaScreen>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  AgendamentoQuickFilter _quickFilter = AgendamentoQuickFilter.todos;
  _SortMode _sortMode = _SortMode.prioridade;

  bool _showOnlyWithFornecedor = false;
  bool _showOnlyComResponsavel = false;
  bool _showOnlyComTipo = false;
  bool _mostrarAgrupado = true;
  final _scrollOffset = ValueNotifier<double>(0);
  final _showFab = ValueNotifier<bool>(false);
  final Map<String, bool> _expandedGroups = {};
  List<AgendamentoMaintenanceDto>? _filteredCache;
  List<AgendamentoMaintenanceDto>? _cachedSource;
  int _cachedSourceLength = -1;
  String? _cachedSourceFirstId;
  String? _cachedSourceLastId;
  String _cachedQuery = '';
  AgendamentoQuickFilter _cachedQuickFilter = AgendamentoQuickFilter.todos;
  _SortMode _cachedSortMode = _SortMode.prioridade;
  bool _cachedShowOnlyWithFornecedor = false;
  bool _cachedShowOnlyComResponsavel = false;
  bool _cachedShowOnlyComTipo = false;
  List<AgendamentoMaintenanceDto>? _searchIndexSource;
  int _searchIndexLength = -1;
  String? _searchIndexFirstId;
  String? _searchIndexLastId;
  Map<String, String> _searchIndex = {};

  // ── Animations ──
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  static final FilteringTextInputFormatter _moneyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'));

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  List<AgendamentoFilterOption> get _quickFilters => [
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.todos,
          label: _tx('Todos', 'All'),
          icon: Icons.grid_view_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.manutencaoGeral,
          label: _tx('Manut. Geral', 'General Maint.'),
          icon: Icons.build_circle_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.atrasados,
          label: _tx('Atrasados', 'Overdue'),
          icon: Icons.warning_amber_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.hoje,
          label: _tx('Hoje', 'Today'),
          icon: Icons.today_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.proximos7,
          label: _tx('Próx. 7 dias', 'Next 7 days'),
          icon: Icons.event_available_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.pendentes,
          label: _tx('Pendentes', 'Pending'),
          icon: Icons.hourglass_bottom_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.agendados,
          label: _tx('Agendados', 'Scheduled'),
          icon: Icons.schedule_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.confirmados,
          label: _tx('Confirmados', 'Confirmed'),
          icon: Icons.check_circle_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.andamento,
          label: _tx('Em andamento', 'In progress'),
          icon: Icons.play_circle_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.concluidos,
          label: _tx('Concluídos', 'Completed'),
          icon: Icons.task_alt_rounded,
        ),
        AgendamentoFilterOption(
          filter: AgendamentoQuickFilter.cancelados,
          label: _tx('Cancelados', 'Cancelled'),
          icon: Icons.cancel_rounded,
        ),
      ];

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

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
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _scrollOffset.dispose();
    _showFab.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollCtrl.offset;
    _scrollOffset.value = offset;
    final show = offset > 300;
    if (show != _showFab.value) _showFab.value = show;
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    _headerAnimController.reset();
    _contentAnimController.reset();

    final auth = context.read<AuthProvider>();
    final provider = context.read<AgendamentosProvider>();

    if (auth.isVisitante || auth.isPortaria) {
      provider.limparDados();
      _headerAnimController.forward();
      _contentAnimController.forward();
      return;
    }
    if (auth.isMorador) {
      final aptId = auth.apartamentoIdDoMorador;
      if (aptId != null && aptId.isNotEmpty) {
        await provider.carregarAgendamentos(apartamentoId: aptId);
      } else {
        provider.limparDados();
      }
    } else if (auth.isStaff) {
      await provider.carregarAgendamentos();
    } else {
      provider.limparDados();
    }

    if (mounted) {
      _headerAnimController.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _contentAnimController.forward();
      });
    }
  }

  // ── filtering & sorting ───────────────────────────────────────────────────

  void _invalidateFilteredCache() {
    _filteredCache = null;
  }

  void _ensureSearchIndex(List<AgendamentoMaintenanceDto> source) {
    final length = source.length;
    final firstId = length > 0 ? source.first.id : null;
    final lastId = length > 0 ? source.last.id : null;
    if (identical(_searchIndexSource, source) &&
        _searchIndexLength == length &&
        _searchIndexFirstId == firstId &&
        _searchIndexLastId == lastId) {
      return;
    }
    _searchIndexSource = source;
    _searchIndexLength = length;
    _searchIndexFirstId = firstId;
    _searchIndexLastId = lastId;
    _searchIndex = {
      for (final a in source)
        a.id: [
          a.titulo,
          a.descricao ?? '',
          a.numeroApartamento ?? '',
          a.blocoApartamento ?? '',
          a.responsavelTecnicoNome ?? '',
          a.responsavelTecnicoId ?? '',
          a.tipoSolicitacaoNome ?? '',
          a.fornecedor ?? '',
          a.status,
          a.id,
        ].map((e) => e.toLowerCase()).join('|'),
    };
  }

  String _normalizeFilterText(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
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
        .replaceAll('ç', 'c')
        .replaceAll('_', '')
        .replaceAll(' ', '');
  }

  bool _isManutencaoGeral(AgendamentoMaintenanceDto a) {
    final tipo = _normalizeFilterText(a.tipo);
    if (tipo.contains('manutencaogeral') || tipo == 'geral') return true;

    final joined = _normalizeFilterText([
      a.titulo,
      a.descricao ?? '',
      a.tipoSolicitacaoNome ?? '',
      a.areaTecnicaNome ?? '',
    ].join(' '));
    return joined.contains('manutencaogeral') || joined.contains('servicogeral');
  }

  bool _isFilterMatch(AgendamentoMaintenanceDto a) {
    switch (_quickFilter) {
      case AgendamentoQuickFilter.manutencaoGeral:
        return _isManutencaoGeral(a);
      case AgendamentoQuickFilter.atrasados:
        return AgendamentoStatusHelper.isOverdue(a);
      case AgendamentoQuickFilter.hoje:
        return AgendamentoStatusHelper.isToday(a);
      case AgendamentoQuickFilter.proximos7:
        return AgendamentoStatusHelper.isNext7Days(a);
      case AgendamentoQuickFilter.pendentes:
        return AgendamentoStatusHelper.statusKey(a.status).contains('pendente');
      case AgendamentoQuickFilter.agendados:
        return AgendamentoStatusHelper.statusKey(a.status).contains('agendado');
      case AgendamentoQuickFilter.confirmados:
        return AgendamentoStatusHelper.statusKey(a.status).contains('confirmado');
      case AgendamentoQuickFilter.andamento:
        return AgendamentoStatusHelper.statusKey(a.status).contains('emandamento') ||
            AgendamentoStatusHelper.statusKey(a.status).contains('iniciado');
      case AgendamentoQuickFilter.concluidos:
        return AgendamentoStatusHelper.statusKey(a.status).contains('concluido') ||
            AgendamentoStatusHelper.statusKey(a.status).contains('avaliado');
      case AgendamentoQuickFilter.cancelados:
        return AgendamentoStatusHelper.statusKey(a.status).contains('cancelado') ||
            AgendamentoStatusHelper.statusKey(a.status).contains('recusado');
      case AgendamentoQuickFilter.todos:
        return true;
    }
  }

  bool _isSearchMatch(AgendamentoMaintenanceDto a) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final fields = _searchIndex[a.id];
    if (fields == null) return false;
    return fields.contains(query);
  }

  bool _isExtraFilterMatch(AgendamentoMaintenanceDto a) {
    if (_showOnlyWithFornecedor && (a.fornecedor ?? '').trim().isEmpty) return false;
    if (_showOnlyComResponsavel &&
        (a.responsavelTecnicoNome ?? a.responsavelTecnicoId ?? '').trim().isEmpty) return false;
    if (_showOnlyComTipo && (a.tipoSolicitacaoNome ?? '').trim().isEmpty) return false;
    return true;
  }

  int _sortByPriority(AgendamentoMaintenanceDto a, AgendamentoMaintenanceDto b) {
    final ao = AgendamentoStatusHelper.isOverdue(a);
    final bo = AgendamentoStatusHelper.isOverdue(b);
    if (ao != bo) return ao ? -1 : 1;
    final at = AgendamentoStatusHelper.isToday(a);
    final bt = AgendamentoStatusHelper.isToday(b);
    if (at != bt) return at ? -1 : 1;
    final ad = AgendamentoStatusHelper.isDone(a);
    final bd = AgendamentoStatusHelper.isDone(b);
    if (ad != bd) return ad ? 1 : -1;
    return a.dataAgendada.compareTo(b.dataAgendada);
  }

  int _sortByStatus(AgendamentoMaintenanceDto a, AgendamentoMaintenanceDto b) {
    final cmp = AgendamentoStatusHelper.statusKey(a.status)
        .compareTo(AgendamentoStatusHelper.statusKey(b.status));
    if (cmp != 0) return cmp;
    return a.dataAgendada.compareTo(b.dataAgendada);
  }

  List<AgendamentoMaintenanceDto> _filtered(List<AgendamentoMaintenanceDto> source) {
    _ensureSearchIndex(source);
    final query = _searchCtrl.text.trim().toLowerCase();
    final length = source.length;
    final firstId = length > 0 ? source.first.id : null;
    final lastId = length > 0 ? source.last.id : null;
    final canUseCache =
        identical(_cachedSource, source) &&
        _cachedSourceLength == length &&
        _cachedSourceFirstId == firstId &&
        _cachedSourceLastId == lastId &&
        _cachedQuery == query &&
        _cachedQuickFilter == _quickFilter &&
        _cachedSortMode == _sortMode &&
        _cachedShowOnlyWithFornecedor == _showOnlyWithFornecedor &&
        _cachedShowOnlyComResponsavel == _showOnlyComResponsavel &&
        _cachedShowOnlyComTipo == _showOnlyComTipo &&
        _filteredCache != null;
    if (canUseCache) return _filteredCache!;

    final list = source
        .where(_isSearchMatch)
        .where(_isFilterMatch)
        .where(_isExtraFilterMatch)
        .toList();
    switch (_sortMode) {
      case _SortMode.prioridade:
        list.sort(_sortByPriority);
        break;
      case _SortMode.dataAsc:
        list.sort((a, b) => a.dataAgendada.compareTo(b.dataAgendada));
        break;
      case _SortMode.dataDesc:
        list.sort((a, b) => b.dataAgendada.compareTo(a.dataAgendada));
        break;
      case _SortMode.status:
        list.sort(_sortByStatus);
        break;
    }
    _cachedSource = source;
    _cachedSourceLength = length;
    _cachedSourceFirstId = firstId;
    _cachedSourceLastId = lastId;
    _cachedQuery = query;
    _cachedQuickFilter = _quickFilter;
    _cachedSortMode = _sortMode;
    _cachedShowOnlyWithFornecedor = _showOnlyWithFornecedor;
    _cachedShowOnlyComResponsavel = _showOnlyComResponsavel;
    _cachedShowOnlyComTipo = _showOnlyComTipo;
    _filteredCache = list;
    return list;
  }

  // ── actions ───────────────────────────────────────────────────────────────

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

  Future<void> _reply(AgendamentoMaintenanceDto a, bool accept) async {
    String? reason;
    if (!accept) {
      final ctrl = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => _PremiumDialog(
          title: _tx('Motivo da recusa', 'Rejection reason'),
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
            _DialogBtn(label: _tx('Cancelar', 'Cancel'), onTap: () => Navigator.pop(ctx)),
            _DialogBtn(label: _tx('Enviar', 'Send'), filled: true, color: OwanyTheme.error,
                onTap: () => Navigator.pop(ctx, ctrl.text.trim())),
          ],
        ),
      );
      if (reason == null || reason.isEmpty) return;
    }
    final ok = await context.read<AgendamentosProvider>().responderAgendamento(
          a.id, aceitar: accept, motivoRecusa: reason);
    if (!mounted) return;
    _snack(
        ok
            ? (accept
                ? _tx('Agendamento confirmado.', 'Appointment confirmed.')
                : _tx('Resposta enviada.', 'Reply sent.'))
            : _tx('Falha ao responder.', 'Failed to reply.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _load();
  }

  Future<void> _finish(AgendamentoMaintenanceDto a) async {
    final obs = TextEditingController();
    final mao = TextEditingController();
    final mat = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: _tx('Concluir agendamento', 'Complete appointment'),
        icon: Icons.task_alt_rounded,
        iconColor: OwanyTheme.success,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: obs, maxLines: 3,
                decoration: OwanyTheme.adaptiveInputDecoration(context,
                    label: _tx('Observações', 'Notes'), icon: Icons.sticky_note_2_outlined)),
            const SizedBox(height: 12),
            TextField(controller: mao,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_moneyInputFormatter],
                decoration: OwanyTheme.adaptiveInputDecoration(context,
                    label: _tx('Custo mão de obra (MZN)', 'Labor cost (MZN)'), icon: Icons.engineering_rounded)),
            const SizedBox(height: 12),
            TextField(controller: mat,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_moneyInputFormatter],
                decoration: OwanyTheme.adaptiveInputDecoration(context,
                    label: _tx('Custo material (MZN)', 'Material cost (MZN)'), icon: Icons.inventory_2_outlined)),
          ],
        ),
        actions: [
          _DialogBtn(label: _tx('Cancelar', 'Cancel'), onTap: () => Navigator.pop(ctx, false)),
          _DialogBtn(label: _tx('Concluir', 'Complete'), filled: true, color: OwanyTheme.success,
              onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (go != true) return;

    final custoMaoObra = _parseMzn(mao.text);
    final custoMaterial = _parseMzn(mat.text);
    if ((mao.text.trim().isNotEmpty && custoMaoObra == null) ||
        (mat.text.trim().isNotEmpty && custoMaterial == null)) {
      _snack(
        _tx('Informe valores válidos para custos em MZN.', 'Provide valid MZN cost values.'),
        SnackBarType.error,
      );
      return;
    }
    final ok = await context.read<AgendamentosProvider>().concluirAgendamento(a.id,
        observacoes: obs.text.trim().isEmpty ? null : obs.text.trim(),
        custoMaoObra: custoMaoObra, custoMaterial: custoMaterial);
    if (!mounted) return;
    _snack(ok ? _tx('Agendamento concluído.', 'Appointment completed.') : _tx('Falha ao concluir.', 'Failed to complete.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _load();
  }

  Future<void> _cancel(AgendamentoMaintenanceDto a) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: _tx('Cancelar agendamento', 'Cancel appointment'),
        icon: Icons.cancel_rounded,
        iconColor: OwanyTheme.error,
        content: Text('${_tx('Deseja cancelar', 'Do you want to cancel')} "${a.titulo}"?\n${_tx('Esta ação não pode ser desfeita.', 'This action cannot be undone.')}',
            style: OwanyTheme.bodyStyle(context)),
        actions: [
          _DialogBtn(label: _tx('Não', 'No'), onTap: () => Navigator.pop(ctx, false)),
          _DialogBtn(label: _tx('Cancelar agend.', 'Cancel appt.'), filled: true, color: OwanyTheme.error,
              onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (go != true) return;
    final ok = await context.read<AgendamentosProvider>().cancelarAgendamento(a.id);
    if (!mounted) return;
    _snack(ok ? _tx('Agendamento cancelado.', 'Appointment cancelled.') : _tx('Falha ao cancelar.', 'Failed to cancel.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _load();
  }

  Future<void> _confirm(AgendamentoMaintenanceDto a) async {
    final ok = await context.read<AgendamentosProvider>().confirmarAgendamento(a.id);
    if (!mounted) return;
    _snack(ok ? _tx('Agendamento confirmado.', 'Appointment confirmed.') : _tx('Falha ao confirmar.', 'Failed to confirm.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _load();
  }

  Future<void> _start(AgendamentoMaintenanceDto a) async {
    final ok = await context.read<AgendamentosProvider>().iniciarAgendamento(a.id);
    if (!mounted) return;
    _snack(ok ? _tx('Agendamento iniciado.', 'Appointment started.') : _tx('Falha ao iniciar.', 'Failed to start.'),
        ok ? SnackBarType.success : SnackBarType.error);
    if (ok) _load();
  }

  void _snack(String msg, SnackBarType type) =>
      ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(msg, type: type));

  // ── filters bottom sheet ──────────────────────────────────────────────────

  Future<void> _showFiltersSheet() async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) {
          Widget sortTile(_SortMode mode, String label, IconData icon) {
            final selected = _sortMode == mode;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _sortMode = mode;
                    _invalidateFilteredCache();
                  });
                  setModal(() {});
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(colors: [
                            OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                            OwanyTheme.accent.withValues(alpha: 0.06),
                          ])
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? OwanyTheme.primaryOrange.withValues(alpha: 0.4)
                          : OwanyTheme.borderColor(context),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? OwanyTheme.primaryOrange.withValues(alpha: 0.15)
                              : OwanyTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16,
                            color: selected
                                ? OwanyTheme.primaryOrange
                                : OwanyTheme.textMutedColor(context)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? OwanyTheme.primaryOrange
                                  : OwanyTheme.textPrimary(context),
                            )),
                      ),
                      if (selected)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          Widget switchTile(String label, String subtitle, bool value,
              void Function(bool) onChanged) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: OwanyTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OwanyTheme.borderColor(context)),
              ),
              child: SwitchListTile(
                dense: true,
                value: value,
                onChanged: onChanged,
                activeColor: OwanyTheme.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: OwanyTheme.textPrimary(context))),
                subtitle: Text(subtitle,
                    style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context))),
              ),
            );
          }

          final hasActiveFilters = _showOnlyWithFornecedor ||
              _showOnlyComResponsavel || _showOnlyComTipo ||
              _sortMode != _SortMode.prioridade;

          return Container(
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                                blurRadius: 8, offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_tx('Filtros avançados', 'Advanced filters'),
                                  style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800,
                                    color: OwanyTheme.textPrimary(context),
                                    letterSpacing: -0.3,
                                  )),
                              Text(_tx('Refine a lista por dados específicos', 'Refine the list using specific data'),
                                  style: TextStyle(fontSize: 12,
                                      color: OwanyTheme.textMutedColor(context),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        if (hasActiveFilters)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_tx('Activos', 'Active'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _SheetSectionLabel(label: _tx('Exibir somente', 'Show only')),
                    const SizedBox(height: 10),
                    switchTile(_tx('Com fornecedor', 'With vendor'), _tx('Apenas agendamentos com fornecedor definido', 'Only appointments with a defined vendor'),
                        _showOnlyWithFornecedor, (v) {
                      setState(() {
                        _showOnlyWithFornecedor = v;
                        _invalidateFilteredCache();
                      });
                      setModal(() {});
                    }),
                    switchTile(_tx('Com responsável', 'With responsible technician'), _tx('Apenas com técnico responsável', 'Only with assigned technician'),
                        _showOnlyComResponsavel, (v) {
                      setState(() {
                        _showOnlyComResponsavel = v;
                        _invalidateFilteredCache();
                      });
                      setModal(() {});
                    }),
                    switchTile(_tx('Com tipo de solicitação', 'With request type'), _tx('Apenas com categoria definida', 'Only with a defined category'),
                        _showOnlyComTipo, (v) {
                      setState(() {
                        _showOnlyComTipo = v;
                        _invalidateFilteredCache();
                      });
                      setModal(() {});
                    }),

                    const SizedBox(height: 20),
                    _SheetSectionLabel(label: _tx('Ordenar por', 'Sort by')),
                    const SizedBox(height: 10),
                    sortTile(_SortMode.prioridade, _tx('Prioridade inteligente', 'Smart priority'), Icons.low_priority_rounded),
                    sortTile(_SortMode.dataAsc, _tx('Data (mais próxima primeiro)', 'Date (nearest first)'), Icons.arrow_upward_rounded),
                    sortTile(_SortMode.dataDesc, _tx('Data (mais recente primeiro)', 'Date (latest first)'), Icons.arrow_downward_rounded),
                    sortTile(_SortMode.status, _tx('Status', 'Status'), Icons.category_rounded),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showOnlyWithFornecedor = false;
                                _showOnlyComResponsavel = false;
                                _showOnlyComTipo = false;
                                _sortMode = _SortMode.prioridade;
                                _invalidateFilteredCache();
                              });
                              setModal(() {});
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: OwanyTheme.borderColor(context)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(_tx('Resetar', 'Reset'),
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.35),
                                  blurRadius: 10, offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(_tx('Aplicar', 'Apply'),
                                  style: TextStyle(fontWeight: FontWeight.w700)),
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
      ),
    );
  }

  // ── group label ───────────────────────────────────────────────────────────

  Widget _buildGroupLabel(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: OwanyTheme.textPrimary(context), letterSpacing: -0.1,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Text('$count',
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── cards ─────────────────────────────────────────────────────────────────

  List<Widget> _buildCards(List<AgendamentoMaintenanceDto> list,
      {required bool isStaff, required bool isMorador}) {
    return list.asMap().entries.map((e) {
      final index = e.key;
      final a = e.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 200 + (index * 40)),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final clamped = value.clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: Opacity(opacity: clamped, child: child),
          );
        },
        child: AgendamentoListCard(
          agendamento: a,
          isStaff: isStaff,
          isMorador: isMorador,
          onOpen: () => Navigator.pushNamed(context, '/agendamento-detalhes', arguments: a.id)
              .then((_) => _load()),
          onEdit: isStaff
              ? () => Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => EditarAgendamentoScreen(agendamento: a)))
                  .then((_) => _load())
              : null,
          onConfirm: isStaff ? () => _confirm(a) : null,
          onStart: isStaff ? () => _start(a) : null,
          onFinish: isStaff ? () => _finish(a) : null,
          onCancel: isStaff ? () => _cancel(a) : null,
          onReplyAccept: isMorador ? () => _reply(a, true) : null,
          onReplyReject: isMorador ? () => _reply(a, false) : null,
        ),
      );
    }).toList();
  }

  List<Widget> _buildGroupedBody(List<AgendamentoMaintenanceDto> list,
      {required bool isStaff, required bool isMorador}) {
    String bucketKey(AgendamentoMaintenanceDto a) {
      final key = AgendamentoStatusHelper.statusKey(a.status);
      if (key.contains('pendente')) return 'pendente';
      if (key.contains('aceito') || key.contains('confirmado')) return 'aceito';
      if (key.contains('recusado')) return 'recusado';
      if (key.contains('agendado')) return 'agendado';
      if (key.contains('emandamento') || key.contains('execucao') || key.contains('iniciado')) return 'emandamento';
      if (key.contains('concluido') || key.contains('avaliado')) return 'concluido';
      if (key.contains('cancelado')) return 'cancelado';
      return 'outros';
    }

    final Map<String, List<AgendamentoMaintenanceDto>> groups = {
      'pendente': [],
      'aceito': [],
      'recusado': [],
      'agendado': [],
      'emandamento': [],
      'concluido': [],
      'cancelado': [],
      'outros': [],
    };
    for (final a in list) {
      groups[bucketKey(a)]!.add(a);
    }

    final widgets = <Widget>[];
    void addSection(String title, List<AgendamentoMaintenanceDto> src, Color color) {
      if (src.isEmpty) return;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));

      final isExpanded = _expandedGroups[title] ?? false;
      widgets.add(
        InkWell(
          onTap: () => setState(() => _expandedGroups[title] = !(isExpanded)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildGroupLabel(title, src.length, color)),
              Transform.rotate(
                angle: isExpanded ? 0 : -math.pi / 2,
                child: Icon(Icons.chevron_left_rounded, color: OwanyTheme.textMutedColor(context)),
              ),
            ],
          ),
        ),
      );

      if (isExpanded) {
        widgets.add(const SizedBox(height: 10));
        widgets.addAll(_buildCards(src, isStaff: isStaff, isMorador: isMorador));
      }
    }

    addSection('Pendente aceitação', groups['pendente']!, OwanyTheme.warning);
    addSection('Aceito', groups['aceito']!, OwanyTheme.info);
    addSection('Recusado', groups['recusado']!, OwanyTheme.error);
    addSection('Agendado', groups['agendado']!, OwanyTheme.primaryOrange);
    addSection('Em andamento', groups['emandamento']!, OwanyTheme.info);
    addSection('Concluído', groups['concluido']!, OwanyTheme.success);
    addSection('Cancelado', groups['cancelado']!, OwanyTheme.textMutedColor(context));
    addSection('Outros', groups['outros']!, OwanyTheme.textMutedColor(context));
    return widgets;
  }

  // ── summary bar ───────────────────────────────────────────────────────────

  Widget _buildSummaryRow(int total, int filtered) {
    final hasFilters = _quickFilter != AgendamentoQuickFilter.todos ||
        _searchCtrl.text.trim().isNotEmpty ||
        _showOnlyWithFornecedor || _showOnlyComResponsavel || _showOnlyComTipo;

    return Row(
      children: [
        Icon(Icons.format_list_bulleted_rounded,
            size: 14, color: OwanyTheme.textMutedColor(context)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$filtered',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: hasFilters
                        ? OwanyTheme.primaryOrange
                        : OwanyTheme.textPrimary(context),
                  ),
                ),
                TextSpan(
                  text: ' de $total agendamento(s)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                      color: OwanyTheme.textMutedColor(context)),
                ),
              ],
            ),
          ),
        ),
        // Group toggle — with gradient when active
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _mostrarAgrupado = !_mostrarAgrupado);
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: _mostrarAgrupado
                    ? LinearGradient(colors: [
                        OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                        OwanyTheme.accent.withValues(alpha: 0.08),
                      ])
                    : null,
                color: _mostrarAgrupado ? null : OwanyTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _mostrarAgrupado
                      ? OwanyTheme.primaryOrange.withValues(alpha: 0.4)
                      : OwanyTheme.borderColor(context),
                  width: _mostrarAgrupado ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_agenda_rounded, size: 14,
                      color: _mostrarAgrupado
                          ? OwanyTheme.primaryOrange
                          : OwanyTheme.textMutedColor(context)),
                  const SizedBox(width: 5),
                  Text(_tx('Agrupar', 'Group'),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _mostrarAgrupado
                            ? OwanyTheme.primaryOrange
                            : OwanyTheme.textMutedColor(context),
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final isStaff = auth.isStaff;
    final isMorador = auth.isMorador;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (_, value, __) =>
              _GlassAppBar(scrollOffset: value, l10n: l10n),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showFab,
        builder: (_, show, __) => AnimatedScale(
          scale: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.4),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              onPressed: () => _scrollCtrl.animateTo(0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              tooltip: _tx('Voltar ao topo', 'Back to top'),
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
        ),
      ),
      body: Consumer<AgendamentosProvider>(
        builder: (context, provider, _) {
          final all = provider.agendamentos;
          final filtered = _filtered(all);
          final metrics = AgendamentoListMetrics.from(all);

          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _load();
            },
            color: OwanyTheme.primaryOrange,
            backgroundColor: OwanyTheme.cardColor(context),
            strokeWidth: 3,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Space for glass app bar
                const SliverToBoxAdapter(child: SizedBox(height: 140)),

                // ── Compact Stats Strip ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _CompactStatsStrip(
                          filteredCount: filtered.length,
                          totalCount: all.length,
                          metrics: metrics,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Search & Filter Card ──
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _PremiumSearchFilterCard(
                          searchCtrl: _searchCtrl,
                          quickFilters: _quickFilters,
                          selectedFilter: _quickFilter,
                          l10n: l10n,
                          onSearch: (_) {
                            _invalidateFilteredCache();
                            setState(() {});
                          },
                          onClear: () {
                            _searchCtrl.clear();
                            _invalidateFilteredCache();
                            setState(() {});
                          },
                          onFilterSelect: (v) {
                            setState(() {
                              _quickFilter = v;
                              _invalidateFilteredCache();
                            });
                            HapticFeedback.selectionClick();
                          },
                          onAdvanced: _showFiltersSheet,
                          hasActiveAdvanced: _showOnlyWithFornecedor ||
                              _showOnlyComResponsavel || _showOnlyComTipo ||
                              _sortMode != _SortMode.prioridade,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Summary Row ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSummaryRow(all.length, filtered.length),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── List ──
                if (provider.isLoading && all.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: AgendamentoLoadingBlock(
                          text: _tx('Carregando agendamentos...', 'Loading appointments...')),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AgendamentoEmptyState(
                        title: _tx('Nenhum agendamento encontrado', 'No appointments found'),
                        subtitle: _tx('Ajuste os filtros ou atualize para tentar novamente.', 'Adjust filters or refresh to try again.'),
                        onReload: _load,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _mostrarAgrupado
                            ? _buildGroupedBody(filtered,
                                isStaff: isStaff, isMorador: isMorador)
                            : _buildCards(filtered,
                                isStaff: isStaff, isMorador: isMorador),
                      ),
                    ),
                  ),

                if (filtered.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.agendamentos_title,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 22, fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Central de atendimentos',
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context)
                                .withValues(alpha: 0.7),
                            fontSize: 12, fontWeight: FontWeight.w500,
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

// =============================================================
// COMPACT STATS STRIP (replaces hero + insight + metric grid)
// =============================================================

class _CompactStatsStrip extends StatelessWidget {
  final int filteredCount;
  final int totalCount;
  final AgendamentoListMetrics metrics;

  const _CompactStatsStrip({
    required this.filteredCount,
    required this.totalCount,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.25),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title + count
          Expanded(
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: OwanyTheme.adaptiveTextOverlay(context), size: 18),
                const SizedBox(width: 8),
                Text(
                  '$filteredCount / $totalCount',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Mini stats
          _MiniStat(
            icon: Icons.warning_amber_rounded,
            value: metrics.atrasados,
            color: OwanyTheme.error,
            context: context,
          ),
          const SizedBox(width: 10),
          _MiniStat(
            icon: Icons.today_rounded,
            value: metrics.hoje,
            color: OwanyTheme.warning,
            context: context,
          ),
          const SizedBox(width: 10),
          _MiniStat(
            icon: Icons.pending_actions_rounded,
            value: metrics.pendentes,
            color: Colors.white,
            context: context,
          ),
          const SizedBox(width: 10),
          _MiniStat(
            icon: Icons.check_circle_outline_rounded,
            value: metrics.concluidos,
            color: OwanyTheme.success,
            context: context,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final BuildContext context;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: OwanyTheme.adaptiveTextOverlay(context),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM HERO DASHBOARD (replaces simple banner)
// =============================================================

class _PremiumHeroDashboard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final int total;
  final AgendamentoListMetrics metrics;

  const _PremiumHeroDashboard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.total,
    required this.metrics,
  });

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
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.35),
            blurRadius: 24, offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.1),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.04),
                ],
              ),
            ),
            child: Column(
              children: [
                // Title + count row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.25),
                        ),
                      ),
                      child: Icon(Icons.calendar_today_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800,
                                color: OwanyTheme.adaptiveTextOverlay(context),
                                letterSpacing: -0.4, height: 1.2,
                              )),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: OwanyTheme.adaptiveTextOverlay(context)
                                    .withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500, height: 1.4,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('$count',
                              style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w900,
                                color: OwanyTheme.adaptiveTextOverlay(context),
                                letterSpacing: -1, height: 1,
                              )),
                          Text('${_txCtx(context, 'de', 'of')} $total',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: OwanyTheme.adaptiveTextOverlay(context)
                                    .withValues(alpha: 0.75),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Circular stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AnimatedCircularStat(
                      label: 'Urgente',
                      value: metrics.atrasados,
                      percent: total == 0 ? 0 : metrics.atrasados / total,
                      color: OwanyTheme.error,
                      delay: 0,
                      overlayContext: context,
                    ),
                    _AnimatedCircularStat(
                      label: 'Hoje',
                      value: metrics.hoje,
                      percent: total == 0 ? 0 : metrics.hoje / total,
                      color: OwanyTheme.warning,
                      delay: 100,
                      overlayContext: context,
                    ),
                    _AnimatedCircularStat(
                      label: 'Pendentes',
                      value: metrics.pendentes,
                      percent: total == 0 ? 0 : metrics.pendentes / total,
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      delay: 200,
                      overlayContext: context,
                    ),
                    _AnimatedCircularStat(
                      label: 'Concluídos',
                      value: metrics.concluidos,
                      percent: total == 0 ? 0 : metrics.concluidos / total,
                      color: OwanyTheme.success,
                      delay: 300,
                      overlayContext: context,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// ANIMATED CIRCULAR STAT
// =============================================================

class _AnimatedCircularStat extends StatefulWidget {
  final String label;
  final int value;
  final double percent;
  final Color color;
  final int delay;
  final BuildContext overlayContext;

  const _AnimatedCircularStat({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.delay,
    required this.overlayContext,
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
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
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
          width: 64,
          height: 64,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _CirclePainter(
                  percent: widget.percent * _anim.value, color: widget.color),
              child: Center(
                child: Text(
                  '${(widget.percent * 100 * _anim.value).round()}%',
                  style: TextStyle(
                    color: OwanyTheme.adaptiveTextOverlay(widget.overlayContext),
                    fontWeight: FontWeight.w900, fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text('${widget.value}',
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(widget.overlayContext),
              fontWeight: FontWeight.w800, fontSize: 16,
            )),
        Text(widget.label,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(widget.overlayContext)
                  .withValues(alpha: 0.8),
              fontSize: 9, fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center),
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
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.2)
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
// PREMIUM SEARCH FILTER CARD
// =============================================================

class _PremiumSearchFilterCard extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<AgendamentoFilterOption> quickFilters;
  final AgendamentoQuickFilter selectedFilter;
  final AppLocalizations l10n;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final ValueChanged<AgendamentoQuickFilter> onFilterSelect;
  final VoidCallback onAdvanced;
  final bool hasActiveAdvanced;

  const _PremiumSearchFilterCard({
    required this.searchCtrl,
    required this.quickFilters,
    required this.selectedFilter,
    required this.l10n,
    required this.onSearch,
    required this.onClear,
    required this.onFilterSelect,
    required this.onAdvanced,
    required this.hasActiveAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [OwanyTheme.primaryOrange, OwanyTheme.accent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 6, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.filter_alt_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_txCtx(context, 'Busca e filtros', 'Search and filters'),
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                          letterSpacing: -0.2,
                        )),
                    Text(_txCtx(context, 'Por status, texto ou regra', 'By status, text, or rule'),
                        style: TextStyle(fontSize: 11,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Advanced filter button with dot indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAdvanced,
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: hasActiveAdvanced
                              ? LinearGradient(colors: [
                                  OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                                  OwanyTheme.accent.withValues(alpha: 0.08),
                                ])
                              : null,
                          color: hasActiveAdvanced ? null : OwanyTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasActiveAdvanced
                                ? OwanyTheme.primaryOrange.withValues(alpha: 0.4)
                                : OwanyTheme.borderColor(context),
                            width: hasActiveAdvanced ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(Icons.tune_rounded, size: 18,
                            color: hasActiveAdvanced
                                ? OwanyTheme.primaryOrange
                                : OwanyTheme.textMutedColor(context)),
                      ),
                    ),
                  ),
                  if (hasActiveAdvanced)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: OwanyTheme.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 8, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AgendamentoSearchBox(
            controller: searchCtrl,
            hint: l10n.agendamentos_search_hint,
            onChanged: onSearch,
            onClear: onClear,
          ),
          const SizedBox(height: 10),
          AgendamentoFilterChips(
            options: quickFilters,
            selected: selectedFilter,
            onSelect: onFilterSelect,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// BOTTOM SHEET SECTION LABEL
// =============================================================

class _SheetSectionLabel extends StatelessWidget {
  final String label;

  const _SheetSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w800,
        color: OwanyTheme.textMutedColor(context),
        letterSpacing: 1.0,
      ),
    );
  }
}

// =============================================================
// SHARED DIALOG WIDGETS
// =============================================================

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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: OwanyTheme.textPrimary(context),
                        letterSpacing: -0.3,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((w) => Padding(padding: const EdgeInsets.only(left: 8), child: w))
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
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 8, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
    }
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: OwanyTheme.textMutedColor(context),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
