import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import 'package:flutter/services.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// COMMON APPBAR - AppBar Premium com Gradiente
/// Design System: OwanyTheme
/// ============================================================

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool centerTitle;
  final bool useGradient;
  final Color? backgroundColor;
  final double elevation;
  final bool showShadow;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.leading,
    this.centerTitle = true,
    this.useGradient = true,
    this.backgroundColor,
    this.elevation = 0,
    this.showShadow = true,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: useGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [OwanyTheme.textPrimary(context), OwanyTheme.primaryBrown],
              ),
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: OwanyTheme.textPrimary(context).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            )
          : BoxDecoration(
              color: backgroundColor ?? OwanyTheme.textPrimary(context),
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: OwanyTheme.textPrimary(context).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: elevation,
        centerTitle: centerTitle,
        systemOverlayStyle:
            systemOverlayStyle ??
            SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
        automaticallyImplyLeading: false,
        leading: _buildLeading(context),
        title: _buildTitle(context),
        actions: _buildActions(),
        bottom: bottom,
      ),
    );
  }

  /// Construir Leading (botão de voltar ou custom)
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBackButton) return null;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onBackPressed ?? () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: OwanyTheme.adaptiveTextOverlay(context), size: 20),
          ),
        ),
      ),
    );
  }

  /// Construir Título (com ou sem subtítulo)
  Widget _buildTitle(BuildContext context) {
    if (subtitle == null) {
      return Text(
        title,
        style: TextStyle(
          color: OwanyTheme.adaptiveTextOverlay(context),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2),
        Text(
          subtitle!,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Construir Actions
  List<Widget>? _buildActions() {
    if (actions == null || actions!.isEmpty) return null;

    return actions!.map((action) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: action);
    }).toList();
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// ============================================================
/// APPBAR ACTION BUTTON - Botão de Ação Premium
/// ============================================================

class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final int? badge;
  final bool showBadge;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.badge,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor ?? OwanyTheme.adaptiveTextOverlay(context), size: 22),
              ),
            ),
          ),
        ),

        // Badge de Notificação
        if (showBadge && badge != null && badge! > 0)
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [OwanyTheme.error, Color(0xFFDC2626)]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OwanyTheme.textPrimary(context), width: 2),
                boxShadow: [
                  BoxShadow(color: OwanyTheme.error.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

/// ============================================================
/// SEARCH APPBAR - AppBar com Campo de Busca
/// ============================================================

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchAppBar({
    super.key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
    this.showBackButton = true,
    this.onBackPressed,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.textPrimary(context), const Color(0xFF2D2420)],
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Botão Voltar
              if (showBackButton) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onBackPressed ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],

              // Campo de Busca
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2), width: 1),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                        size: 22,
                      ),
                      suffixIcon: controller?.text.isNotEmpty ?? false
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                controller?.clear();
                                onClear?.call();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

/// ============================================================
/// TABBED APPBAR - AppBar com Tabs
/// ============================================================

class TabbedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<String> tabs;
  final TabController? controller;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const TabbedAppBar({
    super.key,
    required this.title,
    required this.tabs,
    this.controller,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.textPrimary(context), OwanyTheme.primaryBrown],
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? Container(
                margin: const EdgeInsets.only(left: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onBackPressed ?? () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            color: OwanyTheme.adaptiveTextOverlay(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: actions,
        bottom: TabBar(
          controller: controller,
          isScrollable: tabs.length > 3,
          indicatorColor: OwanyTheme.primaryOrange,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: OwanyTheme.adaptiveTextOverlay(context),
          unselectedLabelColor: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.6),
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class AppBarExample extends StatefulWidget {
  const AppBarExample({super.key});

  @override
  State<AppBarExample> createState() => _AppBarExampleState();
}

class _AppBarExampleState extends State<AppBarExample> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),

      // AppBar Padrão
      appBar: CommonAppBar(
        title: 'Dashboard',
        subtitle: 'Bem-vindo de volta!',
        actions: [
          AppBarActionButton(
            icon: Icons.notifications_rounded,
            onTap: () {},
            tooltip: 'Notificações',
            showBadge: true,
            badge: 5,
          ),
          AppBarActionButton(icon: Icons.settings_rounded, onTap: () {}, tooltip: 'Configurações'),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Demonstração: AppBar com Busca
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: OwanyTheme.backgroundColor(context),
                    appBar: SearchAppBar(
                      hintText: 'Buscar solicitações...',
                      controller: _searchController,
                      onChanged: (value) => debugPrintLog('Buscando: $value'),
                      onClear: () => debugPrintLog('Limpar busca'),
                    ),
                    body: Center(child: Text('Busca')),
                  ),
                ),
              );
            },
            child: Text('Ver AppBar com Busca'),
          ),

          SizedBox(height: 16),

          // Demonstração: AppBar com Tabs
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: OwanyTheme.backgroundColor(context),
                    appBar: TabbedAppBar(
                      title: 'Solicitações',
                      tabs: const ['Pendentes', 'Em Andamento', 'Concluídas'],
                      controller: _tabController,
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: const [
                        Center(child: Text('Pendentes')),
                        Center(child: Text('Em Andamento')),
                        Center(child: Text('Concluídas')),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Text('Ver AppBar com Tabs'),
          ),
        ],
      ),
    );
  }
}
