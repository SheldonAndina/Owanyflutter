## PR: Corrige condição de corrida ao carregar apartamento

Resumo
------
- Objetivo: evitar que respostas assíncronas obsoletas sobrescrevam o estado atual do `Apartamento` no frontend.
- Aborda: sincronização entre endpoints `/api/apartamentos/{id}` (meta) e `/api/apartamentos/{id}/ocupantes` (autoridade) e comportamento após operações que afetam moradores (vincular, transferir, registrar-saida, deletar).

O que foi alterado / recomendado
--------------------------------
- Frontend: adicionar um guard em `carregarApartamento` chamado `_currentLoadingApartamentoId` e checar o guard após cada `await` para ignorar respostas antigas; sempre recarregar os ocupantes usando `/ocupantes` (com fallback `/moradores?apartamentoId=`).
- Backend: já aplicado no repositório: `registrar-saida` e updates que fazem desvinculação agora são transacionais e reavaliam o estado do apartamento por contagem no banco (Count), garantindo que quando o endpoint responder 200/201 o banco reflete a mudança.

Snippet sugerido (pode colar no provider):

```dart
// Guard para evitar sobrescrita por respostas antigas
String? _currentLoadingApartamentoId;

Future<void> carregarApartamento(String id) async {
  final loadingId = id;
  _currentLoadingApartamentoId = loadingId;

  final meta = await _apiService.getApartamento(id);
  if (meta != null) {
    final itens = await _apiService.getItensApartamento(id);
    if (_currentLoadingApartamentoId != loadingId) return; // ignore stale

    var moradores = await _apiService.getOcupantes(id);
    if (_currentLoadingApartamentoId != loadingId) return; // ignore stale

    if (moradores.isEmpty) {
      final fallback = await _apiService.getMoradores(apartamentoId: id);
      if (_currentLoadingApartamentoId != loadingId) return;
      if (fallback.isNotEmpty) moradores = fallback;
    }

    _apartamentoAtual = meta.copyWith(
      itens: itens.isNotEmpty ? itens : null,
      moradores: moradores.isNotEmpty ? moradores : null,
      quantidadeMoradores: moradores.length,
    );
  }

  if (_currentLoadingApartamentoId == loadingId) {
    _currentLoadingApartamentoId = null;
    notifyListeners();
  }
}
```

Checklist de implementação (frontend)
------------------------------------
- Substituir chamadas diretas a `ApiService` para criar/atualizar/deletar moradores por métodos do `MoradoresProvider` que, ao terminar, chamem `await apartamentosProvider.carregarApartamento(aptId)`.
- Garantir que `carregarApartamento` do `ApartamentosProvider` contenha o guard e sempre busque `/ocupantes` como fonte de verdade.
- Adicionar feedback visual (loading) ao usuário durante operações críticas para reduzir ações paralelas via UI.

Testes recomendados
-------------------
- Manual:
  - Vincular morador → verificar `POST /api/moradores/vincular` retorna 201 e logo `GET /api/apartamentos/{id}/ocupantes` contém o morador.
  - Registrar saída → `POST /api/historicoocupacao/{id}/registrar-saida` retorna 201 e em seguida `GET /api/apartamentos/{id}/ocupantes` não contém o morador; `GET /api/apartamentos` mostra estado correto.
  - Testar ações concorrentes: abrir detalhe e executar saída imediatamente; validar que não há morador fantasma.
- Automáticos: testes de integração que executem create/update/delete concurrentes e validem estado final via GET /ocupantes.

Rollout / notas de deploy
-------------------------
- Backend: já foi alterado para usar transações em `registrar-saida` e update-desvinculação. Se aplicar transações em vincular/transferência, coordene deploys para evitar versões mistas.
- Frontend: publicar patch com provider atualizado e instruir QA para executar os testes manuais acima.

Observações finais
------------------
Esta abordagem (backend transacional + frontend recarregar o recurso autoritativo) é a combinação mais robusta para evitar inconsistências visíveis ao usuário em cenários concorrentes.

Arquivo gerado pelo time de manutenção — use este texto como base para o PR description.
