import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/owany_theme.dart';

/// Widget de alternância rápida de tema (opcional)
/// Pode ser adicionado em qualquer tela para facilitar o acesso
class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double? iconSize;

  const ThemeToggleButton({super.key, this.showLabel = false, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: iconSize ?? 24,
          ),
          tooltip: 'Alternar tema: ${themeProvider.themeModeString}',
          onPressed: () async {
            await themeProvider.toggleTheme();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                      ),
                      SizedBox(width: 12),
                      Text('Tema: ${themeProvider.themeModeString}'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: OwanyTheme.primaryOrange,
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// Widget com 3 opções de tema (Light, Dark, System)
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_rounded, color: OwanyTheme.primaryOrange, size: 20),
                  SizedBox(width: 8),
                  Text('Tema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    label: 'Claro',
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: 'Escuro',
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                  _ThemeOption(
                    icon: Icons.settings_suggest_rounded,
                    label: 'Sistema',
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? OwanyTheme.primaryOrange.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? OwanyTheme.primaryOrange : Theme.of(context).iconTheme.color, size: 28),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? OwanyTheme.primaryOrange : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
