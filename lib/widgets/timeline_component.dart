// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/owany_theme.dart';

/// Timeline Status Event
class TimelineEvent {
  final String status;
  final String label;
  final DateTime dateTime;
  final String? description;
  final Color color;
  final IconData icon;
  final bool isCompleted;

  const TimelineEvent({
    required this.status,
    required this.label,
    required this.dateTime,
    this.description,
    required this.color,
    required this.icon,
    required this.isCompleted,
  });
}

/// Timeline Component - Shows progression of request status
class TimelineComponent extends StatelessWidget {
  final List<TimelineEvent> events;
  final int currentEventIndex;
  final Axis direction;
  final double itemHeight;

  const TimelineComponent({
    required this.events,
    required this.currentEventIndex,
    this.direction = Axis.vertical,
    this.itemHeight = 120,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    if (direction == Axis.horizontal) {
      return _buildHorizontalTimeline(context);
    } else {
      return _buildVerticalTimeline(context);
    }
  }

  /// Builds vertical timeline (default)
  Widget _buildVerticalTimeline(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final isActive = index <= currentEventIndex;

        return SizedBox(
          height: itemHeight,
          child: Row(
            children: [
              // Timeline line
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    // Top connector
                    if (index > 0)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: events[index - 1].color.withValues(alpha: 0.3),
                        ),
                      ),
                    // Circle indicator
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive ? event.color : OwanyTheme.borderLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: event.color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          event.icon,
                          color: isActive
                              ? Colors.white
                              : OwanyTheme.textMutedColor(context),
                          size: 24,
                        ),
                      ),
                    ),
                    // Bottom connector
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: event.color.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              // Event details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status label
                      Text(
                        event.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? event.color
                              : OwanyTheme.textMutedColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Date and time
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: OwanyTheme.textMutedColor(context),
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds horizontal timeline (compact)
  Widget _buildHorizontalTimeline(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: List.generate(
            events.length,
            (index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final isActive = index <= currentEventIndex;

              return Row(
                children: [
                  // Circle with connector
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? event.color
                              : OwanyTheme.borderLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isActive)
                              BoxShadow(
                                color: event.color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            event.icon,
                            color: isActive
                                ? Colors.white
                                : OwanyTheme.textMutedColor(context),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? event.color
                              : OwanyTheme.textMutedColor(context),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Connector line
                  if (!isLast)
                    Container(
                      width: 30,
                      height: 2,
                      color: event.color.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Status Progress Indicator with deadline info
class DeadlineIndicator extends StatelessWidget {
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isDelayed;

  const DeadlineIndicator({
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    required this.isCompleted,
    required this.isDelayed,
    super.key,
  });

  int? get _remainingDays {
    if (isCompleted || completedAt != null) return null;
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  Color _getIndicatorColor() {
    if (isCompleted || completedAt != null) return OwanyTheme.success;
    if (isDelayed) return OwanyTheme.error;
    if (_remainingDays != null && _remainingDays! <= 2) {
      return OwanyTheme.warning;
    }
    return OwanyTheme.success;
  }

  String _getStatusText() {
    if (isCompleted || completedAt != null) {
      return '✓ Concluído';
    }
    if (isDelayed) {
      final delayedDays = DateTime.now().difference(dueDate!).inDays;
      return '⚠ $delayedDays dia(s) em atraso';
    }
    final days = _remainingDays;
    if (days == null) return 'Sem prazo definido';
    if (days == 0) return '⚡ Vence hoje';
    if (days == 1) return '⏰ Vence amanhã';
    return '📅 $days dia(s) restante(s)';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getIndicatorColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted || completedAt != null
                  ? Icons.check_circle_rounded
                  : isDelayed
                  ? Icons.error_outline_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (dueDate != null)
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: OwanyTheme.textMutedColor(context),
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
