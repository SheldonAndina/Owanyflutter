import 'package:flutter/material.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  InputDecoration _passwordDecoration({
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return OwanyTheme.inputDecoration(
      context: context,
      label: label,
      hint: hint,
      icon: Icons.lock_outline_rounded,
      dark: Theme.of(context).brightness == Brightness.dark,
    ).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: OwanyTheme.textMutedColor(context),
          size: 20,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().request<bool>(
        'auth/mudar-senha',
        method: 'POST',
        body: {
          'senhaAtual': _currentPasswordController.text,
          'novaSenha': _newPasswordController.text,
          'confirmarNovaSenha': _confirmPasswordController.text,
        },
        fromJson: (json) => json == true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(AppLocalizations.of(context)!.change_password_success));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar('${AppLocalizations.of(context)!.common_error}: ${e.toString()}', type: SnackBarType.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.password_change,
        icon: Icons.lock_rounded,
        showBackButton: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [OwanyTheme.primaryOrange.withValues(alpha: 0.14), OwanyTheme.softOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.lock_reset_rounded, color: OwanyTheme.textPrimary(context)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.change_password_protect_account,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: OwanyTheme.textPrimary(context),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.change_password_tip,
                              style: TextStyle(color: OwanyTheme.textMutedColor(context), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 28),

                // Senha Atual
                Text(
                  AppLocalizations.of(context)!.change_password_current,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_showCurrentPassword,
                  style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: _passwordDecoration(
                    label: AppLocalizations.of(context)!.change_password_current,
                    hint: AppLocalizations.of(context)!.change_password_current_hint,
                    isVisible: _showCurrentPassword,
                    onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return AppLocalizations.of(context)!.change_password_current_hint;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Nova Senha
                Text(
                  AppLocalizations.of(context)!.change_password_new,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: _passwordDecoration(
                    label: AppLocalizations.of(context)!.change_password_new,
                    hint: AppLocalizations.of(context)!.change_password_new_hint,
                    isVisible: _showNewPassword,
                    onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return AppLocalizations.of(context)!.change_password_new_required;
                    }
                    if ((value?.length ?? 0) < 6) {
                      return AppLocalizations.of(context)!.password_min_chars;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Confirmar Senha
                Text(
                  AppLocalizations.of(context)!.change_password_confirm,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: _passwordDecoration(
                    label: AppLocalizations.of(context)!.change_password_confirm,
                    hint: AppLocalizations.of(context)!.change_password_confirm_hint,
                    isVisible: _showConfirmPassword,
                    onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return AppLocalizations.of(context)!.change_password_confirm_required;
                    }
                    if (value != _newPasswordController.text) {
                      return AppLocalizations.of(context)!.password_no_match;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Botão
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: PrimaryButton.primary(
                    text: _isLoading
                        ? AppLocalizations.of(context)!.change_password_saving
                        : AppLocalizations.of(context)!.password_change,
                    onPressed: _isLoading ? null : _changePassword,
                    isLoading: _isLoading,
                    icon: Icons.save_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }
}
