import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../dto/area_tecnica_dto.dart';
import '../../models/dtos_complementares.dart';
import '../../providers/manutencao_preventiva_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../widgets/standard_glass_app_bar.dart';

class ManutencaoPreventivaFormScreen extends StatefulWidget {
  final String? manutencaoId; // null = criar, valor = editar

  const ManutencaoPreventivaFormScreen({super.key, this.manutencaoId});

  @override
  State<ManutencaoPreventivaFormScreen> createState() =>
      _ManutencaoPreventivaFormScreenState();
}

class _ManutencaoPreventivaFormScreenState
    extends State<ManutencaoPreventivaFormScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _fornecedorController;
  late TextEditingController _telefoneFornecedorController;
  late TextEditingController _custoEstimadoController;

  DateTime? _proximaManutencao;
  String? _tipoSelecionadoId;
  String? _areaSelecionadoId; // ID da AreaTecnica selecionada (opcional)
  String? _frequencia; // Tornada opcional para manutenções pontuais
  bool _ativa = true;
  bool _isSaving = false;
    static final FilteringTextInputFormatter _moneyInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'));

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
  }

  double? _parseMzn(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _resolverTipoBackend({
    required SolicitacoesProvider tiposProvider,
    required String? tipoSolicitacaoNome,
    required String? areaSelecionadoId,
  }) {
    String areaNome = '';
    if (areaSelecionadoId != null && areaSelecionadoId.isNotEmpty) {
      for (final a in tiposProvider.areasTecnicas) {
        if (a.id == areaSelecionadoId) {
          areaNome = a.nome;
          break;
        }
      }
    }

    final base = '${tipoSolicitacaoNome ?? ''} $areaNome'.trim();
    final n = _normalizeToken(base);

    if (n.contains('hidraul')) return 'Hidraulica';
    if (n.contains('eletric')) return 'Eletrica';
    if (n.contains('limpez')) return 'Limpeza';
    if (n.contains('jardim') || n.contains('irrig')) return 'Jardim';
    if (n.contains('pintur')) return 'Pintura';
    if (n.contains('imperme')) return 'Impermeabilizacao';
    if (n.contains('incend')) return 'Incendio';
    if (n.contains('interfone')) return 'Interfone';
    if (n.contains('portao')) return 'PortaoAutomatico';
    if (n.contains('elevador')) return 'Elevador';
    if (n.contains('bomba') && n.contains('agua')) return 'BombaAgua';
    if (n.contains('ar condicionado') ||
        n.contains('climat') ||
        n.contains('ventila')) {
      return 'ArCondicionado';
    }
    if (n.contains('eletron') ||
        n.contains('cftv') ||
        n.contains('seguranca') ||
        n.contains('automacao')) {
      return 'CFTV';
    }

    return 'Outros';
  }

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _descricaoController = TextEditingController();
    _fornecedorController = TextEditingController();
    _telefoneFornecedorController = TextEditingController();
    _custoEstimadoController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tiposProvider = context.read<SolicitacoesProvider>();
      if (tiposProvider.tiposSolicitacao.isEmpty &&
          !tiposProvider.isLoadingTipos) {
        await Future.wait([
          tiposProvider.loadTipos(),
          tiposProvider.loadAreas(),
        ]);
      }

      if (widget.manutencaoId != null) {
        await _carregarDados();
      }
    });
  }

  Future<void> _carregarDados() async {
    final provider = context.read<ManutencaoPreventivaProvider>();
    await provider.carregarManutencao(widget.manutencaoId!);

    if (mounted && provider.manutencaoAtual != null) {
      final m = provider.manutencaoAtual!;
      _tituloController.text = m.titulo;
      _descricaoController.text = m.descricao ?? '';
      _fornecedorController.text = m.fornecedor ?? '';
      _telefoneFornecedorController.text = m.telefoneFornecedor ?? '';
      _custoEstimadoController.text = m.custoEstimado?.toString() ?? '';
      _proximaManutencao = m.proximaManutencao;
      _frequencia = m.frequencia.isNotEmpty ? m.frequencia : null;
      _ativa = m.ativa;

      final tiposProvider = context.read<SolicitacoesProvider>();
      String? tipoIdEncontrado;
      for (final t in tiposProvider.tiposSolicitacao) {
        if (t.nome.trim().toLowerCase() == m.tipo.trim().toLowerCase()) {
          tipoIdEncontrado = t.id;
          break;
        }
      }
      _tipoSelecionadoId = tipoIdEncontrado;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _fornecedorController.dispose();
    _telefoneFornecedorController.dispose();
    _custoEstimadoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    if (_tituloController.text.trim().isEmpty) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(
          l10n.mp_form_title_required,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (_proximaManutencao == null) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(
          l10n.mp_form_next_maintenance_required,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    if (_tipoSelecionadoId == null || _tipoSelecionadoId!.isEmpty) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(
          'Selecione o tipo de manutenção',
          type: SnackBarType.error,
        ),
      );
      return;
    }

    final tiposProvider = context.read<SolicitacoesProvider>();
    String? tipoSelecionadoNome;
    for (final tipo in tiposProvider.tiposSolicitacao) {
      if (tipo.id == _tipoSelecionadoId) {
        tipoSelecionadoNome = tipo.nome;
        break;
      }
    }

    if (tipoSelecionadoNome == null || tipoSelecionadoNome.trim().isEmpty) {
      messenger.showSnackBar(
        OwanyTheme.snackBar(
          'Tipo de manutenção inválido',
          type: SnackBarType.error,
        ),
      );
      return;
    }

    final tipoBackend = _resolverTipoBackend(
      tiposProvider: tiposProvider,
      tipoSolicitacaoNome: tipoSelecionadoNome.trim(),
      areaSelecionadoId: _areaSelecionadoId,
    );

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ManutencaoPreventivaProvider>();
      final custoEstimadoTexto = _custoEstimadoController.text.trim();
      final custoEstimado = _parseMzn(custoEstimadoTexto);
      if (custoEstimadoTexto.isNotEmpty && custoEstimado == null) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          OwanyTheme.snackBar(
            'Informe um custo estimado válido em MZN.',
            type: SnackBarType.error,
          ),
        );
        return;
      }
      bool sucesso = false;

      if (widget.manutencaoId != null) {
        // Editar
        sucesso = await provider.atualizarManutencao(
          widget.manutencaoId!,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          tipo: tipoBackend,
          frequencia: _frequencia?.trim().isNotEmpty == true ? _frequencia : null,
          proximaManutencao: _proximaManutencao!,
          ativa: _ativa,
          fornecedor: _fornecedorController.text.trim().isEmpty
              ? null
              : _fornecedorController.text.trim(),
          telefoneFornecedor: _telefoneFornecedorController.text.trim().isEmpty
              ? null
              : _telefoneFornecedorController.text.trim(),
          custoEstimado: custoEstimado,
        );
      } else {
        // Criar
        final novaId = await provider.criarManutencao(
          CriarManutencaoPreventivaRequest(
            titulo: _tituloController.text.trim(),
            descricao: _descricaoController.text.trim(),
            tipo: tipoBackend,
            frequencia: _frequencia?.trim().isNotEmpty == true ? _frequencia!.trim() : null,
            proximaManutencao: _proximaManutencao!,
            custoEstimado: custoEstimado,
            fornecedor: _fornecedorController.text.trim().isEmpty
                ? null
                : _fornecedorController.text.trim(),
            telefoneFornecedor:
                _telefoneFornecedorController.text.trim().isEmpty
                ? null
                : _telefoneFornecedorController.text.trim(),
            tipoSolicitacaoId: _tipoSelecionadoId,
            areaTecnicaId: _areaSelecionadoId,
          ),
        );
        sucesso = novaId != null;
      }

      if (!mounted) return;

      if (sucesso) {
        messenger.showSnackBar(
          OwanyTheme.snackBar(
            widget.manutencaoId != null
                ? l10n.mp_form_updated_success
                : l10n.mp_form_created_success,
            type: SnackBarType.success,
          ),
        );
        nav.pop(true);
      } else {
        messenger.showSnackBar(
          OwanyTheme.snackBar(
            provider.erro ?? l10n.mp_form_save_error,
            type: SnackBarType.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          OwanyTheme.snackBar(
            '${l10n.common_error}: ${e.toString()}',
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.manutencaoId != null;
    final solicitacoesProvider = context.watch<SolicitacoesProvider>();

    return Scaffold(
      appBar: StandardGlassAppBar(
        title: isEditing ? l10n.mp_form_edit_title : l10n.mp_form_new_title,
        icon: isEditing ? Icons.edit_rounded : Icons.add_rounded,
        showBackButton: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                _buildFieldLabel('${l10n.mp_title} *'),
                SizedBox(height: 8),
                TextField(
                  controller: _tituloController,
                  decoration: _buildInputDecoration(l10n.mp_form_title_hint),
                  maxLength: 160,
                  enabled: !_isSaving,
                ),
                SizedBox(height: 16),

                // Tipo
                _buildFieldLabel('${l10n.mp_form_maintenance_type} *'),
                SizedBox(height: 8),
                _buildTipoSelector(solicitacoesProvider, l10n),
                SizedBox(height: 16),

                // Frequência (opcional)
                _buildFieldLabel(l10n.mp_frequency),
                SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _frequencia,
                  items: _getFrequencyItems(l10n),
                  onChanged: _isSaving
                      ? null
                      : (v) => setState(() => _frequencia = v),
                  decoration: _buildInputDecoration(
                    l10n.mp_form_select_frequency,
                  ),
                ),
                SizedBox(height: 16),

                // Área Técnica (opcional)
                _buildFieldLabel('Área técnica (opcional)'),
                SizedBox(height: 8),
                _buildAreaSelector(solicitacoesProvider),
                SizedBox(height: 16),

                // Próxima Manutenção
                _buildFieldLabel('${l10n.mp_next_maintenance} *'),
                SizedBox(height: 8),
                InkWell(
                  onTap: _isSaving
                      ? null
                      : () async {
                          final data = await showDatePicker(
                            context: context,
                            initialDate:
                                _proximaManutencao ??
                                DateTime.now().add(Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (data != null) {
                            setState(() => _proximaManutencao = data);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: OwanyTheme.backgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: OwanyTheme.borderColor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: OwanyTheme.primaryOrange,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _proximaManutencao != null
                                ? '${_proximaManutencao!.day}/${_proximaManutencao!.month}/${_proximaManutencao!.year}'
                                : l10n.mp_form_select_date,
                            style: TextStyle(
                              color: _proximaManutencao != null
                                  ? OwanyTheme.textPrimary(context)
                                  : OwanyTheme.textMutedColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Descrição
                _buildFieldLabel(l10n.mp_description),
                SizedBox(height: 8),
                TextField(
                  controller: _descricaoController,
                  decoration: _buildInputDecoration(
                    l10n.mp_form_description_hint,
                  ),
                  minLines: 3,
                  maxLines: 5,
                  enabled: !_isSaving,
                ),
                SizedBox(height: 16),

                // Fornecedor
                _buildFieldLabel(l10n.mp_supplier),
                SizedBox(height: 8),
                TextField(
                  controller: _fornecedorController,
                  decoration: _buildInputDecoration(l10n.mp_form_supplier_hint),
                  enabled: !_isSaving,
                ),
                SizedBox(height: 16),

                // Telefone Fornecedor
                _buildFieldLabel(l10n.mp_form_supplier_phone),
                SizedBox(height: 8),
                TextField(
                  controller: _telefoneFornecedorController,
                  decoration: _buildInputDecoration('+258 XX XXX XXXX'),
                  keyboardType: TextInputType.phone,
                  enabled: !_isSaving,
                ),
                SizedBox(height: 16),

                // Custo Estimado
                _buildFieldLabel(l10n.mp_estimated_cost),
                SizedBox(height: 8),
                TextFormField(
                  controller: _custoEstimadoController,
                  decoration: _buildInputDecoration(
                    'Formato: 50,000 MZN ou 50.000',
                  ).copyWith(prefixText: 'MZN '),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  enabled: !_isSaving,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = _parseMzn(value);
                    if (parsed == null) {
                      return 'Informe um valor válido. Ex: 50,000 ou 50.000';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _ativa
                        ? OwanyTheme.success.withValues(alpha: 0.1)
                        : OwanyTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ativa
                          ? OwanyTheme.success.withValues(alpha: 0.3)
                          : OwanyTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mp_status,
                              style: TextStyle(
                                fontSize: 12,
                                color: OwanyTheme.textMutedColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _ativa ? l10n.mp_active : l10n.mp_inactive,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _ativa
                                    ? OwanyTheme.success
                                    : OwanyTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _ativa,
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _ativa = v),
                        activeThumbColor: OwanyTheme.success,
                        inactiveThumbColor: OwanyTheme.error.withValues(
                          alpha: 0.7,
                        ),
                        inactiveTrackColor: OwanyTheme.error.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            l10n.common_cancel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: OwanyTheme.textMutedColor(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OwanyTheme.success,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _isSaving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      OwanyTheme.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? l10n.common_update
                                      : l10n.action_create,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: OwanyTheme.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  List<DropdownMenuItem<String?>> _getFrequencyItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(_tx('Manutenção pontual/única', 'One-time maintenance')),
      ),
      DropdownMenuItem(value: 'Semanal', child: Text(l10n.mp_form_freq_weekly)),
      DropdownMenuItem(value: 'Mensal', child: Text(l10n.mp_form_freq_monthly)),
      DropdownMenuItem(
        value: 'Trimestral',
        child: Text(l10n.mp_form_freq_quarterly),
      ),
      DropdownMenuItem(
        value: 'Semestral',
        child: Text(l10n.mp_form_freq_semiannually),
      ),
      DropdownMenuItem(value: 'Anual', child: Text(l10n.mp_form_freq_annually)),
    ];
  }

  Widget _buildTipoSelector(
    SolicitacoesProvider provider,
    AppLocalizations l10n,
  ) {
    if (provider.isLoadingTipos && provider.tiposSolicitacao.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: OwanyTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwanyTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  OwanyTheme.primaryOrange,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _tx('Carregando tipos...', 'Loading types...'),
              style: TextStyle(color: OwanyTheme.textMutedColor(context)),
            ),
          ],
        ),
      );
    }

    if (provider.erroTipos != null && provider.tiposSolicitacao.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: OwanyTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: OwanyTheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tx('Erro ao carregar tipos', 'Error loading types'),
                style: TextStyle(color: OwanyTheme.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => Future.wait([
                      provider.loadTipos(refresh: true),
                      provider.loadAreas(refresh: true),
                    ]),
              child: Text(_tx('Tentar novamente', 'Try again')),
            ),
          ],
        ),
      );
    }

    final hasSelectedValue = provider.tiposSolicitacao.any(
      (t) => t.id == _tipoSelecionadoId,
    );
    final selectedValue = hasSelectedValue ? _tipoSelecionadoId : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      onChanged: _isSaving
          ? null
          : (v) => setState(() => _tipoSelecionadoId = v),
      decoration: _buildInputDecoration(l10n.mp_form_type_hint),
      hint: Text(l10n.mp_form_type_hint),
      items: provider.tiposSolicitacao
          .map(
            (tipo) => DropdownMenuItem<String>(
              value: tipo.id,
              child: Text(tipo.nome, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: OwanyTheme.textPrimary(context),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: OwanyTheme.backgroundColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OwanyTheme.borderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OwanyTheme.borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OwanyTheme.primaryOrange, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildAreaSelector(SolicitacoesProvider provider) {
    final List<AreaTecnicaDto> available = _tipoSelecionadoId != null
        ? provider.getAreasForTipo(_tipoSelecionadoId!)
        : provider.areasTecnicas;

    if ((provider.isLoadingAreas && available.isEmpty) ||
        (provider.isLoadingTipos && provider.tiposSolicitacao.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: _areaSelecionadoId,
      isExpanded: true,
      items: available
          .map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.nome, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _isSaving
          ? null
          : (v) => setState(() => _areaSelecionadoId = v),
      decoration: _buildInputDecoration('Selecione a área técnica'),
    );
  }
}
