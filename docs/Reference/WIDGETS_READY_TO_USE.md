# 📦 Widgets Prontos para Copiar e Colar – OWANY
## Código Pronto para Integração em lib/widgets/

**Status**: ✅ 100% Pronto  
**Formato**: Copiar e colar direto  
**Testado**: Em dashboard, profile, notifications, settings

---

## 1️⃣ Botões

### PrimaryButton.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final EdgeInsets? padding;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OwanyTheme.primaryButtonStyle().copyWith(
          padding: MaterialStatePropertyAll(
            padding ?? const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : icon != null
                ? Icon(icon, size: 20)
                : const SizedBox.shrink(),
        label: Text(isLoading ? 'Processando...' : label),
      ),
    );
  }
}
```

**Uso**:
```dart
PrimaryButton(
  label: 'Salvar',
  onPressed: () => save(),
  isLoading: isLoading,
)
```

---

### SecondaryButton.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: OwanyTheme.darkSlate,
          side: const BorderSide(color: OwanyTheme.lightSlate),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

**Uso**:
```dart
SecondaryButton(
  label: 'Cancelar',
  onPressed: () => Navigator.pop(context),
)
```

---

## 2️⃣ Cards

### StatusCard.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final DateTime date;
  final VoidCallback onTap;

  const StatusCard({
    Key? key,
    required this.title,
    required this.location,
    required this.status,
    required this.date,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    if (status.contains('Pendente')) return Colors.amber;
    if (status.contains('Andamento')) return Colors.indigo;
    if (status.contains('Concluído')) return Colors.green;
    if (status.contains('Interno')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: OwanyTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: OwanyTheme.lightSlate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: OwanyTheme.lightSlate,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Uso**:
```dart
StatusCard(
  title: 'Vazamento na cozinha',
  location: 'Apt 502 | Bloco A',
  status: 'Pendente',
  date: DateTime.now(),
  onTap: () => viewDetail(),
)
```

---

### SectionCard.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.onTap,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: OwanyTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (actionLabel != null && onAction != null)
                    TextButton(
                      onPressed: onAction,
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: OwanyTheme.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
```

**Uso**:
```dart
SectionCard(
  title: 'Informações Gerais',
  actionLabel: 'Editar',
  onAction: () => edit(),
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Criado:'),
        Text('21/01/2026'),
      ],
    ),
  ],
)
```

---

## 3️⃣ Status Badge

### StatusBadge.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final IconData? icon;
  final bool large;

  const StatusBadge({
    Key? key,
    required this.status,
    this.color,
    this.icon,
    this.large = false,
  }) : super(key: key);

  Color _getStatusColor() {
    if (status.contains('Pendente')) return Colors.amber;
    if (status.contains('Andamento')) return Colors.indigo;
    if (status.contains('Concluído')) return Colors.green;
    if (status.contains('Interno')) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? _getStatusColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(large ? 8 : 6),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: large ? 18 : 14,
              color: statusColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Uso**:
```dart
StatusBadge(status: 'Pendente')
StatusBadge(
  status: 'Em Andamento',
  icon: Icons.hourglass_top_rounded,
  large: true,
)
```

---

## 4️⃣ Empty State

### EmptyStateWidget.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: OwanyTheme.darkSlate,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: OwanyTheme.lightSlate),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: OwanyTheme.primaryButtonStyle(),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Uso**:
```dart
if (items.isEmpty)
  EmptyStateWidget(
    icon: Icons.inbox_rounded,
    title: 'Nenhuma solicitação',
    subtitle: 'Crie uma para começar',
    actionLabel: 'Nova Solicitação',
    onAction: () => navigate(),
  )
```

---

## 5️⃣ Loading Overlay

### LoadingOverlay.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        OwanyTheme.primaryOrange,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

**Uso**:
```dart
LoadingOverlay(
  isLoading: isLoading,
  message: 'Salvando...',
  child: YourContent(),
)
```

---

## 6️⃣ Section Header

### SectionHeader.dart

```dart
import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel = 'Ver todos',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: OwanyTheme.lightSlate,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: OwanyTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

**Uso**:
```dart
SectionHeader(
  title: 'Solicitações Recentes',
  subtitle: '5 solicitações',
  actionLabel: 'Ver todas',
  onAction: () => navigate('/list'),
)
```

---

## 📋 Próximos Passos

### 1. Criar Estrutura de Arquivos

```bash
mkdir -p lib/widgets/{buttons,cards,dialogs,loading,empty_states,badges,common}
```

### 2. Copiar Widgets

Copie cada widget acima para seu respectivo arquivo:
- `lib/widgets/buttons/primary_button.dart`
- `lib/widgets/buttons/secondary_button.dart`
- `lib/widgets/cards/status_card.dart`
- `lib/widgets/cards/section_card.dart`
- `lib/widgets/badges/status_badge.dart`
- `lib/widgets/empty_states/empty_state_widget.dart`
- `lib/widgets/loading/loading_overlay.dart`
- `lib/widgets/common/section_header.dart`

### 3. Criar Index

Crie `lib/widgets/index.dart`:
```dart
export 'buttons/primary_button.dart';
export 'buttons/secondary_button.dart';
export 'cards/status_card.dart';
export 'cards/section_card.dart';
export 'badges/status_badge.dart';
export 'empty_states/empty_state_widget.dart';
export 'loading/loading_overlay.dart';
export 'common/section_header.dart';
```

### 4. Usar em Screens

```dart
import 'package:owany_app/widgets/index.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: false,
        child: CustomScrollView(
          slivers: [
            // ...
            SliverList(
              delegate: SliverChildListDelegate([
                PrimaryButton(label: 'Salvar', onPressed: () {}),
                StatusCard(...),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

**Status**: ✅ 100% Pronto para Integração  
**Last Updated**: 21 January 2026  
**Version**: 1.0

