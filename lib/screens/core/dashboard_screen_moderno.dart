import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../providers/apartamentos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/moradores_provider.dart';
import '../../providers/agendamentos_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/notificacoes_provider.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_logger.dart';
import '../../utils/network_error_helper.dart';
import '../../widgets/modern_components.dart';

/// Dashboard Moderno com métricas e atalhos rápidos.
class DashboardScreenModerno extends StatefulWidget {
  const DashboardScreenModerno({super.key});

  @override
  State<DashboardScreenModerno> createState() => _DashboardScreenModernoState();
}

class _DashboardScreenModernoState extends State<DashboardScreenModerno> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados({bool forceRefresh = false}) {
    AppLogger.info('Dashboard', 'Carregando dados...');
    Future.microtask(() async {
      final authProvider = context.read<AuthProvider>();
      final solicitacoesProvider = context.read<SolicitacoesProvider>();
      final apartamentosProvider = context.read<ApartamentosProvider>();

        // Conectar SignalR se ainda não conectado (path de auto-login)
        try {
          final notifProv = context.read<NotificacoesProvider>();
          if (!notifProv.signalRConectado) {
            await notifProv.conectarSignalR();
          }
          // Carregar contagem de notificações não lidas para o badge
          await notifProv.carregarResumo();

          if (!mounted) return;

          // Ativar sincronização em tempo real para cada provider
          final apartamentoIdDoMorador = authProvider.apartamentoIdDoMorador;
          if (authProvider.isMorador || authProvider.isVisitante) {
            if (apartamentoIdDoMorador != null && apartamentoIdDoMorador.isNotEmpty) {
              context
                  .read<ApartamentosProvider>()
                  .inicializarRealtimeSync(apartamentoIdRestrito: apartamentoIdDoMorador);
            } else {
              // Morador/visitante sem apartamento: não assina lista global de apartamentos.
              context.read<ApartamentosProvider>().pararRealtimeSync();
            }
          } else {
            context.read<ApartamentosProvider>().inicializarRealtimeSync();
          }
          context.read<MoradoresProvider>().inicializarRealtimeSync();
          context.read<SolicitacoesProvider>().inicializarRealtimeSync();
          context
              .read<AgendamentosProvider>()
              .inicializarRealtimeSync(apartamentoIdRestrito: apartamentoIdDoMorador);
        } catch (e) {
          AppLogger.error('Dashboard', 'Erro ao conectar SignalR: $e');
      }
      
      if (!mounted) return;

      // RBAC: Controle de acesso por perfil
      if (authProvider.isMorador || authProvider.isVisitante) {
        // Morador/Visitante só vê dados do seu apartamento
        final apartamentoId = authProvider.apartamentoIdDoMorador;
        if (apartamentoId != null && apartamentoId.isNotEmpty) {
          AppLogger.info('Dashboard', '🔒 Morador carregando APENAS apartamento: $apartamentoId');
          // Fase 1: KPIs (contagens) + apartamento (dados essenciais)
          await Future.wait([
            apartamentosProvider.carregarApartamentoPorId(apartamentoId),
            solicitacoesProvider.carregarKpis(),
          ]);
          if (!mounted) return;
          // Fase 2: todas as solicitações (atividade recente)
          await solicitacoesProvider.loadSolicitacoes(
            apartamentoId: apartamentoId,
            refresh: forceRefresh,
            carregarTodas: true,
          );
        } else {
          // Morador sem apartamento vinculado - não carrega nada
          AppLogger.warning('Dashboard', '⚠️ Morador sem apartamento vinculado');
          apartamentosProvider.limparDados();
          solicitacoesProvider.limparDados();
        }
      } else if (authProvider.isPortaria) {
        // Portaria vê apartamentos mas não solicitações
        AppLogger.info('Dashboard', '🔒 Portaria carregando apartamentos');
        await apartamentosProvider.carregarApartamentos(comMoradores: false);
        // Não carrega solicitações para portaria
      } else if (authProvider.isStaff) {
        // Staff (Admin/Síndico/Funcionário) vê tudo
        AppLogger.info('Dashboard', '✅ Staff carregando todos os dados');
        // Fase 1: KPIs (contagens) + apartamentos — 2 chamadas paralelas
        await Future.wait([
          solicitacoesProvider.carregarKpis(),
          apartamentosProvider.carregarApartamentos(comMoradores: false),
        ]);
        if (!mounted) return;
        // Fase 2: todas as solicitações para atividade recente
        await solicitacoesProvider.loadSolicitacoes(
          refresh: forceRefresh,
          carregarTodas: true,
        );
      } else {
        // Outros roles - acesso mínimo
        AppLogger.warning('Dashboard', '⚠️ Role desconhecido ou sem permissão');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: Consumer3<AuthProvider, SolicitacoesProvider, ApartamentosProvider>(
        builder: (context, authProvider, solicitacoesProvider, apartamentosProvider, _) {
          final usuario = authProvider.usuarioAtual;

          if (usuario == null) {
            Future.microtask(() => authProvider.logout(context));
            return Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange)),
            );
          }

          if (solicitacoesProvider.isLoading && apartamentosProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange)),
            );
          }

          if (apartamentosProvider.errorMessage != null) {
            if (NetworkErrorHelper.isServerOffline(apartamentosProvider.errorMessage)) {
              return ModernEmptyState.serverOffline(onRetry: _carregarDados);
            }
            return ModernEmptyState(
              icon: Icons.error_outline_rounded,
              title: AppLocalizations.of(context)!.dashboard_error_loading_apartments,
              message: apartamentosProvider.errorMessage!,
              onRetry: _carregarDados,
              iconColor: OwanyTheme.error,
            );
          }

          // Para morador/visitante, as métricas devem refletir apenas o apartamento
          // carregado; usamos as solicitações já carregadas no provider.
          final kpis = solicitacoesProvider.kpis;
          int totalSolicitacoes = solicitacoesProvider.totalItems;
          int pendentes = 0;
          int emAndamento = 0;
          int concluidas = 0;

          if (authProvider.isMorador || authProvider.isVisitante) {
            final statusCounts = <String, int>{};
            for (final s in solicitacoesProvider.solicitacoes) {
              statusCounts[s.status] = (statusCounts[s.status] ?? 0) + 1;
            }
            pendentes = statusCounts['Pendente'] ?? 0;
            emAndamento = statusCounts['EmAndamento'] ?? 0;
            concluidas = statusCounts['Concluido'] ?? 0;
            totalSolicitacoes = solicitacoesProvider.solicitacoes.length;
          } else {
            // Staff: prefere KPIs do endpoint (global)
            if (kpis != null) {
              pendentes = kpis.pendentes;
              emAndamento = kpis.emAndamento;
              concluidas = kpis.concluidas;
            } else {
              final statusCounts = <String, int>{};
              for (final s in solicitacoesProvider.solicitacoes) {
                statusCounts[s.status] = (statusCounts[s.status] ?? 0) + 1;
              }
              pendentes = statusCounts['Pendente'] ?? 0;
              emAndamento = statusCounts['EmAndamento'] ?? 0;
              concluidas = statusCounts['Concluido'] ?? 0;
            }
          }

          // Contagens da página carregada para statuses não cobertos pelo KPI
          final statusCountsPage = <String, int>{};
          for (final s in solicitacoesProvider.solicitacoes) {
            statusCountsPage[s.status] = (statusCountsPage[s.status] ?? 0) + 1;
          }
          final emAnalise = statusCountsPage['EmAnalise'] ?? 0;
          final rejeitadas = statusCountsPage['Rejeitado'] ?? 0;
          final canceladas = statusCountsPage['Cancelado'] ?? 0;
          final totalApartamentos = apartamentosProvider.apartamentos.length;

          final isPortaria = authProvider.isPortaria;
          final podeComunicado = usuario.tipo == UsuarioTipo.Administrador || usuario.tipo == UsuarioTipo.Sindico;

          return RefreshIndicator(
            onRefresh: () async {
              _carregarDados(forceRefresh: true);
              await Future.delayed(const Duration(milliseconds: 800));
            },
            color: OwanyTheme.primaryOrange,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(usuario.nome, pendentes),
                    SizedBox(height: 32),
                    if (solicitacoesProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OwanyTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: OwanyTheme.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: OwanyTheme.warning, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.dashboard_system_updating,
                                      style: TextStyle(
                                        color: OwanyTheme.textPrimary(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)!.dashboard_requests_not_available,
                                      style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _buildMetrics(
                      totalSolicitacoes,
                      pendentes,
                      totalApartamentos,
                      showSolicitacoes: !isPortaria,
                      showApartamentos: true,
                      disableApartamentosTap: isPortaria,
                    ),
                    SizedBox(height: 32),
                    if (!isPortaria) ...[
                      _buildStatusSection(pendentes, emAnalise, emAndamento, rejeitadas, canceladas, concluidas),
                      SizedBox(height: 32),
                      if (solicitacoesProvider.solicitacoes.isNotEmpty) _buildAtividades(solicitacoesProvider),
                      SizedBox(height: 32),
                      _buildAcoesRapidas(context, podeComunicado),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return nome.isNotEmpty ? nome[0].toUpperCase() : '?';
  }

  Widget _buildHeader(String nome, int pendentes) {
    final hora = DateTime.now().hour;
    final saudacao = hora < 12 ? 'Bom dia' : hora < 18 ? 'Boa tarde' : 'Boa noite';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, const Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                _initials(nome),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saudacao 👋',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  nome,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  pendentes > 0
                      ? '$pendentes solicitaç${pendentes == 1 ? 'ão pendente' : 'ões pendentes'}'
                      : 'Nenhuma pendência ✓',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (pendentes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text(
                '$pendentes',
                style: TextStyle(color: OwanyTheme.primaryOrange, fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetrics(
    int totalSolicitacoes,
    int pendentes,
    int totalApartamentos, {
    bool showSolicitacoes = true,
    bool showApartamentos = true,
    bool disableApartamentosTap = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 560;
        final visibleCards = [
          if (showSolicitacoes) true,
          if (showApartamentos) true,
        ];
        final int cardCount = visibleCards.length;
        final double itemWidth = isNarrow || cardCount <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.dashboard_main_stats,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Relatórios — Staff (Admin/Síndico/Funcionário)
                if (context.read<AuthProvider>().isStaff)
                  TextButton(
                    onPressed: () {
                      AppLogger.info('Dashboard', 'Acessando relatórios');
                      Navigator.pushNamed(context, '/relatorios');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: OwanyTheme.primaryOrange,
                      textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(AppLocalizations.of(context)!.dashboard_view_all),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (showSolicitacoes)
                  SizedBox(
                    width: itemWidth,
                    child: _buildMetricCard(
                      icon: Icons.build_rounded,
                      value: totalSolicitacoes.toString(),
                      label: AppLocalizations.of(context)!.dashboard_maintenance,
                      subtitle: pendentes > 0
                          ? '$pendentes ${AppLocalizations.of(context)!.dashboard_open_count}'
                          : AppLocalizations.of(context)!.dashboard_all_completed,
                      color: OwanyTheme.primaryOrange,
                      onTap: () => Navigator.pushNamed(context, '/solicitacoes'),
                    ),
                  ),
                if (showApartamentos)
                  SizedBox(
                    width: itemWidth,
                    child: _buildMetricCard(
                      icon: Icons.apartment_rounded,
                      value: totalApartamentos.toString(),
                      label: AppLocalizations.of(context)!.apartments_list_title,
                      subtitle: AppLocalizations.of(context)!.dashboard_total_condo,
                      color: OwanyTheme.success,
                      onTap: disableApartamentosTap
                          ? null
                          : () => Navigator.pushNamed(context, '/apartamentos'),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusSection(int pendentes, int emAnalise, int emAndamento, int rejeitadas, int canceladas, int concluidas) {
    final statusItems = [
      (AppLocalizations.of(context)!.maintenance_list_pending, pendentes, OwanyTheme.warning, Icons.hourglass_bottom_rounded),
      ('Em Análise', emAnalise, const Color(0xFF7C3AED), Icons.manage_search_rounded),
      (AppLocalizations.of(context)!.maintenance_list_in_progress, emAndamento, OwanyTheme.info, Icons.autorenew_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dashboard_status_requests,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (int i = 0; i < statusItems.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _buildStatusCard(
                  label: statusItems[i].$1,
                  count: statusItems[i].$2,
                  color: statusItems[i].$3,
                  icon: statusItems[i].$4,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAtividades(SolicitacoesProvider solicitacoesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.dashboard_recent_activity,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/solicitacoes'),
              style: TextButton.styleFrom(
                foregroundColor: OwanyTheme.primaryOrange,
                textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(AppLocalizations.of(context)!.dashboard_view_all),
            ),
          ],
        ),
        SizedBox(height: 16),
          ...solicitacoesProvider.solicitacoes.take(4).map((s) {
            final statusColor = _statusColor(s.status);
            final statusLabel = _statusLabel(s.status);
            return _buildActivityCard(
              title: s.titulo,
              statusLabel: statusLabel,
              statusColor: statusColor,
              timestamp: _formatarTempo(s.criadoEm),
              onTap: () => Navigator.pushNamed(
                context,
                '/solicitacoes-detalhe',
                arguments: {'solicitacaoId': s.id},
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAcoesRapidas(BuildContext context, bool podeComunicado) {
    final auth = context.read<AuthProvider>();
    final userType = auth.usuarioAtual?.tipo;
    final podeCriarSolicitacao = userType == UsuarioTipo.Administrador ||
        userType == UsuarioTipo.Sindico ||
        userType == UsuarioTipo.Funcionario ||
        userType == UsuarioTipo.Morador;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dashboard_quick_actions,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isNarrow = constraints.maxWidth < 520;
            final double itemWidth = isNarrow ? constraints.maxWidth : 220;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (podeCriarSolicitacao)
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      style: OwanyTheme.primaryButtonStyle(),
                      onPressed: () => Navigator.pushNamed(context, '/solicitacoes-nova'),
                      icon: Icon(Icons.add_rounded),
                      label: Text(AppLocalizations.of(context)!.dashboard_new_request),
                    ),
                  ),
                SizedBox(
                  width: itemWidth,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/configuracoes'),
                    icon: Icon(Icons.settings_rounded, color: OwanyTheme.textMutedColor(context)),
                    label: Text(
                      AppLocalizations.of(context)!.settings_title,
                      style: TextStyle(color: OwanyTheme.textMutedColor(context), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatarTempo(DateTime? data) {
    final l10n = AppLocalizations.of(context)!;
    if (data == null) return l10n.dashboard_date_unknown;

    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inMinutes < 1) return l10n.dashboard_date_now;
    if (diferenca.inMinutes < 60) return l10n.time_ago_minutes(diferenca.inMinutes);
    if (diferenca.inHours < 24) return l10n.time_ago_hours(diferenca.inHours);
    if (diferenca.inDays < 7) return l10n.time_ago_days(diferenca.inDays);
    return '${data.day}/${data.month}/${data.year}';
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: OwanyTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context), fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: 0.75, child: card);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildStatusCard({required String label, required int count, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context), letterSpacing: -0.5),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pendente':    return OwanyTheme.warning;
      case 'EmAnalise':   return const Color(0xFF7C3AED);
      case 'EmAndamento': return OwanyTheme.info;
      case 'Concluido':   return OwanyTheme.success;
      case 'Cancelado':   return OwanyTheme.lightSlate;
      case 'Rejeitado':   return OwanyTheme.error;
      default:            return OwanyTheme.textMutedColor(context);
    }
  }

  String _statusLabel(String status) {
    const map = {
      'Pendente': 'Pendente',
      'EmAnalise': 'Em Análise',
      'EmAndamento': 'Em Andamento',
      'Concluido': 'Concluído',
      'Cancelado': 'Cancelado',
      'Rejeitado': 'Rejeitado',
    };
    return map[status] ?? status;
  }

  Widget _buildActivityCard({
    required String title,
    required String statusLabel,
    required Color statusColor,
    required String timestamp,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: OwanyTheme.cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 5)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          timestamp,
                          style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: OwanyTheme.textMutedColor(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
