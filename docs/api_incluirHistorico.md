Resumo: parâmetro `incluirHistorico` para solicitações

O backend passou a suportar o parâmetro `incluirHistorico` no endpoint:

- GET /api/apartamentos/{id}/solicitacoes?incluirHistorico=true

Comportamento:
- Sem `incluirHistorico` (padrão): retorna solicitações do apartamento especificado.
- Com `incluirHistorico=true`: quando o usuário autenticado for `Morador`, o backend retorna todas as solicitações criadas por esse morador (de qualquer apartamento), permitindo exibir histórico de apartamentos anteriores. Para outros papéis, comportamento segue as regras do servidor (normalmente filtros por apartamento/roles).

Como usar no frontend (Flutter):
- O client já passou a suportar a opção. Em telas onde deseja exibir o histórico do morador (ex: "Meu Apartamento"), enviar `incluirHistorico=true` junto à chamada que carrega solicitações.

Exemplo (implementado):
- `SolicitacoesProvider.loadSolicitacoes(apartamentoId: id, incluirHistorico: true, carregarTodas: true)` — chama `GET /api/apartamentos/{id}/solicitacoes?incluirHistorico=true` e carrega todas as páginas para garantir histórico completo.

Dica: sem `carregarTodas: true` o provider carrega apenas a primeira página de resultados; use `carregarTodas` quando quiser o histórico completo do morador.

Notas:
- Esta mudança preserva compatibilidade: chamadas que não informarem o parâmetro mantêm comportamento anterior.
- Se houver necessidade, posso atualizar outras telas para usar `incluirHistorico=true` ou adicionar um toggle no UI para o usuário alternar entre "Solicitações deste apartamento" e "Meu histórico".
