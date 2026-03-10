# 🎯 Owany App - Professional Implementation Checklist

## Phase 1: Foundation ✅ COMPLETE

### Cleanup & Organization
- [x] Delete all C# backend files (6 files)
- [x] Delete backend analysis documentation (12 files)
- [x] Remove old incomplete models.dart
- [x] Remove old incomplete api_dtos.dart
- [x] Remove old incomplete api_service.dart
- [x] Result: Clean Flutter-only project structure

### Core Implementation (3,777 lines)
- [x] **Enums** (117 lines) - UsuarioTipo, StatusSolicitacao, EstadoApartamento, TipoNotificacao
- [x] **Models** (670 lines) - Usuario, Apartamento, Solicitacao, Comentario, Anexo, Notificacao, ItemApartamento, Morador, HistoricoStatus
- [x] **DTOs** (740+ lines) - ApiResponse wrapper + 50+ request/response classes
- [x] **ApiService** (1,350 lines) - 30+ endpoint methods + token management + generic request<T>
- [x] **AuthProvider** (240 lines) - Complete authentication with role-based access
- [x] **SolicitacoesProvider** (280 lines) - CRUD + comments + filtering
- [x] **ApartamentosProvider** (310 lines) - CRUD + items + availability
- [x] **main.dart** (70 lines) - Clean MultiProvider architecture

### Documentation
- [x] **IMPLEMENTATION_GUIDE.md** (500+ lines) - Architecture, patterns, endpoints, testing
- [x] **PHASE1_SUMMARY.md** - Comprehensive accomplishment summary
- [x] **.github/copilot-instructions.md** - AI development guide
- [x] **This checklist** - Progress tracking

### Quality Verification
- [x] 100% null safety across all files
- [x] All 60+ API endpoints implemented
- [x] All error messages in Portuguese
- [x] Complete serialization for all models
- [x] Generic request<T> pattern implemented
- [x] Token management with SharedPreferences
- [x] Role-based access helpers (isAdmin, isFuncionario, isMorador)
- [x] Loading state management in all providers
- [x] Error handling with user-friendly messages

---

## Phase 2: Authentication Screens (Next)

### LoginScreen
- [ ] TextFormField for nomeLogin with validation
- [ ] TextFormField for senha with obscurity toggle
- [ ] "Esqueci minha senha" link
- [ ] "Registrar" link
- [ ] Login button with loading state
- [ ] Error message display
- [ ] Success navigation to Dashboard
- [ ] Remember me checkbox (optional)
- [ ] Material Design 3 styling

### RegisterScreen
- [ ] TextFormField for nome
- [ ] TextFormField for nomeLogin (with uniqueness feedback)
- [ ] TextFormField for telefone (masked input)
- [ ] TextFormField for senha with strength indicator
- [ ] TextFormField for confirmação de senha
- [ ] Terms of service checkbox
- [ ] Register button with loading
- [ ] Error message display
- [ ] Success message + redirect to login
- [ ] Validation rules enforcement

### ForgotPasswordScreen
- [ ] Two-step flow: Request reset → Enter code → New password
- [ ] Step 1: Enter telefone field
- [ ] Step 2: OTP code input
- [ ] Step 3: New password + confirmation
- [ ] Loading states for each step
- [ ] Error handling for each step
- [ ] Back/Cancel option
- [ ] Success confirmation

**Estimated Lines**: 400-500

---

## Phase 3: Dashboard Screen (High Priority)

### Dashboard Components
- [ ] AppBar with notifications + profile menu
- [ ] 9 KPI Cards (estatísticas):
  - [ ] Total Apartamentos
  - [ ] Total Solicitações Pendentes
  - [ ] Total Solicitações Em Andamento
  - [ ] Total Solicitações Concluídas
  - [ ] Total Usuários
  - [ ] Total Moradores
  - [ ] Ocupação (percentage)
  - [ ] Manutenções Sem Responsável
  - [ ] Notificações Não Lidas

### Recent Activity Section
- [ ] Solicitações Recentes (últimas 10)
- [ ] ListTile for each: título, status, apartment, data
- [ ] Tap to navigate to detail
- [ ] Empty state if none

### Status Chart
- [ ] Pie/Donut chart showing distribution:
  - [ ] Pendente (count + percentage)
  - [ ] EmAndamento (count + percentage)
  - [ ] Concluido (count + percentage)
- [ ] Legend with colors
- [ ] Tap segments for filtering

### Quick Actions
- [ ] FAB to create new solicitação (visible for funcionário+)
- [ ] "Ver Todas Solicitações" button
- [ ] "Gerenciar Apartamentos" button (admin only)
- [ ] "Gerenciar Usuários" button (admin only)

### Refresh & Loading
- [ ] Pull-to-refresh on entire screen
- [ ] Skeleton loaders for cards while fetching
- [ ] Error state with retry button
- [ ] Empty state messaging

**Estimated Lines**: 500-600

---

## Phase 4: Solicitações Feature (Core)

### SolicitacoesListScreen
- [ ] Paginated list of solicitações
- [ ] Filter buttons: All / Pendente / EmAndamento / Concluído
- [ ] Search box (by título)
- [ ] Sort options (data, status, prioridade)
- [ ] ListTile for each:
  - [ ] Título (bold, truncated)
  - [ ] Apartment info
  - [ ] Status badge (colored)
  - [ ] Data criação
  - [ ] Responsible name (if assigned)
- [ ] Pull-to-refresh
- [ ] FAB to create new
- [ ] Empty state messaging
- [ ] Navigate to detail on tap

### SolicitacaoDetailScreen
- [ ] Header with:
  - [ ] Título (large)
  - [ ] Status badge (with color)
  - [ ] Data criação + última atualização
  - [ ] Apartment info
  - [ ] Responsible info (if assigned)

- [ ] Description section (full text)
- [ ] Details card:
  - [ ] Criado por
  - [ ] Assigned to (if exists)
  - [ ] Prazo limite (if exists)
  - [ ] Tags (if any)

- [ ] Histórico de Status (timeline):
  - [ ] Each status change: status, usuário, data/hora
  - [ ] Visual timeline layout

- [ ] Comments Section:
  - [ ] List of comments with:
    - [ ] User avatar
    - [ ] Username + role
    - [ ] Message text
    - [ ] Data/hora
    - [ ] "Interno" badge (if interno=true and user has permission)
  - [ ] Delete button (own comments + funcionário+)
  - [ ] Edit option (own comments)
  - [ ] Reply text box:
    - [ ] Message input
    - [ ] "Interno" toggle (funcionário+ only)
    - [ ] Submit button

- [ ] Action Buttons (based on role):
  - [ ] Editar (funcionário+)
  - [ ] Atribuir (admin/funcionário)
  - [ ] Mudar Status (with workflow menu)
  - [ ] Adicionar Anexo
  - [ ] Deletar (admin/owner)

### CriarSolicitacaoScreen
- [ ] Form fields:
  - [ ] Titulo (required, text input)
  - [ ] Descricao (required, multiline text)
  - [ ] Apartamento (required, dropdown/autocomplete)
  - [ ] Responsável (optional, funcionário dropdown)
  - [ ] Anexos (optional, file picker)
- [ ] Form validation (inline errors)
- [ ] Submit button with loading state
- [ ] Success confirmation
- [ ] Navigate back to list

### EditSolicitacaoScreen
- [ ] Same as create but pre-populated
- [ ] Cancel confirmation on unsaved changes
- [ ] Delete button (with confirmation)

**Estimated Lines**: 800-1000

---

## Phase 5: Apartamentos Feature

### ApartamentosListScreen
- [ ] Filter buttons: All / Disponível / Ocupado / Manutenção
- [ ] Bloco selector (dropdown or chips)
- [ ] Search by número/nome
- [ ] GridView (2 columns) of apartment cards:
  - [ ] Apartment image/icon
  - [ ] Número
  - [ ] Bloco
  - [ ] Estado (colored badge)
  - [ ] Quantity of residents
  - [ ] Items count badge
- [ ] FAB to create (admin only)
- [ ] Navigate to detail on tap

### ApartamentoDetailScreen
- [ ] Header:
  - [ ] Número + Bloco + Andar
  - [ ] Estado badge
  - [ ] Quantity of residents

- [ ] Details tab:
  - [ ] Apartment info: nome, número, bloco, andar, estado
  - [ ] Edit button (admin)
  - [ ] Delete button (admin, with confirmation)

- [ ] Residents tab:
  - [ ] List of moradores with names
  - [ ] Add resident button (admin)
  - [ ] Remove resident button (admin)

- [ ] Items tab:
  - [ ] List of items with:
    - [ ] Nome
    - [ ] Status (badge)
    - [ ] Localização
    - [ ] Edit/delete buttons (admin)
  - [ ] Add item button (admin)
  - [ ] Bulk add items option (admin)

### CreateApartamentoScreen
- [ ] Form fields:
  - [ ] Nome (required)
  - [ ] Número (required, unique)
  - [ ] Bloco (required, from list)
  - [ ] Andar (required, number)
  - [ ] Estado (dropdown: Disponível, Ocupado, Manutenção)
- [ ] Submit + success + navigate

**Estimated Lines**: 600-800

---

## Phase 6: Admin Features

### UsuariosListScreen
- [ ] User list with:
  - [ ] Avatar + Nome
  - [ ] Tipo badge (Admin/Funcionário/Morador)
  - [ ] Ativo/Inativo status
  - [ ] Actions menu (edit, activate, deactivate)
- [ ] Filter by tipo
- [ ] Search by nome
- [ ] FAB to create new user
- [ ] Page navigation

### CreateEditUserScreen
- [ ] Form fields:
  - [ ] Nome (required)
  - [ ] NomeLogin (required, unique)
  - [ ] Telefone (required, masked)
  - [ ] Tipo (required, dropdown)
  - [ ] Ativo checkbox
  - [ ] Reset password button (edit mode)

### NotificacoesScreen
- [ ] Notification list:
  - [ ] Type icon/badge
  - [ ] Message text
  - [ ] Date/time
  - [ ] Read status (visual indicator)
- [ ] Filter: All / Unread
- [ ] Mark as read (single)
- [ ] Mark all as read (button)
- [ ] Delete notification
- [ ] Empty state

**Estimated Lines**: 400-500

---

## Phase 7: UI Components Library

### Reusable Widgets
- [ ] LoadingIndicator (with different styles)
- [ ] EmptyStateWidget (customizable)
- [ ] ErrorStateWidget (with retry)
- [ ] SkeletonLoader (card, list, chart variants)
- [ ] StatusBadge (for all status types)
- [ ] PrimaryButton (elevated button style)
- [ ] SecondaryButton
- [ ] DangerButton (delete, red)
- [ ] CustomAppBar (with app-specific styling)
- [ ] CustomBottomNavBar
- [ ] DateTimePickerField
- [ ] FilterChips (reusable)
- [ ] ApartmentCard
- [ ] SolicitacaoCard
- [ ] UserCard
- [ ] CommentWidget
- [ ] TimelineItem
- [ ] StatsCard

**Estimated Lines**: 400-500

---

## Testing Checklist

### Authentication Flow
- [ ] Login with valid admin credentials
- [ ] Login with valid funcionário credentials
- [ ] Login with valid morador credentials
- [ ] Invalid login error handling
- [ ] Password reset flow
- [ ] Register new account flow
- [ ] Token persists across app restart
- [ ] Logout clears token
- [ ] 401 response triggers auto-logout

### Solicitações Feature
- [ ] Load list with all solicitações
- [ ] Filter by status (Pendente, EmAndamento, Concluido)
- [ ] Search by título
- [ ] Create new solicitação
- [ ] View solicitação details
- [ ] Add comment (public & internal)
- [ ] Edit own comments (morador)
- [ ] Edit comment as funcionário
- [ ] Delete comment as admin
- [ ] Assign to funcionário
- [ ] Update status workflow
- [ ] Add/remove anexos
- [ ] View histórico de status
- [ ] Delete solicitação (admin)
- [ ] Morador can only see own solicitações
- [ ] Morador cannot see interno comments

### Apartamentos Feature
- [ ] Load list of apartments
- [ ] Filter by bloco, estado
- [ ] Create apartment
- [ ] Edit apartment
- [ ] Delete apartment
- [ ] Manage items (add, edit, delete)
- [ ] Bulk add items
- [ ] Add/remove residents
- [ ] View available apartments

### Role-Based Access
- [ ] Admin sees all menus + management features
- [ ] Funcionário sees solicitações + can assign
- [ ] Morador sees only own solicitações + dashboard
- [ ] Menu items hidden for unauthorized roles
- [ ] API calls reject unauthorized requests

### Dashboard
- [ ] Load estatísticas on open
- [ ] Display 9 KPI cards correctly
- [ ] Show recent solicitações
- [ ] Display status chart
- [ ] Pull-to-refresh works
- [ ] Navigation to detail screens
- [ ] Empty states work

### Performance
- [ ] List pagination on large datasets
- [ ] Image loading optimization
- [ ] Memory leak prevention
- [ ] Smooth animations
- [ ] Fast navigation between screens

### Error Handling
- [ ] Network errors show user-friendly messages
- [ ] API errors display correctly
- [ ] Retry buttons work
- [ ] Timeout handling
- [ ] Empty states appropriate
- [ ] Loading states visible

---

## Code Quality Standards

### For Each Screen
- [ ] Null safety 100%
- [ ] Provider pattern used correctly
- [ ] Loading state displayed
- [ ] Error state with retry
- [ ] Empty state handled
- [ ] Portuguese text throughout
- [ ] Material Design 3
- [ ] Responsive layout
- [ ] No hardcoded strings/colors
- [ ] Proper spacing/padding

### For Each Provider Method
- [ ] Return type clear (bool/void/T)
- [ ] Error handling with user message
- [ ] Loading state set before/after
- [ ] Success confirmation (if needed)
- [ ] notifyListeners() called
- [ ] No side effects outside provider

### For Each API Call
- [ ] Endpoint documented (URL + method)
- [ ] Request DTO used (if POST/PUT)
- [ ] Response DTO used
- [ ] Error message user-friendly
- [ ] Timeout handled
- [ ] Network error handled

---

## Documentation Requirements

### Code Comments
- [ ] Complex logic explained
- [ ] Public methods have doc comments
- [ ] Non-obvious decisions documented
- [ ] TODO items removed before release

### Screen Documentation
- [ ] Purpose stated at top of file
- [ ] Key state variables documented
- [ ] Complex methods explained

### Architecture Documentation
- [ ] Data flow diagrams
- [ ] State management flow
- [ ] API request/response examples
- [ ] Error handling strategy

---

## Build & Deployment Checklist

### Before Release
- [ ] Remove all debugPrint statements (or use conditional)
- [ ] Remove TODO items
- [ ] No console errors/warnings
- [ ] No memory leaks
- [ ] All screens responsive (phone + tablet)
- [ ] Localization complete (PT-BR)
- [ ] Dark mode working
- [ ] Loading performance acceptable

### Build Targets
- [ ] Android APK builds
- [ ] iOS build ready
- [ ] Windows desktop builds
- [ ] Web builds
- [ ] Splash screen configured
- [ ] Icons configured
- [ ] App name correct

### Testing Environments
- [ ] Development: localhost:7068
- [ ] Staging: staging server URL
- [ ] Production: production server URL

---

## Summary: Lines of Code Target

| Phase | Component | Estimated Lines | Status |
|-------|-----------|-----------------|--------|
| 1 | Foundation (models, DTOs, services, providers) | 3,777 | ✅ Done |
| 2 | Auth Screens (Login, Register, Forgot Password) | 400-500 | ⏳ Next |
| 3 | Dashboard Screen | 500-600 | ⏳ Next |
| 4 | Solicitações Feature | 800-1000 | ⏳ Next |
| 5 | Apartamentos Feature | 600-800 | ⏳ Next |
| 6 | Admin Features | 400-500 | ⏳ Next |
| 7 | UI Components Library | 400-500 | ⏳ Next |
| **TOTAL** | **Complete Professional App** | **~7,500-8,500** | |

---

## Success Criteria

### Phase 1 ✅ Complete
- [x] Clean architecture in place
- [x] All API endpoints implemented
- [x] All models defined
- [x] State management ready
- [x] Documentation complete

### Phase 2-7 ✅ Ready to Start
- [ ] User can authenticate
- [ ] User sees personalized dashboard
- [ ] User can manage solicitações (CRUD)
- [ ] User can manage apartments (CRUD)
- [ ] Admin can manage users
- [ ] Notifications work
- [ ] Role-based access enforced
- [ ] Error handling comprehensive
- [ ] Performance acceptable
- [ ] Code quality senior-level

---

**Updated**: 21 January 2026  
**Status**: Phase 1 ✅ Foundation Complete  
**Next**: Phase 2 - Authentication Screens  
**Quality Target**: Senior-level, as if developed by 20 senior programmers  

🚀 **Ready for Phase 2 UI Development**
