# 🚀 Owany App - Professional Implementation Roadmap

## Current State Assessment
- ✅ Basic project structure exists
- ✅ ApiService with generic request method
- ✅ Provider pattern partially implemented
- ⚠️ Missing: Complete CRUD for all endpoints
- ⚠️ Missing: Professional error handling & UX
- ⚠️ Missing: Dashboard implementation
- ⚠️ Missing: Advanced features (pagination, filtering)
- ⚠️ Quality: Needs elevation to senior-level polish

---

## Phase 1: Foundation (Days 1-2)

### 1.1 Clean Up Project Structure
- [ ] Delete deprecated `pages/` directory (migrate screens to `screens/`)
- [ ] Consolidate models into `models/models.dart` with all enums
- [ ] Create comprehensive DTOs in `dto/` for each endpoint group
- [ ] Remove commented/dead code
- [ ] Verify `main.dart` routing is complete

### 1.2 Enhance ApiService
- [ ] Add pagination support (skip, take parameters)
- [ ] Add filtering methods for each endpoint
- [ ] Implement token refresh logic (if 401, use refreshToken)
- [ ] Add request timeout handling
- [ ] Add logging for API calls (debugPrint)

### 1.3 Create Robust AuthService
- [ ] Load token on app start (SharedPreferences)
- [ ] Login method with token persistence
- [ ] Logout clears token and redirects
- [ ] Auto-logout on 401 Unauthorized
- [ ] Password reset via OTP flow

---

## Phase 2: Core Features (Days 3-5)

### 2.1 Authentication Screens
- [ ] **LoginScreen**: Email/password + Remember me checkbox
- [ ] **RegisterScreen**: Sign-up form with validation
- [ ] **ForgotPasswordScreen**: OTP-based reset
- [ ] **Error handling**: Show clear messages for invalid credentials

### 2.2 Dashboard (Admin View)
- [ ] GET `/api/dashboard/estatisticas` → Show KPI cards
- [ ] GET `/api/dashboard/solicitacoes-recentes` → Recent requests list
- [ ] GET `/api/dashboard/grafico-status` → Status chart
- [ ] Refresh button + pull-to-refresh

### 2.3 Maintenance Requests (Solicitacoes)
- [ ] **List screen**: Filter by status, apartment
- [ ] **Detail screen**: Full request info + comments
- [ ] **Create screen**: Form to create new request
- [ ] **Edit screen**: Update title, description, status
- [ ] **Comments**: Add/edit/delete comments (public vs internal)
- [ ] **Assign**: Admin/Funcionário assign responsible

### 2.4 Apartments Management
- [ ] **List**: Show all apartments with filters (bloco, estado)
- [ ] **Detail**: Apartment info + residents + items
- [ ] **Create**: Form to add new apartment
- [ ] **Items**: Manage apartment inventory items
- [ ] **Residents**: Link residents to apartments

---

## Phase 3: Advanced Features (Days 6-8)

### 3.1 Notifications System
- [ ] GET `/api/notificacoes` → List all notifications
- [ ] Mark as read functionality
- [ ] Notification badges on icons
- [ ] Push notifications (optional FCM integration)

### 3.2 Users Management (Admin Only)
- [ ] **List screen**: All users with type/status filters
- [ ] **Detail screen**: User info + activation status
- [ ] **Edit screen**: Update user details
- [ ] **Activate/Deactivate**: Toggle user status
- [ ] **Role indicators**: Show Admin/Funcionário/Morador badge

### 3.3 Residents Management
- [ ] GET `/api/moradores` with apartment filter
- [ ] Link users to apartments as residents
- [ ] View resident details (contact info)
- [ ] Remove residents from apartments

### 3.4 Professional UI/UX
- [ ] Implement skeleton loaders for all async screens
- [ ] Add pull-to-refresh on list screens
- [ ] Infinite scroll pagination
- [ ] Empty state illustrations
- [ ] Error state with retry buttons
- [ ] Success toast notifications

---

## Phase 4: Quality & Polish (Days 9-10)

### 4.1 Code Quality
- [ ] Run `flutter analyze` → Zero warnings
- [ ] Remove all TODOs/FIXMEs
- [ ] Consistent naming conventions (Portuguese)
- [ ] No magic strings (all in constants/)
- [ ] Proper error handling everywhere

### 4.2 Testing & Validation
- [ ] Test all role-based access (Admin/Funcionário/Morador)
- [ ] Verify pagination works on large datasets
- [ ] Test offline scenarios (no internet)
- [ ] Verify token refresh flow
- [ ] Check all forms have validation

### 4.3 Performance
- [ ] Lazy load lists (pagination)
- [ ] Cache API responses where appropriate
- [ ] Optimize image loading
- [ ] Minimize widget rebuilds
- [ ] Profile with DevTools

### 4.4 Documentation
- [ ] Update README.md with setup instructions
- [ ] Add screen flow diagrams
- [ ] Document API integration points
- [ ] Include troubleshooting section

---

## Implementation Priority by Feature

### 🔴 CRITICAL (Must Have)
1. Authentication (login/logout) ← Start here
2. Solicitacoes CRUD (core business logic)
3. Dashboard with stats
4. Role-based access control

### 🟠 HIGH (Essential)
5. Apartamentos management
6. Comments system
7. User management (admin)
8. Notifications

### 🟡 MEDIUM (Polish)
9. Residents management
10. Advanced filtering/search
11. Offline support
12. Advanced animations

### 🟢 LOW (Nice to Have)
13. Dark theme
14. Multi-language support
15. Analytics tracking
16. Export/reports

---

## Technical Debt to Address

```dart
// ❌ Before: Magic strings
ApiService().request('apartamentos', ...);

// ✅ After: Constants
ApiService().request(ApiEndpoints.apartamentos, ...);

---

// ❌ Before: No error handling
final data = await ApiService().getApartamentos();

// ✅ After: Proper try-catch
try {
  final data = await ApiService().getApartamentos();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro ao carregar: ${_formatError(e)}')),
  );
}

---

// ❌ Before: setState everywhere
setState(() { data = newData; });

// ✅ After: Provider pattern
final provider = Provider.of<DataProvider>(context, listen: false);
await provider.loadData();
```

---

## File Structure After Completion

```
lib/
├── main.dart ✅ COMPLETE
├── constants/
│   ├── api_constants.dart ✅
│   ├── app_colors.dart ✅
│   └── app_strings.dart ✅
├── dto/ ✅ COMPLETE
│   ├── auth_dto.dart
│   ├── apartamento_dto.dart
│   ├── solicitacao_dto.dart
│   ├── dashboard_dto.dart
│   └── ...
├── models/ ✅ COMPLETE
│   └── models.dart (all models + enums)
├── providers/ ✅ COMPLETE
│   ├── auth_provider.dart
│   ├── solicitacoes_provider.dart
│   ├── apartamentos_provider.dart
│   ├── usuarios_provider.dart
│   └── ...
├── screens/ ✅ COMPLETE (replace pages/)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── dashboard_screen.dart
│   ├── solicitacoes/
│   │   ├── solicitacoes_list_screen.dart
│   │   ├── solicitacao_detail_screen.dart
│   │   ├── criar_solicitacao_screen.dart
│   │   └── editar_solicitacao_screen.dart
│   ├── apartamentos/
│   │   ├── apartamentos_list_screen.dart
│   │   ├── apartamento_detail_screen.dart
│   │   ├── criar_apartamento_screen.dart
│   │   └── manage_items_screen.dart
│   ├── usuarios_screen.dart
│   ├── notificacoes_screen.dart
│   └── ...
├── services/
│   ├── api_service.dart ✅ ENHANCED
│   ├── auth_service.dart ✅ COMPLETE
│   └── ...
├── theme/
│   ├── owany_theme.dart ✅
│   ├── app_colors.dart ✅
│   └── typography.dart ✅
├── widgets/ ✅ COMPLETE
│   ├── common/
│   │   ├── loading_skeleton.dart
│   │   ├── empty_state.dart
│   │   ├── error_state.dart
│   │   └── custom_button.dart
│   ├── dialogs/
│   │   ├── confirm_dialog.dart
│   │   └── error_dialog.dart
│   └── cards/
│       ├── solicitacao_card.dart
│       ├── apartamento_card.dart
│       └── ...
├── utils/
│   ├── validators.dart
│   ├── formatters.dart
│   ├── extensions.dart
│   └── ...
├── i18n/
│   └── idioma.dart ✅
└── assets/ ✅
    ├── icons/
    ├── images/
    └── fonts/
```

---

## Success Criteria

✅ **Code Quality**
- Zero lint warnings
- No TODOs or FIXMEs
- Consistent Portuguese naming
- Proper error handling everywhere

✅ **Features**
- All CRUD operations working
- Role-based access control enforced
- Dashboard showing real data
- Comments system functional
- User management accessible (admin)

✅ **UX/UI**
- Professional loading states (skeleton screens)
- Clear error messages
- Empty state screens
- Smooth animations
- Responsive on all screen sizes

✅ **Performance**
- List pagination implemented
- No excessive rebuilds
- Images optimized
- API calls cached where appropriate

✅ **Security**
- JWT tokens handled correctly
- 401 Unauthorized handled (auto-logout)
- No credentials in logs
- HTTPS only in production

---

## Next Steps

1. ✅ Review this roadmap
2. 🔲 Begin Phase 1 (cleanup + foundation)
3. 🔲 Complete Phase 2 (core features)
4. 🔲 Execute Phase 3 (advanced)
5. 🔲 Polish Phase 4 (quality)

**Estimated Time**: 10 business days for one senior developer  
**Team Size for 5 days**: 2 senior developers (parallel work)

---

Generated: 21 January 2026  
Status: Ready for implementation
