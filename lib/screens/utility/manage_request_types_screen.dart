import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../theme/owany_theme.dart';

class ManageRequestTypesScreen extends StatefulWidget {
  const ManageRequestTypesScreen({super.key});

  @override
  State<ManageRequestTypesScreen> createState() =>
      _ManageRequestTypesScreenState();
}

class _ManageRequestTypesScreenState extends State<ManageRequestTypesScreen> {
  final _controller = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prov = Provider.of<SolicitacoesProvider>(context, listen: false);
      if (prov.tiposSolicitacao.isEmpty && !prov.isLoadingTipos) {
        prov.loadTipos();
      }
      if (prov.areasTecnicas.isEmpty && !prov.isLoadingAreas) {
        prov.loadAreas();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _addTipo(BuildContext context) async {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    final prov = Provider.of<SolicitacoesProvider>(context, listen: false);
    final novo = await prov.adicionarTipo(nome);
    if (!mounted) return;

    if (novo != null) {
      _controller.clear();
      FocusScope.of(context).unfocus();
      return;
    }

    if (prov.erroTipos != null) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(prov.erroTipos!, type: SnackBarType.error),
      );
    }
  }

  Future<void> _removerTipo(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final prov = Provider.of<SolicitacoesProvider>(context, listen: false);
    final ok = await prov.removerTipo(id);

    if (!mounted) return;
    if (!ok && prov.erroTipos != null) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(prov.erroTipos!, type: SnackBarType.error),
      );
    }
  }

  Future<void> _addArea(BuildContext context) async {
    final nome = _areaController.text.trim();
    if (nome.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    final prov = Provider.of<SolicitacoesProvider>(context, listen: false);
    final novo = await prov.adicionarArea(nome);
    if (!mounted) return;

    if (novo != null) {
      _areaController.clear();
      FocusScope.of(context).unfocus();
      return;
    }

    if (prov.erroAreas != null) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(prov.erroAreas!, type: SnackBarType.error),
      );
    }
  }

  Future<void> _removerArea(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final prov = Provider.of<SolicitacoesProvider>(context, listen: false);
    final ok = await prov.removerArea(id);

    if (!mounted) return;
    if (!ok && prov.erroAreas != null) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(prov.erroAreas!, type: SnackBarType.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: OwanyTheme.backgroundColor(context),
        appBar: AppBar(
          backgroundColor: OwanyTheme.primaryBrown,
          foregroundColor: OwanyTheme.white,
          title: Text(l10n.request_types_title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(62),
            child: Container(
              height: 44,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                labelColor: OwanyTheme.primaryBrown,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.88),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Tipos'),
                  Tab(text: 'Areas'),
                ],
              ),
            ),
          ),
        ),
        body: Consumer<SolicitacoesProvider>(
          builder: (context, prov, _) {
            return TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTiposTab(context, l10n, prov),
                _buildAreasTab(context, l10n, prov),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTiposTab(
    BuildContext context,
    AppLocalizations l10n,
    SolicitacoesProvider prov,
  ) {
    return _buildTabShell(
      context,
      count: prov.tiposSolicitacao.length,
      countLabel: 'Tipos cadastrados',
      addLabel: l10n.request_types_add_new,
      addHint: l10n.request_types_hint,
      addIcon: Icons.category_rounded,
      addController: _controller,
      loadingAdd: prov.isLoadingTipos,
      onAdd: () => _addTipo(context),
      addButtonText: l10n.common_add,
      errorMessage: prov.erroTipos,
      emptyText: l10n.request_types_empty,
      listIcon: Icons.fact_check_outlined,
      listTitle: l10n.request_types_registered,
      isLoadingList: prov.isLoadingTipos,
      listChild: ListView.separated(
        itemCount: prov.tiposSolicitacao.length,
        separatorBuilder: (_, __) =>
            Divider(color: OwanyTheme.borderColor(context), height: 1),
        itemBuilder: (context, i) {
          final tipo = prov.tiposSolicitacao[i];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
              child: const Icon(
                Icons.build_circle_outlined,
                size: 18,
                color: OwanyTheme.primaryOrange,
              ),
            ),
            title: Text(
              tipo.nome,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: IconButton(
              tooltip: l10n.common_remove,
              onPressed: () => _removerTipo(context, tipo.id),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: OwanyTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAreasTab(
    BuildContext context,
    AppLocalizations l10n,
    SolicitacoesProvider prov,
  ) {
    return _buildTabShell(
      context,
      count: prov.areasTecnicas.length,
      countLabel: 'Areas tecnicas',
      addLabel: 'Adicionar area tecnica',
      addHint: 'Nome da area (ex: Eletrica)',
      addIcon: Icons.home_repair_service_rounded,
      addController: _areaController,
      loadingAdd: prov.isLoadingAreas,
      onAdd: () => _addArea(context),
      addButtonText: l10n.common_add,
      errorMessage: prov.erroAreas,
      emptyText: 'Nenhuma area cadastrada.',
      listIcon: Icons.handyman_outlined,
      listTitle: 'Areas registradas',
      isLoadingList: prov.isLoadingAreas,
      listChild: ListView.separated(
        itemCount: prov.areasTecnicas.length,
        separatorBuilder: (_, __) =>
            Divider(color: OwanyTheme.borderColor(context), height: 1),
        itemBuilder: (context, i) {
          final area = prov.areasTecnicas[i];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: OwanyTheme.info.withValues(alpha: 0.14),
              child: const Icon(
                Icons.room_preferences_outlined,
                size: 18,
                color: OwanyTheme.info,
              ),
            ),
            title: Text(
              area.nome,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: IconButton(
              tooltip: l10n.common_remove,
              onPressed: () => _removerArea(context, area.id),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: OwanyTheme.error,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabShell(
    BuildContext context, {
    required int count,
    required String countLabel,
    required String addLabel,
    required String addHint,
    required IconData addIcon,
    required TextEditingController addController,
    required bool loadingAdd,
    required VoidCallback onAdd,
    required String addButtonText,
    required String? errorMessage,
    required String emptyText,
    required IconData listIcon,
    required String listTitle,
    required bool isLoadingList,
    required Widget listChild,
  }) {
    return SafeArea(
      child: OwanyTheme.responsiveBody(
        maxWidth: 880,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            children: [
              _buildCountCard(context, count, countLabel),
              const SizedBox(height: 12),
              _buildFormCard(
                context,
                title: addLabel,
                hint: addHint,
                icon: addIcon,
                controller: addController,
                isLoading: loadingAdd,
                onSubmit: onAdd,
                buttonText: addButtonText,
              ),
              if (errorMessage != null && errorMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildErrorBanner(context, errorMessage),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _buildListCard(
                  context,
                  title: listTitle,
                  icon: listIcon,
                  child: isLoadingList
                      ? const Center(child: CircularProgressIndicator())
                      : count == 0
                      ? Center(
                          child: Text(
                            emptyText,
                            style: OwanyTheme.mutedStyle(context, fontSize: 14),
                          ),
                        )
                      : listChild,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountCard(BuildContext context, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 20,
              color: OwanyTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Text('$count', style: OwanyTheme.titleStyle(context, fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: OwanyTheme.mutedStyle(context, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context, {
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isLoading,
    required VoidCallback onSubmit,
    required String buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: OwanyTheme.titleStyle(context, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isLoading,
                  onSubmitted: (_) => onSubmit(),
                  decoration: OwanyTheme.adaptiveInputDecoration(
                    context,
                    label: title,
                    hint: hint,
                    icon: icon,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  style: OwanyTheme.primaryButtonStyle(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(buttonText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, color: OwanyTheme.primaryOrange, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: OwanyTheme.titleStyle(context, fontSize: 15),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: OwanyTheme.borderColor(context)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OwanyTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: OwanyTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: OwanyTheme.error.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
