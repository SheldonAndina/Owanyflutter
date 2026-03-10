import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';
import '../models/enums.dart';

/// Status badge with semantic coloring
class StatusBadge extends StatelessWidget {
  final StatusSolicitacao status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  Color _getStatusColor() {
    switch (status) {
      case StatusSolicitacao.Pendente:
        return OwanyTheme.warning;
      case StatusSolicitacao.EmAndamento:
        return OwanyTheme.primaryBlue;
      case StatusSolicitacao.EmAnalise:
        return OwanyTheme.info;
      case StatusSolicitacao.Aguardando:
        return OwanyTheme.primaryOrange;
      case StatusSolicitacao.Concluido:
        return OwanyTheme.success;
      case StatusSolicitacao.Cancelado:
        return OwanyTheme.error;
      case StatusSolicitacao.Rejeitado:
        return OwanyTheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case StatusSolicitacao.Pendente:
        return Icons.schedule;
      case StatusSolicitacao.EmAndamento:
        return Icons.loop;
      case StatusSolicitacao.EmAnalise:
        return Icons.search;
      case StatusSolicitacao.Aguardando:
        return Icons.hourglass_empty;
      case StatusSolicitacao.Concluido:
        return Icons.check_circle;
      case StatusSolicitacao.Cancelado:
        return Icons.cancel;
      case StatusSolicitacao.Rejeitado:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize, color: color),
          SizedBox(width: 6),
          Text(
            status.toPortuguese(),
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
