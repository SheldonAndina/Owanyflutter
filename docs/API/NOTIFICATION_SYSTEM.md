# Sistema de Notificações - Owany App

> **Status**: ✅ **Implementação Completa**  
> **Data**: 21 de Janeiro de 2026  
> **Versão**: 1.0

---

## 📋 Visão Geral

Sistema de notificações em tempo real integrado ao aplicativo Owany para manter moradores, funcionários e administradores informados sobre mudanças e atualizações em solicitações de manutenção.

### Objetivos
- Notificar usuários sobre atividades relevantes em solicitações
- Fornecer UX clara com filtros e ações rápidas
- Rastrear notificações lidas/não lidas
- Integração automática com principais eventos da app

---

## 🎯 Tipos de Notificação

| Tipo | Icon | Evento Disparador | Usuários Notificados | Descrição |
|------|------|---|---|---|
| **NovoComentario** | `comment_rounded` | Comentário público adicionado | Morador, Admin, Funcionário responsável | "Novo comentário em [Título]" |
| **AberturaSolicitacao** | `note_add` | Solicitação criada | Morador (proprietário) | "Sua solicitação foi aberta" |
| **MudancaStatus** | `update_rounded` | Status alterado (Pendente→Em Andamento→Concluído) | Todos envolvidos | "[Status Antigo] → [Status Novo]" |
| **AtribuicaoResponsavel** | `assignment_rounded` | Responsável atribuído | Funcionário responsável | "Você foi atribuído a [Título]" |
| **AlteracaoPrazo** | `schedule_rounded` | Prazo definido/alterado | Morador, Admin | "Novo prazo: DD/MM/YYYY" ou "Prazo removido" |
| **NovasolicitacaoCriada** | `build_rounded` | Nova solicitação criada (admin view) | Administrador | "Nova solicitação de [Morador]" |
| **Aviso** | `warning_rounded` | Aviso do sistema | Todos | Mensagem customizada |
| **Sistema** | `notifications_rounded` | Evento do sistema | Todos | Notificação de manutenção/info geral |

---

## 🏗️ Arquitetura

### 1. **Models & Enums** (`lib/models/`)

#### `enums.dart` - `TipoNotificacao`
```dart
enum TipoNotificacao {
  NovoComentario,
  AberturaSolicitacao,
  MudancaStatus,
  AtribuicaoResponsavel,
  AlteracaoPrazo,
  NovasolicitacaoCriada,
  Aviso,
  Sistema,
}

extension TipoNotificacaoExtension on TipoNotificacao {
  String toPortuguese() { ... }        // "Novo comentário", "Abertura de solicitação", etc
  IconData getIcon() { ... }            // Retorna IconData para cada tipo
}
```

#### `models.dart` - `Notificacao`
```dart
class Notificacao {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensagem;
  final String tipo;                    // TipoNotificacao.toString()
  final bool lida;
  final DateTime criadoEm;
  final String? solicitacaoId;          // Link para solicitação
  final String? nomeRemetente;          // "Sistema", nome do usuário, etc
}
```

### 2. **Services** (`lib/services/`)

#### `api_service.dart` - Métodos de Notificação
```dart
// GET /api/notificacoes
Future<List<Notificacao>> carregarNotificacoes() { ... }

// GET /api/notificacoes/{id}
Future<Notificacao> getNotificacao(String id) { ... }

// POST /api/notificacoes
Future<Notificacao> criarNotificacao({
  required String usuarioId,
  required String titulo,
  required String mensagem,
  required String tipo,
  String? solicitacaoId,
  String? nomeRemetente,
}) { ... }

// DELETE /api/notificacoes/{id}
Future<void> deletarNotificacao(String id) { ... }

// PUT /api/notificacoes/{id}/marcar-lida
Future<void> marcarNotificacaoLida(String id) { ... }

// PUT /api/notificacoes/marcar-todas-lidas
Future<void> marcarTodasNotificacoesLidas() { ... }
```

### 3. **Providers** (`lib/providers/`)

#### `notificacoes_provider.dart` - State Management

**Propriedades:**
```dart
List<Notificacao> _notificacoes = [];           // Todas as notificações
bool _isLoading = false;
String? _errorMessage;
int _filtroTipo = 0;                           // 0=Todas, 1=Não lidas

// Getters
List<Notificacao> get notificacoes { ... }
List<Notificacao> get notificacoesFiltradas { ... }  // Cliente-side filtering
int get totalNaoLidas => notificacoes.where((n) => !n.lida).length;
```

**Métodos Públicos:**

```dart
// Carregar notificações do backend
Future<void> carregarNotificacoes() async {
  // GET /api/notificacoes
  // notifyListeners() após sucesso
}

// Marcar como lida
Future<void> marcarComoLida(String notificacaoId) async {
  // PUT /api/notificacoes/{id}/marcar-lida
  // Atualizar local + notifyListeners()
}

// Marcar todas como lidas
Future<void> marcarTodasComoLidas() async {
  // PUT /api/notificacoes/marcar-todas-lidas
  // Atualizar todas localmente + notifyListeners()
}

// Deletar notificação
Future<void> deletarNotificacao(String notificacaoId) async {
  // DELETE /api/notificacoes/{id}
  // Remover da lista local + notifyListeners()
}

// Gerar notificação de comentário
Future<void> gerarNotificacaoComentario({
  required String solicitacaoId,
  required String titulo,
  required String mensagem,
  required String authorId,
  required String authorName,
  required bool ehInterno,
  required List<String> usuariosParaNotificar,
}) async {
  // if (ehInterno) return;  // Não notifica se interno
  // Para cada usuário em usuariosParaNotificar (exceto autor):
  //   POST /api/notificacoes com TipoNotificacao.NovoComentario
}

// Gerar notificação de status alterado
Future<void> gerarNotificacaoStatusAlterado({
  required String solicitacaoId,
  required String titulo,
  required String oldStatus,
  required String newStatus,
  required String authorId,
  required String authorName,
  required List<String> usuariosParaNotificar,
}) async { ... }

// Gerar notificação de atribuição
Future<void> gerarNotificacaoAtribuicao({
  required String solicitacaoId,
  required String titulo,
  required String newResponsavelId,
  required String attributorName,
}) async { ... }

// Gerar notificação de alteração de prazo
Future<void> gerarNotificacaoAlteracaoPrazo({
  required String solicitacaoId,
  required String titulo,
  required DateTime? novoPrazo,
  required String authorName,
  required List<String> usuariosParaNotificar,
}) async { ... }

// Gerar notificação de abertura
Future<void> gerarNotificacaoAbertura({
  required String solicitacaoId,
  required String titulo,
  required String moradorId,
  required String moradorName,
  required String adminId,
}) async { ... }
```

### 4. **Screens** (`lib/screens/`)

#### `utility/notifications_screen.dart`
**Funcionalidades:**
- ✅ Lista de notificações com scroll infinito
- ✅ Filtros (Todas / Não lidas) no top
- ✅ Badge contador de não lidas no AppBar
- ✅ Cards dismissibles (swipe left = delete)
- ✅ Tap para marcar como lida + navegar para solicitação
- ✅ Botão "Marcar todas como lidas" no AppBar
- ✅ Estado vazio com ícone quando sem notificações
- ✅ Tempo relativo (Agora, Há 5m, Há 2h, etc)

**Exemplo de Card:**
```
┌─────────────────────────────────────┐
│ 💬 Novo comentário                  │  ← Icon by type
│ Em "Vazamento na cozinha"           │  ← Title
│ "Vamos enviar um técnico hoje"      │  ← Message excerpt
│ De: João (Funcionário) • Há 15min   │  ← Sender + time
└─────────────────────────────────────┘
```

#### `core/maintenance_detail_screen.dart` - Integração

**Métodos modificados:**

1. **_adicionarComentario()** 
   - Após sucesso: Chama `notificacoesProvider.gerarNotificacaoComentario()`
   - Notifica: Morador da solicitação, Funcionário responsável, Admin
   - Condicional: Só notifica se comentário é público

2. **_alterarStatus()**
   - Após sucesso: Chama `notificacoesProvider.gerarNotificacaoStatusAlterado()`
   - Notifica: Todos envolvidos (exceto quem alterou)
   - Mensagem: "[Status Antigo] → [Status Novo]"

3. **_salvarEdicao()**
   - Após sucesso: Chamadas condicionais:
     - Se prazo alterado: `gerarNotificacaoAlteracaoPrazo()`
     - Se responsável alterado: `gerarNotificacaoAtribuicao()`
   - Notifica: Morador, Admin

#### `core/dashboard_screen.dart` - Badge

**AppBar com Badge de Notificações:**
```dart
appBar: ModernDrawerAppBar(
  title: 'Owany',
  actions: [
    Stack(  // Badge com contador
      children: [
        IconButton(
          icon: Icon(Icons.notifications_rounded),
          onPressed: () => Navigator.pushNamed(context, '/notificacoes'),
        ),
        if (notificacoesProvider.totalNaoLidas > 0)
          Positioned(
            right: 4, top: 4,
            child: Badge(                // Mostra número de não lidas
              label: Text(naoLidas),
              backgroundColor: OwanyTheme.error,
            ),
          ),
      ],
    ),
  ],
)
```

---

## 🔄 Fluxos Principais

### 1. **Comentário Adicionado**
```
User A escreve comentário em Solicitação #123
  ↓
maintenance_detail_screen: _adicionarComentario() sucesso
  ↓
context.read<NotificacoesProvider>().gerarNotificacaoComentario(
  solicitacaoId: #123,
  authorId: UserA.id,
  authorName: UserA.nome,
  usuariosParaNotificar: [Morador.id, Admin.id, Funcionário.id]
)
  ↓
Para cada usuário em lista (exceto UserA):
  POST /api/notificacoes {
    usuarioId: userId,
    titulo: "Novo comentário: Vazamento na cozinha",
    mensagem: "Vamos enviar um técnico hoje",
    tipo: "NovoComentario",
    solicitacaoId: #123,
    nomeRemetente: "João (Funcionário)"
  }
  ↓
Backend cria Notificacao no DB
  ↓
NotificacoesScreen exibe notificação com ícone 💬
  ↓
User toca → Marcar como lida + Navegar para solicitação
```

### 2. **Status Alterado**
```
User B altera Status: Pendente → Em Andamento
  ↓
maintenance_detail_screen: _alterarStatus(Solicitacao, StatusSolicitacao.EmAndamento)
  ↓
notificacoesProvider.gerarNotificacaoStatusAlterado(
  solicitacaoId: #123,
  oldStatus: "Pendente",
  newStatus: "Em Andamento",
  authorName: UserB.nome,
  usuariosParaNotificar: [Morador.id, Admin.id]
)
  ↓
POST /api/notificacoes (×2, uma por usuário)
  ↓
Notificação exibida com ícone 🔄 "Pendente → Em Andamento"
```

### 3. **Dashboard Badge Update**
```
NotificacoesProvider.carregarNotificacoes() executado
  ↓
totalNaoLidas calculado (notificacoes.where((n) => !n.lida).length)
  ↓
Consumer<NotificacoesProvider> rebuilds
  ↓
Badge mostra contador se > 0
  ↓
User tapa em badge → Navigator.pushNamed(context, '/notificacoes')
```

---

## 📱 UX Patterns

### Notificação Lida/Não Lida
- **Não lida**: Fundo mais claro, sem botão "Ler"
- **Lida**: Transparência aumentada
- **Tap**: Marcar como lida + Navegar para solicitação

### Dismissível (Swipe)
```
Swipe left
  ↓
Mostrar ícone delete em vermelho
  ↓
Confirmação: "Deletar notificação?"
  ↓
DELETE /api/notificacoes/{id}
  ↓
Remove da lista local + notifyListeners()
```

### Tempo Relativo
```dart
// Helper function em notifications_screen.dart
String _getRelativeTime(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);
  
  if (diff.inMinutes < 1) return 'Agora';
  if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}m';
  if (diff.inHours < 24) return 'Há ${diff.inHours}h';
  if (diff.inDays < 7) return 'Há ${diff.inDays}d';
  return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
```

---

## 📂 Estrutura de Arquivos

```
lib/
├── models/
│   ├── models.dart                    # Notificacao class
│   └── enums.dart                     # TipoNotificacao + Extension
├── services/
│   └── api_service.dart               # criarNotificacao(), etc (6 métodos)
├── providers/
│   └── notificacoes_provider.dart     # State + 5 generators
├── screens/
│   ├── core/
│   │   ├── dashboard_screen.dart      # Badge + carregarNotificacoes()
│   │   └── maintenance_detail_screen.dart  # gerarNotificacao*() calls
│   └── utility/
│       └── notifications_screen.dart  # Full UI (1107 linhas)
└── main.dart                          # Route: '/notificacoes'
```

---

## 🔧 Integração com Componentes Existentes

### AuthProvider
- Obtém usuarioAtual para authorId/authorName nos geradores
- Usa usuarioTipo para determinar quem notificar

### SolicitacoesProvider
- Fornece solicitacao.moradorId para notificação
- Fornece solicitacao.responsavelId para notificação de atribuição
- Já executa após atualizarSolicitacao() sucesso

### DashboardScreen
- Carrega notificações em initState
- Exibe badge com totalNaoLidas
- Tap no badge navega para /notificacoes

---

## ✅ Checklist de Funcionalidades

- [x] Enum `TipoNotificacao` com 8 tipos
- [x] Extension `TipoNotificacaoExtension` com toPortuguese() + getIcon()
- [x] `ApiService.criarNotificacao()` POST method
- [x] `ApiService.marcarNotificacaoLida()` PUT method
- [x] `ApiService.marcarTodasNotificacoesLidas()` PUT method
- [x] `ApiService.deletarNotificacao()` DELETE method
- [x] `NotificacoesProvider` com 5 generators (comentario, status, atribuicao, prazo, abertura)
- [x] `NotificationsScreen` com filtros, dismissible, badge, relative time
- [x] Integração em `maintenance_detail_screen.dart` (_adicionarComentario, _alterarStatus, _salvarEdicao)
- [x] Badge de notificações no `dashboard_screen.dart`
- [x] Rota `/notificacoes` em `main.dart`

---

## 🚀 Como Usar

### 1. **Gerar Notificação Manualmente**
```dart
final notificacoesProvider = context.read<NotificacoesProvider>();
await notificacoesProvider.gerarNotificacaoComentario(
  solicitacaoId: '123',
  titulo: 'Novo comentário',
  mensagem: 'Texto do comentário',
  authorId: 'userA',
  authorName: 'João',
  ehInterno: false,
  usuariosParaNotificar: ['userB', 'userC'],
);
```

### 2. **Carregar Notificações**
```dart
@override
void initState() {
  super.initState();
  context.read<NotificacoesProvider>().carregarNotificacoes();
}
```

### 3. **Listenar Mudanças**
```dart
Consumer<NotificacoesProvider>(
  builder: (context, notificacoesProvider, _) {
    return Text('Não lidas: ${notificacoesProvider.totalNaoLidas}');
  },
)
```

### 4. **Navegar para Tela de Notificações**
```dart
Navigator.pushNamed(context, '/notificacoes');
```

---

## 🐛 Troubleshooting

| Problema | Solução |
|----------|----------|
| Notificações não aparecem | Verificar se `carregarNotificacoes()` é chamado no initState |
| Badge não atualiza | Garantir que `notifyListeners()` é chamado após atualização |
| Comentário não gera notificação | Verificar se `ehInterno = true` (filtra internos) |
| API retorna 401 | Token expirado → logout automático requerido |
| Integração lenta | Considerar cache local ou workers em background |

---

## 📝 Notas Importantes

1. **Filtros Cliente-Side**: Notificações filtradas no provider, não no backend
2. **Timestamp UTC**: Backend retorna `criadoEm` em UTC, convertido localmente
3. **Morador Privacidade**: Moradores não veem comentários marcados como `interno=true`
4. **Admin Vê Tudo**: Administradores recebem notificações de todas as solicitações
5. **Funcionário Responsável**: Apenas funcionário atribuído recebe notificações de sua solicitação

---

## 🎯 Próximas Fases (Futuro)

- [ ] Notificações push (Firebase Cloud Messaging)
- [ ] Agendamento de notificações (ex: lembrete 24h antes do prazo)
- [ ] Preferências de notificação (usuário escolhe quais receber)
- [ ] Notificações em tempo real (WebSocket/SignalR)
- [ ] Arquivo de notificações (mostrar histórico > 30 dias)
- [ ] Categorização por solicitação (notificações agrupadas)
- [ ] Sound + vibration para notificações críticas

---

**Data de Atualização**: 21 de Janeiro de 2026  
**Status**: ✅ Pronto para Produção  
**Feedback**: Testar fluxo completo antes do deploy

