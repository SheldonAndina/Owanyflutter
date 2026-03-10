import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// LOADING SHIMMER - Skeleton Loading Premium
/// Design System: OwanyTheme
/// Múltiplos estilos e variações pré-configuradas
/// ============================================================

class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double? borderRadius;
  final ShimmerStyle style;
  final bool isDark;
  final Duration duration;
  final List<Color>? customColors;
  final ShimmerShape shape;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
    this.style = ShimmerStyle.standard,
    this.isDark = false,
    this.duration = const Duration(milliseconds: 1500),
    this.customColors,
    this.shape = ShimmerShape.rectangle,
  });

  /// Factory: Shimmer padrão retangular
  factory LoadingShimmer.rectangle({
    required double height,
    double width = double.infinity,
    double? borderRadius,
    bool isDark = false,
  }) {
    return LoadingShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius,
      isDark: isDark,
      shape: ShimmerShape.rectangle,
    );
  }

  /// Factory: Shimmer circular (avatar)
  factory LoadingShimmer.circle({required double size, bool isDark = false}) {
    return LoadingShimmer(width: size, height: size, isDark: isDark, shape: ShimmerShape.circle);
  }

  /// Factory: Shimmer de texto (linha única)
  factory LoadingShimmer.text({double width = 200, double height = 16, bool isDark = false}) {
    return LoadingShimmer(width: width, height: height, borderRadius: 4, isDark: isDark);
  }

  /// Factory: Shimmer de card
  factory LoadingShimmer.card({double? width, double height = 120, bool isDark = false}) {
    return LoadingShimmer(
      width: width ?? double.infinity,
      height: height,
      borderRadius: 16,
      isDark: isDark,
      style: ShimmerStyle.elevated,
    );
  }

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: widget.duration, vsync: this)..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: _buildDecoration(),
          foregroundDecoration: _buildForegroundDecoration(),
        );
      },
    );
  }

  /// Decoração base
  BoxDecoration _buildDecoration() {
    final baseColors = _getBaseColors();
    final borderRadius = _getBorderRadius();

    BoxDecoration decoration;

    switch (widget.style) {
      case ShimmerStyle.standard:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: baseColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        );
        break;

      case ShimmerStyle.elevated:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: baseColors,
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.textPrimary(context).withValues(alpha: widget.isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;

      case ShimmerStyle.outlined:
        decoration = BoxDecoration(
          color: widget.isDark ? OwanyTheme.darkSurface : OwanyTheme.cardColor(context),
          border: Border.all(
            color: widget.isDark ? OwanyTheme.darkBorder : OwanyTheme.borderColor(context),
            width: 1.5,
          ),
        );
        break;
    }

    // Aplicar border radius ou shape
    if (widget.shape == ShimmerShape.circle) {
      return decoration.copyWith(shape: BoxShape.circle);
    } else {
      return decoration.copyWith(borderRadius: borderRadius);
    }
  }

  /// Decoração do foreground (efeito shimmer)
  BoxDecoration _buildForegroundDecoration() {
    final borderRadius = _getBorderRadius();

    BoxDecoration decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          OwanyTheme.adaptiveOverlay(context, opacity: 0),
          OwanyTheme.adaptiveOverlay(context, opacity: widget.isDark ? 0.15 : 0.4),
          OwanyTheme.adaptiveOverlay(context, opacity: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: _SlidingGradientTransform(slidePercent: _animationController.value),
      ),
    );

    if (widget.shape == ShimmerShape.circle) {
      return decoration.copyWith(shape: BoxShape.circle);
    } else {
      return decoration.copyWith(borderRadius: borderRadius);
    }
  }

  /// Cores base do shimmer
  List<Color> _getBaseColors() {
    if (widget.customColors != null) {
      return widget.customColors!;
    }

    if (widget.isDark) {
      return [OwanyTheme.darkSurface, const Color(0xFF2D2D2D), OwanyTheme.darkSurface];
    } else {
      return [OwanyTheme.surface, OwanyTheme.surfaceHover, OwanyTheme.surface];
    }
  }

  /// Border radius
  BorderRadius? _getBorderRadius() {
    if (widget.shape == ShimmerShape.circle) {
      return null;
    }
    return BorderRadius.circular(widget.borderRadius ?? 8);
  }
}

/// ============================================================
/// SLIDING GRADIENT TRANSFORM - Transformação do Gradiente
/// ============================================================

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// ============================================================
/// ENUMS
/// ============================================================

enum ShimmerStyle {
  standard, // Padrão plano
  elevated, // Com sombra
  outlined, // Com borda
}

enum ShimmerShape {
  rectangle, // Retangular
  circle, // Circular
}

/// ============================================================
/// SHIMMER LAYOUTS - Layouts Pré-configurados
/// ============================================================

/// Layout de Card com Avatar
class ShimmerCardLayout extends StatelessWidget {
  final bool isDark;

  const ShimmerCardLayout({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? OwanyTheme.darkSurface : OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          LoadingShimmer.circle(size: 56, isDark: isDark),

          SizedBox(width: 16),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer.text(width: 150, height: 18, isDark: isDark),
                SizedBox(height: 8),
                LoadingShimmer.text(width: 200, height: 14, isDark: isDark),
                SizedBox(height: 8),
                LoadingShimmer.text(width: 100, height: 12, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout de Lista
class ShimmerListLayout extends StatelessWidget {
  final int itemCount;
  final bool isDark;

  const ShimmerListLayout({super.key, this.itemCount = 5, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) => ShimmerCardLayout(isDark: isDark),
    );
  }
}

/// Layout de Grid
class ShimmerGridLayout extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final bool isDark;

  const ShimmerGridLayout({super.key, this.itemCount = 6, this.crossAxisCount = 2, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingShimmer.card(isDark: isDark);
      },
    );
  }
}

/// Layout de Perfil
class ShimmerProfileLayout extends StatelessWidget {
  final bool isDark;

  const ShimmerProfileLayout({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar grande
          LoadingShimmer.circle(size: 100, isDark: isDark),

          SizedBox(height: 24),

          // Nome
          LoadingShimmer.text(width: 200, height: 24, isDark: isDark),

          SizedBox(height: 8),

          // Subtítulo
          LoadingShimmer.text(width: 150, height: 16, isDark: isDark),

          SizedBox(height: 32),

          // Cards de informação
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingShimmer.card(height: 80, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout de Solicitação
class ShimmerSolicitacaoLayout extends StatelessWidget {
  final bool isDark;

  const ShimmerSolicitacaoLayout({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? OwanyTheme.darkSurface : OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              LoadingShimmer.circle(size: 40, isDark: isDark),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingShimmer.text(width: 180, height: 18, isDark: isDark),
                    SizedBox(height: 6),
                    LoadingShimmer.text(width: 120, height: 14, isDark: isDark),
                  ],
                ),
              ),
              LoadingShimmer.rectangle(width: 80, height: 28, borderRadius: 14, isDark: isDark),
            ],
          ),

          SizedBox(height: 16),

          // Conteúdo
          LoadingShimmer.text(width: double.infinity, height: 14, isDark: isDark),
          SizedBox(height: 8),
          LoadingShimmer.text(width: 250, height: 14, isDark: isDark),

          SizedBox(height: 16),

          // Footer
          Row(
            children: [
              LoadingShimmer.rectangle(width: 100, height: 12, borderRadius: 6, isDark: isDark),
              SizedBox(width: 16),
              LoadingShimmer.rectangle(width: 100, height: 12, borderRadius: 6, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class LoadingShimmerExample extends StatelessWidget {
  const LoadingShimmerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(title: Text('Loading Shimmers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shimmers básicos
          Text('Shimmers Básicos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 16),

          LoadingShimmer.circle(size: 60),
          SizedBox(height: 12),

          LoadingShimmer.text(width: 200, height: 16),
          SizedBox(height: 12),

          LoadingShimmer.rectangle(height: 100),
          SizedBox(height: 12),

          LoadingShimmer.card(height: 120),

          SizedBox(height: 32),

          // Layouts pré-configurados
          Text('Layouts Pré-configurados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 16),

          const ShimmerCardLayout(),
          SizedBox(height: 12),

          const ShimmerSolicitacaoLayout(),
          SizedBox(height: 12),

          const ShimmerListLayout(itemCount: 3),
          SizedBox(height: 24),

          const ShimmerGridLayout(itemCount: 4),
        ],
      ),
    );
  }
}
