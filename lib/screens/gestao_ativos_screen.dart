// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../generated_l10n/app_localizations.dart';
import '../dto/item_apartamento_dto.dart';
import '../dto/item_estado_enums.dart';
import '../models/enums.dart';
import '../providers/itens_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/owany_theme.dart';
import '../utils/patrimonio_deep_link.dart';
import '../widgets/qr_code_widget.dart';
import 'detalhe_ativo_screen.dart';

// =============================================================
// GESTÃO DE ATIVOS SCREEN — PREMIUM PRO VERSION 2.0
// Features: Glassmorphism, Staggered Animations, Advanced Stats
// Mirroring ApartmentsScreen visual language
// =============================================================

String _tx(BuildContext context, String pt, String en) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code.startsWith('en') ? en : pt;
}

class GestaoAtivosScreen extends StatefulWidget {
  const GestaoAtivosScreen({super.key});

  @override
  State<GestaoAtivosScreen> createState() => _GestaoAtivosScreenState();
}

class _GestaoAtivosScreenState extends State<GestaoAtivosScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _headerAnimController;
  late AnimationController _statsAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  String _searchQuery = '';
  int? _filtroStatus;
  bool _loadingQrScan = false;
  bool _showExtendedStats = false;
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _statsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      _carregarDados();
      _headerAnimController.forward();
      _statsAnimController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    _headerAnimController.dispose();
    _statsAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ItensProvider>().carregarMais();
    }
  }

  Future<void> _carregarDados() async {
    final provider = context.read<ItensProvider>();
    await Future.wait([
      provider.carregarItens(reset: true),
      provider.carregarEstatisticas(),
    ]);
  }

  void _aplicarFiltros() {
    context.read<ItensProvider>().carregarItens(
          statusOperacional: _filtroStatus,
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          reset: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollOffset,
          builder: (_, value, __) => _GlassAppBar(
            scrollOffset: value,
            onAdd: _showCadastrarItem,
            onScan: _loadingQrScan ? null : _scanQrCode,
            onRefresh: _carregarDados,
            loadingQr: _loadingQrScan,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final userTipo = auth.usuarioAtual?.tipo;
          final canManageAssets = userTipo != UsuarioTipo.Morador &&
              userTipo != UsuarioTipo.Visitante;

          if (!canManageAssets) {
            return _buildAccessDenied(context, l10n);
          }

          return Consumer<ItensProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.itens.isEmpty) {
                return _PremiumSkeletonLoader();
              }

              if (provider.erro != null && provider.itens.isEmpty) {
                return _ErrorState(
                  message: provider.erro!,
                  onRetry: _carregarDados,
                );
              }

              final itens = provider.itens;
              final stats = provider.estatisticas;

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await _carregarDados();
                },
                color: OwanyTheme.primaryOrange,
                backgroundColor: OwanyTheme.cardColor(context),
                strokeWidth: 3,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // Space for glass app bar
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),

                    // ── Premium Dashboard ──
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: SlideTransition(
                          position: _headerSlideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: _PremiumDashboard(
                              stats: stats,
                              totalItens: provider.totalItens,
                              showExtended: _showExtendedStats,
                              onToggleExtended: () {
                                setState(() =>
                                    _showExtendedStats = !_showExtendedStats);
                                HapticFeedback.lightImpact();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Search Bar ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _PremiumSearchBar(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v.trim()),
                          onSubmitted: (_) => _aplicarFiltros(),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _aplicarFiltros();
                          },
                          onScanTap: _scanQrCode,
                          hasActiveFilters: _filtroStatus != null,
                          onFilterTap: () => _showFilterModal(context, stats),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── Filter Chips ──
                    SliverToBoxAdapter(
                      child: _FilterChipsRow(
                        stats: stats,
                        totalItens: provider.totalItens,
                        filtroStatus: _filtroStatus,
                        onSelect: (val) {
                          setState(() => _filtroStatus = val);
                          HapticFeedback.selectionClick();
                          _aplicarFiltros();
                        },
                      ),
                    ),

                    // ── Active Filters Banner ──
                    if (_searchQuery.isNotEmpty || _filtroStatus != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _ActiveFiltersBanner(
                            searchQuery: _searchQuery,
                            filtroStatus: _filtroStatus,
                            onClear: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filtroStatus = null;
                              });
                              context.read<ItensProvider>().limparFiltros();
                            },
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // ── Counter Row ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: Row(
                          children: [
                            Text(
                              '${itens.length} ${itens.length == 1 ? _tx(context, 'item', 'item') : _tx(context, 'itens', 'items')}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: OwanyTheme.textMutedColor(context),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            if (_searchQuery.isNotEmpty || _filtroStatus != null)
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filtroStatus = null;
                                  });
                                  context.read<ItensProvider>().limparFiltros();
                                  HapticFeedback.mediumImpact();
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(_tx(context, 'Limpar tudo', 'Clear all')),
                                style: TextButton.styleFrom(
                                    foregroundColor: OwanyTheme.primaryOrange),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Items List ──
                    if (itens.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(
                            context, provider.totalItens == 0, l10n),
                      )
                    else
                      _buildAnimatedList(itens, provider, l10n),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFabIfAllowed(context),
    );
  }

  Widget _buildAnimatedList(
      List<ItemSearchResultDto> itens, ItensProvider provider, AppLocalizations l10n) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= itens.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = itens[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + (index * 40)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final clamped = value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: clamped, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PremiumItemCard(
                  item: item,
                  onTap: () => _abrirDetalhes(item),
                  onQrTap: () => _showQrDialog(item, l10n),
                ),
              ),
            );
          },
          childCount: itens.length + (provider.hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool semDados, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              semDados
                  ? l10n.assets_no_items_loaded
                  : l10n.assets_no_match_filter,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              semDados
                  ? _tx(context, 'Nenhum ativo cadastrado ainda.', 'No assets registered yet.')
                  : _tx(context, 'Tente ajustar os filtros de busca.', 'Try adjusting the search filters.'),
              style: TextStyle(
                fontSize: 14,
                color: OwanyTheme.textMutedColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _filtroStatus != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _filtroStatus = null;
                  });
                  context.read<ItensProvider>().limparFiltros();
                },
                icon: const Icon(Icons.clear_all_rounded,
                    color: OwanyTheme.white),
                label: Text(_tx(context, 'Limpar filtros', 'Clear filters'),
                    style: TextStyle(
                        color: OwanyTheme.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwanyTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 64, color: OwanyTheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              _tx(context, 'Acesso Restrito', 'Restricted Access'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tx(
                context,
                'Apenas administradores, síndicos e funcionários podem gerenciar ativos.',
                'Only administrators, managers, and staff can manage assets.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: OwanyTheme.textMutedColor(context),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: OwanyTheme.white),
              label: Text(_tx(context, 'Voltar', 'Back'),
                  style: TextStyle(
                      color: OwanyTheme.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, AtivosEstatisticas? stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterModal(
        filtroAtual: _filtroStatus,
        stats: stats,
        onApply: (status) {
          setState(() => _filtroStatus = status);
          _aplicarFiltros();
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  Widget? _buildFabIfAllowed(BuildContext context) {
    final userTipo = context.watch<AuthProvider>().usuarioAtual?.tipo;
    if (userTipo == UsuarioTipo.Administrador ||
        userTipo == UsuarioTipo.Sindico ||
        userTipo == UsuarioTipo.Funcionario) {
      return FloatingActionButton(
        heroTag: 'ativos_fab',
        onPressed: _showCadastrarItem,
        backgroundColor: OwanyTheme.primaryOrange,
        child: const Icon(Icons.add_rounded, color: OwanyTheme.white),
      );
    }
    return null;
  }

  Future<void> _scanQrCode() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loadingQrScan = true);
    try {
      final scanned = await Navigator.pushNamed(context, '/qr-scan');
      if (scanned is! String || scanned.trim().isEmpty) return;

      final codigo = PatrimonioDeepLink.extractCodigo(
        scanned,
        allowStandaloneCode: true,
      );
      if (codigo == null || codigo.trim().isEmpty) return;

      final provider = context.read<ItensProvider>();
      await provider.buscarPorCodigo(codigo.trim());

      if (!mounted) return;

      if (provider.itemAtual != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  DetalheAtivoScreen(itemId: provider.itemAtual!.id)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_tx(context, 'Item não encontrado', 'Item not found')}: $codigo',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.assets_consult_fail}: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingQrScan = false);
    }
  }

  void _abrirDetalhes(ItemSearchResultDto item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalheAtivoScreen(itemId: item.id)),
    );
  }

  void _showQrDialog(ItemSearchResultDto item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: OwanyTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.assets_qr_patrimony,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QRCodeWidget(
                      data: item.codigoPatrimonio,
                      size: 120,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: OwanyTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.codigoPatrimonio,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.primaryBrown,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.nome,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: OwanyTheme.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (item.localizacaoFormatada.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: OwanyTheme.textMutedColor(context)),
                    const SizedBox(width: 4),
                    Text(
                      item.localizacaoFormatada,
                      style: TextStyle(
                          fontSize: 12,
                          color: OwanyTheme.textMutedColor(context)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCadastrarItem() {
    final nomeCtrl = TextEditingController();
    final tipoCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBottomState) {
          return Container(
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OwanyTheme.textMutedColor(context)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(Icons.add_box_rounded,
                                  color: OwanyTheme.primaryOrange),
                              const SizedBox(width: 12),
                              Text(
                                'Cadastrar Novo Item',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: OwanyTheme.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: nomeCtrl,
                            decoration: OwanyTheme.adaptiveInputDecoration(
                              context,
                              label: 'Nome do Item *',
                              hint: 'Ex: Cadeira de Escritório',
                              icon: Icons.inventory_2_rounded,
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: tipoCtrl,
                            decoration: OwanyTheme.adaptiveInputDecoration(
                              context,
                              label: 'Tipo *',
                              hint: 'Ex: Móvel, Eletrônico',
                              icon: Icons.category_rounded,
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descricaoCtrl,
                            decoration: OwanyTheme.adaptiveInputDecoration(
                              context,
                              label: 'Descrição',
                              hint: 'Detalhes adicionais do item',
                              icon: Icons.description_rounded,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: salvando
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    side: BorderSide(
                                        color: OwanyTheme.textMutedColor(
                                                context)
                                            .withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: salvando
                                      ? null
                                      : () async {
                                          if (nomeCtrl.text.trim().isEmpty ||
                                              tipoCtrl.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(OwanyTheme.snackBar(
                                              'Nome e Tipo são obrigatórios',
                                              type: SnackBarType.warning,
                                            ));
                                            return;
                                          }
                                          setBottomState(
                                              () => salvando = true);
                                          final provider =
                                              ctx.read<ItensProvider>();
                                          final item =
                                              await provider.criarItem(
                                            nome: nomeCtrl.text.trim(),
                                            tipo: tipoCtrl.text.trim(),
                                            descricao: descricaoCtrl.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? descricaoCtrl.text.trim()
                                                : null,
                                          );
                                          if (!ctx.mounted) return;
                                          Navigator.pop(ctx);
                                          if (item != null) {
                                            ScaffoldMessenger.of(this.context)
                                                .showSnackBar(
                                                    OwanyTheme.snackBar(
                                              'Item cadastrado com sucesso!',
                                              type: SnackBarType.success,
                                            ));
                                            _carregarDados();
                                          } else {
                                            ScaffoldMessenger.of(this.context)
                                                .showSnackBar(
                                                    OwanyTheme.snackBar(
                                              provider.erro ??
                                                  'Erro ao cadastrar item',
                                              type: SnackBarType.error,
                                            ));
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: OwanyTheme.primaryOrange,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: salvando
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    OwanyTheme.white),
                                          ),
                                        )
                                      : const Text(
                                          'Cadastrar',
                                          style: TextStyle(
                                            color: OwanyTheme.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// GLASS MORPHISM APP BAR
// =============================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final VoidCallback onAdd;
  final VoidCallback? onScan;
  final VoidCallback onRefresh;
  final bool loadingQr;

  const _GlassAppBar({
    required this.scrollOffset,
    required this.onAdd,
    required this.onScan,
    required this.onRefresh,
    required this.loadingQr,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.primaryOrange
                    .withValues(alpha: 0.8 + (opacity * 0.2)),
                OwanyTheme.accent.withValues(alpha: 0.7 + (opacity * 0.3)),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color:
                    OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gestão de Ativos',
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Controlo patrimonial completo',
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context)
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  _GlassIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: onScan,
                    loading: loadingQr,
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: onRefresh,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final BuildContext context;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.context,
    this.loading = false,
  });

  @override
  Widget build(BuildContext ctx) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        OwanyTheme.adaptiveTextOverlay(context)),
                  ),
                )
              : Icon(
                  icon,
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  size: 20,
                ),
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM DASHBOARD WITH EXTENDED STATS
// =============================================================

class _PremiumDashboard extends StatelessWidget {
  final AtivosEstatisticas? stats;
  final int totalItens;
  final bool showExtended;
  final VoidCallback onToggleExtended;

  const _PremiumDashboard({
    required this.stats,
    required this.totalItens,
    required this.showExtended,
    required this.onToggleExtended,
  });

  int get total => stats?.total ?? totalItens;
  int get emStock => stats?.emStock ?? 0;
  int get emUso => stats?.emUso ?? 0;
  int get danificados => stats?.danificados ?? 0;
  int get emManutencao => stats?.emManutencao ?? 0;

  double _pct(int v) => total == 0 ? 0 : v / total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.1),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                // ── Main Stats Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AnimatedCircularStat(
                      label: 'Em Stock',
                      value: emStock,
                      percent: _pct(emStock),
                      color: StatusOperacionalItem.emStock.cor,
                      delay: 0,
                    ),
                    _AnimatedCircularStat(
                      label: 'Em Uso',
                      value: emUso,
                      percent: _pct(emUso),
                      color: StatusOperacionalItem.emUso.cor,
                      delay: 100,
                    ),
                    _AnimatedCircularStat(
                      label: 'Danificados',
                      value: danificados,
                      percent: _pct(danificados),
                      color: StatusOperacionalItem.danificado.cor,
                      delay: 200,
                    ),
                  ],
                ),

                if (showExtended) ...[
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Extended Stats
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.inventory_2_rounded,
                          label: 'Total de Itens',
                          value: total.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.build_rounded,
                          label: 'Em Manutenção',
                          value: emManutencao.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TaxaUsoBar(
                    percent: total == 0 ? 0.0 : (emUso / total) * 100,
                  ),
                ],

                const SizedBox(height: 16),

                // ── Toggle Button ──
                InkWell(
                  onTap: onToggleExtended,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showExtended ? 'Ver menos' : 'Ver mais estatísticas',
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          showExtended
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 18,
                        ),
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
}

class _AnimatedCircularStat extends StatefulWidget {
  final String label;
  final int value;
  final double percent;
  final Color color;
  final int delay;

  const _AnimatedCircularStat({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.delay,
  });

  @override
  State<_AnimatedCircularStat> createState() => _AnimatedCircularStatState();
}

class _AnimatedCircularStatState extends State<_AnimatedCircularStat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CirclePainter(
                  percent: widget.percent * _animation.value,
                  color: widget.color,
                ),
                child: Center(
                  child: Text(
                    '${(widget.percent * 100 * _animation.value).round()}%',
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.value}',
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context)
                .withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percent;
  final Color color;

  _CirclePainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final bg = Paint()
      ..color = OwanyTheme.primaryBrown.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context)
                  .withValues(alpha: 0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaxaUsoBar extends StatelessWidget {
  final double percent;

  const _TaxaUsoBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxa de Utilização',
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: percent / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: OwanyTheme.textPrimary(context)
                      .withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    OwanyTheme.textPrimary(context),
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM SEARCH BAR
// =============================================================

class _PremiumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onScanTap;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  const _PremiumSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onScanTap,
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                OwanyTheme.textMutedColor(context).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: _tx(context, 'Buscar por nome, código ou tipo...', 'Search by name, code, or type...'),
                hintStyle: TextStyle(
                  color: OwanyTheme.textMutedColor(context)
                      .withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: 24,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: OwanyTheme.textMutedColor(context),
                            size: 18),
                        onPressed: onClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
              ),
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // QR scan button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onScanTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filter button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasActiveFilters
                      ? OwanyTheme.primaryOrange
                      : OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilters
                      ? OwanyTheme.adaptiveTextOverlay(context)
                      : OwanyTheme.primaryOrange,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// =============================================================
// FILTER CHIPS ROW
// =============================================================

class _FilterChipsRow extends StatelessWidget {
  final AtivosEstatisticas? stats;
  final int totalItens;
  final int? filtroStatus;
  final ValueChanged<int?> onSelect;

  const _FilterChipsRow({
    required this.stats,
    required this.totalItens,
    required this.filtroStatus,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        children: [
          _PremiumFilterChip(
            label: 'Todos',
            count: stats?.total ?? totalItens,
            selected: filtroStatus == null,
            onTap: () => onSelect(null),
          ),
          _PremiumFilterChip(
            label: 'Em Stock',
            count: stats?.emStock ?? 0,
            color: StatusOperacionalItem.emStock.cor,
            selected:
                filtroStatus == StatusOperacionalItem.emStock.valor,
            onTap: () =>
                onSelect(StatusOperacionalItem.emStock.valor),
          ),
          _PremiumFilterChip(
            label: 'Em Uso',
            count: stats?.emUso ?? 0,
            color: StatusOperacionalItem.emUso.cor,
            selected: filtroStatus == StatusOperacionalItem.emUso.valor,
            onTap: () => onSelect(StatusOperacionalItem.emUso.valor),
          ),
          _PremiumFilterChip(
            label: 'Danificados',
            count: stats?.danificados ?? 0,
            color: StatusOperacionalItem.danificado.cor,
            selected:
                filtroStatus == StatusOperacionalItem.danificado.valor,
            onTap: () =>
                onSelect(StatusOperacionalItem.danificado.valor),
          ),
          _PremiumFilterChip(
            label: 'Manutenção',
            count: stats?.emManutencao ?? 0,
            color: StatusOperacionalItem.emManutencao.cor,
            selected: filtroStatus ==
                StatusOperacionalItem.emManutencao.valor,
            onTap: () =>
                onSelect(StatusOperacionalItem.emManutencao.valor),
          ),
        ],
      ),
    );
  }
}

class _PremiumFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _PremiumFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OwanyTheme.primaryOrange;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [chipColor, chipColor.withValues(alpha: 0.8)],
                    )
                  : null,
              color: selected
                  ? null
                  : OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? chipColor
                    : OwanyTheme.textMutedColor(context)
                        .withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: chipColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? OwanyTheme.white
                        : OwanyTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : chipColor,
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
}

// =============================================================
// ACTIVE FILTERS BANNER
// =============================================================

class _ActiveFiltersBanner extends StatelessWidget {
  final String searchQuery;
  final int? filtroStatus;
  final VoidCallback onClear;

  const _ActiveFiltersBanner({
    required this.searchQuery,
    required this.filtroStatus,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filtros = <String>[];
    if (searchQuery.isNotEmpty) filtros.add('Texto: "$searchQuery"');
    if (filtroStatus != null) {
      final status = StatusOperacionalItem.values
          .firstWhere((item) => item.valor == filtroStatus);
      filtros.add('Status: ${status.toPortuguese()}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...filtros.map((f) => _FilterChipActive(label: f, onRemove: onClear)),
        ],
      ),
    );
  }
}

class _FilterChipActive extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipActive({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: OwanyTheme.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: OwanyTheme.white),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PREMIUM ITEM CARD
// =============================================================

class _PremiumItemCard extends StatefulWidget {
  final ItemSearchResultDto item;
  final VoidCallback onTap;
  final VoidCallback onQrTap;

  const _PremiumItemCard({
    required this.item,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  State<_PremiumItemCard> createState() => _PremiumItemCardState();
}

class _PremiumItemCardState extends State<_PremiumItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.item.statusOperacionalEnum.cor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? statusColor.withValues(alpha: 0.5)
                    : OwanyTheme.textMutedColor(context)
                        .withValues(alpha: 0.2),
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? statusColor.withValues(alpha: 0.2)
                      : OwanyTheme.textMutedColor(context)
                          .withValues(alpha: 0.04),
                  blurRadius: _isHovered ? 20 : 8,
                  offset: Offset(0, _isHovered ? 8 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Left status stripe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            statusColor,
                            statusColor.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  // Background watermark
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.04,
                      child: Icon(
                        getIconeTipoItem(widget.item.tipo),
                        size: 100,
                        color: statusColor,
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),

                        // Type icon circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor,
                                statusColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            getIconeTipoItem(widget.item.tipo),
                            color: OwanyTheme.white,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Main info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.nome,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: OwanyTheme.textPrimary(context),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.item.statusOperacionalEnum
                                          .toPortuguese(),
                                      style: const TextStyle(
                                        color: OwanyTheme.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  if (widget.item.tipo.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: OwanyTheme.primaryOrange
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.item.tipo,
                                        style: const TextStyle(
                                          color: OwanyTheme.primaryOrange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Code badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: OwanyTheme.surfaceColor(context),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.item.codigoPatrimonio,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: OwanyTheme.textMutedColor(
                                            context),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (widget.item.localizacaoFormatada
                                      .isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.location_on_outlined,
                                        size: 11,
                                        color: OwanyTheme.textMutedColor(
                                            context)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        widget.item.localizacaoFormatada,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: OwanyTheme.textMutedColor(
                                              context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (widget.item.possuiManutencaoAtiva) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: OwanyTheme.warning
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.construction_rounded,
                                              size: 11,
                                              color: OwanyTheme.warning),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Em manutenção',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: OwanyTheme.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // QR + arrow
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: widget.onQrTap,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: OwanyTheme.primaryOrange
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: OwanyTheme.primaryOrange
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.qr_code_rounded,
                                  size: 18,
                                  color: OwanyTheme.primaryOrange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: OwanyTheme.textMutedColor(context),
                            ),
                          ],
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
    );
  }
}

// =============================================================
// ADVANCED FILTER MODAL
// =============================================================

class _AdvancedFilterModal extends StatefulWidget {
  final int? filtroAtual;
  final AtivosEstatisticas? stats;
  final Function(int? status) onApply;

  const _AdvancedFilterModal({
    required this.filtroAtual,
    required this.stats,
    required this.onApply,
  });

  @override
  State<_AdvancedFilterModal> createState() => _AdvancedFilterModalState();
}

class _AdvancedFilterModalState extends State<_AdvancedFilterModal> {
  late int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.filtroAtual;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: OwanyTheme.textMutedColor(context)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          color: OwanyTheme.primaryOrange),
                      const SizedBox(width: 12),
                      Text(
                        'Filtros Avançados',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Status Operacional',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterOptionChip(
                        label: 'Todos',
                        isSelected: _selectedStatus == null,
                        onTap: () {
                          setState(() => _selectedStatus = null);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: 'Em Stock',
                        icon: Icons.inventory_2_outlined,
                        color: StatusOperacionalItem.emStock.cor,
                        isSelected: _selectedStatus ==
                            StatusOperacionalItem.emStock.valor,
                        onTap: () {
                          setState(() => _selectedStatus =
                              StatusOperacionalItem.emStock.valor);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: 'Em Uso',
                        icon: Icons.check_circle_outline,
                        color: StatusOperacionalItem.emUso.cor,
                        isSelected: _selectedStatus ==
                            StatusOperacionalItem.emUso.valor,
                        onTap: () {
                          setState(() => _selectedStatus =
                              StatusOperacionalItem.emUso.valor);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: 'Danificado',
                        icon: Icons.warning_amber_rounded,
                        color: StatusOperacionalItem.danificado.cor,
                        isSelected: _selectedStatus ==
                            StatusOperacionalItem.danificado.valor,
                        onTap: () {
                          setState(() => _selectedStatus =
                              StatusOperacionalItem.danificado.valor);
                          HapticFeedback.selectionClick();
                        },
                      ),
                      _FilterOptionChip(
                        label: 'Manutenção',
                        icon: Icons.build,
                        color: StatusOperacionalItem.emManutencao.cor,
                        isSelected: _selectedStatus ==
                            StatusOperacionalItem.emManutencao.valor,
                        onTap: () {
                          setState(() => _selectedStatus =
                              StatusOperacionalItem.emManutencao.valor);
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _selectedStatus = null);
                            HapticFeedback.lightImpact();
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: OwanyTheme.textMutedColor(context)
                                  .withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_tx(context, 'Limpar', 'Clear'),
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(_selectedStatus);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OwanyTheme.primaryOrange,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            _tx(context, 'Aplicar Filtros', 'Apply Filters'),
                            style: TextStyle(
                              color: OwanyTheme.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? OwanyTheme.primaryOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [chipColor, chipColor.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected
                ? null
                : OwanyTheme.textMutedColor(context)
                    .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : OwanyTheme.textMutedColor(context)
                      .withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 18,
                    color:
                        isSelected ? OwanyTheme.white : chipColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? OwanyTheme.white
                      : OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// PREMIUM SKELETON LOADER
// =============================================================

class _PremiumSkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 140),

          // Dashboard skeleton
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          const SizedBox(height: 20),

          // Search skeleton
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 20),

          // List skeletons
          ...List.generate(
            5,
            (index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 80)),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 92,
                decoration: BoxDecoration(
                  color: OwanyTheme.textMutedColor(context)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ERROR STATE
// =============================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: OwanyTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar ativos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: OwanyTheme.textMutedColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: OwanyTheme.white),
              label: Text(_tx(context, 'Tentar novamente', 'Try again'),
                  style: TextStyle(
                      color: OwanyTheme.white,
                      fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
