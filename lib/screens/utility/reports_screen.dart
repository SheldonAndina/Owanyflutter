import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../generated_l10n/app_localizations.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../services/api_service.dart';
import '../../utils/file_download_helper.dart';
import '../../utils/app_logger.dart';
import '../../utils/network_error_helper.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../dto/api_dtos.dart';
import '../../dto/solicitacoes_kpis_dto.dart';
import '../../dto/solicitacoes_v2_dtos.dart';

/// Formata timestamp para nome de arquivo (compatível com Windows)
/// Substitui ':' por '-' para evitar erro no Windows
String _getWindowsCompatibleTimestamp() {
  final now = DateTime.now();
  final iso = now.toIso8601String();
  // Substitui ':' por '-' para compatibilidade com Windows
  // Ex: 2026-02-13T08:47:43.514859 -> 2026-02-13T08-47-43.514859
  return iso.replaceAll(':', '-');
}

class _StatusChartItem {
  final String key;
  final String label;
  final int count;
  final Color color;

  _StatusChartItem({
    required this.key,
    required this.label,
    required this.count,
    required this.color,
  });
}

class _SolicitacoesResumo {
  final int total;
  final int pendentes;
  final int emAndamento;
  final int concluidas;
  final int emAnalise;
  final int aguardando;
  final int rejeitadas;
  final int canceladas;

  const _SolicitacoesResumo({
    required this.total,
    required this.pendentes,
    required this.emAndamento,
    required this.concluidas,
    required this.emAnalise,
    required this.aguardando,
    required this.rejeitadas,
    required this.canceladas,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Filtros
  DateTime? _mesSelecionado;
  DateTime? _dataInicioFiltro;
  DateTime? _dataFimFiltro;
  bool _mostrarTudo = true;
  String? _statusFiltro;

  bool get _isEn =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('en');

  String _tx(String pt, String en) => _isEn ? en : pt;
  
  // Lista de meses (últimos 12 meses)
  List<DateTime> get _mesesDisponiveis {
    final agora = DateTime.now();
    return List.generate(12, (i) => DateTime(agora.year, agora.month - i, 1));
  }
  
  String _formatarMes(DateTime mes) {
    const mesesPt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    const mesesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final meses = _isEn ? mesesEn : mesesPt;
    return '${meses[mes.month - 1]} ${mes.year}';
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  DateTime _inicioDoDia(DateTime data) => DateTime(data.year, data.month, data.day);

  DateTime _fimDoDia(DateTime data) => DateTime(data.year, data.month, data.day, 23, 59, 59, 999);

  DateTimeRange? _obterPeriodoAtivo() {
    if (_mostrarTudo) return null;

    if (_dataInicioFiltro != null && _dataFimFiltro != null) {
      return DateTimeRange(
        start: _inicioDoDia(_dataInicioFiltro!),
        end: _fimDoDia(_dataFimFiltro!),
      );
    }

    if (_mesSelecionado != null) {
      return DateTimeRange(
        start: DateTime(_mesSelecionado!.year, _mesSelecionado!.month, 1),
        end: DateTime(_mesSelecionado!.year, _mesSelecionado!.month + 1, 0, 23, 59, 59, 999),
      );
    }

    return null;
  }

  bool get _temFiltroAtivo => _obterPeriodoAtivo() != null || _statusFiltro != null || _dataInicioFiltro != null;

  bool _estaNoPeriodo(DateTime data, DateTimeRange? periodo) {
    if (periodo == null) return true;
    return !data.isBefore(periodo.start) && !data.isAfter(periodo.end);
  }

  bool _statusCorresponde(String? status) {
    if (_statusFiltro == null || _statusFiltro!.trim().isEmpty) return true;
    return _normalizeStatusKey(status) == _normalizeStatusKey(_statusFiltro);
  }

  List<SolicitacaoListaDto> _filtrarSolicitacoes(
    List<SolicitacaoListaDto> solicitacoes,
    DateTimeRange? periodo,
  ) {
    final filtradas = solicitacoes
        .where((s) => _estaNoPeriodo(s.criadoEm, periodo) && _statusCorresponde(s.status))
        .toList();
    filtradas.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return filtradas;
  }

  _SolicitacoesResumo _calcularResumoSolicitacoes(List<SolicitacaoListaDto> solicitacoes) {
    int pendentes = 0;
    int emAndamento = 0;
    int concluidas = 0;
    int emAnalise = 0;
    int aguardando = 0;
    int rejeitadas = 0;
    int canceladas = 0;

    for (final sol in solicitacoes) {
      final key = _normalizeStatusKey(sol.status);
      if (key.contains('pend')) {
        pendentes++;
      } else if (key.contains('andam') || key.contains('execu') || key.contains('inici')) {
        emAndamento++;
      } else if (key.contains('concl')) {
        concluidas++;
      } else if (key.contains('analis')) {
        emAnalise++;
      } else if (key.contains('aguard')) {
        aguardando++;
      } else if (key.contains('rejeit') || key.contains('recus')) {
        rejeitadas++;
      } else if (key.contains('cancel')) {
        canceladas++;
      }
    }

    return _SolicitacoesResumo(
      total: solicitacoes.length,
      pendentes: pendentes,
      emAndamento: emAndamento,
      concluidas: concluidas,
      emAnalise: emAnalise,
      aguardando: aguardando,
      rejeitadas: rejeitadas,
      canceladas: canceladas,
    );
  }

  DashboardEstatisticas _buildStatsFiltradas(
    DashboardEstatisticas base,
    List<SolicitacaoListaDto> solicitacoesFiltradas,
    int apartamentosEmManutencao,
  ) {
    final resumo = _calcularResumoSolicitacoes(solicitacoesFiltradas);
    return DashboardEstatisticas(
      totalApartamentos: base.totalApartamentos,
      apartamentosOcupados: base.apartamentosOcupados,
      apartamentosDisponiveis: base.apartamentosDisponiveis,
      apartamentosEmManutencao: apartamentosEmManutencao,
      totalSolicitacoes: resumo.total,
      solicitacoesPendentes: resumo.pendentes,
      solicitacoesEmAndamento: resumo.emAndamento,
      solicitacoesConcluidas: resumo.concluidas,
      solicitacoesEmAnalise: resumo.emAnalise,
      solicitacoesAguardando: resumo.aguardando,
      solicitacoesRejeitadas: resumo.rejeitadas,
      solicitacoesCanceladas: resumo.canceladas,
      totalMoradores: base.totalMoradores,
      totalUsuarios: base.totalUsuarios,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // RBAC: Apenas Staff pode acessar relatórios
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isStaff) {
        AppLogger.warning('Reports', '🔒 ${authProvider.usuarioAtual?.tipo} sem acesso a relatórios');
        Navigator.of(context).pop();
        return;
      }
      
      _carregarDados();
    });
  }
  
  void _carregarDados() {
    final dash = context.read<DashboardProvider>();
    dash.atualizarTudo();
    
    // Carregar KPIs com filtro de data se aplicável
    final periodo = _obterPeriodoAtivo();
    final dataInicio = periodo?.start;
    final dataFim = periodo?.end;
    
    dash.carregarSolicitacoesKpis(dataInicio: dataInicio, dataFim: dataFim);
    // Carregar TODAS as solicitações para métricas completas
    context.read<SolicitacoesProvider>().loadSolicitacoes(refresh: true, carregarTodas: true);
    // Carregar áreas técnicas
    context.read<SolicitacoesProvider>().loadAreas();
  }

  String _normalizeStatusKey(String? status) {
    var s = (status ?? '').trim().toLowerCase();
    s = s
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
    return s;
  }

  String _humanizeStatusRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _tx('Desconhecido', 'Unknown');
    final withSpaces = raw
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (m) => ' ${m.group(1)}')
        .trim();
    final words = withSpaces.split(RegExp(r'\s+'));
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _statusLabelFromKey(String key, String? raw, AppLocalizations l10n) {
    if (key.contains('pend')) return l10n.maintenance_list_pending;
    if (key.contains('analis')) return _tx('Em Análise', 'Under Review');
    if (key.contains('andam') || key.contains('execu') || key.contains('inici')) {
      return l10n.maintenance_list_in_progress;
    }
    if (key.contains('concl')) return l10n.maintenance_list_completed;
    if (key.contains('rejeit') || key.contains('recus')) return _tx('Rejeitado', 'Rejected');
    if (key.contains('cancel')) return _tx('Cancelado', 'Cancelled');
    if (key.contains('aguard')) return _tx('Aguardando', 'Waiting');
    return _humanizeStatusRaw(raw);
  }

  List<_StatusChartItem> _buildStatusChartItems(
    DashboardProvider provider,
    List<SolicitacaoListaDto> solicitacoesFiltradas,
    DashboardEstatisticas stats,
    AppLocalizations l10n,
    bool permitirFallbackGlobal,
  ) {
    final counts = <String, int>{};
    final rawLabels = <String, String>{};

    void addStatus(String? rawStatus, int qtd) {
      final key = _normalizeStatusKey(rawStatus);
      if (key.isEmpty || qtd <= 0) return;
      counts[key] = (counts[key] ?? 0) + qtd;
      rawLabels.putIfAbsent(key, () => rawStatus ?? '');
    }

    if (solicitacoesFiltradas.isNotEmpty) {
      for (final s in solicitacoesFiltradas) {
        addStatus(s.status, 1);
      }
    } else if (permitirFallbackGlobal && provider.graficoStatus.isNotEmpty) {
      for (final item in provider.graficoStatus) {
        addStatus(item.status, item.quantidade);
      }
    } else if (permitirFallbackGlobal) {
      addStatus('Pendente', stats.solicitacoesPendentes);
      addStatus('EmAnalise', stats.solicitacoesEmAnalise);
      addStatus('EmAndamento', stats.solicitacoesEmAndamento);
      addStatus('Rejeitado', stats.solicitacoesRejeitadas);
      addStatus('Cancelado', stats.solicitacoesCanceladas);
      addStatus('Concluido', stats.solicitacoesConcluidas);
    }

    final items = counts.entries
        .map((e) => _StatusChartItem(
              key: e.key,
              label: _statusLabelFromKey(e.key, rawLabels[e.key], l10n),
              count: e.value,
              color: _colorForStatus(e.key),
            ))
        .toList();
    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 900;
    final authProvider = context.watch<AuthProvider>();
    
    // RBAC: Bloquear acesso para não-staff
    if (!authProvider.isStaff) {
      return Scaffold(
        backgroundColor: OwanyTheme.backgroundColor(context),
        appBar: AppBar(
          title: Text(l10n.reports_title),
          backgroundColor: OwanyTheme.primaryOrange,
          foregroundColor: OwanyTheme.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: OwanyTheme.textMutedColor(context)),
              const SizedBox(height: 16),
              Text(
                'Você não tem permissão para acessar relatórios',
                style: TextStyle(color: OwanyTheme.textMutedColor(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: OwanyTheme.primaryOrange,
            foregroundColor: OwanyTheme.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: OwanyTheme.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.analytics_rounded, color: OwanyTheme.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.reports_analytics,
                                style: TextStyle(color: OwanyTheme.white, fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Consumer<DashboardProvider>(
                                builder: (context, provider, _) {
                                  final stats = provider.estatisticas;
                                  return Text(
                                    stats != null
                                        ? l10n.reports_header_summary(stats.totalSolicitacoes, stats.totalMoradores)
                                        : l10n.common_loading,
                                    style: TextStyle(color: OwanyTheme.white.withValues(alpha: 0.8), fontSize: 14),
                                  );
                                },
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
            actions: [
              Consumer<DashboardProvider>(
                builder: (context, provider, _) => IconButton(
                  onPressed: provider.isLoading ? null : _carregarDados,
                  icon: provider.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.white),
                          ),
                        )
                      : Icon(Icons.refresh_rounded),
                  tooltip: l10n.common_update,
                ),
              ),
              // Export menu
              IconButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final l10nLocal = AppLocalizations.of(context)!;

                  final choice = await showMenu<String>(
                    context: context,
                    position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                    items: [
                      // Solicitações
                      PopupMenuItem(value: 'solicitacoes_excel', child: Text(l10nLocal.reports_export_requests_excel)),
                      PopupMenuItem(value: 'solicitacoes_pdf', child: Text(l10nLocal.reports_export_requests_pdf)),
                      const PopupMenuDivider(),
                      // Dados básicos
                      PopupMenuItem(value: 'apartamentos_excel', child: Text(l10nLocal.reports_export_apartments_excel)),
                      PopupMenuItem(value: 'moradores_excel', child: Text(l10nLocal.reports_export_residents_excel)),
                      PopupMenuItem(value: 'usuarios_excel', child: Text(l10nLocal.reports_export_users_excel)),
                      const PopupMenuDivider(),
                      // Agendamentos e Manutenções
                      PopupMenuItem(value: 'agendamentos_excel', child: Text(l10nLocal.reports_export_agendamentos_excel)),
                      PopupMenuItem(value: 'manutencoes_excel', child: Text(l10nLocal.reports_export_manutencoes_excel)),
                      PopupMenuItem(value: 'ativos_excel', child: Text(l10nLocal.reports_export_ativos_excel)),
                      const PopupMenuDivider(),
                      // KPIs e Indicadores
                      PopupMenuItem(value: 'kpi_excel', child: Text(l10nLocal.reports_export_kpi_excel)),
                      PopupMenuItem(value: 'kpi_pdf', child: Text(l10nLocal.reports_export_kpi_pdf)),
                      const PopupMenuDivider(),
                      // SMS (Admin only)
                      PopupMenuItem(value: 'sms_excel', child: Text(l10nLocal.reports_export_sms_excel)),
                      const PopupMenuDivider(),
                      // Relatório completo
                      PopupMenuItem(value: 'relatorio_completo', child: Text(l10nLocal.reports_export_complete)),
                      PopupMenuItem(value: 'relatorio_completo_zip', child: Text(l10nLocal.reports_export_complete_zip)),
                    ],
                  );

                  if (choice == null) return;
                  
                  try {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 16),
                            Text(l10nLocal.reports_exporting),
                          ],
                        ),
                        duration: Duration(seconds: 30),
                      ),
                    );

                    AppLogger.info('Reports', '🔄 Iniciando exportação de relatório...');
                    
                    List<int> bytes;
                    String fileName;
                    String fileExtension = 'xlsx'; // padrão

                    AppLogger.info('Reports', '📋 Tipo: $choice');

                    switch (choice) {
                      case 'solicitacoes_excel':
                        AppLogger.info('Reports', '📥 Baixando solicitações em Excel...');
                        bytes = await ApiService().exportarSolicitacoesExcel();
                        fileName = 'solicitacoes_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'solicitacoes_pdf':
                        AppLogger.info('Reports', '📥 Baixando solicitações em PDF...');
                        bytes = await ApiService().exportarSolicitacoesPdf();
                        fileName = 'solicitacoes_${_getWindowsCompatibleTimestamp()}.pdf';
                        fileExtension = 'pdf';
                        break;
                      case 'apartamentos_excel':
                        AppLogger.info('Reports', '📥 Baixando apartamentos em Excel...');
                        bytes = await ApiService().exportarApartamentosExcel();
                        fileName = 'apartamentos_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'moradores_excel':
                        AppLogger.info('Reports', '📥 Baixando moradores em Excel...');
                        bytes = await ApiService().exportarMoradoresExcel();
                        fileName = 'moradores_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'usuarios_excel':
                        AppLogger.info('Reports', '📥 Baixando usuários em Excel...');
                        bytes = await ApiService().exportarUsuariosExcel();
                        fileName = 'usuarios_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;

                      // Novos relatórios
                      case 'agendamentos_excel':
                        AppLogger.info('Reports', '📥 Baixando agendamentos em Excel...');
                        bytes = await ApiService().exportarAgendamentosExcel();
                        fileName = 'agendamentos_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'manutencoes_excel':
                        AppLogger.info('Reports', '📥 Baixando manutenções preventivas em Excel...');
                        bytes = await ApiService().exportarManutencoesPreventivasExcel();
                        fileName = 'manutencoes_preventivas_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'ativos_excel':
                        AppLogger.info('Reports', '📥 Baixando ativos em Excel...');
                        bytes = await ApiService().exportarAtivosExcel();
                        fileName = 'ativos_patrimonio_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'sms_excel':
                        AppLogger.info('Reports', '📥 Baixando histórico SMS em Excel...');
                        bytes = await ApiService().exportarSmsExcel();
                        fileName = 'historico_sms_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'kpi_excel':
                        AppLogger.info('Reports', '📥 Baixando KPIs em Excel...');
                        bytes = await ApiService().exportarKpiExcel();
                        fileName = 'kpis_${_getWindowsCompatibleTimestamp()}.xlsx';
                        fileExtension = 'xlsx';
                        break;
                      case 'kpi_pdf':
                        AppLogger.info('Reports', '📥 Baixando KPIs em PDF...');
                        bytes = await ApiService().exportarKpiPdf();
                        fileName = 'kpis_${_getWindowsCompatibleTimestamp()}.pdf';
                        fileExtension = 'pdf';
                        break;

                      case 'relatorio_completo':
                        // Tratamento especial para relatório completo em pasta
                        AppLogger.info('Reports', '📦 Iniciando download de relatório completo...');
                        if (!mounted) return;
                        await _downloadRelatoCompleto();
                        return;

                      case 'relatorio_completo_zip':
                        // Download de ZIP único
                        AppLogger.info('Reports', '📦 Baixando relatório completo em ZIP...');
                        bytes = await ApiService().exportarRelatorioCompletoZip();
                        fileName = 'relatorio_completo_${_getWindowsCompatibleTimestamp()}.zip';
                        fileExtension = 'zip';
                        break;

                      default:
                        AppLogger.warning('Reports', '⚠️ Tipo desconhecido: $choice');
                        return;
                    }

                    AppLogger.info('Reports', '✅ Backend retornou ${bytes.length} bytes');

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    
                    AppLogger.info('Reports', '🎯 Salvando arquivo em pasta padrão...');
                    final success = await FileDownloadHelper.saveFileWithPicker(
                      context,
                      fileBytes: bytes,
                      fileName: fileName,
                      fileExtension: fileExtension,
                    );

                    if (success) {
                      AppLogger.info('Reports', '✅ Download finalizado com sucesso!');
                    } else {
                      AppLogger.warning('Reports', '❌ Download não foi completado');
                    }
                  } catch (e, stackTrace) {
                    AppLogger.error('Reports', '❌ Erro ao exportar relatório', e, stackTrace);
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ ${_tx('Erro', 'Error')}: ${e.toString()}'),
                        backgroundColor: OwanyTheme.error,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded),
                tooltip: l10n.reports_export_tooltip,
              ),
            ],
          ),
        ],
        body: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.estatisticas == null) {
              return Center(child: SkeletonListLoader(itemCount: 6));
            }

            if (provider.hasError) {
              return _buildErrorState(provider, l10n);
            }

            final stats = provider.estatisticas;
            if (stats == null) {
              return _buildEmptyState(l10n);
            }

            // Calcular apartamentos em manutenção baseado nas solicitações em andamento
            // (solução temporária até o backend atualizar o campo automaticamente)
            final solicitacoesProvider = context.watch<SolicitacoesProvider>();
            final aptosComManutencao = <String>{};
            final periodoAtivo = _obterPeriodoAtivo();
            final solicitacoesFiltradas = _filtrarSolicitacoes(
              solicitacoesProvider.solicitacoes,
              periodoAtivo,
            );
            for (final sol in solicitacoesFiltradas.where((s) {
              final key = _normalizeStatusKey(s.status);
              return key.contains('andam') || key.contains('execu') || key.contains('inici');
            })) {
              aptosComManutencao.add('${sol.blocoApartamento}-${sol.numeroApartamento}');
            }
            final apartamentosEmManutencaoCalculado = aptosComManutencao.length;
            final statsExibicao = _temFiltroAtivo
                ? _buildStatsFiltradas(
                    stats,
                    solicitacoesFiltradas,
                    apartamentosEmManutencaoCalculado,
                  )
                : stats;

            return RefreshIndicator(
              onRefresh: () async {
                _carregarDados();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: OwanyTheme.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros
                    _buildFiltrosSection(l10n),
                     const SizedBox(height: 20),
                     
                     // KPIs Grid
                     _buildKPIsGrid(statsExibicao, isWide, l10n, apartamentosEmManutencaoCalculado),
                     const SizedBox(height: 24),

                     // Charts Section
                     _buildChartsSection(
                       statsExibicao,
                       provider,
                       solicitacoesFiltradas,
                       isWide,
                      l10n,
                    ),
                    const SizedBox(height: 24),

                    // Maintenance Progress
                    _buildSectionHeader(
                      title: l10n.dashboard_maintenance,
                      subtitle: l10n.dashboard_status_requests,
                      icon: Icons.build_rounded,
                    ),
                     const SizedBox(height: 12),
                     _buildMaintenanceProgress(statsExibicao, solicitacoesFiltradas, l10n),
                    const SizedBox(height: 24),

                    // Occupancy Section
                    _buildSectionHeader(
                      title: l10n.reports_occupancy,
                      subtitle: l10n.reports_building_summary,
                      icon: Icons.apartment_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildOccupancySection(stats, l10n),
                    const SizedBox(height: 24),

                    // Users Summary
                    _buildUsersSummary(stats, l10n),
                    const SizedBox(height: 24),

                    // Solicitações KPIs Section
                    _buildSolicitacoesKpisSection(solicitacoesFiltradas),
                    const SizedBox(height: 24),
                    
                    // Distribuição por Área Técnica
                    _buildDistribuicaoAreaTecnicaSection(solicitacoesFiltradas),
                    const SizedBox(height: 24),

                    // Manutenções Gerais
                    _buildManutencoesGeraisSection(solicitacoesFiltradas),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================
  // ERROR & EMPTY STATES
  // ========================

  Widget _buildErrorState(DashboardProvider provider, AppLocalizations l10n) {
    final offline = NetworkErrorHelper.isServerOffline(provider.errorMessage);
    final icon = offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded;
    final accent = offline ? OwanyTheme.warning : OwanyTheme.error;
    final title = offline ? NetworkErrorHelper.offlineTitle() : l10n.reports_loading_error;
    final detail = offline
        ? NetworkErrorHelper.offlineMessage()
        : (provider.errorMessage ?? l10n.common_loading);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 14),
              ),
              const SizedBox(height: 20),
              PrimaryButton.primary(
                text: l10n.common_retry,
                onPressed: provider.atualizarTudo,
                icon: Icons.refresh_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: OwanyTheme.textMutedColor(context)),
            const SizedBox(height: 16),
            Text(
              l10n.reports_no_data,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ========================
  // KPIs
  // ========================

  Widget _buildKPIsGrid(DashboardEstatisticas stats, bool isWide, AppLocalizations l10n, int apartamentosEmManutencao) {
    return GridView.count(
      crossAxisCount: isWide ? 5 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWide ? 1.8 : 1.5,
      children: [
        _buildKPICard(
          label: l10n.apartments_list_title,
          value: stats.totalApartamentos,
          icon: Icons.apartment_rounded,
          color: OwanyTheme.primaryOrange,
        ),
        _buildKPICard(
          label: l10n.apartments_list_occupied,
          value: stats.apartamentosOcupados,
          icon: Icons.people_rounded,
          color: OwanyTheme.success,
        ),
        _buildKPICard(
          label: l10n.apartments_list_maintenance,
          value: apartamentosEmManutencao,  // Usa valor calculado localmente
          icon: Icons.construction_rounded,
          color: OwanyTheme.warning,
        ),
        _buildKPICard(
          label: l10n.common_residents,
          value: stats.totalMoradores,
          icon: Icons.group_rounded,
          color: OwanyTheme.info,
        ),
        _buildKPICard(
          label: l10n.maintenance_list_title,
          value: stats.totalSolicitacoes,
          icon: Icons.build_rounded,
          color: OwanyTheme.accent,
        ),
      ],
    );
  }

  Widget _buildKPICard({required String label, required int value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: OwanyTheme.textMutedColor(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // CHARTS
  // ========================

  Widget _buildChartsSection(
    DashboardEstatisticas stats,
    DashboardProvider provider,
    List<SolicitacaoListaDto> solicitacoesFiltradas,
    bool isWide,
    AppLocalizations l10n,
  ) {
    final statusItems = _buildStatusChartItems(
      provider,
      solicitacoesFiltradas,
      stats,
      l10n,
      !_temFiltroAtivo,
    );
    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPieChart(statusItems, l10n)),
              const SizedBox(width: 16),
              Expanded(child: _buildBarChart(statusItems, l10n)),
            ],
          )
        : Column(children: [_buildPieChart(statusItems, l10n), const SizedBox(height: 16), _buildBarChart(statusItems, l10n)]);
  }

  Widget _buildPieChart(List<_StatusChartItem> statusItems, AppLocalizations l10n) {
    final sections = statusItems
        .where((item) => item.count > 0)
        .map(
          (item) => PieChartSectionData(
            value: item.count.toDouble(),
            radius: 40,
            title: '${item.count}',
            color: item.color,
            titleStyle: TextStyle(color: OwanyTheme.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        )
        .toList();

    final hasData = sections.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: OwanyTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.dashboard_maintenance,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: OwanyTheme.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: hasData
                ? PieChart(
                    PieChartData(
                      centerSpaceRadius: 45,
                      sectionsSpace: 3,
                      sections: sections,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, size: 48, color: OwanyTheme.textMutedColor(context)),
                        const SizedBox(height: 8),
                        Text(l10n.reports_no_data, style: TextStyle(color: OwanyTheme.textMutedColor(context))),
                      ],
                    ),
                  ),
          ),
          if (hasData) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: statusItems
                  .where((item) => item.count > 0)
                  .map((item) => _buildLegendItem('${item.label} (${item.count})', item.color))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context))),
      ],
    );
  }

  Widget _buildBarChart(List<_StatusChartItem> statusItems, AppLocalizations l10n) {
    final items = statusItems.where((item) => item.count > 0).toList();
    final maxValue = items.isEmpty
        ? 0.0
        : items.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: OwanyTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.reports_requests_summary,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: OwanyTheme.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxValue > 0 ? maxValue * 1.2 : 10,
                barGroups: items
                    .asMap()
                    .entries
                    .map((entry) => _buildBarGroup(entry.key, entry.value.count, entry.value.color))
                    .toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 2.5,
                  getDrawingHorizontalLine: (value) => FlLine(color: OwanyTheme.borderColor(context), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final labels = items.map((e) => e.label).toList();
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          color: color,
        ),
      ],
    );
  }

  // ========================
  // MAINTENANCE PROGRESS
  // ========================

  Widget _buildMaintenanceProgress(
    DashboardEstatisticas stats,
    List<SolicitacaoListaDto> solicitacoes,
    AppLocalizations l10n,
  ) {
    
    int pendentes = 0, emAnalise = 0, emAndamento = 0, rejeitadas = 0, canceladas = 0, concluidas = 0;
    for (final sol in solicitacoes) {
      final key = _normalizeStatusKey(sol.status);
      if (key.contains('pend')) {
        pendentes++;
      } else if (key.contains('analis')) {
        emAnalise++;
      } else if (key.contains('andam') || key.contains('execu') || key.contains('inici')) {
        emAndamento++;
      } else if (key.contains('rejeit') || key.contains('recus')) {
        rejeitadas++;
      } else if (key.contains('cancel')) {
        canceladas++;
      } else if (key.contains('concl')) {
        concluidas++;
      }
    }
    
    // Sem filtro ativo, mantém fallback para evitar cards vazios no primeiro carregamento.
    if (solicitacoes.isEmpty && !_temFiltroAtivo) {
      pendentes = stats.solicitacoesPendentes;
      emAnalise = stats.solicitacoesEmAnalise;
      emAndamento = stats.solicitacoesEmAndamento;
      rejeitadas = stats.solicitacoesRejeitadas;
      canceladas = stats.solicitacoesCanceladas;
      concluidas = stats.solicitacoesConcluidas;
    }
    
    final total = (pendentes + emAnalise + emAndamento + rejeitadas + canceladas + concluidas).clamp(1, 999999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildProgressRow(l10n.maintenance_list_pending, pendentes, total, OwanyTheme.warning),
          const SizedBox(height: 12),
          _buildProgressRow('Em Análise', emAnalise, total, OwanyTheme.info),
          const SizedBox(height: 12),
          _buildProgressRow(
            l10n.maintenance_list_in_progress,
            emAndamento,
            total,
            OwanyTheme.primaryOrange,
          ),
          const SizedBox(height: 12),
          _buildProgressRow('Rejeitado', rejeitadas, total, OwanyTheme.error),
          const SizedBox(height: 12),
          _buildProgressRow('Cancelado', canceladas, total, OwanyTheme.lightSlate),
          const SizedBox(height: 12),
          _buildProgressRow(l10n.maintenance_list_completed, concluidas, total, OwanyTheme.success),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int value, int total, Color color) {
    final percent = (value / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value  •  ${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: OwanyTheme.borderColor(context).withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // OCCUPANCY
  // ========================

  Widget _buildOccupancySection(DashboardEstatisticas stats, AppLocalizations l10n) {
    final occupancyRate = stats.totalApartamentos > 0
        ? (stats.apartamentosOcupados / stats.totalApartamentos * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Occupancy rate circle
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: occupancyRate / 100,
                        strokeWidth: 8,
                        backgroundColor: OwanyTheme.borderColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          occupancyRate > 80
                              ? OwanyTheme.success
                              : occupancyRate > 50
                              ? OwanyTheme.warning
                              : OwanyTheme.error,
                        ),
                      ),
                    ),
                    Text(
                      '${occupancyRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reports_occupancy_rate,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.reports_apartments_of_total(stats.apartamentosOcupados, stats.totalApartamentos),
                      style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildOccupancyTile(
                  l10n.mp_list_total,
                  stats.totalApartamentos,
                  OwanyTheme.primaryOrange,
                  Icons.apartment_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOccupancyTile(
                  l10n.apartments_list_occupied,
                  stats.apartamentosOcupados,
                  OwanyTheme.success,
                  Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOccupancyTile(
                  l10n.reports_available,
                  stats.apartamentosDisponiveis,
                  OwanyTheme.warning,
                  Icons.event_available_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyTile(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========================
  // USERS SUMMARY
  // ========================

  Widget _buildUsersSummary(DashboardEstatisticas stats, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.people_alt_rounded, color: OwanyTheme.primaryOrange, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reports_system_users,
                  style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalUsuarios}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.totalMoradores}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: OwanyTheme.success),
              ),
              Text(l10n.common_residents, style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context))),
            ],
          ),
        ],
      ),
    );
  }

  // ========================
  // SECTION HEADER
  // ========================

  Widget _buildSectionHeader({required String title, required String subtitle, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: OwanyTheme.primaryOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
              ),
              Text(subtitle, style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  // ========================
  // CALCULAR KPIs FILTRADOS
  // ========================

  SolicitacoesKpisDto _calcularKpisFiltrados(List<SolicitacaoListaDto> solicitacoes) {
    int pendentes = 0, emAndamento = 0, concluidas = 0, atrasadas = 0;
    final Map<String, int> responsaveisAtraso = {};
    final Map<String, double> responsaveisAtrasoTempo = {};
    final Map<DateTime, int> countsPorMes = {};

    for (final sol in solicitacoes) {
      final key = _normalizeStatusKey(sol.status);
      
      // Contar por status
      if (key.contains('pend')) {
        pendentes++;
      } else if (key.contains('andam') || key.contains('execu') || key.contains('inici')) {
        emAndamento++;
      } else if (key.contains('concl')) {
        concluidas++;
      }

      // Verificar se está atrasada
      if (sol.prazoLimite != null && DateTime.now().isAfter(sol.prazoLimite!) && !key.contains('concl')) {
        atrasadas++;
        
        // Calcular dias de atraso
        final diasAtraso = DateTime.now().difference(sol.prazoLimite!).inDays.toDouble();
        
        // Contar responsável com atraso
        final resp = sol.nomeResponsavel ?? 'Não atribuído';
        responsaveisAtraso[resp] = (responsaveisAtraso[resp] ?? 0) + 1;
        responsaveisAtrasoTempo[resp] = (responsaveisAtrasoTempo[resp] ?? 0.0) + diasAtraso;
      }

      // Contar por mês (para gráfico mensal)
      final mesChave = DateTime(sol.criadoEm.year, sol.criadoEm.month, 1);
      countsPorMes[mesChave] = (countsPorMes[mesChave] ?? 0) + 1;
    }

    // Converter responsáveis em top 5
    final topResponsaveis = responsaveisAtraso.entries
        .map((e) => ResponsavelAtrasoDto(
          nome: e.key, 
          quantidadeAtrasadas: e.value,
          diasAtrasoMedio: e.value > 0 ? (responsaveisAtrasoTempo[e.key] ?? 0.0) / e.value : 0.0,
        ))
        .toList()
      ..sort((a, b) => b.quantidadeAtrasadas.compareTo(a.quantidadeAtrasadas));
    
    final top5Responsaveis = topResponsaveis.take(5).toList();

    // Converter dados mensais - usar nomes de mês em português
    final mesesPt = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final dadosMensais = countsPorMes.entries
        .map((e) => GraficoMensalDto(
          mes: '${mesesPt[e.key.month - 1]}/${e.key.year}', 
          quantidade: e.value,
        ))
        .toList()
      ..sort((a, b) => a.mes.compareTo(b.mes));

    // Calcular métricas adiccionais
    final total = solicitacoes.length;
    final taxaConclusao = total > 0 ? (concluidas / total) * 100.0 : 0.0;
    final taxaSla = total > 0 ? ((total - atrasadas) / total) * 100.0 : 100.0;

    return SolicitacoesKpisDto(
      total: total,
      pendentes: pendentes,
      emAndamento: emAndamento,
      concluidas: concluidas,
      atrasadas: atrasadas,
      taxaConclusao: taxaConclusao,
      taxaSla: taxaSla,
      mttrHoras: 0.0, // Seria necessário dados de resolução para calcular
      diasAtrasoMedio: 0.0, // Seria necessário mais lógica para calcular
      diasAtrasoMediana: 0.0, // Seria necessário mais lógica para calcular  
      percentOver48h: 0.0, // Seria necessário dados de SLA para calcular
      bucketsAtraso: [], // Vazio para filtros básicos
      topResponsaveisAtraso: top5Responsaveis,
      distribuicaoPorTipo: [], // Vazio para filtros básicos
      graficoMensal: dadosMensais,
    );
  }

  // ========================
  // SOLICITAÇÕES KPIs
  // ========================

  Widget _buildSolicitacoesKpisSection(List<SolicitacaoListaDto> solicitacoesFiltradas) {
    final kpis = _calcularKpisFiltrados(solicitacoesFiltradas);
    if (kpis.total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: _tx('KPIs de Solicitações', 'Request KPIs'),
          subtitle: _tx('Métricas detalhadas de desempenho (período filtrado)', 'Detailed performance metrics (filtered period)'),
          icon: Icons.speed_rounded,
        ),
        const SizedBox(height: 12),
        _buildKpisSummaryCards(kpis),
        if (kpis.topResponsaveisAtraso.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTopResponsaveisCard(kpis),
        ],
        if (kpis.graficoMensal.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGraficoMensalCard(kpis),
        ],
      ],
    );
  }

  Widget _buildKpisSummaryCards(SolicitacoesKpisDto kpis) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width > 900;
    
    // Calcular percentual de atrasadas
    final percentAtrasadas = kpis.total > 0 ? (kpis.atrasadas / kpis.total * 100) : 0.0;
    
    return Column(
      children: [
        // Linha principal: Total + Pendentes + Em Andamento + Concluídas + Atrasadas
        GridView.count(
          crossAxisCount: isWide ? 5 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 1.6 : 1.2,
          children: [
            _buildMiniKpi(
              label: l10n.mp_list_total,
              value: '${kpis.total}',
              icon: Icons.list_alt_rounded,
              color: OwanyTheme.primaryOrange,
            ),
            _buildMiniKpi(
              label: l10n.maintenance_list_pending,
              value: '${kpis.pendentes}',
              icon: Icons.hourglass_top_rounded,
              color: OwanyTheme.warning,
              subtitle: kpis.total > 0 ? '${(kpis.pendentes / kpis.total * 100).toStringAsFixed(0)}%' : null,
            ),
            _buildMiniKpi(
              label: l10n.maintenance_list_in_progress,
              value: '${kpis.emAndamento}',
              icon: Icons.engineering_rounded,
              color: OwanyTheme.info,
              subtitle: kpis.total > 0 ? '${(kpis.emAndamento / kpis.total * 100).toStringAsFixed(0)}%' : null,
            ),
            _buildMiniKpi(
              label: l10n.maintenance_list_completed,
              value: '${kpis.concluidas}',
              icon: Icons.task_alt_rounded,
              color: OwanyTheme.success,
              subtitle: kpis.total > 0 ? '${(kpis.concluidas / kpis.total * 100).toStringAsFixed(0)}%' : null,
            ),
            _buildMiniKpi(
              label: l10n.mp_alerts_overdue,
              value: '${kpis.atrasadas}',
              icon: Icons.running_with_errors_rounded,
              color: OwanyTheme.error,
              subtitle: percentAtrasadas > 0 ? '${percentAtrasadas.toStringAsFixed(0)}%' : null,
              highlight: kpis.atrasadas > 0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.06)
            : OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.3)
              : OwanyTheme.borderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryBrown.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: OwanyTheme.textPrimary(context),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: OwanyTheme.textMutedColor(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Removed: _buildKpisRatesRow, _buildRateCard, _buildMttrCard
  // Removed: _buildDelayStatsCard, _delayMetric
  // Removed: _buildDistribuicaoTipoCard
  // (User requested removal of Taxa Conclusão, MTTR, Taxa SLA, Delay Stats, Distribution by Type)

  Widget _buildTopResponsaveisCard(SolicitacoesKpisDto kpis) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OwanyTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_search_rounded, color: OwanyTheme.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text(l10n.reports_top_late_responsible, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 16),
          ...kpis.topResponsaveisAtraso.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final medalColors = [OwanyTheme.warning, OwanyTheme.textSecondary, const Color(0xFFCD7F32)];
            final medalColor = i < 3 ? medalColors[i] : OwanyTheme.borderColor(context);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: i < 3
                      ? medalColor.withValues(alpha: 0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: i < 3
                      ? Border.all(color: medalColor.withValues(alpha: 0.15))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: medalColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: medalColor))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r.nome, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: OwanyTheme.textPrimary(context)), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: OwanyTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: OwanyTheme.error),
                          const SizedBox(width: 4),
                          Text('${r.quantidadeAtrasadas}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OwanyTheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGraficoMensalCard(SolicitacoesKpisDto kpis) {
    final l10n = AppLocalizations.of(context)!;
    final data = kpis.graficoMensal;
    final maxVal = data.fold<int>(0, (m, e) => e.quantidade > m ? e.quantidade : m);
    final totalMensal = data.fold<int>(0, (s, e) => s + e.quantidade);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OwanyTheme.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up_rounded, color: OwanyTheme.info, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.reports_monthly_evolution, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: OwanyTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalMensal total',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OwanyTheme.info),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal.toDouble() * 1.2 : 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[groupIndex];
                      return BarTooltipItem(
                        '${item.mes}\n${rod.toY.toInt()} solicitações',
                        TextStyle(color: OwanyTheme.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        final label = data[idx].mes.length > 3 ? data[idx].mes.substring(0, 3) : data[idx].mes;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: OwanyTheme.textMutedColor(context))),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: OwanyTheme.textMutedColor(context)),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? maxVal / 4 : 2.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: OwanyTheme.borderColor(context).withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.quantidade.toDouble(),
                        gradient: LinearGradient(
                          colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withValues(alpha: 0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // HELPERS
  // ========================

  Widget _buildFiltrosSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, color: OwanyTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                _tx('Filtros', 'Filters'),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: OwanyTheme.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preset rápido de período
          Text(
            _tx('Período', 'Period'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textMutedColor(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodoChip(_tx('Tudo', 'All'), _mostrarTudo && _dataInicioFiltro == null && _mesSelecionado == null, () {
                setState(() { _mostrarTudo = true; _mesSelecionado = null; _dataInicioFiltro = null; _dataFimFiltro = null; });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Hoje', 'Today'), _isPeriodoAtivo('hoje'), () {
                final hoje = DateTime.now();
                setState(() { _mostrarTudo = false; _mesSelecionado = null; _dataInicioFiltro = hoje; _dataFimFiltro = hoje; });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Esta Semana', 'This Week'), _isPeriodoAtivo('semana'), () {
                final hoje = DateTime.now();
                final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
                final fim = inicio.add(const Duration(days: 6));
                setState(() { _mostrarTudo = false; _mesSelecionado = null; _dataInicioFiltro = inicio; _dataFimFiltro = fim; });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Este Mês', 'This Month'), _isPeriodoAtivo('mes'), () {
                final hoje = DateTime.now();
                setState(() { _mostrarTudo = false; _mesSelecionado = DateTime(hoje.year, hoje.month, 1); _dataInicioFiltro = null; _dataFimFiltro = null; });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Semestre', 'Semester'), _isPeriodoAtivo('semestre'), () {
                final hoje = DateTime.now();
                final inicioSemestre = hoje.month <= 6 ? DateTime(hoje.year, 1, 1) : DateTime(hoje.year, 7, 1);
                final fimSemestre = hoje.month <= 6 ? DateTime(hoje.year, 6, 30) : DateTime(hoje.year, 12, 31);
                setState(() { _mostrarTudo = false; _mesSelecionado = null; _dataInicioFiltro = inicioSemestre; _dataFimFiltro = fimSemestre; });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Ano', 'Year'), _isPeriodoAtivo('ano'), () {
                final hoje = DateTime.now();
                setState(() { _mostrarTudo = false; _mesSelecionado = null; _dataInicioFiltro = DateTime(hoje.year, 1, 1); _dataFimFiltro = DateTime(hoje.year, 12, 31); });
                _carregarDados();
              }),
              _buildPeriodoChip(_tx('Personalizado', 'Custom'), _isPeriodoAtivo('personalizado'), () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _dataInicioFiltro != null && _dataFimFiltro != null
                      ? DateTimeRange(start: _dataInicioFiltro!, end: _dataFimFiltro!)
                      : null,
                );
                if (range != null) {
                  setState(() { _mostrarTudo = false; _mesSelecionado = null; _dataInicioFiltro = range.start; _dataFimFiltro = range.end; });
                  _carregarDados();
                }
              }, icon: Icons.date_range_rounded),
            ],
          ),
          const SizedBox(height: 16),
          // Filtro de Status
          Row(
            children: [
              Text(
                _tx('Status', 'Status'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textMutedColor(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: OwanyTheme.borderColor(context)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _statusFiltro,
                      isExpanded: true,
                      hint: Text(_tx('Todos os Status', 'All Statuses'), style: TextStyle(color: OwanyTheme.textMutedColor(context))),
                      items: [
                        DropdownMenuItem(value: null, child: Text(_tx('Todos os Status', 'All Statuses'))),
                        DropdownMenuItem(value: 'Pendente', child: Text(_tx('Pendente', 'Pending'))),
                        DropdownMenuItem(value: 'EmAndamento', child: Text(_tx('Em Andamento', 'In Progress'))),
                        DropdownMenuItem(value: 'Concluido', child: Text(_tx('Concluído', 'Completed'))),
                        DropdownMenuItem(value: 'Cancelado', child: Text(_tx('Cancelado', 'Cancelled'))),
                        DropdownMenuItem(value: 'EmAnalise', child: Text(_tx('Em Análise', 'Under Review'))),
                        DropdownMenuItem(value: 'Rejeitado', child: Text(_tx('Rejeitado', 'Rejected'))),
                      ],
                      onChanged: (status) {
                        setState(() => _statusFiltro = status);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_temFiltroAtivo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OwanyTheme.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OwanyTheme.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: OwanyTheme.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFiltroResumoTexto(),
                      style: TextStyle(fontSize: 12, color: OwanyTheme.info, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(_tx('Limpar', 'Clear')),
                    onPressed: () {
                      setState(() {
                        _mostrarTudo = true;
                        _mesSelecionado = null;
                        _dataInicioFiltro = null;
                        _dataFimFiltro = null;
                        _statusFiltro = null;
                      });
                      _carregarDados();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isPeriodoAtivo(String tipo) {
    if (_mostrarTudo) return false;
    final hoje = DateTime.now();
    switch (tipo) {
      case 'hoje':
        return _dataInicioFiltro != null && _dataFimFiltro != null && _mesSelecionado == null &&
            _dataInicioFiltro!.year == hoje.year && _dataInicioFiltro!.month == hoje.month && _dataInicioFiltro!.day == hoje.day &&
            _dataFimFiltro!.year == hoje.year && _dataFimFiltro!.month == hoje.month && _dataFimFiltro!.day == hoje.day;
      case 'semana':
        final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
        return _dataInicioFiltro != null && _mesSelecionado == null &&
            _dataInicioFiltro!.year == inicio.year && _dataInicioFiltro!.month == inicio.month && _dataInicioFiltro!.day == inicio.day;
      case 'mes':
        return _mesSelecionado != null && _mesSelecionado!.year == hoje.year && _mesSelecionado!.month == hoje.month;
      case 'semestre':
        if (_dataInicioFiltro == null || _mesSelecionado != null) return false;
        final inicioS = hoje.month <= 6 ? DateTime(hoje.year, 1, 1) : DateTime(hoje.year, 7, 1);
        return _dataInicioFiltro!.year == inicioS.year && _dataInicioFiltro!.month == inicioS.month && _dataInicioFiltro!.day == inicioS.day;
      case 'ano':
        return _dataInicioFiltro != null && _mesSelecionado == null &&
            _dataInicioFiltro!.year == hoje.year && _dataInicioFiltro!.month == 1 && _dataInicioFiltro!.day == 1 &&
            _dataFimFiltro != null && _dataFimFiltro!.month == 12 && _dataFimFiltro!.day == 31;
      case 'personalizado':
        return !_mostrarTudo && _mesSelecionado == null && _dataInicioFiltro != null &&
            !_isPeriodoAtivo('hoje') && !_isPeriodoAtivo('semana') && !_isPeriodoAtivo('semestre') && !_isPeriodoAtivo('ano');
      default: return false;
    }
  }

  String _buildFiltroResumoTexto() {
    final partes = <String>[];
    if (_dataInicioFiltro != null && _dataFimFiltro != null) {
      partes.add('${_formatarData(_dataInicioFiltro!)} - ${_formatarData(_dataFimFiltro!)}');
    } else if (_mesSelecionado != null) {
      partes.add(_formatarMes(_mesSelecionado!));
    }
    if (_statusFiltro != null) partes.add(_statusFiltro!);
    return '${_tx('Filtrando', 'Filtering')}: ${partes.join(' • ')}';
  }

  Widget _buildPeriodoChip(String label, bool selected, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? OwanyTheme.primaryOrange : OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? OwanyTheme.primaryOrange : OwanyTheme.borderColor(context),
          ),
          boxShadow: selected ? [
            BoxShadow(color: OwanyTheme.primaryOrange.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : OwanyTheme.textMutedColor(context)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : OwanyTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistribuicaoAreaTecnicaSection(List<SolicitacaoListaDto> solicitacoes) {
    final solicitacoesProvider = context.watch<SolicitacoesProvider>();
    final areas = solicitacoesProvider.areasTecnicas;
    
    if (areas.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Calcular distribuição por área técnica
    final distribuicaoPorArea = <String, int>{};
    for (final area in areas) {
      distribuicaoPorArea[area.nome] = 0;
    }
    distribuicaoPorArea['Sem área'] = 0;
    
    for (final sol in solicitacoes) {
      final areaNome = sol.areaTecnicaNome;
      if (areaNome != null && areaNome.isNotEmpty) {
        distribuicaoPorArea[areaNome] = (distribuicaoPorArea[areaNome] ?? 0) + 1;
      } else {
        distribuicaoPorArea['Sem área'] = (distribuicaoPorArea['Sem área'] ?? 0) + 1;
      }
    }
    
    // Remover áreas com 0
    final distribuicaoFiltrada = distribuicaoPorArea.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (distribuicaoFiltrada.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final maxQtd = distribuicaoFiltrada.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    final total = distribuicaoFiltrada.fold<int>(0, (sum, e) => sum + e.value);
    
    // Cores para cada área
    final cores = [
      OwanyTheme.primaryOrange,
      OwanyTheme.success,
      OwanyTheme.info,
      OwanyTheme.warning,
      OwanyTheme.accent,
      OwanyTheme.error,
      const Color(0xFF7C3AED), // purple
      const Color(0xFF0891B2), // cyan
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: _tx('Distribuição por Área Técnica', 'Distribution by Technical Area'),
          subtitle: '$total ${_tx('solicitações agrupadas por área de atuação', 'requests grouped by work area')}',
          icon: Icons.category_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              ...distribuicaoFiltrada.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final cor = cores[i % cores.length];
                final percent = total > 0 ? (e.value / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                e.key,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${e.value}  •  ${percent.toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: maxQtd > 0 ? e.value / maxQtd : 0,
                          backgroundColor: cor.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(cor),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _mesAbreviado(int mes) {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return meses[mes - 1];
  }

  // ========================
  // MANUTENÇÕES GERAIS SECTION
  // ========================

  Widget _buildManutencoesGeraisSection(List<SolicitacaoListaDto> solicitacoes) {
    if (solicitacoes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Solicitações por mês (últimos 6 meses)
    final agora = DateTime.now();
    final porMes = <String, Map<String, int>>{};
    for (int i = 5; i >= 0; i--) {
      final mes = DateTime(agora.year, agora.month - i, 1);
      final chave = '${_mesAbreviado(mes.month)} ${mes.year.toString().substring(2)}';
      porMes[chave] = {'criadas': 0, 'concluidas': 0};
    }
    
    for (final sol in solicitacoes) {
      final mes = DateTime(sol.criadoEm.year, sol.criadoEm.month, 1);
      final diff = (agora.year * 12 + agora.month) - (mes.year * 12 + mes.month);
      if (diff >= 0 && diff < 6) {
        final chave = '${_mesAbreviado(mes.month)} ${mes.year.toString().substring(2)}';
        if (porMes.containsKey(chave)) {
          porMes[chave]!['criadas'] = (porMes[chave]!['criadas'] ?? 0) + 1;
          if (sol.status == 'Concluido') {
            porMes[chave]!['concluidas'] = (porMes[chave]!['concluidas'] ?? 0) + 1;
          }
        }
      }
    }
    
    // Resumo geral
    final totalSolicitacoes = solicitacoes.length;
    final abertas = solicitacoes.where((s) => s.status == 'Pendente' || s.status == 'EmAndamento' || s.status == 'EmAnalise').length;
    final resolvidas = solicitacoes.where((s) => s.status == 'Concluido').length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: _tx('Manutenções Gerais', 'General Maintenance'),
          subtitle: _tx('Visão consolidada das solicitações', 'Consolidated request overview'),
          icon: Icons.handyman_rounded,
        ),
        const SizedBox(height: 12),
        // Resumo cards
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResumoItem('Solicitações', '$totalSolicitacoes', OwanyTheme.primaryOrange),
                  Container(width: 1, height: 40, color: OwanyTheme.borderColor(context)),
                  _buildResumoItem('Abertas', '$abertas', OwanyTheme.warning),
                  Container(width: 1, height: 40, color: OwanyTheme.borderColor(context)),
                  _buildResumoItem('Resolvidas', '$resolvidas', OwanyTheme.success),
                ],
              ),
            ],
          ),
        ),
        // Evolução mensal (criadas vs concluídas)
        if (porMes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.show_chart_rounded, color: OwanyTheme.primaryOrange, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Criadas vs Concluídas (6 meses)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxMensalValue(porMes) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final mesKey = porMes.keys.elementAt(groupIndex);
                            final label = rodIndex == 0 ? 'Criadas' : 'Concluídas';
                            return BarTooltipItem(
                              '$mesKey\n$label: ${rod.toY.toInt()}',
                              TextStyle(color: OwanyTheme.white, fontSize: 11, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= porMes.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  porMes.keys.elementAt(idx),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: OwanyTheme.textMutedColor(context)),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: OwanyTheme.textMutedColor(context)),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: OwanyTheme.borderColor(context).withValues(alpha: 0.5),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      barGroups: porMes.entries.toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final data = entry.value.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (data['criadas'] ?? 0).toDouble(),
                              color: OwanyTheme.primaryOrange,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: (data['concluidas'] ?? 0).toDouble(),
                              color: OwanyTheme.success,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Criadas', OwanyTheme.primaryOrange),
                    const SizedBox(width: 24),
                    _buildLegendItem('Concluídas', OwanyTheme.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  double _maxMensalValue(Map<String, Map<String, int>> porMes) {
    double max = 10;
    for (final data in porMes.values) {
      final criadas = (data['criadas'] ?? 0).toDouble();
      final concluidas = (data['concluidas'] ?? 0).toDouble();
      if (criadas > max) max = criadas;
      if (concluidas > max) max = concluidas;
    }
    return max;
  }

  Widget _buildResumoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: OwanyTheme.textMutedColor(context)), textAlign: TextAlign.center),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: OwanyTheme.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OwanyTheme.borderColor(context)),
      boxShadow: [
        BoxShadow(color: OwanyTheme.primaryBrown.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }

  Color _colorForStatus(String? status) {
    final s = _normalizeStatusKey(status);
    if (s.contains('pend')) return OwanyTheme.warning;
    if (s.contains('andam')) return OwanyTheme.primaryOrange;
    if (s.contains('concl')) return OwanyTheme.success;
    if (s.contains('analis')) return OwanyTheme.info;
    if (s.contains('aguard')) return OwanyTheme.textSecondary;
    if (s.contains('rejeit')) return OwanyTheme.error;
    if (s.contains('recus')) return OwanyTheme.error;
    if (s.contains('cancel')) return OwanyTheme.lightSlate;
    return OwanyTheme.lightSlate;
  }

  /// Download múltiplos arquivos para uma pasta
  Future<void> _downloadRelatoCompleto() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      final l10n = AppLocalizations.of(context)!;
      
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text(l10n.reports_exporting_multiple),
            ],
          ),
          duration: Duration(seconds: 60),
        ),
      );

      // Selecionar pasta para salvar arquivos
      AppLogger.info('Reports', '📂 Abrindo diálogo para escolher pasta...');
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Escolha onde salvar o relatório',
      );
      
      if (selectedDirectory == null) {
        messenger.hideCurrentSnackBar();
        AppLogger.info('Reports', '❌ Download cancelado pelo usuário');
        return;
      }
      AppLogger.info('Reports', '✅ Pasta selecionada: $selectedDirectory');

      // Criar subpasta para o relatório
      final timestamp = _getWindowsCompatibleTimestamp();
      final reportFolder = path.join(selectedDirectory, 'Relatorio_$timestamp');
      await Directory(reportFolder).create(recursive: true);
      AppLogger.info('Reports', '📁 Subpasta criada: $reportFolder');

      // Lista de arquivos a baixar (numerados para facilitar navegação)
      final downloads = [
        {'name': '01_Solicitações Excel', 'file': '01_solicitacoes_$timestamp.xlsx', 'type': 'solicitacoes_excel'},
        {'name': '02_Solicitações PDF', 'file': '02_solicitacoes_$timestamp.pdf', 'type': 'solicitacoes_pdf'},
        {'name': '03_Apartamentos', 'file': '03_apartamentos_$timestamp.xlsx', 'type': 'apartamentos_excel'},
        {'name': '04_Moradores', 'file': '04_moradores_$timestamp.xlsx', 'type': 'moradores_excel'},
        {'name': '05_Usuários', 'file': '05_usuarios_$timestamp.xlsx', 'type': 'usuarios_excel'},
        {'name': '06_Agendamentos', 'file': '06_agendamentos_$timestamp.xlsx', 'type': 'agendamentos_excel'},
        {'name': '07_Manutenções Preventivas', 'file': '07_manutencoes_preventivas_$timestamp.xlsx', 'type': 'manutencoes_excel'},
        {'name': '08_Ativos/Patrimônio', 'file': '08_ativos_patrimonio_$timestamp.xlsx', 'type': 'ativos_excel'},
        {'name': '09_KPIs Excel', 'file': '09_kpis_$timestamp.xlsx', 'type': 'kpi_excel'},
        {'name': '10_KPIs PDF', 'file': '10_kpis_$timestamp.pdf', 'type': 'kpi_pdf'},
        {'name': '11_Histórico SMS', 'file': '11_historico_sms_$timestamp.xlsx', 'type': 'sms_excel'},
      ];

      int downloadCount = 0;

      for (var item in downloads) {
        try {
          final fileName = item['file'] as String;
          final type = item['type'] as String;
          final name = item['name'] as String;

          AppLogger.info('Reports', '📥 Baixando $name...');

          List<int> bytes;
          switch (type) {
            case 'solicitacoes_excel':
              bytes = await ApiService().exportarSolicitacoesExcel();
              break;
            case 'solicitacoes_pdf':
              bytes = await ApiService().exportarSolicitacoesPdf();
              break;
            case 'apartamentos_excel':
              bytes = await ApiService().exportarApartamentosExcel();
              break;
            case 'moradores_excel':
              bytes = await ApiService().exportarMoradoresExcel();
              break;
            case 'usuarios_excel':
              bytes = await ApiService().exportarUsuariosExcel();
              break;
            case 'agendamentos_excel':
              bytes = await ApiService().exportarAgendamentosExcel();
              break;
            case 'manutencoes_excel':
              bytes = await ApiService().exportarManutencoesPreventivasExcel();
              break;
            case 'ativos_excel':
              bytes = await ApiService().exportarAtivosExcel();
              break;
            case 'kpi_excel':
              bytes = await ApiService().exportarKpiExcel();
              break;
            case 'kpi_pdf':
              bytes = await ApiService().exportarKpiPdf();
              break;
            case 'sms_excel':
              bytes = await ApiService().exportarSmsExcel();
              break;
            default:
              continue;
          }

          // Salvar arquivo na subpasta
          final filePath = path.join(reportFolder, fileName);
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          
          AppLogger.info('Reports', '✅ $name salvo: $fileName');
          downloadCount++;
        } catch (e) {
          AppLogger.error('Reports', '❌ Erro ao baixar item', e);
        }
      }

      if (!mounted) return;
      messenger.hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${_tx('Relatório completo salvo', 'Full report saved')}! ($downloadCount ${_tx('arquivos', 'files')})',
          ),
          backgroundColor: OwanyTheme.success,
          duration: Duration(seconds: 5),
        ),
      );

      AppLogger.info('Reports', '🎉 Relatório completo finalizado com sucesso! ($downloadCount arquivos)');
    } catch (e) {
      AppLogger.error('Reports', '❌ Erro ao criar relatório completo', e);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${_tx('Erro', 'Error')}: ${e.toString()}'),
          backgroundColor: OwanyTheme.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}

