import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// PRIMARY BUTTON - Botão Premium com Estados
/// Design System: OwanyTheme
/// Suporta loading, success, error e múltiplos estilos
/// ============================================================

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonState state;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.state = ButtonState.normal,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
    this.fullWidth = false,
  });

  /// Factory: Botão Primário (padrão)
  factory PrimaryButton.primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.primary,
      icon: icon,
    );
  }

  /// Factory: Botão Secundário
  factory PrimaryButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.secondary,
      icon: icon,
    );
  }

  /// Factory: Botão de Sucesso
  factory PrimaryButton.success({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      state: ButtonState.success,
      icon: icon,
    );
  }

  /// Factory: Botão de Erro
  factory PrimaryButton.error({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      state: ButtonState.error,
      icon: icon,
    );
  }

  /// Factory: Botão Outlined
  factory PrimaryButton.outlined({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.outlined,
      icon: icon,
    );
  }

  /// Factory: Botão com Gradiente
  factory PrimaryButton.gradient({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: ButtonVariant.gradient,
      icon: icon,
    );
  }

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) {
        _controller.forward();
      },
      onTapUp: isDisabled ? null : (_) {
        _controller.reverse();
      },
      onTapCancel: isDisabled ? null : () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(isDisabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(isDisabled);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(isDisabled);
      case ButtonVariant.outlined:
        return _buildOutlinedButton(isDisabled);
      case ButtonVariant.gradient:
        return _buildGradientButton(isDisabled);
    }
  }

  /// Botão Primário
  Widget _buildPrimaryButton(bool isDisabled) {
    return Container(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: _getBaseColor().withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// Botão Secundário
  Widget _buildSecondaryButton(bool isDisabled) {
    return Container(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: OwanyTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled ? OwanyTheme.borderColor(context) : _getBaseColor(),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(textColor: _getBaseColor()),
          ),
        ),
      ),
    );
  }

  /// Botão Outlined
  Widget _buildOutlinedButton(bool isDisabled) {
    return Container(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled
              ? OwanyTheme.borderColor(context)
              : _getBaseColor().withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(textColor: _getBaseColor()),
          ),
        ),
      ),
    );
  }

  /// Botão com Gradiente
  Widget _buildGradientButton(bool isDisabled) {
    return Container(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            OwanyTheme.primaryOrange,
            OwanyTheme.accent,
            Color(0xFFFFB380),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  /// Conteúdo do Botão
  Widget _buildContent({Color? textColor}) {
    final effectiveTextColor = textColor ?? OwanyTheme.adaptiveTextOverlay(context);
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: effectiveTextColor,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.state == ButtonState.success)
          _buildStateIcon(Icons.check_circle_rounded, effectiveTextColor)
        else if (widget.state == ButtonState.error)
          _buildStateIcon(Icons.error_rounded, effectiveTextColor)
        else if (widget.icon != null) ...[
          Icon(widget.icon, color: effectiveTextColor, size: 20),
          SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Ícone de Estado
  Widget _buildStateIcon(IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }

  /// Cores do Gradiente
  List<Color> _getGradientColors() {
    switch (widget.state) {
      case ButtonState.normal:
        return [
          OwanyTheme.primaryOrange,
          OwanyTheme.accent,
        ];
      case ButtonState.success:
        return [
          OwanyTheme.success,
          const Color(0xFF059669),
        ];
      case ButtonState.error:
        return [
          OwanyTheme.error,
          const Color(0xFFDC2626),
        ];
      case ButtonState.warning:
        return [
          OwanyTheme.warning,
          const Color(0xFFD97706),
        ];
    }
  }

  /// Cor Base
  Color _getBaseColor() {
    switch (widget.state) {
      case ButtonState.normal:
        return OwanyTheme.primaryOrange;
      case ButtonState.success:
        return OwanyTheme.success;
      case ButtonState.error:
        return OwanyTheme.error;
      case ButtonState.warning:
        return OwanyTheme.warning;
    }
  }
}

/// ============================================================
/// ENUMS
/// ============================================================

enum ButtonState {
  normal,
  success,
  error,
  warning,
}

enum ButtonVariant {
  primary,   // Preenchido com gradiente
  secondary, // Com fundo e borda
  outlined,  // Apenas borda
  gradient,  // Gradiente premium
}

/// ============================================================
/// BUTTON GROUP - Grupo de Botões
/// ============================================================

class ButtonGroup extends StatelessWidget {
  final List<Widget> buttons;
  final Axis direction;
  final MainAxisAlignment alignment;
  final double spacing;

  const ButtonGroup({
    super.key,
    required this.buttons,
    this.direction = Axis.horizontal,
    this.alignment = MainAxisAlignment.center,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: alignment,
        children: _buildChildrenWithSpacing(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildChildrenWithSpacing(),
      );
    }
  }

  List<Widget> _buildChildrenWithSpacing() {
    final List<Widget> children = [];
    for (int i = 0; i < buttons.length; i++) {
      children.add(
        direction == Axis.horizontal
            ? Expanded(child: buttons[i])
            : buttons[i],
      );
      if (i < buttons.length - 1) {
        children.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
    }
    return children;
  }
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class PrimaryButtonExample extends StatefulWidget {
  const PrimaryButtonExample({super.key});

  @override
  State<PrimaryButtonExample> createState() => _PrimaryButtonExampleState();
}

class _PrimaryButtonExampleState extends State<PrimaryButtonExample> {
  bool _isLoading = false;
  ButtonState _buttonState = ButtonState.normal;

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _buttonState = ButtonState.success;
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _buttonState = ButtonState.normal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text('Primary Buttons'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Botão com Estado Dinâmico
          Text(
            'Botão com Estados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          
          PrimaryButton(
            text: _isLoading
                ? 'Carregando...'
                : _buttonState == ButtonState.success
                    ? 'Sucesso!'
                    : 'Enviar Formulário',
            onPressed: _isLoading ? null : _handleSubmit,
            isLoading: _isLoading,
            state: _buttonState,
            icon: Icons.send_rounded,
            fullWidth: true,
          ),

          SizedBox(height: 32),

          // Variações de Botões
          Text(
            'Variações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          PrimaryButton.primary(
            text: 'Botão Primário',
            onPressed: () => debugPrintLog('Primary'),
            icon: Icons.check_rounded,
          ),

          SizedBox(height: 12),

          PrimaryButton.secondary(
            text: 'Botão Secundário',
            onPressed: () => debugPrintLog('Secondary'),
            icon: Icons.settings_rounded,
          ),

          SizedBox(height: 12),

          PrimaryButton.outlined(
            text: 'Botão Outlined',
            onPressed: () => debugPrintLog('Outlined'),
            icon: Icons.info_rounded,
          ),

          SizedBox(height: 12),

          PrimaryButton.gradient(
            text: 'Botão Gradiente Premium',
            onPressed: () => debugPrintLog('Gradient'),
            icon: Icons.star_rounded,
          ),

          SizedBox(height: 32),

          // Estados
          Text(
            'Estados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          PrimaryButton.success(
            text: 'Operação Concluída',
            onPressed: () => debugPrintLog('Success'),
            icon: Icons.check_circle_rounded,
          ),

          SizedBox(height: 12),

          PrimaryButton.error(
            text: 'Erro na Operação',
            onPressed: () => debugPrintLog('Error'),
            icon: Icons.error_rounded,
          ),

          SizedBox(height: 12),

          PrimaryButton(
            text: 'Aviso Importante',
            onPressed: () => printLog('Warning'),
            state: ButtonState.warning,
            icon: Icons.warning_rounded,
          ),

          SizedBox(height: 32),

          // Loading
          Text(
            'Loading State',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          PrimaryButton(
            text: 'Processando...',
            onPressed: () {},
            isLoading: true,
          ),

          SizedBox(height: 32),

          // Button Group
          Text(
            'Button Groups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          ButtonGroup(
            buttons: [
              PrimaryButton.outlined(
                text: 'Cancelar',
                onPressed: () => debugPrintLog('Cancel'),
              ),
              PrimaryButton.primary(
                text: 'Confirmar',
                onPressed: () => debugPrintLog('Confirm'),
              ),
            ],
          ),

          SizedBox(height: 16),

          ButtonGroup(
            direction: Axis.vertical,
            buttons: [
              PrimaryButton.primary(
                text: 'Opção 1',
                onPressed: () => debugPrintLog('Option 1'),
              ),
              PrimaryButton.secondary(
                text: 'Opção 2',
                onPressed: () => debugPrintLog('Option 2'),
              ),
              PrimaryButton.outlined(
                text: 'Opção 3',
                onPressed: () => debugPrintLog('Option 3'),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Disabled
          Text(
            'Disabled State',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          PrimaryButton(
            text: 'Botão Desabilitado',
            onPressed: null,
          ),
        ],
      ),
    );
  }
}










