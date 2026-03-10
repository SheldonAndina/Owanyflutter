import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// EMPTY STATE - Estado Vazio Premium
/// Design System: OwanyTheme
/// Suporta múltiplos estilos e animações
/// ============================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final EmptyStateStyle style;
  final Widget? customIllustration;
  final bool showAnimation;
  final List<String>? suggestions;
  final Widget? secondaryAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.style = EmptyStateStyle.standard,
    this.customIllustration,
    this.showAnimation = true,
    this.suggestions,
    this.secondaryAction,
  });

  /// Factory: Estado vazio padrão
  factory EmptyState.standard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    Color? iconColor,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: iconColor,
      style: EmptyStateStyle.standard,
    );
  }

  /// Factory: Estado vazio com gradiente
  factory EmptyState.gradient({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    Widget? customIllustration,
    Color? iconColor,
    List<String>? suggestions,
    Widget? secondaryAction,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      style: EmptyStateStyle.gradient,
      customIllustration: customIllustration,
      iconColor: iconColor,
      suggestions: suggestions,
      secondaryAction: secondaryAction,
    );
  }

  /// Factory: Lista vazia
  factory EmptyState.emptyList({required String title, String? subtitle, String? actionLabel, VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.inbox_rounded,
      title: title,
      subtitle: subtitle ?? 'Nenhum item encontrado',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Factory: Busca sem resultados
  factory EmptyState.noResults({required String searchTerm, VoidCallback? onClearSearch}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'Nenhum resultado encontrado',
      subtitle: 'Não encontramos resultados para "$searchTerm"',
      actionLabel: 'Limpar busca',
      onAction: onClearSearch,
      iconColor: OwanyTheme.textMuted,
    );
  }

  /// Factory: Erro de conexão
  factory EmptyState.connectionError({required VoidCallback onRetry}) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Sem conexão',
      subtitle: 'Verifique sua conexão com a internet e tente novamente',
      actionLabel: 'Tentar novamente',
      onAction: onRetry,
      iconColor: OwanyTheme.error,
    );
  }

  /// Factory: Permissão negada
  factory EmptyState.permissionDenied({required String title, String? subtitle, VoidCallback? onRequestPermission}) {
    return EmptyState(
      icon: Icons.lock_rounded,
      title: title,
      subtitle: subtitle ?? 'Você não tem permissão para acessar este conteúdo',
      actionLabel: 'Solicitar acesso',
      onAction: onRequestPermission,
      iconColor: OwanyTheme.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ilustração/Ícone
              _buildIllustration(),

              SizedBox(height: 32),

              // Título
              _buildTitle(context),

              // Subtítulo
              if (subtitle != null) ...[SizedBox(height: 12), _buildSubtitle(context)],

              // Sugestões
              if (suggestions != null && suggestions!.isNotEmpty) ...[SizedBox(height: 24), _buildSuggestions()],

              // Ações
              if (actionLabel != null && onAction != null) ...[SizedBox(height: 32), _buildPrimaryAction()],

              // Ação secundária
              if (secondaryAction != null) ...[SizedBox(height: 12), secondaryAction!],
            ],
          ),
        ),
      ),
    );
  }

  /// Ilustração com animação
  Widget _buildIllustration() {
    if (customIllustration != null) {
      return customIllustration!;
    }

    return showAnimation
        ? _AnimatedIcon(icon: icon, color: iconColor ?? OwanyTheme.primaryOrange, style: style)
        : _StaticIcon(icon: icon, color: iconColor ?? OwanyTheme.primaryOrange, style: style);
  }

  /// Título
  Widget _buildTitle(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: OwanyTheme.textDark, letterSpacing: -0.5),
      textAlign: TextAlign.center,
    );
  }

  /// Subtítulo
  Widget _buildSubtitle(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Text(
        subtitle!,
        style: TextStyle(fontSize: 15, color: OwanyTheme.textMuted, height: 1.6),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Lista de sugestões
  Widget _buildSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, size: 16, color: OwanyTheme.warning),
              SizedBox(width: 8),
              Text(
                'Sugestões',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textDark),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...suggestions!.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(color: OwanyTheme.primaryOrange, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(suggestion, style: TextStyle(fontSize: 13, color: OwanyTheme.textMuted, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de ação primária
  Widget _buildPrimaryAction() {
    return Builder(
      builder: (context) => ElevatedButton.icon(
        onPressed: onAction,
        icon: Icon(Icons.add_rounded, size: 20),
        label: Text(actionLabel!),
        style: ElevatedButton.styleFrom(
          backgroundColor: iconColor ?? OwanyTheme.primaryOrange,
          foregroundColor: OwanyTheme.adaptiveTextOverlay(context),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(overlayColor: WidgetStateProperty.all(OwanyTheme.adaptiveOverlay(context, opacity: 0.1))),
      ),
    );
  }
}

/// ============================================================
/// ANIMATED ICON - Ícone Animado
/// ============================================================

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final EmptyStateStyle style;

  const _AnimatedIcon({required this.icon, required this.color, required this.style});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(angle: _rotationAnimation.value, child: _buildIconContainer()),
          ),
        );
      },
    );
  }

  Widget _buildIconContainer() {
    switch (widget.style) {
      case EmptyStateStyle.standard:
        return _buildStandardIcon();
      case EmptyStateStyle.gradient:
        return _buildGradientIcon();
      case EmptyStateStyle.outlined:
        return _buildOutlinedIcon();
    }
  }

  Widget _buildStandardIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(widget.icon, size: 56, color: widget.color),
    );
  }

  Widget _buildGradientIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.color, widget.color.withValues(alpha: 0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Icon(widget.icon, size: 56, color: OwanyTheme.adaptiveTextOverlay(context)),
    );
  }

  Widget _buildOutlinedIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        shape: BoxShape.circle,
        border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(widget.icon, size: 56, color: widget.color),
    );
  }
}

/// ============================================================
/// STATIC ICON - Ícone Estático
/// ============================================================

class _StaticIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final EmptyStateStyle style;

  const _StaticIcon({required this.icon, required this.color, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 56, color: color),
    );
  }
}

/// ============================================================
/// EMPTY STATE STYLE - Estilos
/// ============================================================

enum EmptyStateStyle {
  standard, // Padrão com fundo colorido
  gradient, // Com gradiente
  outlined, // Com borda
}

/// ============================================================
/// EMPTY STATE VARIANTS - Variações Pré-configuradas
/// ============================================================

/// Estado vazio para solicitações
class EmptySolicitacoes extends StatelessWidget {
  final VoidCallback? onCreateNew;

  const EmptySolicitacoes({super.key, this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.build_rounded,
      title: 'Nenhuma solicitação',
      subtitle: 'Você ainda não possui solicitações. Crie sua primeira solicitação agora!',
      actionLabel: 'Criar Solicitação',
      onAction: onCreateNew,
      suggestions: const ['Descreva o problema claramente', 'Adicione fotos se necessário', 'Defina um prazo adequado'],
    );
  }
}

/// Estado vazio para apartamentos
class EmptyApartamentos extends StatelessWidget {
  final VoidCallback? onAddNew;

  const EmptyApartamentos({super.key, this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return EmptyState.gradient(
      icon: Icons.apartment_rounded,
      title: 'Nenhum apartamento cadastrado',
      subtitle: 'Adicione apartamentos para começar a gerenciar o condomínio',
      actionLabel: 'Adicionar Apartamento',
      onAction: onAddNew,
    );
  }
}

/// Estado vazio para usuários
class EmptyUsuarios extends StatelessWidget {
  final VoidCallback? onAddNew;

  const EmptyUsuarios({super.key, this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.people_rounded,
      title: 'Nenhum usuário encontrado',
      subtitle: 'Convide usuários para colaborar no sistema',
      actionLabel: 'Convidar Usuário',
      onAction: onAddNew,
      iconColor: const Color(0xFF8B5CF6),
    );
  }
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class EmptyStateExample extends StatelessWidget {
  const EmptyStateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(title: Text('Empty States')),
      body: ListView(
        children: [
          // Estado padrão
          SizedBox(
            height: 400,
            child: EmptyState.standard(
              icon: Icons.inbox_rounded,
              title: 'Nada por aqui',
              subtitle: 'Comece criando seu primeiro item',
              actionLabel: 'Criar Novo',
              onAction: () => debugPrintLog('Criar'),
            ),
          ),

          const Divider(),

          // Estado com gradiente
          SizedBox(
            height: 400,
            child: EmptyState.gradient(
              icon: Icons.apartment_rounded,
              title: 'Sem apartamentos',
              subtitle: 'Adicione apartamentos para gerenciar',
              actionLabel: 'Adicionar',
              onAction: () => debugPrintLog('Adicionar'),
            ),
          ),

          const Divider(),

          // Busca sem resultados
          SizedBox(
            height: 400,
            child: EmptyState.noResults(searchTerm: 'apartamento 101', onClearSearch: () => debugPrintLog('Limpar')),
          ),

          const Divider(),

          // Erro de conexão
          SizedBox(height: 400, child: EmptyState.connectionError(onRetry: () => debugPrintLog('Retry'))),

          const Divider(),

          // Com sugestões
          SizedBox(
            height: 500,
            child: EmptyState(
              icon: Icons.build_rounded,
              title: 'Nenhuma solicitação',
              subtitle: 'Crie sua primeira solicitação',
              actionLabel: 'Criar',
              onAction: () => debugPrintLog('Criar'),
              suggestions: const [
                'Descreva o problema claramente',
                'Adicione fotos se necessário',
                'Defina um prazo adequado',
              ],
            ),
          ),

          const Divider(),

          // Componentes pré-configurados
          SizedBox(height: 500, child: EmptySolicitacoes()),
        ],
      ),
    );
  }
}
