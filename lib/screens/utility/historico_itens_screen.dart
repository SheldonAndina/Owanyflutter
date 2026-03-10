import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../providers/item_movimentacao_provider.dart';
import '../../dto/item_movimentacao_dto.dart';
import '../../models/item_estado.dart';
import '../../generated_l10n/app_localizations.dart';

class HistoricoItensScreen extends StatefulWidget {
  final String? itemId;

  const HistoricoItensScreen({super.key, this.itemId});

  @override
  State<HistoricoItensScreen> createState() => _HistoricoItensScreenState();
}

class _HistoricoItensScreenState extends State<HistoricoItensScreen> {
  final _searchController = TextEditingController();

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(l10n.items_history_title),
        backgroundColor: OwanyTheme.primaryBrown,
        actions: [
          IconButton(
            onPressed: () async {
              // Transferir or atualizar dialogs require itemId
              if (widget.itemId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.items_item_not_provided)),
                );
                return;
              }

              final choice = await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                items: [
                  PopupMenuItem(
                    value: 'transferir',
                    child: Text(l10n.items_transfer_dialog_title),
                  ),
                  PopupMenuItem(
                    value: 'atualizar',
                    child: Text(l10n.items_update_state_menu),
                  ),
                ],
              );

              if (choice == null) return;
              if (!mounted) return;
              if (choice == 'transferir') {
                await _showTransferDialog(context, widget.itemId!);
                if (!mounted) return;
              } else if (choice == 'atualizar') {
                await _showAtualizarEstadoDialog(context, widget.itemId!);
                if (!mounted) return;
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: l10n.common_actions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.common_search_placeholder,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: OwanyTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PrimaryButton.primary(
                  text: l10n.common_search,
                  onPressed: () {
                    // Placeholder search action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.common_search_action)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),

            Consumer<ItemMovimentacaoProvider>(
              builder: (context, prov, _) {
                return Expanded(
                  child: prov.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: OwanyTheme.primaryOrange,
                          ),
                        )
                      : prov.errorMessage != null
                      ? Center(
                          child: Text(
                            prov.errorMessage!,
                            style: TextStyle(color: OwanyTheme.error),
                          ),
                        )
                      : prov.historico.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: OwanyTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              l10n.items_no_movement_found,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: OwanyTheme.textMutedColor(context),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: prov.historico.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final m = prov.historico[idx];
                            return ListTile(
                              tileColor: OwanyTheme.cardColor(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                m.tipo,
                                style: TextStyle(
                                  color: OwanyTheme.textPrimary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.usuarioNome ?? 'Sistema'} • ${m.criadoEm.toLocal().toString().substring(0, 16)}',
                                    style: TextStyle(
                                      color: OwanyTheme.textMutedColor(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (m.solicitacao != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.build_rounded,
                                            size: 12,
                                            color: OwanyTheme.primaryOrange,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              m.solicitacao!.titulo,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: OwanyTheme.primaryOrange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                estadoToUiLabel(estadoFromString(m.novoEstado)),
                                style: TextStyle(
                                  color: OwanyTheme.primaryOrange,
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: OwanyTheme.cardColor(ctx),
                                    title: Text(l10n.items_movement_details,
                                        style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${l10n.items_origin}: ${m.apartamentoOrigemId ?? '-'}',
                                          style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                                        ),
                                        Text(
                                          '${l10n.items_destination}: ${m.apartamentoDestinoId ?? '-'}',
                                          style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                                        ),
                                        if (m.motivo != null)
                                          Text(
                                            '${l10n.items_reason}: ${m.motivo}',
                                            style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                                          ),
                                        if (m.observacoes != null)
                                          Text(
                                            '${l10n.items_observations}: ${m.observacoes}',
                                            style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                                          ),
                                        if (m.solicitacao != null) ...[
                                          const SizedBox(height: 8),
                                          const Divider(height: 1),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.build_rounded,
                                                size: 14,
                                                color: OwanyTheme.primaryOrange,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Solicitação: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: OwanyTheme.textPrimary(ctx),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(m.solicitacao!.titulo,
                                              style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Status: ${m.solicitacao!.status}',
                                            style: TextStyle(
                                              color: OwanyTheme.primaryOrange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        child: Text(l10n.common_close,
                                            style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransferDialog(BuildContext context, String itemId) async {
    final l10n = AppLocalizations.of(context)!;
    final destController = TextEditingController();
    String? estadoSelecionado;
    final motivoController = TextEditingController();
    final obsController = TextEditingController();
    final prov = context.read<ItemMovimentacaoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwanyTheme.cardColor(ctx),
        title: Text(l10n.items_transfer_dialog_title,
            style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: destController,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_dest_apartment_id,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: estadoSelecionado,
                dropdownColor: OwanyTheme.cardColor(ctx),
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_new_state_optional,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(_tx('Sem alteração', 'No change')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Disponivel',
                    child: Text(_tx('Disponível', 'Available')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Manutencao',
                    child: Text(_tx('Em manutenção', 'Under maintenance')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Danificado',
                    child: Text(_tx('Danificado', 'Damaged')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'EmStock',
                    child: Text(_tx('Em Stock', 'In Stock')),
                  ),
                ],
                onChanged: (v) => estadoSelecionado = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_reason_optional,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_observations_optional,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel,
                style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
          ),
          ElevatedButton(
            onPressed: () async {
              final req = TransferirItemRequest(
                itemApartamentoId: itemId,
                apartamentoDestinoId: destController.text.trim(),
                novoEstado: estadoSelecionado == null
                    ? null
                    : estadoToString(estadoFromString(estadoSelecionado)),
                motivo: motivoController.text.trim().isEmpty
                    ? null
                    : motivoController.text.trim(),
                observacoes: obsController.text.trim().isEmpty
                    ? null
                    : obsController.text.trim(),
              );

              final ok = await prov.transferir(req);
              Navigator.of(ctx).pop(ok);
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.items_transfer_success)),
      );
      // reload histórico
      await prov.loadHistorico(itemId);
    } else if (result == false) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.items_transfer_fail)));
    }
  }

  Future<void> _showAtualizarEstadoDialog(
    BuildContext context,
    String itemId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    String novoEstado = 'Disponivel';
    final motivoController = TextEditingController();
    final obsController = TextEditingController();

    final prov = context.read<ItemMovimentacaoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwanyTheme.cardColor(ctx),
        title: Text(l10n.items_update_state_dialog_title,
            style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: novoEstado,
                dropdownColor: OwanyTheme.cardColor(ctx),
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(ctx, label: l10n.items_new_state),
                items: [
                  DropdownMenuItem<String>(
                    value: 'Disponivel',
                    child: Text(_tx('Disponível', 'Available')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Manutencao',
                    child: Text(_tx('Em manutenção', 'Under maintenance')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Danificado',
                    child: Text(_tx('Danificado', 'Damaged')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'EmStock',
                    child: Text(_tx('Em Stock', 'In Stock')),
                  ),
                ],
                onChanged: (v) => novoEstado = v ?? 'Disponivel',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_reason_optional,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: l10n.items_observations_optional,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel,
                style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
          ),
          ElevatedButton(
            onPressed: () async {
              final req = AtualizarEstadoItemRequest(
                itemApartamentoId: itemId,
                novoEstado: estadoToString(estadoFromString(novoEstado)),
                motivo: motivoController.text.trim().isEmpty
                    ? null
                    : motivoController.text.trim(),
                observacoes: obsController.text.trim().isEmpty
                    ? null
                    : obsController.text.trim(),
              );

              final ok = await prov.atualizarEstado(req);
              Navigator.of(ctx).pop(ok);
            },
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.items_update_success)),
      );
      await prov.loadHistorico(itemId);
    } else if (result == false) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.items_update_fail)));
    }
  }
}
