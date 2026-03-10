# 🎨 DESIGN SYSTEM – OWANY
## Guia Completo de UI/UX para Sistema de Gestão Predial

**Data**: 21 de Janeiro de 2026  
**Status**: ✅ Produção (implementação em progresso)  
**Framework**: Flutter + Material 3  
**Abordagem**: Clean Design, Corporativo, Minimalista

---

## 📋 Índice
1. [Fundamentos Visuais](#fundamentos-visuais)
2. [Paleta de Cores](#paleta-de-cores)
3. [Tipografia](#tipografia)
4. [Componentes Reutilizáveis](#componentes-reutilizáveis)
5. [Padrões de Layout](#padrões-de-layout)
6. [Guia por Tela](#guia-por-tela)
7. [Estados e Feedback](#estados-e-feedback)
8. [Checklist de Implementação](#checklist-de-implementação)

---

# 🧭 Fundamentos Visuais

## Filosofia de Design

- **Clean & Corporativo**: Sem poluição visual, foco em informação clara
- **Minimalista**: 3 cores principais, resto neutro
- **Acessível**: Alto contraste, ícones claros, feedback visual óbvio
- **Responsivo**: Mobile-first, escalável para tablet/desktop
- **Confortável**: Uso prolongado sem fadiga visual

## Princípios Core

✅ **Hierarquia clara** – Títulos > subtítulos > texto  
✅ **Espaçamento generoso** – Respira entre elementos  
✅ **Ícones outline** – Simples, não carregados  
✅ **Sombras suaves** – Elevação, não drama  
✅ **Consistência visual** – Um único padrão em toda app  

---

# 🎯 Paleta de Cores

## Cores Definidas (owany_theme.dart)

```dart
// 🔴 PRIMÁRIA
primaryOrange    = #ED7A23    // Ação, destaque, CTAs
softOrange       = #FFF1E6    // Fundo suave, destaque muito leve

// 🔵 SECUNDÁRIA
primaryBlue      = #2C7BE5    // Informação, dados, links

// ⚫ NEUTRAS
darkSlate        = #1F2937    // Texto principal (80% uso)
lightSlate       = #6B7280    // Texto secundário, placeholders
background      = #F3F4F6    // Fundo principal (cinza frio, não branco)
surface         = #EDEDF2    // Cards, containers

// 🚨 SEMÁTICAS
success          = #10B981    // ✅ Sucesso, confirmação
error            = #EF4444    // ❌ Erro, alerta crítico
warning          = #F59E0B    // ⚠️ Aviso, pendência

// 🌙 DARK MODE
darkBackground   = #0B1220
darkSurface      = #111827
darkText         = #E5E7EB
darkSubText      = #9CA3AF
```

## Uso Prático

| Elemento | Cor | Exemplo |
|----------|-----|---------|
| **Botão primário (CTA)** | primaryOrange | "Entrar", "Salvar", "Nova solicitação" |
| **Botão secundário** | Outlined + lightSlate | "Cancelar", "Voltar" |
| **Status Pendente** | warning (#F59E0B) | Badge amarelo claro |
| **Status Em Andamento** | primaryBlue (#2C7BE5) | Badge azul |
| **Status Concluído** | success (#10B981) | Badge verde |
| **Fundo de card** | surface (#EDEDF2) | Containers de informação |
| **Texto principal** | darkSlate (#1F2937) | Todos os títulos e texto corpo |
| **Texto secundário** | lightSlate (#6B7280) | Labels, hints, datas pequenas |
| **Links** | primaryBlue (#2C7BE5) | "Esqueci minha senha", "Ver todas" |
| **Borda leve** | Colors.black12 | Divisão entre elementos |

---

# 📝 Tipografia

## Fonte Recomendada
- **Font**: Inter, Roboto ou SF Pro Display
- **Fallback**: Sistema (Segoe UI no Windows, -apple-system no iOS)
- **Peso**: 400 (normal), 500 (medium), 600 (semibold), 700 (bold), 800 (extrabold)

## Hierarquia de Texto

```dart
// 1️⃣ HEADING 1 – Títulos de página
fontSize: 32, fontWeight: 800, letterSpacing: -0.4
color: darkSlate
Exemplo: "Dashboard", "Solicitações"

// 2️⃣ HEADING 2 – Subtítulos, seções
fontSize: 20, fontWeight: 700, letterSpacing: -0.2
color: darkSlate
Exemplo: "Solicitações Recentes", "Informações Gerais"

// 3️⃣ HEADING 3 – Card titles, labels importantes
fontSize: 16, fontWeight: 700
color: darkSlate
Exemplo: Título de uma solicitação, Nome de usuário

// 4️⃣ BODY STRONG – Texto corpo com ênfase
fontSize: 14, fontWeight: 600
color: darkSlate
Exemplo: Status de uma solicitação, labels em formulários

// 5️⃣ BODY – Texto corpo padrão
fontSize: 14, fontWeight: 500
color: darkSlate
Exemplo: Descrição de solicitação, conteúdo principal

// 6️⃣ BODY SMALL – Texto secundário
fontSize: 12, fontWeight: 500
color: lightSlate
Exemplo: Data, hora, texto de ajuda

// 7️⃣ CAPTION – Muito pequeno
fontSize: 11, fontWeight: 500
color: lightSlate
Exemplo: Timestamps, hints em inputs
```

## LineHeight (Espaçamento entre linhas)
- Heading: 1.1x
- Body: 1.5x  
- Caption: 1.4x

---

# 🧱 Componentes Reutilizáveis

## 1. Botões

### Botão Primário (Ação Principal)
```dart
ElevatedButton(
  onPressed: () {},
  style: OwanyTheme.primaryButtonStyle(),
  child: const Text('Salvar Solicitação'),
)
```
- **Cor de fundo**: primaryOrange (#ED7A23)
- **Cor do texto**: Branco (Colors.white)
- **Padding**: 18px vertical, padrão horizontal
- **Border radius**: 8px
- **Elevação**: 0 (flat)
- **Largura**: 100% do container (fullWidth)
- **Altura mínima**: 56px (touch-friendly)

### Botão Secundário (Ação Secundária)
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: OwanyTheme.lightSlate),
    padding: const EdgeInsets.symmetric(vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: const Text('Cancelar'),
)
```
- **Borda**: 1px solid lightSlate
- **Fundo**: Transparente
- **Texto**: darkSlate
- **Mesmas dimensões do primário**

### Botão Terciário (Ação Leve)
```dart
TextButton(
  onPressed: () {},
  child: const Text('Esqueci minha senha'),
)
```
- **Sem borda, sem fundo**
- **Texto**: primaryOrange (clicável)
- **Hover**: Fundo muito suave (Colors.black.withOpacity(0.05))

### Estado Disabled (Desativado)
```dart
ElevatedButton(
  onPressed: null, // null = disabled
  child: const Text('Salvar'),
)
```
- **Opacidade**: 0.5
- **Cursor**: notAllowed

---

## 2. Cards

### Card Padrão (Informação)
```dart
Container(
  decoration: OwanyTheme.cardDecoration(),
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Título do Card', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Conteúdo...', style: Theme.of(context).textTheme.bodyMedium),
    ],
  ),
)
```
- **Fundo**: surface (#EDEDF2)
- **Border**: 1px lightGray (Colors.black12)
- **Border radius**: 14px
- **Sombra**: Leve (blur 22, y-offset 12)
- **Padding**: 16px (interno)
- **Espaçamento externo**: 16px (entre cards)

### Card de Status (Colored Badge)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: statusColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: statusColor.withOpacity(0.3)),
  ),
  child: Text(
    'Pendente',
    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
  ),
)
```

### Card de Ícone (Stat Card com Ícone)
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: OwanyTheme.cardDecoration(),
  child: Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OwanyTheme.primaryOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.build_rounded, color: OwanyTheme.primaryOrange),
      ),
      const SizedBox(height: 12),
      const Text('42', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('Solicitações', style: TextStyle(color: OwanyTheme.lightSlate)),
    ],
  ),
)
```

---

## 3. Inputs / Formulários

### Text Input (usandoOwanyTheme.inputDecoration)
```dart
TextFormField(
  decoration: OwanyTheme.inputDecoration(
    label: 'Seu e-mail',
    icon: Icons.email_rounded,
  ),
  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
)
```
- **Fundo**: surface (#EDEDF2)
- **Border**: 1px lightGray (enabled), 2px primaryOrange (focused)
- **Border radius**: 8px
- **Altura**: 56px mínimo
- **Padding**: 16px horizontal, 18px vertical
- **Ícone**: Prefixx em primaryOrange

### Dropdown / Select
```dart
DropdownButtonFormField<String>(
  value: selectedValue,
  items: const [
    DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
    DropdownMenuItem(value: 'andamento', child: Text('Em Andamento')),
  ],
  onChanged: (value) {},
  decoration: OwanyTheme.inputDecoration(label: 'Status'),
)
```
- **Mesmos padrões do Text Input**
- **Ícone dropdown**: Direita da field

### Checkbox / Switch
```dart
CheckboxListTile(
  title: const Text('Comentário interno'),
  value: isInternal,
  onChanged: (value) {},
  activeColor: OwanyTheme.primaryOrange,
  controlAffinity: ListTileControlAffinity.leading,
)
```
- **Checkbox color**: primaryOrange
- **Padding**: 12px
- **Label font**: 14px medium

### Radio Button
```dart
RadioListTile<String>(
  title: const Text('Morador'),
  value: 'morador',
  groupValue: selectedRole,
  onChanged: (value) {},
  activeColor: OwanyTheme.primaryOrange,
)
```
- **Radio color**: primaryOrange
- **Espaçamento**: 12px

---

## 4. AppBar / Header

### AppBar Padrão
```dart
AppBar(
  title: const Text('Solicitações'),
  backgroundColor: OwanyTheme.surface,
  elevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () {},
    ),
  ],
)
```
- **Fundo**: surface (#EDEDF2)
- **Texto**: darkSlate
- **Elevação**: 0 (flat)
- **Ícones**: Outline, tamanho 24

### SliverAppBar (Scrollable com Gradient)
```dart
SliverAppBar(
  expandedHeight: 200,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.primaryOrange.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bem-vindo de volta',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    )),
            const SizedBox(height: 8),
            Text('João Silva',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    )),
          ],
        ),
      ),
    ),
  ),
)
```

---

## 5. Ícones

### Paleta de Ícones Recomendados

| Ação | Ícone | Uso |
|------|-------|-----|
| Adicionar | `Icons.add_rounded` | Novo item, CTA |
| Voltar | `Icons.arrow_back_ios_new_rounded` | Navegação |
| Buscar | `Icons.search_rounded` | Campo de busca |
| Mais opções | `Icons.more_vert_rounded` | Menu contextual |
| Editar | `Icons.edit_rounded` | Edição |
| Deletar | `Icons.delete_outline_rounded` | Remover |
| Notificação | `Icons.notifications_none_rounded` | Alertas |
| Usuário | `Icons.person_rounded` | Perfil |
| Configurações | `Icons.settings_rounded` | Preferências |
| Logout | `Icons.logout_rounded` | Sair |
| Sucesso | `Icons.check_circle_rounded` | Confirmação |
| Erro | `Icons.error_outline_rounded` | Problema |
| Aviso | `Icons.warning_rounded` | Alerta |
| Info | `Icons.info_rounded` | Informação |
| Fechar | `Icons.close_rounded` | Dismiss |

**Padrões**:
- Todos com `_rounded` suffix
- Tamanho padrão: 24
- Tamanho pequeno: 18
- Tamanho grande: 32
- Cor padrão: darkSlate, primária ou semântica

---

## 6. Navegação

### Bottom Navigation (para móvel)
```dart
BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Solicitações'),
    BottomNavigationBarItem(icon: Icon(Icons.domain_rounded), label: 'Apartamentos'),
    BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
  ],
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  type: BottomNavigationBarType.fixed,
  backgroundColor: OwanyTheme.surface,
  selectedItemColor: OwanyTheme.primaryOrange,
  unselectedItemColor: OwanyTheme.lightSlate,
)
```
- **Fundo**: surface (#EDEDF2)
- **Ícone selecionado**: primaryOrange
- **Ícone não selecionado**: lightSlate
- **Tipo**: fixed (sempre mostra labels)

### Drawer Lateral (para admin/desktop)
```dart
Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withOpacity(0.7)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(child: Text('JS')),
            const SizedBox(height: 12),
            const Text('João Silva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.home_rounded),
        title: const Text('Dashboard'),
        onTap: () => Navigator.pushNamed(context, '/dashboard'),
      ),
      // Mais itens...
    ],
  ),
)
```

---

## 7. Diálogos e Modais

### Alert Dialog (Aviso/Confirmação)
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirmar ação'),
    content: const Text('Tem certeza que deseja deletar esta solicitação?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar', style: TextStyle(color: OwanyTheme.lightSlate)),
      ),
      ElevatedButton(
        onPressed: () {
          // Ação
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(backgroundColor: OwanyTheme.error),
        child: const Text('Deletar'),
      ),
    ],
  ),
)
```
- **Title font**: 18px bold
- **Content font**: 14px medium
- **Buttons**: Standard ElevatedButton + TextButton
- **Border radius**: 12px
- **Padding**: 24px

### Bottom Sheet (Ações contextuais)
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit_rounded),
          title: const Text('Editar'),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: OwanyTheme.error),
          title: const Text('Deletar', style: TextStyle(color: OwanyTheme.error)),
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  ),
)
```

---

## 8. Snackbars e Toasts

### Snackbar de Sucesso
```dart
ScaffoldMessenger.of(context).showSnackBar(
  OwanyTheme.snackBar('Solicitação criada com sucesso!'),
)
```
- **Fundo**: success (#10B981)
- **Texto**: Branco, bold
- **Posição**: Bottom, floating
- **Duração**: 3 segundos

### Snackbar de Erro
```dart
ScaffoldMessenger.of(context).showSnackBar(
  OwanyTheme.snackBar('Erro ao salvar. Tente novamente.', isError: true),
)
```
- **Fundo**: error (#EF4444)
- **Restante**: igual ao sucesso

---

## 9. Loading e Estados Vazios

### Loading Spinner
```dart
const Center(
  child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation(OwanyTheme.primaryOrange),
  ),
)
```
- **Cor**: primaryOrange
- **Tamanho**: 40 (padrão)

### Shimmer Loading (Skeleton)
```dart
Container(
  height: 100,
  decoration: BoxDecoration(
    color: OwanyTheme.surface,
    borderRadius: BorderRadius.circular(14),
  ),
)
// Usar pacote: shimmer 2.0.0+
```

### Empty State
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 16),
      Text('Nenhuma solicitação', style: TextStyle(color: OwanyTheme.lightSlate)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () {},
        style: OwanyTheme.primaryButtonStyle(),
        child: const Text('Criar primeira solicitação'),
      ),
    ],
  ),
)
```

---

# 📐 Padrões de Layout

## Spacing (Margens e Paddings)

```dart
// ESPAÇAMENTO PADRÃO
const SizedBox(height: 8),    // Muito pequeno (entre elementos)
const SizedBox(height: 12),   // Pequeno (entre linhas)
const SizedBox(height: 16),   // Padrão (entre seções)
const SizedBox(height: 24),   // Grande (entre cards)
const SizedBox(height: 32),   // Muito grande (entre grandes blocos)

// PADDING PADRÃO
padding: const EdgeInsets.all(16),              // Geral
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Cards
padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12), // Lists
```

## Grid e Layouts

### Grid de Cards (Stats)
```dart
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  children: statCards,
)
```
- **Desktop**: 4 colunas
- **Tablet**: 3 colunas
- **Mobile**: 2 colunas
- **Espaçamento**: 12px entre itens

### Lista de Cards
```dart
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  padding: const EdgeInsets.all(16),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(...),
    );
  },
)
```

### CustomScrollView (Scroll infinito com header)
```dart
CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
    SliverAppBar(...),
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(...),
    ),
  ],
)
```

---

## Responsividade

```dart
// Helper para detectar screen size
bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

// Exemplo de uso
child: isMobile(context)
  ? SingleChildScrollView(...) // Mobile: scrollable
  : Row(...), // Desktop: lado a lado
```

---

# 🖥️ Guia por Tela

## 1️⃣ LOGIN SCREEN

### Objetivo
Permitir autenticação simples, clara e segura.

### Layout
```
┌─────────────────────────────┐
│                             │
│       LOGO OWANY (48x48)    │
│                             │
├─────────────────────────────┤
│                             │
│  "Bem-vindo de volta"       │  ← subtitle (12px, gray)
│                             │
│  Campo: Nome de usuário     │
│  Campo: Senha               │
│                             │
│  ☐ Lembrar-me              │
│                             │
│  [  ENTRAR  ] (fullWidth)   │  ← primaryOrange, 56px altura
│                             │
│  Esqueci minha senha?       │  ← TextButton em primaryBlue
│                             │
│  Não tem conta? Registrar   │  ← TextButton + primaryOrange
│                             │
└─────────────────────────────┘
```

### Componentes
- **Logo**: Centrada, 48x48px
- **Título**: "Bem-vindo de volta" (14px, lightSlate)
- **Inputs**: 
  - Username (icon: person_rounded)
  - Password (icon: lock_rounded, obscured)
  - Validation: error message em vermelho (11px)
- **Checkbox**: "Lembrar-me" (primaryOrange quando checked)
- **Botão Entrar**: Fullwidth, primaryOrange, 56px
- **Links**: TextButton em primaryBlue para "Esqueci minha senha?" e "Registrar"

### Estados
- **Loading**: Spinner dentro do botão, desativado
- **Erro**: SnackBar com mensagem amigável
- **Sucesso**: Navega para /dashboard

### Animações
- FadeIn ao carregar a tela
- Bounce no focus dos inputs

---

## 2️⃣ DASHBOARD SCREEN ✅ (Já Implementado)

### Status: MODERNIZADO
O dashboard já tem:
- ✅ SliverAppBar com gradient 3-cores
- ✅ Stats cards animados
- ✅ Quick actions cards
- ✅ Lista de solicitações recentes
- ✅ Animações staggered

### Melhorias Futuras
- Adicionar fundo suave na SliverAppBar
- Considerar loading skeleton para primeira carga

---

## 3️⃣ LISTA DE SOLICITAÇÕES

### Objetivo
Listar todas as solicitações com busca, filtro e navegação rápida.

### Layout
```
┌──────────────────────────────┐
│ ← Dashboard    Solicitações   │ ← AppBar padrão
├──────────────────────────────┤
│ [  🔍 Buscar solicitação...] │ ← SearchBar
├──────────────────────────────┤
│ Filtrar:                     │
│ [Todos] [Pendente] [Andando] │ ← Chips, scrollable H
│ [Concluído]                  │
├──────────────────────────────┤
│ Solicitações (12)            │
├──────────────────────────────┤
│                              │
│ ┌────────────────────────────┐│
│ │ ⚠️ Vazamento na cozinha   ││ ← Card com left border
│ │ Apt 502 | Bloco A          ││
│ │ Pendente  |  21/01/2026    ││ ← Status badge + data
│ └────────────────────────────┘│
│                              │
│ ┌────────────────────────────┐│
│ │ ⚙️ Manutencao do elevador ││
│ │ Apt 301 | Bloco B          ││
│ │ Em Andamento | 20/01/2026  ││
│ └────────────────────────────┘│
│                              │
│ [  Carregar mais...  ]       │ ← Pagination
│                              │
└──────────────────────────────┘
```

### Componentes
- **AppBar**: Padrão com título "Solicitações"
- **SearchBar**: Input com icon search, placeholder "Buscar por título"
- **Chips de Filtro**: 
  - Todos (default selected, primaryOrange background)
  - Pendente (warning color)
  - Em Andamento (primaryBlue)
  - Concluído (success color)
- **Cards de Solicitação**:
  - Left border (4px) na cor do status
  - Título (14px bold)
  - Localização (Apt + Bloco, 12px gray)
  - Status badge + Data em linha
  - Ripple effect ao tocar

### Funcionalidades
- Busca em tempo real
- Filtro por status
- Paginação (lazy load)
- Tap para abrir detalhe

### Estados
- Empty: "Nenhuma solicitação encontrada"
- Loading: Shimmer cards
- Error: Mensagem com retry

---

## 4️⃣ DETALHE DA SOLICITAÇÃO

### Objetivo
Visualizar todos os detalhes, histórico, comentários e atualizar status.

### Layout
```
┌────────────────────────────────────┐
│ ← Solicitações   [⋮] Mais opções  │ ← AppBar com menu
├────────────────────────────────────┤
│ GRADIENT HEADER (primaryOrange)     │
│ ⚠️ Vazamento na cozinha            │ ← Título grande (white)
│ Bloco A | Apt 502 | Criado há 2d   │ ← Info (white, smaller)
├────────────────────────────────────┤
│ STATUS: Pendente                   │ ← Badge grande (warning)
├────────────────────────────────────┤
│                                    │
│ INFORMAÇÕES GERAIS                 │ ← Section title (16px bold)
│ ┌────────────────────────────────┐ │
│ │ Descrição                      │ │
│ │ Vazamento visível na parede    │ │
│ │ da cozinha, próximo ao fregadô │ │
│ │                                │ │
│ │ Criado: 21/01/2026 10:30       │ │
│ │ Prazo: 25/01/2026             │ │
│ └────────────────────────────────┘ │
│                                    │
│ APARTAMENTO & MORADOR              │
│ ┌────────────────────────────────┐ │
│ │ Apartamento: 502               │ │
│ │ Bloco: A | Andar: 5            │ │
│ │ Morador: Maria Silva           │ │
│ │ Telefone: (11) 98765-4321      │ │
│ └────────────────────────────────┘ │
│                                    │
│ RESPONSÁVEL                        │
│ ┌────────────────────────────────┐ │
│ │ João Pereira (Funcionário)     │ │
│ │ Atualizado: 21/01/2026 14:00   │ │
│ └────────────────────────────────┘ │
│                                    │
│ HISTÓRICO DE STATUS (Timeline)     │
│ ┌────────────────────────────────┐ │
│ │ 🟠 Pendente                    │ │
│ │    21/01/2026 10:30            │ │
│ │    Criada por: Admin           │ │
│ └────────────────────────────────┘ │
│                                    │
│ COMENTÁRIOS (5)                    │ ← Section title
│ ┌────────────────────────────────┐ │
│ │ Maria Silva (Morador)          │ │
│ │ 21/01/2026 10:45               │ │
│ │                                │ │
│ │ "Já tentei fechar a torneira   │ │
│ │  mas continua vazando."        │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ João Pereira (Funcionário)     │ │
│ │ 21/01/2026 14:00  🔒 Interno  │ │
│ │                                │ │
│ │ "Será necessário chamar        │ │
│ │  encanador especializado."     │ │
│ └────────────────────────────────┘ │
│                                    │
│ ADICIONAR COMENTÁRIO               │
│ ┌────────────────────────────────┐ │
│ │ [TextField com hint]           │ │
│ │ ☐ Comentário interno          │ │
│ │ [ Enviar ] [ Cancelar ]        │ │
│ └────────────────────────────────┘ │
│                                    │
│ AÇÕES FIXAS (Bottom)               │
│ [ Atualizar Status ] [ Editar ]    │ ← Buttons fullWidth
│                                    │
└────────────────────────────────────┘
```

### Componentes
- **Header Gradient**: SliverAppBar com gradient primaryOrange
- **Status Badge**: Grande, com cor semântica
- **Section Cards**: Info, Apt, Responsável, Histórico
- **Timeline**: Vertical com ícones e datas
- **Comentários**: Balões estilo chat, com diferenciação visual para "interno"
- **Comment Input**: TextField fixo na base com checkbox "Interno"
- **Action Buttons**: Fullwidth na base: "Atualizar Status", "Editar"

### Funcionalidades
- Visualizar histórico de mudanças
- Adicionar comentários
- Atualizar status (dropdown/modal)
- Editar solicitação
- Deletar (com confirmação)

---

## 5️⃣ CRIAR/EDITAR SOLICITAÇÃO

### Objetivo
Formulário limpo e intuitivo para criar ou editar solicitações.

### Layout
```
┌────────────────────────────────┐
│ ← Dashboard    Nova Solicitação│
├────────────────────────────────┤
│                                │
│ TÍTULO                         │ ← Section
│ ┌────────────────────────────┐ │
│ │ Campo: Título *            │ │
│ │ (ex: Vazamento na cozinha) │ │
│ └────────────────────────────┘ │
│                                │
│ DESCRIÇÃO DETALHADA            │
│ ┌────────────────────────────┐ │
│ │ Campo: Descrição *         │ │
│ │ (multiline, 5 linhas min)  │ │
│ └────────────────────────────┘ │
│                                │
│ APARTAMENTO                    │
│ ┌────────────────────────────┐ │
│ │ Dropdown: Selecione apt... │ │
│ │ (502 - Bloco A - Maria S.) │ │
│ └────────────────────────────┘ │
│                                │
│ PRAZO PARA CONCLUSÃO           │
│ ┌────────────────────────────┐ │
│ │ Picker: Data (dd/mm/yyyy)  │ │
│ │ [25/01/2026]               │ │
│ └────────────────────────────┘ │
│                                │
│ PRIORIDADE (opcional)          │
│ ○ Baixa  ○ Normal  ○ Alta      │ ← Radio buttons
│                                │
│ RESPONSÁVEL (Admin only)       │
│ ┌────────────────────────────┐ │
│ │ Dropdown: Selecione usu... │ │
│ └────────────────────────────┘ │
│                                │
│ ANEXOS (opcional)              │
│ [ + Adicionar arquivo ]        │ ← Button
│                                │
│                                │
│ [  SALVAR  ]  [ CANCELAR ]     │ ← Full width buttons
│                                │
└────────────────────────────────┘
```

### Componentes
- **Inputs**: 
  - Título (required, text)
  - Descrição (required, multiline, 5 linhas)
  - Apartamento (required, dropdown)
  - Prazo (required, date picker)
  - Prioridade (optional, radio)
  - Responsável (admin only, dropdown)
  - Anexos (optional, file picker)
- **Validação**: Red error text under each field
- **Required indicator**: Asterisco vermelho (*) no label

### Funcionalidades
- Validação em tempo real
- DatePicker nativo (plataforma específico)
- FilePicker para anexos
- Preview de anexos
- Salvar como rascunho (opção extra)

---

## 6️⃣ COMENTÁRIOS (Sub-tela ou Modal)

### Objetivo
Visualizar e gerenciar comentários de forma clara.

### Estilo Chat
```
┌──────────────────────────────┐
│ ← Detalhes    Comentários (5)│
├──────────────────────────────┤
│                              │
│  Maria Silva (Morador)       │ ← Nome + tipo em cinza
│  21/01 10:45                 │ ← Data/hora
│  "Já tentei fechar a torneira│ │ Balão com fundo suave
│   mas continua vazando."     │ │ (surface)
│                              │
│               João Pereira ← │ ← Alinhado à direita (current user)
│               (Funcionário)  │
│               21/01 14:00    │
│  "Será necessário chamar     │ │ Balão com fundo  
│   encanador especializado.   │ │ primaryOrange.withOpacity(0.1)
│   🔒 Interno"                │ │ 🔒 Badge "Interno"
│                              │
│  Maria Silva                 │ ← Alinhado à esquerda
│  (Morador)                   │
│  21/01 15:30                 │
│  "Muito bem, obrigada!"      │
│                              │
├──────────────────────────────┤
│                              │
│ ESCREVER COMENTÁRIO          │
│ ┌────────────────────────────┐
│ │ [TextField]                │
│ │ ☐ Comentário interno (🔒) │
│ │                            │
│ │ [ Enviar ]  [ Cancelar ]   │
│ └────────────────────────────┘
│                              │
└──────────────────────────────┘
```

### Componentes
- **Balão de Comentário**:
  - Nome + tipo do usuário (12px bold)
  - Data/hora (11px gray)
  - Texto do comentário (14px)
  - Badge 🔒 se interno (apenas admin/funcionário veem)
  - Fundo: surface se alheio, primária suave se do próprio usuário
- **TextField**: Multiline, placeholder "Adicionar comentário..."
- **Checkbox Interno**: Apenas visível para admin/funcionário

### Funcionalidades
- Listar comentários em ordem cronológica
- Filtrar "Apenas comentários internos" (admin)
- Deletar comentário próprio
- Editar comentário próprio (com indicador "editado")

---

## 7️⃣ APARTAMENTOS

### Lista
```
┌────────────────────────────────┐
│ ← Dashboard    Apartamentos    │
├────────────────────────────────┤
│ [ 🔍 Buscar apartamento...]    │
│                                │
│ Filtrar:                       │
│ [Todos] [Disponível] [Ocupado] │
│                                │
│ Grid 2x2 (mobile) / 3x2 (tablet)
│                                │
│ ┌──────────────┐  ┌──────────┐ │
│ │ APT 502      │  │ APT 301  │ │
│ │ Bloco A      │  │ Bloco B  │ │
│ │ Andar 5      │  │ Andar 3  │ │
│ │              │  │          │ │
│ │ ✅ Ocupado   │  │ ⚫ Livre │ │
│ │ 2 moradores  │  │ 0 mor.  │ │
│ └──────────────┘  └──────────┘ │
│                                │
│ ┌──────────────┐  ┌──────────┐ │
│ │ APT 601      │  │ APT 401  │ │
│ │ Bloco A      │  │ Bloco C  │ │
│ │ Andar 6      │  │ Andar 4  │ │
│ │              │  │          │ │
│ │ 🔧 Manutencao│ │ ✅ Ocupado│ │
│ │ Em reforma   │  │ 1 morador│ │
│ └──────────────┘  └──────────┘ │
│                                │
│ [ + Novo Apartamento ]         │
│                                │
└────────────────────────────────┘
```

### Detalhe
```
┌────────────────────────────────┐
│ ← Apartamentos  APT 502        │
├────────────────────────────────┤
│ GRADIENT HEADER                │
│ 🏠 APARTAMENTO 502             │ ← Título
│ Bloco A | Andar 5              │
├────────────────────────────────┤
│ INFORMAÇÕES GERAIS             │
│ ┌────────────────────────────┐ │
│ │ Número: 502                │ │
│ │ Bloco: A                   │ │
│ │ Andar: 5                   │ │
│ │ Estado: Ocupado            │ │ ← Status badge
│ │ Metragem: 85 m²            │ │
│ │ Criado: 01/01/2020         │ │
│ └────────────────────────────┘ │
│                                │
│ MORADORES (2)                  │
│ ┌────────────────────────────┐ │
│ │ 👤 Maria Silva             │ │
│ │    (Proprietária)          │ │
│ │    Telefone: (11) 3123-456 │ │
│ │                            │ │
│ │ 👤 João Santos             │ │
│ │    (Locatário)             │ │
│ │    Telefone: (11) 8765-432 │ │
│ │                            │ │
│ │ [ + Adicionar Morador ]    │ │
│ └────────────────────────────┘ │
│                                │
│ ITENS DO APARTAMENTO (7)       │
│ ┌────────────────────────────┐ │
│ │ ▪ Ar condicionado          │ │
│ │ ▪ Forno elétrico           │ │
│ │ ▪ Máquina de lavar         │ │
│ │ ▪ ...                      │ │
│ │ [ Gerenciar itens ]        │ │
│ └────────────────────────────┘ │
│                                │
│ [  EDITAR  ]  [ DELETAR ]      │
│                                │
└────────────────────────────────┘
```

---

## 8️⃣ PERFIL DO USUÁRIO ✅ (Já Implementado)

### Status: MODERNIZADO
O perfil já tem:
- ✅ SliverAppBar com gradient
- ✅ Avatar animado com ScaleTransition
- ✅ Cards de informação
- ✅ Botões de ação
- ✅ CustomScrollView

---

## 9️⃣ NOTIFICAÇÕES ✅ (Já Implementado)

### Status: MODERNIZADO
Notificações já tem:
- ✅ SliverAppBar com gradient
- ✅ Type-based color coding
- ✅ Animated cards com Fade transitions
- ✅ Badges para unread

---

## 🔟 CONFIGURAÇÕES ✅ (Já Implementado)

### Status: MODERNIZADO (Recém-corrigido)
Configurações já tem:
- ✅ SliverAppBar com gradient
- ✅ 4 seções bem organizadas
- ✅ Switches e dropdowns com styling
- ✅ Staggered animations

---

## 1️⃣1️⃣ ESQUECI MINHA SENHA

### Layout
```
┌────────────────────────────────┐
│ ← Entrar  Redefinir Senha      │
├────────────────────────────────┤
│                                │
│ PASSO 1: SEU TELEFONE          │ ← Progress: 1 of 3
│ ───────────────────────        │
│                                │
│ Informe seu telefone para      │
│ receber um código de verificação
│                                │
│ ┌────────────────────────────┐ │
│ │ Campo: Telefone *          │ │
│ │ (+55) ____________         │ │
│ └────────────────────────────┘ │
│                                │
│ [ ENVIAR CÓDIGO ] [ CANCELAR ]  │
│                                │
│ ────────────────────────────────│
│                                │
│ Já tem código? [ Pular ]        │ ← TextButton
│                                │
└────────────────────────────────┘

┌────────────────────────────────┐
│ ← Entrar  Redefinir Senha      │
├────────────────────────────────┤
│                                │
│ PASSO 2: CÓDIGO DE VERIFICAÇÃO │ ← Progress: 2 of 3
│ ───────────────────────────────│
│                                │
│ Enviamos um código SMS para:    │
│ (11) 98765-4321                │ ← Masked
│                                │
│ ┌────────────────────────────┐ │
│ │ Campo: Código (6 dígitos)  │ │
│ │ [______]                   │ │
│ │ Expira em: 01:45           │ │ ← Countdown
│ └────────────────────────────┘ │
│                                │
│ [ VERIFICAR ] [ CANCELAR ]      │
│                                │
│ Não recebeu? [ Reenviar ]       │ ← TextButton
│                                │
└────────────────────────────────┘

┌────────────────────────────────┐
│ ← Entrar  Redefinir Senha      │
├────────────────────────────────┤
│                                │
│ PASSO 3: NOVA SENHA            │ ← Progress: 3 of 3
│ ──────────────────             │
│                                │
│ ┌────────────────────────────┐ │
│ │ Campo: Nova Senha *        │ │
│ │ ••••••••••                 │ │
│ │ ✓ Mínimo 8 caracteres      │ │
│ │ ✓ Mínimo 1 número          │ │
│ │ ✓ Mínimo 1 maiúscula       │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Campo: Confirmar Senha *   │ │
│ │ ••••••••••                 │ │
│ └────────────────────────────┘ │
│                                │
│ [ REDEFINIR ] [ CANCELAR ]      │
│                                │
└────────────────────────────────┘
```

### Componentes
- **Progress Indicator**: Linear progress bar (1 of 3, 2 of 3, 3 of 3)
- **Step Cards**: Cada passo em um card com background suave
- **Telefone Masked**: (11) 98765-4321 → (11) 9876-xxxx (masked)
- **Countdown Timer**: Expira em MM:SS
- **Password Strength Indicator**: Checkmarks para requisitos

---

# 🎬 Estados e Feedback

## Loading States

### Shimmer (Skeleton Loading)
```dart
// Mostrar 3 shimmer cards enquanto carrega
// Cor: surface com shimmer animation
// Altura: 100px, borderRadius: 12
```

### Spinner
```dart
// CircularProgressIndicator em primaryOrange
// Utilizar ao fazer ações (save, delete)
```

## Success States

```dart
// ✅ SnackBar em success (#10B981)
// Mensagem: "Solicitação criada com sucesso!"
// Duração: 3s, desaparece automático
```

## Error States

```dart
// ❌ SnackBar em error (#EF4444)
// Mensagem: "Erro ao salvar. Tente novamente."
// Com opção de Retry se aplicável
```

## Feedback Visual

### Hover (Desktop)
- Mudança de cor leve (primaryOrange.withOpacity(0.8))
- Sombra aumentada
- Cursor: pointer

### Pressed/Active
- Escurecimento da cor (20% mais escuro)
- Animação rápida (200ms)

### Disabled
- Opacidade: 0.5
- Cursor: notAllowed
- Sem hover effect

### Focus (Accessibility)
- Border em primaryOrange (2px)
- Outline visível
- No mobile: sem outline, apenas feedback tátil

---

# ✅ Checklist de Implementação

## Cores & Tema
- [ ] Verificar se `owany_theme.dart` tem todas as cores
- [ ] Adicionar `primaryBlue = #2C7BE5` se não existir
- [ ] Documentar cores no theme file
- [ ] Criar paleta de cores em `DESIGN_SYSTEM.md`

## Tipografia
- [ ] Font Inter/Roboto instalada no `pubspec.yaml`
- [ ] Definir text styles no tema (heading, body, caption)
- [ ] Usar TextStyle consistently em todos os screens
- [ ] Testar hierarquia em diferentes tamanhos de tela

## Componentes Reutilizáveis
- [ ] `PrimaryButton` widget customizado
- [ ] `SecondaryButton` widget customizado
- [ ] `CustomCard` com decoration padrão
- [ ] `LoadingShimmer` para estados de carregamento
- [ ] `EmptyState` widget genérico
- [ ] `ErrorDialog` widget customizado
- [ ] `SuccessSnackBar` helper

## Screens Implementadas
- [x] LoginScreen – Funcional
- [x] DashboardScreen – ✅ Modernizado
- [x] ProfileScreen – ✅ Modernizado
- [x] NotificationsScreen – ✅ Modernizado
- [x] SettingsScreen – ✅ Modernizado (recém-corrigido)
- [ ] MaintenanceListScreen – Refazer com cards modernos
- [ ] MaintenanceDetailScreen – Refazer com sections
- [ ] MaintenanceRequestScreen – Refazer com formulário limpo
- [ ] ApartmentsScreen – Refazer com grid moderno
- [ ] ApartmentDetailScreen – Refazer com seções
- [ ] CreateApartmentScreen – Formulário padronizado
- [ ] UsersScreen – Admin-only, grid/lista
- [ ] UserDetailScreen – Detalhes do usuário
- [ ] ForgotPasswordScreen – 3-step wizard
- [ ] RegisterScreen – Formulário de cadastro

## Navegação
- [ ] Bottom Navigation ou Drawer (escolher padrão)
- [ ] Rotas nomeadas em `main.dart`
- [ ] Transições suaves entre screens
- [ ] Back button funcionando corretamente

## Dark Mode
- [ ] Verificar temas em ambos light/dark
- [ ] Testar todos screens em dark mode
- [ ] Cores semânticas funcionando nos dois modos
- [ ] Shimmer visível em ambos modos

## Acessibilidade
- [ ] Labels em todos inputs
- [ ] Alt text em ícones/imagens
- [ ] Contraste de cores testado (WCAG AA)
- [ ] Tamanhos de touch targets ≥ 48x48px
- [ ] Focus visible em navegação por teclado

## Responsividade
- [ ] Mobile (360px-600px): Testes em emulador
- [ ] Tablet (600px-1200px): Layout adaptativo
- [ ] Desktop (>1200px): Layout side-by-side onde faz sentido
- [ ] Testar orientações portrait/landscape

## Performance
- [ ] Lazy loading em listas longas
- [ ] Pagination implementada
- [ ] Shimmer em vez de delay branco
- [ ] Imagens otimizadas
- [ ] BuildContext.watch() apenas onde necessário

## Testes
- [ ] Visual regression testing (screenshots)
- [ ] Testar todos estados de erro
- [ ] Testar loading states
- [ ] Testar empty states
- [ ] Testar navegação entre screens
- [ ] Testar role-based UI (Admin/Funcionário/Morador)

---

# 📚 Referências de Código

## Padrão de Tela Completa

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      OwanyTheme.primaryOrange,
                      OwanyTheme.primaryOrange.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Conteúdo aqui
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

**Última Atualização**: 21 de Janeiro de 2026  
**Versão**: 1.0  
**Autor**: Design System Team – Owany  
**Status**: ✅ Pronto para implementação

