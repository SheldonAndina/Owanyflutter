import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// STANDARD GLASS APP BAR - Padrão Premium com Glassmorphism
/// Design System: OwanyTheme com gradiente laranja + glassmorphism
/// ============================================================

class StandardGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double scrollOffset;
  final Color? gradientStartColor;
  final Color? gradientEndColor;

  const StandardGlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = false,
    this.scrollOffset = 0.0,
    this.gradientStartColor,
    this.gradientEndColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (gradientStartColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.8 + (opacity * 0.2)),
                (gradientEndColor ?? OwanyTheme.accent).withValues(alpha: 0.7 + (opacity * 0.3)),
              ],
            ),
            border: Border(bottom: BorderSide(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      if (showBackButton && !centerTitle)
                        _buildBackButton(context)
                      else if (icon != null && !centerTitle) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
                        ),
                        SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: OwanyTheme.adaptiveTextOverlay(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null && actions!.isNotEmpty) ...[SizedBox(width: 12), ...actions!],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onBackPressed ?? () => Navigator.maybePop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.arrow_back_rounded, color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
      ),
    );
  }
}

/// Variante com título centralizado (para telas de detalhe)
class CenteredGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double scrollOffset;
  final Color? gradientStartColor;
  final Color? gradientEndColor;

  const CenteredGlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.scrollOffset = 0.0,
    this.gradientStartColor,
    this.gradientEndColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    final opacity = (scrollOffset / 100).clamp(0.0, 1.0);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (gradientStartColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.8 + (opacity * 0.2)),
                (gradientEndColor ?? OwanyTheme.accent).withValues(alpha: 0.7 + (opacity * 0.3)),
              ],
            ),
            border: Border(bottom: BorderSide(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),

                  // Back button on left
                  if (showBackButton)
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: onBackPressed ?? () => Navigator.maybePop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: OwanyTheme.adaptiveTextOverlay(context),
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                  // Actions on right
                  if (actions != null && actions!.isNotEmpty) Positioned(right: 0, child: Row(children: actions!)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
