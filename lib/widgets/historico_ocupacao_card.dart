import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/historico_ocupacao.dart';
import '../theme/owany_theme.dart';

/// Card widget para exibir um item do histórico
class HistoricoOcupacaoCard extends StatelessWidget {
  final HistoricoOcupacaoResumo historico;
  final VoidCallback? onTap;

  const HistoricoOcupacaoCard({super.key, required this.historico, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(historico.dataMovimentacao);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OwanyTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.textPrimary(context).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Tipo icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: historico.tipoColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(historico.tipoIcon, color: historico.tipoColor, size: 20),
              ),
              SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            historico.nomeMorador,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OwanyTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: historico.tipoColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            historico.tipoMovimentacao,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: historico.tipoColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      historico.descricao,
                      style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: OwanyTheme.textMuted),
                        SizedBox(width: 4),
                        Text(formattedDate, style: TextStyle(fontSize: 11, color: OwanyTheme.textMuted)),
                        SizedBox(width: 12),
                        Icon(Icons.person_rounded, size: 12, color: OwanyTheme.textMuted),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            historico.nomeExecutor,
                            style: TextStyle(fontSize: 11, color: OwanyTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),

              // Arrow icon
              Icon(Icons.chevron_right_rounded, color: OwanyTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for history
class HistoricoVazioWidget extends StatelessWidget {
  final String? mensagem;

  const HistoricoVazioWidget({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: OwanyTheme.softOrange, borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.history_rounded, size: 40, color: OwanyTheme.primaryOrange),
            ),
            SizedBox(height: 16),
            Text(
              'Sem histórico',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
            ),
            SizedBox(height: 8),
            Text(
              mensagem ?? 'Nenhuma movimentação registrada ainda',
              style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
