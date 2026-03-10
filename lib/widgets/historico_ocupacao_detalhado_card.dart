import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/owany_theme.dart';

/// Card widget para exibir histórico de ocupação detalhado
class HistoricoOcupacaoDetalhadoCard extends StatelessWidget {
  final HistoricoOcupacao historico;
  final VoidCallback? onTap;
  final VoidCallback? onRegistrarSaida;

  const HistoricoOcupacaoDetalhadoCard({super.key, required this.historico, this.onTap, this.onRegistrarSaida});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dataEntradaFormatada = dateFormat.format(historico.dataEntrada);
    final dataSaidaFormatada = historico.dataSaida != null ? dateFormat.format(historico.dataSaida!) : 'Presente';

    final isAtivo = historico.estaAtivo;
    final corStatus = isAtivo ? OwanyTheme.success : OwanyTheme.textMutedColor(context);
    final iconeStatus = isAtivo ? Icons.check_circle_rounded : Icons.history_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAtivo ? OwanyTheme.success.withValues(alpha: 0.3) : OwanyTheme.borderColor(context),
              width: isAtivo ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.primaryBrown.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nome + Status
              Row(
                children: [
                  // Ícone de status
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(iconeStatus, color: corStatus, size: 20),
                  ),
                  SizedBox(width: 12),

                  // Nome do morador (com fallback para residentes sem nome)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historico.nomeMorador.trim().isNotEmpty 
                              ? historico.nomeMorador 
                              : 'Residente ${historico.numeroApartamento ?? ''}'.trim(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: OwanyTheme.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          isAtivo ? 'Vivendo aqui' : 'Morador anterior',
                          style: TextStyle(fontSize: 12, color: corStatus, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Badge de duração
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      historico.duracaoFormatada,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OwanyTheme.primaryOrange),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14),

              // Informações de datas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: OwanyTheme.background, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    // Data de entrada
                    Row(
                      children: [
                        Icon(Icons.login_rounded, size: 16, color: OwanyTheme.success),
                        SizedBox(width: 8),
                        Text(
                          'Entrada:',
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dataEntradaFormatada,
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),
                    Divider(height: 1, color: OwanyTheme.borderColor(context).withValues(alpha: 0.5)),
                    SizedBox(height: 8),

                    // Data de saída ou "até presente"
                    Row(
                      children: [
                        Icon(
                          isAtivo ? Icons.calendar_today_rounded : Icons.logout_rounded,
                          size: 16,
                          color: isAtivo ? OwanyTheme.primaryOrange : OwanyTheme.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isAtivo ? 'Até:' : 'Saída:',
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dataSaidaFormatada,
                          style: TextStyle(
                            fontSize: 13,
                            color: isAtivo ? OwanyTheme.primaryOrange : OwanyTheme.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Apartamento info
              if (historico.numeroApartamento != null || historico.blocoApartamento != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.apartment_rounded, size: 14, color: OwanyTheme.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Apartamento ${historico.numeroApartamento ?? ''}/${historico.blocoApartamento ?? ''}',
                      style: TextStyle(fontSize: 12, color: OwanyTheme.textMuted),
                    ),
                  ],
                ),
              ],

              // Motivo da saída (se houver)
              if (historico.motivoSaida != null && historico.motivoSaida!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OwanyTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, size: 14, color: OwanyTheme.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          historico.motivoSaida!,
                          style: TextStyle(fontSize: 12, color: OwanyTheme.error, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botão de registrar saída (se ainda estiver ativo)
              if (isAtivo && onRegistrarSaida != null) ...[
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRegistrarSaida,
                    icon: Icon(Icons.logout_rounded, size: 16),
                    label: Text('Registrar Saída'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OwanyTheme.error,
                      side: BorderSide(color: OwanyTheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
