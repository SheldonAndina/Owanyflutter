// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dto/item_apartamento_dto.dart';
import '../generated_l10n/app_localizations.dart';
import '../providers/itens_provider.dart';
import '../theme/owany_theme.dart';
import '../widgets/standard_glass_app_bar.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

/// Tela de histórico de movimentações do ativo (PREMIUM VERSION)
/// Utiliza ItensProvider para carregar histórico com timeline moderna
class HistoricoAtivoScreen extends StatefulWidget {
  final String itemId;
  const HistoricoAtivoScreen({super.key, required this.itemId});

  @override
  State<HistoricoAtivoScreen> createState() => _HistoricoAtivoScreenState();
}

class _HistoricoAtivoScreenState extends State<HistoricoAtivoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _erro;
  HistoricoItemDto? _historico;
  DateTime? _filtroDataInicio;
  DateTime? _filtroDataFim;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarHistorico();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    
    try {
      final provider = context.read<ItensProvider>();
      await provider.carregarHistorico(widget.itemId);
      
      setState(() {
        _historico = provider.historicoAtual;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _erro = '${l10n.common_error}: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alocacoesFiltradas = _filtrarAlocacoes(_historico?.alocacoes ?? []);
    final mudancasFiltradas =
        _filtrarMudancasEstado(_historico?.mudancasEstado ?? []);
    final totalFiltrado = alocacoesFiltradas.length + mudancasFiltradas.length;
    final filtroAtivo = _filtroDataInicio != null || _filtroDataFim != null;
    final rangeLabel = _buildRangeLabel();
    
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: l10n.assets_movement_history,
        subtitle: l10n.assets_management_title,
        icon: Icons.history_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErroWidget()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateFilterButton(
                                  icon: Icons.calendar_today_rounded,
                                  label: filtroAtivo
                                      ? rangeLabel
                                      : _tx('Selecionar período', 'Select period'),
                                  onTap: () => _selectDateRange(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: () => _showExportDialog(context),
                                icon: const Icon(Icons.download_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      OwanyTheme.primaryOrange.withOpacity(0.1),
                                  foregroundColor: OwanyTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                          if (filtroAtivo) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: OwanyTheme.primaryOrange
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: OwanyTheme.primaryOrange
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.filter_alt_rounded,
                                          size: 14,
                                          color: OwanyTheme.primaryOrange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$totalFiltrado ${_tx('movimentações no período', 'movements in period')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: OwanyTheme.primaryOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: _tx('Limpar filtro', 'Clear filter'),
                                  onPressed: () => setState(() {
                                    _filtroDataInicio = null;
                                    _filtroDataFim = null;
                                  }),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildSummaryStrip(alocacoesFiltradas.length,
                        mudancasFiltradas.length, totalFiltrado),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: OwanyTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: OwanyTheme.borderColor(context)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: OwanyTheme.primaryOrange,
                        unselectedLabelColor: OwanyTheme.textMutedColor(context),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        tabs: [
                          Tab(
                            text: '${_tx('Alocações', 'Allocations')} (${alocacoesFiltradas.length})',
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          ),
                          Tab(
                            text: '${_tx('Mudanças', 'Changes')} (${mudancasFiltradas.length})',
                            icon: const Icon(
                              Icons.change_circle_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAlocacoesTab(alocacoesFiltradas),
                          _buildMudancasEstadoTab(mudancasFiltradas),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  List<AlocacaoItemDto> _filtrarAlocacoes(List<AlocacaoItemDto> alocacoes) {
    if (_filtroDataInicio == null && _filtroDataFim == null) return alocacoes;
    return alocacoes.where((item) => _dateDentroDoFiltro(item.dataAlocacao)).toList();
  }

  List<MudancaEstadoItemDto> _filtrarMudancasEstado(
    List<MudancaEstadoItemDto> mudancas,
  ) {
    if (_filtroDataInicio == null && _filtroDataFim == null) return mudancas;
    return mudancas.where((item) => _dateDentroDoFiltro(item.dataMudanca)).toList();
  }

  bool _dateDentroDoFiltro(DateTime? value) {
    if (value == null) return false;
    final alvo = DateTime(value.year, value.month, value.day);
    final inicio = _filtroDataInicio != null
        ? DateTime(
            _filtroDataInicio!.year,
            _filtroDataInicio!.month,
            _filtroDataInicio!.day,
          )
        : null;
    final fim = _filtroDataFim != null
        ? DateTime(_filtroDataFim!.year, _filtroDataFim!.month, _filtroDataFim!.day)
        : null;
    if (inicio != null && alvo.isBefore(inicio)) return false;
    if (fim != null && alvo.isAfter(fim)) return false;
    return true;
  }

  String _buildRangeLabel() {
    if (_filtroDataInicio == null && _filtroDataFim == null) return '';
    if (_filtroDataInicio == null && _filtroDataFim != null) {
      return '${_tx('Até', 'Until')} ${DateFormat('dd/MM').format(_filtroDataFim!)}';
    }
    if (_filtroDataInicio != null && _filtroDataFim == null) {
      return '${_tx('Desde', 'From')} ${DateFormat('dd/MM').format(_filtroDataInicio!)}';
    }
    return '${DateFormat('dd/MM').format(_filtroDataInicio!)} - ${DateFormat('dd/MM').format(_filtroDataFim!)}';
  }

  Widget _buildSummaryStrip(int alocacoes, int mudancas, int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryItem(_tx('Total', 'Total'), total, OwanyTheme.primaryBrown)),
          Expanded(child: _summaryItem(_tx('Alocações', 'Allocations'), alocacoes, OwanyTheme.success)),
          Expanded(child: _summaryItem(_tx('Mudanças', 'Changes'), mudancas, OwanyTheme.primaryOrange)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: OwanyTheme.textMutedColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildErroWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: OwanyTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 38, color: OwanyTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              _erro!,
              style: const TextStyle(color: OwanyTheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarHistorico,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.common_retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlocacoesTab(List<AlocacaoItemDto> alocacoes) {
    final l10n = AppLocalizations.of(context)!;
    
    if (alocacoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 38,
                color: OwanyTheme.primaryOrange.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.items_history_empty,
                style: TextStyle(color: OwanyTheme.textMutedColor(context),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alocacoes.length,
        itemBuilder: (context, index) => _buildAlocacaoCard(alocacoes[index]),
      ),
    );
  }

  Widget _buildAlocacaoCard(AlocacaoItemDto alocacao) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: OwanyTheme.isDark(context)
            ? []
            : [
                BoxShadow(
                  color: OwanyTheme.primaryBrown.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OwanyTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: OwanyTheme.success, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alocacao.motivo ?? l10n.assets_movement,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (alocacao.dataAlocacao != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: OwanyTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      df.format(alocacao.dataAlocacao!),
                      style: TextStyle(
                        fontSize: 10,
                        color: OwanyTheme.textMutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (alocacao.apartamentoNumero.isNotEmpty)
              _infoChip(Icons.apartment_rounded,
                  '${l10n.assets_field_apartment} ${alocacao.apartamentoNumero}'),
            if (alocacao.usuarioNome != null &&
                alocacao.usuarioNome!.isNotEmpty)
              _infoChip(
                  Icons.person_outline_rounded, alocacao.usuarioNome!),
            if (alocacao.observacoes != null &&
                alocacao.observacoes!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OwanyTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alocacao.observacoes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMudancasEstadoTab(List<MudancaEstadoItemDto> mudancas) {
    final l10n = AppLocalizations.of(context)!;
    
    if (mudancas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.change_circle_outlined,
                size: 38,
                color: OwanyTheme.primaryOrange.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.items_history_empty,
                style: TextStyle(color: OwanyTheme.textMutedColor(context),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mudancas.length,
        itemBuilder: (context, index) => _buildMudancaCard(mudancas[index]),
      ),
    );
  }

  Widget _buildMudancaCard(MudancaEstadoItemDto mudanca) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: OwanyTheme.isDark(context)
            ? []
            : [
                BoxShadow(
                  color: OwanyTheme.primaryBrown.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.change_circle_outlined,
                      color: OwanyTheme.primaryOrange, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mudanca.motivo ?? _tx('Alteração de Estado', 'Status change'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                ),
                if (mudanca.dataMudanca != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: OwanyTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      df.format(mudanca.dataMudanca!),
                      style: TextStyle(
                        fontSize: 10,
                        color: OwanyTheme.textMutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (mudanca.estadoAnterior != null && mudanca.novoEstado != null) ...[  
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OwanyTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: OwanyTheme.borderColor(context)),
                    ),
                    child: Text(
                      mudanca.estadoAnterior!,
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: OwanyTheme.textMuted),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mudanca.novoEstado!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (mudanca.usuarioNome != null &&
                mudanca.usuarioNome!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              _infoChip(
                  Icons.person_outline_rounded, mudanca.usuarioNome!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: OwanyTheme.textMutedColor(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: OwanyTheme.textMutedColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: OwanyTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OwanyTheme.borderColor(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: OwanyTheme.textMutedColor(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: OwanyTheme.textMutedColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filtroDataInicio != null && _filtroDataFim != null
          ? DateTimeRange(start: _filtroDataInicio!, end: _filtroDataFim!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _filtroDataInicio = picked.start;
        _filtroDataFim = picked.end;
      });
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(_tx('Exportar Histórico', 'Export History')),
        content: Text(
          _tx(
            'Deseja exportar o histórico em formato CSV ou PDF?',
            'Do you want to export the history in CSV or PDF format?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tx('Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_tx('Exportação iniciada...', 'Export started...'))),
              );
            },
            child: Text(_tx('CSV', 'CSV')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _tx('Geração de PDF iniciada...', 'PDF generation started...'),
                  ),
                ),
              );
            },
            child: Text(_tx('PDF', 'PDF')),
          ),
        ],
      ),
    );
  }
}
