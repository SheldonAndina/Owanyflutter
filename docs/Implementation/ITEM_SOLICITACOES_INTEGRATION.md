# 📋 Integração de Solicitações na Tela de Detalhe do Item

## ✅ O que foi implementado

### 1. **DTO Atualizado** - `SolicitacaoListaDto`
Adicionados dois novos campos para rastrear solicitações vinculadas a itens:
```dart
final String? itemApartamentoId;      // ID do item vinculado
final String? itemApartamentoNome;    // Nome do item vinculado
```

### 2. **Serviço** - `SolicitacoesService`
Novo método para buscar solicitações por item:
```dart
/// GET /api/Solicitacoes?itemApartamentoId={itemId}&pageSize=50
Future<PagedResult<SolicitacaoListaDto>> getSolicitacoesPorItem(
  String itemApartamentoId, {
  int pageSize = 50,
}) async { ... }
```

### 3. **Provider** - `SolicitacoesProvider`
Novos getters e método:
```dart
// Campos privados
List<SolicitacaoListaDto> _solicitacoesPorItem = [];
bool _isLoadingSolicitacoesPorItem = false;
String? _errorMessagePorItem;

// Getters
List<SolicitacaoListaDto> get solicitacoesPorItem => _solicitacoesPorItem;
bool get isLoadingSolicitacoesPorItem => _isLoadingSolicitacoesPorItem;
String? get errorMessagePorItem => _errorMessagePorItem;

// Método principal
Future<void> loadSolicitacoesPorItem(
  String itemApartamentoId, {
  bool refresh = false,
}) async { ... }
```

---

## 🛠️ Como usar na Tela de Detalhe do Item

### Exemplo Completo

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:owany_app/providers/solicitacoes_provider.dart';
import 'package:owany_app/theme/owany_theme.dart';
import 'package:owany_app/generated_l10n/app_localizations.dart';

class ItemDetalheScreen extends StatefulWidget {
  final String itemId;
  
  const ItemDetalheScreen({
    required this.itemId,
    super.key,
  });

  @override
  State<ItemDetalheScreen> createState() => _ItemDetalheScreenState();
}

class _ItemDetalheScreenState extends State<ItemDetalheScreen> {
  @override
  void initState() {
    super.initState();
    
    // Carrega solicitações vinculadas ao item assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SolicitacoesProvider>().loadSolicitacoesPorItem(
          widget.itemId,
          refresh: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Item')),
      body: Consumer<SolicitacoesProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              // ... outras seções do item ...
              
              // Seção de Solicitações Vinculadas
              SliverToBoxAdapter(
                child: _buildSolicitacoesSection(
                  context: context,
                  provider: provider,
                  l10n: l10n,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSolicitacoesSection({
    required BuildContext context,
    required SolicitacoesProvider provider,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Solicitações Vinculadas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: OwanyTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),

          // Estado de carregamento
          if (provider.isLoadingSolicitacoesPorItem)
            const Center(
              child: CircularProgressIndicator(),
            )
          
          // Erro ao carregar
          else if (provider.errorMessagePorItem != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.errorMessagePorItem!,
                style: TextStyle(color: OwanyTheme.error),
              ),
            )
          
          // Nenhuma solicitação
          else if (provider.solicitacoesPorItem.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: OwanyTheme.success,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nenhuma solicitação vinculada a este item',
                      style: TextStyle(
                        color: OwanyTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          
          // Lista de solicitações
          else
            ...provider.solicitacoesPorItem.map((solicitacao) {
              return _buildSolicitacaoCard(
                context: context,
                solicitacao: solicitacao,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/solicitacao-detalhes',
                  arguments: solicitacao.id,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSolicitacaoCard({
    required BuildContext context,
    required SolicitacaoListaDto solicitacao,
    required VoidCallback onTap,
  }) {
    final statusColor = _getStatusColor(solicitacao.status);
    final statusIcon = _getStatusIcon(solicitacao.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: OwanyTheme.cardColor(context),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitacao.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 12,
                          color: OwanyTheme.textMutedColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Apt ${solicitacao.numeroApartamento}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${solicitacao.tipoSolicitacaoNome ?? 'Sem tipo'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: OwanyTheme.textMutedColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _translateStatus(solicitacao.status, context),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: OwanyTheme.textMutedColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Concluido') return OwanyTheme.success;
    if (status == 'EmAndamento' || status == 'EmAnalise') return OwanyTheme.warning;
    if (status == 'Pendente') return OwanyTheme.error;
    return OwanyTheme.textMutedColor(context);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'Concluido') return Icons.check_circle_rounded;
    if (status == 'EmAndamento') return Icons.build_rounded;
    if (status == 'EmAnalise') return Icons.manage_search_rounded;
    return Icons.schedule_rounded;
  }

  String _translateStatus(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'Concluido') return l10n.maintenance_status_completed;
    if (status == 'EmAndamento') return l10n.maintenance_status_in_progress;
    if (status == 'EmAnalise') return l10n.maintenance_status_in_analysis;
    if (status == 'Pendente') return l10n.maintenance_status_pending;
    return status;
  }
}
```

---

## 📱 Alternativa: Buscar em Paralelo com Histórico

Se você já tem uma tela que busca o histórico do item, pode paralelizar as chamadas:

```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      // Busca histórico E solicitações em paralelo
      Future.wait([
        context.read<ItensProvider>().loadHistorico(widget.itemId),
        context.read<SolicitacoesProvider>().loadSolicitacoesPorItem(
          widget.itemId,
          refresh: true,
        ),
      ]);
    }
  });
}
```

---

## 🔗 Backend - O que Precisa Ser Implementado

O backend precisa expor um novo query parameter no endpoint de solicitações:

```csharp
// GET /api/Solicitacoes?itemApartamentoId={id}&pageSize=50
[HttpGet]
public async Task<IActionResult> GetSolicitacoes(
  [FromQuery] Guid? itemApartamentoId,  // ← NOVO
  [FromQuery] string? status,
  [FromQuery] Guid? apartamentoId,
  [FromQuery] int pageNumber = 1,
  [FromQuery] int pageSize = 20)
{
  var query = _context.Solicitacoes.AsQueryable();
  
  if (itemApartamentoId.HasValue)
    query = query.Where(s => s.ItemApartamentoId == itemApartamentoId);
  
  if (!string.IsNullOrEmpty(status))
    query = query.Where(s => s.Status == status);
    
  // ... resto da lógica
}
```

---

## ✅ Resumo das Alterações

| Arquivo | O que foi Alterado |
|---------|----------------|
| `lib/dto/solicitacoes_v2_dtos.dart` | ✅ Adicionados `itemApartamentoId` e `itemApartamentoNome` a `SolicitacaoListaDto` |
| `lib/services/solicitacoes_service.dart` | ✅ Adicionado método `getSolicitacoesPorItem()` |
| `lib/providers/solicitacoes_provider.dart` | ✅ Adicionados fields, getters e método `loadSolicitacoesPorItem()` |

---

## 🎯 Próximos Passos

1. **Backend**: Implementar filtro `itemApartamentoId` no endpoint `/api/Solicitacoes`
2. **Tela de Detalhes do Item**: Integrar widget de solicitações conforme exemplo acima
3. **Testes**: Validar que as solicitações aparecem corretamente quando vinculadas a um item
4. **i18n**: Se necessário, adicionar novos textos de localização (ex: "Solicitações Vinculadas")

---

## 📊 Estrutura de Dados (Response)

```json
{
  "sucesso": true,
  "mensagem": "OK",
  "data": {
    "items": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "titulo": "Vazamento na cozinha",
        "status": "EmAndamento",
        "nomeUsuarioCriador": "João Silva",
        "nomeResponsavel": "Carlos Técnico",
        "numeroApartamento": "301",
        "blocoApartamento": "A",
        "criadoEm": "2026-02-20T10:30:00Z",
        "prazoLimite": "2026-02-25T10:30:00Z",
        "quantidadeComentarios": 3,
        "quantidadeAnexos": 2,
        "tipoSolicitacaoNome": "Manutenção Hydraulica",
        "areaTecnicaNome": "Hidráulica",
        "itemApartamentoId": "789f0123-4567-89ab-cdef-012345678901",
        "itemApartamentoNome": "Torneira Cozinha"
      }
    ],
    "pageNumber": 1,
    "pageSize": 50,
    "totalItems": 1,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  }
}
```
