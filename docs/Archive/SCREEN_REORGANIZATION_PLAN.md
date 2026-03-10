# 🎯 Plano de Reorganização de Screens - Owany App

**Data**: 21 de Janeiro de 2026  
**Objetivo**: Organizar caos de 24 screens em estrutura clara + melhorar UX com OwanyTheme

---

## 📂 Estrutura Proposta

```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── forgot_password_screen.dart
│   
├── core/
│   ├── dashboard_screen.dart
│   ├── maintenance_list_screen.dart
│   ├── maintenance_detail_screen.dart
│   ├── maintenance_request_screen.dart
│   └── notifications_screen.dart
│
├── apartments/
│   ├── apartments_screen.dart
│   ├── apartment_detail_screen.dart
│   ├── create_apartment_screen.dart
│   └── manage_apartment_items_screen.dart
│
├── users/
│   ├── users_screen.dart
│   ├── user_detail_screen.dart
│   ├── add_user_screen.dart
│   ├── edit_user_screen.dart
│   └── manage_residents_screen.dart
│
└── utility/
    ├── profile_screen.dart
    ├── settings_screen.dart
    ├── reports_screen.dart
    ├── report_detail_screen.dart
    └── morador_detail_screen.dart
```

---

## ✅ Ações Necessárias

### FASE 1: Criar Diretórios (0 min)
```bash
# Criar subdirs sem mover arquivos ainda
New-Item -ItemType Directory "lib/screens/auth" -Force
New-Item -ItemType Directory "lib/screens/core" -Force
New-Item -ItemType Directory "lib/screens/apartments" -Force
New-Item -ItemType Directory "lib/screens/users" -Force
New-Item -ItemType Directory "lib/screens/utility" -Force
```

### FASE 2: Reorganizar Arquivos
**AUTH (4 files)**
- ✅ `login_screen.dart` → `auth/login_screen.dart`
- ✅ `register_screen.dart` → `auth/register_screen.dart`
- ✅ `forgot_password_screen.dart` → `auth/forgot_password_screen.dart`
- ❌ `forgot_password_screen_new.dart` → DELETE (consolidar em forgot_password_screen.dart)

**CORE (5 files)**
- ✅ `dashboard_screen.dart` → `core/dashboard_screen.dart`
- ✅ `maintenance_list_screen.dart` → `core/maintenance_list_screen.dart`
- ✅ `maintenance_detail_screen.dart` → `core/maintenance_detail_screen.dart`
- ✅ `maintenance_request_screen.dart` → `core/maintenance_request_screen.dart`
- ✅ `notifications_screen.dart` → `core/notifications_screen.dart`

**APARTMENTS (4 files)**
- ✅ `apartments_screen.dart` → `apartments/apartments_screen.dart`
- ✅ `apartment_detail_screen.dart` → `apartments/apartment_detail_screen.dart`
- ✅ `create_apartment_screen.dart` → `apartments/create_apartment_screen.dart`
- ✅ `manage_apartment_items_screen.dart` → `apartments/manage_apartment_items_screen.dart`

**USERS (5 files)**
- ✅ `users_screen.dart` → `users/users_screen.dart`
- ✅ `user_detail_screen.dart` → `users/user_detail_screen.dart`
- ✅ `add_user_screen.dart` → `users/add_user_screen.dart`
- ✅ `edit_user_screen.dart` → `users/edit_user_screen.dart`
- ✅ `manage_residents_screen.dart` → `users/manage_residents_screen.dart`

**UTILITY (5 files)**
- ✅ `profile_screen.dart` → `utility/profile_screen.dart`
- ✅ `settings_screen.dart` → `utility/settings_screen.dart`
- ✅ `reports_screen.dart` → `utility/reports_screen.dart`
- ✅ `report_detail_screen.dart` → `utility/report_detail_screen.dart`
- ✅ `morador_detail_screen.dart` → `utility/morador_detail_screen.dart`

### FASE 3: Atualizar Imports

**main.dart** será atualizado para:
```dart
// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Core screens
import 'screens/core/dashboard_screen.dart';
import 'screens/core/maintenance_list_screen.dart';
import 'screens/core/maintenance_detail_screen.dart';
import 'screens/core/maintenance_request_screen.dart';
import 'screens/core/notifications_screen.dart';

// Apartment screens
import 'screens/apartments/apartments_screen.dart';
import 'screens/apartments/apartment_detail_screen.dart';
import 'screens/apartments/create_apartment_screen.dart';
import 'screens/apartments/manage_apartment_items_screen.dart';

// User screens
import 'screens/users/users_screen.dart';
import 'screens/users/user_detail_screen.dart';
import 'screens/users/add_user_screen.dart';
import 'screens/users/edit_user_screen.dart';
import 'screens/users/manage_residents_screen.dart';

// Utility screens
import 'screens/utility/profile_screen.dart';
import 'screens/utility/settings_screen.dart';
import 'screens/utility/reports_screen.dart';
import 'screens/utility/report_detail_screen.dart';
import 'screens/utility/morador_detail_screen.dart';
```

### FASE 4: Consolidar Duplicados
- Mesclar `forgot_password_screen.dart` + `forgot_password_screen_new.dart`
- Usar variante mais completa
- Delete arquivo duplicado

### FASE 5: Criar Widgets Reutilizáveis

**Novos widgets em `lib/widgets/`:**

1. **custom_card.dart** - Card com OwanyTheme
   ```dart
   class CustomCard extends StatelessWidget {
     final Widget child;
     final EdgeInsets padding;
     final VoidCallback? onTap;
     // Usa OwanyTheme.cardDecoration()
   }
   ```

2. **status_badge.dart** - Badge com cores semânticas
   ```dart
   class StatusBadge extends StatelessWidget {
     final StatusSolicitacao status;
     // Exibe cor + texto português
   }
   ```

3. **empty_state.dart** - Estado vazio genérico
   ```dart
   class EmptyState extends StatelessWidget {
     final IconData icon;
     final String title;
     final String message;
     final Widget? action;
   }
   ```

4. **loading_shimmer.dart** - Shimmer para loading
   ```dart
   class LoadingShimmer extends StatelessWidget {
     final double height;
     final int itemCount;
   }
   ```

5. **common_app_bar.dart** - AppBar padronizado
   ```dart
   class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
     final String title;
     final List<Widget>? actions;
     final bool showBackButton;
     // Usa OwanyTheme.primaryBrown
   }
   ```

### FASE 6: Melhorias de UX/UI

Cada screen receberá:
- ✅ AppBar padronizado com `CommonAppBar`
- ✅ Espaçamento consistente (8, 16, 24px)
- ✅ Cores do `OwanyTheme` (remover Material defaults)
- ✅ Sombras em cards via `cardDecoration()`
- ✅ Loading states com `LoadingShimmer`
- ✅ Empty states com `EmptyState`
- ✅ Status badges com `StatusBadge`
- ✅ Botões com `primaryButtonStyle()`

**Exemplo de antes/depois:**

❌ **ANTES** (sem padrão):
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Solicitações'),
  ),
  body: ListView(
    children: [...],
  ),
)
```

✅ **DEPOIS** (com OwanyTheme):
```dart
Scaffold(
  appBar: CommonAppBar(
    title: 'Solicitações',
    actions: [IconButton(...)],
  ),
  body: Consumer<SolicitacoesProvider>(
    builder: (context, provider, _) {
      if (provider.isLoading) return LoadingShimmer(itemCount: 5);
      if (provider.solicitacoes.isEmpty) 
        return EmptyState(
          icon: Icons.request_quote,
          title: 'Nenhuma solicitação',
          message: 'Crie uma nova para começar',
          action: ElevatedButton(...),
        );
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemBuilder: (_, i) => CustomCard(
          child: ListTile(
            title: Text(provider.solicitacoes[i].titulo),
            trailing: StatusBadge(status: provider.solicitacoes[i].status),
          ),
        ),
      );
    },
  ),
)
```

---

## 📊 Impacto

| Métrica | Antes | Depois |
|---------|-------|--------|
| Screens em raiz | 23 | 0 |
| Screens organizados | 0 | 23 |
| Imports em main.dart | 23 linhas | 23 linhas (organized) |
| Código duplicado | ~5% | ~0% |
| Consistência de cores | ⚠️ Parcial | ✅ Total |
| Loading states | ❌ Inconsistente | ✅ Padrão |
| Empty states | ❌ Faltam | ✅ Presentes |

---

## 🔧 Próximos Passos

1. ✅ Copilot aprova este plano?
2. ⏳ Confirma para executar?
3. 🚀 Execução automática:
   - Criar diretórios
   - Reorganizar arquivos (via `mv` commands)
   - Atualizar imports
   - Consolidar duplicados
   - Criar novos widgets
   - Aplicar melhorias em cada screen

---

**Status**: 🔴 Aguardando confirmação  
**Tempo Estimado**: ~2-3 horas (automático)  
**Risco**: ⚠️ Médio (muitos imports para atualizar, mas pode ser automatizado)

