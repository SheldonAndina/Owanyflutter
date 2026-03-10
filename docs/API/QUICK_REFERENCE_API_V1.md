# 🚀 Quick Reference - Solicitações API V1 Implementation

**Generated**: 27 January 2026  
**Status**: ✅ Ready for Development  
**Base URL**: `https://localhost:7068/api`  
**Endpoints Used**: `/Solicitacoes`, `/Comentarios`

---

## 📚 Quick Links

| Document | Purpose |
|----------|---------|
| [API_V1_VALIDATION_MAPPING.md](API_V1_VALIDATION_MAPPING.md) | DTO ↔ API Endpoint validation |
| [IMPLEMENTATION_NEXT_STEPS.md](IMPLEMENTATION_NEXT_STEPS.md) | Detailed task breakdown |
| [lib/dto/solicitacoes_v2_dtos.dart](lib/dto/solicitacoes_v2_dtos.dart) | 9 ready-to-use DTOs |
| [lib/services/solicitacoes_service_v2.dart](lib/services/solicitacoes_service_v2.dart) | 8 service methods |
| [lib/providers/solicitacoes_provider_v2.dart](lib/providers/solicitacoes_provider_v2.dart) | State management |

---

## 🎯 What's Ready

### ✅ Backend Integration
- [x] All V1 endpoints validated (GET, POST, PUT, DELETE)
- [x] Service methods implemented (list, create, update, comment, attach)
- [x] DTOs aligned with API responses
- [x] Error handling + response unwrapping
- [x] Pagination support

### ✅ State Management
- [x] ChangeNotifier Provider ready
- [x] Async state handling
- [x] Loading states
- [x] Error states

### ✅ API Documentation
- [x] Swagger V1 endpoints documented
- [x] Request/response bodies mapped
- [x] Status codes documented
- [x] Validation complete

---

## 📦 Quick API Reference

### List Solicitações (Paginated)
```dart
// Request
GET /api/Solicitacoes?pageNumber=1&pageSize=20&status=Pendente&apartamentoId=...

// Response
{
  "sucesso": true,
  "mensagem": "string",
  "data": {
    "items": [ SolicitacaoListaDto ],
    "total": 150,
    "pageNumber": 1,
    "pageSize": 20,
    "totalPages": 8,
    "hasPreviousPage": false,
    "hasNextPage": true
  }
}

// Usage
final result = await service.getSolicitacoes(
  pageNumber: 1,
  pageSize: 20,
  status: 'Pendente',
  apartamentoId: '...',
);
```

### Get Solicitação Details
```dart
// Request
GET /api/Solicitacoes/{id}

// Response
{
  "sucesso": true,
  "mensagem": "string",
  "dados": {
    "id": "...",
    "titulo": "Vazamento na cozinha",
    "descricao": "...",
    "status": "EmAndamento",
    "usuarioCriadorId": "...",
    "nomeUsuarioCriador": "João Silva",
    "responsavelId": "...",
    "nomeResponsavel": "Carlos Andrade",
    "moradorId": "...",
    "nomeMorador": "João Silva",
    "apartamentoId": "...",
    "numeroApartamento": "101",
    "blocoApartamento": "A",
    "criadoEm": "2026-01-27T13:18:51.390Z",
    "atualizadoEm": "2026-01-27T14:00:00.000Z",
    "concluidoEm": null,
    "prazoLimite": "2026-02-27T13:18:51.390Z",
    "comentarios": [ ComentarioDto ],
    "historicoStatus": [ HistoricoStatusDto ],
    "anexos": [ AnexoDto ]
  }
}

// Usage
final solicitacao = await service.getSolicitacao(id);
```

### Create Solicitação
```dart
// Request
POST /api/Solicitacoes
{
  "titulo": "Vazamento na cozinha",
  "descricao": "Há vazamento de água",
  "moradorId": "...",
  "apartamentoId": "...",
  "prazoLimite": "2026-02-27T13:18:51.381Z"
}

// Usage
final dto = CriarSolicitacaoDto(
  titulo: 'Vazamento na cozinha',
  descricao: 'Há vazamento de água',
  moradorId: moradorId,
  apartamentoId: apartamentoId,
  prazoLimite: DateTime.now().add(Duration(days: 30)),
);
final nova = await service.criarSolicitacao(dto);
```

### Change Status
```dart
// Request
PUT /api/Solicitacoes/{id}/status
{
  "novoStatus": "EmAndamento",
  "comentario": "Iniciando atendimento"
}

// Usage
await service.mudarStatus(id, MudarStatusDto(
  novoStatus: 'EmAndamento',
  comentario: 'Iniciando atendimento',
));
```

### Add Comment
```dart
// Request
POST /api/Solicitacoes/{id}/comentarios
{
  "solicitacaoId": "...",
  "mensagem": "Já iniciei o atendimento",
  "interno": false
}

// Usage
await service.adicionarComentario(id, CriarComentarioDto(
  solicitacaoId: id,
  mensagem: 'Já iniciei o atendimento',
  interno: false,
));
```

### Upload Attachment
```dart
// Request
POST /api/Solicitacoes/{id}/anexos
multipart/form-data:
  arquivo: <binary_file>

// Usage
final anexo = await service.uploadAnexo(
  id,
  fileBytes,
  'foto_problema.jpg',
);
```

---

## 🛠️ Usage in Screens

### Provider Setup (In main.dart)
```dart
import 'providers/solicitacoes_provider.dart';

// Register in MultiProvider
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider<SolicitacoesProvider>(
      create: (_) => SolicitacoesProvider(),
    ),
  ],
)
```

### In Screens (List Example)
```dart
class MaintenanceListScreen extends StatefulWidget {
  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  late SolicitacoesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<SolicitacoesProvider>();
    
    // Defer loading until after widget tree built
    Future.microtask(() => _provider.loadSolicitacoes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return ErrorWidget(message: provider.error!);
          }

          if (provider.solicitacoes.isEmpty) {
            return EmptyWidget();
          }

          return ListView.builder(
            itemCount: provider.solicitacoes.length,
            itemBuilder: (context, index) {
              final solicitacao = provider.solicitacoes[index];
              return SolicitacaoCard(solicitacao: solicitacao);
            },
          );
        },
      ),
    );
  }
}
```

### In Screens (Detail Example)
```dart
class MaintenanceDetailScreen extends StatefulWidget {
  final String solicitacaoId;
  
  const MaintenanceDetailScreen({required this.solicitacaoId});
  
  @override
  State<MaintenanceDetailScreen> createState() => 
    _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SolicitacoesProvider _provider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _provider = context.read<SolicitacoesProvider>();
    
    Future.microtask(
      () => _provider.loadSolicitacao(widget.solicitacaoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Detalhes'),
            Tab(text: 'Comentários'),
            Tab(text: 'Anexos'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          if (provider.solicitacaoAtual == null) {
            return Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(provider.solicitacaoAtual!),
              _buildCommentsTab(provider.solicitacaoAtual!),
              _buildAttachmentsTab(provider.solicitacaoAtual!),
              _buildHistoryTab(provider.solicitacaoAtual!),
            ],
          );
        },
      ),
    );
  }

  // Implement _buildDetailsTab, _buildCommentsTab, etc.
}
```

---

## 🎨 UI Components Needed

### Reusable Widgets (Create in lib/widgets/)

#### SolicitacaoCard
```dart
class SolicitacaoCard extends StatelessWidget {
  final SolicitacaoListaDto solicitacao;
  final VoidCallback? onTap;
  
  const SolicitacaoCard({
    required this.solicitacao,
    this.onTap,
  });
}
```

#### StatusBadge
```dart
class StatusBadge extends StatelessWidget {
  final String status; // 'Pendente', 'EmAndamento', 'Concluido'
  
  const StatusBadge({required this.status});
}
```

#### CommentItem
```dart
class CommentItem extends StatelessWidget {
  final ComentarioDto comentario;
  
  const CommentItem({required this.comentario});
}
```

#### AttachmentItem
```dart
class AttachmentItem extends StatelessWidget {
  final AnexoDto anexo;
  
  const AttachmentItem({required this.anexo});
}
```

---

## 🔐 Authorization Checks

```dart
// Get current user type
final auth = context.read<AuthProvider>();
final userType = auth.usuario?.tipo; // 'Administrador', 'Funcionario', 'Morador'

// Check permissions
bool canCreate = userType != null && 
  ['Morador', 'Funcionario', 'Administrador'].contains(userType);
bool canAssign = userType == 'Funcionario' || userType == 'Administrador';
bool canCommentInternal = userType != 'Morador';
bool canDelete = userType == 'Administrador';
```

---

## 🐛 Common Issues & Solutions

### Issue: "404 Not Found" on API calls
**Cause**: Still using `/v1/solicitacoesv2` endpoint  
**Solution**: Update baseUrl to `/api/Solicitacoes`  
**Status**: ✅ FIXED in updated Service

### Issue: "setState() called during build"
**Cause**: Provider.loadSolicitacoes() called in initState directly  
**Solution**: Wrap in `Future.microtask()`  
**Status**: ✅ FIXED in maintenance_list_screen_v2.dart

### Issue: Dialog overflow
**Cause**: Column not scrollable when content exceeds screen height  
**Solution**: Wrap Column in SingleChildScrollView  
**Status**: ✅ FIXED in manage_apartment_items_screen.dart

---

## 📊 Database Models (From API)

### Solicitacao Status Values
```
"Pendente"      → Just created, waiting for assignment
"EmAndamento"   → Someone assigned and working
"Concluido"     → Marked as complete
```

### User Types (tipoUsuario)
```
"Administrador" → Full access (can create, assign, delete)
"Funcionario"   → Can create, assign, comment
"Morador"       → Can create, comment (own only)
```

### Comment Types (internal flag)
```
interno: true   → Only visible to staff (Funcionario, Administrador)
interno: false  → Visible to all (public comment)
```

---

## 🧪 Testing Checklist

```markdown
- [ ] List screen loads with data
- [ ] Infinite scroll loads next page
- [ ] Pull-to-refresh updates list
- [ ] Filters work (status, apartment)
- [ ] Create new solicitation
- [ ] View solicitation details
- [ ] Change status
- [ ] Add public comment
- [ ] Add internal comment (if admin)
- [ ] Upload attachment
- [ ] View attachment
- [ ] View status history
- [ ] Role-based access (Morador ≠ Admin)
- [ ] Error states show correctly
- [ ] Empty states show correctly
- [ ] Loading states appear
- [ ] Navigate back without crashes
- [ ] No memory leaks (dispose properly)
- [ ] 0 compilation errors
- [ ] 0 runtime exceptions
```

---

## 📞 Support References

**API Documentation**: https://localhost:7068/swagger/v1/swagger.json  
**Design System**: [lib/theme/owany_theme.dart](lib/theme/owany_theme.dart)  
**Provider Pattern**: [lib/providers/](lib/providers/)  
**Flutter Null Safety**: [Dart Docs](https://dart.dev/null-safety)

---

**Last Updated**: 27 January 2026  
**Status**: 🎉 ALL SYSTEMS READY  
**Next Step**: Start with Task 1 from [IMPLEMENTATION_NEXT_STEPS.md](IMPLEMENTATION_NEXT_STEPS.md)

