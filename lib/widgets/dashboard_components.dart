import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// Métrica Estatística (para Dashboard)
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? percentage;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? OwanyTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwanyTheme.borderColor(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor ?? OwanyTheme.primaryOrange, size: 24),
                ),
                if (percentage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorForPercentage(percentage!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage!.toStringAsFixed(0)}%',
                      style: OwanyTheme.labelSmall.copyWith(
                        color: OwanyTheme.cardColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(value, style: OwanyTheme.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(
              label,
              style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMuted, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(subtitle!, style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.primaryOrange)),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 75) return const Color(0xFF7BA57E);
    if (percentage >= 50) return const Color(0xFFD9A85C);
    return const Color(0xFFE85D46);
  }
}

/// Card de Atividade Recente
class ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String timestamp;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.timestamp,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OwanyTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OwanyTheme.borderColor(context), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor ?? OwanyTheme.primaryOrange, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: OwanyTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.textMuted.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: OwanyTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Card de Status com Indicador
class StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const StatusCard({
    super.key,
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected ? backgroundColor : backgroundColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: backgroundColor, size: 24),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: OwanyTheme.headlineSmall.copyWith(color: backgroundColor, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: OwanyTheme.labelSmall.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Header do Dashboard
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String? greeting;
  final String? subtitle;
  final VoidCallback? onNotificationTap;
  final bool showNotificationBadge;
  final int notificationCount;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.greeting,
    this.subtitle,
    this.onNotificationTap,
    this.showNotificationBadge = false,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting ?? 'Olá, $userName 👋',
                  style: OwanyTheme.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(subtitle!, style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMuted)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OwanyTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OwanyTheme.borderColor(context), width: 1),
                  ),
                  child: Icon(Icons.notifications_outlined, color: OwanyTheme.textMuted, size: 24),
                ),
                if (showNotificationBadge && notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85D46),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        notificationCount > 9 ? '9+' : '$notificationCount',
                        style: OwanyTheme.labelSmall.copyWith(
                          color: OwanyTheme.cardColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Secção com Título e Ação
class DashboardSection extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final List<Widget> children;
  final ScrollDirection direction;
  final double spacing;

  const DashboardSection({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    required this.children,
    this.direction = ScrollDirection.vertical,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
        SizedBox(height: 12),
        if (direction == ScrollDirection.vertical)
          Column(
            children: List.generate(
              children.length,
              (index) => Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: index < children.length - 1 ? spacing : 0),
                child: children[index],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(
                children.length,
                (index) => Padding(
                  padding: EdgeInsets.only(right: index < children.length - 1 ? spacing : 0),
                  child: children[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Card Simples para Informação
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  final Color? accentColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.unit,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwanyTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OwanyTheme.borderColor(context), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (accentColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accentColor ?? OwanyTheme.primaryOrange, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.textMuted)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: OwanyTheme.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                    if (unit != null) ...[
                      SizedBox(width: 4),
                      Text(unit!, style: OwanyTheme.labelSmall.copyWith(color: OwanyTheme.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ScrollDirection { vertical, horizontal }
