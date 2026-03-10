import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with SingleTickerProviderStateMixin {
    final _phoneMaskFormatter = MaskTextInputFormatter(mask: '+258 ##-#######');
  late AnimationController _animController;
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _nomeController = TextEditingController();
  final _nomeLoginController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Admin/Síndico podem criar Funcionario, Sindico, Portaria, Morador ou Visitante
  UsuarioTipo _tipoSelecionado = UsuarioTipo.Funcionario;
  bool _obscureSenha = true;
  bool _obscureConfirmacao = true;
  bool _isLoading = false;
  bool _enviarSMS = false; // Optional: Send SMS with credentials

  // Filter out roles that can't be created by admin
  List<UsuarioTipo> get _rolesDisponiveis => [
    UsuarioTipo.Funcionario,
    UsuarioTipo.Sindico,
    UsuarioTipo.Portaria,
    UsuarioTipo.Morador,
    UsuarioTipo.Visitante,
    UsuarioTipo.Administrador,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nomeController.dispose();
    _nomeLoginController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(AppLocalizations.of(context)!.users_password_no_match, type: SnackBarType.error),
      );
      return;
    }

    // Normalizar telefone para apenas dígitos e prefixo 258
    String telefoneNumerico = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
    if (telefoneNumerico.length == 9) {
      telefoneNumerico = '258$telefoneNumerico';
    } else if (telefoneNumerico.length == 12 && telefoneNumerico.startsWith('258')) {
      // ok
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(AppLocalizations.of(context)!.users_phone_invalid, type: SnackBarType.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Criar usuário no backend
      AppLogger.info('AddUser', 'Criando usuário com enviarSMS: $_enviarSMS');
      final usuarioCriado = await _apiService.criarFuncionario(
        nome: _nomeController.text.trim(),
        nomeLogin: _nomeLoginController.text.trim(),
        telefone: telefoneNumerico,
        tipo: _tipoSelecionado.toApiValue(),
        senha: _senhaController.text,
        enviarSMS: false, // Backend não suporta envio automático
      );

      // 2. Se checkbox marcado, enviar SMS manualmente usando endpoint de SMS em massa
      if (_enviarSMS && mounted) {
        try {
          AppLogger.info('AddUser', 'Enviando SMS de credenciais para ${usuarioCriado.telefone}...');
          final mensagemSms = '''Bem-vindo ao Owany!
Suas credenciais de acesso:
Usuário: ${_nomeLoginController.text.trim()}
Senha: ${_senhaController.text}

Faça login no aplicativo para começar.''';

          await _apiService.enviarSmsMassa(
            mensagem: mensagemSms,
            usuarioIds: [usuarioCriado.id],
            enviarNotificacaoApp: false,
          );
          AppLogger.info('AddUser', 'SMS enviado com sucesso');
        } catch (smsError) {
          AppLogger.error('AddUser', 'Erro ao enviar SMS: $smsError');
          // Não falhar a criação se SMS falhar
        }
      }

      if (mounted) {
        String mensagem = AppLocalizations.of(context)!.users_created_success;
        if (_enviarSMS) {
          mensagem += '\n${AppLocalizations.of(context)!.users_credentials_sent(telefoneNumerico)}';
        }
        AppLogger.info('AddUser', 'Usuário criado com sucesso. enviarSMS=$_enviarSMS');
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(mensagem, type: SnackBarType.success),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      AppLogger.error('AddUser', 'Erro ao criar usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${AppLocalizations.of(context)!.common_error}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.users_new,
        icon: Icons.person_add_rounded,
        showBackButton: true,
      ),
      body: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeIn),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OwanyTheme.primaryOrange.withValues(alpha: 0.12),
                        OwanyTheme.softOrange.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: OwanyTheme.primaryOrange,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.users_create_new,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.users_fill_data,
                                style: TextStyle(
                                  color: OwanyTheme.textMutedColor(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Nome Completo
                _buildLabel(AppLocalizations.of(context)!.users_full_name),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nomeController,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    icon: Icons.person_rounded,
                    hint: AppLocalizations.of(context)!.users_full_name,
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? AppLocalizations.of(context)!.common_required_field : null,
                ),
                SizedBox(height: 16),

                // Nome Login
                _buildLabel(AppLocalizations.of(context)!.users_login_name),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nomeLoginController,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    icon: Icons.account_circle_rounded,
                    hint: AppLocalizations.of(context)!.users_login_name_hint,
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? AppLocalizations.of(context)!.common_required_field : null,
                ),
                SizedBox(height: 16),

                // Telefone
                _buildLabel(AppLocalizations.of(context)!.users_phone),
                SizedBox(height: 8),
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: _buildInputDecoration(
                    icon: Icons.phone_rounded,
                    hint: AppLocalizations.of(context)!.users_phone_hint,
                  ).copyWith(
                    prefixText: '+258 ',
                  ),
                  validator: (v) {
                    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.isEmpty) return AppLocalizations.of(context)!.common_required_field;
                    if (digits.length != 9 && !(digits.length == 12 && digits.startsWith('258'))) {
                      return AppLocalizations.of(context)!.users_phone_invalid;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Tipo de Usuário
                _buildLabel(AppLocalizations.of(context)!.users_user_type),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: OwanyTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwanyTheme.borderColor(context)),
                  ),
                  child: DropdownButtonFormField<UsuarioTipo>(
                    initialValue: _tipoSelecionado,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.security_rounded,
                        color: OwanyTheme.primaryOrange,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: _rolesDisponiveis
                        .map(
                          (tipo) => DropdownMenuItem<UsuarioTipo>(
                            value: tipo,
                            child: Text(tipo.toPortuguese()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _tipoSelecionado = value ?? UsuarioTipo.Funcionario,
                    ),
                    isExpanded: true,
                  ),
                ),
                SizedBox(height: 20),

                // SMS Notification Checkbox
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _enviarSMS 
                      ? OwanyTheme.primaryOrange.withValues(alpha: 0.08)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _enviarSMS
                        ? OwanyTheme.primaryOrange.withValues(alpha: 0.3)
                        : OwanyTheme.borderColor(context),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _enviarSMS,
                    onChanged: (value) => setState(() => _enviarSMS = value ?? false),
                    title: Text(
                      AppLocalizations.of(context)!.users_send_sms_credentials,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.users_sms_subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(context),
                      ),
                    ),
                    activeColor: OwanyTheme.primaryOrange,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(height: 20),

                // Divider com Segurança
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        AppLocalizations.of(context)!.users_security,
                        style: TextStyle(
                          color: OwanyTheme.textMutedColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Senha
                _buildLabel(AppLocalizations.of(context)!.users_password),
                SizedBox(height: 8),
                TextFormField(
                  controller: _senhaController,
                  obscureText: _obscureSenha,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    icon: Icons.lock_rounded,
                    hint: AppLocalizations.of(context)!.users_password_hint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSenha
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: OwanyTheme.primaryBlue.withValues(alpha: 0.7),
                      ),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return AppLocalizations.of(context)!.common_required_field;
                    if (v!.length < 6) return AppLocalizations.of(context)!.users_min_chars;
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Confirmar Senha
                _buildLabel(AppLocalizations.of(context)!.users_confirm_password),
                SizedBox(height: 8),
                TextFormField(
                  controller: _confirmarSenhaController,
                  obscureText: _obscureConfirmacao,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    icon: Icons.lock_rounded,
                    hint: AppLocalizations.of(context)!.users_confirm_password_hint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmacao
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: OwanyTheme.primaryBlue.withValues(alpha: 0.7),
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirmacao = !_obscureConfirmacao),
                    ),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? AppLocalizations.of(context)!.common_required_field : null,
                ),
                SizedBox(height: 32),

                // Botões
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.primary(
                    text: AppLocalizations.of(context)!.users_create_button,
                    onPressed: _isLoading ? null : _criarUsuario,
                    isLoading: _isLoading,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton.secondary(
                    text: AppLocalizations.of(context)!.common_cancel,
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: Icons.close_rounded,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  InputDecoration _buildInputDecoration({
    required IconData icon,
    required String hint,
    Widget? suffixIcon,
  }) {
    return OwanyTheme.inputDecoration(
      context: context,
      label: '',
      hint: hint,
      icon: icon,
      suffixIcon: suffixIcon,
      dark: Theme.of(context).brightness == Brightness.dark,
    ).copyWith(
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      filled: true,
      fillColor: OwanyTheme.cardColor(context),
    );
  }
}




















