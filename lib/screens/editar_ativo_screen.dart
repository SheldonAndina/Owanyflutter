// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dto/item_apartamento_dto.dart';
import '../dto/item_estado_enums.dart';
import '../generated_l10n/app_localizations.dart';
import '../providers/itens_provider.dart';
import '../theme/owany_theme.dart';
import '../widgets/standard_glass_app_bar.dart';

/// Tela de edição de ativo patrimonial (PREMIUM VERSION)
/// Utiliza ItensProvider para carregar e atualizar o item com validação visual
class EditarAtivoScreen extends StatefulWidget {
  final String itemId;
  const EditarAtivoScreen({super.key, required this.itemId});

  @override
  State<EditarAtivoScreen> createState() => _EditarAtivoScreenState();
}

class _EditarAtivoScreenState extends State<EditarAtivoScreen> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _valorEstimadoCtrl;
  late final TextEditingController _observacoesCtrl;
  
  DateTime? _dataAquisicao;
  DateTime? _dataEntrada;
  EstadoFisicoItem _estadoFisico = EstadoFisicoItem.disponivel;

  bool _loading = true;
  bool _saving = false;
  ItemApartamentoDto? _item;
  Map<String, dynamic> _originalValues = {};

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  String _estadoFisicoLabel(EstadoFisicoItem estado) {
    if (!Localizations.localeOf(context).languageCode.toLowerCase().startsWith('en')) {
      return estado.toPortuguese();
    }
    switch (estado) {
      case EstadoFisicoItem.disponivel:
        return 'Available';
      case EstadoFisicoItem.danificado:
        return 'Damaged';
      case EstadoFisicoItem.emManutencao:
        return 'Under Maintenance';
      case EstadoFisicoItem.inutilizado:
        return 'Out of Service';
      case EstadoFisicoItem.extraviado:
        return 'Missing';
    }
  }

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _descricaoCtrl = TextEditingController();
    _tipoCtrl = TextEditingController();
    _quantidadeCtrl = TextEditingController(text: '1');
    _valorEstimadoCtrl = TextEditingController();
    _observacoesCtrl = TextEditingController();
    _carregarItem();
  }

  Future<void> _carregarItem() async {
    try {
      final provider = context.read<ItensProvider>();
      await provider.carregarItem(widget.itemId);
      
      final item = provider.itemAtual;
      if (item != null) {
        _item = item;
        _nomeCtrl.text = item.nome;
        _descricaoCtrl.text = item.descricao ?? '';
        _tipoCtrl.text = item.tipo ?? '';
        _quantidadeCtrl.text = '${item.quantidade}';
        _valorEstimadoCtrl.text = item.valorEstimado?.toStringAsFixed(2) ?? '';
        _observacoesCtrl.text = item.observacoes ?? '';
        _dataAquisicao = item.dataAquisicao;
        _dataEntrada = item.dataEntrada;
        
        // Parse estado físico
        _estadoFisico = EstadoFisicoItemExtension.fromString(item.estadoFisico);
        
        // Backup de valores originais para détecção de mudanças
        _originalValues = {
          'nome': item.nome,
          'descricao': item.descricao,
          'tipo': item.tipo,
          'quantidade': item.quantidade,
          'valorEstimado': item.valorEstimado,
          'estadoFisico': item.estadoFisico,
          'dataAquisicao': item.dataAquisicao,
          'dataEntrada': item.dataEntrada,
          'observacoes': item.observacoes,
        };
      }
    } catch (e) {
      debugPrint('[EditarAtivo] Erro ao carregar item: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _tipoCtrl.dispose();
    _quantidadeCtrl.dispose();
    _valorEstimadoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? current,
    ValueChanged<DateTime> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.assets_field_name_required)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<ItensProvider>();
      
      final request = AtualizarItemRequest(
        nome: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim().isEmpty ? null : _descricaoCtrl.text.trim(),
        tipo: _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
        quantidade: int.tryParse(_quantidadeCtrl.text.trim()),
        valorEstimado: double.tryParse(_valorEstimadoCtrl.text.trim().replaceAll(',', '.')),
        estadoFisico: _estadoFisico.valor,
        dataAquisicao: _dataAquisicao,
        dataEntrada: _dataEntrada,
        observacoes: _observacoesCtrl.text.trim().isEmpty ? null : _observacoesCtrl.text.trim(),
      );
      
      final ok = await provider.atualizarItem(widget.itemId, request);
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assets_asset_updated)),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.erro ?? l10n.common_error)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final df = DateFormat('dd/MM/yyyy');
    final hasMudancas = _hasMudancas();

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: l10n.assets_edit_asset,
        subtitle: l10n.assets_management_title,
        icon: Icons.edit_note_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopHeaderCard(hasMudancas),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: _tx('Identificação', 'Identification'),
                          icon: Icons.badge_outlined,
                          children: [
                            TextFormField(
                              initialValue: _item?.codigoPatrimonio ?? '',
                              readOnly: true,
                                decoration: OwanyTheme.adaptiveInputDecoration(
                                  context,
                                  label: _tx('Código Patrimônio', 'Asset Code'),
                                  icon: Icons.qr_code_rounded,
                                ).copyWith(
                                filled: true,
                                fillColor: OwanyTheme.surfaceColor(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nomeCtrl,
                              decoration: OwanyTheme.adaptiveInputDecoration(
                                context,
                                label: _tx('Nome *', 'Name *'),
                                icon: Icons.inventory_2_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _tipoCtrl,
                              decoration: OwanyTheme.adaptiveInputDecoration(
                                context,
                                label: l10n.assets_field_type,
                                icon: Icons.category_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _descricaoCtrl,
                              decoration: OwanyTheme.adaptiveInputDecoration(
                                context,
                                label: l10n.assets_field_description,
                                icon: Icons.description_outlined,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: _tx('Valores e Estoque', 'Values and Stock'),
                          icon: Icons.monetization_on_outlined,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _quantidadeCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: OwanyTheme.adaptiveInputDecoration(
                                      context,
                                      label: l10n.assets_field_quantity,
                                      icon: Icons.numbers_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextField(
                                    controller: _valorEstimadoCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: OwanyTheme.adaptiveInputDecoration(
                                      context,
                                      label: _tx('Valor estimado', 'Estimated value'),
                                      icon: Icons.attach_money_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<EstadoFisicoItem>(
                              value: _estadoFisico,
                              decoration: OwanyTheme.adaptiveInputDecoration(
                                context,
                                label: _tx('Estado físico', 'Physical status'),
                                icon: Icons.info_outline_rounded,
                              ),
                              items: EstadoFisicoItem.values
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(_estadoFisicoLabel(e)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _estadoFisico = v ?? _estadoFisico,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: _tx('Datas', 'Dates'),
                          icon: Icons.calendar_month_outlined,
                          children: [
                            InkWell(
                              onTap: () => _pickDate(
                                context,
                                _dataAquisicao,
                                (d) => setState(() => _dataAquisicao = d),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: OwanyTheme.adaptiveInputDecoration(
                                  context,
                                  label: _tx('Data de aquisição', 'Acquisition date'),
                                  icon: Icons.calendar_today_outlined,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dataAquisicao != null
                                          ? df.format(_dataAquisicao!)
                                          : _tx('Não definido', 'Not set'),
                                      style: TextStyle(
                                        color: _dataAquisicao != null
                                            ? OwanyTheme.textPrimary(context)
                                            : OwanyTheme.textMutedColor(context),
                                      ),
                                    ),
                                    if (_dataAquisicao != null)
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _dataAquisicao = null,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color:
                                              OwanyTheme.textMutedColor(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () => _pickDate(
                                context,
                                _dataEntrada,
                                (d) => setState(() => _dataEntrada = d),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: OwanyTheme.adaptiveInputDecoration(
                                  context,
                                  label: _tx('Data de entrada', 'Entry date'),
                                  icon: Icons.home_outlined,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dataEntrada != null
                                          ? df.format(_dataEntrada!)
                                          : _tx('Não definido', 'Not set'),
                                      style: TextStyle(
                                        color: _dataEntrada != null
                                            ? OwanyTheme.textPrimary(context)
                                            : OwanyTheme.textMutedColor(context),
                                      ),
                                    ),
                                    if (_dataEntrada != null)
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _dataEntrada = null),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color:
                                              OwanyTheme.textMutedColor(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: _tx('Observações', 'Notes'),
                          icon: Icons.notes_rounded,
                          children: [
                            TextField(
                              controller: _observacoesCtrl,
                              decoration: OwanyTheme.adaptiveInputDecoration(
                                context,
                                label: l10n.assets_field_observations,
                                icon: Icons.notes_rounded,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildBottomActions(l10n: l10n, hasMudancas: hasMudancas),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeaderCard(bool hasMudancas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.primaryBrown,
            OwanyTheme.primaryBrown.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: OwanyTheme.isDark(context)
            ? []
            : [
                BoxShadow(
                  color: OwanyTheme.primaryBrown.withOpacity(0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _item?.nome ?? _tx('Editar ativo', 'Edit asset'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_tx('Código', 'Code')} ${_item?.codigoPatrimonio ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.78),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (hasMudancas)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: OwanyTheme.primaryOrange.withOpacity(0.5),
                ),
              ),
              child: Text(
                _tx('Não salvo', 'Unsaved'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions({
    required AppLocalizations l10n,
    required bool hasMudancas,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                l10n.common_cancel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: OwanyTheme.primaryBrown,
                side: BorderSide(color: OwanyTheme.primaryBrown.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: OwanyTheme.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _saving ? l10n.common_saving : l10n.common_save,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onPressed: (_saving || !hasMudancas) ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: OwanyTheme.primaryOrange.withOpacity(0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: OwanyTheme.isDark(context)
            ? []
            : [
                BoxShadow(
                  color: OwanyTheme.primaryBrown.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(icon, size: 14, color: OwanyTheme.primaryOrange),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  bool _hasMudancas() {
    if (_item == null || _originalValues.isEmpty) return false;
    
    return _nomeCtrl.text.trim() != (_originalValues['nome'] ?? '') ||
        _descricaoCtrl.text.trim() != (_originalValues['descricao'] ?? '') ||
        _tipoCtrl.text.trim() != (_originalValues['tipo'] ?? '') ||
        int.tryParse(_quantidadeCtrl.text.trim()) != _originalValues['quantidade'] ||
        double.tryParse(_valorEstimadoCtrl.text.trim().replaceAll(',', '.')) != _originalValues['valorEstimado'] ||
        _estadoFisico.valor != _originalValues['estadoFisico'] ||
        _dataAquisicao != _originalValues['dataAquisicao'] ||
        _dataEntrada != _originalValues['dataEntrada'] ||
        _observacoesCtrl.text.trim() != (_originalValues['observacoes'] ?? '');
  }

}
