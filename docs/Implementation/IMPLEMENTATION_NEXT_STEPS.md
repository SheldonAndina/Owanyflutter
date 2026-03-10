# 🚀 Próximos Passos - Implementação Solicitações V1

**Data**: 27 January 2026  
**Status**: 🎉 VALIDAÇÃO COMPLETA - Pronto para implementação  
**Backend**: Owany API V1 (Endpoints validados)  
**Frontend**: Flutter Dart (100% null-safe)

---

## ✅ O Que Já Está Pronto

### 1. **DTOs (Data Transfer Objects)** ✅
- **Arquivo**: [lib/dto/solicitacoes_v2_dtos.dart](lib/dto/solicitacoes_v2_dtos.dart)
- **Status**: 9 DTOs completos, validados contra API V1
- **Interfaces**:
  - `SolicitacaoListaDto` → Listar solicitações (paginated)
  - `SolicitacaoDto` → Detalhes completos
  - `CriarSolicitacaoDto` → Criar nova solicitação
  - `MudarStatusDto` → Mudar status
  - `CriarComentarioDto` → Comentários
  - `ComentarioDto` → Exibir comentário
  - `AnexoDto` → Arquivo anexado
  - `HistoricoStatusDto` → Auditoria de status
  - `PagedResult<T>` → Paginação genérica

### 2. **Service** ✅
- **Arquivo**: [lib/services/solicitacoes_service_v2.dart](lib/services/solicitacoes_service_v2.dart)
- **Status**: 8 métodos, endpoints V1 atualizados
- **URL Base**: `https://localhost:7068/api/Solicitacoes` ✅ (V1 real)
- **Métodos**:
  - `getSolicitacoes()` → GET com paginação, filtros
  - `getSolicitacao(id)` → GET detalhes
  - `criarSolicitacao(dto)` → POST nova
  - `mudarStatus(id, dto)` → PUT status
  - `adicionarComentario(id, dto)` → POST comentário
  - `getComentarios(id)` → GET lista comentários
  - `getAnexos(id)` → GET lista anexos
  - `uploadAnexo(id, bytes, fileName)` → POST upload

### 3. **Provider** ✅
- **Arquivo**: [lib/providers/solicitacoes_provider_v2.dart](lib/providers/solicitacoes_provider_v2.dart)
- **Status**: ChangeNotifier completo com state management
- **Suporta**: Listagem, detalhes, criação, comentários, anexos

### 4. **Documentação** ✅
- **Arquivo**: [API_V1_VALIDATION_MAPPING.md](API_V1_VALIDATION_MAPPING.md)
- **Status**: Mapping 100% validado contra Swagger V1
- Todos os DTOs alinhados com respostas reais da API

---

## 📋 Tarefas Pendentes (TODO)

### FASE 1: Refatoração (Renomear para não confundir com V2)

#### Task 1.1: Renomear Service
```bash
# Rename:
lib/services/solicitacoes_service_v2.dart
# Para:
lib/services/solicitacoes_service.dart

# Dentro do arquivo, alterar:
class SolicitacoesServiceV2 {}
# Para:
class SolicitacoesService {}
```

**Por quê?**: O "V2" é confuso. Os endpoints SÃO V1. O "V2" na API ainda não foi implementado (retorna 404).

#### Task 1.2: Renomear Provider
```bash
# Rename:
lib/providers/solicitacoes_provider_v2.dart
# Para:
lib/providers/solicitacoes_provider.dart

# Dentro do arquivo, alterar:
class SolicitacoesProviderV2 extends ChangeNotifier {}
# Para:
class SolicitacoesProvider extends ChangeNotifier {}

# E no imports:
import '../services/solicitacoes_service.dart';
```

#### Task 1.3: Renomear DTOs (Opcional - já está OK)
```bash
# Atual: lib/dto/solicitacoes_v2_dtos.dart
# Pode manter, pois "V2" aqui refere-se à segunda versão do projeto interno
# Ou renomear para: lib/dto/solicitacoes_dtos.dart
```

#### Task 1.4: Atualizar imports em main.dart
```dart
// ANTES:
import 'providers/solicitacoes_provider_v2.dart';
Provider<SolicitacoesProviderV2>(...),

// DEPOIS:
import 'providers/solicitacoes_provider.dart';
Provider<SolicitacoesProvider>(...),
```

#### Task 1.5: Atualizar Provider imports em screens
```dart
// ANTES:
context.read<SolicitacoesProviderV2>()
Consumer<SolicitacoesProviderV2>(...)

// DEPOIS:
context.read<SolicitacoesProvider>()
Consumer<SolicitacoesProvider>(...)
```

---

### FASE 2: Implementação de Screens

#### Task 2.1: MaintenanceListScreen (Listar Solicitações)
**Arquivo**: `lib/screens/core/maintenance_list_screen.dart`

**Features**:
- [ ] Fetch lista paginada via Provider
- [ ] Infinite scroll (carregar próxima página ao scroll)
- [ ] Pull-to-refresh (swipe para atualizar)
- [ ] Cards mostrando: título, status, apartamento, data, comentários, anexos
- [ ] Filtros: por status, por apartamento
- [ ] Busca por título
- [ ] Loading skeleton enquanto carrega
- [ ] Empty state quando vazio
- [ ] Error state com retry

**UI Spec**:
```
Card (Material Design 3):
├─ Icon + Status badge (verde=Pendente, laranja=EmAndamento, azul=Concluído)
├─ Título (bold)
├─ "Apto 101 - Bloco A" (secondary text)
├─ Data criação (small text)
└─ Rodapé: "3 comentários, 2 anexos" (chips)
```

**API Calls**:
- `Provider.read<SolicitacoesProvider>().loadSolicitacoes()`
- `Provider.read<SolicitacoesProvider>().loadNextPage()`

#### Task 2.2: MaintenanceDetailScreen (Detalhes)
**Arquivo**: `lib/screens/core/maintenance_detail_screen.dart`

**Features**:
- [ ] Header: Título + Status (change status button)
- [ ] Tabs: Detalhes | Comentários | Anexos | Histórico
- [ ] **Tab Detalhes**:
  - Descrição completa
  - Morador: nome + telefone
  - Apartamento: número + bloco
  - Responsável: nome (change button)
  - Prazo limite
  - Datas: criado em, atualizado em, concluído em
- [ ] **Tab Comentários**:
  - Lista comentários (internal vs public)
  - Input para adicionar comentário
  - Checkbox "Interno" (só admin vê)
- [ ] **Tab Anexos**:
  - Lista anexos com download
  - Button para upload (camera/gallery)
- [ ] **Tab Histórico**:
  - Timeline: mudança de status + quem fez + quando
- [ ] Back button + Delete button (if authorized)

**API Calls**:
- `Provider.read<SolicitacoesProvider>().loadSolicitacao(id)`
- `Provider.read<SolicitacoesProvider>().mudarStatus(id, novoStatus)`
- `Provider.read<SolicitacoesProvider>().adicionarComentario(id, msg, interno)`
- `Provider.read<SolicitacoesProvider>().uploadAnexo(id, file)`

#### Task 2.3: CreateMaintenanceScreen (Criar)
**Arquivo**: `lib/screens/core/create_maintenance_screen.dart`

**Features**:
- [ ] Form fields:
  - Título (required, 160 chars max)
  - Descrição (optional, multiline)
  - Apartamento (dropdown com lista)
  - Morador (dropdown filtrado por apartamento)
  - Prazo limite (date picker)
  - Anexo inicial (optional, file picker)
- [ ] Validações:
  - Título obrigatório
  - Descripção não vazia se preenchida
  - Apartamento obrigatório
  - Morador obrigatório
- [ ] Botões:
  - "Criar & Adicionar Comentário" (submit + go to detail)
  - "Criar & Voltar" (submit + go back)
  - "Cancelar"
- [ ] Loading state ao enviar
- [ ] Success snackbar após criar

**API Calls**:
- `Provider.read<SolicitacoesProvider>().criarSolicitacao(dto)`

---

### FASE 3: Testes E2E

#### Task 3.1: Login Flow
- [ ] Login com usuário válido (Morador, Funcionário, Admin)
- [ ] Redirect para Dashboard

#### Task 3.2: Maintenance List Flow
- [ ] Navegar para Solicitações
- [ ] Listar solicitações
- [ ] Scroll infinito carrega mais
- [ ] Pull-to-refresh atualiza
- [ ] Filtrar por status
- [ ] Filtrar por apartamento

#### Task 3.3: Create Maintenance Flow
- [ ] Criar nova solicitação
- [ ] Validações funcionam
- [ ] Anexo upload funciona
- [ ] Sucesso redireciona para detalhes

#### Task 3.4: Detail & Interact Flow
- [ ] Abrir detalhes de solicitação
- [ ] Trocar status (se authorized)
- [ ] Adicionar comentário (público)
- [ ] Adicionar comentário interno (se admin)
- [ ] Upload anexo
- [ ] Ver histórico

#### Task 3.5: Role-Based Access
- [ ] Morador: pode criar, comentar, ver próprio
- [ ] Funcionário: pode criar, atribuir, comentar, ver todos
- [ ] Admin: full access

---

## 🔧 Arquivos a Criar/Modificar

### Criar (Novos):
```
lib/screens/core/maintenance_list_screen.dart
lib/screens/core/maintenance_detail_screen.dart
lib/screens/core/create_maintenance_screen.dart
lib/widgets/maintenance_card.dart (reusable)
lib/widgets/maintenance_status_badge.dart (reusable)
lib/widgets/comment_item.dart (reusable)
lib/widgets/attachment_item.dart (reusable)
```

### Renomear:
```
lib/services/solicitacoes_service_v2.dart → solicitacoes_service.dart
lib/providers/solicitacoes_provider_v2.dart → solicitacoes_provider.dart
```

### Modificar:
```
lib/main.dart (update imports + provider registration)
lib/screens/core/maintenance_list_screen_v2.dart (delete or keep as backup)
lib/providers/solicitacoes_provider_v2.dart (keep for reference)
lib/services/solicitacoes_service_v2.dart (keep for reference)
```

---

## 📊 Checklist de Implementação

### Fase 1: Refatoração (Renomagem)
- [ ] Task 1.1: Renomear Service para `solicitacoes_service.dart`
- [ ] Task 1.2: Renomear Provider para `solicitacoes_provider.dart`
- [ ] Task 1.3: Atualizar imports em `main.dart`
- [ ] Task 1.4: Atualizar imports em screens
- [ ] Task 1.5: Testar compilação (flutter pub get && flutter build)

### Fase 2: Implementação de Screens
- [ ] Task 2.1: `MaintenanceListScreen` com infinite scroll
- [ ] Task 2.2: `MaintenanceDetailScreen` com tabs
- [ ] Task 2.3: `CreateMaintenanceScreen` com validação
- [ ] Task 2.4: Widgets reutilizáveis (Card, Badge, Comment, Attachment)
- [ ] Task 2.5: Navigation setup (rotas em main.dart)

### Fase 3: Testes E2E
- [ ] Task 3.1: Login flow
- [ ] Task 3.2: Maintenance list flow
- [ ] Task 3.3: Create maintenance flow
- [ ] Task 3.4: Detail & interact flow
- [ ] Task 3.5: Role-based access control

---

## 🎨 UI Reference (Based on Design System)

### Cores (Use OwanyTheme)
- **Primary**: `OwanyTheme.primaryOrange` (#FF7A3D)
- **Secondary**: `OwanyTheme.primaryBrown` (#2D1B0E)
- **Success**: `OwanyTheme.success` (#7BA57E)
- **Warning**: `OwanyTheme.warning` (#D9A85C)
- **Error**: `OwanyTheme.error` (#E85D46)
- **Background**: `OwanyTheme.background` (#FAFAF8)
- **Surface**: `OwanyTheme.surface` (#F5F1ED)

### Status Badge Colors
```dart
const statusColors = {
  'Pendente': OwanyTheme.primaryOrange,
  'EmAndamento': OwanyTheme.info,
  'Concluido': OwanyTheme.success,
};
```

### Responsive Layout
- **Mobile**: Full width, vertical stacking
- **Tablet**: 2-column layout where appropriate
- **Desktop**: 3-column layout (if needed)

---

## 🔐 Authentication & Authorization

### User Types (From API)
```dart
enum UsuarioTipo {
  Administrador,  // Full access
  Funcionario,    // Create, assign, comment, view all
  Morador         // Create, comment, view own
}
```

### Permission Checks (In Screens)
```dart
bool canCreate = auth.isMorador || auth.isFuncionario || auth.isAdmin;
bool canAssign = auth.isFuncionario || auth.isAdmin;
bool canCommentInternal = auth.isFuncionario || auth.isAdmin;
bool canDelete = auth.isAdmin;
```

---

## 📝 Status Enum (From API)

```dart
enum SolicitacaoStatus {
  Pendente,     // Just created
  EmAndamento,  // Someone assigned
  Concluido,    // Marked complete
}
```

---

## 💬 API Response Unwrapping

All API responses wrapped in:
```json
{
  "sucesso": true,
  "mensagem": "...",
  "dados": <actual_data>,
  "erros": []
}
```

**Service automatically extracts `dados`** → Your screen gets typed `T` directly.

---

## 🚨 Error Handling

### In Provider:
```dart
try {
  await service.getSolicitacoes();
} on Exception catch (e) {
  _error = e.toString();
  notifyListeners();
}
```

### In Screen:
```dart
if (provider.error != null) {
  return ErrorWidget(
    message: provider.error!,
    onRetry: () => provider.loadSolicitacoes(),
  );
}
```

---

## 📚 References

- [API V1 Validation Mapping](API_V1_VALIDATION_MAPPING.md)
- [Copilot Instructions](../.github/copilot-instructions.md)
- [Theme System](lib/theme/owany_theme.dart)
- [Provider Pattern](lib/providers/)
- [Owany API Swagger](https://localhost:7068/swagger/v1/swagger.json)

---

## 🎯 Success Criteria

✅ Listar solicitações paginadas com filters & search  
✅ Criar nova solicitação com validação  
✅ Ver detalhes com comentários & anexos  
✅ Trocar status com histórico  
✅ Upload/download anexos  
✅ Role-based access control  
✅ E2E tests passing  
✅ Zero compilation errors  
✅ Zero runtime exceptions  

---

**READY TO IMPLEMENT! 🚀**

Next Developer Should:
1. Do Tasks from Fase 1 (Refactoring/Renaming)
2. Follow Fase 2 (Screen Implementation)
3. Execute Fase 3 (E2E Tests)
4. Reference files listed above for guidance

