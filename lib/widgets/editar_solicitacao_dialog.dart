import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/owany_theme.dart';
import '../services/api_service.dart';
import '../dto/api_dtos.dart';
import '../models/models.dart';
import '../providers/solicitacoes_provider.dart';
import '../providers/usuarios_provider.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

class EditarSolicitacaoDialog extends StatefulWidget {
  final String solicitacaoId;
  final String tituloAtual;
  final String? descricaoAtual;
  final String? areaAtualId;
  final String statusAtual;
  final String? responsavelIdAtual;
  final String? nomeResponsavelAtual;
  final DateTime? prazoLimiteAtual;
  final VoidCallback onSuccess;

  const EditarSolicitacaoDialog({
    super.key,
    required this.solicitacaoId,
    required this.tituloAtual,
    this.descricaoAtual,
    this.areaAtualId,
    required this.statusAtual,
    this.responsavelIdAtual,
    this.nomeResponsavelAtual,
    this.prazoLimiteAtual,
    required this.onSuccess,
  });

  @override
  State<EditarSolicitacaoDialog> createState() => _EditarSolicitacaoDialogState();
}

class _EditarSolicitacaoDialogState extends State<EditarSolicitacaoDialog> {
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _loadingAreas = false;
  bool _loadingFuncionarios = false;

  String? _selectedAreaId;
  String? _selectedStatus;
  String? _selectedResponsavelId;
  DateTime? _selectedPrazo;

  List<Usuario> _funcionarios = [];

  static const List<String> _statusOpcoes = [
    'Pendente',
    'EmAndamento',
    'EmAnalise',
    'Aguardando',
    'Concluido',
    'Cancelado',
    'Rejeitado',
  ];

  String _statusLabel(String s) {
    switch (s) {
      case 'Pendente': return 'Pendente';
      case 'EmAndamento': return 'Em andamento';
      case 'EmAnalise': return 'Em análise';
      case 'Aguardando': return 'Aguardando';
      case 'Concluido': return 'Concluído';
      case 'Cancelado': return 'Cancelado';
      case 'Rejeitado': return 'Rejeitado';
      default: return s;
    }
  }

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tituloAtual);
    _descricaoController = TextEditingController(text: widget.descricaoAtual ?? '');
    _selectedAreaId = widget.areaAtualId;
    _selectedStatus = widget.statusAtual;
    _selectedResponsavelId = widget.responsavelIdAtual;
    _selectedPrazo = widget.prazoLimiteAtual;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Carregar áreas técnicas
      final provSol = context.read<SolicitacoesProvider>();
      if (provSol.areasTecnicas.isEmpty && !provSol.isLoadingAreas) {
        setState(() => _loadingAreas = true);
        try {
          await provSol.loadAreas();
        } finally {
          if (mounted) setState(() => _loadingAreas = false);
        }
      }

      // Carregar funcionários (possíveis responsáveis)
      final provUsu = context.read<UsuariosProvider>();
      if (provUsu.funcionarios.isEmpty) {
        setState(() => _loadingFuncionarios = true);
        try {
          await provUsu.carregarFuncionarios();
          if (mounted) setState(() => _funcionarios = provUsu.funcionarios);
        } catch (_) {
        } finally {
          if (mounted) setState(() => _loadingFuncionarios = false);
        }
      } else {
        setState(() => _funcionarios = provUsu.funcionarios);
      }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPrazo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPrazo ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Selecionar prazo limite',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
    if (picked != null && mounted) {
      setState(() => _selectedPrazo = picked);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final novoTitulo = _tituloController.text.trim();
    final novaDescricao = _descricaoController.text.trim();

    final semMudanca = novoTitulo == widget.tituloAtual &&
        novaDescricao == (widget.descricaoAtual ?? '') &&
        _selectedAreaId == widget.areaAtualId &&
        _selectedStatus == widget.statusAtual &&
        _selectedResponsavelId == widget.responsavelIdAtual &&
        _selectedPrazo?.toIso8601String() == widget.prazoLimiteAtual?.toIso8601String();

    if (semMudanca) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar('Nenhuma alteração realizada', type: SnackBarType.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? nomeResponsavel;
      if (_selectedResponsavelId != null) {
        final func = _funcionarios.where((f) => f.id == _selectedResponsavelId).firstOrNull;
        nomeResponsavel = func?.nome;
      }

      await ApiService().atualizarSolicitacao(
        widget.solicitacaoId,
        AtualizarSolicitacaoRequest(
          titulo: novoTitulo,
          descricao: novaDescricao.isNotEmpty ? novaDescricao : null,
          areaTecnicaId: _selectedAreaId,
          status: _selectedStatus != widget.statusAtual ? _selectedStatus : null,
          responsavelId: _selectedResponsavelId,
          nomeResponsavel: nomeResponsavel,
          prazoLimite: _selectedPrazo,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('Solicitação atualizada com sucesso!', type: SnackBarType.success),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('Erro ao atualizar: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedAlertDialog(
      title: Text('Editar Solicitação', style: OwanyTheme.headerStyle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Título ──────────────────────────────────────────
                TextFormField(
                  controller: _tituloController,
                  decoration: OwanyTheme.inputDecoration(
                    context: context,
                    label: 'Título *',
                  ),
                  maxLength: 120,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Título obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // ── Descrição ────────────────────────────────────────
                TextFormField(
                  controller: _descricaoController,
                  decoration: OwanyTheme.inputDecoration(
                    context: context,
                    label: 'Descrição',
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
                const SizedBox(height: 12),

                // ── Status ───────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  items: _statusOpcoes
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ))
                      .toList(),
                  decoration: OwanyTheme.inputDecoration(
                    context: context,
                    label: 'Status',
                  ),
                  onChanged: (v) => setState(() => _selectedStatus = v),
                  isExpanded: true,
                ),
                const SizedBox(height: 12),

                // ── Responsável ──────────────────────────────────────
                if (_loadingFuncionarios)
                  const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedResponsavelId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sem responsável'),
                      ),
                      ..._funcionarios.map(
                        (f) => DropdownMenuItem(value: f.id, child: Text(f.nome)),
                      ),
                    ],
                    decoration: OwanyTheme.inputDecoration(
                      context: context,
                      label: 'Responsável',
                    ),
                    onChanged: (v) => setState(() => _selectedResponsavelId = v),
                    isExpanded: true,
                  ),
                const SizedBox(height: 12),

                // ── Prazo Limite ─────────────────────────────────────
                GestureDetector(
                  onTap: _selecionarPrazo,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: OwanyTheme.inputDecoration(
                        context: context,
                        label: 'Prazo limite',
                      ).copyWith(
                        hintText: 'Toque para selecionar',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedPrazo != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedPrazo = null),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.clear, size: 18),
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                      controller: TextEditingController(
                        text: _selectedPrazo != null
                            ? '${_selectedPrazo!.day.toString().padLeft(2, '0')}/'
                              '${_selectedPrazo!.month.toString().padLeft(2, '0')}/'
                              '${_selectedPrazo!.year}'
                            : '',
                      ),
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Área Técnica ─────────────────────────────────────
                Builder(builder: (ctx) {
                  final prov = ctx.read<SolicitacoesProvider>();
                  if (_loadingAreas) {
                    return const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final areas = prov.areasTecnicas;
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAreaId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nenhuma área')),
                      ...areas.map(
                        (a) => DropdownMenuItem(value: a.id, child: Text(a.nome)),
                      ),
                    ],
                    decoration: OwanyTheme.inputDecoration(
                      context: context,
                      label: 'Área técnica',
                    ),
                    onChanged: (v) => setState(() => _selectedAreaId = v),
                    isExpanded: true,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _salvar,
          style: OwanyTheme.primaryButtonStyle(),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
