# API Reference — Owany

Este documento apresenta um resumo pronto dos endpoints da API, contratos (DTOs) principais e comportamentos importantes para integração do frontend.

Base
- Base URL: `https://{host}/api`
- Autenticação: Bearer JWT (Header `Authorization: Bearer {token}`)
- Formato: JSON
- Padrão de resposta: `ApiResponse<T>`

```json
{
  "sucesso": true|false,
  "mensagem": "string | null",
  "data": object | array | null,
  "erros": ["string"] | null
}
```

Códigos HTTP comuns: `200`, `201`, `204`, `400`, `401`, `403`, `404`, `429`, `500`.

Roles (exemplos): `Administrador`, `Funcionario`, `Sindico`, `Morador`.

---

## 1. Autenticação

### `POST /api/auth/login`
Request:
```json
{ "nomeLogin": "string", "senha": "string" }
```
Response (200): token JWT, `usuario` (id, nome, nomeLogin, telefone, tipo, ativo).

### Reset de senha via SMS
- `POST /api/auth/solicitar-reset` (telefone)
- `POST /api/auth/validar-codigo` (telefone + codigo)
- `POST /api/auth/resetar-senha` (telefone + otp + novaSenha)

Rate limiting aplicado a endpoints sensíveis (login / solicitar-reset).

---

## 2. Apartamentos

- `GET /api/apartamentos` — listagem (query: `pageNumber`, `pageSize`, `estado`, `bloco`, `andar`)
- `GET /api/apartamentos/{id}`
- `POST /api/apartamentos` (roles: `Administrador,Funcionario`)
- `PUT /api/apartamentos/{id}`
- `DELETE /api/apartamentos/{id}`

DTO resumo (exemplo):
```json
{
  "id": "guid",
  "numero": "101",
  "bloco": "A",
  "andar": 1,
  "estado": "Disponivel"
}
```

---

## 3. Moradores

- `GET /api/moradores`
- `GET /api/moradores/{id}`
- `POST /api/moradores` — cria morador e vincula ao apartamento (aciona histórico, altera estado do apto)
- `PUT /api/moradores/{id}`
- `DELETE /api/moradores/{id}`

Request `POST /api/moradores` (exemplo):
```json
{ "nome": "Joao Silva", "usuarioId": "guid", "apartamentoId": "guid", "proprietario": true }
```

---

## 4. Solicitações (V2)

- `GET /api/v1/solicitacoesv2` — paginação e filtros (`status`, `apartamentoId`, etc.)
- `GET /api/v1/solicitacoesv2/{id}` — detalhe completo
- `POST /api/v1/solicitacoesv2` — criar (campos obrigatórios: `titulo`, `moradorId`, `apartamentoId`)
- `PUT /api/v1/solicitacoesv2/{id}/status` — atualizar status (roles: `Administrador,Funcionario`)
- `POST /api/v1/solicitacoesv2/{id}/comentarios`
- `POST /api/v1/solicitacoesv2/{id}/anexos` (multipart)

Resposta padrão retorna `SolicitacaoListaDto` ou `SolicitacaoDetalheDto` contendo campos como `id`, `titulo`, `status`, `nomeUsuarioCriador`, `comentarios[]`, `anexos[]`, `historicoStatus[]`.

Observações:
- Campo `interno` em comentários indica visibilidade (apenas staff quando `true`).

---

## 5. Notificações

- `GET /api/notificacoes` — listar (query param `apenasNaoLidas` disponível)
- `GET /api/notificacoes/{id}`
- `PUT /api/notificacoes/{id}/lida`
- `PUT /api/notificacoes/marcar-todas-lidas`
- `DELETE /api/notificacoes/{id}`

DTO básico:
```json
{ "id":"guid","usuarioId":"guid","tipo":"string","titulo":"string","mensagem":"string","lida":false,"criadoEm":"ISO8601" }
```

Regras de envio:
- Notificações normais criam registro no app; se `PixMoz:Enabled` e usuário tem `ReceberSms` e telefone, o SMS é enviado.
- Quando a notificação possui `tipo == "SMS_MASSA"` (case-insensitive) o serviço suprime o envio SMS individual — envios massivos controlados por `POST /api/smsmassa/enviar`.
- Deduplication: `NotificarUsuariosIfNotDuplicateAsync` evita duplicatas usando janela temporal.

---

## 6. Itens do Apartamento

- `GET /api/itemapartamento` — listar todos (roles: `Administrador,Funcionario`)
- `GET /api/itemapartamento/{id}` — detalhe
- `GET /api/itemapartamento/apartamento/{apartamentoId}` — itens por apto
- `POST /api/itemapartamento` — cria item (gera `CodigoPatrimonio` automaticamente)
- `POST /api/itemapartamento/bulk` — criar múltiplos
- `PUT /api/itemapartamento/{id}` — atualizar (não permite remover patrimonio)
- `DELETE /api/itemapartamento/{id}` (role: `Administrador`)

Campos relevantes:
- `CodigoPatrimonio` format: `PAT-YYYYMMDD-####` (único)
- Endpoints adicionais:
  - `POST /api/itemapartamento/{id}/generate-patrimonio` — gera se ausente
  - `POST /api/itemapartamento/generate-patrimonio` — gera para todos ausentes
  - `GET /api/itemapartamento/{id}/qrcode` — retorna `image/svg+xml` (SVG QR)
  - `GET /api/itemapartamento/qrcodes-lote` — lista com `QrCodeBase64`

Exemplo `CriarItemApartamentoDto`:
```json
{ "apartamentoId":"guid","nome":"Geladeira","descricao":"...","tipo":"Eletro","quantidade":1 }
```

---

## 7. Dashboard

- `GET /api/dashboard` — dashboard resumo (cache, padrão 5 minutos)
- `GET /api/dashboard/estatisticas`
- `GET /api/dashboard/solicitacoes-kpis` — KPIs de solicitações
- `GET /api/dashboard/completo` — dashboard completo com KPIs por área

Resposta: objetos com métricas e arrays de DTOs (ex.: `GraficoMensalDto`, `DashboardManutencaoDto`, etc.).

---

## 8. SMS em Massa e Histórico

- `POST /api/smsmassa/enviar` — request exemplo:
```json
{
  "mensagem":"Texto",
  "usuarioIds":["guid1","guid2"],
  "enviarNotificacaoApp": true,
  "tituloNotificacao": "Titulo opcional"
}
```
- `GET /api/smsmassa/historico`
- `GET /api/smsmassa/destinatarios`

Rate limit e auditoria aplicados. O fluxo de envio em massa normalmente registra histórico e pode criar notificações in-app separadamente.

---

## Regras transversais e boas práticas para frontend

- GUIDs são serializados como `string` no JSON — trate como `String` no Dart.
- Sempre verificar `sucesso` no `ApiResponse` antes de desserializar `data`.
- Para uploads, usar `Content-Type: multipart/form-data`.
- Não confiar em strings de estado: use os valores documentados (ex.: `Pendente`, `EmAndamento`, `Concluido`).
- Para exibir QR retornado em base64: `data:image/svg+xml;base64,{QrCodeBase64}`.
- Ao disparar envios massivos de SMS, use `POST /api/smsmassa/enviar` — não tente simular via `Notificacao` (isso pode causar duplicação ou ausência de SMS).

---

## Exemplos rápidos (curl)

Login:
```bash
curl -X POST https://{host}/api/auth/login -H "Content-Type: application/json" -d '{"nomeLogin":"admin","senha":"Senha123"}'
```
Criar item de apartamento:
```bash
curl -X POST https://{host}/api/itemapartamento \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"apartamentoId":"guid","nome":"Geladeira"}'
```

---

Documento gerado automaticamente a partir do código atual. Verifique com o backend se houve endpoints adicionais ou alterações antes de integrar em produção.
