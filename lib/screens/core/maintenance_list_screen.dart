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
  /// Controla se pode abrir o detalhe da manutenção ao tocar no card
  final bool permitirAbrirDetalhe;
  
  const MaintenanceListScreen({
    super.key,
    this.apartamentoId,
    this.permitirAbrirDetalhe = true,
  });

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  String _filtroStatus = 'todas';
  String _filtroVisao = 'todas'; // 'todas' ou 'minhas' (minhas solicitações)
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _apartamentoSubtitulo;
  bool _mostrarAgrupado = true;
  final Map<String, bool> _expandedGroups = {};
  List<SolicitacaoListaDto>? _filteredCache;
  List<SolicitacaoListaDto>? _cachedSource;
  int _cachedSourceLength = -1;
  String? _cachedSourceFirstId;
  String? _cachedSourceLastId;
  String _cachedFiltroStatus = 'todas';
  String _cachedFiltroVisao = 'todas';
  String _cachedSearchQuery = '';
  List<SolicitacaoListaDto>? _searchIndexSource;
  int _searchIndexLength = -1;
  String? _searchIndexFirstId;
  String? _searchIndexLastId;
  Map<String, String> _searchIndex = {};

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
            refresh: false,
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
    final length = lista.length;
    final firstId = length > 0 ? lista.first.id : null;
    final lastId = length > 0 ? lista.last.id : null;
    final canUseCache =
        identical(_cachedSource, lista) &&
        _cachedSourceLength == length &&
        _cachedSourceFirstId == firstId &&
        _cachedSourceLastId == lastId &&
        _cachedFiltroStatus == _filtroStatus &&
        _cachedFiltroVisao == _filtroVisao &&
        _cachedSearchQuery == _searchQuery &&
        _filteredCache != null;
    if (canUseCache) return _filteredCache!;

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
      if (!identical(_searchIndexSource, lista) ||
          _searchIndexLength != length ||
          _searchIndexFirstId != firstId ||
          _searchIndexLastId != lastId) {
        _searchIndexSource = lista;
        _searchIndexLength = length;
        _searchIndexFirstId = firstId;
        _searchIndexLastId = lastId;
        _searchIndex = {
          for (final s in lista)
            s.id: [
              s.titulo,
              s.numeroApartamento,
              s.blocoApartamento,
              s.nomeUsuarioCriador,
              s.nomeResponsavel ?? '',
              s.tipoSolicitacaoNome ?? '',
              s.id,
            ].map((e) => e.toLowerCase()).join('|'),
        };
      }
      final q = _searchQuery.toLowerCase();
      resultado = resultado.where((s) => (_searchIndex[s.id] ?? '').contains(q)).toList();
    }

    // Ordenar por data de criação (mais recentes primeiro)
    resultado.sort((a, b) => (b.criadoEm).compareTo(a.criadoEm));

    _cachedSource = lista;
    _cachedSourceLength = length;
    _cachedSourceFirstId = firstId;
    _cachedSourceLastId = lastId;
    _cachedFiltroStatus = _filtroStatus;
    _cachedFiltroVisao = _filtroVisao;
    _cachedSearchQuery = _searchQuery;
    _filteredCache = resultado;
    return resultado;
  }

  void _invalidateFilteredCache() {
    _filteredCache = null;
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

  Widget _buildGroupLabel(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(SolicitacaoListaDto solicitacao) {
    final cor = _corStatus(solicitacao.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: widget.permitirAbrirDetalhe
            ? () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaintenanceDetailScreen(
                      solicitacaoId: solicitacao.id,
                    ),
                  ),
                );
              }
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
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
            size: 18,
          ),
        ),
        title: Text(
          solicitacao.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: OwanyTheme.textPrimary(context),
          ),
        ),
        subtitle: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: 12, color: OwanyTheme.textMutedColor(context)),
            Text(
              _formatarData(solicitacao.criadoEm),
              style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
            ),
            Icon(Icons.apartment_rounded, size: 12, color: OwanyTheme.textMutedColor(context)),
            Text(
              widget.apartamentoId != null
                  ? (solicitacao.nomeUsuarioCriador.isNotEmpty
                      ? solicitacao.nomeUsuarioCriador
                      : 'Morador')
                  : 'Apt ${solicitacao.numeroApartamento}',
              style: TextStyle(fontSize: 11, color: OwanyTheme.textMutedColor(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withValues(alpha: 0.3)),
          ),
          child: Text(
            _traduzirStatus(solicitacao.status, context),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cor),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(List<SolicitacaoListaDto> list) {
    final pendentes = list.where((s) => s.status == 'Pendente').toList();
    final andamento = list.where((s) => s.status == 'EmAndamento' || s.status == 'EmAnalise').toList();
    final concluidas = list.where((s) => s.status == 'Concluido').toList();
    final outros = list.where((s) =>
        s.status != 'Pendente' &&
        s.status != 'EmAndamento' &&
        s.status != 'EmAnalise' &&
        s.status != 'Concluido').toList();

    final widgets = <Widget>[];
    void addSection(String title, List<SolicitacaoListaDto> src, Color color) {
      if (src.isEmpty) return;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      final isExpanded = _expandedGroups[title] ?? false;
      widgets.add(
        InkWell(
          onTap: () => setState(() => _expandedGroups[title] = !isExpanded),
          child: Row(
            children: [
              Expanded(child: _buildGroupLabel(title, src.length, color)),
              const SizedBox(width: 6),
              Transform.rotate(
                angle: isExpanded ? 0 : -3.1416 / 2,
                child: Icon(Icons.chevron_left_rounded, color: OwanyTheme.textMutedColor(context)),
              ),
            ],
          ),
        ),
      );
      if (isExpanded) {
        widgets.add(const SizedBox(height: 8));
        widgets.addAll(src.map(_buildCompactCard));
      }
    }

    addSection(_tx('Pendentes', 'Pending'), pendentes, OwanyTheme.error);
    addSection(_tx('Em andamento', 'In progress'), andamento, OwanyTheme.warning);
    addSection(_tx('Concluídas', 'Completed'), concluidas, OwanyTheme.success);
    addSection(_tx('Outros', 'Others'), outros, OwanyTheme.textMutedColor(context));
    return widgets;
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

          return Column(
            children: [
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
                          _invalidateFilteredCache();
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
                                  _invalidateFilteredCache();
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tx('Agrupar por status', 'Group by status'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                        ),
                        Switch(
                          value: _mostrarAgrupado,
                          onChanged: (v) => setState(() => _mostrarAgrupado = v),
                          activeColor: OwanyTheme.primaryOrange,
                        ),
                      ],
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: _mostrarAgrupado
                        ? _buildGroupedList(solicitacoesFiltradasLista)
                        : solicitacoesFiltradasLista.map(_buildCompactCard).toList(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatRelative({DateTime? prazo}) {
    if (prazo == null) return '';
    final now = DateTime.now();
    final diff = now.difference(prazo);
    if (diff.inDays >= 1) return '${diff.inDays} dias atrás';
    if (diff.inHours >= 1) return '${diff.inHours}h atrás';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m atrás';
    return 'agora';
  }

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _filtroStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroStatus = value;
          _invalidateFilteredCache();
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
