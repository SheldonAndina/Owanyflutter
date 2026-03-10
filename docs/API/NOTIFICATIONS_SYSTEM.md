# Sistema de Notificações - Implementação 🔔

**Data**: 26 January 2026  
**Status**: 🎯 Especificação Completa

---

## 📋 Regras de Negócio

### Para o MORADOR
Recebe notificação quando:
1. **Novo comentário** em uma de suas solicitações
2. **Abertura da solicitação** (quando criada/atribuída a ele)
3. **Qualquer alteração** (mudança de status, prazo limite alterado, responsável atribuído, etc)

### Para o ADMINISTRADOR
Recebe notificação quando:
1. **Comentário em qualquer solicitação** (não é dele)
2. **Mudança de status em qualquer solicitação** (não é dele)
3. **Nova solicitação criada** por qualquer morador
4. **Responsável atribuído/alterado** em qualquer solicitação

### Para o FUNCIONÁRIO
Recebe notificação quando:
1. **Novo comentário** em solicitações atribuídas a ele
2. **Atribuição de nova solicitação**
3. **Mudança de status** em solicitações que ele está responsável
4. **Prazo alterado** em suas solicitações

---

## 🔧 Implementação no NotificacoesProvider

### 1. Modelo de Notificação (models.dart)
```dart
class Notificacao {
  final String id;
  final String usuarioId;           // Quem recebe
  final String titulo;
  final String mensagem;
  final TipoNotificacao tipo;       // enum
  final String? solicitacaoId;
  final String? comentarioId;
  final bool lida;
  final DateTime criadoEm;
  final String? nomeRemetente;      // Quem gerou (para exibição)
  final String? tipoRemetente;      // Tipo do usuário que gerou
  
  // ... rest
}

enum TipoNotificacao {
  NovoComentario,
  AberturaSolicitacao,
  MudancaStatus,
  AtribuicaoResponsavel,
  AlteracaoPrazo,
  NovasolicitacaoCriada,
}
```

### 2. Métodos no NotificacoesProvider

#### `_gerarNotificacaoComentario(comentario, solicitacao, usuario)`
```dart
Future<void> _gerarNotificacaoComentario(
  Comentario comentario,
  Solicitacao solicitacao,
  Usuario usuarioAutor,
) async {
  // Para MORADOR: notifica se é sua solicitação
  if (solicitacao.moradorId == usuarioAutor.id) {
    // Não envia para o próprio morador comentando
    return;
  }
  
  // Se comentário for externo (não interno), notifica:
  if (!comentario.interno) {
    if (solicitacao.moradorId != null) {
      // Notifica o morador
      await _apiService.criarNotificacao(
        usuarioId: solicitacao.moradorId,
        titulo: 'Novo comentário: ${solicitacao.titulo}',
        mensagem: comentario.mensagem.substring(0, 50),
        tipo: TipoNotificacao.NovoComentario,
        solicitacaoId: solicitacao.id,
        nomeRemetente: usuarioAutor.nome,
        tipoRemetente: usuarioAutor.tipo.toString(),
      );
    }
  }
  
  // Para ADMIN: notifica sempre
  // Para FUNCIONÁRIO: notifica se é responsável
  if (solicitacao.responsavelId == usuarioAutor.id) {
    // Notifica admin sobre comentário
    // ...
  }
}
```

#### `_gerarNotificacaoStatusAlterado(solicitacao, statusAnterior, statusNovo, usuarioAlterador)`
```dart
Future<void> _gerarNotificacaoStatusAlterado(
  Solicitacao solicitacao,
  String statusAnterior,
  String statusNovo,
  Usuario usuarioAlterador,
) async {
  // Para MORADOR: notifica sempre
  if (solicitacao.moradorId != null && solicitacao.moradorId != usuarioAlterador.id) {
    await _apiService.criarNotificacao(
      usuarioId: solicitacao.moradorId,
      titulo: '${solicitacao.titulo} - Status alterado',
      mensagem: '$statusAnterior → $statusNovo',
      tipo: TipoNotificacao.MudancaStatus,
      solicitacaoId: solicitacao.id,
      nomeRemetente: usuarioAlterador.nome,
      tipoRemetente: usuarioAlterador.tipo.toString(),
    );
  }
  
  // Para ADMIN: notifica se não foi o admin que alterou
  // Para FUNCIONÁRIO: notifica se é responsável
}
```

#### `_gerarNotificacaoAtribuicao(solicitacao, responsavelAnterior, novoResponsavel, usuarioQueAtribuiu)`
```dart
Future<void> _gerarNotificacaoAtribuicao(
  Solicitacao solicitacao,
  String? responsavelAnteriorId,
  String novoResponsavelId,
  Usuario usuarioQueAtribuiu,
) async {
  // Notifica o novo responsável (FUNCIONÁRIO)
  if (novoResponsavelId != usuarioQueAtribuiu.id) {
    await _apiService.criarNotificacao(
      usuarioId: novoResponsavelId,
      titulo: 'Nova atribuição: ${solicitacao.titulo}',
      mensagem: 'Você foi designado como responsável',
      tipo: TipoNotificacao.AtribuicaoResponsavel,
      solicitacaoId: solicitacao.id,
      nomeRemetente: usuarioQueAtribuiu.nome,
      tipoRemetente: usuarioQueAtribuiu.tipo.toString(),
    );
  }
  
  // Notifica o responsável anterior (se houver)
  if (responsavelAnteriorId != null && responsavelAnteriorId != novoResponsavelId) {
    await _apiService.criarNotificacao(
      usuarioId: responsavelAnteriorId,
      titulo: 'Alteração de atribuição: ${solicitacao.titulo}',
      mensagem: 'Você não é mais o responsável',
      tipo: TipoNotificacao.AtribuicaoResponsavel,
      solicitacaoId: solicitacao.id,
      nomeRemetente: usuarioQueAtribuiu.nome,
      tipoRemetente: usuarioQueAtribuiu.tipo.toString(),
    );
  }
}
```

#### `_gerarNotificacaoAbertura(solicitacao, moradorId)`
```dart
Future<void> _gerarNotificacaoAbertura(
  Solicitacao solicitacao,
  String moradorId,
) async {
  // Notifica o morador quando sua solicitação é aberta/criada
  await _apiService.criarNotificacao(
    usuarioId: moradorId,
    titulo: 'Solicitação recebida: ${solicitacao.titulo}',
    mensagem: 'Sua solicitação foi registrada no sistema',
    tipo: TipoNotificacao.AberturaSolicitacao,
    solicitacaoId: solicitacao.id,
    nomeRemetente: 'Sistema',
    tipoRemetente: 'Sistema',
  );
  
  // Notifica ADMIN sobre nova solicitação
  await _apiService.criarNotificacao(
    usuarioId: 'admin_id', // Buscar admin user
    titulo: 'Nova solicitação criada',
    mensagem: '${solicitacao.titulo} - ${solicitacao.nomeMorador}',
    tipo: TipoNotificacao.NovasolicitacaoCriada,
    solicitacaoId: solicitacao.id,
    nomeRemetente: solicitacao.nomeMorador,
    tipoRemetente: 'Morador',
  );
}
```

#### `_gerarNotificacaoAlteracaoPrazo(solicitacao, prazoAnterior, novoPrazo, usuarioQueAlterou)`
```dart
Future<void> _gerarNotificacaoAlteracaoPrazo(
  Solicitacao solicitacao,
  DateTime? prazoAnterior,
  DateTime? novoPrazo,
  Usuario usuarioQueAlterou,
) async {
  // Para MORADOR
  if (solicitacao.moradorId != null) {
    await _apiService.criarNotificacao(
      usuarioId: solicitacao.moradorId,
      titulo: 'Prazo alterado: ${solicitacao.titulo}',
      mensagem: 'Novo prazo: ${_formatDate(novoPrazo)}',
      tipo: TipoNotificacao.AlteracaoPrazo,
      solicitacaoId: solicitacao.id,
      nomeRemetente: usuarioQueAlterou.nome,
      tipoRemetente: usuarioQueAlterou.tipo.toString(),
    );
  }
  
  // Para FUNCIONÁRIO responsável
  if (solicitacao.responsavelId != null) {
    await _apiService.criarNotificacao(
      usuarioId: solicitacao.responsavelId,
      titulo: 'Prazo alterado: ${solicitacao.titulo}',
      mensagem: 'Novo prazo: ${_formatDate(novoPrazo)}',
      tipo: TipoNotificacao.AlteracaoPrazo,
      solicitacaoId: solicitacao.id,
      nomeRemetente: usuarioQueAlterou.nome,
      tipoRemetente: usuarioQueAlterou.tipo.toString(),
    );
  }
}
```

### 3. Métodos Públicos

```dart
// Marcar como lida
Future<void> marcarComoLida(String notificacaoId) async {
  try {
    await _apiService.marcarNotificacaoComoLida(notificacaoId);
    final idx = _notificacoes.indexWhere((n) => n.id == notificacaoId);
    if (idx != -1) {
      _notificacoes[idx] = _notificacoes[idx].copyWith(lida: true);
      _totalNaoLidas--;
      notifyListeners();
    }
  } catch (e) {
    _errorMessage = _formatError(e);
    notifyListeners();
  }
}

// Marcar todas como lidas
Future<void> marcarTodasComoLidas() async {
  try {
    await _apiService.marcarTodasNotificacoesComoLidas();
    for (var notif in _notificacoes) {
      notif = notif.copyWith(lida: true);
    }
    _totalNaoLidas = 0;
    notifyListeners();
  } catch (e) {
    _errorMessage = _formatError(e);
    notifyListeners();
  }
}

// Deletar notificação
Future<void> deletarNotificacao(String notificacaoId) async {
  try {
    await _apiService.deletarNotificacao(notificacaoId);
    _notificacoes.removeWhere((n) => n.id == notificacaoId);
    notifyListeners();
  } catch (e) {
    _errorMessage = _formatError(e);
    notifyListeners();
  }
}
```

---

## 📱 Tela de Notificações (notifications_screen.dart)

### Features
- Lista de notificações com filtros (todas, não lidas, por tipo)
- Marca como lida ao clicar
- Swipe para deletar
- Badge com contador de não lidas na AppBar
- Navega para solicitação ao clicar

### Estrutura
```dart
class NotificationsScreen extends StatefulWidget { ... }

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filtro = 'todas'; // todas, naoLidas, comentarios, status
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          // Botão "Marcar todas como lidas"
          // Botão de filtros
        ],
      ),
      body: Consumer<NotificacoesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return _buildLoading();
          
          final notificacoes = _filtrarNotificacoes(
            provider.notificacoes,
            _filtro,
          );
          
          if (notificacoes.isEmpty) {
            return _buildVazio();
          }
          
          return ListView.builder(
            itemCount: notificacoes.length,
            itemBuilder: (context, index) {
              final notif = notificacoes[index];
              return _buildNotificacaoCard(notif, provider);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificacaoCard(Notificacao notif, NotificacoesProvider provider) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => provider.deletarNotificacao(notif.id),
      background: Container(
        color: OwanyTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: OwanyTheme.white),
      ),
      child: GestureDetector(
        onTap: () {
          provider.marcarComoLida(notif.id);
          if (notif.solicitacaoId != null) {
            Navigator.pushNamed(
              context,
              '/solicitacoes-detalhe',
              arguments: {'solicitacaoId': notif.solicitacaoId},
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.lida ? OwanyTheme.white : OwanyTheme.primaryOrange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notif.lida
                  ? OwanyTheme.borderLight.withOpacity(0.3)
                  : OwanyTheme.primaryOrange.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIconForType(notif.tipo), color: OwanyTheme.primaryOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notif.titulo,
                      style: TextStyle(
                        color: OwanyTheme.primaryBrown,
                        fontWeight: notif.lida ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!notif.lida)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: OwanyTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notif.mensagem,
                style: TextStyle(
                  color: OwanyTheme.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notif.nomeRemetente ?? 'Sistema',
                    style: TextStyle(
                      color: OwanyTheme.textSecondary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatRelativeTime(notif.criadoEm),
                    style: TextStyle(
                      color: OwanyTheme.textSecondary.withOpacity(0.6),
                      fontSize: 12,
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
  
  IconData _getIconForType(TipoNotificacao tipo) {
    switch (tipo) {
      case TipoNotificacao.NovoComentario:
        return Icons.comment_rounded;
      case TipoNotificacao.AberturaSolicitacao:
        return Icons.note_add_rounded;
      case TipoNotificacao.MudancaStatus:
        return Icons.update_rounded;
      case TipoNotificacao.AtribuicaoResponsavel:
        return Icons.assignment_rounded;
      case TipoNotificacao.AlteracaoPrazo:
        return Icons.schedule_rounded;
      case TipoNotificacao.NovasolicitacaoCriada:
        return Icons.build_rounded;
    }
  }
}
```

---

## 🔌 Integração com Solicitações

### Em `maintenance_request_screen.dart` (criar solicitação)
```dart
await provider.criarSolicitacao(...)
  .then((_) {
    // Gera notificação de abertura para morador
    NotificacoesProvider notif = context.read();
    notif._gerarNotificacaoAbertura(novaSolicitacao, widget.moradorId);
  });
```

### Em `maintenance_detail_screen.dart` (alterar status)
```dart
await provider.atualizarSolicitacao(...)
  .then((_) {
    // Gera notificação de mudança de status
    NotificacoesProvider notif = context.read();
    notif._gerarNotificacaoStatusAlterado(
      solicitacao, 
      statusAnterior, 
      novoStatus, 
      usuarioAtual
    );
  });
```

### Em `_buildCommentBar` (adicionar comentário)
```dart
await provider.adicionarComentario(...)
  .then((_) {
    // Gera notificação de novo comentário
    NotificacoesProvider notif = context.read();
    notif._gerarNotificacaoComentario(
      novoComentario,
      solicitacao,
      usuarioAtual
    );
  });
```

### Em `_buildStatusActions` ou edit dialog (alterar prazo/responsável)
```dart
await provider.atualizarSolicitacao(
  prazoLimite: novoPrazo,
  nomeResponsavel: novoResponsavel,
).then((_) {
  if (novoPrazo != null) {
    NotificacoesProvider notif = context.read();
    notif._gerarNotificacaoAlteracaoPrazo(...);
  }
});
```

---

## 📊 Tabela de Notificações

| Evento | Morador | Funcionário | Admin |
|--------|---------|-------------|-------|
| Novo Comentário | ✅ | ✅ (se responsável) | ✅ |
| Abertura Solicitação | ✅ | - | ✅ |
| Mudança Status | ✅ | ✅ (se responsável) | ✅ |
| Atribuição Responsável | - | ✅ | ✅ |
| Alteração Prazo | ✅ | ✅ (se responsável) | ✅ |
| Nova Solicitação Criada | - | - | ✅ |

---

## 🎯 Próximos Passos

1. **Atualizar Models**
   - [ ] Adicionar `TipoNotificacao` enum
   - [ ] Adicionar campos a `Notificacao` model

2. **Atualizar DTOs**
   - [ ] Criar `CriarNotificacaoRequest` DTO

3. **Atualizar ApiService**
   - [ ] `criarNotificacao()`
   - [ ] `marcarNotificacaoComoLida()`
   - [ ] `marcarTodasNotificacoesComoLidas()`
   - [ ] `deletarNotificacao()`

4. **Implementar NotificacoesProvider**
   - [ ] Adicionar métodos de geração de notificações
   - [ ] Integrar com SolicitacoesProvider

5. **Criar notifications_screen.dart**
   - [ ] Lista com filtros
   - [ ] Dismiss to delete
   - [ ] Badge de contador

6. **Integrar em Solicitações**
   - [ ] Chamar gerador de notificações ao criar/alterar

---

**Status**: 🚀 Pronto para implementação  
**Complexidade**: Média  
**Tempo Estimado**: 4-5 horas

