import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_logger.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _nomeLoginController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1: phone, 2: code, 3: password
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  static const int _resendSeconds = 90;
  String? _nomeLoginError;
  bool _nomeLoginIsValid = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nomeLoginController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNomeLogin(String value) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _nomeLoginError = l10n.forgot_password_login_required;
        _nomeLoginIsValid = false;
      } else if (value.trim().length < 4) {
        _nomeLoginError = l10n.forgot_password_login_too_short;
        _nomeLoginIsValid = false;
      } else {
        _nomeLoginError = null;
        _nomeLoginIsValid = true;
      }
    });
  }

  Future<void> _solicitarReset() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_nomeLoginIsValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(l10n.forgot_password_error_invalid_login, type: SnackBarType.warning));
      return;
    }

    final nomeLogin = _nomeLoginController.text.trim();
    AppLogger.info('ForgotPassword', 'Solicitar reset para: $nomeLogin');

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.solicitarReset(nomeLogin);

    if (sucesso && mounted) {
      setState(() => _step = 2);
      _startResendCountdown();
      final destino = authProvider.tempTelefoneMascarado != null && authProvider.tempTelefoneMascarado!.isNotEmpty
          ? 'para ${authProvider.tempTelefoneMascarado}'
          : l10n.forgot_password_to_registered_phone;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(l10n.forgot_password_sms_sent_to(destino), type: SnackBarType.success));
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(authProvider.errorMessage!, type: SnackBarType.error));
    }
  }

  Future<void> _validarCodigo() async {
    final authProvider = context.read<AuthProvider>();
    AppLogger.info('ForgotPassword', 'Validar código OTP');

    final sucesso = await authProvider.validarCodigo(_codeController.text);

    if (sucesso && mounted) {
      setState(() => _step = 3);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(authProvider.errorMessage!, type: SnackBarType.error));
    }
  }

  Future<void> _resetarSenha() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(l10n.forgot_password_passwords_dont_match, type: SnackBarType.error));
      return;
    }

    AppLogger.info('ForgotPassword', 'Reset de senha');

    final authProvider = context.read<AuthProvider>();
    final sucesso = await authProvider.resetarSenha(codigo: _codeController.text, novaSenha: _passwordController.text);

    if (sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(l10n.forgot_password_success));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(authProvider.errorMessage!, type: SnackBarType.error));
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCountdown <= 1) {
        setState(() => _resendCountdown = 0);
        timer.cancel();
        return;
      }

      setState(() => _resendCountdown--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: l10n.forgot_password_title,
        icon: Icons.lock_reset_rounded,
        showBackButton: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Step indicator com OwanyTheme
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OwanyTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: OwanyTheme.textPrimary(context).withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(3, (index) {
                      final isActive = _step == index + 1;
                      final isCompleted = _step > index + 1;
                      final stepNum = index + 1;
                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? OwanyTheme.success
                                    : isActive
                                    ? OwanyTheme.primaryOrange
                                    : OwanyTheme.borderColor(context).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? Icon(Icons.check_rounded, color: OwanyTheme.cardColor(context), size: 20)
                                    : Text(
                                        '$stepNum',
                                        style: TextStyle(
                                          color: isActive
                                              ? OwanyTheme.cardColor(context)
                                              : OwanyTheme.textMutedColor(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              stepNum == 1
                                  ? l10n.forgot_password_step_verification
                                  : stepNum == 2
                                  ? l10n.forgot_password_step_code
                                  : l10n.forgot_password_step_new_password,
                              style: TextStyle(
                                color: isActive ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
                                fontSize: 11,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 32),

                // Step 1: NomeLogin
                if (_step == 1) ..._buildStep1(authProvider),

                // Step 2: Code
                if (_step == 2) ..._buildStep2(authProvider),

                // Step 3: New Password
                if (_step == 3) ..._buildStep3(authProvider),
              ],
            ),
            ),
          ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStep1(AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.forgot_password_step1_heading,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
      ),
      SizedBox(height: 8),
      Text(
        l10n.forgot_password_step1_subtitle,
        style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
      ),
      SizedBox(height: 24),
      TextFormField(
        controller: _nomeLoginController,
        onChanged: _validateNomeLogin,
        style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: l10n.forgot_password_login_label,
          hintText: l10n.forgot_password_login_hint,
          helperText: l10n.forgot_password_login_helper,
          prefixIcon: Icon(Icons.person_rounded, color: OwanyTheme.primaryOrange),
          filled: true,
          fillColor: OwanyTheme.cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _nomeLoginError != null
                  ? OwanyTheme.error
                  : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _nomeLoginError != null
                  ? OwanyTheme.error
                  : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _nomeLoginError != null ? OwanyTheme.error : OwanyTheme.primaryOrange,
              width: 2,
            ),
          ),
          errorText: _nomeLoginError,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.text,
        autocorrect: false,
      ),
      if (_nomeLoginIsValid)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwanyTheme.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OwanyTheme.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: OwanyTheme.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.forgot_password_sms_will_be_sent,
                    style: TextStyle(fontSize: 12, color: OwanyTheme.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: PrimaryButton.secondary(text: l10n.common_cancel, onPressed: () => Navigator.pop(context)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: PrimaryButton.primary(
              text: l10n.common_next,
              onPressed: authProvider.isLoading || !_nomeLoginIsValid ? null : _solicitarReset,
              isLoading: authProvider.isLoading,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStep2(AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.forgot_password_step2_heading,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
      ),
      SizedBox(height: 8),
      Text(
        l10n.forgot_password_step2_subtitle,
        style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
      ),
      SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.sms_rounded, size: 16, color: OwanyTheme.primaryOrange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.forgot_password_phone_label(authProvider.tempTelefoneMascarado ?? '***'),
                style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24),
      TextFormField(
        controller: _codeController,
        style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: l10n.forgot_password_otp_label,
          prefixIcon: Icon(Icons.lock_rounded, color: OwanyTheme.primaryOrange),
          filled: true,
          fillColor: OwanyTheme.cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.primaryOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
        maxLength: 6,
      ),
      SizedBox(height: 16),
      if (_resendCountdown > 0)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OwanyTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OwanyTheme.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: OwanyTheme.warning),
              SizedBox(width: 8),
              Text(
                l10n.forgot_password_resend_in(_resendCountdown),
                style: TextStyle(fontSize: 12, color: OwanyTheme.warning, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        )
      else
        TextButton.icon(
          onPressed: _solicitarReset,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
          icon: Icon(Icons.refresh_rounded, size: 16, color: OwanyTheme.primaryOrange),
          label: Text(
            l10n.forgot_password_resend_button,
            style: TextStyle(color: OwanyTheme.primaryOrange, fontWeight: FontWeight.w600),
          ),
        ),
      SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: PrimaryButton.secondary(text: l10n.action_back, onPressed: () => setState(() => _step = 1)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: PrimaryButton.primary(
              text: l10n.common_next,
              onPressed: authProvider.isLoading ? null : _validarCodigo,
              isLoading: authProvider.isLoading,
              icon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStep3(AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    return [
      Text(
        l10n.forgot_password_step3_heading,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
      ),
      SizedBox(height: 8),
      Text(
        l10n.forgot_password_step3_subtitle,
        style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
      ),
      SizedBox(height: 24),
      TextFormField(
        controller: _passwordController,
        style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: l10n.forgot_password_step3_password,
          prefixIcon: Icon(Icons.lock_rounded, color: OwanyTheme.primaryOrange),
          filled: true,
          fillColor: OwanyTheme.cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.primaryOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: OwanyTheme.textMutedColor(context),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        obscureText: _obscurePassword,
      ),
      SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: l10n.forgot_password_step3_confirm,
          prefixIcon: Icon(Icons.lock_open_rounded, color: OwanyTheme.primaryOrange),
          filled: true,
          fillColor: OwanyTheme.cardColor(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: OwanyTheme.primaryOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: OwanyTheme.textMutedColor(context),
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        obscureText: _obscureConfirm,
      ),
      SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: PrimaryButton.secondary(text: l10n.action_back, onPressed: () => setState(() => _step = 2)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: PrimaryButton.success(
              text: l10n.forgot_password_reset_button,
              onPressed: authProvider.isLoading ? null : _resetarSenha,
              isLoading: authProvider.isLoading,
              icon: Icons.check_circle_rounded,
            ),
          ),
        ],
      ),
    ];
  }
}
