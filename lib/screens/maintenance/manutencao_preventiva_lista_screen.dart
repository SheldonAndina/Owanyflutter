import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:owany_app/models/dtos_complementares.dart';
import 'package:owany_app/providers/manutencao_preventiva_provider.dart';
import 'package:owany_app/providers/language_provider.dart';
import 'package:owany_app/theme/owany_theme.dart';
import 'package:owany_app/widgets/standard_glass_app_bar.dart';

/// Lista de Manutenções Gerais/Preventivas
/// API: /api/manutencoes
/// Provider: ManutencaoPreventivaProvider
class ManutencaoPreventivalisaScreen extends StatefulWidget {
  const ManutencaoPreventivalisaScreen({super.key});

  @override
  State<ManutencaoPreventivalisaScreen> createState() => _ManutencaoPreventivalisaScreenState();
}

class _ManutencaoPreventivalisaScreenState extends State<ManutencaoPreventivalisaScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _filterController;

  String _filtroStatus = 'todos';
  String _filtroTipo = 'todos'; // 'todos' | 'gerais' | 'eventuais'
  String _searchQuery = '';
  bool _showFilters = false;
  final _searchController = TextEditingController();

  // Cache: evita recomputar filtro/sort a cada rebuild cosmético
  List<ManutencaoPreventivaDto> _cachedFiltered = [];
  List<ManutencaoPreventivaDto> _lastSourceList = [];
  String _lastFiltroStatus = '';
  String _lastFiltroTipo = '';
  String _lastSearchQuery = '';

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  String _normalizeFreq(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
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
  }

  bool _isPontualOuUnica(ManutencaoPreventivaDto m) {
    final freq = _normalizeFreq(m.frequencia);
    return freq.isEmpty || freq == 'pontual' || freq == 'unica' || freq == 'unico';
  }

  bool _isRecorrente(ManutencaoPreventivaDto m) => !_isPontualOuUnica(m);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _filterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ManutencaoPreventivaProvider>().carregarManutencoes();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _filterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ManutencaoPreventivaDto> _getFiltered(List<ManutencaoPreventivaDto> source) {
    if (identical(source, _lastSourceList) &&
        _lastFiltroStatus == _filtroStatus &&
        _lastFiltroTipo == _filtroTipo &&
        _lastSearchQuery == _searchQuery) {
      return _cachedFiltered;
    }
    _lastSourceList = source;
    _lastFiltroStatus = _filtroStatus;
    _lastFiltroTipo = _filtroTipo;
    _lastSearchQuery = _searchQuery;
    _cachedFiltered = _filtrarManutencoes(source);
    return _cachedFiltered;
  }

  List<ManutencaoPreventivaDto> _filtrarManutencoes(List<ManutencaoPreventivaDto> lista) {
    var resultado = lista;

    // Filtrar por tipo (recorrentes/gerais vs eventuais/pontuais)
    if (_filtroTipo == 'gerais') {
      resultado = resultado.where(_isRecorrente).toList();
    } else if (_filtroTipo == 'eventuais') {
      resultado = resultado.where(_isPontualOuUnica).toList();
    }

    // Filtrar por status
    if (_filtroStatus == 'vencidas') {
      resultado = resultado.where((m) => m.vencida).toList();
    } else if (_filtroStatus == 'alerta') {
      resultado = resultado.where((m) => m.alerta && !m.vencida).toList();
    } else if (_filtroStatus == 'proximas') {
      resultado = resultado.where((m) => m.diasFaltantes >= 0 && m.diasFaltantes <= 7 && !m.vencida && !m.alerta).toList();
    } else if (_filtroStatus == 'normais') {
      resultado = resultado.where((m) => !m.vencida && !m.alerta && m.diasFaltantes > 7).toList();
    }

    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      resultado = resultado
          .where(
            (m) =>
                m.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (m.descricao ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (m.responsavelNome ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (m.fornecedor ?? '').toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    resultado.sort((a, b) => a.proximaManutencao.compareTo(b.proximaManutencao));
    return resultado;
  }


  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManutencaoPreventivaProvider, LanguageProvider>(
      builder: (context, provider, languageProvider, _) {
        final baseFiltered = _getFiltered(provider.manutencoes);

        return Scaffold(
          backgroundColor: OwanyTheme.backgroundColor(context),
          appBar: StandardGlassAppBar(
            title: _tx('Manutenções Gerais', 'General Maintenance'),
            icon: Icons.handyman_rounded,
            showBackButton: false,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header section (search + filters + dashboard) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildTipoFilterRow(),
                      const SizedBox(height: 10),
                      _buildFiltersToggle(),
                      if (_showFilters) ...[const SizedBox(height: 12), _buildFilterChips()],
                      if (provider.manutencoes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDashboard(provider.manutencoes),
                      ],
                      // Banner de background refresh
                      if (provider.isLoadingLista && provider.hasData) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 13, height: 13,
                                child: CircularProgressIndicator(strokeWidth: 2, color: OwanyTheme.primaryOrange),
                              ),
                              const SizedBox(width: 8),
                              Text(_tx('Atualizando...', 'Updating...'),
                                  style: TextStyle(color: OwanyTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // ── Lista ──
                Expanded(
                  child: provider.isLoadingLista && !provider.hasData
                      ? Center(child: CircularProgressIndicator(color: OwanyTheme.primaryOrange))
                      : provider.erro != null && !provider.hasData
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(provider.erro!, style: TextStyle(color: OwanyTheme.error)),
                                ),
                              ),
                            )
                          : _buildTabList(baseFiltered, OwanyTheme.primaryOrange, Icons.handyman_rounded),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/manutencao-criar');
            },
            backgroundColor: OwanyTheme.primaryOrange,
            icon: Icon(Icons.add_rounded, color: OwanyTheme.white),
            label: Text(_tx('Nova Manutenção', 'New Maintenance'), style: TextStyle(color: OwanyTheme.white, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  Widget _buildTabList(List<ManutencaoPreventivaDto> items, Color tintColor, IconData sectionIcon) {
    if (items.isEmpty) return _buildEmptyState();

    // Separate items that have no frequency (null/empty) — they need different treatment
    final semFrequencia = items.where((m) => (m.frequencia ?? '').trim().isEmpty).toList();
    final restantes = items.where((m) => (m.frequencia ?? '').trim().isNotEmpty).toList();

    // Group by status (only for items that have a frequency)
    final vencidas = restantes.where((m) => m.vencida).toList();
    final emAlerta = restantes.where((m) => m.alerta && !m.vencida).toList();
    final proximas = restantes.where((m) => m.diasFaltantes >= 0 && m.diasFaltantes <= 7 && !m.vencida && !m.alerta).toList();
    final normais = restantes.where((m) => !m.vencida && !m.alerta && m.diasFaltantes > 7).toList();

    final groups = <Map<String, dynamic>>[];
    if (semFrequencia.isNotEmpty) groups.add({'label': 'Sem frequência', 'icon': Icons.not_listed_location, 'color': OwanyTheme.info, 'items': semFrequencia});
    if (vencidas.isNotEmpty) groups.add({'label': 'Vencidas', 'icon': Icons.warning_amber_rounded, 'color': OwanyTheme.error, 'items': vencidas});
    if (emAlerta.isNotEmpty) groups.add({'label': 'Em Alerta', 'icon': Icons.notification_important_rounded, 'color': OwanyTheme.warning, 'items': emAlerta});
    if (proximas.isNotEmpty) groups.add({'label': 'Próximas (7 dias)', 'icon': Icons.schedule_rounded, 'color': OwanyTheme.info, 'items': proximas});
    if (normais.isNotEmpty) groups.add({'label': 'Normais', 'icon': Icons.check_circle_outline_rounded, 'color': OwanyTheme.success, 'items': normais});

    return RefreshIndicator(
      color: OwanyTheme.primaryOrange,
      onRefresh: () => context.read<ManutencaoPreventivaProvider>().carregarManutencoes(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: groups.fold<int>(
          0,
          (sum, g) => sum + 1 + (g['items'] as List).length,
        ),
        itemBuilder: (context, index) {
          // Flattened index → group header or card
          int offset = 0;
          for (final group in groups) {
            final groupItems = group['items'] as List<ManutencaoPreventivaDto>;
            if (index == offset) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: _buildSectionHeader(
                  group['label'] as String,
                  groupItems.length,
                  group['icon'] as IconData,
                  group['color'] as Color,
                ),
              );
            }
            offset++;
            if (index < offset + groupItems.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildManutencaoCard(groupItems[index - offset], context,
                    statusColor: group['color'] as Color),
              );
            }
            offset += groupItems.length;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: OwanyTheme.textPrimary(context)),
        decoration: InputDecoration(
          hintText: _tx('Buscar manutenções...', 'Search maintenance...'),
          hintStyle: TextStyle(color: OwanyTheme.textMutedColor(context)),
          prefixIcon: Icon(Icons.search_rounded, color: OwanyTheme.textMutedColor(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFiltersToggle() {
    return GestureDetector(
      onTap: _toggleFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showFilters
                ? OwanyTheme.primaryOrange
                : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              color: _showFilters ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Filtros',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _showFilters ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
              ),
            ),
            Spacer(),
            Icon(
              _showFilters ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: _showFilters ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoFilterRow() {
    return Row(
      children: [
        _buildTipoChip(_tx('Todos', 'All'), 'todos', Icons.list_rounded),
        const SizedBox(width: 8),
        _buildTipoChip(_tx('Gerais', 'Recurring'), 'gerais', Icons.repeat_rounded),
        const SizedBox(width: 8),
        _buildTipoChip(_tx('Eventuais', 'One-time'), 'eventuais', Icons.flash_on_rounded),
      ],
    );
  }

  Widget _buildFilterChips() {
    // Status filter only — tipo filter is always visible above
    return Row(
      children: [
        Text('${_tx('Status', 'Status')}: ', style: TextStyle(fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context))),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Todos', 'todos'),
              _buildFilterChip('Vencidas', 'vencidas'),
              _buildFilterChip('Em Alerta', 'alerta'),
              _buildFilterChip('Pr\u00f3ximas', 'proximas'),
              _buildFilterChip('Normais', 'normais'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipoChip(String label, String value, IconData icon) {
    final isSelected = _filtroTipo == value;
    return FilterChip(
      avatar: Icon(icon, size: 14, color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context)),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filtroTipo = value;
        });
      },
      backgroundColor: OwanyTheme.cardColor(context),
      selectedColor: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
      checkmarkColor: OwanyTheme.primaryOrange,
      labelStyle: TextStyle(
        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        width: isSelected ? 1.5 : 1.0,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroStatus = selected ? value : 'todos';
        });
      },
      backgroundColor: OwanyTheme.cardColor(context),
      selectedColor: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
      checkmarkColor: OwanyTheme.primaryOrange,
      labelStyle: TextStyle(
        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildDashboard(List<ManutencaoPreventivaDto> manutencoes) {
    final vencidas = manutencoes.where((m) => m.vencida).length;
    final emAlerta = manutencoes.where((m) => m.alerta && !m.vencida).length;
    final proximas = manutencoes.where((m) => m.diasFaltantes >= 0 && m.diasFaltantes <= 7 && !m.vencida && !m.alerta).length;
    final normais = manutencoes.where((m) => !m.vencida && !m.alerta && m.diasFaltantes > 7).length;

    return Row(
      children: [
        Expanded(child: _buildDashboardCard('Vencidas', vencidas.toString(), OwanyTheme.error)),
        const SizedBox(width: 8),
        Expanded(child: _buildDashboardCard('Em Alerta', emAlerta.toString(), OwanyTheme.warning)),
        const SizedBox(width: 8),
        Expanded(child: _buildDashboardCard('Próximas', proximas.toString(), OwanyTheme.info)),
        const SizedBox(width: 8),
        Expanded(child: _buildDashboardCard('Normais', normais.toString(), OwanyTheme.success)),
      ],
    );
  }

  Widget _buildDashboardCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.handyman_rounded,
            size: 64,
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Nenhuma manutenção encontrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: OwanyTheme.textMutedColor(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Adicione uma nova manutenção ou ajuste os filtros',
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, [Color? color]) {
    final headerColor = color ?? OwanyTheme.primaryOrange;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: headerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: headerColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: OwanyTheme.textPrimary(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: headerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: headerColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManutencaoCard(ManutencaoPreventivaDto manutencao, BuildContext context, {required Color statusColor}) {
    final statusIcon = manutencao.vencida
        ? Icons.warning_amber_rounded
        : manutencao.alerta
            ? Icons.notification_important_rounded
            : manutencao.diasFaltantes <= 7
                ? Icons.schedule_rounded
                : Icons.check_circle_outline_rounded;

    final statusLabel = manutencao.vencida
        ? 'Vencida'
        : manutencao.alerta
            ? 'Em Alerta'
            : 'Dias: ${manutencao.diasFaltantes}';

    final String _freqValue = manutencao.frequencia;
    final bool _isNullFreq = _freqValue == null;
    final bool _freqNotEmpty = (_freqValue ?? '').isNotEmpty;
    final String _freqLower = (_freqValue ?? '').toLowerCase();
    final frequenciaColor = (_freqNotEmpty && _freqLower != 'pontual') ? OwanyTheme.primaryOrange : OwanyTheme.info;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/manutencao-detalhes', arguments: manutencao.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: OwanyTheme.borderColor(context).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          manutencao.titulo,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: OwanyTheme.textPrimary(
                                                context),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                              alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: statusColor.withValues(
                                                alpha: 0.45),
                                          ),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (manutencao.descricao != null &&
                                      manutencao.descricao!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      manutencao.descricao!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            OwanyTheme.textMutedColor(context),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: frequenciaColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _freqNotEmpty && _freqLower != 'pontual' ? Icons.repeat_rounded : Icons.wb_sunny_rounded,
                                    color: frequenciaColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isNullFreq ? 'Sem frequência' : ((_freqValue ?? '').isEmpty ? 'Pontual' : _freqValue),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: frequenciaColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: OwanyTheme.textMutedColor(context)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: OwanyTheme.textMutedColor(context),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatarData(manutencao.proximaManutencao),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          OwanyTheme.textMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (manutencao.responsavelNome != null &&
                            manutencao.responsavelNome!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: OwanyTheme.textMutedColor(context),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Responsável: ${manutencao.responsavelNome}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: OwanyTheme.textMutedColor(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((manutencao.custoEstimado ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                color: OwanyTheme.textMutedColor(context),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Custo estimado: MZN ${manutencao.custoEstimado?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (manutencao.totalExecucoes > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: OwanyTheme.textMutedColor(context),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Execuções: ${manutencao.totalExecucoes}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}


