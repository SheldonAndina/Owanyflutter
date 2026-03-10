import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:provider/provider.dart';
import '../../dto/solicitacoes_v2_dtos.dart';
import '../../dto/area_tecnica_dto.dart';
import '../../theme/owany_theme.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/apartamentos_provider.dart';
import '../../providers/moradores_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import '../../services/solicitacoes_service.dart';
import '../../screens/utility/qr_scan_screen.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../utils/app_logger.dart';

class MaintenanceRequestScreen extends StatefulWidget {
  const MaintenanceRequestScreen({super.key});

  @override
  State<MaintenanceRequestScreen> createState() =>
      _MaintenanceRequestScreenState();
}

class _MaintenanceRequestScreenState extends State<MaintenanceRequestScreen>
    with SingleTickerProviderStateMixin {
  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  late AnimationController _animController;
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _areaSelecionadoId;
  List<PlatformFile> _selectedFiles = [];
  String? _apartamentoSelecionado;
  String? _moradorSelecionado;
  String? _itemApartamentoSelecionadoId;
  String? _itemApartamentoNome;
  bool _initializedFromArgs = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
    // Usar addPostFrameCallback para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final apartamentosProv = context.read<ApartamentosProvider>();
    final moradoresProv = context.read<MoradoresProvider>();
    final solicitacoesProv = context.read<SolicitacoesProvider>();

    // Auto-fill morador data first
    final moradorInfo = authProvider.usuarioAtual?.moradorInfo;
    AppLogger.info(
      'MaintenanceRequestScreen',
      'Init: moradorInfo=${moradorInfo != null}, aptId=${moradorInfo?.apartamentoId ?? "null"}',
    );

    if (moradorInfo != null) {
      // Verificar se apartamentoId existe E não é vazio
      final aptId = moradorInfo.apartamentoId;
      if (aptId.isNotEmpty) {
        _apartamentoSelecionado = aptId;
        _moradorSelecionado = moradorInfo.moradorId;
        AppLogger.info(
          'MaintenanceRequestScreen',
          'Apartamento definido: $_apartamentoSelecionado',
        );
        // Chamada imediata de setState para exibir item selector logo
        if (mounted) {
          setState(() {});
        }
      } else {
        AppLogger.warning(
          'MaintenanceRequestScreen',
          'ApartamentoId está vazio',
        );
      }
    }

    // Load all data in parallel
    await Future.wait([
      apartamentosProv.carregarApartamentos(),
      moradoresProv.carregarMoradores(),
      solicitacoesProv.loadAreas(),
    ]);

    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['apartamentoId'] is String) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.usuarioAtual?.moradorInfo == null) {
        _apartamentoSelecionado = args['apartamentoId'] as String;
      }
    }
    _initializedFromArgs = true;
  }

  @override
  void dispose() {
    _animController.dispose();
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _criarSolicitacao() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        AppLocalizations.of(context)!.maintenance_request_fill_required,
        SnackBarType.warning,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final isStaff =
        authProvider.isAdmin ||
        authProvider.isFuncionario ||
        authProvider.isSindico;

    if (_areaSelecionadoId == null || _areaSelecionadoId!.isEmpty) {
      _showSnackBar(
        'Por favor, selecione a categoria',
        SnackBarType.warning,
      );
      return;
    }

    final usuario = authProvider.usuarioAtual;

    if (_apartamentoSelecionado == null && isStaff) {
      _showSnackBar(
        AppLocalizations.of(
          context,
        )!.maintenance_request_select_apartment_error,
        SnackBarType.warning,
      );
      return;
    }

    if (usuario == null) {
      _showSnackBar(
        AppLocalizations.of(
          context,
        )!.maintenance_request_user_not_authenticated,
        SnackBarType.error,
      );
      return;
    }

    // Determine moradorId
    String? moradorId;
    String? apartamentoId;
    if (isStaff) {
      // Staff precisa selecionar morador e apartamento
      moradorId = _moradorSelecionado;
      apartamentoId = _apartamentoSelecionado;
      if (moradorId == null || moradorId.isEmpty) {
        _showSnackBar(
          AppLocalizations.of(
            context,
          )!.maintenance_request_select_resident_error,
          SnackBarType.warning,
        );
        return;
      }
      if (apartamentoId == null || apartamentoId.isEmpty) {
        _showSnackBar(
          AppLocalizations.of(
            context,
          )!.maintenance_request_select_apartment_error,
          SnackBarType.warning,
        );
        return;
      }
    } else {
      // Morador: backend auto-popula moradorId/apartamentoId a partir do JWT
      // Envia se disponível localmente, mas não bloqueia se ausente
      moradorId = usuario.moradorInfo?.moradorId;
      apartamentoId =
          _apartamentoSelecionado ?? usuario.moradorInfo?.apartamentoId;
    }

    setState(() => _isSubmitting = true);

    try {
      final solicitacoesProvider = context.read<SolicitacoesProvider>();
      final descricao = _descricaoController.text.trim();

      final dto = CriarSolicitacaoDto(
        titulo: _tituloController.text.trim(),
        descricao: descricao.isEmpty ? null : descricao,
        moradorId: moradorId,
        apartamentoId: apartamentoId,
        itemApartamentoId: _itemApartamentoSelecionadoId,
        areaTecnicaId: _areaSelecionadoId,
        areaTecnicaIds: _areaSelecionadoId != null
            ? [_areaSelecionadoId!]
            : null,
      );

      AppLogger.info(
        'MaintenanceRequestScreen',
        'Criando solicitação: apt=$apartamentoId, morador=$moradorId, area=$_areaSelecionadoId',
      );
      AppLogger.debug(
        'MaintenanceRequestScreen',
        'Payload criarSolicitacao: ${dto.toJson()}',
      );
      // Cria solicitação via service para obter o ID retornado
      final serv = SolicitacoesService();
      final solicitacaoCriada = await serv.criarSolicitacao(dto);
      AppLogger.info(
        'MaintenanceRequestScreen',
        'Solicitação criada: id=${solicitacaoCriada.id}',
      );

      // Envia anexos selecionados (se houver)
      if (_selectedFiles.isNotEmpty) {
        for (final pf in _selectedFiles) {
          try {
            List<int>? bytes;
            // Primeiro tenta usar bytes já carregados (web ou desktop)
            if (pf.bytes != null && pf.bytes!.isNotEmpty) {
              bytes = pf.bytes!;
            } else if (!kIsWeb && pf.path != null) {
              // Em mobile/desktop, lê do path se bytes vazio
              bytes = await File(pf.path!).readAsBytes();
            }
            
            if (bytes == null || bytes.isEmpty) {
              AppLogger.warning('MaintenanceRequestScreen', 'Anexo ${pf.name} sem bytes, pulando.');
              continue;
            }
            
            final ok = await solicitacoesProvider.uploadAnexo(solicitacaoCriada.id, bytes, pf.name);
            if (ok) {
              AppLogger.info('MaintenanceRequestScreen', 'Anexo enviado: ${pf.name}');
            } else {
              AppLogger.error('MaintenanceRequestScreen', 'Falha ao enviar anexo: ${pf.name}');
            }
          } catch (e) {
            AppLogger.error('MaintenanceRequestScreen', 'Erro ao enviar anexo ${pf.name}: $e');
          }
        }
      }

      // Carrega detalhes da solicitação criada (inclui anexos enviados)
      try {
        await solicitacoesProvider.loadSolicitacao(solicitacaoCriada.id);
      } catch (_) {}

      // Atualiza lista local e notifica sucesso
      final auth = context.read<AuthProvider>();
      String? aptId;
      String? respId;
      if (auth.isMorador) aptId = auth.apartamentoIdDoMorador;
      if (auth.isFuncionario) respId = auth.usuarioAtual?.id;
      await solicitacoesProvider.loadSolicitacoes(
        apartamentoId: aptId,
        responsavelId: respId,
        refresh: true,
      );
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context)!.maintenance_request_success,
        SnackBarType.success,
      );
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '${AppLocalizations.of(context)!.common_error}: ${e.toString()}',
        SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, SnackBarType type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(OwanyTheme.snackBar(message, type: type));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.maintenance_request_title,
        icon: Icons.build_rounded,
        showBackButton: true,
      ),
      body:
          Consumer3<
            SolicitacoesProvider,
            ApartamentosProvider,
            MoradoresProvider
          >(
            builder:
                (
                  context,
                  solicitacoesProvider,
                  apartamentosProvider,
                  moradoresProvider,
                  _,
                ) {
                  final authProvider = context.read<AuthProvider>();
                  final showMoradorSelector =
                      authProvider.isAdmin ||
                      authProvider.isFuncionario ||
                      authProvider.isSindico;

                  return FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animController,
                        curve: Curves.easeIn,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(context),
                            const SizedBox(height: 20),
                            _buildAreaSelector(
                              context,
                              solicitacoesProvider,
                            ),
                            const SizedBox(height: 20),
                            _buildTituloField(context),
                            const SizedBox(height: 20),
                            _buildDescricaoField(context),
                            const SizedBox(height: 20),
                            if (showMoradorSelector) ...[
                              _buildMoradorSelector(context, moradoresProvider),
                              const SizedBox(height: 20),
                            ],
                            _buildApartamentoField(
                              context,
                              apartamentosProvider,
                              showMoradorSelector,
                            ),
                            const SizedBox(height: 20),
                            _buildItemApartamentoSelector(context),
                            const SizedBox(height: 12),
                            // Attachment picker
                            Text(
                              AppLocalizations.of(context)!.maintenance_request_attachments_optional ?? 'Anexos (opcional)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._selectedFiles.map((f) => Chip(
                                      label: Text(f.name, overflow: TextOverflow.ellipsis),
                                      onDeleted: () => setState(() => _selectedFiles.remove(f)),
                                    )),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
                                    if (res == null) return;
                                    setState(() {
                                      _selectedFiles = [..._selectedFiles, ...res.files];
                                    });
                                  },
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(AppLocalizations.of(context)!.maintenance_request_add_attachment),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActionButtons(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.primaryOrange.withValues(alpha: 0.1),
            OwanyTheme.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.build_rounded,
              color: OwanyTheme.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.maintenance_request_describe_problem,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.maintenance_request_describe_hint,
                  style: TextStyle(
                    color: OwanyTheme.textMutedColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaSelector(
    BuildContext context,
    SolicitacoesProvider provider,
  ) {
    // Mostrar todas as áreas técnicas disponíveis (independente do tipo selecionado)
    final List<AreaTecnicaDto> available = provider.areasTecnicas;

    if (provider.isLoadingAreas && available.isEmpty) {
      return const SizedBox.shrink();
    }

    if (available.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categoria *',
            style: TextStyle(
              color: OwanyTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwanyTheme.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: OwanyTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhuma categoria disponível no momento.',
                    style: TextStyle(color: OwanyTheme.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria *',
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: OwanyTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _areaSelecionadoId,
            dropdownColor: OwanyTheme.cardColor(context),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.room_service_rounded,
                color: OwanyTheme.primaryOrange,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: available
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      a.nome,
                      style: TextStyle(
                        color: OwanyTheme.textPrimary(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _areaSelecionadoId = value),
            hint: Text(
              'Selecione a categoria',
              style: TextStyle(
                color: OwanyTheme.textMutedColor(
                  context,
                ).withValues(alpha: 0.6),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecione a categoria';
              }
              return null;
            },
            isExpanded: true,
            icon: const Icon(
              Icons.expand_more_rounded,
              color: OwanyTheme.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTituloField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.maintenance_request_subject,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tituloController,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(
              context,
            )!.maintenance_request_subject_hint,
            hintStyle: TextStyle(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(
              Icons.subject_rounded,
              color: OwanyTheme.primaryOrange,
            ),
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
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? OwanyTheme.darkSurface
                : OwanyTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (v) => (v?.isEmpty ?? true)
              ? AppLocalizations.of(context)!.common_required_field
              : null,
        ),
      ],
    );
  }

  Widget _buildDescricaoField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.maintenance_request_description,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descricaoController,
          maxLines: 5,
          minLines: 3,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(
              context,
            )!.maintenance_request_description_hint,
            hintStyle: TextStyle(
              color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.6),
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(top: 12, right: 12),
              child: Icon(
                Icons.description_rounded,
                color: OwanyTheme.primaryOrange,
              ),
            ),
            alignLabelWithHint: true,
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
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? OwanyTheme.darkSurface
                : OwanyTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (v) => (v?.isEmpty ?? true)
              ? AppLocalizations.of(context)!.common_required_field
              : null,
        ),
      ],
    );
  }

  Widget _buildMoradorSelector(
    BuildContext context,
    MoradoresProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.maintenance_request_resident_responsible,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (provider.isLoading)
          _buildLoadingContainer(context)
        else
          Container(
            decoration: BoxDecoration(
              color: OwanyTheme.backgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _moradorSelecionado,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.person_rounded,
                  color: OwanyTheme.primaryOrange,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: provider.moradores
                  .map(
                    (morador) => DropdownMenuItem(
                      value: morador.id,
                      child: Text(
                        morador.nome,
                        style: TextStyle(
                          color: OwanyTheme.textPrimary(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _moradorSelecionado = value),
              hint: Text(
                AppLocalizations.of(
                  context,
                )!.maintenance_request_select_resident,
                style: TextStyle(
                  color: OwanyTheme.textMutedColor(
                    context,
                  ).withValues(alpha: 0.6),
                ),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: OwanyTheme.primaryOrange,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApartamentoField(
    BuildContext context,
    ApartamentosProvider provider,
    bool showMoradorSelector,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.maintenance_request_apartment,
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (provider.isLoading)
          _buildLoadingContainer(context)
        else if (!showMoradorSelector)
          _buildReadOnlyApartamento(context, provider)
        else
          _buildEditableApartamento(context, provider),
      ],
    );
  }

  Widget _buildReadOnlyApartamento(
    BuildContext context,
    ApartamentosProvider provider,
  ) {
    final apartamentoNome =
        provider.apartamentos
            .where((apt) => apt.id == _apartamentoSelecionado)
            .map((apt) => apt.nome)
            .firstOrNull ??
        'Apartamento não encontrado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OwanyTheme.backgroundColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.apartment_rounded,
            color: OwanyTheme.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              apartamentoNome,
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableApartamento(
    BuildContext context,
    ApartamentosProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _apartamentoSelecionado,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.apartment_rounded,
            color: OwanyTheme.primaryOrange,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: provider.apartamentos
            .map(
              (apt) => DropdownMenuItem(
                value: apt.id,
                child: Text(
                  apt.nome,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 14,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _apartamentoSelecionado = value),
        hint: Text(
          AppLocalizations.of(context)!.maintenance_request_select_apartment,
          style: TextStyle(
            color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.6),
          ),
        ),
        isExpanded: true,
        icon: const Icon(
          Icons.expand_more_rounded,
          color: OwanyTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildLoadingContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: OwanyTheme.primaryOrange),
      ),
    );
  }

  Widget _buildItemApartamentoSelector(BuildContext context) {
    if (_apartamentoSelecionado == null || _apartamentoSelecionado!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item/Ativo vinculado (opcional)',
          style: TextStyle(
            color: OwanyTheme.textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: OwanyTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              if (_itemApartamentoSelecionadoId != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OwanyTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: OwanyTheme.success,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _itemApartamentoNome ?? 'Item selecionado',
                    style: TextStyle(
                      color: OwanyTheme.textPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: OwanyTheme.error,
                      size: 20,
                    ),
                    onPressed: () => setState(() {
                      _itemApartamentoSelecionadoId = null;
                      _itemApartamentoNome = null;
                    }),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showItemPicker(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: OwanyTheme.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Selecionar item do apartamento',
                                  style: TextStyle(
                                    color: OwanyTheme.textMutedColor(
                                      context,
                                    ).withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: OwanyTheme.borderColor(
                              context,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: OwanyTheme.primaryOrange,
                        ),
                        onPressed: () => _scanItemQrCode(),
                        tooltip: _tx('Escanear QR Code', 'Scan QR Code'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showItemPicker() async {
    if (_apartamentoSelecionado == null) return;

    try {
      final items = await ApiService().getItensApartamento(
        _apartamentoSelecionado!,
      );
      if (!mounted) return;

      if (items.isEmpty) {
        _showSnackBar(
          _tx('Nenhum item vinculado a este apartamento', 'No item linked to this apartment'),
          SnackBarType.info,
        );
        return;
      }

      final selected = await showModalBottomSheet<ItemApartamento>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: OwanyTheme.cardColor(context),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OwanyTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        color: OwanyTheme.primaryOrange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _tx('Selecionar Item', 'Select Item'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: OwanyTheme.primaryOrange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: OwanyTheme.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          item.codigoPatrimonio ?? item.tipo ?? '',
                          style: TextStyle(
                            color: OwanyTheme.textMutedColor(context),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );

      if (selected != null && mounted) {
        setState(() {
          _itemApartamentoSelecionadoId = selected.id;
          _itemApartamentoNome = selected.nome;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          '${_tx('Erro ao carregar itens', 'Error loading items')}: ${e.toString()}',
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _scanItemQrCode() async {
    String? codigo;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      codigo = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      );
    } else {
      final controller = TextEditingController();
      codigo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: OwanyTheme.cardColor(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: OwanyTheme.primaryOrange,
              ),
              const SizedBox(width: 12),
              Text(
                _tx('Código do patrimônio', 'Asset code'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: OwanyTheme.textPrimary(ctx),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
            decoration: OwanyTheme.adaptiveInputDecoration(
              ctx,
              label: _tx('Código', 'Code'),
              hint: 'PAT-...',
              icon: Icons.fingerprint_rounded,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tx('Cancelar', 'Cancel'),
                  style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.primaryOrange,
              ),
              child: Text(_tx('Buscar', 'Search')),
            ),
          ],
        ),
      );
    }

    if (codigo == null || codigo.isEmpty || !mounted) return;

    try {
      final item = await ApiService().getItemApartamentoPorPatrimonio(codigo);
      if (mounted) {
        setState(() {
          _itemApartamentoSelecionadoId = item.id;
          _itemApartamentoNome = item.nome;
        });
        _showSnackBar('Item encontrado: ${item.nome}', SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Item não encontrado com o código: $codigo',
          SnackBarType.error,
        );
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PrimaryButton.primary(
            text: _isSubmitting
                ? AppLocalizations.of(context)!.maintenance_request_sending
                : AppLocalizations.of(context)!.maintenance_request_create,
            onPressed: _isSubmitting ? null : _criarSolicitacao,
            icon: _isSubmitting ? null : Icons.check_circle_rounded,
            isLoading: _isSubmitting,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton.secondary(
            text: AppLocalizations.of(context)!.common_cancel,
            onPressed: () => Navigator.pop(context),
            icon: Icons.close_rounded,
          ),
        ),
      ],
    );
  }
}

