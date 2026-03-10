// ignore_for_file: deprecated_member_use
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../generated_l10n/app_localizations.dart';
import '../dto/item_apartamento_dto.dart';
import '../dto/item_estado_enums.dart';
import '../dto/item_apartamento_movimentacao_dtos.dart';
import '../dto/solicitacoes_v2_dtos.dart';
import '../models/enums.dart';
import '../providers/itens_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/apartamentos_provider.dart';
import '../providers/solicitacoes_provider.dart';
import '../providers/item_movimentacao_provider.dart';
import '../dto/item_movimentacao_dto.dart';
import '../theme/owany_theme.dart';
import '../widgets/qr_code_widget.dart';
import 'editar_ativo_screen.dart';
import 'historico_ativo_screen.dart';

// =============================================================
// DETALHE ATIVO SCREEN — PREMIUM PRO VERSION 2.0
// Features: Glassmorphism Header, Staggered Animations,
//           Gradient Badges, Premium Cards — mirrors ApartmentsScreen
// =============================================================

String _tx(BuildContext context, String pt, String en) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code.startsWith('en') ? en : pt;
}

class DetalheAtivoScreen extends StatefulWidget {
  final String? itemId;
  final String? codigoPatrimonio;

  const DetalheAtivoScreen({super.key, this.itemId, this.codigoPatrimonio})
      : assert(itemId != null || codigoPatrimonio != null,
            'Deve fornecer itemId ou codigoPatrimonio');

  @override
  State<DetalheAtivoScreen> createState() => _DetalheAtivoScreenState();
}

class _DetalheAtivoScreenState extends State<DetalheAtivoScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  ItemApartamentoDto? _item;
  HistoricoItemDto? _historico;
  bool _loadingHistorico = false;

  late AnimationController _masterController;
  late AnimationController _headerController;

  // Staggered animations — mirror ApartmentsScreen pattern
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;

  double _scrollOffset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
    _carregarDados();
  }

  void _initAnimations() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _statsFade = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _cardsFade = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = context.read<ItensProvider>();

      if (widget.itemId != null) {
        await provider.carregarItem(widget.itemId!);
      } else if (widget.codigoPatrimonio != null) {
        await provider.carregarItemPorCodigo(widget.codigoPatrimonio!);
      }

      _item = provider.itemAtual;

      if (_item == null) {
        setState(() {
          _error = 'Item não encontrado';
          _loading = false;
        });
        return;
      }

      setState(() => _loadingHistorico = true);

      // Carrega histórico e solicitações vinculadas em paralelo
      await Future.wait([
        provider.carregarHistorico(_item!.id),
        context.read<SolicitacoesProvider>().loadSolicitacoesPorItem(
          _item!.id,
          refresh: true,
        ),
      ]);
      _historico = provider.historicoAtual;

      setState(() {
        _loadingHistorico = false;
        _loading = false;
      });

      // Fire staggered animations
      _headerController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _masterController.forward();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _GlassAppBar(
          scrollOffset: _scrollOffset,
          item: _item,
          l10n: l10n,
          onRefresh: _carregarDados,
          onMenuSelected: _handleMenuAction,
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final userTipo = auth.usuarioAtual?.tipo;
          final canView = userTipo != UsuarioTipo.Morador &&
              userTipo != UsuarioTipo.Visitante;

          if (!canView) return _buildAccessDenied(context, l10n);

          if (_loading) return _PremiumSkeletonLoader();

          if (_error != null) {
            return _ErrorState(message: _error!, onRetry: _carregarDados);
          }

          return _buildBody(context, l10n);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final item = _item!;

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

          // ── Hero Header Card ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _PremiumHeaderCard(
                    item: item,
                    onQrTap: () => _showQRCodePreview(item, l10n),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Stats Row ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _statsFade,
              child: SlideTransition(
                position: _statsSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsRow(item, l10n),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Maintenance Alert ──
          if (item.possuiManutencaoAtiva)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _cardsFade,
                child: SlideTransition(
                  position: _cardsSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _MaintenanceAlert(item: item),
                  ),
                ),
              ),
            ),

          // ── Details Card ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsFade,
              child: SlideTransition(
                position: _cardsSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DetailsCard(item: item, l10n: l10n),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Histórico Card ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsFade,
              child: SlideTransition(
                position: _cardsSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HistoricoCard(
                    historico: _historico,
                    loadingHistorico: _loadingHistorico,
                    item: item,
                    l10n: l10n,
                    onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              HistoricoAtivoScreen(itemId: item.id)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Solicitações Card ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsFade,
              child: SlideTransition(
                position: _cardsSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SolicitacoesCard(
                    historico: _historico,
                    loadingHistorico: _loadingHistorico,
                    l10n: l10n,
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Actions Row ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardsFade,
              child: SlideTransition(
                position: _cardsSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ActionsRow(
                    item: item,
                    l10n: l10n,
                    onTransfer: () => _mostrarDialogTransferencia(item),
                    onStatus: () => _mostrarDialogAlterarEstado(item),
                    onMore: () => _showActionsBottomSheet(item, l10n),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ItemApartamentoDto item, AppLocalizations l10n) {
    final totalMovs = _historico?.totalMovimentacoes ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: l10n.assets_quantity,
            value: '${item.quantidade}',
            icon: Icons.inventory_2_outlined,
            delay: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: l10n.assets_estimated_value,
            value: _formatCurrency(item.valorEstimado),
            icon: Icons.monetization_on_outlined,
            delay: 100,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: l10n.assets_last_movement,
            value: totalMovs > 0 ? '$totalMovs mov.' : '-',
            icon: Icons.history_rounded,
            delay: 200,
          ),
        ),
      ],
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
              child:
                  const Icon(Icons.lock_outline_rounded, size: 64, color: OwanyTheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Acesso Restrito',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Apenas administradores, síndicos e funcionários podem visualizar detalhes de ativos.',
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
              icon: const Icon(Icons.arrow_back_rounded, color: OwanyTheme.white),
              label: Text(l10n.common_back,
                  style: const TextStyle(
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

  String _formatCurrency(double? value) {
    if (value == null) return '-';
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'editar':
        if (_item != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditarAtivoScreen(itemId: _item!.id)),
          ).then((updated) {
            if (updated == true) _carregarDados();
          });
        }
        break;
      case 'transferir':
        if (_item != null) _mostrarDialogTransferencia(_item!);
        break;
      case 'estado':
        if (_item != null) _mostrarDialogAlterarEstado(_item!);
        break;
    }
  }

  void _showQRCodePreview(ItemApartamentoDto item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: OwanyTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Código de Patrimônio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: OwanyTheme.textMutedColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Hero(
                tag: 'qr_${item.id}',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QRCodeWidget(data: item.codigoPatrimonio, size: 200),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
                ),
                child: Text(
                  item.codigoPatrimonio,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: OwanyTheme.primaryOrange,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: OwanyTheme.white),
                  label: Text(l10n.common_close,
                      style: const TextStyle(
                          color: OwanyTheme.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwanyTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogTransferencia(ItemApartamentoDto item) async {
    final l10n = AppLocalizations.of(context)!;
    final apartamentosProvider = context.read<ApartamentosProvider>();
    String? apartamentoDestinoId;
    String? apartamentoDestinoNome;
    final motivoController = TextEditingController();
    final observacoesController = TextEditingController();

    if (apartamentosProvider.apartamentos.isEmpty) {
      try {
        await apartamentosProvider.carregarApartamentos();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_tx(context, 'Erro ao carregar apartamentos', 'Failed to load apartments')}: $e',
            ),
          ),
        );
        return;
      }
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: OwanyTheme.cardColor(ctx),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: OwanyTheme.primaryOrange),
              const SizedBox(width: 10),
              Text(l10n.assets_transfer_asset,
                  style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tx(ctx, 'Apartamento Destino', 'Destination Apartment'),
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: OwanyTheme.textPrimary(ctx))),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: OwanyTheme.borderColor(ctx)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: apartamentosProvider.apartamentos.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(_tx(ctx, 'Nenhum apartamento disponível', 'No apartment available'),
                                  style: TextStyle(
                                      color:
                                          OwanyTheme.textMutedColor(ctx))),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                apartamentosProvider.apartamentos.length,
                            itemBuilder: (lbContext, index) {
                              final apt =
                                  apartamentosProvider.apartamentos[index];
                              final isSelected =
                                  apartamentoDestinoId == apt.id;
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    apartamentoDestinoId = apt.id;
                                    apartamentoDestinoNome =
                                        'Apt ${apt.numero}${apt.bloco.isNotEmpty ? ' - Bloco ${apt.bloco}' : ''}';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? OwanyTheme.primaryOrange
                                            .withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                          color: OwanyTheme.borderColor(
                                              context)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isSelected
                                              ? const LinearGradient(colors: [
                                                  OwanyTheme.primaryOrange,
                                                  OwanyTheme.accent,
                                                ])
                                              : null,
                                          border: isSelected
                                              ? null
                                              : Border.all(
                                                  color: OwanyTheme
                                                      .textMutedColor(context),
                                                  width: 2,
                                                ),
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                                size: 12, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('${_tx(context, 'Apt', 'Apt')} ${apt.numero}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            if (apt.bloco.isNotEmpty)
                                              Text(
                                                '${_tx(context, 'Bloco', 'Block')} ${apt.bloco}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        OwanyTheme.textMutedColor(
                                                            context)),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (apartamentoDestinoNome != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                          OwanyTheme.accent.withValues(alpha: 0.06),
                        ]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: OwanyTheme.primaryOrange
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: OwanyTheme.primaryOrange, size: 18),
                          const SizedBox(width: 8),
                          Text('${_tx(context, 'Destino', 'Destination')}: $apartamentoDestinoNome',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: OwanyTheme.primaryOrange,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: motivoController,
                    decoration: OwanyTheme.adaptiveInputDecoration(
                      context,
                      label: l10n.assets_field_reason,
                      hint: 'Motivo da transferência',
                      icon: Icons.notes_rounded,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: observacoesController,
                    decoration: OwanyTheme.adaptiveInputDecoration(
                      context,
                      label: l10n.assets_field_observations,
                      hint: 'Observações adicionais (opcional)',
                      icon: Icons.comment_outlined,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: apartamentoDestinoId == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.assets_menu_transfer,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmado == true && apartamentoDestinoId != null) {
      try {
        final provider = context.read<ItemMovimentacaoProvider>();
        final request = TransferirItemRequest(
          itemApartamentoId: item.id,
          apartamentoDestinoId: apartamentoDestinoId!,
          motivo: motivoController.text.trim().isNotEmpty ? motivoController.text.trim() : null,
          observacoes: observacoesController.text.trim().isNotEmpty ? observacoesController.text.trim() : null,
        );
        final success = await provider.transferir(request);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
            l10n.assets_transfer_completed,
            type: SnackBarType.success,
          ));
          _carregarDados();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
            provider.errorMessage ?? l10n.assets_transfer_failed,
            type: SnackBarType.error,
          ));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
          '${l10n.assets_transfer_failed}: $e',
          type: SnackBarType.error,
        ));
      }
    }

    motivoController.dispose();
    observacoesController.dispose();
  }

  Future<void> _mostrarDialogAlterarEstado(ItemApartamentoDto item) async {
    StatusOperacionalItem? novoStatus = item.statusOperacionalEnum;
    final motivoController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.change_circle_rounded,
                  color: OwanyTheme.primaryOrange),
              const SizedBox(width: 10),
              Text(_tx(context, 'Alterar Estado', 'Change Status')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tx(context, 'Novo Status Operacional', 'New Operational Status'),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                ...StatusOperacionalItem.values.map((status) {
                  final isSelected = novoStatus == status;
                  return GestureDetector(
                    onTap: () => setStateDialog(() => novoStatus = status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [
                                status.cor.withValues(alpha: 0.15),
                                status.cor.withValues(alpha: 0.05),
                              ])
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? status.cor
                              : OwanyTheme.borderColor(context),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: status.cor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Text(status.toPortuguese(),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? status.cor
                                    : OwanyTheme.textPrimary(context),
                              )),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: status.cor, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoController,
                  decoration: OwanyTheme.adaptiveInputDecoration(
                    context,
                    label: _tx(context, 'Motivo', 'Reason'),
                    hint: _tx(context, 'Descreva o motivo da alteração', 'Describe the reason for this change'),
                    icon: Icons.notes_rounded,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_tx(context, 'Cancelar', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (motivoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
                    _tx(context, 'O motivo é obrigatório', 'Reason is required'),
                    type: SnackBarType.warning,
                  ));
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_tx(context, 'Confirmar', 'Confirm'),
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmado == true && novoStatus != null) {
      try {
        final provider = context.read<ItensProvider>();
        await provider.alterarEstado(item.id, novoStatus!.valor, motivo: motivoController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
          _tx(context, 'Estado alterado com sucesso', 'Status updated successfully'),
          type: SnackBarType.success,
        ));
        _carregarDados();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(
          '${_tx(context, 'Falha ao alterar estado', 'Failed to change status')}: $e',
          type: SnackBarType.error,
        ));
      }
    }
    motivoController.dispose();
  }

  Future<void> _showActionsBottomSheet(
      ItemApartamentoDto item, AppLocalizations l10n) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: OwanyTheme.primaryOrange),
                        const SizedBox(width: 12),
                        Text(
                          'Ações Rápidas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: OwanyTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _BottomSheetActionTile(
                      icon: Icons.edit_rounded,
                      label: l10n.assets_menu_edit,
                      color: OwanyTheme.primaryOrange,
                      onTap: () {
                        Navigator.pop(context);
                        _handleMenuAction('editar');
                      },
                    ),
                    const SizedBox(height: 12),
                    _BottomSheetActionTile(
                      icon: Icons.swap_horiz_rounded,
                      label: l10n.assets_menu_transfer,
                      color: OwanyTheme.info,
                      onTap: () {
                        Navigator.pop(context);
                        _handleMenuAction('transferir');
                      },
                    ),
                    const SizedBox(height: 12),
                    _BottomSheetActionTile(
                      icon: Icons.change_circle_rounded,
                      label: l10n.assets_current_state,
                      color: OwanyTheme.warning,
                      onTap: () {
                        Navigator.pop(context);
                        _handleMenuAction('estado');
                      },
                    ),
                  ],
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
// GLASS MORPHISM APP BAR
// =============================================================

class _GlassAppBar extends StatelessWidget {
  final double scrollOffset;
  final ItemApartamentoDto? item;
  final AppLocalizations l10n;
  final VoidCallback onRefresh;
  final ValueChanged<String> onMenuSelected;

  const _GlassAppBar({
    required this.scrollOffset,
    required this.item,
    required this.l10n,
    required this.onRefresh,
    required this.onMenuSelected,
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
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
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
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwanyTheme.adaptiveOverlay(context,
                              opacity: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item != null
                              ? l10n.assets_asset_title(item!.codigoPatrimonio)
                              : l10n.assets_details,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.assets_management_title,
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

                  // Refresh
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRefresh,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwanyTheme.adaptiveOverlay(context,
                              opacity: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  if (item != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: onMenuSelected,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwanyTheme.adaptiveOverlay(context,
                              opacity: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'editar',
                          child: _PopupItem(
                              icon: Icons.edit_rounded,
                              label: l10n.assets_menu_edit),
                        ),
                        PopupMenuItem(
                          value: 'transferir',
                          child: _PopupItem(
                              icon: Icons.swap_horiz_rounded,
                              label: l10n.assets_menu_transfer),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'estado',
                          child: _PopupItem(
                              icon: Icons.change_circle_rounded,
                              label: l10n.assets_current_state),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PopupItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OwanyTheme.primaryOrange),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// =============================================================
// PREMIUM HEADER CARD (replaces simple title)
// =============================================================

class _PremiumHeaderCard extends StatelessWidget {
  final ItemApartamentoDto item;
  final VoidCallback onQrTap;

  const _PremiumHeaderCard({required this.item, required this.onQrTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.statusOperacionalEnum.cor;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.08),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.03),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        getIconeTipoItem(item.tipo),
                        size: 32,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name + badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nome,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: OwanyTheme.adaptiveTextOverlay(context),
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          if (item.descricao != null &&
                              item.descricao!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.descricao!,
                              style: TextStyle(
                                fontSize: 13,
                                color: OwanyTheme.adaptiveTextOverlay(context)
                                    .withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _GlassBadge(
                                label: item.statusOperacionalEnum.toPortuguese(),
                                dotColor: statusColor,
                                context: context,
                              ),
                              _GlassBadge(
                                label: item.estadoFisicoEnum.toPortuguese(),
                                dotColor: item.estadoFisicoEnum.cor,
                                context: context,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // QR Code
                    GestureDetector(
                      onTap: onQrTap,
                      child: Column(
                        children: [
                          Hero(
                            tag: 'qr_${item.id}',
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: QRCodeWidget(
                                  data: item.codigoPatrimonio, size: 70),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.codigoPatrimonio,
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                              color: OwanyTheme.adaptiveTextOverlay(context)
                                  .withValues(alpha: 0.65),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Location row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16,
                          color: OwanyTheme.adaptiveTextOverlay(context)
                              .withValues(alpha: 0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.localizacaoFormatada,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                OwanyTheme.adaptiveTextOverlay(context),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

class _GlassBadge extends StatelessWidget {
  final String label;
  final Color dotColor;
  final BuildContext context;

  const _GlassBadge({
    required this.label,
    required this.dotColor,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: OwanyTheme.adaptiveOverlay(context, opacity: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ANIMATED STAT CARD
// =============================================================

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final int delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.delay,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OwanyTheme.cardColor(context),
              OwanyTheme.primaryOrange.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OwanyTheme.primaryOrange,
                    OwanyTheme.accent,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child:
                  Icon(widget.icon, size: 16, color: OwanyTheme.white),
            ),
            const SizedBox(height: 10),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: OwanyTheme.textPrimary(context),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// MAINTENANCE ALERT
// =============================================================

class _MaintenanceAlert extends StatelessWidget {
  final ItemApartamentoDto item;

  const _MaintenanceAlert({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.warning.withValues(alpha: 0.14),
            OwanyTheme.warning.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: OwanyTheme.warning.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.warning.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: OwanyTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.construction_rounded,
                color: OwanyTheme.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item em Manutenção Ativa',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.warning,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Este item possui manutenção preventiva ativa no momento.',
                  style: TextStyle(
                    fontSize: 12,
                    color: OwanyTheme.warning,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// DETAILS CARD
// =============================================================

class _DetailsCard extends StatelessWidget {
  final ItemApartamentoDto item;
  final AppLocalizations l10n;

  const _DetailsCard({required this.item, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 16, color: OwanyTheme.white),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.assets_details,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailRow(
                label: l10n.assets_type, value: item.tipo ?? '-'),
            _DetailRow(
                label: l10n.assets_description,
                value: item.descricao ?? '-'),
            _DetailRow(
              label: l10n.assets_acquisition_date,
              value: item.dataAquisicao != null
                  ? DateFormat('dd/MM/yyyy').format(item.dataAquisicao!)
                  : '-',
            ),
            _DetailRow(
              label: 'Data Entrada',
              value: item.dataEntrada != null
                  ? DateFormat('dd/MM/yyyy').format(item.dataEntrada!)
                  : '-',
            ),
            _DetailRow(
                label: 'Estado Físico',
                value: item.estadoFisicoEnum.toPortuguese()),
            _DetailRow(
                label: 'Status Operacional',
                value: item.statusOperacionalEnum.toPortuguese()),
            if (item.observacoes != null && item.observacoes!.isNotEmpty)
              _DetailRow(
                  label: l10n.assets_notes, value: item.observacoes!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: OwanyTheme.surfaceColor(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// HISTÓRICO CARD
// =============================================================

class _HistoricoCard extends StatelessWidget {
  final HistoricoItemDto? historico;
  final bool loadingHistorico;
  final ItemApartamentoDto item;
  final AppLocalizations l10n;
  final VoidCallback onViewAll;

  const _HistoricoCard({
    required this.historico,
    required this.loadingHistorico,
    required this.item,
    required this.l10n,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final totalMovs = historico?.totalMovimentacoes ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded,
                      size: 16, color: OwanyTheme.white),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.assets_movement_history,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
                const Spacer(),
                if (loadingHistorico)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OwanyTheme.primaryOrange,
                    ),
                  )
                else if (totalMovs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalMovs mov.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewAll,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.open_in_new_rounded,
                          size: 16, color: OwanyTheme.primaryOrange),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (totalMovs == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.history_rounded,
                            size: 36,
                            color: OwanyTheme.textMutedColor(context)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.assets_no_movements,
                        style: TextStyle(
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  if (historico!.alocacoes.isNotEmpty)
                    ...historico!.alocacoes
                        .map((a) => _AlocacaoTile(a: a, l10n: l10n)),
                  if (historico!.mudancasEstado.isNotEmpty)
                    ...historico!.mudancasEstado
                        .map((m) => _MudancaEstadoTile(m: m, l10n: l10n)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AlocacaoTile extends StatelessWidget {
  final AlocacaoItemDto a;
  final AppLocalizations l10n;

  const _AlocacaoTile({required this.a, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OwanyTheme.success.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: OwanyTheme.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OwanyTheme.success,
                  OwanyTheme.success.withValues(alpha: 0.7)
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: OwanyTheme.success.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.login_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_tx(context, 'Alocação', 'Allocation'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: OwanyTheme.textPrimary(context),
                        )),
                    if (a.dataAlocacao != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yy').format(a.dataAlocacao!),
                          style: TextStyle(
                            fontSize: 10,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Apt ${a.apartamentoNumero}${a.apartamentoBloco.isNotEmpty ? ' - Bloco ${a.apartamentoBloco}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
                if (a.usuarioNome != null && a.usuarioNome!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 11,
                          color: OwanyTheme.textMutedColor(context)),
                      const SizedBox(width: 3),
                      Text(
                        a.usuarioNome!,
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
        ],
      ),
    );
  }
}

class _MudancaEstadoTile extends StatelessWidget {
  final MudancaEstadoItemDto m;
  final AppLocalizations l10n;

  const _MudancaEstadoTile({required this.m, required this.l10n});

  @override
  Widget build(BuildContext context) {
    const tileColor = OwanyTheme.primaryOrange;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tileColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tileColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: tileColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child:
                const Icon(Icons.change_circle, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_tx(context, 'Mudança de Estado', 'Status Change'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: OwanyTheme.textPrimary(context),
                        )),
                    if (m.dataMudanca != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yy').format(m.dataMudanca!),
                          style: TextStyle(
                            fontSize: 10,
                            color: OwanyTheme.textMutedColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (m.estadoAnterior != null)
                      Text(
                        m.estadoAnterior!,
                        style: TextStyle(
                          fontSize: 11,
                          color: OwanyTheme.textMutedColor(context),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 12,
                        color: OwanyTheme.textMutedColor(context)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.estadoNovo,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (m.motivo != null && m.motivo!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    m.motivo!,
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                ],
                if (m.usuarioNome != null && m.usuarioNome!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 11,
                          color: OwanyTheme.textMutedColor(context)),
                      const SizedBox(width: 3),
                      Text(
                        m.usuarioNome!,
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
        ],
      ),
    );
  }
}

// =============================================================
// ACTIONS ROW
// =============================================================

class _ActionsRow extends StatelessWidget {
  final ItemApartamentoDto item;
  final AppLocalizations l10n;
  final VoidCallback onTransfer;
  final VoidCallback onStatus;
  final VoidCallback onMore;

  const _ActionsRow({
    required this.item,
    required this.l10n,
    required this.onTransfer,
    required this.onStatus,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Primary: Transfer
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OwanyTheme.primaryOrange, OwanyTheme.accent],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onTransfer();
              },
              icon: const Icon(Icons.swap_horiz_rounded,
                  size: 18, color: OwanyTheme.white),
              label: Text(l10n.assets_menu_transfer,
                  style: const TextStyle(
                    color: OwanyTheme.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Secondary: Status
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              onStatus();
            },
            icon: Icon(Icons.change_circle_outlined,
                size: 16, color: OwanyTheme.primaryOrange),
            label: Text(_tx(context, 'Estado', 'Status'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
            style: OutlinedButton.styleFrom(
              foregroundColor: OwanyTheme.primaryOrange,
              side: BorderSide(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.5),
                  width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // More
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onMore();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: OwanyTheme.primaryOrange, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// BOTTOM SHEET ACTION TILE
// =============================================================

class _BottomSheetActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: OwanyTheme.textPrimary(context),
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withValues(alpha: 0.6)),
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

          // Header card skeleton
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          const SizedBox(height: 20),

          // Stats row skeleton
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 12),
                  height: 90,
                  decoration: BoxDecoration(
                    color: OwanyTheme.textMutedColor(context)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Cards skeletons
          ...List.generate(
            2,
            (index) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 100)),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 180,
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
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: OwanyTheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              _tx(context, 'Erro ao carregar ativo', 'Failed to load asset'),
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
              icon: const Icon(Icons.refresh_rounded, color: OwanyTheme.white),
              label: Text(_tx(context, 'Tentar novamente', 'Try again'),
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
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SOLICITAÇÕES CARD
// ════════════════════════════════════════════════════════════════════════════

class _SolicitacoesCard extends StatelessWidget {
  final HistoricoItemDto? historico;
  final bool loadingHistorico;
  final AppLocalizations l10n;

  const _SolicitacoesCard({
    required this.historico,
    required this.loadingHistorico,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final solProvider = context.watch<SolicitacoesProvider>();
    final solicitacoesFromProvider = solProvider.solicitacoesPorItem;
    final isLoadingSol = solProvider.isLoadingSolicitacoesPorItem;
    
    // Usa dados do SolicitacoesProvider (endpoint filtrado) como fonte principal
    // Fallback para historico.solicitacoes se provider estiver vazio
    final totalSolicitacoes = solicitacoesFromProvider.isNotEmpty
        ? solicitacoesFromProvider.length
        : (historico?.totalSolicitacoes ?? 0);
    final isLoading = loadingHistorico || isLoadingSol;

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.warning.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OwanyTheme.warning,
                        OwanyTheme.warning.withValues(alpha: 0.7)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_circle_rounded,
                      size: 16, color: OwanyTheme.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitações Vinculadas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Manutenções e serviços relacionados',
                        style: TextStyle(
                          fontSize: 11,
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OwanyTheme.warning,
                    ),
                  )
                else if (totalSolicitacoes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        OwanyTheme.warning,
                        OwanyTheme.warning.withValues(alpha: 0.8)
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalSolicitacoes',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Content
            if (totalSolicitacoes == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OwanyTheme.textMutedColor(context)
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.build_circle_rounded,
                            size: 36,
                            color: OwanyTheme.textMutedColor(context)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma solicitação vinculada',
                        style: TextStyle(
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (solicitacoesFromProvider.isNotEmpty)
              Column(
                children: [
                  ...solicitacoesFromProvider.map((sol) =>
                      _SolicitacaoListaTile(
                        solicitacao: sol,
                        l10n: l10n,
                      )),
                ],
              )
            else
              Column(
                children: [
                  ...historico!.solicitacoes.map((solicitacao) =>
                      _SolicitacaoTile(
                        solicitacao: solicitacao,
                        l10n: l10n,
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SOLICITAÇÃO TILE
// ════════════════════════════════════════════════════════════════════════════

class _SolicitacaoTile extends StatelessWidget {
  final SolicitacaoResumoItemDto solicitacao;
  final AppLocalizations l10n;

  const _SolicitacaoTile({
    required this.solicitacao,
    required this.l10n,
  });

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('concluido') ||
        normalized.contains('avaliado')) {
      return OwanyTheme.success;
    } else if (normalized.contains('pendente')) {
      return OwanyTheme.warning;
    } else if (normalized.contains('cancelado') ||
        normalized.contains('recusado')) {
      return OwanyTheme.error;
    } else if (normalized.contains('emandamento') ||
        normalized.contains('iniciado')) {
      return OwanyTheme.info;
    }
    return OwanyTheme.primaryOrange;
  }

  IconData _getStatusIcon(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('concluido') ||
        normalized.contains('avaliado')) {
      return Icons.check_circle_rounded;
    } else if (normalized.contains('pendente')) {
      return Icons.schedule_rounded;
    } else if (normalized.contains('cancelado') ||
        normalized.contains('recusado')) {
      return Icons.cancel_rounded;
    } else if (normalized.contains('emandamento') ||
        normalized.contains('iniciado')) {
      return Icons.play_circle_rounded;
    }
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(solicitacao.status);
    final statusIcon = _getStatusIcon(solicitacao.status);

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(statusIcon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitacao.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: OwanyTheme.textPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    solicitacao.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Pode navegar para detalhes da solicitação aqui
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_tx(context, 'Solicitação', 'Request')}: ${solicitacao.id}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded,
                size: 18, color: OwanyTheme.primaryOrange),
            tooltip: _tx(context, 'Ver detalhes', 'View details'),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SOLICITAÇÃO LISTA TILE (from SolicitacaoListaDto via SolicitacoesProvider)
// ════════════════════════════════════════════════════════════════════════════

class _SolicitacaoListaTile extends StatelessWidget {
  final SolicitacaoListaDto solicitacao;
  final AppLocalizations l10n;

  const _SolicitacaoListaTile({
    required this.solicitacao,
    required this.l10n,
  });

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('concluido') || normalized.contains('avaliado')) {
      return OwanyTheme.success;
    } else if (normalized.contains('pendente')) {
      return OwanyTheme.warning;
    } else if (normalized.contains('cancelado') || normalized.contains('recusado')) {
      return OwanyTheme.error;
    } else if (normalized.contains('emandamento') || normalized.contains('iniciado')) {
      return OwanyTheme.info;
    }
    return OwanyTheme.primaryOrange;
  }

  IconData _getStatusIcon(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('concluido') || normalized.contains('avaliado')) {
      return Icons.check_circle_rounded;
    } else if (normalized.contains('pendente')) {
      return Icons.schedule_rounded;
    } else if (normalized.contains('cancelado') || normalized.contains('recusado')) {
      return Icons.cancel_rounded;
    } else if (normalized.contains('emandamento') || normalized.contains('iniciado')) {
      return Icons.play_circle_rounded;
    }
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(solicitacao.status);
    final statusIcon = _getStatusIcon(solicitacao.status);

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(statusIcon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitacao.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: OwanyTheme.textPrimary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (solicitacao.tipoSolicitacaoNome != null)
                  Text(
                    solicitacao.tipoSolicitacaoNome!,
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.textMutedColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    solicitacao.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/maintenance-detail',
                arguments: {'solicitacaoId': solicitacao.id},
              );
            },
            icon: const Icon(Icons.open_in_new_rounded,
                size: 18, color: OwanyTheme.primaryOrange),
            tooltip: _tx(context, 'Ver detalhes', 'View details'),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
