# Cross-Platform Responsiveness Audit Report

**App**: Owany Flutter Property Management  
**Platforms**: iOS, Android, Windows, Web  
**Date**: 2026-02-14  
**Files Audited**: 55+ screens, 23 widgets, main.dart, theme  

---

## GLOBAL / ARCHITECTURAL ISSUES

### 1. Portrait-Only Orientation Lock
- **File**: `lib/main.dart` · Line 90–93
- **Issue**: `SystemChrome.setPreferredOrientations([portraitUp, portraitDown])` locks all platforms to portrait
- **Impact**: On **Windows** and **Web**, the app cannot be used in landscape/wide windows. Users resizing the browser or maximizing a desktop window get a portrait-only layout.
- **Severity**: **HIGH**
- **Fix**: Guard with `kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS` to skip orientation lock on desktop/web.

### 2. No Adaptive Navigation (Drawer-Only on All Platforms)
- **File**: `lib/main.dart` · Lines 700–900 (MainScaffold)
- **Issue**: `MainScaffold` uses a hamburger `Drawer` + `BottomNavigationBar` on all platforms, including desktop/web. Desktop UIs conventionally use a permanent `NavigationRail` or sidebar.
- **Impact**: Poor desktop/web UX; users must open a drawer for navigation on a 1920px-wide screen.
- **Severity**: **HIGH**
- **Fix**: Use `LayoutBuilder` in `MainScaffold` — show `NavigationRail`/permanent sidebar when `width >= 900`, `BottomNavigationBar` + Drawer when mobile.

### 3. No Max-Width Constraint on Content
- **File**: Multiple (see per-file details below)
- **Issue**: Nearly all screens use `SingleChildScrollView` with `padding: EdgeInsets.all(16–24)` without a `ConstrainedBox(maxWidth: ~800)` or `Center` wrapper. On a 1920px-wide desktop, form fields and cards stretch to the full width.
- **Impact**: Unreadable forms and cards on wide screens.
- **Severity**: **HIGH**
- **Fix**: Wrap body content in `Center > ConstrainedBox(maxWidth: 900)` on screens that are form-based or detail views.

### 4. `StandardGlassAppBar` Fixed Height 120px
- **File**: `lib/widgets/standard_glass_app_bar.dart` · Line 39
- **Issue**: `preferredSize => const Size.fromHeight(120)` — this tall AppBar is fixed regardless of screen size. On small phones (320px width, 568px height like iPhone SE) it consumes 21% of vertical space.
- **Impact**: Reduced content area on small devices; excessive header on desktop.
- **Severity**: **MEDIUM**
- **Fix**: Make height responsive (e.g., `kToolbarHeight + MediaQuery.of(context).padding.top + 40` or smaller variant for compact screens).

### 5. `BackdropFilter` Performance on Web
- **File**: `lib/widgets/standard_glass_app_bar.dart`, `lib/screens/apartments/apartments_screen.dart`, multiple agendamento screens
- **Issue**: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))` is used extensively. On Flutter Web (HTML renderer), this causes significant performance degradation and potential rendering artifacts.
- **Impact**: Laggy scrolling and rendering on web platform.
- **Severity**: **MEDIUM**
- **Fix**: Conditionally disable blur on web: `kIsWeb ? ImageFilter.blur() : ImageFilter.blur(sigmaX: 10, sigmaY: 10)` or use simple opacity overlay.

---

## PER-FILE FINDINGS

---

### `lib/screens/auth/login_screen.dart` (357 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 119–121 | Missing max-width constraint | `SafeArea > SingleChildScrollView > Padding(24)` — content stretches full width on desktop. Login forms should be max ~400px wide. | **HIGH** |
| 131–132 | Hardcoded logo size | `Container(width: 80, height: 80)` — fixed logo size doesn't scale for tablets/desktop. | **LOW** |
| 140 | Hardcoded font size | `fontSize: 40` for title. On very small screens, may overflow or look oversized. | **LOW** |

---

### `lib/screens/auth/forgot_password_screen.dart` (556 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~80 | Missing max-width constraint | `SingleChildScrollView > Padding(24)` — no `ConstrainedBox`. Multi-step form stretches too wide on desktop. | **HIGH** |
| ~115 | Hardcoded step circles | Step indicator uses 3 `Expanded` children with `Container(width: 40, height: 40)`. Step circles work but connecting lines don't adapt. | **LOW** |

---

### `lib/screens/auth/register_screen.dart` (326 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 75–78 | Missing max-width constraint | `SafeArea > SingleChildScrollView > Padding(24)`. Registration form stretches on desktop. | **HIGH** |

---

### `lib/screens/core/dashboard_screen_moderno.dart` (621 lines) — ✅ GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 251, 319, 420 | ✅ Uses `LayoutBuilder` | `_buildMetrics`, `_buildStatusSection`, `_buildAcoesRapidas` all use `LayoutBuilder` with breakpoints (560, 520). | ✅ OK |
| ~150 | Fixed padding | `padding: const EdgeInsets.all(24)` — minor; content inside uses LayoutBuilder so acceptable. | **LOW** |

---

### `lib/screens/core/maintenance_list_screen.dart` (471 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~210 | Hardcoded grid | `GridView.count(crossAxisCount: 3)` for status filter chips — not adaptive. On very small screens (320px), 3 columns could be too tight. On desktop, wastes space. | **MEDIUM** |
| N/A | Missing LayoutBuilder | Screen has no responsive layout adaptation at all. | **MEDIUM** |

---

### `lib/screens/core/maintenance_detail_screen.dart` (1317 lines) — ✅ MOSTLY GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 250, 451, 600, 645, 704, 968, 1071, 1137 | ✅ Uses `MediaQuery.of(context).size.width < 600` isMobile checks throughout | Good responsive behavior — different layouts for mobile vs. desktop. | ✅ OK |
| 1036 | Hardcoded width calculation | `width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2` — manual math assumes fixed padding. Fragile on large screens. | **LOW** |
| 704–705 | Keyboard handling | Uses `MediaQuery.of(context).viewInsets.bottom` for comment bar — good keyboard overlap handling. | ✅ OK |

---

### `lib/screens/core/maintenance_request_screen.dart` (860 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/MediaQuery | Form-heavy screen with no responsive layout. `SingleChildScrollView > padding: 16`. | **HIGH** |
| ~350 | Horizontal chip scroll | Problem type chips use horizontal `SingleChildScrollView` — works on all sizes. | ✅ OK |

---

### `lib/screens/core/notifications_screen.dart` (553 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing max-width constraint | `ListView.separated` stretches to full width on desktop. Notification cards should be max ~700px. | **MEDIUM** |
| N/A | No SafeArea | No `SafeArea` wrapper — relies on `MainScaffold` parent which has it, so minor. | **LOW** |

---

### `lib/screens/core/sms_massa_screen.dart` (733 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | `TabBar + TabBarView` with no responsive adaptation. Form stretches on wide screens. | **MEDIUM** |
| N/A | Missing max-width constraint | SMS composition stretches full width on desktop. | **MEDIUM** |

---

### `lib/screens/apartments/apartments_screen.dart` (2137 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~175 | `showModalBottomSheet` no max-width | Filter modal bottom sheet will stretch full width on desktop browsers. Should use `constraints: BoxConstraints(maxWidth: 500)`. | **MEDIUM** |
| ~412 | ✅ Good grid: `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200)` | Auto-adapts columns based on width. | ✅ OK |
| 512 | SafeArea in glassmorphism AppBar | `SafeArea(bottom: false)` properly used. | ✅ OK |
| N/A | `HapticFeedback` calls | `HapticFeedback.selectionClick()`, `lightImpact()`, `mediumImpact()` — no-op on web, but no error. | **LOW** |

---

### `lib/screens/apartments/apartment_detail_screen.dart` (2054 lines) — ✅ PARTIALLY GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~30 | ✅ Uses `isTablet = screenWidth >= 600` | Adapts layout for tablet. | ✅ OK |
| 1453 | `showModalBottomSheet` no constraints | Modal bottom sheets will stretch full width on desktop. | **MEDIUM** |
| 1684, 1755, 1808, 1895 | Multiple `showDialog` calls | Dialogs use default sizing — generally OK on all platforms, but no explicit `maxWidth` constraints. | **LOW** |

---

### `lib/screens/apartments/create_apartment_screen.dart` (424 lines) — ✅ GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~38 | ✅ Uses `LayoutBuilder` with `isWide = constraints.maxWidth >= 900` | Properly adapts form layout for wide screens. | ✅ OK |
| ~38 | ✅ Has `SafeArea` | Proper safe area handling. | ✅ OK |

---

### `lib/screens/apartments/manage_apartment_items_screen.dart` (1099 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~104 | Dialog with `maxWidth: 500` | ✅ Good — constrains dialog width. | ✅ OK |
| 1021 | `showModalBottomSheet` might not have max-width | Bottom sheet could stretch on desktop. | **MEDIUM** |

---

### `lib/screens/apartments/historico_ocupacao_detalhado_screen.dart` (697 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 1 | Has `kIsWeb` import comment | But actual usage not found in the screen. | **LOW** |
| N/A | Missing LayoutBuilder | Chart-heavy screen with no responsive layout adaptation. | **MEDIUM** |

---

### `lib/screens/users/users_screen.dart` (442 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~50 | `SliverAppBar(expandedHeight: 140)` | Fixed expanded height — tall on small screens, though this is a common Material pattern. | **LOW** |
| 71 | ✅ Has `SafeArea` | In flexible space. | ✅ OK |
| N/A | Missing LayoutBuilder | User list has no responsive grid — `ListView` always 1-column even on desktop. | **MEDIUM** |

---

### `lib/screens/users/user_detail_screen.dart` (524 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | Detail info stretches full width on desktop. | **MEDIUM** |
| N/A | No SafeArea | Relies on parent scaffold. | **LOW** |

---

### `lib/screens/users/add_user_screen.dart` (547 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | `SingleChildScrollView > padding: 20`. Form stretches on wide screens. | **HIGH** |
| N/A | Missing max-width constraint | Input fields span 1920px on desktop. | **HIGH** |

---

### `lib/screens/users/edit_user_screen.dart` (640 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | Same pattern as `add_user_screen` — no adaptive layout. | **HIGH** |
| N/A | Missing max-width constraint | Form stretches on wide screens. | **HIGH** |

---

### `lib/screens/users/create_morador_screen.dart` (702 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | Animated form with dropdowns — no adaptive layout. | **HIGH** |
| N/A | Missing max-width constraint | Fields span full width on desktop. | **HIGH** |

---

### `lib/screens/users/manage_residents_screen.dart` (466 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | List view with search/filter — no responsive grid for desktop. | **MEDIUM** |
| N/A | Horizontal `FilterChip` scroll | Works on all sizes — OK. | ✅ OK |

---

### `lib/screens/users/morador_detail_screen.dart` (535 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | Info rows stretch full width on desktop. | **MEDIUM** |

---

### `lib/screens/users/niveis_acesso_screen.dart` (1159 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~140 | `SliverAppBar(expandedHeight: 140)` | Fixed height — acceptable pattern. | **LOW** |
| 554, 754 | `showModalBottomSheet` no max-width | Bottom sheets stretch on desktop. | **MEDIUM** |
| N/A | Missing LayoutBuilder for tab content | Tab views don't adapt to wide screens. | **MEDIUM** |
| 157 | ✅ Has `SafeArea` | Proper safe area in AppBar. | ✅ OK |

---

### `lib/screens/agendamentos/agendamentos_lista_screen.dart` (573 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | List view with no responsive grid for desktop. | **MEDIUM** |
| ~120 | `SliverToBoxAdapter(child: SizedBox(height: 120))` | Fixed 120px spacer for AppBar offset — fragile if AppBar height changes. | **LOW** |

---

### `lib/screens/agendamentos/agendamento_detalhes_screen.dart` (697 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 88 | Hardcoded background color | `backgroundColor: const Color(0xFFF8F9FA)` — bypasses `OwanyTheme`, breaks dark mode. | **HIGH** |
| 225 | Hardcoded color again | `const Color(0xFFF8F9FA)` used in gradient. | **HIGH** |
| 321, 402 | ✅ Uses `LayoutBuilder` | In info cards and action sections — good. | ✅ OK |
| N/A | Missing max-width | Detail content stretches on desktop. | **MEDIUM** |

---

### `lib/screens/agendamentos/criar_agendamento_screen.dart` (1139 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder | Complex form with date/time/location — no responsive layout. | **HIGH** |
| N/A | Missing max-width constraint | Form stretches on desktop. | **HIGH** |

---

### `lib/screens/agendamentos/criar_agendamento_manutencao_simples_screen.dart` (382 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 147 | ✅ `bottomNavigationBar: SafeArea(...)` | Good — submit button handles bottom insets. | ✅ OK |
| N/A | Missing max-width | Form stretches on desktop. | **MEDIUM** |

---

### `lib/screens/agendamentos/responder_agendamento_screen.dart` (483 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | Content stretches full width on desktop. | **MEDIUM** |
| N/A | `BackdropFilter` glass AppBar | Performance concern on web. | **LOW** |

---

### `lib/screens/agendamentos/avaliar_agendamento_screen.dart` (648 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | Star rating and form stretch on desktop. | **MEDIUM** |
| N/A | `BackdropFilter` glass AppBar | Performance concern on web. | **LOW** |

---

### `lib/screens/agendamentos/editar_agendamento_screen.dart` (264 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `SingleChildScrollView > padding: 16`. Form stretches. | **HIGH** |
| ~155 | Row with date/time | `Row > Expanded` for date + time — works but no adaptation for very narrow screens. | **LOW** |

---

### `lib/screens/maintenance/manutencao_alertas_screen.dart` (559 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~148 | `SingleChildScrollView(scrollDirection: Axis.horizontal)` | Statistics row scrolls horizontally — works but cards could reflow with `Wrap` on wider screens. | **LOW** |
| N/A | Missing LayoutBuilder/max-width | Alert cards stretch full width on desktop. | **MEDIUM** |

---

### `lib/screens/maintenance/manutencao_preventiva_lista_screen.dart` (1038 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 108 | ✅ Has `SafeArea` | Wraps body. | ✅ OK |
| N/A | Missing LayoutBuilder/max-width | Cards stretch full width on desktop. | **MEDIUM** |

---

### `lib/screens/maintenance/manutencao_preventiva_detalhes_screen.dart` (935 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 254, 285, 384, 450, 489 | Hardcoded `Color(0xFF1A1A1A)` | Multiple instances — bypasses `OwanyTheme.textPrimary(context)`, breaks dark mode. | **HIGH** |
| 263 | Hardcoded border color | `Border.all(color: const Color(0xFFF0F0F0))` — breaks dark mode. | **MEDIUM** |
| N/A | Missing LayoutBuilder/max-width | Tab views stretch on desktop. | **MEDIUM** |

---

### `lib/screens/maintenance/manutencao_preventiva_form_screen.dart` (442 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `SingleChildScrollView > padding: 16`. Form stretches on desktop. | **HIGH** |

---

### `lib/screens/utility/reports_screen.dart` (1585 lines) — ✅ PARTIALLY GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 64 | ✅ Uses `MediaQuery.of(context).size.width > 900` for `isWide` | Good responsive check. | ✅ OK |
| 1085 | ✅ Adaptive grid | `crossAxisCount: MediaQuery > 900 ? 5 : 3` | ✅ OK |
| ~100 | `SliverAppBar(expandedHeight: 140)` | Fixed height. | **LOW** |
| 112 | ✅ Has `SafeArea` | In AppBar. | ✅ OK |

---

### `lib/screens/utility/profile_screen.dart` (524 lines) — ✅ GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 46 | ✅ Uses `LayoutBuilder` with `isWide = constraints.maxWidth >= 900` | Adapts padding and layout for wide screens. | ✅ OK |
| 23 | ✅ Has `SafeArea` | Wraps body. | ✅ OK |
| ~80 | Uses `Wrap` for info cards | Good — auto-wraps on small screens. | ✅ OK |

---

### `lib/screens/utility/settings_screen.dart` (795 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `SingleChildScrollView > padding: 16`. Settings list stretches on desktop. | **MEDIUM** |
| 506 | `showDialog` | Default sizing — OK. | ✅ OK |

---

### `lib/screens/utility/change_password_screen.dart` (265 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `SingleChildScrollView > padding: 20`. Password form stretches on desktop. | **HIGH** |
| N/A | No outer max-width | TextFormFields span full 1920px on desktop — usability issue. | **HIGH** |

---

### `lib/screens/utility/manage_request_types_screen.dart` (134 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~73 | `AppBar(backgroundColor: OwanyTheme.primaryBrown)` | Uses non-standard AppBar (not glass), minor inconsistency. | **LOW** |
| N/A | Missing max-width | Simple list stretches on desktop. | **MEDIUM** |

---

### `lib/screens/utility/qr_code_batch_screen.dart` (729 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~185 | `AppBar(backgroundColor: OwanyTheme.primaryBrown)` | Non-standard AppBar. | **LOW** |
| N/A | Missing LayoutBuilder/max-width | Options and report stretch on desktop. | **MEDIUM** |

---

### `lib/screens/utility/asset_management_screen.dart` (1491 lines) — SOME GOOD

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 1307, 1335 | ✅ Uses `kIsWeb` checks | Only screen to check web platform for QR scanning. | ✅ OK |
| 137 | ✅ Has `SafeArea` | In SliverAppBar. | ✅ OK |
| ~130 | `SliverAppBar(expandedHeight: 130)` | Fixed height. | **LOW** |
| 417 | `showModalBottomSheet` | No max-width constraint for desktop. | **MEDIUM** |
| N/A | Missing LayoutBuilder for list | Asset list is always 1-column, could be 2-column on desktop. | **MEDIUM** |
| ~150 | `.withOpacity()` (deprecated) | Uses `.withOpacity()` instead of `.withValues(alpha:)`. | **LOW** |

---

### `lib/screens/utility/historico_ocupacao_screen.dart` (107 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing max-width | `SingleChildScrollView > padding: 20`. History cards stretch. | **MEDIUM** |

---

### `lib/screens/utility/historico_itens_screen.dart` (301 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~52 | `RelativeRect.fromLTRB(1000, 80, 16, 0)` for `showMenu` | Hardcoded position — popup menu positioned at x=1000px. On narrow screens, this positioned off-screen. | **HIGH** |
| N/A | Missing max-width | List and search stretch on desktop. | **MEDIUM** |

---

### `lib/screens/utility/qr_scan_screen.dart` (58 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | No `kIsWeb` guard | Uses `MobileScanner` which requires camera. On **web**, `mobile_scanner` has limited support and will crash if camera access is denied without graceful fallback. On **Windows desktop**, camera support varies. | **HIGH** |
| N/A | No platform check | Should check `kIsWeb` and show file upload alternative or text input for QR code value. | **HIGH** |

---

### `lib/screens/gestao_ativos_screen.dart` (272 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `Column > Expanded(ListView)` — asset list stretches on desktop. | **MEDIUM** |
| ~50 | Default Material `AppBar` | No glass/custom AppBar — minor style inconsistency. | **LOW** |

---

### `lib/screens/detalhe_ativo_screen.dart` (705 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 241 | ✅ Has `SafeArea` | Wraps body. | ✅ OK |
| N/A | Missing LayoutBuilder/max-width | Detail content stretches on desktop. | **MEDIUM** |

---

### `lib/screens/editar_ativo_screen.dart` (311 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing LayoutBuilder/max-width | `SingleChildScrollView > padding: 16`. Form stretches. | **HIGH** |
| ~200 | Hardcoded `InputDecoration` | Uses `const InputDecoration(labelText: 'Código Patrimônio', ...)` instead of `OwanyTheme.inputDecoration()`. | **MEDIUM** |
| ~200 | Hardcoded Portuguese strings | Labels like `'Nome *'`, `'Código Patrimônio'` — not using `AppLocalizations`. | **MEDIUM** |

---

### `lib/screens/historico_ativo_screen.dart` (75 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Missing max-width | `ListView.separated` stretches on desktop. | **MEDIUM** |
| N/A | Default `AppBar` | No custom styling. | **LOW** |

---

### `lib/screens/qr_scan_screen.dart` (root level duplicate)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Same as `utility/qr_scan_screen.dart` | Duplicate file — should be consolidated. | **LOW** |

---

## WIDGET-LEVEL FINDINGS

### `lib/widgets/maintenance_card.dart` (656 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 253, 255, 313, 380, 494, 506–512 | 15+ hardcoded `Color(0x...)` values | Colors like `Color(0xFF8B5CF6)`, `Color(0xFF3B82F6)`, `Color(0xFF10B981)` bypass OwanyTheme. Will not adapt to dark mode. | **HIGH** |
| ~130 | `OwanyTheme.textDark` and `OwanyTheme.textMuted` (non-adaptive) | Uses static color constants instead of adaptive `OwanyTheme.textPrimary(context)`. Breaks dark mode. | **MEDIUM** |

---

### `lib/widgets/apartment_card.dart` (639 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~99, 106 | Hardcoded `Color(0xFF1A1A1A)` and `Color(0xFF6B7280)` | Used for text colors in compact card — bypasses theme, breaks dark mode. | **HIGH** |
| ~230 | Same `Color(0xFF1A1A1A)` | In full card's title. | **HIGH** |

---

### `lib/widgets/vincular_morador_dialog.dart` (561 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| ~180 | `Dialog(insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24))` | Good for mobile, but no `maxWidth` set on the dialog `ConstrainedBox`. On desktop, dialog will be very wide. | **MEDIUM** |

---

### `lib/widgets/editar_solicitacao_dialog.dart` (371 lines)

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| N/A | Default `Dialog` sizing | No explicit `maxWidth` — will be acceptable (defaults to ~560px) but bottom part may be cut off on small screens. Should have `SingleChildScrollView`. | **LOW** |

---

### `lib/widgets/navigation_components.dart`

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 123, 263 | Hardcoded `Color(0xFFE85D46)` | Badge/notification dot bypasses OwanyTheme. | **LOW** |

---

### `lib/widgets/primary_button.dart`

| Line(s) | Issue | Description | Severity |
|---------|-------|-------------|----------|
| 301, 405, 410, 415 | Hardcoded colors | `Color(0xFFFFB380)`, `Color(0xFF059669)`, `Color(0xFFDC2626)`, `Color(0xFFD97706)` — accent colors. | **LOW** |

---

## SUMMARY BY SEVERITY

### HIGH (27 findings)
1. **main.dart**: Portrait-only lock breaks desktop/web
2. **main.dart**: No adaptive navigation (Drawer-only for all platforms)
3. **Global**: No max-width constraints on ~25+ screens (forms stretch to 1920px on desktop)
4. **qr_scan_screen.dart**: No `kIsWeb` guard — crashes on web/desktop
5. **agendamento_detalhes_screen.dart**: Hardcoded background color (2x) — breaks dark mode
6. **manutencao_preventiva_detalhes_screen.dart**: 5+ hardcoded `Color(0xFF1A1A1A)` — breaks dark mode
7. **maintenance_card.dart**: 15+ hardcoded colors — breaks dark mode
8. **apartment_card.dart**: 3+ hardcoded `Color(0xFF1A1A1A)` — breaks dark mode
9. **historico_itens_screen.dart**: `RelativeRect.fromLTRB(1000, 80, 16, 0)` — popup off-screen on narrow devices
10. Form screens without LayoutBuilder: login, forgot_password, register, add_user, edit_user, create_morador, maintenance_request, change_password, editar_ativo, criar_agendamento, editar_agendamento, manutencao_preventiva_form

### MEDIUM (30 findings)
- Missing LayoutBuilder/max-width on detail/list screens (notifications, sms_massa, users_screen, user_detail, manage_residents, morador_detail, agendamentos_lista, settings, manage_request_types, qr_code_batch, historico_ocupacao, gestao_ativos, detalhe_ativo, historico_ativo, etc.)
- `showModalBottomSheet` without max-width constraints (apartments_screen, apartment_detail, manage_apartment_items, niveis_acesso, asset_management)
- `StandardGlassAppBar` fixed 120px height
- `BackdropFilter` perf on web
- Hardcoded border colors in manutencao_preventiva_detalhes

### LOW (18 findings)
- Hardcoded font sizes, logo sizes, step circles
- Minor AppBar style inconsistencies
- Fixed SliverAppBar heights (140px)
- `HapticFeedback` calls (no-op on web)
- `.withOpacity()` deprecation
- Duplicate `qr_scan_screen.dart`

---

## TOP PRIORITY FIXES

1. **Remove portrait-only lock for desktop/web** — `lib/main.dart` line 90
2. **Add `ConstrainedBox(maxWidth: 800)` wrapper** to all form/detail screens
3. **Add adaptive navigation** (NavigationRail for desktop) in `MainScaffold`
4. **Add `kIsWeb` guard** to `qr_scan_screen.dart` with text-input fallback
5. **Replace all hardcoded `Color(0x...)` values** in widgets and screens with `OwanyTheme.*` adaptive colors
6. **Add max-width to `showModalBottomSheet`** calls: `constraints: BoxConstraints(maxWidth: 500)`
7. **Fix `RelativeRect.fromLTRB(1000, ...)`** in `historico_itens_screen.dart`

---

*Report generated by automated audit. Line numbers are approximate due to file length.*
