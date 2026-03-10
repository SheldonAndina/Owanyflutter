---

## 📦 Gestão de Ativos (Asset Management)

- **Endpoints disponíveis:**
  - `GET /api/itemapartamento/patrimonio/{codigo}`: Busca relatório completo do ativo pelo código de patrimônio (ideal para scan de QR code).
  - Cadastrar, consultar, transferir e atualizar ativos via endpoints dedicados.
  - Gerar e consultar QR code individual ou em lote para ativos.
  - Consultar histórico completo do ativo: movimentações, manutenções, idade, localização.

- **Na screen de gestão de ativos:**
  - Permite cadastro, consulta, transferência e atualização de ativos.
  - Busca rápida por código de patrimônio (útil para leitura de QR code).
  - Exibe relatório detalhado do ativo, incluindo histórico e movimentações.

- **Padrão de uso:**
  - Utilize `ApiService().request<T>()` para consumir todos os endpoints de ativos.
  - Exemplo de busca por código de patrimônio:
    ```dart
    final ativo = await ApiService().request<Ativo>(
      'itemapartamento/patrimonio/$codigo',
      method: 'GET',
      fromJson: (json) => Ativo.fromJson(json),
    );
    ```
  - Exiba sempre informações completas do ativo, incluindo QR code e histórico, na tela de gestão.

---
extension UsuarioTipoExtension on UsuarioTipo {
  String toPortuguese() { ... }
  static UsuarioTipo fromString(String value) { ... }
}

enum StatusSolicitacao { Pendente, EmAndamento, Concluido }
// Extensions for .toPortuguese() and fromString()

enum EstadoApartamento { Disponivel, Ocupado, Manutencao }
// Same extension pattern
  Usuario? _usuarioAtual;
  
  Future<void> login(String identificador, String senha) async {
    try {
      final usuario = await ApiService().request<Usuario>(
        'auth/login',
        method: 'POST',
        body: { 'identificador': identificador, 'senha': senha },
        fromJson: (json) => Usuario.fromJson(json),
      );
      _usuarioAtual = usuario;
      notifyListeners(); // ← CRITICAL: Screen rebuilds after this
    } on Exception catch (e) {
      throw 'Login falhou: ${e.toString()}';
    }
  }
}

// Usage in screen:
  @override
  State<MyScreen> createState() => _MyScreenState();

# Owany App – AI Coding Agent Guide

> **Status**: 🚀 Active Development | **Last Updated**: 14 February 2026

Owany is a professional Flutter property management app for apartment buildings. This guide is the **source of truth** for AI agents and developers working in this codebase.

---

## 🏗️ Architecture & Data Flow

- **Strict Provider Pattern**: All state is managed via `ChangeNotifier` providers in `lib/providers/`. UI never uses `setState` for business logic.
- **ApiService Gateway**: All HTTP requests go through `lib/services/api_service.dart` using the generic `request<T>()` method. This injects JWT tokens, unwraps backend responses, and maps `dados` to models.
- **Backend Response Format**: Always `{ sucesso, mensagem, dados, erros }`. ApiService extracts `dados` and throws on error.
- **Directory Structure**: See `lib/` for:
  - `theme/owany_theme.dart`: All colors/styles (NO Material defaults)
  - `models/`: Data models and enums (Portuguese naming)
  - `providers/`: One provider per feature (auth, apartments, requests)
  - `screens/`: 24+ feature screens (no `pages/`)
  - `widgets/`: Reusable UI components
  - `dto/`: API DTOs
  - `constants/`, `utils/`, `i18n/`: App constants, helpers, and internationalization

---

## 🎨 UI & Theme Rules

- **NO Material Colors**: Use only `OwanyTheme.*` (see `lib/theme/owany_theme.dart`).
- **Surfaces**: Use `OwanyTheme.background` and `OwanyTheme.surface` (not pure white/black).
- **Buttons/Inputs**: Use `primaryButtonStyle()` and `inputDecoration()` helpers.
- **All user-facing strings**: Must be in PT-BR, variable names in camelCase Portuguese.

---

## 🔄 Provider & API Patterns

- **Provider Lifecycle**: Providers are created at the app level, never inside widgets.
- **State Updates**: Always call `notifyListeners()` after mutating provider state.
- **API Calls**: Use `ApiService().request<T>()` with `fromJson` for all backend access. Never add `Authorization` headers manually.
- **Error Handling**: Catch exceptions in providers, show user-friendly PT-BR messages via `OwanyTheme.snackBar()`.

**Example:**
```dart
final usuario = await ApiService().request<Usuario>(
  'auth/login',
  method: 'POST',
  body: { 'identificador': user, 'senha': pass },
  fromJson: (json) => Usuario.fromJson(json),
);
```

---

## 🛠️ Build, Run & Analyze

- **Run (Windows):** `flutter run -d windows`
- **Build APK:** `flutter build apk --release`
- **Analyze:** `flutter analyze` (see also `analyze_results.txt`)
- **Check Theme Usage:** `grep -r "Colors\." lib/screens/` (should be zero)

---

## ⚠️ Project-Specific Conventions

- **No Riverpod/GetX/BLoC**: Use only Provider for state.
- **No setState for business logic**: Use providers.
- **No dead code**: Remove unused screens/pages. `pages/` is deprecated.
- **Null safety**: Always handle nullable API responses.
- **Role-based UI**: Check `usuario.tipo` before showing admin-only features.
- **Portuguese everywhere**: All user-facing text and variable names.

---

## 🐛 Common Issues & Fixes

- 401 Unauthorized: Token expired → logout and redirect to login.
- Colors off: Use only `OwanyTheme.*`.
- Screen not updating: Missing `notifyListeners()` in provider.
- Network timeout: Adjust `_timeout` in ApiService.

---

## 📋 Key Files & Examples

- `lib/theme/owany_theme.dart`: Color system, button/input styles
- `lib/services/api_service.dart`: All HTTP logic, token management
- `lib/providers/auth_provider.dart`: Login/logout, user state
- `lib/models/enums.dart`: Enum extensions for PT-BR
- `lib/screens/`: All feature screens

---

## 🧭 Quickstart for AI Agents

1. Use only `OwanyTheme` for all UI colors/styles.
2. All API calls via `ApiService().request<T>()`.
3. All state via Providers, never setState.
4. All user-facing text in PT-BR.
5. Follow directory structure and patterns above.

---

**Update this file if you discover new patterns or project rules.**
