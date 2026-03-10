import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dto/solicitacoes_v2_dtos.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/notificacoes_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../widgets/editar_solicitacao_dialog.dart';
import '../../widgets/atribuir_responsavel_dialog.dart';
import '../../widgets/timeline_component.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../widgets/themed_alert_dialog.dart';
import '../../services/api_service.dart';
import '../../services/signalr_service.dart';
import '../../utils/app_logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  final String solicitacaoId;
  final String? comentarioId;

  const MaintenanceDetailScreen({
    required this.solicitacaoId,
    this.comentarioId,
    super.key,
  });

  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  // Estado do apartamento
  Apartamento? _apartamento;
  bool _carregandoApartamento = false;
  String? _categoriaResolvida;
  String? _areasTecnicasResolvidas;
  String? _patrimonioResolvido;
  String? _metadataResolvedForSolicitacaoId;
  bool _resolvendoMetadata = false;

  // Carregar apartamento ao receber solicitação
  void _onSolicitacaoAtualizada() {
    final provider = context.read<SolicitacoesProvider>();
    final solicitacao = provider.solicitacaoAtual;
    if (solicitacao != null) {
      _carregarApartamento(
        solicitacao.numeroApartamento,
        solicitacao.blocoApartamento,
      );
      _resolverMetadataSolicitacao(solicitacao);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SolicitacoesProvider>();
      provider.addListener(_onSolicitacaoAtualizada);
    });
  }

  Future<void> _resolverMetadataSolicitacao(SolicitacaoDto solicitacao) async {
    if (_resolvendoMetadata) return;
    if (_metadataResolvedForSolicitacaoId == solicitacao.id) return;

    _resolvendoMetadata = true;
    try {
      final provider = context.read<SolicitacoesProvider>();

      if (provider.tiposSolicitacao.isEmpty && !provider.isLoadingTipos) {
        await provider.loadTipos();
      }
      if (provider.areasTecnicas.isEmpty && !provider.isLoadingAreas) {
        await provider.loadAreas();
      }
      if (!mounted) return;

      String? categoria = solicitacao.tipoSolicitacaoNome?.trim();
      if (categoria == null || categoria.isEmpty) {
        final tipoId = solicitacao.tipoSolicitacaoId?.trim();
        if (tipoId != null && tipoId.isNotEmpty) {
          final tipo = provider.tiposSolicitacao
              .where((t) => t.id.toLowerCase() == tipoId.toLowerCase())
              .firstOrNull;
          if (tipo != null && tipo.nome.trim().isNotEmpty) {
            categoria = tipo.nome.trim();
          } else {
            final tipoDireto = await provider.getTipoById(tipoId);
            if (!mounted) return;
            if (tipoDireto != null && tipoDireto.nome.trim().isNotEmpty) {
              categoria = tipoDireto.nome.trim();
            }
          }
        }
      }

      final nomesAreas = solicitacao.areaTecnicaNomes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (nomesAreas.isEmpty && solicitacao.areaTecnicaIds.isNotEmpty) {
        for (final areaId in solicitacao.areaTecnicaIds) {
          final fromCache = provider.areasTecnicas
              .where((a) => a.id == areaId)
              .firstOrNull;
          if (fromCache != null && fromCache.nome.trim().isNotEmpty) {
            nomesAreas.add(fromCache.nome.trim());
            continue;
          }

          final area = await provider.getAreaById(areaId);
          if (!mounted) return;
          if (area != null && area.nome.trim().isNotEmpty) {
            nomesAreas.add(area.nome.trim());
          }
        }
      }

      if ((categoria == null || categoria.isEmpty) &&
          solicitacao.areaTecnicaIds.isNotEmpty) {
        final tipoNomes = <String>{};
        for (final areaId in solicitacao.areaTecnicaIds) {
          final tipos = await provider.getTiposByArea(areaId, refresh: true);
          if (!mounted) return;
          for (final tipo in tipos) {
            final nome = tipo.nome.trim();
            if (nome.isNotEmpty) tipoNomes.add(nome);
          }
        }
        if (tipoNomes.isNotEmpty) {
          categoria = tipoNomes.join(', ');
        }
      }

      String? patrimonio = solicitacao.itemApartamentoCodigoPatrimonio?.trim();
      if ((patrimonio == null || patrimonio.isEmpty) &&
          solicitacao.itemApartamentoId != null &&
          solicitacao.itemApartamentoId!.trim().isNotEmpty) {
        try {
          final item = await ApiService().getItemApartamento(
            solicitacao.itemApartamentoId!.trim(),
          );
          if (!mounted) return;
          patrimonio = (item.codigoPatrimonio ?? item.codigoIdentificador ?? '')
              .trim();
        } catch (_) {
          // mantém vazio
        }
      }

      if (!mounted) return;
      setState(() {
        _categoriaResolvida = (categoria != null && categoria.isNotEmpty)
            ? categoria
            : null;
        _areasTecnicasResolvidas = nomesAreas.isNotEmpty
            ? nomesAreas.join(', ')
            : null;
        _patrimonioResolvido = (patrimonio != null && patrimonio.isNotEmpty)
            ? patrimonio
            : null;
        _metadataResolvedForSolicitacaoId = solicitacao.id;
      });
    } finally {
      _resolvendoMetadata = false;
    }
  }

  Future<void> _carregarApartamento(String? numero, String? bloco) async {
    if (numero == null || bloco == null) return;
    setState(() => _carregandoApartamento = true);
    try {
      final lista = await ApiService().request<List<Apartamento>>(
        'apartamentos?numero=$numero&bloco=$bloco',
        method: 'GET',
        fromJson: (json) {
          final items = json is List
              ? json
              : (json is Map<String, dynamic>
                    ? (json['items'] ??
                          json['apartamentos'] ??
                          json['registros'] ??
                          [json])
                    : [json]);
          return (items as List)
              .map(
                (item) => Apartamento.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        },
      );
      if (!mounted) return;
      if (lista.isEmpty) {
        setState(() => _apartamento = null);
      } else {
        var apt = lista.first;
        try {
          final moradores = await ApiService().getMoradores(
            apartamentoId: apt.id,
          );
          if (moradores.isNotEmpty) {
            apt = apt.copyWith(
              moradores: moradores,
              quantidadeMoradores: moradores.length,
            );
          }
        } catch (_) {}
        if (!mounted) return;
        setState(() => _apartamento = apt);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _apartamento = null);
    } finally {
      if (mounted) setState(() => _carregandoApartamento = false);
    }
  }

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _commentKeys = {};
  bool _isInternal = false;
  // Anexos pendentes para a solicitação
  List<PlatformFile> _pendingSolicitacaoAnexos = [];
  bool _uploadingSolicitacaoAnexos = false;
  bool _initialized = false;
  bool _focoComentarioExecutado = false;

  // Para edição
  late TextEditingController _responsavelController;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _resolverNomeMorador(SolicitacaoDto solicitacao) {
    final nomeDaSolicitacao = solicitacao.nomeMorador.trim();
    if (nomeDaSolicitacao.isNotEmpty) return nomeDaSolicitacao;

    final moradores = _apartamento?.moradores;
    if (moradores != null && moradores.isNotEmpty) {
      final moradorPorId = moradores.where(
        (m) => m.id == solicitacao.moradorId,
      );
      if (moradorPorId.isNotEmpty) {
        final nome = moradorPorId.first.nome.trim();
        if (nome.isNotEmpty) return nome;
        final nomeUsuario = moradorPorId.first.nomeUsuario?.trim() ?? '';
        if (nomeUsuario.isNotEmpty) return nomeUsuario;
      }

      final primeiroComNome = moradores.firstWhere(
        (m) =>
            m.nome.trim().isNotEmpty ||
            (m.nomeUsuario?.trim().isNotEmpty ?? false),
        orElse: () => moradores.first,
      );
      final nome = primeiroComNome.nome.trim();
      if (nome.isNotEmpty) return nome;
      final nomeUsuario = primeiroComNome.nomeUsuario?.trim() ?? '';
      if (nomeUsuario.isNotEmpty) return nomeUsuario;
    }

    return '-';
  }

  GlobalKey _keyForComment(String commentId) {
    return _commentKeys.putIfAbsent(commentId, () => GlobalKey());
  }

  void _agendarFocoComentarioSeNecessario(
    List<ComentarioDto> comentariosVisiveis,
  ) {
    final comentarioIdAlvo = widget.comentarioId?.trim();
    if (comentarioIdAlvo == null || comentarioIdAlvo.isEmpty) return;
    if (_focoComentarioExecutado) return;
    if (comentariosVisiveis.isEmpty) return;

    final comentarioExiste = comentariosVisiveis.any(
      (c) => c.id == comentarioIdAlvo,
    );
    if (!comentarioExiste) {
      _focoComentarioExecutado = true;
      return;
    }

    _focoComentarioExecutado = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _commentKeys[comentarioIdAlvo]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
      }
    });
  }

  Future<void> _alterarStatus(
    SolicitacaoDto solicitacao,
    String novoStatus,
  ) async {
    // Se ação é "Atribuir", mostrar dialog de atribuição de responsável
    if (novoStatus == 'Atribuir') {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AtribuirResponsavelDialog(
          solicitacaoId: solicitacao.id,
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              OwanyTheme.snackBar(
                AppLocalizations.of(context)!.maintenance_detail_status_updated,
                type: SnackBarType.success,
              ),
            );
          },
        ),
      );
      return;
    }

    // Se ação é "DefinirPrazo", mostrar date picker
    if (novoStatus == 'DefinirPrazo') {
      await _mostrarDefinirPrazo(solicitacao);
      return;
    }

    // Se ação é "Concluido", mostrar dialog para comentário final
    if (novoStatus == 'Concluido') {
      await _mostrarConcluirDialog(solicitacao);
      return;
    }

    // Se ação é "Cancelado", mostrar dialog para comentário obrigatório
    if (novoStatus == 'Cancelado') {
      await _mostrarCancelarRejeitar(solicitacao, 'Cancelado');
      return;
    }

    // Se ação é "Rejeitado", mostrar dialog para comentário obrigatório
    if (novoStatus == 'Rejeitado') {
      await _mostrarCancelarRejeitar(solicitacao, 'Rejeitado');
      return;
    }

    final provider = context.read<SolicitacoesProvider>();

    final dto = MudarStatusDto(novoStatus: novoStatus);
    await provider.mudarStatus(solicitacao.id, dto);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(provider.errorMessage!, type: SnackBarType.error),
      );
    } else {
      await _gerarNotificacoesStatus(solicitacao, novoStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.maintenance_detail_status_updated,
          type: SnackBarType.success,
        ),
      );
    }
  }

  /// Mostra date picker para o funcionário definir o prazo limite
  Future<void> _mostrarDefinirPrazo(SolicitacaoDto solicitacao) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;

    final provider = context.read<SolicitacoesProvider>();
    final sucesso = await provider.definirPrazoLimite(solicitacao.id, picked);
    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.maintenance_detail_status_updated,
          type: SnackBarType.success,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(provider.errorMessage!, type: SnackBarType.error),
      );
    }
  }

  /// Mostra dialog para adicionar comentário final ao concluir
  Future<void> _mostrarConcluirDialog(SolicitacaoDto solicitacao) async {
    final comentarioController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    bool interno = false;

    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return ThemedAlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: OwanyTheme.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tx('Concluir Solicitação', 'Complete Request'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(dialogContext),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tx(
                      'Nota de fechamento:',
                      'Closing note:',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textPrimary(dialogContext),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: comentarioController,
                    minLines: 2,
                    maxLines: 4,
                    style: TextStyle(
                      color: OwanyTheme.textPrimary(dialogContext),
                    ),
                    cursorColor: OwanyTheme.primaryOrange,
                    decoration: OwanyTheme.inputDecoration(
                      context: dialogContext,
                      label: _tx('Nota de fechamento', 'Closing note'),
                      hint: _tx(
                        'Ex: Serviço realizado com sucesso...',
                        'Ex: Service completed successfully...',
                      ),
                      dark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: interno,
                          onChanged: (v) => setDialogState(() => interno = v ?? false),
                          activeColor: OwanyTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.lock_outline, size: 16, color: OwanyTheme.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _tx('Comentário interno (apenas staff)', 'Internal comment (staff only)'),
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textMutedColor(dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_tx('Cancelar', 'Cancel')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, {
                      'comentario': comentarioController.text.trim(),
                      'interno': interno,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwanyTheme.success,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(_tx('Concluir', 'Complete')),
                ),
              ],
            );
          },
        );
      },
    );

    comentarioController.dispose();

    // Se o usuário cancelou o dialog
    if (resultado == null || !mounted) return;

    final provider = context.read<SolicitacoesProvider>();
    final comentario = resultado['comentario'] as String;

    // Cria DTO com ou sem comentário
    final dto = MudarStatusDto(
      novoStatus: 'Concluido',
      comentario: comentario.isNotEmpty ? comentario : null,
    );
    
    await provider.mudarStatus(solicitacao.id, dto);
    if (!mounted) return;

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(provider.errorMessage!, type: SnackBarType.error),
      );
    } else {
      // Adicionar comentário com label de fechamento se preenchido
      if (comentario.isNotEmpty) {
        final notaLabel = _tx('Nota de fechamento', 'Closing note');
        final mensagemFinal = '[$notaLabel] $comentario';
        final comentarioDto = CriarComentarioDto(
          mensagem: mensagemFinal,
          interno: resultado['interno'] as bool,
        );
        await provider.adicionarComentario(solicitacao.id, comentarioDto);
        if (!mounted) return;
      }

      await _gerarNotificacoesStatus(solicitacao, 'Concluido');

      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          l10n.maintenance_detail_status_updated,
          type: SnackBarType.success,
        ),
      );
    }
  }

  /// Mostra dialog para cancelar ou rejeitar com comentário obrigatório e opção interno/público
  Future<void> _mostrarCancelarRejeitar(SolicitacaoDto solicitacao, String novoStatus) async {
    final comentarioController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    bool interno = false;

    final isCancelar = novoStatus == 'Cancelado';
    final tituloDialog = isCancelar
        ? _tx('Cancelar Solicitação', 'Cancel Request')
        : _tx('Rejeitar Solicitação', 'Reject Request');
    final iconColor = OwanyTheme.error;
    final icon = isCancelar ? Icons.cancel_rounded : Icons.block_rounded;
    final labelNota = isCancelar
        ? _tx('Nota de cancelamento', 'Cancellation note')
        : _tx('Nota de rejeição', 'Rejection note');
    final hintNota = isCancelar
        ? _tx('Descreva o motivo do cancelamento...', 'Describe the cancellation reason...')
        : _tx('Descreva o motivo da rejeição...', 'Describe the rejection reason...');
    final btnLabel = isCancelar
        ? _tx('Cancelar Solicitação', 'Cancel Request')
        : _tx('Rejeitar Solicitação', 'Reject Request');

    final resultado = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return ThemedAlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tituloDialog,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(dialogContext),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$labelNota:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: OwanyTheme.textPrimary(dialogContext),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: comentarioController,
                    minLines: 2,
                    maxLines: 4,
                    style: TextStyle(
                      color: OwanyTheme.textPrimary(dialogContext),
                    ),
                    cursorColor: OwanyTheme.primaryOrange,
                    decoration: OwanyTheme.inputDecoration(
                      context: dialogContext,
                      label: labelNota,
                      hint: hintNota,
                      dark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: interno,
                          onChanged: (v) => setDialogState(() => interno = v ?? false),
                          activeColor: OwanyTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.lock_outline, size: 16, color: OwanyTheme.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _tx('Comentário interno (apenas staff)', 'Internal comment (staff only)'),
                          style: TextStyle(
                            fontSize: 13,
                            color: OwanyTheme.textMutedColor(dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_tx('Voltar', 'Back')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (comentarioController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        OwanyTheme.snackBar(
                          _tx('O comentário é obrigatório.', 'Comment is required.'),
                          type: SnackBarType.error,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'comentario': comentarioController.text.trim(),
                      'interno': interno,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: iconColor),
                  icon: Icon(icon, size: 18),
                  label: Text(btnLabel),
                ),
              ],
            );
          },
        );
      },
    );

    comentarioController.dispose();

    if (resultado == null || !mounted) return;

    final provider = context.read<SolicitacoesProvider>();

    // 1. Mudar status
    final dto = MudarStatusDto(
      novoStatus: novoStatus,
      comentario: resultado['comentario'] as String,
    );
    await provider.mudarStatus(solicitacao.id, dto);
    if (!mounted) return;

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(provider.errorMessage!, type: SnackBarType.error),
      );
      return;
    }

    // 2. Adicionar comentário com o label adequado
    final notaLabel = isCancelar
        ? _tx('Nota de cancelamento', 'Cancellation note')
        : _tx('Nota de rejeição', 'Rejection note');
    final mensagemFinal = '[$notaLabel] ${resultado['comentario']}';
    final comentarioDto = CriarComentarioDto(
      mensagem: mensagemFinal,
      interno: resultado['interno'] as bool,
    );
    await provider.adicionarComentario(solicitacao.id, comentarioDto);
    if (!mounted) return;

    await _gerarNotificacoesStatus(solicitacao, novoStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      OwanyTheme.snackBar(
        l10n.maintenance_detail_status_updated,
        type: SnackBarType.success,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _responsavelController = TextEditingController();
    Future.microtask(() {
      final provider = context.read<SolicitacoesProvider>();
      final signalRConectado = SignalRService().isConnected;
      AppLogger.info(
        'MaintenanceDetailScreen',
        '🔄 Inicializando - SignalR conectado: $signalRConectado',
      );

      provider.loadSolicitacao(widget.solicitacaoId);
      provider.loadComentarios(widget.solicitacaoId);
      provider.loadTipos();
      provider.loadAreas();
      // Entra no grupo para escutar comentários em tempo real
      provider.entrarNoGrupoDaSolicitacao(widget.solicitacaoId);
    });
  }

  Future<List<String>> _obterUsuariosParaNotificar(
    SolicitacaoDto solicitacao,
  ) async {
    final ids = <String>{};

    try {
      final admins = await ApiService().listarUsuariosPorTipo(
        UsuarioTipo.Administrador.toApiValue(),
      );
      ids.addAll(admins.map((u) => u.id));

      final sindicos = await ApiService().listarUsuariosPorTipo(
        UsuarioTipo.Sindico.toApiValue(),
      );
      ids.addAll(sindicos.map((u) => u.id));
    } catch (_) {
      // Ignorar erro ao carregar admins/síndicos
    }

    ids.add(solicitacao.usuarioCriadorId);

    // Buscar TODOS os moradores actuais do apartamento (mais fiável que usar o moradorId da solicitação)
    try {
      final moradores = await ApiService().getMoradores(
        apartamentoId: solicitacao.apartamentoId,
      );
      for (final m in moradores) {
        if (m.usuarioId != null && m.usuarioId!.isNotEmpty) {
          ids.add(m.usuarioId!);
        }
      }
    } catch (_) {
      // Fallback: usar moradorId da solicitação
      try {
        final morador = await ApiService().getMorador(solicitacao.moradorId);
        if (morador.usuarioId != null && morador.usuarioId!.isNotEmpty) {
          ids.add(morador.usuarioId!);
        }
      } catch (_) {}
    }

    if (solicitacao.responsavelId != null &&
        solicitacao.responsavelId!.isNotEmpty) {
      ids.add(solicitacao.responsavelId!);
    }

    return ids.toList();
  }

  Future<void> _gerarNotificacoesStatus(
    SolicitacaoDto solicitacao,
    String novoStatus,
  ) async {
    final notificacoesProvider = context.read<NotificacoesProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.usuarioAtual == null) return;

    final usuariosParaNotificar = await _obterUsuariosParaNotificar(
      solicitacao,
    );

    await notificacoesProvider.gerarNotificacaoStatusAlterado(
      solicitacaoId: solicitacao.id,
      solicitacaoTitulo: solicitacao.titulo,
      statusAnterior: solicitacao.status,
      statusNovo: novoStatus,
      usuarioAlteradorId: authProvider.usuarioAtual!.id,
      usuarioAlteradorNome: authProvider.usuarioAtual!.nome,
      usuariosParaNotificar: usuariosParaNotificar,
    );
  }

  /// Gera notificações para novo comentário:
  /// - Comentários internos → notifica apenas staff (admin/síndico/responsável)
  /// - Comentários públicos → notifica todos os envolvidos (inclui morador)
  Future<void> _gerarNotificacoesComentario(
    SolicitacaoDto solicitacao,
    String mensagem,
    bool ehInterno,
  ) async {
    try {
      final notificacoesProvider = context.read<NotificacoesProvider>();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.usuarioAtual == null) return;

      final usuarioAutorId = authProvider.usuarioAtual!.id;
      final usuarioAutorNome = authProvider.usuarioAtual!.nome;

      if (ehInterno) {
        // Comentário interno: notifica apenas staff (sem morador)
        final ids = <String>{};
        try {
          final admins = await ApiService().listarUsuariosPorTipo(
            UsuarioTipo.Administrador.toApiValue(),
          );
          ids.addAll(admins.map((u) => u.id));
          final sindicos = await ApiService().listarUsuariosPorTipo(
            UsuarioTipo.Sindico.toApiValue(),
          );
          ids.addAll(sindicos.map((u) => u.id));
        } catch (_) {}
        if (solicitacao.responsavelId != null &&
            solicitacao.responsavelId!.isNotEmpty) {
          ids.add(solicitacao.responsavelId!);
        }
        ids.add(solicitacao.usuarioCriadorId);
        for (final uid in ids) {
          if (uid == usuarioAutorId) continue;
          try {
            await ApiService().criarNotificacao(
              usuarioId: uid,
              titulo: '[Interno] ${solicitacao.titulo}',
              mensagem: mensagem.length > 50
                  ? '${mensagem.substring(0, 50)}...'
                  : mensagem,
              tipo: 'NovoComentario',
            );
          } catch (_) {}
        }
      } else {
        // Comentário público: notifica todos os envolvidos
        final usuariosParaNotificar = await _obterUsuariosParaNotificar(
          solicitacao,
        );
        await notificacoesProvider.gerarNotificacaoComentario(
          solicitacaoId: solicitacao.id,
          solicitacaoTitulo: solicitacao.titulo,
          mensagem: mensagem,
          usuarioAutorId: usuarioAutorId,
          usuarioAutorNome: usuarioAutorNome,
          ehInterno: false,
          usuariosParaNotificar: usuariosParaNotificar,
        );
      }
    } catch (e) {
      AppLogger.error(
        'MaintenanceDetailScreen',
        'Erro ao gerar notificação de comentário: $e',
      );
    }
  }

  /// Gera notificações para novo(s) anexo(s) enviados à solicitação.
  /// Notifica todos os envolvidos (morador, responsável, admins, síndicos).
  Future<void> _gerarNotificacoesAnexo(
    SolicitacaoDto solicitacao,
    int quantidade,
  ) async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.usuarioAtual == null) return;

      final usuarioAutorId = authProvider.usuarioAtual!.id;
      final usuarioAutorNome = authProvider.usuarioAtual!.nome;
      
      final mensagem = quantidade == 1
          ? '📎 $usuarioAutorNome enviou um anexo'
          : '📎 $usuarioAutorNome enviou $quantidade anexos';

      // Obter todos os envolvidos
      final usuariosParaNotificar = await _obterUsuariosParaNotificar(
        solicitacao,
      );

      // Criar notificação para cada usuário (exceto o autor)
      for (final uid in usuariosParaNotificar) {
        if (uid == usuarioAutorId) continue;
        try {
          await ApiService().criarNotificacao(
            usuarioId: uid,
            titulo: solicitacao.titulo,
            mensagem: mensagem,
            tipo: 'NovoAnexo',
          );
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.error(
        'MaintenanceDetailScreen',
        'Erro ao gerar notificação de anexo: $e',
      );
    }
  }

  @override
  void dispose() {
    final provider = context.read<SolicitacoesProvider>();
    provider.sairDoGrupoDaSolicitacao();
    provider.removeListener(_onSolicitacaoAtualizada);
    _commentController.dispose();
    _responsavelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _adicionarComentario(SolicitacoesProvider provider) async {
    final textoVazio = _commentController.text.trim().isEmpty;
    if (textoVazio) return;

    final mensagem = _commentController.text.trim();
    final ehInterno = _isInternal;

    final comentarioDto = CriarComentarioDto(
      mensagem: mensagem,
      interno: ehInterno,
    );
    final sucesso = await provider.adicionarComentario(
      widget.solicitacaoId,
      comentarioDto,
    );

    if (!mounted) return;

    if (sucesso) {
      _commentController.clear();
      setState(() => _isInternal = false);

      // Recarregar solicitação completa
      await provider.loadSolicitacao(widget.solicitacaoId);

      // Gerar notificações de comentário para todos os envolvidos
      final solicitacao = provider.solicitacaoAtual;
      if (solicitacao != null) {
        _gerarNotificacoesComentario(solicitacao, mensagem, ehInterno);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          AppLocalizations.of(context)!.maintenance_detail_comment_added,
          type: SnackBarType.success,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(provider.errorMessage!, type: SnackBarType.error),
      );
    }
  }

  /// Builds timeline events from request status progression
  List<TimelineEvent> _buildTimelineEvents(SolicitacaoDto solicitacao) {
    final events = <TimelineEvent>[];
    
    // Criação
    events.add(TimelineEvent(
      status: 'Pendente',
      label: 'Criado',
      dateTime: solicitacao.criadoEm,
      color: OwanyTheme.warning,
      icon: Icons.add_circle_outline_rounded,
      isCompleted: true,
      description: 'Solicitação criada',
    ));

    // Atribuído
    if (solicitacao.responsavelId != null && solicitacao.responsavelId!.isNotEmpty) {
      events.add(TimelineEvent(
        status: 'Atribuído',
        label: 'Atribuído',
        dateTime: solicitacao.criadoEm.add(const Duration(hours: 1)),
        color: OwanyTheme.info,
        icon: Icons.person_add_outlined,
        isCompleted: solicitacao.status.toString().toLowerCase().contains('atribuido') ||
            solicitacao.status.toString().toLowerCase().contains('emandamento') ||
            solicitacao.status.toString().toLowerCase().contains('concluido'),
        description: 'Responsável designado',
      ));
    }

    // Em Andamento
    if (solicitacao.status.toString().toLowerCase().contains('emandamento') ||
        solicitacao.status.toString().toLowerCase().contains('concluido')) {
      events.add(TimelineEvent(
        status: 'EmAndamento',
        label: 'Em Andamento',
        dateTime: solicitacao.atualizadoEm ?? solicitacao.criadoEm,
        color: OwanyTheme.info,
        icon: Icons.play_circle_outline_rounded,
        isCompleted: solicitacao.status.toString().toLowerCase().contains('concluido'),
        description: 'Execução iniciada',
      ));
    }

    // Concluído
    if (solicitacao.status.toString().toLowerCase().contains('concluido')) {
      events.add(TimelineEvent(
        status: 'Concluido',
        label: 'Concluído',
        dateTime: solicitacao.atualizadoEm ?? solicitacao.criadoEm,
        color: OwanyTheme.success,
        icon: Icons.check_circle_outline_rounded,
        isCompleted: true,
        description: 'Solicitação concluída',
      ));
    }

    // Cancelado ou Rejeitado
    if (solicitacao.status.toString().toLowerCase().contains('cancelado') ||
        solicitacao.status.toString().toLowerCase().contains('rejeitado')) {
      events.add(TimelineEvent(
        status: 'Cancelado',
        label: solicitacao.status.toString().toLowerCase().contains('rejeitado') 
            ? 'Rejeitado' 
            : 'Cancelado',
        dateTime: solicitacao.atualizadoEm ?? solicitacao.criadoEm,
        color: OwanyTheme.error,
        icon: Icons.cancel_outlined,
        isCompleted: true,
        description: 'Solicitação finalizada',
      ));
    }

    return events;
  }

  /// Returns the current event index for timeline progress
  int _getCurrentTimelineIndex(SolicitacaoDto solicitacao) {
    final status = solicitacao.status.toString().toLowerCase();
    if (status.contains('cancelado') || status.contains('rejeitado')) return 4;
    if (status.contains('concluido')) return 3;
    if (status.contains('emandamento')) return 2;
    if (status.contains('atribuido')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          // Estado de carregamento
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          // Resolver solicitação
          final solicitacao = _resolveSolicitacao(provider);

          // Solicitação não encontrada
          if (solicitacao == null) {
            return _buildNotFoundState();
          }

          final comentarios = provider.comentarios;
          final isMobile = MediaQuery.of(context).size.width < 600;
          final contentPadding = isMobile ? 12.0 : 16.0;
          final spacingMedium = isMobile ? 16.0 : 20.0;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                expandedHeight: isMobile ? 100 : 140,
                backgroundColor: OwanyTheme.primaryOrange,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.build_rounded,
                      color: OwanyTheme.primaryOrange,
                      size: 22,
                    ),
                  ),
                ),
                actions: [
                  if (context.read<AuthProvider>().isStaff)
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: OwanyTheme.cardColor(context),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => EditarSolicitacaoDialog(
                            solicitacaoId: solicitacao.id,
                            tituloAtual: solicitacao.titulo,
                            descricaoAtual: solicitacao.descricao,
                            areaAtualId: solicitacao.areaTecnicaIds.isNotEmpty
                                ? solicitacao.areaTecnicaIds.first
                                : null,
                            statusAtual: solicitacao.status,
                            responsavelIdAtual: solicitacao.responsavelId,
                            nomeResponsavelAtual: solicitacao.nomeResponsavel,
                            prazoLimiteAtual: solicitacao.prazoLimite,
                            onSuccess: () {
                              context
                                  .read<SolicitacoesProvider>()
                                  .loadSolicitacao(solicitacao.id);
                            },
                          ),
                        );
                      },
                      tooltip: AppLocalizations.of(context)!.common_edit,
                    ),
                  // Delete — Admin only (conforme API spec)
                  if (context.read<AuthProvider>().isAdmin)
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: OwanyTheme.error,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(_tx('Remover Solicitação', 'Remove Request')),
                            content: Text(
                              _tx(
                                'Tem certeza que deseja remover esta solicitação? Esta ação não pode ser desfeita.',
                                'Are you sure you want to remove this request? This action cannot be undone.',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(_tx('Cancelar', 'Cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: OwanyTheme.error),
                                child: Text(_tx('Remover', 'Remove')),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await context.read<SolicitacoesProvider>().deletarSolicitacao(solicitacao.id);
                          if (mounted) Navigator.of(context).pop();
                        }
                      },
                      tooltip: _tx('Remover solicitação', 'Remove request'),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 16,
                      isMobile ? 12 : 16,
                      isMobile ? 12 : 16,
                      isMobile ? 8 : 12,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        solicitacao.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OwanyTheme.cardColor(context),
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 16 : 18,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Badge de status destacado, fora do AppBar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isMobile ? 16 : 32,
                    right: isMobile ? 16 : 32,
                    top: isMobile ? 8 : 16,
                    bottom: isMobile ? 8 : 12,
                  ),
                  child: Row(
                    children: [
                      _StatusBadge(status: solicitacao.status.toString()),
                      const SizedBox(width: 12),
                      if (_carregandoApartamento)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: OwanyTheme.info,
                          ),
                        )
                      else if (_apartamento != null &&
                          _apartamento!.emManutencao == true)
                        _EmManutencaoBadge(),
                    ],
                  ),
                ),
              ),

              // Deadline Indicator
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 32,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: DeadlineIndicator(
                    createdAt: solicitacao.criadoEm,
                    dueDate: solicitacao.prazoLimite,
                    completedAt: solicitacao.concluidoEm,
                    isCompleted: solicitacao.status.toString().toLowerCase().contains('concluido'),
                    isDelayed: (solicitacao.prazoLimite?.isBefore(DateTime.now()) ?? false) &&
                        !solicitacao.status.toString().toLowerCase().contains('concluido'),
                  ),
                ),
              ),

              // Conteúdo
              SliverPadding(
                padding: EdgeInsets.all(contentPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Timeline
                    Text(
                      'Progresso',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    TimelineComponent(
                      events: _buildTimelineEvents(solicitacao),
                      currentEventIndex: _getCurrentTimelineIndex(solicitacao),
                      itemHeight: 110,
                    ),
                    SizedBox(height: spacingMedium),

                    // Info Grid
                    _DetailGrid(
                      solicitacao: solicitacao,
                      formatDate: _formatDate,
                      nomeMoradorResolvido: _resolverNomeMorador(solicitacao),
                      categoriaResolvida: _categoriaResolvida,
                      areasTecnicasResolvidas: _areasTecnicasResolvidas,
                      patrimonioResolvido: _patrimonioResolvido,
                    ),
                    SizedBox(height: spacingMedium),

                    // Status Actions
                    _buildStatusActions(context, provider, solicitacao),
                    SizedBox(height: spacingMedium),

                    // Descrição
                    _buildDescriptionSection(solicitacao),
                    SizedBox(height: spacingMedium),

                    // Anexos da solicitação
                    _buildAnexosSection(solicitacao),
                    SizedBox(height: spacingMedium),

                    // Comentários
                    _buildCommentsSection(comentarios),
                    // Padding extra para garantir que o comentário não fique tapado pelo bottomSheet
                    SizedBox(height: isMobile ? 180 : 140),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          final solicitacao = _resolveSolicitacao(provider);
          if (solicitacao == null) return const SizedBox.shrink();
          final status = solicitacao.status.toString();
          final isTerminal =
              status.contains('Concluido') ||
              status.contains('Cancelado') ||
              status.contains('Rejeitado');
          if (isTerminal) return const SizedBox.shrink();
          return _buildCommentBar(context);
        },
      ),
    );
  }

  // =========================
  // HELPERS DE ESTADO
  // =========================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: OwanyTheme.primaryOrange),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.maintenance_detail_loading,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_outlined, size: 48, color: OwanyTheme.error),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.maintenance_detail_not_found,
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // BUILD METHODS
  // =========================

  Widget _buildStatusActions(
    BuildContext context,
    SolicitacoesProvider provider,
    SolicitacaoDto solicitacao,
  ) {
    final auth = context.watch<AuthProvider>();
    final userType = auth.usuarioAtual?.tipo;
    final userId = auth.usuarioAtual?.id;
    final isAdmin = userType == UsuarioTipo.Administrador;
    final isSindico = userType == UsuarioTipo.Sindico;
    final isFuncionario = userType == UsuarioTipo.Funcionario;
    final isGestor = isAdmin || isSindico;
    final canEditStatus = isGestor || isFuncionario;

    if (!canEditStatus) {
      return const SizedBox.shrink();
    }

    final status = solicitacao.status;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    // Montar lista de botões baseado no papel e status
    final List<Widget> actionButtons = [];

    // Editar — Admin/Síndico sempre pode editar
    if (isGestor) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.secondary(
            text: l10n.maintenance_detail_edit,
            icon: Icons.edit_rounded,
            onPressed: provider.isLoading
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => EditarSolicitacaoDialog(
                          solicitacaoId: solicitacao.id,
                          tituloAtual: solicitacao.titulo,
                          descricaoAtual: solicitacao.descricao,
                          areaAtualId: solicitacao.areaTecnicaIds.isNotEmpty
                              ? solicitacao.areaTecnicaIds.first
                              : null,
                          statusAtual: solicitacao.status,
                          responsavelIdAtual: solicitacao.responsavelId,
                          nomeResponsavelAtual: solicitacao.nomeResponsavel,
                          prazoLimiteAtual: solicitacao.prazoLimite,
                          onSuccess: () {
                            context.read<SolicitacoesProvider>().loadSolicitacao(
                              solicitacao.id,
                            );
                          },
                        ),
                    );
                  },
          ),
        ),
      );
    }

    // Atribuir Responsável — Staff (Admin/Síndico/Func), quando status é Pendente
    if (canEditStatus && (status.contains('Pendente'))) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.primary(
            text: l10n.maintenance_detail_assign_responsible,
            icon: Icons.person_add_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'Atribuir'),
          ),
        ),
      );
    }

    // Definir Prazo — Funcionário atribuído, quando status é EmAnalise
    if (isFuncionario &&
        status.contains('EmAnalise') &&
        solicitacao.responsavelId == userId) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.primary(
            text: l10n.maintenance_detail_define_deadline,
            icon: Icons.timer_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'DefinirPrazo'),
          ),
        ),
      );
    }

    // Concluir — Funcionário (se responsável) ou Admin/Síndico, quando em EmAndamento
    if ((isGestor || (isFuncionario && solicitacao.responsavelId == userId)) &&
        status.contains('EmAndamento')) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.primary(
            text: l10n.maintenance_detail_complete,
            icon: Icons.check_circle_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'Concluido'),
          ),
        ),
      );
    }

    // Cancelar — Admin/Síndico, quando NÃO está Concluido/Cancelado/Rejeitado
    if (isGestor &&
        !status.contains('Concluido') &&
        !status.contains('Cancelado') &&
        !status.contains('Rejeitado')) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.error(
            text: l10n.maintenance_detail_cancel_request,
            icon: Icons.cancel_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'Cancelado'),
          ),
        ),
      );
    }

    // Rejeitar — Admin/Síndico, quando Pendente ou EmAnalise
    if (isGestor &&
        (status.contains('Pendente') || status.contains('EmAnalise'))) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.error(
            text: l10n.maintenance_detail_reject_request,
            icon: Icons.block_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'Rejeitado'),
          ),
        ),
      );
    }

    // Reabrir — Admin/Síndico quando Concluido/Cancelado/Rejeitado
    if (isGestor &&
        (status.contains('Concluido') ||
            status.contains('Cancelado') ||
            status.contains('Rejeitado'))) {
      actionButtons.add(
        Expanded(
          child: PrimaryButton.secondary(
            text: l10n.maintenance_detail_reopen,
            icon: Icons.restart_alt_rounded,
            onPressed: provider.isLoading
                ? null
                : () => _alterarStatus(solicitacao, 'Pendente'),
          ),
        ),
      );
    }

    if (actionButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.maintenance_detail_quick_actions,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        if (isMobile)
          // Mobile: pares de 2 por linha
          Column(
            children: [
              for (int i = 0; i < actionButtons.length; i += 2)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i + 2 < actionButtons.length ? 10 : 0,
                  ),
                  child: Row(
                    children: [
                      actionButtons[i],
                      if (i + 1 < actionButtons.length) ...[
                        SizedBox(width: 10),
                        actionButtons[i + 1],
                      ],
                    ],
                  ),
                ),
            ],
          )
        else
          // Desktop: Row horizontal
          Row(
            children: [
              for (int i = 0; i < actionButtons.length; i++) ...[
                if (i > 0) SizedBox(width: 10),
                actionButtons[i],
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildDescriptionSection(SolicitacaoDto solicitacao) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.maintenance_detail_description,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            solicitacao.descricao ??
                AppLocalizations.of(context)!.maintenance_detail_no_description,
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontSize: isMobile ? 13 : 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Abre URL do anexo para download/visualização
  Future<void> _abrirAnexo(String url) async {
    final uri = ApiService().resolveServerUri(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          _tx('Não foi possível abrir o arquivo', 'Could not open the file'),
          type: SnackBarType.error,
        ),
      );
    }
  }

  /// Selecionar arquivo para anexar à solicitação
  Future<void> _pickAnexoSolicitacao() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null && mounted) {
      setState(() => _pendingSolicitacaoAnexos.addAll(result.files));
    }
  }

  /// Enviar anexos pendentes para a solicitação
  Future<void> _uploadAnexosSolicitacao(SolicitacoesProvider provider) async {
    if (_pendingSolicitacaoAnexos.isEmpty) return;
    
    setState(() => _uploadingSolicitacaoAnexos = true);
    final anexosCopia = List<PlatformFile>.from(_pendingSolicitacaoAnexos);
    setState(() => _pendingSolicitacaoAnexos = []);
    
    int sucessos = 0;
    for (final file in anexosCopia) {
      if (file.bytes != null) {
        final ok = await provider.uploadAnexo(
          widget.solicitacaoId,
          file.bytes!,
          file.name,
        );
        if (ok) sucessos++;
      }
    }
    
    setState(() => _uploadingSolicitacaoAnexos = false);
    if (!mounted) return;
    
    // Recarregar detalhes para atualizar lista de anexos
    await provider.loadSolicitacao(widget.solicitacaoId);
    
    if (sucessos > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          '$sucessos ${sucessos == 1 ? 'arquivo enviado' : 'arquivos enviados'} com sucesso!',
          type: SnackBarType.success,
        ),
      );
      
      // Gerar notificações de anexo para todos os envolvidos
      final solicitacao = provider.solicitacaoAtual;
      if (solicitacao != null) {
        _gerarNotificacoesAnexo(solicitacao, sucessos);
      }
    }
  }

  Widget _buildAnexosSection(SolicitacaoDto solicitacao) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final anexos = solicitacao.anexos;
    
    // Verifica se usuário pode adicionar anexos (status não concluído/cancelado/rejeitado)
    final status = solicitacao.status.toString().toLowerCase();
    final isTerminal = status.contains('concluido') ||
        status.contains('cancelado') ||
        status.contains('rejeitado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _tx('Anexos', 'Attachments'),
                style: TextStyle(
                  color: OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 15 : 16,
                ),
              ),
            ),
            if (!isTerminal)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: OwanyTheme.primaryOrange,
                  size: isMobile ? 22 : 24,
                ),
                onPressed: _pickAnexoSolicitacao,
                tooltip: _tx('Adicionar anexo', 'Add attachment'),
              ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 12),
        // Anexos pendentes para upload
        if (_pendingSolicitacaoAnexos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _pendingSolicitacaoAnexos.map((f) {
              return Chip(
                avatar: Icon(
                  Icons.attach_file_rounded,
                  size: 14,
                  color: OwanyTheme.primaryOrange,
                ),
                label: Text(
                  f.name,
                  style: TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                deleteIcon: Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _pendingSolicitacaoAnexos.remove(f)),
                backgroundColor: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                side: BorderSide(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8),
          Consumer<SolicitacoesProvider>(
            builder: (context, provider, _) {
              return _uploadingSolicitacaoAnexos
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: OwanyTheme.primaryOrange,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _tx('Enviando...', 'Uploading...'),
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                        ),
                      ],
                    )
                  : PrimaryButton.primary(
                      text: _tx('Enviar anexos', 'Upload attachments'),
                      icon: Icons.cloud_upload_rounded,
                      onPressed: () => _uploadAnexosSolicitacao(provider),
                    );
            },
          ),
          SizedBox(height: 12),
        ],
        // Lista de anexos existentes
        if (anexos.isEmpty && _pendingSolicitacaoAnexos.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.attachment_rounded,
                    size: isMobile ? 40 : 48,
                    color: OwanyTheme.borderColor(context).withValues(alpha: 0.5),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    _tx('Nenhum anexo', 'No attachments'),
                    style: TextStyle(
                      color: OwanyTheme.textMutedColor(context),
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (anexos.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < anexos.length; i++) ...[
                  _AnexoTile(
                    anexo: anexos[i],
                    onTap: () => _abrirAnexo(anexos[i].url),
                    isMobile: isMobile,
                  ),
                  if (i < anexos.length - 1)
                    Divider(
                      height: 1,
                      color: OwanyTheme.borderColor(context).withValues(alpha: 0.2),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSection(List<ComentarioDto> comentarios) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final verticalSpacing = isMobile ? 14.0 : 18.0;

    // Filtra comentários baseado no tipo de usuário
    final auth = context.watch<AuthProvider>();
    final userType = auth.usuarioAtual?.tipo;
    final isStaff =
        userType == UsuarioTipo.Administrador ||
        userType == UsuarioTipo.Sindico ||
        userType == UsuarioTipo.Funcionario;

    // Moradores só veem comentários públicos
    final comentariosVisivel = isStaff
        ? comentarios
        : comentarios.where((c) => !c.interno).toList();

    _agendarFocoComentarioSeNecessario(comentariosVisivel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.maintenance_detail_comments(comentariosVisivel.length),
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        if (comentariosVisivel.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 32),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: isMobile ? 40 : 48,
                    color: OwanyTheme.borderColor(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.maintenance_detail_no_comments,
                    style: TextStyle(
                      color: OwanyTheme.textMutedColor(context),
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Lista de comentários com espaçamento maior
          ...List.generate(
            comentariosVisivel.length,
            (i) => Column(
              children: [
                _CommentCard(
                  key: _keyForComment(comentariosVisivel[i].id),
                  comentario: comentariosVisivel[i],
                  solicitacaoId: widget.solicitacaoId,
                  isStaff: isStaff,
                  isMobile: isMobile,
                  isHighlighted:
                      widget.comentarioId?.trim() == comentariosVisivel[i].id,
                  onAbrirAnexo: _abrirAnexo,
                  onRemoverAnexo: null,
                  onEditarAnexo: null,
                ),
                if (i < comentariosVisivel.length - 1)
                  SizedBox(height: verticalSpacing),
              ],
            ),
          ),
        ],
        // Divisor visual acima do campo de comentário
        SizedBox(height: isMobile ? 18 : 24),
        Divider(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.25),
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }

  Widget _buildCommentBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = (viewInsets > 0)
        ? (viewInsets + (isMobile ? 12.0 : 16.0))
        : (isMobile ? 12.0 : 16.0);

    // Apenas staff pode marcar comentário como interno
    final auth = context.watch<AuthProvider>();
    final userType = auth.usuarioAtual?.tipo;
    final isStaff =
        userType == UsuarioTipo.Administrador ||
        userType == UsuarioTipo.Sindico ||
        userType == UsuarioTipo.Funcionario;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16.0,
        isMobile ? 12.0 : 16.0,
        16.0,
        bottomPadding.toDouble(),
      ),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        border: Border(
          top: BorderSide(
            color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.08),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _commentController,
              maxLines: isMobile ? 3 : 4,
              minLines: isMobile ? 2 : 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                )!.maintenance_detail_add_comment,
                hintStyle: TextStyle(
                  color: OwanyTheme.textMutedColor(
                    context,
                  ).withValues(alpha: 0.6),
                  fontSize: isMobile ? 13 : 14,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? OwanyTheme.darkSurface
                    : OwanyTheme.surface,
                prefixIcon: Icon(
                  Icons.comment_outlined,
                  color: OwanyTheme.primaryOrange,
                  size: isMobile ? 20 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: OwanyTheme.borderColor(
                      context,
                    ).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: OwanyTheme.borderColor(
                      context,
                    ).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: OwanyTheme.primaryOrange,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 10 : 12,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 10 : 12),
            if (isMobile)
              // Mobile: Stack vertical
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isStaff)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _isInternal
                            ? OwanyTheme.warning.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isInternal,
                            onChanged: (v) =>
                                setState(() => _isInternal = v ?? false),
                            fillColor: WidgetStateProperty.all(
                              OwanyTheme.warning,
                            ),
                            checkColor: OwanyTheme.cardColor(context),
                            splashRadius: 20,
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.maintenance_detail_internal_comment,
                            style: TextStyle(
                              color: _isInternal
                                  ? OwanyTheme.warning
                                  : OwanyTheme.textMutedColor(context),
                              fontWeight: _isInternal
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isStaff) SizedBox(height: 10),
                  PrimaryButton.primary(
                    text: AppLocalizations.of(context)!.maintenance_detail_send,
                    onPressed: () => _adicionarComentario(
                      context.read<SolicitacoesProvider>(),
                    ),
                    icon: Icons.send_rounded,
                  ),
                ],
              )
            else
              // Desktop: Row horizontal
              Row(
                children: [
                  if (isStaff)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _isInternal
                            ? OwanyTheme.warning.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _isInternal,
                            onChanged: (v) =>
                                setState(() => _isInternal = v ?? false),
                            fillColor: WidgetStateProperty.all(
                              OwanyTheme.warning,
                            ),
                            checkColor: OwanyTheme.cardColor(context),
                            splashRadius: 20,
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.maintenance_detail_internal,
                            style: TextStyle(
                              color: _isInternal
                                  ? OwanyTheme.warning
                                  : OwanyTheme.textMutedColor(context),
                              fontWeight: _isInternal
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    child: PrimaryButton.primary(
                      text: AppLocalizations.of(
                        context,
                      )!.maintenance_detail_send,
                      onPressed: () => _adicionarComentario(
                        context.read<SolicitacoesProvider>(),
                      ),
                      icon: Icons.send_rounded,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Badge funcional "Em manutenção"
class _EmManutencaoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OwanyTheme.info.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OwanyTheme.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_rounded, size: 14, color: OwanyTheme.info),
          SizedBox(width: 6),
          Text(
            'Em manutenção',
            style: TextStyle(
              color: OwanyTheme.info,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// WIDGETS ANTERIORES (sem mudanças)
// =========================

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final SolicitacaoDto solicitacao;
  final String Function(DateTime?) formatDate;
  final String nomeMoradorResolvido;
  final String? categoriaResolvida;
  final String? areasTecnicasResolvidas;
  final String? patrimonioResolvido;

  const _DetailGrid({
    required this.solicitacao,
    required this.formatDate,
    required this.nomeMoradorResolvido,
    this.categoriaResolvida,
    this.areasTecnicasResolvidas,
    this.patrimonioResolvido,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<SolicitacoesProvider>();

    final tiles = [
      _InfoTile(
        label: l10n.maintenance_detail_requester,
        value: _buildSolicitante(),
        icon: Icons.person_outline_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_apartment,
        value: _buildApartamento(context),
        icon: Icons.apartment_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_resident,
        value: nomeMoradorResolvido,
        icon: Icons.person_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_responsible,
        value: solicitacao.nomeResponsavel ?? '-',
        icon: Icons.handyman_rounded,
      ),
      _InfoTile(
        label: 'Categoria',
        value: _buildCategoria(provider),
        icon: Icons.category_rounded,
      ),
      _InfoTile(
        label: 'Área técnica',
        value: _buildAreasTecnicas(provider),
        icon: Icons.room_service_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_created_at,
        value: formatDate(solicitacao.criadoEm),
        icon: Icons.calendar_month_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_deadline,
        value: formatDate(solicitacao.prazoLimite),
        icon: Icons.timer_rounded,
      ),
      _InfoTile(
        label: l10n.maintenance_detail_updated_at,
        value: formatDate(solicitacao.atualizadoEm),
        icon: Icons.update_rounded,
      ),
      if (solicitacao.itemApartamentoNome != null &&
          solicitacao.itemApartamentoNome!.isNotEmpty)
        _InfoTile(
          label: 'Item Vinculado',
          value: solicitacao.itemApartamentoNome!,
          icon: Icons.inventory_2_rounded,
        ),
      if (_buildPatrimonio().isNotEmpty)
        _InfoTile(
          label: 'Patrimônio',
          value: _buildPatrimonio(),
          icon: Icons.qr_code_rounded,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(children: tiles)
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: tiles
                  .map(
                    (t) => SizedBox(
                      width:
                          (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
                      child: t,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  String _buildSolicitante() {
    return solicitacao.nomeUsuarioCriador;
  }

  String _buildApartamento(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final numero = solicitacao.numeroApartamento;
    final bloco = solicitacao.blocoApartamento;
    if (numero.isEmpty && bloco.isEmpty) return '-';
    if (numero.isNotEmpty && bloco.isNotEmpty)
      return l10n.maintenance_apt_block(numero, bloco);
    return numero.isNotEmpty ? 'Nº $numero' : bloco;
  }

  String _buildCategoria(SolicitacoesProvider provider) {
    final resolved = categoriaResolvida?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;

    final nome = solicitacao.tipoSolicitacaoNome?.trim();
    if (nome != null && nome.isNotEmpty) return nome;

    final tipoId = solicitacao.tipoSolicitacaoId?.trim();
    if (tipoId == null || tipoId.isEmpty) return '-';

    final tipo = provider.tiposSolicitacao
        .where((t) => t.id.toLowerCase() == tipoId.toLowerCase())
        .firstOrNull;
    if (tipo != null && tipo.nome.trim().isNotEmpty) {
      return tipo.nome.trim();
    }
    return tipoId;
  }

  String _buildAreasTecnicas(SolicitacoesProvider provider) {
    final resolvedAreas = areasTecnicasResolvidas?.trim();
    if (resolvedAreas != null && resolvedAreas.isNotEmpty) return resolvedAreas;

    final nomes = solicitacao.areaTecnicaNomes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (nomes.isNotEmpty) {
      return nomes.join(', ');
    }

    final ids = solicitacao.areaTecnicaIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (ids.isEmpty) return '-';

    final resolved = <String>[];
    for (final id in ids) {
      final area = provider.areasTecnicas.where((a) => a.id == id).firstOrNull;
      resolved.add(
        area?.nome.trim().isNotEmpty == true ? area!.nome.trim() : id,
      );
    }
    return resolved.join(', ');
  }

  String _buildPatrimonio() {
    final resolved = patrimonioResolvido?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return solicitacao.itemApartamentoCodigoPatrimonio?.trim() ?? '';
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      margin: isMobile ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: OwanyTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: OwanyTheme.primaryOrange,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final ComentarioDto comentario;
  final bool isMobile;
  final bool isHighlighted;
  final bool isStaff;
  final String solicitacaoId;
  final Future<void> Function(String anexoId)? onRemoverAnexo;
  final Future<void> Function(String anexoId, String? nomeArquivo, List<int>? bytes, String? fileName)? onEditarAnexo;
  final Future<void> Function(String url)? onAbrirAnexo;

  const _CommentCard({
    super.key,
    required this.comentario,
    required this.solicitacaoId,
    this.isMobile = false,
    this.isHighlighted = false,
    this.isStaff = false,
    this.onRemoverAnexo,
    this.onEditarAnexo,
    this.onAbrirAnexo,
  });

  @override
  Widget build(BuildContext context) {
    final isInternal = comentario.interno;
    final isMobileView = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.only(bottom: isMobileView ? 10 : 12),
      padding: EdgeInsets.all(isMobileView ? 12 : 14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? OwanyTheme.primaryOrange.withValues(alpha: 0.12)
            : (isInternal
                  ? OwanyTheme.warning.withValues(alpha: 0.05)
                  : OwanyTheme.cardColor(context)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? OwanyTheme.primaryOrange.withValues(alpha: 0.75)
              : (isInternal
                    ? OwanyTheme.warning.withValues(alpha: 0.2)
                    : OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          width: isHighlighted ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobileView ? 32 : 36,
                height: isMobileView ? 32 : 36,
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    comentario.nomeUsuario[0].toUpperCase(),
                    style: TextStyle(
                      color: OwanyTheme.primaryOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobileView ? 12 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobileView ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comentario.nomeUsuario,
                            style: TextStyle(
                              color: OwanyTheme.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: isMobileView ? 13 : 14,
                            ),
                          ),
                        ),
                        if (isInternal)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobileView ? 6 : 8,
                              vertical: isMobileView ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: OwanyTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: isMobileView ? 10 : 12,
                                  color: OwanyTheme.warning,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  AppLocalizations.of(context)!.common_internal,
                                  style: TextStyle(
                                    color: OwanyTheme.warning,
                                    fontSize: isMobileView ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatDateTime(comentario.criadoEm, context),
                      style: TextStyle(
                        fontSize: isMobileView ? 11 : 12,
                        color: OwanyTheme.textMutedColor(
                          context,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobileView ? 10 : 12),
          Text(
            comentario.mensagem,
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontSize: isMobileView ? 12 : 13,
              height: 1.4,
            ),
          ),
          // Anexos do comentário
          if (comentario.anexos.isNotEmpty) ...[
            SizedBox(height: isMobileView ? 8 : 10),
            Divider(
              height: 1,
              color: OwanyTheme.borderColor(context).withValues(alpha: 0.15),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: comentario.anexos
                  .map((a) => _buildAnexoChip(context, a))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnexoChip(BuildContext context, AnexoComentarioDto a) {
    IconData icone;
    Color cor;
    if (a.isImagem) {
      icone = Icons.image_outlined;
      cor = OwanyTheme.info;
    } else if (a.isPdf) {
      icone = Icons.picture_as_pdf_outlined;
      cor = OwanyTheme.error;
    } else if (a.isZip) {
      icone = Icons.folder_zip_outlined;
      cor = OwanyTheme.warning;
    } else {
      icone = Icons.attach_file_rounded;
      cor = OwanyTheme.primaryOrange;
    }

    final canEdit = onEditarAnexo != null || onRemoverAnexo != null;

    return GestureDetector(
      onTap: onAbrirAnexo != null ? () => onAbrirAnexo!(a.url) : null,
      onLongPress: canEdit
          ? () => _showAnexoOptionsDialog(context, a)
          : null,
      child: Chip(
        avatar: Icon(icone, size: 14, color: cor),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.nomeArquivo,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (a.tamanhoFormatado.isNotEmpty)
              Text(
                a.tamanhoFormatado,
                style: TextStyle(
                  fontSize: 10,
                  color: OwanyTheme.textMutedColor(context),
                ),
              ),
          ],
        ),
        backgroundColor: cor.withValues(alpha: 0.08),
        side: BorderSide(color: cor.withValues(alpha: 0.25)),
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  void _showAnexoOptionsDialog(BuildContext context, AnexoComentarioDto a) {
    final nomeController = TextEditingController(text: a.nomeArquivo);
    List<int>? pendingBytes;
    String? pendingFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return ThemedAlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit_outlined, color: OwanyTheme.primaryOrange, size: 20),
                SizedBox(width: 8),
                Text('Editar anexo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Renomear
                Text('Nome do arquivo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: OwanyTheme.textMuted)),
                SizedBox(height: 6),
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 14),
                // Substituir arquivo
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pendingFileName != null
                            ? pendingFileName!
                            : 'Nenhum arquivo selecionado',
                        style: TextStyle(
                            fontSize: 12,
                            color: pendingFileName != null
                                ? OwanyTheme.success
                                : OwanyTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setDialogState(() {
                            pendingBytes = result.files.first.bytes;
                            pendingFileName = result.files.first.name;
                            if (nomeController.text.isEmpty) {
                              nomeController.text = result.files.first.name;
                            }
                          });
                        }
                      },
                      icon: Icon(Icons.upload_file_outlined, size: 16),
                      label: Text('Substituir', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OwanyTheme.primaryOrange,
                        side: BorderSide(color: OwanyTheme.primaryOrange),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Remover
              if (onRemoverAnexo != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onRemoverAnexo!(a.id);
                  },
                  icon: Icon(Icons.delete_outline, size: 16, color: OwanyTheme.error),
                  label: Text('Remover', style: TextStyle(color: OwanyTheme.error, fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar'),
              ),
              // Salvar
              if (onEditarAnexo != null)
                ElevatedButton(
                  onPressed: () {
                    final novoNome = nomeController.text.trim();
                    final nomeAlterado = novoNome != a.nomeArquivo && novoNome.isNotEmpty;
                    if (!nomeAlterado && pendingBytes == null) {
                      Navigator.pop(ctx);
                      return;
                    }
                    Navigator.pop(ctx);
                    onEditarAnexo!(
                      a.id,
                      nomeAlterado ? novoNome : null,
                      pendingBytes,
                      pendingFileName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OwanyTheme.primaryOrange,
                    foregroundColor: OwanyTheme.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: Text('Salvar'),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt, BuildContext context) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final l10n = AppLocalizations.of(context)!;
    return '${dt.day}/${dt.month}/${dt.year} ${l10n.maintenance_detail_at_time('$hour:$minute')}';
  }
}

// =========================
// STATUS HELPERS
// =========================

Color _getStatusColor(String status) {
  if (status.contains('Pendente')) return OwanyTheme.warning;
  if (status.contains('EmAnalise')) return const Color(0xFF7C3AED); // Purple
  if (status.contains('EmAndamento')) return OwanyTheme.info;
  if (status.contains('Concluido')) return OwanyTheme.success;
  if (status.contains('Cancelado')) return OwanyTheme.error;
  return OwanyTheme.textMuted;
}

String _getStatusLabel(String status, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  if (status.contains('Pendente')) return l10n.maintenance_status_pending;
  if (status.contains('EmAnalise')) return l10n.maintenance_status_in_analysis;
  if (status.contains('EmAndamento'))
    return l10n.maintenance_status_in_progress;
  if (status.contains('Concluido')) return l10n.maintenance_status_completed;
  if (status.contains('Cancelado')) return l10n.maintenance_status_cancelled;
  return l10n.maintenance_detail_unknown;
}

SolicitacaoDto? _resolveSolicitacao(SolicitacoesProvider provider) {
  return provider.solicitacaoAtual;
}

IconData _getStatusIcon(String status) {
  if (status.contains('Pendente')) return Icons.schedule_rounded;
  if (status.contains('EmAnalise')) return Icons.search_rounded;
  if (status.contains('EmAndamento')) return Icons.autorenew_rounded;
  if (status.contains('Concluido')) return Icons.check_circle_rounded;
  if (status.contains('Cancelado')) return Icons.cancel_rounded;
  return Icons.help_outline_rounded;
}

// =========================
// ANEXO TILE WIDGET
// =========================
class _AnexoTile extends StatelessWidget {
  final AnexoDto anexo;
  final VoidCallback onTap;
  final bool isMobile;

  const _AnexoTile({
    required this.anexo,
    required this.onTap,
    required this.isMobile,
  });

  IconData _getIconForType(String tipo) {
    if (tipo.startsWith('image/')) return Icons.image_rounded;
    if (tipo.startsWith('video/')) return Icons.video_file_rounded;
    if (tipo.startsWith('audio/')) return Icons.audio_file_rounded;
    if (tipo.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (tipo.contains('word') || tipo.contains('document')) return Icons.description_rounded;
    if (tipo.contains('excel') || tipo.contains('spreadsheet')) return Icons.table_chart_rounded;
    if (tipo.contains('zip') || tipo.contains('rar') || tipo.contains('compressed')) return Icons.folder_zip_rounded;
    return Icons.attach_file_rounded;
  }

  Color _getColorForType(String tipo) {
    if (tipo.startsWith('image/')) return const Color(0xFF7C3AED); // Purple
    if (tipo.startsWith('video/')) return OwanyTheme.info;
    if (tipo.startsWith('audio/')) return const Color(0xFFF59E0B); // Amber
    if (tipo.contains('pdf')) return OwanyTheme.error;
    if (tipo.contains('word') || tipo.contains('document')) return OwanyTheme.info;
    if (tipo.contains('excel') || tipo.contains('spreadsheet')) return OwanyTheme.success;
    return OwanyTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType(anexo.tipoConteudo);
    final color = _getColorForType(anexo.tipoConteudo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anexo.nomeArquivo,
                    style: TextStyle(
                      color: OwanyTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    anexo.tamanhoFormatado,
                    style: TextStyle(
                      color: OwanyTheme.textMutedColor(context),
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              color: OwanyTheme.primaryOrange,
              size: isMobile ? 20 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
