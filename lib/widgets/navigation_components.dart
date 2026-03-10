import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// Bottom Navigation Moderna e Profissional
class ModernBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final bool showLabels;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.showLabels = true,
  });

  @override
  State<ModernBottomNavBar> createState() => _ModernBottomNavBarState();
}

class _ModernBottomNavBarState extends State<ModernBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? OwanyTheme.surface,
        border: Border(top: BorderSide(color: OwanyTheme.borderColor(context), width: 1)),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              widget.items.length,
              (index) => Expanded(
                child: _NavItem(
                  item: widget.items[index],
                  isSelected: widget.currentIndex == index,
                  onTap: () => widget.onTap(index),
                  selectedColor: widget.selectedItemColor ?? OwanyTheme.primaryOrange,
                  unselectedColor: widget.unselectedItemColor ?? OwanyTheme.textMuted,
                  showLabel: widget.showLabels,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ModernNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: isSelected ? selectedColor : unselectedColor, size: 24),
            ),
            if (showLabel) ...[
              SizedBox(height: 4),
              Text(
                item.label,
                style: OwanyTheme.labelSmall.copyWith(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.badgeCount != null && item.badgeCount! > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: const Color(0xFFE85D46), borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    item.badgeCount! > 9 ? '9+' : '${item.badgeCount}',
                    style: OwanyTheme.labelSmall.copyWith(
                      color: OwanyTheme.cardColor(context),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Item de Bottom Navigation
class ModernNavItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  ModernNavItem({required this.icon, required this.label, this.badgeCount});
}

/// Drawer Moderno
class ModernDrawer extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String? userPhone;
  final IconData? userIcon;
  final VoidCallback? onProfileTap;
  final List<DrawerItem> items;
  final VoidCallback? onLogout;

  const ModernDrawer({
    super.key,
    required this.userName,
    this.userEmail,
    this.userPhone,
    this.userIcon,
    this.onProfileTap,
    required this.items,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: OwanyTheme.backgroundColor(context),
      child: SafeArea(
        child: Column(
          children: [
            // Header com Usuário
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OwanyTheme.textPrimary(context),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: GestureDetector(
                onTap: onProfileTap,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        userIcon ?? Icons.person_outline_rounded,
                        color: OwanyTheme.cardColor(context),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: OwanyTheme.bodyLarge.copyWith(
                              color: OwanyTheme.cardColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userEmail != null) ...[
                            SizedBox(height: 4),
                            Text(
                              userEmail!,
                              style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.white.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (userPhone != null) ...[
                            SizedBox(height: 2),
                            Text(
                              userPhone!,
                              style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.white.withValues(alpha: 0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: OwanyTheme.white.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: items.map((item) => _DrawerItemWidget(item: item)).toList(),
              ),
            ),

            // Logout Button
            if (onLogout != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.logout_rounded),
                  label: Text('Sair'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFE85D46),
                    foregroundColor: OwanyTheme.cardColor(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemWidget extends StatelessWidget {
  final DrawerItem item;

  const _DrawerItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (item.isSection) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.label,
                style: OwanyTheme.labelLarge.copyWith(
                  color: OwanyTheme.textMutedColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Divider(color: OwanyTheme.borderColor(context), height: 1, indent: 20, endIndent: 20),
        ] else
          ListTile(
            leading: Icon(
              item.icon,
              color: item.isActive ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
            ),
            title: Text(
              item.label,
              style: OwanyTheme.bodySmall.copyWith(
                color: item.isActive ? OwanyTheme.primaryOrange : OwanyTheme.textPrimary(context),
                fontWeight: item.isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: item.trailing,
            onTap: item.onTap,
            tileColor: item.isActive ? OwanyTheme.primaryOrange.withValues(alpha: 0.08) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

/// Item do Drawer
class DrawerItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isActive;
  final bool isSection;

  DrawerItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.trailing,
    this.isActive = false,
    this.isSection = false,
  });
}

/// AppBar com Drawer Automático
class ModernDrawerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onDrawerTap;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final IconData? leadingIcon;

  const ModernDrawerAppBar({
    super.key,
    required this.title,
    this.onDrawerTap,
    this.actions,
    this.showBack = false,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.leadingIcon,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: OwanyTheme.headlineMedium.copyWith(
          color: titleColor ?? OwanyTheme.cardColor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: backgroundColor ?? OwanyTheme.primaryOrange,
      elevation: 2,
      centerTitle: false,
      iconTheme: IconThemeData(color: iconColor ?? OwanyTheme.cardColor(context)),
      leading: showBack
          ? IconButton(icon: Icon(Icons.arrow_back_rounded), onPressed: onBackPressed ?? () => Navigator.pop(context))
          : Builder(
              builder: (context) => IconButton(
                icon: Icon(leadingIcon ?? Icons.menu_rounded, color: iconColor ?? OwanyTheme.cardColor(context)),
                onPressed: onDrawerTap ?? () => Scaffold.of(context).openDrawer(),
              ),
            ),
      actions: actions,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
    );
  }
}
