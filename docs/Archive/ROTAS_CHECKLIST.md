# 🗺️ Rotas - Checklist de Vinculação

## ✅ Rotas Públicas (Sem Autenticação)
- [x] `/login` → LoginScreen
- [x] `/register` → RegisterScreen
- [x] `/forgot-password` → ForgotPasswordScreen

---

## ✅ Rotas Protegidas - DASHBOARD E NOTIFICAÇÕES
| Rota | Tela | Parâmetros | Status |
|------|------|-----------|--------|
| `/dashboard` | DashboardScreen | Nenhum | ✅ |
| `/notificacoes` | NotificationsScreen | Nenhum | ✅ |

---

## ✅ MANUTENÇÕES (Solicitações)
| Rota | Tela | Parâmetros | Navegação de/para |
|------|------|-----------|------------------|
| `/solicitacoes` | MaintenanceListScreen | Nenhum | Drawer → Manutenções |
| `/solicitacoes-detalhe` | MaintenanceDetailScreen | `solicitacaoId` (String) | List → clique item |
| `/solicitacoes-nova` | MaintenanceRequestScreen | Nenhum | List → FAB ou botão |

**Verificações:**
- [x] Lista carrega todas as solicitações
- [x] Clique em item abre detalhe com histórico + comentários
- [x] Botão criar abre formulário novo
- [x] Status (Pendente/EmAndamento/Concluído) funciona
- [x] Comentários carregam corretamente

---

## ✅ APARTAMENTOS
| Rota | Tela | Parâmetros | Navegação |
|------|------|-----------|-----------|
| `/apartamentos` | ApartmentsScreen | Nenhum | Drawer → Apartamentos |
| `/apartamentos-detalhe` | ApartmentDetailScreen | `apartamentoId` (String) | List → clique item |
| `/apartamentos-novo` | CreateApartmentScreen | Nenhum | List → FAB |
| `/apartamentos-itens` | ManageApartmentItemsScreen | `{id, nome}` (Map) | Detail → botão Items |

**Verificações:**
- [x] Lista carrega apartamentos
- [x] Clique abre detalhe com info + moradores
- [x] Botão Items abre tela de gerenciamento
- [x] Permite adicionar múltiplos itens
- [x] Botão criar novo funciona

---

## ✅ USUÁRIOS (Admin/Funcionário apenas)
| Rota | Tela | Parâmetros | Navegação |
|------|------|-----------|-----------|
| `/usuarios` | UsersScreen | Nenhum | Drawer → Usuários |
| `/usuarios-detalhe` | UserDetailScreen | `usuarioId` (String) | List → clique item |
| `/usuarios-novo` | AddUserScreen | Nenhum | List → FAB |
| `/usuarios-editar` | EditUserScreen | `usuarioId` (String) | Detail → botão Editar |

**Verificações:**
- [x] Listagem carrega usuários
- [x] Clique abre detalhe com tipo de usuário (Admin/Funcionário/Síndico/Portaria/Morador/Visitante)
- [x] Criar novo funciona com todos os tipos
- [x] Editar mantém os dados
- [x] Telefone formatado como +258 XXXXXXXXX

---

## ✅ MORADORES (Gestão de Residentes)
| Rota | Tela | Parâmetros | Navegação |
|------|------|-----------|-----------|
| `/moradores` | ManageResidentsScreen | Nenhum | Drawer → Moradores |
| `/moradores-novo` | CreateMoradorScreen | Nenhum | List → FAB |
| `/moradores-detalhe` | MoradorDetailScreen | Nenhum | Detalhe passado por argumentos |

**Verificações:**
- [x] Lista carrega moradores
- [x] Criar novo vincula usuário + apartamento
- [x] **Histórico de mudança de morador** ativo (HstoricoOcupacaoScreen)
- [x] Clique em morador mostra histórico de ocupação

---

## ✅ UTILIDADES
| Rota | Tela | Parâmetros | Navegação |
|------|------|-----------|-----------|
| `/perfil` | ProfileScreen | Nenhum | AppBar → avatar ou Drawer → Perfil |
| `/configuracoes` | SettingsScreen | Nenhum | Drawer → Configurações |
| `/change-password` | ChangePasswordScreen | Nenhum | Perfil → Alterar Senha |
| `/relatorios` | ReportsScreen | Nenhum | Drawer → Relatórios (Admin/Funcionário) |

**Verificações:**
- [x] Perfil carrega dados do usuário
- [x] Configurações funciona
- [x] Mudança de senha funciona
- [x] Relatórios visíveis apenas para Admin/Funcionário

---

## 🔗 VERIFICAÇÕES DE VINCULAÇÃO

### Drawer Visibilidade
- [x] Usuários (Admin/Funcionário) veem "Administração"
- [x] Todos veem "Principal" e "Gestão de Moradores"
- [x] Rotas admin bloqueadas para Moradores

### Bottom Navigation
- [x] Dashboard, Manutenções, Apartamentos navegáveis
- [x] Ícones corretos

### FABs (Floating Action Button)
- [x] `/solicitacoes` → FAB cria nova solicitação
- [x] `/apartamentos` → FAB cria novo apartamento
- [x] `/usuarios` → FAB cria novo usuário
- [x] `/moradores` → FAB cria novo morador

### Autenticação
- [x] Logout remove token e volta a `/login`
- [x] Token injetado em todas requisições
- [x] 401 Unauthorized redireciona a login

### Transições
- [x] Todas rotas usam SlideTransition + FadeTransition
- [x] Duração 300ms forward, 250ms backward

---

## 📋 STATUS FINAL

**Todas as rotas estão vinculadas e funcionando** ✅

Próximas melhorias (se necessário):
- [ ] Deep linking (URLs diretas para rotas)
- [ ] Navigation guards (validação de estado antes de navegar)
- [ ] Named route constants em arquivo separado (rotas_constants.dart)
