import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../providers/historico_ocupacao_provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/historico_ocupacao_card.dart';
import '../../widgets/standard_glass_app_bar.dart';
import '../../utils/app_logger.dart';

class HistoricoOcupacaoScreen extends StatefulWidget {
  final String? apartamentoId;
  final String? moradorId;
  final String titulo;

  const HistoricoOcupacaoScreen({super.key, this.apartamentoId, this.moradorId, required this.titulo});

  @override
  State<HistoricoOcupacaoScreen> createState() => _HistoricoOcupacaoScreenState();
}

class _HistoricoOcupacaoScreenState extends State<HistoricoOcupacaoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarHistorico();
    });
  }

  Future<void> _carregarHistorico() async {
    final provider = context.read<HistoricoOcupacaoProvider>();

    if (widget.apartamentoId != null) {
      await provider.carregarHistoricoApartamento(widget.apartamentoId!);
    } else if (widget.moradorId != null) {
      await provider.carregarHistoricoMorador(widget.moradorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: widget.titulo.isNotEmpty ? widget.titulo : AppLocalizations.of(context)!.history_title,
        icon: Icons.history_rounded,
        showBackButton: true,
      ),
      body: Consumer<HistoricoOcupacaoProvider>(
        builder: (context, provider, _) {
          final historico = widget.apartamentoId != null ? provider.historicoApartamento : provider.historicoMorador;

          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange)),
            );
          }

          if (historico.isEmpty) {
            return HistoricoVazioWidget(mensagem: AppLocalizations.of(context)!.history_no_records);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, size: 18, color: OwanyTheme.primaryOrange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${historico.length} ${AppLocalizations.of(context)!.history_records_count}',
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // History cards
                ...List.generate(historico.length, (index) {
                  return HistoricoOcupacaoCard(
                    historico: historico[index],
                    onTap: () {
                      AppLogger.info('Historico', 'Tap em: ${historico[index].id}');
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
