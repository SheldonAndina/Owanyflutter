# Plano de Melhoria de Tema - Owany App

## Estratégia de Refactor de Cores e Estilos

### Padrões de Substituição:

#### 1. Cores Gerais
- `Colors.grey[500]` → `OwanyTheme.textMuted`
- `Colors.grey[400]` → `OwanyTheme.textMuted.withOpacity(0.7)`
- `Colors.grey[600]` → `OwanyTheme.textSecondary`
- `Colors.grey[700]` → `OwanyTheme.primaryBrown`
- `Colors.grey[300]` → `OwanyTheme.borderLight`
- `Colors.grey` (genérico) → `OwanyTheme.borderLight`

#### 2. Cores Específicas
- `Colors.blue` → `OwanyTheme.info` (ou remover)
- `Colors.indigo` → `OwanyTheme.info` (ou remover)
- `Colors.green` → `OwanyTheme.success`
- `Colors.red` → `OwanyTheme.error`
- `Colors.white` → `OwanyTheme.white` (já correto)

#### 3. TextStyle
- Remover `TextStyle(fontSize: 14, fontWeight: FontWeight.w400)` → usar `OwanyTheme.bodyMedium`
- Remover `TextStyle(fontSize: 12)` → usar `OwanyTheme.labelMedium`
- Remover `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` → usar `OwanyTheme.headlineSmall`

#### 4. Decorations
- Remover `BoxDecoration(border: Border.all(color: Colors.grey))` → usar `OwanyTheme.outlinedCardDecoration()`
- Remover `Container(decoration: BoxDecoration(color: Colors.grey[100]))` → usar `Container(decoration: OwanyTheme.flatCardDecoration())`

#### 5. AppBar
- Sempre usar `backgroundColor: OwanyTheme.white`
- Usar `titleTextStyle` do appBarTheme

#### 6. Button Styles
- `ElevatedButton.styleFrom(backgroundColor: Colors.orange)` → usar `style: OwanyTheme.primaryButtonStyle()`
- `OutlinedButton.styleFrom()` → usar `style: OwanyTheme.secondaryButtonStyle()`

### Screens a Melhorar (Ordem de Prioridade):

1. **dashboard_screen.dart** - ALTA (muitos Colors hardcoded)
2. **settings_screen.dart** - ALTA
3. **profile_screen.dart** - ALTA
4. **change_password_screen.dart** - ALTA
5. **maintenance_list_screen.dart** - MÉDIA
6. **maintenance_detail_screen.dart** - MÉDIA
7. **login_screen.dart** - MÉDIA
8. **register_screen.dart** - MÉDIA
9. **forgot_password_screen.dart** - MÉDIA
10. Restantes screens - BAIXA

## Implementação:

Cada screen será atualizado com:
- ✅ Colors do OwanyTheme
- ✅ TextStyles do OwanyTheme
- ✅ InputDecoration do OwanyTheme (quando aplicável)
- ✅ ButtonStyles do OwanyTheme (quando aplicável)
- ✅ CardDecoration do OwanyTheme (quando aplicável)

## Status:
- [ ] dashboard_screen.dart
- [ ] settings_screen.dart
- [ ] profile_screen.dart
- [ ] change_password_screen.dart
- [ ] maintenance_list_screen.dart
- [ ] maintenance_detail_screen.dart
- [ ] login_screen.dart
- [ ] register_screen.dart
- [ ] forgot_password_screen.dart
- [ ] Restantes screens
