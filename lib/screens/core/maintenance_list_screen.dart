import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:owany_app/generated_l10n/app_localizations.dart';
import 'package:owany_app/providers/solicitacoes_provider.dart';
import 'package:owany_app/providers/auth_provider.dart';
import 'package:owany_app/models/enums.dart';
import 'package:owany_app/theme/owany_theme.dart';
import 'package:owany_app/dto/solicitacoes_v2_dtos.dart';
import 'package:owany_app/widgets/standard_glass_app_bar.dart';
import 'package:owany_app/utils/network_error_helper.dart';
import 'package:owany_app/screens/core/maintenance_detail_screen.dart';

class MaintenanceListScreen extends StatefulWidget {
  /// Filtro opcional de apartamento para mostrar apenas solicitações de um apartamento específico
  final String? apartamentoId;
  
  const MaintenanceListScreen({super.key, this.apartamentoId});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  String _filtroStatus = 'todas';
  String _filtroVisao = 'todas'; // 'todas' ou 'minhas' (minhas solicitações)
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _apartamentoSubtitulo;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Se tem apartamentoId filtro, carrega apenas desse apartamento
        if (widget.apartamentoId != null) {
          context.read<SolicitacoesProvider>().setFilters(
            apartamentoId: widget.apartamentoId,
            verTodas: true,
          );
          _carregarInfoApartamento();
        } else {
          // Funcionário começa em "todas", mas pode alternar para "minhas".
          final auth = context.read<AuthProvider>();
          String? aptId;
          String? respId;
          final verTodas = auth.isStaff && !auth.isMorador && _filtroVisao == 'todas';
          if (auth.isMorador) {
            aptId = auth.apartamentoIdDoMorador;
          } else if (auth.isFuncionario && !verTodas) {
            respId = auth.usuarioAtual?.id;
          }
          context.read<SolicitacoesProvider>().loadSolicitacoes(
            apartamentoId: aptId,
            responsavelId: respId,
            verTodas: verTodas,
            refresh: true,
          );
        }
      }
    });
  }
  
  /// Carrega as informações do apartamento para mostrar no título
  Future<void> _carregarInfoApartamento() async {
    if (widget.apartamentoId == null) return;
    
    // Aguarda as solicitações carregarem para pegar o número do apartamento
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    
    final solicitacoes = context.read<SolicitacoesProvider>().solicitacoes;
    if (solicitacoes.isNotEmpty) {
      final primeira = solicitacoes.first;
      setState(() {
        _apartamentoSubtitulo = 'Apt ${primeira.numeroApartamento}';
        if (primeira.blocoApartamento.isNotEmpty) {
          _apartamentoSubtitulo = '$_apartamentoSubtitulo / Bloco ${primeira.blocoApartamento}';
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SolicitacaoListaDto> _filtrarSolicitacoes(List<SolicitacaoListaDto> lista) {
    var resultado = lista;

    // Filtrar por visão (minhas vs todas)
    if (_filtroVisao == 'minhas') {
      final userId = context.read<AuthProvider>().usuarioAtual?.id;
      resultado = resultado.where((s) => s.responsavelId != null && s.responsavelId == userId).toList();
    }

    // Filtrar por status
    if (_filtroStatus == 'pendentes') {
      resultado = resultado.where((s) => s.status == 'Pendente').toList();
    } else if (_filtroStatus == 'andamento') {
      resultado = resultado.where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise').toList();
    } else if (_filtroStatus == 'concluidas') {
      resultado = resultado.where((s) => s.status == 'Concluido').toList();
    }

    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      resultado = resultado.where((s) => s.titulo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Ordenar por data de criação (mais recentes primeiro)
    resultado.sort((a, b) => (b.criadoEm).compareTo(a.criadoEm));

    return resultado;
  }

  Color _corStatus(String status) {
    if (status == 'Concluido') return OwanyTheme.success;
    if (status == 'EmAndamento') return OwanyTheme.warning;
    if (status == 'EmAnalise') return const Color(0xFF7C3AED);
    return OwanyTheme.error;
  }

  String _traduzirStatus(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'Concluido') return l10n.maintenance_status_completed;
    if (status == 'EmAndamento') return l10n.maintenance_status_in_progress;
    if (status == 'EmAnalise') return l10n.maintenance_status_in_analysis;
    if (status == 'Pendente') return l10n.maintenance_status_pending;
    return status;
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);
    final l10n = AppLocalizations.of(context)!;

    if (diferenca.inMinutes < 60) {
      return l10n.time_ago_minutes(diferenca.inMinutes);
    } else if (diferenca.inHours < 24) {
      return l10n.time_ago_hours(diferenca.inHours);
    } else if (diferenca.inDays == 1) {
      return l10n.time_yesterday;
    } else if (diferenca.inDays < 7) {
      return l10n.time_ago_days(diferenca.inDays);
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardGlassAppBar(
        title: widget.apartamentoId != null
            ? AppLocalizations.of(context)!.history_title
            : AppLocalizations.of(context)!.maintenance_list_title,
        icon: widget.apartamentoId != null ? Icons.history_rounded : Icons.build_rounded,
        showBackButton: widget.apartamentoId != null,
        subtitle: _apartamentoSubtitulo ?? (widget.apartamentoId != null ? 'Carregando...' : null),
      ),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: _buildLoadingSkeleton());
          }

          if (provider.errorMessage != null) {
            final offline = NetworkErrorHelper.isServerOffline(provider.errorMessage);
            final icon = offline ? Icons.cloud_off_rounded : Icons.error_outline;
            final accent = offline ? OwanyTheme.warning : OwanyTheme.error;
            final title = offline
                ? NetworkErrorHelper.offlineTitle()
                : AppLocalizations.of(context)!.maintenance_error_loading;
            final detail = offline
                ? NetworkErrorHelper.offlineMessage()
                : (provider.errorMessage ?? AppLocalizations.of(context)!.maintenance_try_again);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 64, color: accent),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: OwanyTheme.textPrimary(context)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    detail,
                    style: TextStyle(color: OwanyTheme.textMutedColor(context)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      String? aptId;
                      String? respId;
                      final verTodas = _filtroVisao == 'todas';
                      if (!verTodas) {
                        if (auth.isMorador) aptId = auth.apartamentoIdDoMorador;
                        if (auth.isFuncionario) respId = auth.usuarioAtual?.id;
                      }
                      provider.loadSolicitacoes(
                        apartamentoId: aptId,
                        responsavelId: respId,
                        verTodas: verTodas,
                        refresh: true,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: OwanyTheme.primaryOrange),
                    child: Text(AppLocalizations.of(context)!.maintenance_try_again),
                  ),
                ],
              ),
            );
          }

          final solicitacoesFiltradasLista = _filtrarSolicitacoes(provider.solicitacoes);

          // Contar por status
          final pendentes = provider.solicitacoes.where((s) => s.status == 'Pendente').length;
          final emAndamento = provider.solicitacoes.where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise').length;
          final concluidas = provider.solicitacoes.where((s) => s.status == 'Concluido').length;

          return Column(
            children: [
              // Dashboard Cards
              Container(
                padding: const EdgeInsets.all(16),
                color: OwanyTheme.textPrimary(context).withValues(alpha: 0.05),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildDashboardCard(
                      AppLocalizations.of(context)!.maintenance_pending_count,
                      pendentes.toString(),
                      OwanyTheme.error,
                      Icons.schedule,
                    ),
                    _buildDashboardCard(
                      AppLocalizations.of(context)!.maintenance_in_progress_count,
                      emAndamento.toString(),
                      OwanyTheme.warning,
                      Icons.build,
                    ),
                    _buildDashboardCard(
                      AppLocalizations.of(context)!.maintenance_completed_count,
                      concluidas.toString(),
                      OwanyTheme.success,
                      Icons.check_circle,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Filtros e busca
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de busca
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        color: OwanyTheme.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.maintenance_search_hint,
                        prefixIcon: Icon(Icons.search, color: OwanyTheme.textMutedColor(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: OwanyTheme.softOrange.withValues(alpha: 0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Filtro de Visão (Minhas vs Todas) — oculto em modo apartamento
                    if (widget.apartamentoId == null) ...[                      
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'todas',
                                  label: Text(_tx('Todas', 'All')),
                                  icon: const Icon(Icons.list),
                                ),
                                ButtonSegment(
                                  value: 'minhas',
                                  label: Text(_tx('Minhas', 'Mine')),
                                  icon: const Icon(Icons.assignment),
                                ),
                              ],
                              selected: {_filtroVisao},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _filtroVisao = newSelection.first;
                                });
                                final verTodas = _filtroVisao == 'todas';
                                final auth = context.read<AuthProvider>();
                                String? aptId;
                                String? respId;
                                if (!verTodas) {
                                  if (auth.isMorador) aptId = auth.apartamentoIdDoMorador;
                                  if (auth.isFuncionario) respId = auth.usuarioAtual?.id;
                                }
                                context.read<SolicitacoesProvider>().loadSolicitacoes(
                                  apartamentoId: aptId,
                                  responsavelId: respId,
                                  verTodas: verTodas,
                                  refresh: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                    ],

                    // FilterChips para status
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip('todas', AppLocalizations.of(context)!.maintenance_all),
                          SizedBox(width: 8),
                          _buildStatusChip('pendentes', AppLocalizations.of(context)!.maintenance_pending_count),
                          SizedBox(width: 8),
                          _buildStatusChip('andamento', AppLocalizations.of(context)!.maintenance_status_in_progress),
                          SizedBox(width: 8),
                          _buildStatusChip('concluidas', AppLocalizations.of(context)!.maintenance_completed_count),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Lista
              if (solicitacoesFiltradasLista.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.apartamentoId != null
                              ? Icons.home_work_outlined
                              : Icons.inbox_outlined,
                          size: 64,
                          color: widget.apartamentoId != null
                              ? OwanyTheme.success
                              : OwanyTheme.softOrange,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.maintenance_empty,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: OwanyTheme.textPrimary(context)),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.apartamentoId != null
                              ? (_filtroStatus == 'todas'
                                  ? 'Nenhuma solicitação registrada para este apartamento.'
                                  : AppLocalizations.of(context)!.maintenance_empty_filter_hint)
                              : (_filtroStatus == 'todas'
                                  ? AppLocalizations.of(context)!.maintenance_empty_create_hint
                                  : AppLocalizations.of(context)!.maintenance_empty_filter_hint),
                          style: TextStyle(color: OwanyTheme.textMutedColor(context)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: solicitacoesFiltradasLista.length,
                    itemBuilder: (context, index) {
                      final solicitacao = solicitacoesFiltradasLista[index];
                      final cor = _corStatus(solicitacao.status);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: cor.withValues(alpha: 0.3), width: 1.5),
                        ),
                        elevation: 2,
                        shadowColor: cor.withValues(alpha: 0.2),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaintenanceDetailScreen(
                                  solicitacaoId: solicitacao.id,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        solicitacao.status == 'Concluido'
                                            ? Icons.check_circle_rounded
                                            : solicitacao.status == 'Pendente'
                                            ? Icons.schedule_rounded
                                            : Icons.build_circle_rounded,
                                        color: cor,
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            solicitacao.titulo,
                                            style: TextStyle(
                                              fontSize: 15, 
                                              fontWeight: FontWeight.w700,
                                              color: OwanyTheme.textPrimary(context),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              if (widget.apartamentoId != null) ...[  
                                                Icon(Icons.person_outline_rounded, size: 14, color: OwanyTheme.textMutedColor(context)),
                                                SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    solicitacao.nomeUsuarioCriador,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: OwanyTheme.textMutedColor(context),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ] else ...[  
                                                Icon(Icons.apartment_rounded, size: 14, color: OwanyTheme.textMutedColor(context)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Apt ${solicitacao.numeroApartamento}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: OwanyTheme.textMutedColor(context),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                              SizedBox(width: 12),
                                              Icon(Icons.access_time_rounded, size: 14, color: OwanyTheme.textMutedColor(context)),
                                              SizedBox(width: 4),
                                              Text(
                                                _formatarData(solicitacao.criadoEm),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: OwanyTheme.textMutedColor(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: cor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _traduzirStatus(solicitacao.status, context),
                                        style: TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.w700, 
                                          color: cor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Barra de progresso visual
                                SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: solicitacao.status == 'Concluido'
                                        ? 1.0
                                        : solicitacao.status == 'EmAndamento'
                                            ? 0.6
                                            : solicitacao.status == 'EmAnalise'
                                                ? 0.3
                                                : 0.1,
                                    backgroundColor: OwanyTheme.borderColor(context),
                                    color: cor,
                                    minHeight: 4,
                                  ),
                                ),
                                // Linha de metadados: tipo, responsável, prazo, contagens
                                Builder(builder: (context) {
                                  final temTipo = (solicitacao.tipoSolicitacaoNome?.isNotEmpty ?? false);
                                  final temArea = (solicitacao.areaTecnicaNome?.isNotEmpty ?? false);
                                  final temResponsavel = (solicitacao.nomeResponsavel?.isNotEmpty ?? false) &&
                                      widget.apartamentoId == null;
                                  final atrasado = solicitacao.prazoLimite != null &&
                                      solicitacao.prazoLimite!.isBefore(DateTime.now()) &&
                                      solicitacao.status != 'Concluido';
                                  final prazoHoje = solicitacao.prazoLimite != null &&
                                      !atrasado &&
                                      solicitacao.prazoLimite!.difference(DateTime.now()).inHours <= 24 &&
                                      solicitacao.status != 'Concluido';
                                  final muted = OwanyTheme.textMutedColor(context);

                                  if (!temTipo && !temArea && !temResponsavel &&
                                      solicitacao.quantidadeComentarios == 0 &&
                                      solicitacao.quantidadeAnexos == 0 &&
                                      solicitacao.prazoLimite == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (temTipo)
                                          _buildMetaChip(
                                            Icons.category_outlined,
                                            solicitacao.tipoSolicitacaoNome!,
                                            muted,
                                          ),
                                        if (temArea)
                                          _buildMetaChip(
                                            Icons.engineering_outlined,
                                            solicitacao.areaTecnicaNome!,
                                            muted,
                                          ),
                                        if (temResponsavel)
                                          _buildMetaChip(
                                            Icons.build_outlined,
                                            solicitacao.nomeResponsavel!,
                                            muted,
                                          ),
                                        if (solicitacao.quantidadeComentarios > 0)
                                          _buildMetaChip(
                                            Icons.chat_bubble_outline_rounded,
                                            '${solicitacao.quantidadeComentarios}',
                                            muted,
                                          ),
                                        if (solicitacao.quantidadeAnexos > 0)
                                          _buildMetaChip(
                                            Icons.attach_file_rounded,
                                            '${solicitacao.quantidadeAnexos}',
                                            muted,
                                          ),
                                        if (atrasado)
                                          _buildMetaChip(
                                            Icons.warning_amber_rounded,
                                            'Prazo expirado',
                                            OwanyTheme.error,
                                          ),
                                        if (prazoHoje)
                                          _buildMetaChip(
                                            Icons.schedule_rounded,
                                            'Prazo hoje',
                                            OwanyTheme.warning,
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFabIfAllowed(),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w500),
              ),
              Icon(icone, color: cor, size: 16),
            ],
          ),
          Text(
            valor,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _filtroStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroStatus = value;
        });
      },
      selectedColor: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
      backgroundColor: OwanyTheme.softOrange,
      labelStyle: TextStyle(
        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.softOrange),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard skeleton
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(
                3,
                (index) => Container(
                  decoration: BoxDecoration(color: OwanyTheme.softOrange, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Search skeleton
            Container(
              height: 48,
              decoration: BoxDecoration(color: OwanyTheme.softOrange, borderRadius: BorderRadius.circular(8)),
            ),
            SizedBox(height: 12),

            // List skeleton
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(color: OwanyTheme.softOrange, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFabIfAllowed() {
    final userType = context.watch<AuthProvider>().usuarioAtual?.tipo;
    // FAB só para gestores (Admin, Síndico, Funcionário)
    if (userType != UsuarioTipo.Administrador &&
        userType != UsuarioTipo.Sindico &&
        userType != UsuarioTipo.Funcionario) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/solicitacao-criar');
      },
      backgroundColor: OwanyTheme.primaryOrange,
      child: Icon(Icons.add, color: OwanyTheme.adaptiveTextOverlay(context)),
    );
  }
}
