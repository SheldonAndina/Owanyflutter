import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/owany_theme.dart';
import '../providers/solicitacoes_provider.dart';
import '../providers/agendamentos_provider.dart';

/// Widget que exibe alertas de solicitações e agendamentos pendentes do morador
/// Mostra um banner comunicativo se houver itens pendentes
class PendingAlertsBanner extends StatelessWidget {
  final VoidCallback? onTapSolicitacoes;
  final VoidCallback? onTapAgendamentos;

  const PendingAlertsBanner({
    super.key,
    this.onTapSolicitacoes,
    this.onTapAgendamentos,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SolicitacoesProvider, AgendamentosProvider>(
      builder: (context, solProvider, agendProvider, _) {
        // Contar solicitações pendentes (não concluídas)
        final solicitacoesPendentes = solProvider.solicitacoes
            .where((s) => s.status != 'Concluido' && s.status != 'Fechado')
            .length;

        // Contar agendamentos pendentes (não concluídos)
        final agendamentosPendentes = agendProvider.agendamentos
            .where((a) => a.status != 'Concluido' && a.status != 'Cancelado')
            .length;

        // Se não há pendências, não mostra nada
        if (solicitacoesPendentes == 0 && agendamentosPendentes == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // BANNER DE SOLICITAÇÕES
            if (solicitacoesPendentes > 0)
                _buildAlertTile(
                context,
                icon: Icons.task_alt_rounded,
                title:
                    '$solicitacoesPendentes ${_pluralize('solicitação pendente', solicitacoesPendentes)}',
                subtitle: 'Clique para revisar',
                color: OwanyTheme.warning,
                onTap: onTapSolicitacoes,
              ),

            if (solicitacoesPendentes > 0 && agendamentosPendentes > 0)
              const SizedBox(height: 8),

            // BANNER DE AGENDAMENTOS
            if (agendamentosPendentes > 0)
                _buildAlertTile(
                context,
                icon: Icons.calendar_today_rounded,
                title:
                    '$agendamentosPendentes ${_pluralize('agendamento pendente', agendamentosPendentes)}',
                subtitle: 'Aguardando sua confirmação',
                color: OwanyTheme.info,
                onTap: onTapAgendamentos,
              ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Constrói um tile de alerta individual
  Widget _buildAlertTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontWeight: FontWeight.bold,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  /// Pluraliza a string baseado no count
  static String _pluralize(String singular, int count) {
    if (count == 1) return singular;
    // Remove a última letra ou ajusta respeitando português
    final parts = singular.split(' ');
    final lastWord = parts.last;
    // Adiciona 's' para pluralizar (simplificado)
    parts[parts.length - 1] = '${lastWord}s';
    return parts.join(' ');
  }
}
