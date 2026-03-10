import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/dashboard_components.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final usuario = authProvider.usuarioAtual;
            if (usuario == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.profile_user_not_found,
                      style: OwanyTheme.bodyLarge,
                    ),
                    SizedBox(height: 12),
                    PrimaryButton.primary(
                      text: AppLocalizations.of(context)!.action_back,
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final horizontalPadding = isWide ? 32.0 : 24.0;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      elevation: 0,
                      backgroundColor: OwanyTheme.cardColor(context),

                      title: Text(
                        AppLocalizations.of(context)!.profile_title,
                        style: OwanyTheme.headlineLarge.copyWith(
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _ProfileHeader(usuario: usuario, isWide: isWide),

                          SizedBox(height: 28),

                          DashboardSection(
                            title: AppLocalizations.of(context)!.profile_personal_info,
                            children: [
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _ProfileInfoCard(
                                    icon: Icons.person_rounded,
                                    label: AppLocalizations.of(context)!.profile_full_name,
                                    value: usuario.nome,
                                  ),
                                  _ProfileInfoCard(
                                    icon: Icons.account_circle_rounded,
                                    label: AppLocalizations.of(context)!.profile_login_name,
                                    value: usuario.nomeLogin,
                                  ),
                                  _ProfileInfoCard(
                                    icon: Icons.phone_rounded,
                                    label: AppLocalizations.of(context)!.common_phone,
                                    value: usuario.telefone,
                                  ),
                                  _ProfileInfoCard(
                                    icon: Icons.badge_rounded,
                                    label: AppLocalizations.of(context)!.profile_user_type,
                                    value: _tipoUsuarioLabel(context, usuario.tipo),
                                  ),
                                  _ProfileInfoCard(
                                    icon: Icons.verified_user_rounded,
                                    label: AppLocalizations.of(context)!.common_status,
                                    value: usuario.ativo ? AppLocalizations.of(context)!.profile_active_in_system : AppLocalizations.of(context)!.common_inactive,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 24),

                          DashboardSection(
                            title: AppLocalizations.of(context)!.common_actions,
                            children: [
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  _ProfileActionButton(
                                    icon: Icons.settings_rounded,
                                    label: AppLocalizations.of(context)!.settings_title,
                                    subtitle: AppLocalizations.of(context)!.settings_account_subtitle,
                                    color: OwanyTheme.primaryOrange,
                                    onTap: () => Navigator.pushNamed(context, '/configuracoes'),
                                  ),
                                  _ProfileActionButton(
                                    icon: Icons.help_rounded,
                                    label: AppLocalizations.of(context)!.profile_help_support,
                                    subtitle: AppLocalizations.of(context)!.profile_get_in_touch,
                                    color: OwanyTheme.warning,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context)!.profile_support_email),
                                          backgroundColor: OwanyTheme.warning,
                                        ),
                                      );
                                    },
                                  ),
                                  _ProfileActionButton(
                                    icon: Icons.logout_rounded,
                                    label: AppLocalizations.of(context)!.profile_sign_out,
                                    subtitle: AppLocalizations.of(context)!.profile_do_logout,
                                    color: OwanyTheme.primaryOrange,
                                    onTap: () => _logout(context, authProvider),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.profile_sign_out_confirm),
        content: Text(AppLocalizations.of(context)!.profile_disconnect_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.common_cancel,
              style: TextStyle(color: OwanyTheme.textPrimary(context)),
            ),
          ),
          PrimaryButton.primary(
            text: AppLocalizations.of(context)!.common_exit,
            onPressed: () => Navigator.pop(context, true),
            icon: Icons.logout_rounded,
          ),
        ],
      ),
    );

    if (confirma == true && context.mounted) {
      await authProvider.logout(context);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

}

String _tipoUsuarioLabel(BuildContext context, UsuarioTipo tipo) {
  final l10n = AppLocalizations.of(context)!;
  switch (tipo) {
    case UsuarioTipo.Administrador:
      return l10n.profile_type_admin;
    case UsuarioTipo.Funcionario:
      return l10n.profile_type_employee;
    case UsuarioTipo.Sindico:
      return l10n.profile_type_manager;
    case UsuarioTipo.Portaria:
      return l10n.profile_type_doorman;
    case UsuarioTipo.Morador:
      return l10n.profile_type_resident;
    case UsuarioTipo.Visitante:
      return l10n.profile_type_visitor;
  }
}

/// ==========================
/// PROFILE HEADER
/// ==========================
class _ProfileHeader extends StatelessWidget {
  final Usuario usuario;
  final bool isWide;

  const _ProfileHeader({required this.usuario, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final nome = usuario.nome.trim();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.primaryOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isWide ? 96 : 82,
                height: isWide ? 96 : 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OwanyTheme.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: OwanyTheme.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    inicial,
                    style: TextStyle(
                      color: OwanyTheme.cardColor(context),
                      fontSize: isWide ? 40 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isWide ? 24 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isNotEmpty ? nome : AppLocalizations.of(context)!.common_user,
                      style: TextStyle(
                        color: OwanyTheme.cardColor(context),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: _StatusPill(
                            label: _tipoUsuarioLabel(context, usuario.tipo),
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: _StatusPill(
                            label: usuario.ativo ? AppLocalizations.of(context)!.common_active : AppLocalizations.of(context)!.common_inactive,
                            icon: usuario.ativo ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Login: ${usuario.nomeLogin}',
                      style: OwanyTheme.bodyMedium.copyWith(
                        color: OwanyTheme.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OwanyTheme.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OwanyTheme.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: OwanyTheme.cardColor(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: OwanyTheme.cardColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==========================
/// PROFILE INFO CARD
/// ==========================
class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.textPrimary(context).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: OwanyTheme.primaryOrange, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMutedColor(context)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: OwanyTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================
/// PROFILE ACTION BUTTON
/// ==========================
class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: OwanyTheme.labelLarge.copyWith(color: color),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: OwanyTheme.bodySmall.copyWith(
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}



















