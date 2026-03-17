import 'package:flutter/material.dart';
import '../../utils/log_shim.dart';
import '../../utils/patrimonio_deep_link.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../models/item_estado.dart';
import '../../services/api_service.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_date_time.dart';
import '../../dto/api_dtos.dart';
import '../../dto/item_apartamento_movimentacao_dtos.dart';
import '../../dto/item_estado_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/apartamentos_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

class ManageApartmentItemsScreen extends StatefulWidget {
  final String apartamentoId;
  final String apartamentoNome;

  const ManageApartmentItemsScreen({
    required this.apartamentoId,
    required this.apartamentoNome,
    super.key,
  });

  @override
  State<ManageApartmentItemsScreen> createState() =>
      _ManageApartmentItemsScreenState();
}

class _ManageApartmentItemsScreenState
    extends State<ManageApartmentItemsScreen> {
  final ApiService _apiService = ApiService();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');
  final _valorController = TextEditingController();
  late Future<List<ItemApartamento>> _itemsFuture;
  bool _isCreating = false;
  ItemApartamento? _editingItem;
  bool _canManage = true;
  bool _didResolvePermissions = false;
  String _tipoSelecionado = 'Mobília';
  DateTime? _dataAquisicaoSelecionada;
  EstadoFisicoItem _estadoFisicoSelecionado = EstadoFisicoItem.disponivel;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didResolvePermissions) {
      final auth = context.read<AuthProvider>();
      final userType = auth.usuarioAtual?.tipo;
      _canManage =
          userType == UsuarioTipo.Administrador ||
          userType == UsuarioTipo.Sindico;
      _didResolvePermissions = true;
    }
  }

  void _loadItems() {
    _itemsFuture = _apiService.getItensApartamento(widget.apartamentoId);
  }

  Future<void> _scanQrCode() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final scanned = await Navigator.pushNamed(context, '/qr-scan');
      if (scanned is! String || scanned.trim().isEmpty) return;

      final codigo = PatrimonioDeepLink.extractCodigo(
        scanned,
        allowStandaloneCode: true,
      )?.trim();
      if (codigo == null || codigo.isEmpty) return;

      // Ensure we have latest apartment items
      final items = await _apiService.getItensApartamento(widget.apartamentoId);
      ItemApartamento? match;
      for (final it in items) {
        if ((it.codigoPatrimonio ?? '').trim() == codigo) {
          match = it;
          break;
        }
      }

      if (!mounted) return;

      if (match != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalheAtivoScreen(itemId: match.id)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.assets_no_items_loaded}: $codigo')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.assets_consult_fail}: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _quantidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _showForm({ItemApartamento? item, bool allowMultiple = true}) {
    final l10n = AppLocalizations.of(context)!;
    if (!_canManage) {
      _showError(l10n.items_no_permission);
      return;
    }

    _editingItem = item;
    _nomeController.text = item?.nome ?? '';
    _descricaoController.text = item?.descricao ?? '';
    final l10nTipos = <String>[
      // mesma lista do dropdown
      l10n.items_type_furniture,
      l10n.items_type_appliance,
      l10n.items_type_electronics,
      l10n.items_type_plumbing,
      l10n.items_type_lighting,
      l10n.items_type_structure,
      l10n.items_type_other,
    ];
    // Remove duplicatas
    final tiposUnicos = l10nTipos.toSet().toList();
    // Se o tipo do item não está na lista, seleciona o primeiro
    if (item?.tipo != null && tiposUnicos.contains(item!.tipo)) {
      _tipoSelecionado = item.tipo!;
    } else {
      _tipoSelecionado = tiposUnicos.first;
    }
    _quantidadeController.text = (item?.quantidade ?? 1).toString();
    _valorController.text = item?.valorEstimado != null
        ? item!.valorEstimado!.toStringAsFixed(2)
        : '';
    _dataAquisicaoSelecionada = item?.dataAquisicao;
    if (item?.estadoAtual != null) {
      _estadoFisicoSelecionado = EstadoFisicoItemExtension.fromString(item!.estadoAtual!);
    } else {
      _estadoFisicoSelecionado = EstadoFisicoItem.disponivel;
    }
    bool isEditing = item != null;

    showDialog(
      context: context,
      barrierDismissible: !_isCreating,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dataAquisicaoSelecionada ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              helpText: _tx('Data de Aquisi\u00e7\u00e3o', 'Acquisition date'),
            );
            if (picked != null) {
              setState(() => _dataAquisicaoSelecionada = picked);
              setDialogState(() {});
            }
          }

          Widget estadoDropdown() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tx('Estado f\u00edsico', 'Physical state'),
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EstadoFisicoItem>(
                  initialValue: _estadoFisicoSelecionado,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? OwanyTheme.darkSurface
                        : OwanyTheme.surface,
                    prefixIcon: Icon(
                      _estadoFisicoSelecionado.icone,
                      color: _estadoFisicoSelecionado.cor,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: OwanyTheme.primaryOrange,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: OwanyTheme.primaryOrange),
                  items: EstadoFisicoItem.values.map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(e.icone, color: e.cor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          e.toPortuguese(),
                          style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 14),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _estadoFisicoSelecionado = value);
                    setDialogState(() {});
                  },
                ),
              ],
            );
          }

          Widget dataAquisicaoField() {
            final hasDate = _dataAquisicaoSelecionada != null;
            final label = hasDate
                ? '${_dataAquisicaoSelecionada!.day.toString().padLeft(2, '0')}/'
                    '${_dataAquisicaoSelecionada!.month.toString().padLeft(2, '0')}/'
                    '${_dataAquisicaoSelecionada!.year}'
                : _tx('Selecionar data', 'Select date');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tx('Data de aquisi\u00e7\u00e3o', 'Acquisition date'),
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? OwanyTheme.darkSurface
                          : OwanyTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: OwanyTheme.primaryOrange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: hasDate
                                  ? OwanyTheme.textPrimary(context)
                                  : OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (hasDate)
                          GestureDetector(
                            onTap: () {
                              setState(() => _dataAquisicaoSelecionada = null);
                              setDialogState(() {});
                            },
                            child: Icon(Icons.close_rounded,
                                size: 16,
                                color: OwanyTheme.textMutedColor(context)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OwanyTheme.primaryOrange,
                        OwanyTheme.primaryOrange.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OwanyTheme.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          size: 24,
                          color: OwanyTheme.cardColor(context),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? l10n.items_edit_item
                                  : l10n.items_new_item,
                              style: TextStyle(
                                color: OwanyTheme.cardColor(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              l10n.items_for_apartment(widget.apartamentoNome),
                              style: TextStyle(
                                color: OwanyTheme.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== CONTENT =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        label: l10n.items_name_label,
                        hint: l10n.items_name_hint,
                        icon: Icons.label_rounded,
                        controller: _nomeController,
                      ),
                      SizedBox(height: 20),
                      _buildFormField(
                        label: l10n.items_description_label,
                        hint: l10n.items_description_hint,
                        icon: Icons.description_rounded,
                        controller: _descricaoController,
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      _buildTipoDropdown(),
                      SizedBox(height: 20),
                      _buildFormField(
                        label: l10n.items_quantity_label,
                        hint: l10n.items_quantity_hint,
                        icon: Icons.confirmation_number_rounded,
                        controller: _quantidadeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4, // Max 9999
                      ),
                      SizedBox(height: 20),
                      _buildFormField(
                        label: l10n.items_estimated_value_label,
                        hint: l10n.items_estimated_value_hint,
                        icon: Icons.attach_money_rounded,
                        controller: _valorController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      SizedBox(height: 20),
                      estadoDropdown(),
                      SizedBox(height: 20),
                      dataAquisicaoField(),
                    ],
                  ),
                ),

                // ===== ACTIONS =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton.primary(
                        text: isEditing
                            ? l10n.items_update_item
                            : l10n.items_add_item,
                        onPressed: _isCreating
                            ? null
                            : () async {
                                await _adicionarItem();
                                if (!mounted) return;

                                if (isEditing) {
                                  // If editing, close dialog
                                  Navigator.pop(context);
                                } else {
                                  // If creating new, clear fields
                                  _nomeController.clear();
                                  _descricaoController.clear();
                                  _editingItem = null;
                                }
                              },
                        icon: isEditing
                            ? Icons.update_rounded
                            : Icons.check_rounded,
                      ),
                      SizedBox(height: 12),
                      if (!isEditing && allowMultiple)
                        PrimaryButton.secondary(
                          text: l10n.items_close,
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.pop(context),
                          icon: Icons.close_rounded,
                        )
                      else if (isEditing)
                        PrimaryButton.secondary(
                          text: l10n.common_cancel,
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.pop(context),
                          icon: Icons.close_rounded,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
        },
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : 2,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: OwanyTheme.primaryOrange, size: 20),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? OwanyTheme.darkSurface
                : OwanyTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: OwanyTheme.primaryOrange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final tipos = <String>{
      l10n.items_type_furniture,
      l10n.items_type_appliance,
      l10n.items_type_electronics,
      l10n.items_type_plumbing,
      l10n.items_type_lighting,
      l10n.items_type_structure,
      l10n.items_type_other,
    }.toList(); // remove duplicatas

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.items_type_label,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _tipoSelecionado,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? OwanyTheme.darkSurface
                : OwanyTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: OwanyTheme.primaryOrange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: OwanyTheme.primaryOrange,
          ),
          items: tipos
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t,
                    style: TextStyle(
                      color: OwanyTheme.textPrimary(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _tipoSelecionado = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _adicionarItem() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nomeController.text.isEmpty) {
      _showError(l10n.items_name_required);
      return;
    }

    debugPrintLog(
      '[DEBUG] _quantidadeController.text = "${_quantidadeController.text}"',
    );
    debugPrintLog(
      '[DEBUG] _quantidadeController.text.trim() = "${_quantidadeController.text.trim()}"',
    );

    final quantidade = int.tryParse(_quantidadeController.text.trim());
    debugPrintLog('[DEBUG] Quantidade parseada = $quantidade');

    if (quantidade == null || quantidade <= 0) {
      _showError(l10n.items_quantity_invalid);
      return;
    }

    // Max limit validation (backend bug protection)
    if (quantidade > 9999) {
      _showError(l10n.items_quantity_max);
      return;
    }

    final valorEstimado = double.tryParse(
      _valorController.text.trim().replaceAll(',', '.'),
    );

    try {
      setState(() => _isCreating = true);

      final wasEditing = _editingItem != null;

      if (_editingItem == null) {
        // Create new item
        final request = CriarItemApartamentoRequest(
          apartamentoId: widget.apartamentoId,
          nome: _nomeController.text,
          descricao: _descricaoController.text.isEmpty
              ? null
              : _descricaoController.text,
          tipo: _tipoSelecionado,
          quantidade: quantidade,
          valorEstimado: valorEstimado,
          estadoAtual: _estadoFisicoSelecionado.toBackendValue(),
          dataAquisicao: _dataAquisicaoSelecionada,
        );
        await _apiService.criarItemApartamento(request);
      } else {
        // Update existing item
        await _apiService.atualizarItemApartamento(_editingItem!.id, {
          'nome': _nomeController.text,
          'descricao': _descricaoController.text.isEmpty
              ? null
              : _descricaoController.text,
          'tipo': _tipoSelecionado,
          'quantidade': quantidade,
          'valorEstimado': valorEstimado,
          'estadoAtual': _estadoFisicoSelecionado.toBackendValue(),
          if (_dataAquisicaoSelecionada != null)
            'dataAquisicao': toBackendUtcIsoString(_dataAquisicaoSelecionada!),
        });
      }

      _nomeController.clear();
      _descricaoController.clear();
      _quantidadeController.text = '1';
      _valorController.clear();
      _tipoSelecionado = 'Mobília';
      _dataAquisicaoSelecionada = null;
      _estadoFisicoSelecionado = EstadoFisicoItem.disponivel;
      _editingItem = null;
      _loadItems();
      setState(() => _isCreating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(
            wasEditing
                ? l10n.items_updated_success
                : l10n.items_created_success,
          ),
        );

        // Return to list if creating (not editing)
        if (!wasEditing) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      _showError(l10n.items_save_error(e.toString()));
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canManage) {
      _showError(l10n.items_no_delete_permission);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.items_delete_title),
        content: Text(l10n.items_delete_confirm),
        actions: [
          PrimaryButton.secondary(
            text: l10n.common_cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          PrimaryButton.error(
            text: l10n.action_delete,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deletarItemApartamento(itemId);
        _loadItems();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(OwanyTheme.snackBar(l10n.items_deleted_success));
        }
      } catch (e) {
        _showError(l10n.items_delete_error(e.toString()));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(OwanyTheme.snackBar(message, type: SnackBarType.error));
  }

  IconData _getItemIcon(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('ar') || name.contains('condicionado'))
      return Icons.ac_unit_rounded;
    if (name.contains('geladeira') ||
        name.contains('refrigerador') ||
        name.contains('fridge'))
      return Icons.kitchen_rounded;
    if (name.contains('micro') || name.contains('ondas'))
      return Icons.microwave_rounded;
    if (name.contains('tv') || name.contains('televisão'))
      return Icons.tv_rounded;
    if (name.contains('fogão') || name.contains('cooktop'))
      return Icons.fireplace_rounded;
    if (name.contains('máquina') || name.contains('lavar'))
      return Icons.local_laundry_service_rounded;
    if (name.contains('sofa') ||
        name.contains('sofá') ||
        name.contains('cadeira'))
      return Icons.chair_rounded;
    if (name.contains('mesa') || name.contains('bancada'))
      return Icons.table_restaurant_rounded;
    if (name.contains('cama') || name.contains('colchão'))
      return Icons.hotel_rounded;
    if (name.contains('chuveiro') || name.contains('banheira'))
      return Icons.bathroom_rounded;
    if (name.contains('luz') || name.contains('lâmpada'))
      return Icons.lightbulb_rounded;
    if (name.contains('porta') || name.contains('janela'))
      return Icons.door_sliding_rounded;
    if (name.contains('piso') || name.contains('tapete'))
      return Icons.domain_rounded;
    return Icons.inventory_2_rounded;
  }

  String _normalizeEstadoForApi(String estado) {
    return normalizeEstadoForApi(estado, hasApartamento: true);
  }

  Color _estadoColor(String? estadoRaw) {
    switch (estadoFromString(estadoRaw)) {
      case ItemEstado.Disponivel:
        return OwanyTheme.success;
      case ItemEstado.EmUso:
        return OwanyTheme.primaryBlue;
      case ItemEstado.Manutencao:
        return OwanyTheme.warning;
      case ItemEstado.Danificado:
        return OwanyTheme.error;
      case ItemEstado.Inutilizado:
        return OwanyTheme.gray;
      case ItemEstado.Extraviado:
        return OwanyTheme.purple;
      case ItemEstado.EmStock:
        return OwanyTheme.info;
      case ItemEstado.Desconhecido:
        return OwanyTheme.textMutedColor(context);
    }
  }

  Widget _infoChip(String texto, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTransferDialog(ItemApartamento item) async {
    final l10n = AppLocalizations.of(context)!;
    final apartamentosProvider = Provider.of<ApartamentosProvider>(
      context,
      listen: false,
    );
    String? apartamentoDestinoId;
    String novoEstado = 'Disponível';
    final motivoController = TextEditingController();
    final obsController = TextEditingController();
    final apartamentos = apartamentosProvider.apartamentos
        .where((a) => a.id != item.apartamentoId)
        .toList();
    if (apartamentos.isEmpty) {
      _showError(l10n.assets_no_apartment_transfer);
      return;
    }
    apartamentoDestinoId = apartamentos.first.id;
    await showDialog(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.items_transfer_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: apartamentoDestinoId,
              items: apartamentos
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.numero)),
                  )
                  .toList(),
              onChanged: (v) => apartamentoDestinoId = v,
              decoration: InputDecoration(labelText: _tx('Apartamento destino', 'Destination apartment')),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: novoEstado,
              items: [
                DropdownMenuItem(
                  value: 'Disponível',
                  child: Text(_tx('Disponível', 'Available')),
                ),
                DropdownMenuItem(
                  value: 'Em manutenção',
                  child: Text(_tx('Em manutenção', 'Under maintenance')),
                ),
                DropdownMenuItem(
                  value: 'Danificado',
                  child: Text(_tx('Danificado', 'Damaged')),
                ),
              ],
              onChanged: (v) => novoEstado = v ?? 'Disponível',
              decoration: InputDecoration(labelText: _tx('Novo estado', 'New state')),
            ),
            SizedBox(height: 12),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(labelText: _tx('Motivo', 'Reason')),
            ),
            SizedBox(height: 12),
            TextField(
              controller: obsController,
              decoration: InputDecoration(labelText: _tx('Observações', 'Notes')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (apartamentoDestinoId == null ||
                  motivoController.text.isEmpty) {
                _showError(_tx('Preencha todos os campos obrigatórios.', 'Fill in all required fields.'));
                return;
              }
              final req = TransferirItemApartamentoRequest(
                itemApartamentoId: item.id,
                apartamentoDestinoId: apartamentoDestinoId!,
                novoEstado: _normalizeEstadoForApi(novoEstado),
                motivo: motivoController.text,
                observacoes: obsController.text,
              );
              final ok = await apartamentosProvider.transferirItemApartamento(
                req,
              );
              if (ok) {
                Navigator.pop(context);
                _showError(_tx('Item transferido com sucesso!', 'Item transferred successfully!'));
                setState(() => _loadItems());
              }
            },
            child: Text(l10n.items_transfer_button),
          ),
        ],
      ),
    );
  }

  void _showUpdateEstadoDialog(ItemApartamento item) async {
    final l10n = AppLocalizations.of(context)!;
    final apartamentosProvider = Provider.of<ApartamentosProvider>(
      context,
      listen: false,
    );
    String novoEstado = 'Disponível';
    final motivoController = TextEditingController();
    final obsController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.items_update_state_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: novoEstado,
              items: [
                DropdownMenuItem(
                  value: 'Disponível',
                  child: Text(_tx('Disponível', 'Available')),
                ),
                DropdownMenuItem(
                  value: 'Em manutenção',
                  child: Text(_tx('Em manutenção', 'Under maintenance')),
                ),
                DropdownMenuItem(
                  value: 'Danificado',
                  child: Text(_tx('Danificado', 'Damaged')),
                ),
              ],
              onChanged: (v) => novoEstado = v ?? 'Disponível',
              decoration: InputDecoration(labelText: _tx('Novo estado', 'New state')),
            ),
            SizedBox(height: 12),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(labelText: _tx('Motivo', 'Reason')),
            ),
            SizedBox(height: 12),
            TextField(
              controller: obsController,
              decoration: InputDecoration(labelText: _tx('Observações', 'Notes')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.isEmpty) {
                _showError(_tx('Preencha todos os campos obrigatórios.', 'Fill in all required fields.'));
                return;
              }
              final req = AtualizarEstadoItemApartamentoRequest(
                itemApartamentoId: item.id,
                novoEstado: _normalizeEstadoForApi(novoEstado),
                motivo: motivoController.text,
                observacoes: obsController.text,
              );
              final ok = await apartamentosProvider
                  .atualizarEstadoItemApartamento(req);
              if (ok) {
                Navigator.pop(context);
                _showError(_tx('Estado atualizado com sucesso!', 'State updated successfully!'));
                setState(() => _loadItems());
              }
            },
            child: Text(l10n.common_update),
          ),
        ],
      ),
    );
  }

  void _showHistoricoDialog(ItemApartamento item) async {
    final l10n = AppLocalizations.of(context)!;
    final apartamentosProvider = Provider.of<ApartamentosProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.items_movement_history),
        content: FutureBuilder<List<ItemApartamentoMovimentacaoHistoricoDto>>(
          future: apartamentosProvider.getHistoricoMovimentacao(
            item.id,
            updateState: false,
            forceRefresh: true,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text(l10n.items_history_load_error);
            }
            final historico = snapshot.data ?? [];
            if (historico.isEmpty) {
              return Text(l10n.items_history_empty);
            }
            return SizedBox(
              width: 350,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: historico.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, idx) {
                  final h = historico[idx];
                  final origemLabel = h.origem != null && h.origem!.numero.isNotEmpty
                      ? 'Apto ${h.origem!.numero}${h.origem!.bloco.isNotEmpty ? " / ${h.origem!.bloco}" : ""}'
                      : h.apartamentoOrigemId;
                  final destinoLabel = h.destino != null && h.destino!.numero.isNotEmpty
                      ? 'Apto ${h.destino!.numero}${h.destino!.bloco.isNotEmpty ? " / ${h.destino!.bloco}" : ""}'
                      : h.apartamentoDestinoId;
                  return ListTile(
                    title: Text(
                      'De: $origemLabel → $destinoLabel',
                    ),
                    subtitle: Text(
                      'Estado: ${h.estadoAnterior} → ${h.estadoNovo}\nMotivo: ${h.motivo}\n${h.observacoes}',
                    ),
                    trailing: Text(
                      '${h.criadoEm.day}/${h.criadoEm.month}/${h.criadoEm.year}',
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: l10n.items_apartment_title,
        subtitle: widget.apartamentoNome,
        icon: Icons.inventory_2_rounded,
        actions: [
          IconButton(
            tooltip: l10n.common_refresh,
            onPressed: () => setState(_loadItems),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: l10n.assets_scan_qr_short,
            onPressed: _scanQrCode,
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<ItemApartamento>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: OwanyTheme.primaryOrange),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final items = snapshot.data ?? [];

          final content = items.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: OwanyTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: OwanyTheme.borderColor(
                            context,
                          ).withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: OwanyTheme.textPrimary(
                              context,
                            ).withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: null, // Disabled - items cannot be edited, only transferred
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // ===== ICON BADGE =====
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.primaryOrange.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getItemIcon(item.nome),
                                    size: 24,
                                    color: OwanyTheme.primaryOrange,
                                  ),
                                ),
                                SizedBox(width: 16),

                                // ===== ITEM INFO =====
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.nome,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: OwanyTheme.textPrimary(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (item.codigoIdentificador !=
                                                  null &&
                                              item
                                                  .codigoIdentificador!
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.qr_code_2_rounded,
                                                    size: 16,
                                                    color: OwanyTheme.info,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    item.codigoIdentificador!,
                                                    style: TextStyle(
                                                      color: OwanyTheme.info,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (item.descricao != null &&
                                          item.descricao!.isNotEmpty) ...[
                                        SizedBox(height: 6),
                                        Text(
                                          item.descricao!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: OwanyTheme.textMutedColor(
                                              context,
                                            ),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _infoChip(
                                            item.tipo ??
                                                AppLocalizations.of(
                                                  context,
                                                )!.items_type_not_informed,
                                            OwanyTheme.primaryOrange.withValues(
                                              alpha: 0.15,
                                            ),
                                            OwanyTheme.primaryOrange,
                                          ),
                                          _infoChip(
                                            'Qtd: ${item.quantidade ?? 1}',
                                            OwanyTheme.info.withValues(
                                              alpha: 0.12,
                                            ),
                                            OwanyTheme.info,
                                          ),
                                          if (item.valorEstimado != null)
                                            _infoChip(
                                              'MZN ${item.valorEstimado!.toStringAsFixed(2)}',
                                              OwanyTheme.warning.withValues(
                                                alpha: 0.15,
                                              ),
                                              OwanyTheme.warning,
                                            ),
                                          if (item.status != null)
                                            _infoChip(
                                              estadoToUiLabel(
                                                estadoFromString(item.status),
                                              ),
                                              _estadoColor(
                                                item.status,
                                              ).withValues(alpha: 0.15),
                                              _estadoColor(item.status),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),

                                // ===== ACTIONS =====
                                // Only transfer allowed - no edit or delete
                                if (_canManage)
                                  ElevatedButton.icon(
                                    onPressed: () => _showTransferDialog(item),
                                    icon: const Icon(
                                      Icons.compare_arrows_rounded,
                                      size: 16,
                                    ),
                                    label: Text(l10n.items_transfer_button),
                                    style: OwanyTheme.primaryButtonStyle().copyWith(
                                      padding: WidgetStateProperty.all(
                                        const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right,
                                    color: OwanyTheme.textMutedColor(
                                      context,
                                    ).withValues(alpha: 0.4),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

          return RefreshIndicator(
            color: OwanyTheme.primaryOrange,
            onRefresh: () async {
              setState(() => _loadItems());
              // give FutureBuilder a tick to rebuild
              await Future.delayed(const Duration(milliseconds: 250));
            },
            child: content,
          );
        },
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              heroTag: 'manage_items_fab',
              backgroundColor: OwanyTheme.primaryOrange,
              onPressed: _isCreating ? null : () => _showVincularItemDisponivel(),
              icon: Icon(
                Icons.link_rounded,
                color: OwanyTheme.cardColor(context),
                size: 24,
              ),
              label: Text(
                l10n.assets_link,
                style: TextStyle(
                  color: OwanyTheme.cardColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _showVincularItemDisponivel() async {
    // Buscar todos os itens e filtrar os que NÃO estão vinculados a apartamento (Em Stock)
    List<ItemApartamento> itensSemVinculo = [];
    bool carregando = true;
    String? erroCarregamento;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (carregando) {
            // Carregar itens disponíveis (sem apartamento vinculado = Em Stock)
            _apiService
                .getTodosItensApartamento()
                .then((todosItens) {
                  final disponiveis = todosItens
                      .where(
                        (item) =>
                            item.apartamentoId == null ||
                            item.apartamentoId!.isEmpty,
                      )
                      .toList();
                  setDialogState(() {
                    itensSemVinculo = disponiveis;
                    carregando = false;
                  });
                })
                .catchError((e) {
                  setDialogState(() {
                    erroCarregamento = e.toString();
                    carregando = false;
                  });
                });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
              decoration: BoxDecoration(
                color: OwanyTheme.cardColor(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OwanyTheme.info,
                          OwanyTheme.info.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: OwanyTheme.cardColor(context),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Itens em Stock',
                                style: TextStyle(
                                  color: OwanyTheme.cardColor(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Selecione um item disponível para vincular',
                                style: TextStyle(
                                  color: OwanyTheme.cardColor(
                                    context,
                                  ).withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: OwanyTheme.cardColor(context),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Flexible(
                    child: carregando
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: OwanyTheme.primaryOrange,
                              ),
                            ),
                          )
                        : erroCarregamento != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: OwanyTheme.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Erro ao carregar itens',
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : itensSemVinculo.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 36,
                                    color: OwanyTheme.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum item em Stock disponível',
                                  style: TextStyle(
                                    color: OwanyTheme.textMutedColor(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cadastre itens na Gestão de Ativos primeiro',
                                  style: TextStyle(
                                    color: OwanyTheme.textMutedColor(context),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: itensSemVinculo.length,
                            itemBuilder: (context, index) {
                              final item = itensSemVinculo[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: OwanyTheme.cardColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: OwanyTheme.borderColor(context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: OwanyTheme.primaryBrown.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: OwanyTheme.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _getItemIcon(item.nome),
                                            color: OwanyTheme.success,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.nome,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: OwanyTheme.textPrimary(context),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  if (item.codigoPatrimonio != null && item.codigoPatrimonio!.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: OwanyTheme.surfaceColor(context),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: OwanyTheme.borderColor(context)),
                                                      ),
                                                      child: Text(
                                                        item.codigoPatrimonio!,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontFamily: 'monospace',
                                                          color: OwanyTheme.textMutedColor(context),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Text(
                                                      item.tipo ?? 'Sem tipo',
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
                                        Container(
                                          decoration: BoxDecoration(
                                            color: OwanyTheme.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: OwanyTheme.success.withValues(alpha: 0.3)),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.link_rounded,
                                              color: OwanyTheme.success,
                                              size: 20,
                                            ),
                                            tooltip: _tx('Vincular item', 'Link item'),
                                            onPressed: () async {
                                      try {
                                        await _apiService
                                            .transferirItemApartamento({
                                              'itemId': item.id,
                                              'apartamentoDestinoId':
                                                  widget.apartamentoId,
                                            });
                                        if (mounted) {
                                          Navigator.pop(context);
                                          _loadItems();
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            OwanyTheme.snackBar(
                                              'Item "${item.nome}" vinculado com sucesso!',
                                              type: SnackBarType.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            OwanyTheme.snackBar(
                                              'Erro ao vincular item: $e',
                                              type: SnackBarType.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

  Widget _buildErrorState(Object? error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: OwanyTheme.error,
              ),
            ),
            SizedBox(height: 24),
            Text(
              l10n.items_load_error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              l10n.items_check_connection,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 13,
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: PrimaryButton.primary(
                    text: l10n.common_retry,
                    onPressed: () {
                      setState(() => _loadItems());
                    },
                    icon: Icons.refresh_rounded,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton.secondary(
                    text: l10n.items_view_details,
                    onPressed: () => _showErrorDetails(error),
                    icon: Icons.info_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDetails(Object? error) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: OwanyTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.items_error_details_title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OwanyTheme.softOrange,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OwanyTheme.borderColor(context)),
                ),
                child: Text(
                  '${error ?? l10n.items_unknown_error}',
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.items_close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: OwanyTheme.primaryOrange,
              ),
            ),
            SizedBox(height: 24),
            Text(
              l10n.items_empty_title,
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              l10n.items_empty_subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            PrimaryButton.primary(
              text: 'Vincular Item em Stock',
              onPressed: !_canManage ? null : () => _showVincularItemDisponivel(),
              icon: Icons.link_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
