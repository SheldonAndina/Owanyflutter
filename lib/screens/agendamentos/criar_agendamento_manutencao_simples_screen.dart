import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../theme/owany_theme.dart';
import '../../dto/area_tecnica_dto.dart';
import '../../providers/agendamentos_provider.dart';
import '../../providers/usuarios_provider.dart';
import '../../providers/manutencao_preventiva_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../generated_l10n/app_localizations.dart';

/// Minimal screen to create a maintenance appointment (agendamento)
class CriarAgendamentoManutencaoSimplesScreen extends StatefulWidget {
  const CriarAgendamentoManutencaoSimplesScreen({super.key});

  @override
  State<CriarAgendamentoManutencaoSimplesScreen> createState() => _CriarAgendamentoState();
}

class _CriarAgendamentoState extends State<CriarAgendamentoManutencaoSimplesScreen> {
  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _descricao = TextEditingController();
  TipoManutencao? _tipoManutencaoSelecionado;
  final TextEditingController _duracaoController = TextEditingController(text: '1');
  final TextEditingController _fornecedorController = TextEditingController();
  final TextEditingController _telefoneFornecedorController = TextEditingController();
  final TextEditingController _custoEstimadoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final _phoneMaskFormatter = MaskTextInputFormatter(mask: '+258 ##-#######');

  DateTime? _data;
  String? _hora;
  String? _apartamentoId;
  String? _responsavelId;
  bool _isSubmitting = false;
  String? _tipoSolicitacaoId;
  String? _areaSelecionadoId;

  List<Map<String, String>> _apartamentos = [];
  List<Map<String, String>> _itensApartamento = [];
  String? _itemApartamentoSelecionadoId;
  List<Usuario> _funcionarios = [];
  

  final List<String> _horas = [
    '08:00','09:00','10:00','11:00','13:00','14:00','15:00','16:00'
  ];

  @override
  void initState() {
    super.initState();
    _data = DateTime.now().add(const Duration(days: 1));
    // Carregar dados após o frame para garantir que os providers estejam disponíveis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApartamentos();
      _loadFuncionarios();
      final prov = context.read<SolicitacoesProvider>();
      prov.loadTipos();
      prov.loadAreas();
    });
  }

  double? _parseDecimal(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final normalized = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _loadApartamentos() async {
    try {
      final prov = context.read<ManutencaoPreventivaProvider>();
      final lista = await prov.buscarApartamentosDisponiveis();
      setState(() {
        _apartamentos = lista.map((e) => {'id': e['id'] as String, 'nome': '${e['numero']} - ${e['bloco'] ?? ''}'}).toList();
        if (_apartamentos.isNotEmpty) {
          _apartamentoId = _apartamentos.first['id'];
        }
      });
      await _loadItensApartamento();
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar apartamentos: $e');
    }
  }

  Future<void> _loadItensApartamento() async {
    if (_apartamentoId == null || _apartamentoId!.isEmpty) return;
    try {
      final itens = await ApiService().getItensApartamento(_apartamentoId!);
      if (!mounted) return;
      setState(() {
        _itensApartamento = itens
            .map((i) => {
                  'id': i.id,
                  'nome': i.nome ?? i.codigoPatrimonio ?? 'Item',
                })
            .toList();
        _itemApartamentoSelecionadoId = null; // item é opcional
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar itens do apartamento: $e');
      if (!mounted) return;
      setState(() {
        _itensApartamento = [];
        _itemApartamentoSelecionadoId = null;
      });
    }
  }

  Future<void> _loadFuncionarios() async {
    try {
      final usuarios = await context.read<UsuariosProvider>().carregarFuncionariosComRetorno();
      if (!mounted) return;
      setState(() {
        _funcionarios = usuarios;
        if (_funcionarios.isNotEmpty) _responsavelId = _funcionarios.first.id;
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar funcionários: $e');
      // Retry once after a short delay
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      try {
        final usuarios = await context.read<UsuariosProvider>().carregarFuncionariosComRetorno();
        if (!mounted) return;
        setState(() {
          _funcionarios = usuarios;
          if (_funcionarios.isNotEmpty) _responsavelId = _funcionarios.first.id;
        });
      } catch (e2) {
        debugPrint('⚠️ Retry falhou ao carregar funcionários: $e2');
      }
    }
  }

  /// Valida se a string é um GUID válido (formato: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  bool _isValidGuid(String value) {
    if (value.isEmpty) return false;
    final guidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return guidRegex.hasMatch(value.trim());
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    // _tipoController removed; nothing to dispose here
    _duracaoController.dispose();
    _fornecedorController.dispose();
    _telefoneFornecedorController.dispose();
    _custoEstimadoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (_titulo.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.agendamentos_title_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_apartamentoId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.agendamentos_location_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_data == null || _hora == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.agendamentos_date_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_responsavelId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.agendamentos_responsible_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_tipoSolicitacaoId == null || _tipoSolicitacaoId!.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Selecione o tipo de solicitação.'), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_areaSelecionadoId == null || _areaSelecionadoId!.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Selecione a área técnica.'), backgroundColor: OwanyTheme.error));
      return false;
    }
    final duracao = int.tryParse(_duracaoController.text.trim());
    if (duracao == null || duracao <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Informe uma duração válida em horas.'), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_custoEstimadoController.text.trim().isNotEmpty && _parseDecimal(_custoEstimadoController.text) == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Informe um custo estimado válido.'), backgroundColor: OwanyTheme.error));
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nav = Navigator.of(context);
    setState(() => _isSubmitting = true);
    try {
      final horaParts = (_hora ?? '08:00').split(':');
      final hora = int.tryParse(horaParts[0]) ?? 8;
      final minuto = int.tryParse(horaParts[1]) ?? 0;
      final dataAgendada = DateTime(_data!.year, _data!.month, _data!.day, hora, minuto);
      final duracao = int.parse(_duracaoController.text.trim());

      // Usar o itemApartamentoSelecionadoId do dropdown
      final itemApartamentoId = _itemApartamentoSelecionadoId;

      final success = await context.read<AgendamentosProvider>().criarAgendamento(
        apartamentoId: _apartamentoId!,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        areaTecnicaId: _areaSelecionadoId,
        tipoSolicitacaoId: _tipoSolicitacaoId,
        dataAgendada: dataAgendada,
        duracaoEstimadaHoras: duracao,
        responsavelTecnicoId: _responsavelId!,
        fornecedor: _fornecedorController.text.trim().isEmpty ? null : _fornecedorController.text.trim(),
        telefoneFornecedor: _telefoneFornecedorController.text.trim().isEmpty ? null : _telefoneFornecedorController.text.trim(),
        custoEstimado: _parseDecimal(_custoEstimadoController.text),
        observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
        itemApartamentoId: _itemApartamentoSelecionadoId,
      );

      if (success && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.agendamentos_created_success), backgroundColor: OwanyTheme.success));
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.common_error}: $e'),
            backgroundColor: OwanyTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = OwanyTheme.isDark(context);

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(l10n.agendamentos_new_title),
      ),

      // ✅ BOTÃO FIXO MOBILE-FIRST
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: OwanyTheme.primaryButtonStyle(dark: dark),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OwanyTheme.white,
                  ),
                )
              : Text(l10n.agendamentos_create_button),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 HEADER PREMIUM
            Container(
              padding: const EdgeInsets.all(24),
              decoration: OwanyTheme.gradientCardDecoration(
                dark: dark,
                useOrange: true,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OwanyTheme.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: OwanyTheme.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.agendamentos_new_title,
                          style: const TextStyle(
                            color: OwanyTheme.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.agendamentos_schedule_maintenance,
                          style: TextStyle(
                            color: OwanyTheme.white.withValues(alpha: 0.95),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 📍 LOCALIZAÇÃO
            Text(
              l10n.agendamentos_location,
              style: OwanyTheme.titleStyle(context, fontSize: 16),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _apartamentoId,
              items: _apartamentos
                  .map((a) => DropdownMenuItem(
                        value: a['id'],
                        child: Text(a['nome']!),
                      ))
                  .toList(),
              onChanged: (v) async {
                setState(() => _apartamentoId = v);
                await _loadItensApartamento();
              },
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: l10n.agendamentos_location,
                icon: Icons.apartment_rounded,
              ),
            ),

            const SizedBox(height: 24),

            // 🏷️ TIPO DE SOLICITAÇÃO
            Consumer<SolicitacoesProvider>(
              builder: (context, prov, _) {
                final tipos = prov.tiposSolicitacao;
                if (prov.isLoadingTipos && tipos.isEmpty) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                if (tipos.isNotEmpty && (_tipoSolicitacaoId == null || _tipoSolicitacaoId!.isEmpty)) {
                  _tipoSolicitacaoId = tipos.first.id;
                }
                return DropdownButtonFormField<String>(
                  initialValue: _tipoSolicitacaoId,
                  items: tipos
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.nome ?? 'Sem nome'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _tipoSolicitacaoId = v),
                  decoration: OwanyTheme.adaptiveInputDecoration(
                    context,
                    label: 'Tipo de solicitação',
                    icon: Icons.category_outlined,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🛠️ ÁREA TÉCNICA
            Consumer<SolicitacoesProvider>(
              builder: (context, prov, _) => _buildAreaSelector(context, prov),
            ),

            const SizedBox(height: 24),

            // 📝 TÍTULO
            TextFormField(
              controller: _titulo,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: l10n.agendamentos_title_field,
                hint: l10n.agendamentos_title_hint,
                icon: Icons.build_circle_outlined,
              ),
            ),

            const SizedBox(height: 20),

            // 📄 DESCRIÇÃO
            TextFormField(
              controller: _descricao,
              maxLines: 4,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: l10n.agendamentos_description_optional,
                hint: l10n.agendamentos_description_hint,
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 24),


            // �📅 DATA & HORA (BLOCO MAIS BONITO)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: OwanyTheme.subtleCardDecoration(dark: dark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.agendamentos_schedule_section,
                    style: OwanyTheme.titleStyle(context, fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            decoration:
                                OwanyTheme.outlinedCardDecoration(dark: dark),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _data != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_data!)
                                      : l10n.agendamentos_select_date,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _hora,
                          items: _horas
                              .map((h) => DropdownMenuItem(
                                    value: h,
                                    child: Text(h),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _hora = v),
                          decoration: OwanyTheme.adaptiveInputDecoration(
                            context,
                            label: "Hora",
                            icon: Icons.access_time_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _duracaoController,
                    keyboardType: TextInputType.number,
                    decoration: OwanyTheme.adaptiveInputDecoration(
                      context,
                      label: 'Duração estimada (horas)',
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _custoEstimadoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    decoration: OwanyTheme.adaptiveInputDecoration(
                      context,
                      label: 'Custo estimado (MZN)',
                      icon: Icons.payments_outlined,
                      hint: 'Formato: 50,000 MZN ou 50.000',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _fornecedorController,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: 'Fornecedor (opcional)',
                icon: Icons.store_mall_directory_outlined,
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _telefoneFornecedorController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneMaskFormatter],
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: 'Telefone do fornecedor (opcional)',
                icon: Icons.phone_outlined,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String?>(
              initialValue: _itemApartamentoSelecionadoId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nenhum item (opcional)'),
                ),
                ..._itensApartamento.map((i) => DropdownMenuItem<String?>(
                      value: i['id'],
                      child: Text(i['nome'] ?? i['id'] ?? 'Sem nome'),
                    ))
              ],
              onChanged: (v) => setState(() => _itemApartamentoSelecionadoId = v),
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: 'Item do Apartamento (opcional)',
                icon: Icons.inventory_2_outlined,
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: 'Observações (opcional)',
                icon: Icons.sticky_note_2_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // 👨‍🔧 RESPONSÁVEL
            DropdownButtonFormField<String>(
              initialValue: _responsavelId,
              items: _funcionarios
                  .map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.nome),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _responsavelId = v),
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: l10n.agendamentos_responsible,
                icon: Icons.engineering_rounded,
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaSelector(BuildContext context, SolicitacoesProvider provider) {
    // Mostrar todas as áreas técnicas disponíveis (independente do tipo selecionado)
    final List<AreaTecnicaDto> available = provider.areasTecnicas;

    if ((provider.isLoadingAreas && available.isEmpty) || (provider.isLoadingTipos && provider.tiposSolicitacao.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (available.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_areaSelecionadoId == null && available.isNotEmpty) {
      _areaSelecionadoId = available.first.id;
    }

    return DropdownButtonFormField<String>(
      initialValue: _areaSelecionadoId,
      isExpanded: true,
      items: available.map((a) => DropdownMenuItem(
        value: a.id,
        child: Text(a.nome),
      )).toList(),
      onChanged: (v) => setState(() => _areaSelecionadoId = v),
      decoration: OwanyTheme.adaptiveInputDecoration(
        context,
        label: 'Área técnica',
        icon: Icons.room_service_rounded,
      ),
      dropdownColor: OwanyTheme.cardColor(context),
    );
  }
}


