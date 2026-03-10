import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// CUSTOM CARD - Card Premium Versátil
/// Design System: OwanyTheme
/// Suporta múltiplos estilos e variações
/// ============================================================

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final CardStyle style;
  final bool showBorder;
  final Color? borderColor;
  final LinearGradient? gradient;
  final double? width;
  final double? height;
  final bool isLoading;
  final Widget? header;
  final Widget? footer;
  final bool isDark;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.style = CardStyle.flat,
    this.showBorder = false,
    this.borderColor,
    this.gradient,
    this.width,
    this.height,
    this.isLoading = false,
    this.header,
    this.footer,
    this.isDark = false,
  });

  /// Factory: Card Plano (padrão)
  factory CustomCard.flat({required Widget child, EdgeInsets? padding, VoidCallback? onTap, bool isDark = false}) {
    return CustomCard(style: CardStyle.flat, padding: padding, onTap: onTap, isDark: isDark, child: child);
  }

  /// Factory: Card Elevado (com sombra)
  factory CustomCard.elevated({required Widget child, EdgeInsets? padding, VoidCallback? onTap, bool isDark = false}) {
    return CustomCard(style: CardStyle.elevated, padding: padding, onTap: onTap, isDark: isDark, child: child);
  }

  /// Factory: Card com Borda
  factory CustomCard.outlined({
    required Widget child,
    EdgeInsets? padding,
    VoidCallback? onTap,
    Color? borderColor,
    bool isDark = false,
  }) {
    return CustomCard(
      style: CardStyle.outlined,
      padding: padding,
      onTap: onTap,
      borderColor: borderColor,
      isDark: isDark,
      child: child,
    );
  }

  /// Factory: Card com Gradiente
  factory CustomCard.gradient({
    required Widget child,
    required LinearGradient gradient,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return CustomCard(style: CardStyle.gradient, gradient: gradient, padding: padding, onTap: onTap, child: child);
  }

  /// Factory: Card com Header e Footer
  factory CustomCard.withSections({
    required Widget child,
    Widget? header,
    Widget? footer,
    EdgeInsets? padding,
    VoidCallback? onTap,
    CardStyle style = CardStyle.elevated,
    bool isDark = false,
  }) {
    return CustomCard(
      style: style,
      header: header,
      footer: footer,
      padding: padding,
      onTap: onTap,
      isDark: isDark,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard(context);
    }

    return Container(
      width: width,
      height: height,
      decoration: _getDecoration(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (se houver)
              if (header != null) ...[
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: header!),
                _buildDivider(),
              ],

              // Content
              Padding(padding: padding ?? const EdgeInsets.all(16), child: child),

              // Footer (se houver)
              if (footer != null) ...[
                _buildDivider(),
                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: footer!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Decoração baseada no estilo
  BoxDecoration _getDecoration(BuildContext context) {
    switch (style) {
      case CardStyle.flat:
        return _flatDecoration();
      case CardStyle.elevated:
        return _elevatedDecoration(context);
      case CardStyle.outlined:
        return _outlinedDecoration();
      case CardStyle.gradient:
        return _gradientDecoration();
    }
  }

  /// Card Plano
  BoxDecoration _flatDecoration() {
    return BoxDecoration(
      color: isDark ? OwanyTheme.darkSurface : OwanyTheme.surface,
      borderRadius: BorderRadius.circular(16),
    );
  }

  /// Card Elevado
  BoxDecoration _elevatedDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDark ? OwanyTheme.darkSurface : OwanyTheme.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: OwanyTheme.textPrimary(context).withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: OwanyTheme.textPrimary(context).withValues(alpha: isDark ? 0.1 : 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Card com Borda
  BoxDecoration _outlinedDecoration() {
    return BoxDecoration(
      color: isDark ? OwanyTheme.darkSurface : OwanyTheme.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? (isDark ? OwanyTheme.darkBorder : OwanyTheme.borderLight), width: 1.5),
    );
  }

  /// Card com Gradiente
  BoxDecoration _gradientDecoration() {
    return BoxDecoration(
      gradient:
          gradient ??
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [OwanyTheme.accentLight, OwanyTheme.surface],
          ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: (gradient?.colors.first ?? OwanyTheme.primaryOrange).withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Divider interno
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? OwanyTheme.darkBorder : OwanyTheme.borderLight).withValues(alpha: 0),
            isDark ? OwanyTheme.darkBorder : OwanyTheme.borderLight,
            (isDark ? OwanyTheme.darkBorder : OwanyTheme.borderLight).withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  /// Card de Loading (Shimmer)
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.surface, OwanyTheme.surfaceHover, OwanyTheme.surface],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _ShimmerEffect(
        child: Container(
          decoration: BoxDecoration(
            color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// CARD STYLE - Estilos de Card
/// ============================================================

enum CardStyle {
  flat, // Plano (sem sombra)
  elevated, // Elevado (com sombra)
  outlined, // Com borda
  gradient, // Com gradiente
}

/// ============================================================
/// SHIMMER EFFECT - Efeito de Loading
/// ============================================================

class _ShimmerEffect extends StatefulWidget {
  final Widget child;

  const _ShimmerEffect({required this.child});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [Color(0xFFEBEBEB), Color(0xFFF4F4F4), Color(0xFFEBEBEB)],
              stops: [_controller.value - 0.3, _controller.value, _controller.value + 0.3],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// ============================================================
/// CUSTOM CARD VARIANTS - Variações Pré-configuradas
/// ============================================================

/// Card de Estatística
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard.gradient(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: OwanyTheme.adaptiveTextOverlay(context),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de Informação
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = OwanyTheme.primaryOrange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard.elevated(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [iconColor, iconColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: OwanyTheme.adaptiveTextOverlay(context), size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OwanyTheme.textDark),
                ),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 14, color: OwanyTheme.textMuted)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: OwanyTheme.textMuted),
        ],
      ),
    );
  }
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class CustomCardExample extends StatelessWidget {
  const CustomCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(title: Text('Custom Cards')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cards de Estatística em Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                label: 'PENDENTES',
                value: '30',
                icon: Icons.pending_rounded,
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
              ),
              StatCard(
                label: 'EM ANDAMENTO',
                value: '15',
                icon: Icons.engineering_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              ),
              StatCard(
                label: 'CONCLUÍDAS',
                value: '120',
                icon: Icons.check_circle_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              ),
              StatCard(
                label: 'USUÁRIOS',
                value: '45',
                icon: Icons.people_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Card Plano
          CustomCard.flat(child: Text('Card Plano - sem sombra, ideal para listas', style: TextStyle(fontSize: 14))),

          SizedBox(height: 12),

          // Card Elevado
          CustomCard.elevated(
            onTap: () => debugPrintLog('Card elevado clicado'),
            child: Text('Card Elevado - com sombra suave', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),

          SizedBox(height: 12),

          // Card com Borda
          CustomCard.outlined(
            borderColor: OwanyTheme.primaryOrange,
            child: Text('Card Outlined - com borda customizada', style: TextStyle(fontSize: 14)),
          ),

          SizedBox(height: 12),

          // Card com Header e Footer
          CustomCard.withSections(
            style: CardStyle.elevated,
            header: Row(
              children: [
                Icon(Icons.info_rounded, color: OwanyTheme.primaryOrange),
                SizedBox(width: 8),
                Text('Card com Seções', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: Text('Cancelar')),
                SizedBox(width: 8),
                ElevatedButton(onPressed: () {}, child: Text('Confirmar')),
              ],
            ),
            child: Text(
              'Este card tem header e footer separados com dividers automáticos.',
              style: TextStyle(fontSize: 14),
            ),
          ),

          SizedBox(height: 12),

          // Card de Loading
          const CustomCard(isLoading: true, height: 120, child: SizedBox()),

          SizedBox(height: 24),

          // Info Cards
          InfoCard(
            icon: Icons.apartment_rounded,
            title: 'Apartamentos',
            subtitle: 'Ver todos os apartamentos',
            iconColor: OwanyTheme.primaryOrange,
            onTap: () => debugPrintLog('Apartamentos'),
          ),

          SizedBox(height: 12),

          InfoCard(
            icon: Icons.people_rounded,
            title: 'Usuários',
            subtitle: '45 usuários cadastrados',
            iconColor: const Color(0xFF8B5CF6),
            onTap: () => debugPrintLog('Usuários'),
          ),
        ],
      ),
    );
  }
}
