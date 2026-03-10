import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/owany_theme.dart';

/// Modern AppBar com design profissional
/// Uso: Coloque em todo screen no lugar de AppBar simples
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final double elevation;
  final bool centerTitle;
  final TextStyle? titleStyle;

  const ModernAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.elevation = 2,
    this.centerTitle = false,
    this.titleStyle,
  });

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            OwanyTheme.headlineMedium.copyWith(color: OwanyTheme.cardColor(context), fontWeight: FontWeight.w700),
      ),
      backgroundColor: backgroundColor ?? OwanyTheme.textPrimary(context),
      elevation: elevation,
      centerTitle: centerTitle,
      leading:
          leading ??
          (showBack
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: OwanyTheme.cardColor(context)),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                )
              : null),
      actions: actions ?? [],
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: OwanyTheme.primaryOrange,
        statusBarIconBrightness: Brightness.light,
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
    );
  }
}

/// Modern Button - Ação Primária (Orange)
class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.height = 48,
    this.borderRadius = 12,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        backgroundColor: backgroundColor ?? OwanyTheme.primaryOrange,
        disabledBackgroundColor: OwanyTheme.softOrange,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textColor ?? OwanyTheme.cardColor(context)),
                strokeWidth: 2,
              ),
            )
          : icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor ?? OwanyTheme.cardColor(context)),
                SizedBox(width: 8),
                Text(
                  label,
                  style: OwanyTheme.labelLarge.copyWith(
                    color: textColor ?? OwanyTheme.cardColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: OwanyTheme.labelLarge.copyWith(
                color: textColor ?? OwanyTheme.cardColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Modern Secondary Button - Ações secundárias
class ModernOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;

  const ModernOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 12,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        side: BorderSide(color: borderColor ?? OwanyTheme.primaryOrange, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textColor ?? OwanyTheme.primaryOrange),
                strokeWidth: 2,
              ),
            )
          : icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor ?? OwanyTheme.primaryOrange),
                SizedBox(width: 8),
                Text(
                  label,
                  style: OwanyTheme.labelLarge.copyWith(
                    color: textColor ?? OwanyTheme.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: OwanyTheme.labelLarge.copyWith(
                color: textColor ?? OwanyTheme.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Modern Card - Container padrão
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double elevation;
  final double borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool clickable;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation = 2,
    this.borderRadius = 12,
    this.border,
    this.onTap,
    this.clickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? OwanyTheme.surface,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ?? Border.all(color: OwanyTheme.borderColor(context), width: 1),
        ),
        child: InkWell(
          onTap: clickable ? onTap : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

/// Modern List Item - Item de lista padrão
class ModernListItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool showDivider;

  const ModernListItem({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          tileColor: backgroundColor ?? Colors.transparent,
          leading: icon != null ? Icon(icon, color: OwanyTheme.primaryOrange, size: 28) : null,
          title: Text(title, style: OwanyTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          subtitle: subtitle != null
              ? Text(subtitle!, style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMuted))
              : null,
          trailing: trailing ?? Icon(Icons.arrow_forward_rounded, color: OwanyTheme.textMuted),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        if (showDivider) Divider(height: 1, color: OwanyTheme.borderColor(context), indent: 56),
      ],
    );
  }
}

/// Modern Empty State
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final Color? iconColor;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.iconColor,
  });

  factory ModernEmptyState.serverOffline({VoidCallback? onRetry}) {
    return ModernEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Servidor indisponível',
      message: 'Não foi possível comunicar com o servidor. Tente novamente em instantes.',
      onRetry: onRetry,
      iconColor: OwanyTheme.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: iconColor ?? OwanyTheme.primaryOrange.withValues(alpha: 0.3)),
          SizedBox(height: 16),
          Text(
            title,
            style: OwanyTheme.headlineSmall.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: 8),
            Text(
              message!,
              style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: 24),
            ModernButton(label: 'Tentar Novamente', onPressed: onRetry!, backgroundColor: OwanyTheme.primaryOrange),
          ],
        ],
      ),
    );
  }
}

/// Modern Section Header - Para dividir seções
class ModernSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const ModernSectionHeader({super.key, required this.title, this.actionLabel, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: OwanyTheme.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
          if (actionLabel != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: OwanyTheme.labelLarge.copyWith(color: OwanyTheme.primaryOrange, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
