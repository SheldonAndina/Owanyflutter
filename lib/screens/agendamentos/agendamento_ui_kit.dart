import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../dto/agendamentos_dtos.dart';
import '../../theme/owany_theme.dart';

String _tx(BuildContext context, String pt, String en) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code.startsWith('en') ? en : pt;
}

class AgendamentoStatusMeta {
  final String key;
  final String label;
  final Color color;
  final IconData icon;
  final bool terminal;

  const AgendamentoStatusMeta({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.terminal,
  });
}

class AgendamentoStatusHelper {
  static String normalize(String? value) {
    var v = (value ?? '').trim().toLowerCase();
    v = v
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
        .replaceAll(' ', '')
        .replaceAll('_', '');
    return v;
  }

  static String statusKey(String? status) {
    final raw = (status ?? '').trim();
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      switch (asInt) {
        case 0:
          return 'pendente';
        case 1:
          return 'agendado';
        case 2:
          return 'recusado';
        case 3:
          return 'confirmado';
        case 4:
          return 'emandamento';
        case 5:
          return 'concluido';
        case 6:
          return 'avaliado';
        case 7:
          return 'cancelado';
      }
    }
    return normalize(raw);
  }

  static AgendamentoStatusMeta meta(BuildContext context, String? status) {
    final key = statusKey(status);

    if (key.contains('cancelado') || key.contains('recusado')) {
      return const AgendamentoStatusMeta(
        key: 'cancelado',
        label: 'Cancelado',
        color: OwanyTheme.error,
        icon: Icons.cancel_rounded,
        terminal: true,
      );
    }

    if (key.contains('concluido') || key.contains('avaliado')) {
      return const AgendamentoStatusMeta(
        key: 'concluido',
        label: 'Concluido',
        color: OwanyTheme.success,
        icon: Icons.task_alt_rounded,
        terminal: true,
      );
    }

    if (key.contains('emandamento') || key.contains('iniciado') || key.contains('execucao')) {
      return const AgendamentoStatusMeta(
        key: 'emandamento',
        label: 'Em andamento',
        color: OwanyTheme.info,
        icon: Icons.play_circle_fill_rounded,
        terminal: false,
      );
    }

    if (key.contains('confirmado') || key.contains('aceito')) {
      return const AgendamentoStatusMeta(
        key: 'confirmado',
        label: 'Confirmado',
        color: OwanyTheme.success,
        icon: Icons.check_circle_rounded,
        terminal: false,
      );
    }

    if (key.contains('agendado') || key.contains('aguardando')) {
      return const AgendamentoStatusMeta(
        key: 'agendado',
        label: 'Agendado',
        color: OwanyTheme.info,
        icon: Icons.event_available_rounded,
        terminal: false,
      );
    }

    return const AgendamentoStatusMeta(
      key: 'pendente',
      label: 'Pendente',
      color: OwanyTheme.warning,
      icon: Icons.hourglass_bottom_rounded,
      terminal: false,
    );
  }

  static bool isDone(AgendamentoMaintenanceDto a) => metaFromDto(a).terminal;

  static AgendamentoStatusMeta metaFromDto(AgendamentoMaintenanceDto a) {
    final key = statusKey(a.status);

    if (key.contains('cancelado') || key.contains('recusado')) {
      return const AgendamentoStatusMeta(
        key: 'cancelado',
        label: 'Cancelado',
        color: OwanyTheme.error,
        icon: Icons.cancel_rounded,
        terminal: true,
      );
    }

    if (key.contains('concluido') || key.contains('avaliado')) {
      return const AgendamentoStatusMeta(
        key: 'concluido',
        label: 'Concluido',
        color: OwanyTheme.success,
        icon: Icons.task_alt_rounded,
        terminal: true,
      );
    }

    if (key.contains('emandamento') || key.contains('iniciado') || key.contains('execucao')) {
      return const AgendamentoStatusMeta(
        key: 'emandamento',
        label: 'Em andamento',
        color: OwanyTheme.info,
        icon: Icons.play_circle_fill_rounded,
        terminal: false,
      );
    }

    if (key.contains('confirmado') || key.contains('aceito')) {
      return const AgendamentoStatusMeta(
        key: 'confirmado',
        label: 'Confirmado',
        color: OwanyTheme.success,
        icon: Icons.check_circle_rounded,
        terminal: false,
      );
    }

    if (key.contains('agendado') || key.contains('aguardando')) {
      return const AgendamentoStatusMeta(
        key: 'agendado',
        label: 'Agendado',
        color: OwanyTheme.info,
        icon: Icons.event_available_rounded,
        terminal: false,
      );
    }

    return const AgendamentoStatusMeta(
      key: 'pendente',
      label: 'Pendente',
      color: OwanyTheme.warning,
      icon: Icons.hourglass_bottom_rounded,
      terminal: false,
    );
  }

  static bool isOverdue(AgendamentoMaintenanceDto a) {
    if (isDone(a)) return false;
    return a.dataAgendada.isBefore(DateTime.now());
  }

  static bool isToday(AgendamentoMaintenanceDto a) {
    final now = DateTime.now();
    return a.dataAgendada.year == now.year &&
        a.dataAgendada.month == now.month &&
        a.dataAgendada.day == now.day;
  }

  static bool isNext7Days(AgendamentoMaintenanceDto a) {
    if (isDone(a)) return false;
    final now = DateTime.now();
    return a.dataAgendada.isAfter(now) && a.dataAgendada.isBefore(now.add(const Duration(days: 7)));
  }

  static bool canReply(String? status) {
    final s = statusKey(status);
    return s.contains('pendente') || s.contains('agendado') || s.contains('confirmacaopendente');
  }

  static bool canConfirm(String? status) {
    final s = statusKey(status);
    return s.contains('aceito') || s.contains('aguardandoconfirmacao') || s.contains('confirmacaopendente');
  }

  static bool canStart(String? status) {
    final s = statusKey(status);
    return s.contains('confirmado') || s.contains('agendado');
  }

  static bool canFinish(String? status) {
    final s = statusKey(status);
    return !(s.contains('concluido') || s.contains('avaliado') || s.contains('cancelado') || s.contains('recusado'));
  }

  static bool canCancel(String? status) {
    final s = statusKey(status);
    return !(s.contains('concluido') || s.contains('avaliado') || s.contains('cancelado') || s.contains('recusado'));
  }

  static bool canEdit(String? status) {
    final s = statusKey(status);
    return !(s.contains('concluido') || s.contains('avaliado') || s.contains('cancelado') || s.contains('recusado'));
  }

  static String apartmentLabel(AgendamentoMaintenanceDto a, {String fallback = 'Condominio geral'}) {
    final num = (a.numeroApartamento ?? '').trim();
    final block = (a.blocoApartamento ?? '').trim();
    if (num.isEmpty && block.isEmpty) return fallback;
    if (block.isEmpty) return 'Apt $num';
    if (num.isEmpty) return 'Bloco $block';
    return 'Apt $num - Bloco $block';
  }

  static String relativeTimeLabel(DateTime target) {
    final now = DateTime.now();
    final startNow = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final startTarget = DateTime(target.year, target.month, target.day, target.hour, target.minute);

    final diff = startTarget.difference(startNow);
    final minutes = diff.inMinutes;

    if (minutes.abs() < 60) {
      if (minutes == 0) return 'Agora';
      if (minutes > 0) return 'Em $minutes min';
      return '${minutes.abs()} min atrasado';
    }

    final hours = diff.inHours;
    if (hours.abs() < 24) {
      if (hours > 0) return 'Em $hours h';
      return '${hours.abs()} h atrasado';
    }

    final days = diff.inDays;
    if (days == 0) return 'Hoje';
    if (days == 1) return 'Amanha';
    if (days == -1) return 'Ontem';
    if (days > 1) return 'Em $days dias';
    return '${days.abs()} dias atrasado';
  }

  static String compactDate(DateTime value) => DateFormat('dd/MM HH:mm').format(value);
  static String fullDate(DateTime value) => DateFormat('dd/MM/yyyy HH:mm').format(value);
}

enum AgendamentoQuickFilter {
  todos,
  manutencaoGeral,
  atrasados,
  hoje,
  proximos7,
  pendentes,
  agendados,
  confirmados,
  andamento,
  concluidos,
  cancelados,
}

class AgendamentoFilterOption {
  final AgendamentoQuickFilter filter;
  final String label;
  final IconData icon;

  const AgendamentoFilterOption({
    required this.filter,
    required this.label,
    required this.icon,
  });
}

class AgendamentoListMetrics {
  final int total;
  final int atrasados;
  final int hoje;
  final int proximos7;
  final int pendentes;
  final int andamento;
  final int concluidos;
  final int cancelados;

  const AgendamentoListMetrics({
    required this.total,
    required this.atrasados,
    required this.hoje,
    required this.proximos7,
    required this.pendentes,
    required this.andamento,
    required this.concluidos,
    required this.cancelados,
  });

  factory AgendamentoListMetrics.from(List<AgendamentoMaintenanceDto> list) {
    var atrasados = 0;
    var hoje = 0;
    var proximos7 = 0;
    var pendentes = 0;
    var andamento = 0;
    var concluidos = 0;
    var cancelados = 0;

    for (final item in list) {
      final key = AgendamentoStatusHelper.statusKey(item.status);
      if (AgendamentoStatusHelper.isOverdue(item)) atrasados++;
      if (AgendamentoStatusHelper.isToday(item)) hoje++;
      if (AgendamentoStatusHelper.isNext7Days(item)) proximos7++;
      if (key.contains('pendente')) pendentes++;
      if (key.contains('emandamento') || key.contains('iniciado') || key.contains('execucao')) andamento++;
      if (key.contains('concluido') || key.contains('avaliado')) concluidos++;
      if (key.contains('cancelado') || key.contains('recusado')) cancelados++;
    }

    return AgendamentoListMetrics(
      total: list.length,
      atrasados: atrasados,
      hoje: hoje,
      proximos7: proximos7,
      pendentes: pendentes,
      andamento: andamento,
      concluidos: concluidos,
      cancelados: cancelados,
    );
  }
}

class AgendamentoHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? sideLabel;

  const AgendamentoHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.sideLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.primaryOrange.withValues(alpha: 0.85),
            OwanyTheme.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (sideLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                sideLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AgendamentoMetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const AgendamentoMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const Spacer(),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: OwanyTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendamentoMetricGrid extends StatelessWidget {
  final AgendamentoListMetrics metrics;

  const AgendamentoMetricGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 920;
    final crossAxisCount = isWide ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isWide ? 1.8 : 1.45,
      children: [
        AgendamentoMetricCard(
          label: 'Total',
          value: metrics.total,
          icon: Icons.calendar_month_rounded,
          color: OwanyTheme.primaryOrange,
        ),
        AgendamentoMetricCard(
          label: 'Atrasados',
          value: metrics.atrasados,
          icon: Icons.warning_amber_rounded,
          color: OwanyTheme.error,
        ),
        AgendamentoMetricCard(
          label: 'Hoje',
          value: metrics.hoje,
          icon: Icons.today_rounded,
          color: OwanyTheme.warning,
        ),
        AgendamentoMetricCard(
          label: 'Prox. 7 dias',
          value: metrics.proximos7,
          icon: Icons.event_available_rounded,
          color: OwanyTheme.info,
        ),
        AgendamentoMetricCard(
          label: 'Pendentes',
          value: metrics.pendentes,
          icon: Icons.schedule_rounded,
          color: OwanyTheme.warning,
        ),
        AgendamentoMetricCard(
          label: 'Em andamento',
          value: metrics.andamento,
          icon: Icons.play_circle_rounded,
          color: OwanyTheme.info,
        ),
        AgendamentoMetricCard(
          label: 'Concluidos',
          value: metrics.concluidos,
          icon: Icons.task_alt_rounded,
          color: OwanyTheme.success,
        ),
        AgendamentoMetricCard(
          label: 'Cancelados',
          value: metrics.cancelados,
          icon: Icons.cancel_rounded,
          color: OwanyTheme.error,
        ),
      ],
    );
  }
}
class AgendamentoSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hint;

  const AgendamentoSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: hint,
        suffixIcon: hasText
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: _tx(context, 'Limpar', 'Clear'),
              )
            : null,
      ),
    );
  }
}

class AgendamentoFilterChips extends StatelessWidget {
  final List<AgendamentoFilterOption> options;
  final AgendamentoQuickFilter selected;
  final ValueChanged<AgendamentoQuickFilter> onSelect;

  const AgendamentoFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => FilterChip(
              avatar: Icon(option.icon, size: 14),
              label: Text(option.label),
              selected: selected == option.filter,
              onSelected: (_) => onSelect(option.filter),
            ),
          )
          .toList(),
    );
  }
}

class AgendamentoStatusPill extends StatelessWidget {
  final AgendamentoStatusMeta meta;

  const AgendamentoStatusPill({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 13, color: meta.color),
          const SizedBox(width: 6),
          Text(
            meta.label,
            style: TextStyle(
              color: meta.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendamentoTimePill extends StatelessWidget {
  final AgendamentoMaintenanceDto agendamento;

  const AgendamentoTimePill({super.key, required this.agendamento});

  @override
  Widget build(BuildContext context) {
    Color color = OwanyTheme.info;
    IconData icon = Icons.event_available_rounded;
    String label = AgendamentoStatusHelper.relativeTimeLabel(agendamento.dataAgendada);

    if (AgendamentoStatusHelper.isOverdue(agendamento)) {
      color = OwanyTheme.error;
      icon = Icons.warning_amber_rounded;
    } else if (AgendamentoStatusHelper.isToday(agendamento)) {
      color = OwanyTheme.warning;
      icon = Icons.today_rounded;
      label = 'Hoje ${DateFormat('HH:mm').format(agendamento.dataAgendada)}';
    } else if (AgendamentoStatusHelper.isNext7Days(agendamento)) {
      color = OwanyTheme.info;
      icon = Icons.event_available_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendamentoSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const AgendamentoSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: OwanyTheme.primaryOrange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class AgendamentoInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const AgendamentoInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: OwanyTheme.primaryOrange),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? line
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: line,
            ),
    );
  }
}

class AgendamentoActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool outlined;

  const AgendamentoActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: color),
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
class AgendamentoListCard extends StatelessWidget {
  final AgendamentoMaintenanceDto agendamento;
  final bool isStaff;
  final bool isMorador;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onConfirm;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;
  final VoidCallback? onReplyAccept;
  final VoidCallback? onReplyReject;

  const AgendamentoListCard({
    super.key,
    required this.agendamento,
    required this.isStaff,
    required this.isMorador,
    required this.onOpen,
    this.onEdit,
    this.onConfirm,
    this.onStart,
    this.onFinish,
    this.onCancel,
    this.onReplyAccept,
    this.onReplyReject,
  });

  @override
  Widget build(BuildContext context) {
    final meta = AgendamentoStatusHelper.meta(context, agendamento.status);
    final cardColor = meta.color;
    final aptLabel = AgendamentoStatusHelper.apartmentLabel(agendamento);
    final dateLabel = AgendamentoStatusHelper.fullDate(agendamento.dataAgendada);

    final canEdit = isStaff && AgendamentoStatusHelper.canEdit(agendamento.status);
    final canConfirm = isStaff && AgendamentoStatusHelper.canConfirm(agendamento.status);
    final canStart = isStaff && AgendamentoStatusHelper.canStart(agendamento.status);
    final canFinish = isStaff && AgendamentoStatusHelper.canFinish(agendamento.status);
    final canCancel = isStaff && AgendamentoStatusHelper.canCancel(agendamento.status);
    final canReply = isMorador && AgendamentoStatusHelper.canReply(agendamento.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  meta.icon,
                                  color: cardColor,
                                  size: 18,
                                ),
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
                                            agendamento.titulo,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  OwanyTheme.textPrimary(context),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AgendamentoStatusPill(meta: meta),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (agendamento.descricao ?? '')
                                              .trim()
                                              .isEmpty
                                          ? 'Sem descricao informada.'
                                          : agendamento.descricao!.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            OwanyTheme.textMutedColor(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isStaff) ...[
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'concluir' &&
                                        onFinish != null) {
                                      onFinish!();
                                    }
                                    if (value == 'cancelar' &&
                                        onCancel != null) {
                                      onCancel!();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (canFinish)
                                      PopupMenuItem(
                                        value: 'concluir',
                                        child: Text(_tx(
                                            context, 'Concluir', 'Complete')),
                                      ),
                                    if (canCancel)
                                      PopupMenuItem(
                                        value: 'cancelar',
                                        child: Text(
                                            _tx(context, 'Cancelar', 'Cancel')),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ((agendamento.tipoSolicitacaoNome ?? agendamento.tipo ?? '').trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.info.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.category_outlined, size: 12, color: OwanyTheme.info),
                                      const SizedBox(width: 4),
                                      Text(
                                        (agendamento.tipoSolicitacaoNome ?? agendamento.tipo ?? '').trim(),
                                        style: const TextStyle(
                                          color: OwanyTheme.info,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if ((agendamento.areaTecnicaNome ?? agendamento.areaTecnicaId ?? '').trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.primaryBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.engineering_outlined, size: 12, color: OwanyTheme.primaryBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        (agendamento.areaTecnicaNome ?? agendamento.areaTecnicaId ?? '').trim(),
                                        style: const TextStyle(
                                          color: OwanyTheme.primaryBlue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              AgendamentoTimePill(agendamento: agendamento),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: OwanyTheme.textMutedColor(context)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 12,
                                      color:
                                          OwanyTheme.textMutedColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM HH:mm')
                                          .format(agendamento.dataAgendada),
                                      style: TextStyle(
                                        color: OwanyTheme.textMutedColor(
                                            context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.home_work_outlined,
                                size: 14,
                                color: OwanyTheme.textMutedColor(context),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  aptLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: OwanyTheme.textPrimary(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: OwanyTheme.textMutedColor(context),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  agendamento.responsavelTecnicoNome ??
                                      agendamento.responsavelTecnicoId ??
                                      'Não definido',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: OwanyTheme.textPrimary(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: OwanyTheme.textMutedColor(context),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: OwanyTheme.textMutedColor(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (canConfirm ||
                              canStart ||
                              canFinish ||
                              canCancel ||
                              canReply) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (canConfirm && onConfirm != null)
                                  AgendamentoActionChip(
                                    label: 'Confirmar',
                                    icon: Icons.check_circle_rounded,
                                    onTap: onConfirm!,
                                    color: OwanyTheme.success,
                                  ),
                                if (canStart && onStart != null)
                                  AgendamentoActionChip(
                                    label: 'Iniciar',
                                    icon: Icons.play_circle_rounded,
                                    onTap: onStart!,
                                    color: OwanyTheme.info,
                                  ),
                                if (canFinish && onFinish != null)
                                  AgendamentoActionChip(
                                    label: 'Concluir',
                                    icon: Icons.task_alt_rounded,
                                    onTap: onFinish!,
                                    color: OwanyTheme.success,
                                    outlined: false,
                                  ),
                                if (canCancel && onCancel != null)
                                  AgendamentoActionChip(
                                    label: 'Cancelar',
                                    icon: Icons.cancel_outlined,
                                    onTap: onCancel!,
                                    color: OwanyTheme.error,
                                  ),
                                if (canReply && onReplyAccept != null)
                                  AgendamentoActionChip(
                                    label: 'Aceitar',
                                    icon: Icons.thumb_up_alt_rounded,
                                    onTap: onReplyAccept!,
                                    color: OwanyTheme.success,
                                    outlined: false,
                                  ),
                                if (canReply && onReplyReject != null)
                                  AgendamentoActionChip(
                                    label: 'Recusar',
                                    icon: Icons.thumb_down_alt_rounded,
                                    onTap: onReplyReject!,
                                    color: OwanyTheme.error,
                                  ),
                              ],
                            ),
                          ],
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

class AgendamentoTimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final bool current;

  const AgendamentoTimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.current,
  });
}

class AgendamentoTimeline extends StatelessWidget {
  final List<AgendamentoTimelineStep> steps;

  const AgendamentoTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final s = steps[index];
        final isLast = index == steps.length - 1;
        final color = s.done
            ? OwanyTheme.success
            : s.current
                ? OwanyTheme.primaryOrange
                : OwanyTheme.borderColor(context);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: s.done
                        ? OwanyTheme.success.withValues(alpha: 0.15)
                        : s.current
                            ? OwanyTheme.primaryOrange.withValues(alpha: 0.12)
                            : OwanyTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color),
                  ),
                  child: Icon(
                    s.icon,
                    size: 16,
                    color: s.done
                        ? OwanyTheme.success
                        : s.current
                            ? OwanyTheme.primaryOrange
                            : OwanyTheme.textMutedColor(context),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: s.done ? OwanyTheme.success.withValues(alpha: 0.3) : OwanyTheme.borderColor(context),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.subtitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: OwanyTheme.textMutedColor(context),
                        fontSize: 12,
                      ),
                    ),
                    if (!isLast) const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
class AgendamentoEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onReload;

  const AgendamentoEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: OwanyTheme.primaryOrange, size: 38),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: OwanyTheme.textMutedColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onReload != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_tx(context, 'Atualizar', 'Refresh')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AgendamentoLoadingBlock extends StatelessWidget {
  final String text;

  const AgendamentoLoadingBlock({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: OwanyTheme.primaryOrange),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendamentoInsightBanner extends StatelessWidget {
  final AgendamentoListMetrics metrics;

  const AgendamentoInsightBanner({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    String headline = 'Agenda equilibrada';
    String detail = 'Sem urgencias elevadas no momento.';
    Color color = OwanyTheme.success;
    IconData icon = Icons.verified_rounded;

    if (metrics.atrasados >= 5) {
      headline = 'Muitos agendamentos atrasados';
      detail = 'Priorize os itens em atraso para reduzir pendencias.';
      color = OwanyTheme.error;
      icon = Icons.warning_amber_rounded;
    } else if (metrics.atrasados > 0) {
      headline = 'Ha itens em atraso';
      detail = 'Revise os casos atrasados para evitar acumulacao.';
      color = OwanyTheme.warning;
      icon = Icons.pending_actions_rounded;
    } else if (metrics.hoje > 0) {
      headline = 'Dia ativo de manutencao';
      detail = '${metrics.hoje} atendimento(s) para hoje.';
      color = OwanyTheme.info;
      icon = Icons.today_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
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
