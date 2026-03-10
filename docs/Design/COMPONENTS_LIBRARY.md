# 🧩 Componentes Reutilizáveis – OWANY
## Biblioteca de Widgets Prontos para Uso

**Status**: ✅ Pronto para integração  
**Local**: `lib/widgets/`  
**Framework**: Flutter + Material 3

---

## 📋 Índice de Componentes

1. [Botões](#botões)
2. [Cards](#cards)
3. [Diálogos](#diálogos)
4. [Estados Vazios](#estados-vazios)
5. [Loading](#loading)
6. [Badges](#badges)
7. [Inputs Customizados](#inputs-customizados)
8. [Seções](#seções)

---

# 🔘 Botões

## PrimaryButton

```dart
// lib/widgets/buttons.dart

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OwanyTheme.primaryButtonStyle(),
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
        label: Text(isLoading ? 'Salvando...' : label),
      ),
    );
  }
}

// Uso:
PrimaryButton(
  label: 'Entrar',
  onPressed: () => login(),
)

PrimaryButton(
  label: 'Criar Solicitação',
  icon: Icons.add_rounded,
  isFullWidth: false,
  onPressed: () => navigateToCreate(),
)
```

## SecondaryButton

```dart
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: OwanyTheme.darkSlate,
        side: const BorderSide(color: OwanyTheme.lightSlate),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Uso:
SecondaryButton(
  label: 'Cancelar',
  onPressed: () => Navigator.pop(context),
)
```

## TertiaryButton (Text Button)

```dart
class TertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const TertiaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: OwanyTheme.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Uso:
TertiaryButton(
  label: 'Esqueci minha senha',
  onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
)
```

---

# 🎨 Cards

## InfoCard (Informação Genérica)

```dart
class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    this.color = OwanyTheme.primaryOrange,
    this.onTap,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: OwanyTheme.lightSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: OwanyTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: OwanyTheme.lightSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Uso:
InfoCard(
  title: 'Total',
  value: '42',
  subtitle: 'Solicitações',
  icon: Icons.build_rounded,
  color: OwanyTheme.primaryOrange,
)
```

## StatusCard (Com Badge Colorida)

```dart
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

  Color _getStatusColor() {
    if (status.contains('Pendente')) return Colors.amber;
    if (status.contains('Andamento')) return Colors.indigo;
    if (status.contains('Concluído')) return Colors.green;
    return Colors.grey;
  }
}

// Uso:
StatusCard(
  title: 'Vazamento na cozinha',
  location: 'Apt 502 | Bloco A',
  status: 'Pendente',
  date: DateTime.now(),
  onTap: () => Navigator.pushNamed(context, '/maintenance_detail'),
)
```

## SectionCard (Seção de Informações)

```dart
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onTap;

  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.onTap,
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
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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

// Uso:
SectionCard(
  title: 'Informações Gerais',
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Criado:'),
        Text('21/01/2026'),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Prazo:'),
        Text('25/01/2026'),
      ],
    ),
  ],
)
```

---

# 📬 Diálogos

## ConfirmDialog

```dart
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    required this.onConfirm,
    this.onCancel,
    this.confirmColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? OwanyTheme.primaryOrange,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

// Uso:
showDialog(
  context: context,
  builder: (context) => ConfirmDialog(
    title: 'Deletar Solicitação',
    message: 'Tem certeza que deseja deletar esta solicitação?',
    confirmLabel: 'Deletar',
    confirmColor: OwanyTheme.error,
    onConfirm: () => deleteSolicitacao(),
  ),
)
```

---

# 📭 Estados Vazios

## EmptyState

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
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
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction!,
              isFullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

// Uso:
if (solicitacoes.isEmpty)
  EmptyState(
    icon: Icons.inbox_rounded,
    title: 'Nenhuma solicitação',
    subtitle: 'Crie uma nova para gerenciar manutenções',
    actionLabel: 'Criar Solicitação',
    onAction: () => Navigator.pushNamed(context, '/solicitacoes-nova'),
  )
```

---

# ⏳ Loading

## ShimmerCard

```dart
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    Key? key,
    this.height = 100,
    this.width,
    this.borderRadius = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: OwanyTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      // Adicionar shimmer animation com pacote shimmer 2.0.0+
    );
  }
}

// Uso (com pacote shimmer):
Shimmer.fromColors(
  baseColor: OwanyTheme.surface,
  highlightColor: Colors.grey[100]!,
  child: ShimmerCard(),
)
```

## LoadingOverlay

```dart
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

// Uso:
LoadingOverlay(
  isLoading: isLoading,
  message: 'Salvando solicitação...',
  child: YourContent(),
)
```

---

# 🏷️ Badges

## StatusBadge

```dart
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.status,
    this.color,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: statusColor),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (status.contains('Pendente')) return Colors.amber;
    if (status.contains('Andamento')) return Colors.indigo;
    if (status.contains('Concluído')) return Colors.green;
    if (status.contains('Interno')) return Colors.red;
    return Colors.grey;
  }
}

// Uso:
StatusBadge(
  status: 'Pendente',
  icon: Icons.schedule_rounded,
)
```

---

# ⌨️ Inputs Customizados

## CustomTextField

```dart
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscure;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.icon,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscure = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: OwanyTheme.inputDecoration(
        label: label,
        icon: icon,
      ).copyWith(
        hintText: hint,
      ),
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      obscureText: obscure,
      validator: validator,
    );
  }
}

// Uso:
CustomTextField(
  label: 'E-mail',
  hint: 'seu.email@example.com',
  icon: Icons.email_rounded,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
)
```

---

# 📑 Seções

## SectionHeader

```dart
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
          Column(
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
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: OwanyTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Uso:
SectionHeader(
  title: 'Solicitações Recentes',
  subtitle: '5 solicitações',
  actionLabel: 'Ver todas',
  onAction: () => Navigator.pushNamed(context, '/maintenance_list'),
)
```

---

## Summary

**Componentes Criados**:
- ✅ 3 tipos de botões (Primary, Secondary, Tertiary)
- ✅ 3 tipos de cards (Info, Status, Section)
- ✅ Diálogos (Confirm)
- ✅ Estados vazios (EmptyState)
- ✅ Loading (Shimmer, Overlay)
- ✅ Badges (Status)
- ✅ Inputs (CustomTextField)
- ✅ Seções (SectionHeader)

**Próximos Passos**:
1. Copiar estes componentes para `lib/widgets/`
2. Importar em screens que precisam
3. Testar em diferentes tamanhos de tela
4. Adicionar animações conforme necessário

