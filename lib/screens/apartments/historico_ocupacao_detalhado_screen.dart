// for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// import 'package:path_provider/path_provider.dart'; // removido para web
// import 'package:printing/printing.dart'; // removido para web

import '../../generated_l10n/app_localizations.dart';
import '../../providers/historico_ocupacao_provider.dart';
import '../../providers/apartamentos_provider.dart';
import '../../models/historico_ocupacao.dart';
import '../../models/models.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/historico_ocupacao_detalhado_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';
import '../../widgets/themed_alert_dialog.dart';

class _TimelineData {
  final List<FlSpot> spots;
  final List<DateTime> datas;
  _TimelineData(this.spots, this.datas);
}

/// Tela dedicada para exibir histórico detalhado de ocupação de moradores
class HistoricoOcupacaoDetalhadoScreen extends StatefulWidget {
  final String? apartamentoId;
  final String? moradorId;
  final String titulo;

  const HistoricoOcupacaoDetalhadoScreen({super.key, this.apartamentoId, this.moradorId, required this.titulo});

  @override
  State<HistoricoOcupacaoDetalhadoScreen> createState() => _HistoricoOcupacaoDetalhadoScreenState();
}

class _HistoricoOcupacaoDetalhadoScreenState extends State<HistoricoOcupacaoDetalhadoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _normalizarTexto(String texto) {
    var t = texto.toLowerCase().trim();
    t = t
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
        .replaceAll('ç', 'c');
    return t;
  }

  bool _isEntradaEvento(HistoricoOcupacaoResumo evento) {
    final tipo = _normalizarTexto(evento.tipoMovimentacao);
    if (tipo == 'entrada') return true;
    if (tipo == 'transferencia') {
      if (evento.apartamentoDestinoId != null && evento.apartamentoDestinoId!.isNotEmpty) {
        return evento.apartamentoDestinoId == evento.apartamentoId;
      }
      if (evento.numeroApartamentoDestino != null && evento.numeroApartamentoDestino!.isNotEmpty) {
        return evento.numeroApartamentoDestino == evento.numeroApartamento;
      }
      return true;
    }
    return false;
  }

  bool _isSaidaEvento(HistoricoOcupacaoResumo evento) {
    final tipo = _normalizarTexto(evento.tipoMovimentacao);
    if (tipo == 'saida') return true;
    if (tipo == 'transferencia') {
      if (evento.apartamentoOrigemId != null && evento.apartamentoOrigemId!.isNotEmpty) {
        return evento.apartamentoOrigemId == evento.apartamentoId;
      }
      if (evento.numeroApartamentoOrigem != null && evento.numeroApartamentoOrigem!.isNotEmpty) {
        return evento.numeroApartamentoOrigem == evento.numeroApartamento;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarHistorico();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    final provider = context.read<HistoricoOcupacaoProvider>();

    if (widget.apartamentoId != null) {
      try {
        await context
            .read<ApartamentosProvider>()
            .carregarApartamento(widget.apartamentoId!);
      } catch (_) {}
      await provider.carregarHistoricoDetalhadoApartamento(widget.apartamentoId!);
    } else if (widget.moradorId != null) {
      await provider.carregarHistoricoDetalhadoMorador(widget.moradorId!);
    }
  }

  Future<void> _showRegistrarSaidaDialog(String moradorId, String nomeMorador) async {
    if (moradorId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(AppLocalizations.of(context)!.apartments_exit_invalid_resident, type: SnackBarType.error),
        );
      }
      return;
    }
    final motivoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: OwanyTheme.error),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.apartments_register_exit,
                style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.apartments_confirm_exit(nomeMorador),
              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.apartments_exit_reason,
                hintText: AppLocalizations.of(context)!.apartments_exit_reason_hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: OwanyTheme.primaryOrange, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton.secondary(
            text: AppLocalizations.of(context)!.common_cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          SizedBox(width: 8),
          PrimaryButton.error(
            text: AppLocalizations.of(context)!.apartments_confirm_exit_button,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<HistoricoOcupacaoProvider>();
      final sucesso = await provider.registrarSaida(
        moradorId,
        motivo: motivoController.text.isNotEmpty ? motivoController.text : null,
      );

      if (sucesso && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(OwanyTheme.snackBar(AppLocalizations.of(context)!.apartments_exit_success));
        // Refresh history and apartment detail (if viewing by apartment)
        await _carregarHistorico();
        if (widget.apartamentoId != null) {
          await context.read<ApartamentosProvider>().carregarApartamento(widget.apartamentoId!);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(AppLocalizations.of(context)!.apartments_exit_error, type: SnackBarType.error),
        );
      }
    }

    motivoController.dispose();
  }

  String _labelFiltro(FiltroPeriodo filtro) {
    final l10n = AppLocalizations.of(context)!;
    switch (filtro) {
      case FiltroPeriodo.ultimos30Dias:
        return l10n.history_filter_30_days;
      case FiltroPeriodo.ultimos6Meses:
        return l10n.history_filter_6_months;
      case FiltroPeriodo.ultimos12Meses:
        return l10n.history_filter_12_months;
      case FiltroPeriodo.todos:
        return l10n.history_filter_all;
    }
  }

  _TimelineData _buildTimelineData(List historicos) {
    if (historicos.isEmpty) return _TimelineData([], []);
    final deltas = <DateTime, int>{};
    for (final h in historicos) {
      final entrada = DateTime(h.dataEntrada.year, h.dataEntrada.month, h.dataEntrada.day);
      deltas[entrada] = (deltas[entrada] ?? 0) + 1;

      final saida = h.dataSaida != null ? DateTime(h.dataSaida!.year, h.dataSaida!.month, h.dataSaida!.day + 1) : null;
      if (saida != null) {
        deltas[saida] = (deltas[saida] ?? 0) - 1;
      }
    }

    final orderedDates = deltas.keys.toList()..sort();
    int acumulado = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < orderedDates.length; i++) {
      acumulado += deltas[orderedDates[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), acumulado.toDouble()));
    }
    return _TimelineData(spots, orderedDates);
  }

  Widget _buildTimelineChart(List historicos) {
    final timeline = _buildTimelineData(historicos);
    if (timeline.spots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: OwanyTheme.primaryOrange, size: 18),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.history_occupancy_timeline,
                style: TextStyle(color: OwanyTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                lineTouchData: LineTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= timeline.spots.length) return const SizedBox.shrink();
                        final date = timeline.datas[idx];
                        // Rótulo enxuto: exibe a cada 5 pontos ou no último
                        if (idx % 5 != 0 && idx != timeline.spots.length - 1) return const SizedBox.shrink();
                        return Text(DateFormat('dd/MM').format(date), style: TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: timeline.spots,
                    isCurved: true,
                    color: OwanyTheme.primaryOrange,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: OwanyTheme.primaryOrange.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.history_residents_title,
        icon: Icons.people_alt_rounded,
        showBackButton: true,
        subtitle: widget.titulo,
      ),
      body: Consumer<HistoricoOcupacaoProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: OwanyTheme.primaryOrange,
                labelColor: OwanyTheme.primaryOrange,
                unselectedLabelColor: OwanyTheme.textSecondary,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.history_current_residents),
                  Tab(text: AppLocalizations.of(context)!.history_complete),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildMoradoresAtuaisTab(), _buildHistoricoCompletoTab()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMoradoresAtuaisTab() {
    return Consumer2<HistoricoOcupacaoProvider, ApartamentosProvider>(
      builder: (context, provider, apartamentosProvider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: OwanyTheme.primaryOrange));
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider.errorMessage!);
        }

        final apartamentoAtual = widget.apartamentoId != null
            ? apartamentosProvider.apartamentoAtual
            : null;
        final moradoresAtuais = (apartamentoAtual != null &&
                apartamentoAtual.id == widget.apartamentoId)
            ? (apartamentoAtual.moradores ?? const <Morador>[])
            : const <Morador>[];
        final historicosAtivos = provider.historicosAtivos;
        final idsMoradoresAtuais =
            moradoresAtuais.map((m) => m.id).where((id) => id.isNotEmpty).toSet();
        final historicosAtivosFiltrados = idsMoradoresAtuais.isNotEmpty
            ? historicosAtivos
                .where((h) => idsMoradoresAtuais.contains(h.moradorId))
                .toList()
            : historicosAtivos;
        final historicosPorMorador = <String, HistoricoOcupacao>{};
        for (final h in historicosAtivosFiltrados) {
          if (h.moradorId.isNotEmpty) historicosPorMorador[h.moradorId] = h;
        }
        if (historicosPorMorador.isEmpty && moradoresAtuais.isNotEmpty) {
          for (final h in provider.historicosFiltrados) {
            if (h.moradorId.isEmpty) continue;
            if (idsMoradoresAtuais.contains(h.moradorId)) {
              historicosPorMorador[h.moradorId] = h;
            }
          }
        }
        final historicosPorNome = <String, HistoricoOcupacao>{};
        for (final h in historicosAtivosFiltrados) {
          if (h.nomeMorador.trim().isEmpty) continue;
          historicosPorNome[_normalizarTexto(h.nomeMorador)] = h;
        }
        
        if (widget.apartamentoId != null &&
            moradoresAtuais.isEmpty &&
            historicosAtivosFiltrados.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum morador ativo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.apartamentoId != null 
                        ? 'Este apartamento não possui moradores atualmente'
                        : 'Este morador não está vinculado a nenhum apartamento',
                    style: TextStyle(
                      fontSize: 14,
                      color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        if (widget.apartamentoId != null &&
            historicosAtivosFiltrados.isEmpty &&
            moradoresAtuais.isNotEmpty) {
          return Column(
            children: [
              _buildFilterRow(provider),
            Expanded(
              child: _buildMoradoresAtuaisList(
                moradoresAtuais,
                historicosPorMorador: historicosPorMorador,
                historicosPorNome: historicosPorNome,
              ),
            ),
          ],
        );
        }
        return Column(
          children: [
            _buildFilterRow(provider),
            Expanded(
              child: _buildHistoricosList(
                historicosAtivosFiltrados,
                mostrarAtivos: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoradoresAtuaisList(
    List<Morador> moradores, {
    required Map<String, HistoricoOcupacao> historicosPorMorador,
    required Map<String, HistoricoOcupacao> historicosPorNome,
  }) {
    return RefreshIndicator(
      color: OwanyTheme.primaryOrange,
      onRefresh: _carregarHistorico,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: moradores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final morador = moradores[index];
          HistoricoOcupacao? historico = historicosPorMorador[morador.id];
          if (historico == null) {
            final nomeKey = morador.nome.trim().isNotEmpty
                ? _normalizarTexto(morador.nome)
                : (morador.nomeUsuario?.trim().isNotEmpty ?? false)
                    ? _normalizarTexto(morador.nomeUsuario!)
                    : '';
            if (nomeKey.isNotEmpty) {
              historico = historicosPorNome[nomeKey];
            }
          }
          final nome = morador.nome.trim().isNotEmpty
              ? morador.nome.trim()
              : (morador.nomeUsuario?.trim().isNotEmpty ?? false)
                  ? morador.nomeUsuario!.trim()
                  : (historico != null && historico.nomeMorador.trim().isNotEmpty)
                      ? historico.nomeMorador.trim()
                      : AppLocalizations.of(context)!.common_resident;
          final dataEntradaReal = morador.dataEntrada ?? historico?.dataEntrada;
          final dataEntrada = dataEntradaReal != null
              ? DateFormat('dd/MM/yyyy').format(dataEntradaReal)
              : null;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OwanyTheme.borderColor(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: OwanyTheme.info.withValues(alpha: 0.15),
                  child: Text(
                    nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: OwanyTheme.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      if (dataEntrada != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context)!.morador_since_date(dataEntrada)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoricoCompletoTab() {
    return Consumer2<HistoricoOcupacaoProvider, ApartamentosProvider>(
      builder: (context, provider, apartamentosProvider, _) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: OwanyTheme.primaryOrange),
                const SizedBox(height: 16),
                Text(
                  'Carregando histórico completo...',
                  style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider.errorMessage!);
        }

        final todoHistorico = provider.eventosFiltrados;
        final resumoHistorico = provider.historicosFiltrados;
        final apartamentoAtual = widget.apartamentoId != null
            ? apartamentosProvider.apartamentoAtual
            : null;
        final moradoresAtuais = (apartamentoAtual != null &&
                apartamentoAtual.id == widget.apartamentoId)
            ? (apartamentoAtual.moradores ?? const <Morador>[])
            : const <Morador>[];
        final moradoresPorId = <String, Morador>{};
        for (final m in moradoresAtuais) {
          if (m.id.isNotEmpty) moradoresPorId[m.id] = m;
        }
        final moradorUnicoAtual = moradoresAtuais.length == 1 ? moradoresAtuais.first : null;
        final nomesPorMoradorId = <String, String>{};
        for (final h in resumoHistorico) {
          if (h is HistoricoOcupacao &&
              h.moradorId.isNotEmpty &&
              h.nomeMorador.trim().isNotEmpty) {
            nomesPorMoradorId[h.moradorId] = h.nomeMorador.trim();
          }
        }
        
        if (todoHistorico.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum histórico encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O histórico de ocupação aparecerá aqui',
                    style: TextStyle(
                      fontSize: 14,
                      color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (todoHistorico.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum histórico encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O histórico de ocupação aparecerá aqui',
                    style: TextStyle(
                      fontSize: 14,
                      color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final historicosBase = resumoHistorico.whereType<HistoricoOcupacao>().toList();
        final latestByKey = <String, HistoricoOcupacaoResumo>{};
        for (final evento in todoHistorico) {
          if (evento.moradorId.trim().isEmpty && evento.nomeMorador.trim().isEmpty) {
            continue;
          }
          final key = evento.moradorId.trim().isNotEmpty
              ? evento.moradorId.trim()
              : _normalizarTexto(evento.nomeMorador);
          final existente = latestByKey[key];
          if (existente == null || evento.dataMovimentacao.isAfter(existente.dataMovimentacao)) {
            latestByKey[key] = evento;
          }
        }

        int ativosOverride = 0;
        for (final historico in historicosBase) {
          final key = historico.moradorId.trim().isNotEmpty
              ? historico.moradorId.trim()
              : _normalizarTexto(historico.nomeMorador);
          final ultimoEvento = latestByKey[key];
          final ativo = ultimoEvento != null ? _isEntradaEvento(ultimoEvento) && !_isSaidaEvento(ultimoEvento) : historico.estaAtivo;
          if (ativo) ativosOverride++;
        }

        final totalOverride = historicosBase.length;
        final inativosOverride = totalOverride - ativosOverride;
        final diasTotais = historicosBase
            .where((h) => !h.estaAtivo)
            .fold<int>(0, (sum, h) => sum + h.diasOcupacao);
        final inativosParaMedia =
            historicosBase.where((h) => !h.estaAtivo).length;
        final mediaOverride = inativosParaMedia > 0
            ? (diasTotais / inativosParaMedia).round()
            : 0;

        return Column(
          children: [
            _buildFilterRow(provider),
            Expanded(
              child: _buildEventosList(
                todoHistorico,
                mostrarAtivos: false,
                resumoHistorico: resumoHistorico,
                moradoresPorId: moradoresPorId,
                nomesPorMoradorId: nomesPorMoradorId,
                moradorUnicoAtual: moradorUnicoAtual,
                totalOverride: totalOverride,
                ativosOverride: ativosOverride,
                inativosOverride: inativosOverride,
                mediaOverride: mediaOverride,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventosList(
    List historicos, {
    required bool mostrarAtivos,
    List? resumoHistorico,
    Map<String, Morador>? moradoresPorId,
    Map<String, String>? nomesPorMoradorId,
    Morador? moradorUnicoAtual,
    int? totalOverride,
    int? ativosOverride,
    int? inativosOverride,
    int? mediaOverride,
  }) {
    if (historicos.isEmpty) {
      return _buildEmptyState(
        mostrarAtivos
            ? AppLocalizations.of(context)!.history_no_current_residents
            : AppLocalizations.of(context)!.history_no_records,
      );
    }

    return RefreshIndicator(
      color: OwanyTheme.primaryOrange,
      onRefresh: _carregarHistorico,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mostrarAtivos && resumoHistorico != null && resumoHistorico.isNotEmpty) ...[
              _buildTimelineChart(resumoHistorico),
              _buildEstatisticas(
                totalOverride: totalOverride,
                ativosOverride: ativosOverride,
                inativosOverride: inativosOverride,
                mediaOverride: mediaOverride,
              ),
              SizedBox(height: 8),
            ],
            ...List.generate(historicos.length, (index) {
              final h = historicos[index];
              // Se for HistoricoOcupacaoResumo (eventos detalhados), mostrar de forma diferente
              if (h is HistoricoOcupacaoResumo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEventoCard(
                    h,
                    moradorOverride: moradoresPorId?[h.moradorId],
                    moradorUnicoAtual: moradorUnicoAtual,
                    nomeFallback: nomesPorMoradorId?[h.moradorId],
                  ),
                );
              }
              // Se for HistoricoOcupacao (resumo agregado)
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HistoricoOcupacaoDetalhadoCard(historico: h),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(
    HistoricoOcupacaoResumo evento, {
    Morador? moradorOverride,
    Morador? moradorUnicoAtual,
    String? nomeFallback,
  }) {
    final nomeEventoValido =
        evento.nomeMorador.isNotEmpty && evento.nomeMorador.toLowerCase().trim() != 'residente';
    final nomeResolvido = nomeEventoValido
        ? evento.nomeMorador
        : (moradorOverride != null && moradorOverride.nome.trim().isNotEmpty)
            ? moradorOverride.nome.trim()
            : (moradorOverride != null &&
                    (moradorOverride.nomeUsuario?.trim().isNotEmpty ?? false))
                ? moradorOverride.nomeUsuario!.trim()
                : (moradorUnicoAtual != null && moradorUnicoAtual.nome.trim().isNotEmpty)
                    ? moradorUnicoAtual.nome.trim()
                    : (moradorUnicoAtual != null &&
                            (moradorUnicoAtual.nomeUsuario?.trim().isNotEmpty ?? false))
                        ? moradorUnicoAtual.nomeUsuario!.trim()
                : (nomeFallback != null && nomeFallback.trim().isNotEmpty)
                    ? nomeFallback.trim()
                : AppLocalizations.of(context)!.apartments_no_residents;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                evento.tipoMovimentacao == 'Entrada' ? Icons.login_rounded : Icons.logout_rounded,
                color: evento.tipoMovimentacao == 'Entrada' ? OwanyTheme.success : OwanyTheme.error,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  evento.tipoMovimentacao,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: evento.tipoMovimentacao == 'Entrada' ? OwanyTheme.success : OwanyTheme.error,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(evento.dataMovimentacao),
                style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: OwanyTheme.primaryOrange),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  nomeResolvido,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.home_rounded, size: 16, color: OwanyTheme.primaryOrange),
              SizedBox(width: 6),
              Text(
                AppLocalizations.of(
                  context,
                )!.apartments_apt_block_label(evento.numeroApartamento, evento.blocoApartamento),
                style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
              ),
            ],
          ),
          // Mostra executado por (se disponível)
          if (evento.nomeExecutor.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, size: 14, color: OwanyTheme.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Por: ${evento.nomeExecutor}',
                    style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (evento.observacoes != null && evento.observacoes!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                evento.observacoes!,
                style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterRow(HistoricoOcupacaoProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: OwanyTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.filter_alt_rounded, color: OwanyTheme.primaryOrange, size: 18),
          ),
          SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.history_period,
            style: TextStyle(color: OwanyTheme.textPrimary(context), fontWeight: FontWeight.w700, fontSize: 14),
          ),
          SizedBox(width: 12),
          DropdownButton<FiltroPeriodo>(
            value: provider.filtroPeriodo,
            underline: const SizedBox.shrink(),
            dropdownColor: OwanyTheme.cardColor(context),
            iconEnabledColor: OwanyTheme.primaryOrange,
            items: FiltroPeriodo.values
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(
                      _labelFiltro(f),
                      style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            onChanged: (filtro) {
              if (filtro != null) provider.definirFiltro(filtro);
            },
          ),
          const Spacer(),
          Text(
            '${provider.historicosFiltrados.length} ${AppLocalizations.of(context)!.history_records}',
            style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricosList(List historicos, {required bool mostrarAtivos}) {
    if (historicos.isEmpty) {
      return _buildEmptyState(
        mostrarAtivos
            ? AppLocalizations.of(context)!.history_no_current_residents
            : AppLocalizations.of(context)!.history_no_records,
      );
    }

    return RefreshIndicator(
      color: OwanyTheme.primaryOrange,
      onRefresh: _carregarHistorico,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estatísticas (apenas para histórico completo)
            if (!mostrarAtivos) ...[_buildTimelineChart(historicos), _buildEstatisticas()],

            // Lista de históricos
            ...List.generate(historicos.length, (index) {
              final historico = historicos[index];
              final podeRegistrarSaida = historico.estaAtivo && historico.moradorId.trim().isNotEmpty;
              return HistoricoOcupacaoDetalhadoCard(
                historico: historico,
                onRegistrarSaida: podeRegistrarSaida
                    ? () => _showRegistrarSaidaDialog(historico.moradorId, historico.nomeMorador)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticas({
    int? totalOverride,
    int? ativosOverride,
    int? inativosOverride,
    int? mediaOverride,
  }) {
    final provider = context.watch<HistoricoOcupacaoProvider>();
    final stats = provider.estatisticas;
    final total = totalOverride ?? stats['total'];
    final ativos = ativosOverride ?? stats['ativos'];
    final inativos = inativosOverride ?? stats['inativos'];
    final media = mediaOverride ?? stats['mediaOcupacao'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OwanyTheme.primaryOrange.withValues(alpha: 0.1), OwanyTheme.primaryOrange.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: OwanyTheme.primaryOrange, size: 20),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.residents_statistics,
                style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(AppLocalizations.of(context)!.common_total, '$total', Icons.people_rounded),
              _buildStatItem(
                AppLocalizations.of(context)!.history_active,
                '$ativos',
                Icons.check_circle_rounded,
              ),
              _buildStatItem(
                AppLocalizations.of(context)!.history_previous,
                '$inativos',
                Icons.history_rounded,
              ),
              _buildStatItem(
                AppLocalizations.of(context)!.history_average,
                '${media}d',
                Icons.timer_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: OwanyTheme.primaryOrange),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context))),
      ],
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.people_outline_rounded, size: 64, color: OwanyTheme.primaryOrange),
            ),
            SizedBox(height: 20),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String erro) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.error_outline_rounded, size: 64, color: OwanyTheme.error),
            ),
            SizedBox(height: 20),
            Text(
              erro,
              textAlign: TextAlign.center,
              style: TextStyle(color: OwanyTheme.error, fontSize: 14),
            ),
            SizedBox(height: 20),
            PrimaryButton.primary(
              text: AppLocalizations.of(context)!.common_retry,
              onPressed: _carregarHistorico,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
