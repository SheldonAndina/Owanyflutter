import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/owany_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../widgets/standard_glass_app_bar.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _notificationsSms = true;
  bool _updatingSms = false;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    // Initialize SMS preference from user's current setting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.usuarioAtual != null) {
        setState(() {
          _notificationsSms = authProvider.usuarioAtual!.receberSms;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: OwanyTheme.backgroundColor(context),
          appBar: StandardGlassAppBar(
            title: AppLocalizations.of(context)!.settings_title,
            icon: Icons.settings_rounded,
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: OwanyTheme.primaryOrange,
                          size: 26,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.settings_account_preferences,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: OwanyTheme.textPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.settings_account_subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============ SEGURANÇA ============
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.settings_security,
                        Icons.shield_rounded,
                        OwanyTheme.primaryOrange,
                      ),
                      SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: AppLocalizations.of(context)!.settings_change_password,
                        subtitle: AppLocalizations.of(context)!.settings_change_password_subtitle,
                        backgroundColor: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                        iconColor: OwanyTheme.primaryOrange,
                        onTap: () => Navigator.pushNamed(context, '/change-password'),
                      ),
                      SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_rounded,
                        title: _tx('Níveis de Acesso', 'Access Levels'),
                        subtitle: _tx('Gerenciar permissões e roles', 'Manage permissions and roles'),
                        backgroundColor: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                        iconColor: OwanyTheme.primaryOrange,
                        onTap: () => Navigator.pushNamed(context, '/niveis-acesso'),
                      ),
                      SizedBox(height: 28),

                      // ============ NOTIFICAÇÕES ============
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.settings_notifications,
                        Icons.notifications_rounded,
                        OwanyTheme.warning,
                      ),
                      SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: OwanyTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OwanyTheme.borderColor(context),
                          ),
                        ),
                        child: Column(
                          children: [
                            _NotificationToggleTile(
                              icon: Icons.notifications_active_rounded,
                              title: AppLocalizations.of(context)!.settings_notifications_push,
                              subtitle: AppLocalizations.of(context)!.settings_notifications_push_subtitle,
                              value: _notificationsEnabled,
                              onChanged: (v) => setState(() => _notificationsEnabled = v),
                              iconColor: OwanyTheme.warning,
                            ),
                            Divider(
                              height: 1,
                              color: OwanyTheme.borderColor(context).withValues(alpha: 0.5),
                              indent: 56,
                            ),
                            _NotificationToggleTile(
                              icon: Icons.sms_rounded,
                              title: AppLocalizations.of(context)!.settings_notifications_sms,
                              subtitle: AppLocalizations.of(context)!.settings_notifications_sms_subtitle,
                              value: _notificationsSms,
                              enabled: !_updatingSms,
                              onChanged: (v) async {
                                setState(() => _updatingSms = true);
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final success = await authProvider.updateSmsPreference(v);
                                if (mounted) {
                                  setState(() {
                                    _updatingSms = false;
                                    if (success) {
                                      _notificationsSms = v;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        OwanyTheme.snackBar(
                                          v 
                                            ? AppLocalizations.of(context)!.settings_sms_enabled
                                            : AppLocalizations.of(context)!.settings_sms_disabled,
                                          type: SnackBarType.success,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        OwanyTheme.snackBar(
                                          AppLocalizations.of(context)!.settings_sms_update_failed,
                                          type: SnackBarType.error,
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                              iconColor: OwanyTheme.info,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28),

                      // ============ APARÊNCIA E IDIOMA ============
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.settings_appearance,
                        Icons.palette_rounded,
                        OwanyTheme.success,
                      ),
                      SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return _SettingsTile(
                            icon: themeProvider.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            title: AppLocalizations.of(context)!.settings_theme,
                            subtitle: themeProvider.themeModeString,
                            backgroundColor: OwanyTheme.success.withValues(alpha: 0.08),
                            iconColor: OwanyTheme.success,
                            trailing: _ThemeToggleButton(
                              isDark: themeProvider.isDarkMode,
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final l10n = AppLocalizations.of(context)!;
                                await themeProvider.toggleTheme();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    OwanyTheme.snackBar(
                                      l10n.settings_theme_changed(themeProvider.themeModeString),
                                      type: SnackBarType.success,
                                    ),
                                  );
                                }
                              },
                            ),
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final l10n = AppLocalizations.of(context)!;
                              await themeProvider.toggleTheme();
                              if (mounted) {
                                messenger.showSnackBar(
                                  OwanyTheme.snackBar(
                                    l10n.settings_theme_changed(themeProvider.themeModeString),
                                    type: SnackBarType.success,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: OwanyTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OwanyTheme.borderColor(context),
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
                                    color: OwanyTheme.info.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.language_rounded,
                                    color: OwanyTheme.info,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.settings_language,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: OwanyTheme.textPrimary(context),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        AppLocalizations.of(context)!.settings_language_subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: OwanyTheme.textMutedColor(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: OwanyTheme.backgroundColor(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: languageProvider.idiomaCode,
                                isExpanded: true,
                                underline: SizedBox(),
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: OwanyTheme.primaryOrange,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'pt',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(_tx('Português (PT)', 'Portuguese (PT)')),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(_tx('Inglês (EN)', 'English (EN)')),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    languageProvider.setIdioma(
                                      value == 'en' ? 'en' : 'pt',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      OwanyTheme.snackBar(
                                        AppLocalizations.of(context)!.settings_language_apply_restart,
                                        type: SnackBarType.info,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28),

                      // ============ SOBRE ============
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.settings_about,
                        Icons.info_outline_rounded,
                        OwanyTheme.primaryBrown,
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OwanyTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OwanyTheme.borderColor(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Owany App',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: OwanyTheme.primaryOrange,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'v1.0.0',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: OwanyTheme.textMutedColor(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: OwanyTheme.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.common_current,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: OwanyTheme.success,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.settings_about_description,
                              style: TextStyle(
                                fontSize: 12,
                                color: OwanyTheme.textMutedColor(context),
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),

                      // ============ LOGOUT ============
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: Icon(Icons.logout_rounded, size: 20, color: OwanyTheme.white),
                          label: Text(
                            AppLocalizations.of(context)!.settings_logout,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: OwanyTheme.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OwanyTheme.primaryOrange,
                            foregroundColor: OwanyTheme.white,
                            textStyle: const TextStyle(inherit: false, fontSize: 15, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: OwanyTheme.textPrimary(context),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ThemedAlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: OwanyTheme.primaryOrange, size: 24),
            SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.settings_logout_confirm_title,
              style: TextStyle(
                color: OwanyTheme.textPrimary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.settings_logout_confirm_body,
          style: TextStyle(
            color: OwanyTheme.textMutedColor(context),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: OwanyTheme.borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                AppLocalizations.of(context)!.common_cancel,
                style: TextStyle(
                  color: OwanyTheme.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().logout(context);
              navigator.pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OwanyTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                AppLocalizations.of(context)!.common_exit,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: OwanyTheme.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ CUSTOM WIDGETS ============

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OwanyTheme.borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8),
                trailing!,
              ] else
                Icon(
                  Icons.chevron_right_rounded,
                  color: OwanyTheme.borderColor(context),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color iconColor;
  final Function(bool) onChanged;
  final bool enabled;

  const _NotificationToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconColor,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.textMutedColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              enabled
                  ? Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: iconColor,
                      inactiveThumbColor: OwanyTheme.textMutedColor(context).withValues(alpha: 0.5),
                      inactiveTrackColor: OwanyTheme.textMutedColor(context).withValues(alpha: 0.12),
                    )
                  : SizedBox(
                      width: 48,
                      height: 24,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeToggleButton({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: OwanyTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.cached_rounded,
              color: OwanyTheme.success,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}




