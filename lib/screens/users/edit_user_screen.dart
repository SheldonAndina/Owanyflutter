import 'package:flutter/material.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_date_time.dart';
import '../../widgets/primary_button.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';
import '../../widgets/standard_glass_app_bar.dart';

class EditUserScreen extends StatefulWidget {
  final String usuarioId;

  const EditUserScreen({required this.usuarioId, super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
    final _phoneMaskFormatter = MaskTextInputFormatter(mask: '+258 ##-#######');
  final _apiService = ApiService();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _nomeLogin;

  late Future<Usuario> _usuarioFuture;
  late UsuarioTipo _tipoSelecionado;
  bool _isLoading = false;
  bool _didFetch = false;

  /// Parse role string to UsuarioTipo using the extension method that handles accents
  UsuarioTipo _parseUsuarioTipo(String role) {
    try {
      return UsuarioTipoExtension.fromString(role);
    } catch (e) {
      return UsuarioTipo.Morador;
    }
  }

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = UsuarioTipo.Funcionario;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didFetch) return;
    _didFetch = true;
    _usuarioFuture = _loadUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<Usuario> _loadUsuario() async {
    final dto = await _apiService.getUsuario(widget.usuarioId);
    if (mounted) {
      _nomeController.text = dto.nome;
      _telefoneController.text = dto.telefone;
      _nomeLogin = dto.nomeLogin;
      _tipoSelecionado = _parseUsuarioTipo(dto.role);
    }
    return Usuario(
      id: dto.id,
      nome: dto.nome,
      nomeLogin: dto.nomeLogin,
      telefone: dto.telefone,
      tipo: _tipoSelecionado,
      ativo: dto.ativo,
      criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
    );
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Normalizar telefone para apenas dígitos e prefixo 258
      String telefoneNumerico = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
      if (telefoneNumerico.length == 9) {
        telefoneNumerico = '258$telefoneNumerico';
      } else if (telefoneNumerico.length == 12 && telefoneNumerico.startsWith('258')) {
        // ok
      } else if (telefoneNumerico.length > 12 && telefoneNumerico.startsWith('258')) {
        telefoneNumerico = telefoneNumerico.substring(0, 12);
      }

      await _apiService.atualizarUsuario(
        widget.usuarioId, // primeiro parâmetro posicional
        nome: _nomeController.text.trim(),
        telefone: telefoneNumerico,
        ativo: true, // manter ativo durante edição
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(AppLocalizations.of(context)!.users_updated_success, type: SnackBarType.success),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${AppLocalizations.of(context)!.common_error}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetarSenha() async {
    final l10n = AppLocalizations.of(context)!;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.users_reset_confirm),
        content: Text(l10n.users_reset_description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: OwanyTheme.warning),
            child: Text(l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirma != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      if (_nomeLogin == null || _nomeLogin!.trim().isEmpty) {
        throw Exception(AppLocalizations.of(context)!.users_error_login_name_not_found);
      }
      // Chamar endpoint de reset de senha
      await _apiService.solicitarReset(_nomeLogin!.trim());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(OwanyTheme.snackBar(AppLocalizations.of(context)!.users_reset_sent, type: SnackBarType.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${AppLocalizations.of(context)!.users_error_reset}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _desativarUsuario() async {
    final l10n = AppLocalizations.of(context)!;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.users_deactivate),
        content: Text(l10n.users_deactivate_description(_nomeController.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: OwanyTheme.error),
            child: Text(l10n.users_deactivate_button),
          ),
        ],
      ),
    );

    if (confirma != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.desativarUsuario(widget.usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(AppLocalizations.of(context)!.users_deactivated_success, type: SnackBarType.success),
        );
        Navigator.pop(context, true); // Retorna true para indicar que houve mudança
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${AppLocalizations.of(context)!.users_error_deactivate}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: OwanyTheme.textDark),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: OwanyTheme.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OwanyTheme.borderColor(context)),
      boxShadow: [
        BoxShadow(
          color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon, String? hint, bool enabled = true}) {
    return OwanyTheme.inputDecoration(
      context: context,
      label: label,
      hint: hint,
      icon: icon,
      dark: Theme.of(context).brightness == Brightness.dark,
    ).copyWith(
      enabled: enabled,
      fillColor: OwanyTheme.cardColor(context),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OwanyTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_rounded, color: OwanyTheme.error),
              ),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.morador_error_loading,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 16),
              PrimaryButton.primary(
                text: AppLocalizations.of(context)!.common_retry,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.users_edit_title,
        icon: Icons.edit_rounded,
        showBackButton: true,
      ),
      body: FutureBuilder<Usuario>(
        future: _usuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange)),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState('${AppLocalizations.of(context)!.common_error}: ${snapshot.error}', () {
              setState(() {
                _usuarioFuture = _loadUsuario();
              });
            });
          }

          if (snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OwanyTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.info_rounded, color: OwanyTheme.warning),
                      ),
                      SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.users_not_found,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.users_no_results_subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                          OwanyTheme.softOrange.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: OwanyTheme.primaryOrange.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.manage_accounts_rounded, color: OwanyTheme.primaryOrange, size: 26),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.users_update_data,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: OwanyTheme.textPrimary(context),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(context)!.users_update_info,
                                style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.badge_rounded, color: OwanyTheme.primaryOrange),
                            ),
                            SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.users_data,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OwanyTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        _buildLabel(AppLocalizations.of(context)!.users_full_name_label),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _nomeController,
                          style: TextStyle(
                            color: OwanyTheme.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.users_full_name,
                            hint: AppLocalizations.of(context)!.users_full_name_example,
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppLocalizations.of(context)!.common_required_field
                              : null,
                        ),
                        SizedBox(height: 16),

                        _buildLabel(AppLocalizations.of(context)!.users_phone),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _telefoneController,
                          style: TextStyle(
                            color: OwanyTheme.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.users_phone,
                            hint: AppLocalizations.of(context)!.users_phone_example,
                            icon: Icons.phone_rounded,
                          ),
                          keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneMaskFormatter],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppLocalizations.of(context)!.common_required_field
                                : null,
                        ),
                        SizedBox(height: 16),

                        _buildLabel(AppLocalizations.of(context)!.users_user_type),
                        SizedBox(height: 8),
                        DropdownButtonFormField<UsuarioTipo>(
                          initialValue: _tipoSelecionado,
                          decoration: _inputDecoration(
                            label: AppLocalizations.of(context)!.users_user_type,
                            icon: Icons.security_rounded,
                            enabled: false,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: UsuarioTipo.Administrador,
                              child: Text(AppLocalizations.of(context)!.common_administrator),
                            ),
                            DropdownMenuItem(
                              value: UsuarioTipo.Funcionario,
                              child: Text(AppLocalizations.of(context)!.users_type_employee),
                            ),
                            DropdownMenuItem(
                              value: UsuarioTipo.Morador,
                              child: Text(AppLocalizations.of(context)!.users_type_resident),
                            ),
                          ],
                          onChanged: null,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: PrimaryButton.primary(
                            text: _isLoading
                                ? AppLocalizations.of(context)!.users_saving
                                : AppLocalizations.of(context)!.users_save_changes,
                            onPressed: _isLoading ? null : _salvarAlteracoes,
                            isLoading: _isLoading,
                            icon: Icons.save_rounded,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: PrimaryButton.secondary(
                            text: AppLocalizations.of(context)!.common_cancel,
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            icon: Icons.close_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // Ações adicionais
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.users_actions,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: OwanyTheme.textPrimary(context),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _resetarSenha,
                                  icon: Icon(Icons.vpn_key_rounded, size: 18),
                                  label: Text(AppLocalizations.of(context)!.users_reset_password),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: OwanyTheme.warning,
                                    foregroundColor: OwanyTheme.adaptiveTextOverlay(context),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _desativarUsuario,
                                  icon: Icon(Icons.block_rounded, size: 18),
                                  label: Text(AppLocalizations.of(context)!.users_deactivate_button),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: OwanyTheme.error,
                                    foregroundColor: OwanyTheme.adaptiveTextOverlay(context),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OwanyTheme.info.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OwanyTheme.info.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OwanyTheme.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline_rounded, color: OwanyTheme.info, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.users_type_readonly_info,
                            style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
            ),
          );
        },
      ),
    );
  }
}
