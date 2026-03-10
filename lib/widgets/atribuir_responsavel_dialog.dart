import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dto/solicitacoes_v2_dtos.dart';
import '../models/enums.dart';
import '../providers/solicitacoes_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/owany_theme.dart';
import '../utils/app_logger.dart';

/// Dialog para atribuir responsável e definir prazo quando status = "Em andamento"
class AtribuirResponsavelDialog extends StatefulWidget {
  final String solicitacaoId;
  final VoidCallback? onSuccess;

  const AtribuirResponsavelDialog({
    super.key,
    required this.solicitacaoId,
    this.onSuccess,
  });

  @override
  State<AtribuirResponsavelDialog> createState() => _AtribuirResponsavelDialogState();
}

class _AtribuirResponsavelDialogState extends State<AtribuirResponsavelDialog> {
  String? _responsavelId;
  final _observacoesController = TextEditingController();
  bool _isLoading = false;
  List<Usuario> _funcionarios = [];
  bool _loadingFuncionarios = false;

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    setState(() => _loadingFuncionarios = true);
    try {
      final lista = await ApiService().listarFuncionarios();
      if (mounted) {
        setState(() {
          _funcionarios = lista;
          _loadingFuncionarios = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFuncionarios = false);
    }
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  String _nomeResponsavelSelecionado() {
    for (final usuario in _funcionarios) {
      if (usuario.id == _responsavelId) return usuario.nome;
    }
    return 'Funcionário';
  }

  Future<void> _notificarEnvolvidosAposAtribuicao(
    SolicitacaoDto solicitacao,
    String nomeResponsavel,
  ) async {
    final destinatarios = <String>{};

    try {
      final admins = await ApiService()
          .listarUsuariosPorTipo(UsuarioTipo.Administrador.toApiValue());
      destinatarios.addAll(admins.map((u) => u.id));
    } catch (e) {
      AppLogger.warning('AtribuirResponsavelDialog',
          'Falha ao listar administradores para notificação: $e');
    }

    try {
      final sindicos = await ApiService()
          .listarUsuariosPorTipo(UsuarioTipo.Sindico.toApiValue());
      destinatarios.addAll(sindicos.map((u) => u.id));
    } catch (e) {
      AppLogger.warning('AtribuirResponsavelDialog',
          'Falha ao listar síndicos para notificação: $e');
    }

    // Moradores apenas do apartamento da solicitação.
    try {
      final moradores = await ApiService()
          .getMoradores(apartamentoId: solicitacao.apartamentoId);
      for (final morador in moradores) {
        if (morador.usuarioId != null && morador.usuarioId!.isNotEmpty) {
          destinatarios.add(morador.usuarioId!);
        }
      }
    } catch (e) {
      AppLogger.warning('AtribuirResponsavelDialog',
          'Falha ao listar moradores do apartamento para notificação: $e');
    }

    if (destinatarios.isEmpty) return;

    final apartamentoLabel =
        '${solicitacao.blocoApartamento}-${solicitacao.numeroApartamento}';
    final titulo = 'Responsável definido: ${solicitacao.titulo}';
    final mensagem =
        '$nomeResponsavel foi definido para o apartamento $apartamentoLabel.';

    for (final usuarioId in destinatarios) {
      try {
        await ApiService().criarNotificacao(
          usuarioId: usuarioId,
          titulo: titulo,
          mensagem: mensagem,
          tipo: 'AtribuicaoResponsavel',
        );
      } catch (e) {
        AppLogger.error('AtribuirResponsavelDialog',
            'Erro ao notificar usuário $usuarioId: $e');
      }
    }
  }

  void _atribuir() async {
    if (_responsavelId == null || _responsavelId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um responsável'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<SolicitacoesProvider>();
    final solicitacaoAntes = provider.solicitacaoAtual;
    final success = await provider.atribuirResponsavel(
      widget.solicitacaoId,
      _responsavelId!,
      descricao: _observacoesController.text.trim().isNotEmpty
          ? _observacoesController.text.trim()
          : null,
    );

    if (success) {
      SolicitacaoDto? solicitacao = provider.solicitacaoAtual ?? solicitacaoAntes;
      if (solicitacao == null) {
        await provider.loadSolicitacao(widget.solicitacaoId);
        solicitacao = provider.solicitacaoAtual;
      }
      if (solicitacao != null) {
        await _notificarEnvolvidosAposAtribuicao(
          solicitacao,
          _nomeResponsavelSelecionado(),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Responsável atribuído com sucesso!'),
            backgroundColor: OwanyTheme.success,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${provider.errorMessage}'),
            backgroundColor: OwanyTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = OwanyTheme.isDark(context);
    final textPrimary = OwanyTheme.textPrimary(context);
    final textMuted = OwanyTheme.textMutedColor(context);
    final surface = OwanyTheme.cardColor(context);

    return Dialog(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atribuir Responsável',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 24),
              Text(
                'Responsável *',
                style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 8),
              _loadingFuncionarios
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      initialValue: _responsavelId,
                      dropdownColor: surface,
                      style: TextStyle(color: textPrimary),
                      iconEnabledColor: textMuted,
                      decoration: OwanyTheme.inputDecoration(
                        context: context,
                        label: 'Selecione um funcionário',
                        dark: isDark,
                      ),
                      items: _funcionarios.map((u) {
                        return DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(
                            u.nome,
                            style: TextStyle(color: textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _responsavelId = value);
                      },
                    ),
              const SizedBox(height: 16),
              Text(
                'Observações',
                style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _observacoesController,
                maxLines: 3,
                style: TextStyle(color: textPrimary),
                decoration: OwanyTheme.inputDecoration(
                  context: context,
                  label: 'Observações adicionais (opcional)',
                  dark: isDark,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('Cancelar', style: TextStyle(color: textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: OwanyTheme.primaryButtonStyle(),
                    onPressed: _isLoading ? null : _atribuir,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
