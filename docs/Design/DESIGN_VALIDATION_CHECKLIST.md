# 🎯 Design Validation Checklist – OWANY
## Guia de Validação Visual e UX

**Data**: 21 de Janeiro de 2026  
**Propósito**: Garantir consistência visual em todas as telas  
**Periodicidade**: Revisar antes de cada release

---

## ✅ Cores – Validação

### Paleta Implementada

- [ ] **primaryOrange (#ED7A23)** – Visível em todos CTAs
- [ ] **softOrange (#FFF1E6)** – Fundo suave em destaques
- [ ] **primaryBlue (#2C7BE5)** – Links, informações, secondary actions
- [ ] **darkSlate (#1F2937)** – Texto principal em 80% da app
- [ ] **lightSlate (#6B7280)** – Texto secundário, labels
- [ ] **background (#F3F4F6)** – Fundo principal (cinza, não branco)
- [ ] **surface (#EDEDF2)** – Cards e containers
- [ ] **success (#10B981)** – Status concluído, confirmações
- [ ] **warning (#F59E0B)** – Status pendente, avisos
- [ ] **error (#EF4444)** – Erros críticos
- [ ] Dark mode colors testadas

### Contrastes Verificados

- [ ] Texto darkSlate sobre background: ✅ WCAG AA
- [ ] Texto lightSlate sobre surface: ✅ WCAG AA
- [ ] Texto branco sobre primaryOrange: ✅ WCAG AAA
- [ ] Status badges legíveis em ambos modos

---

## 📝 Tipografia – Validação

### Hierarquia de Tamanhos

- [ ] Heading 1 (32px) – Títulos de páginas
- [ ] Heading 2 (20px) – Subtítulos, seções
- [ ] Heading 3 (16px) – Card titles
- [ ] Body Strong (14px, 600) – Texto importante
- [ ] Body (14px, 500) – Texto corpo padrão
- [ ] Body Small (12px) – Texto secundário
- [ ] Caption (11px) – Muito pequeno

### Pesos de Fonte

- [ ] 400 (regular) – Não usado (substituído por 500)
- [ ] 500 (medium) – Texto padrão
- [ ] 600 (semibold) – Ênfase
- [ ] 700 (bold) – Títulos
- [ ] 800 (extrabold) – Headings grandes

### Letter Spacing

- [ ] Headings: -0.4px (mais compacto)
- [ ] Body: 0px (normal)
- [ ] Buttons: +0.3px (mais espaçado)

### Line Height

- [ ] Heading: 1.1x
- [ ] Body: 1.5x
- [ ] Caption: 1.4x

---

## 🧱 Componentes – Validação

### Botões

#### Primary Button
- [ ] Cor: primaryOrange (#ED7A23)
- [ ] Altura: 56px mínimo
- [ ] Padding: 18px vertical
- [ ] Border radius: 8px
- [ ] Elevação: 0 (flat)
- [ ] Fullwidth (quando em forms)
- [ ] Label: Branco, bold
- [ ] Estado disabled: Opacidade 0.5
- [ ] Loading state: Spinner dentro do botão

#### Secondary Button
- [ ] Borda: 1px solid lightSlate
- [ ] Fundo: Transparente
- [ ] Texto: darkSlate
- [ ] Mesmas dimensões do primário
- [ ] Hover: Fundo cinza suave (0.05)

#### Tertiary Button
- [ ] Sem borda, sem fundo
- [ ] Texto: primaryBlue
- [ ] Hover: Fundo suave
- [ ] Cursor: pointer

### Cards

- [ ] Fundo: surface (#EDEDF2)
- [ ] Border: 1px Colors.black12
- [ ] Border radius: 14px
- [ ] Sombra: blur 22, y-offset 12
- [ ] Padding interno: 16px
- [ ] Espaçamento externo: 16px entre cards
- [ ] Ripple effect ao clicar (onde aplicável)

### Inputs

- [ ] Altura mínima: 56px
- [ ] Fundo: surface
- [ ] Border: 1px lightGray (enabled), 2px primaryOrange (focused)
- [ ] Border radius: 8px
- [ ] Ícone prefix: 20px, primaryOrange
- [ ] Label: 14px medium, lightSlate
- [ ] Placeholder: 12px, lightSlate
- [ ] Error message: 11px, error color
- [ ] Padding: 16px horizontal, 18px vertical

### AppBar

- [ ] Fundo: surface (#EDEDF2)
- [ ] Elevação: 0
- [ ] Ícones: 24px, outline
- [ ] Título: 16px bold
- [ ] Altura: 56px padrão

### SliverAppBar (Gradient Header)

- [ ] Height expandido: 200px-240px
- [ ] Gradient: 3 cores (primary → opacity → soft)
- [ ] Título: Branco, 24px-32px
- [ ] Subtítulo: Branco 70%, 14px
- [ ] Pinned: true
- [ ] Floating: true (opcional)

### Status Badges

- [ ] Padding: 12px horizontal, 8px vertical
- [ ] Border radius: 6px
- [ ] Cor de fundo: status.withOpacity(0.1)
- [ ] Borda: 1px status.withOpacity(0.3)
- [ ] Texto: bold, 12px

### Ícones

- [ ] Todos com `_rounded` suffix
- [ ] Tamanho padrão: 24
- [ ] Tamanho pequeno: 18
- [ ] Tamanho grande: 32
- [ ] Cor: Consistente com contexto

---

## 📐 Espaçamento – Validação

### Margens Padrão

- [ ] Muito pequeno: 8px (entre inline elements)
- [ ] Pequeno: 12px (entre linhas)
- [ ] Padrão: 16px (entre seções)
- [ ] Grande: 24px (entre cards)
- [ ] Muito grande: 32px (entre blocos)

### Padding Padrão

- [ ] Cards: 16px all
- [ ] AppBar: 16px-24px
- [ ] Seções: 16px all
- [ ] Lists: 16px all (com 12px between items)

### Breakpoints Responsivos

- [ ] Mobile: < 600px (fullwidth, stacked)
- [ ] Tablet: 600px-1200px (2-3 colunas)
- [ ] Desktop: > 1200px (4+ colunas, side-by-side)

---

## 🎬 Animações – Validação

### Transições Padrão

- [ ] Page transitions: 300ms ease-out
- [ ] Button hover: 200ms ease-in-out
- [ ] Card scale: 400ms easeOutQuad
- [ ] Fade in: 300ms-600ms
- [ ] Staggered animations: 100ms interval entre items

### Loading States

- [ ] Shimmer: Infinito, suave
- [ ] Spinner: 2s rotation
- [ ] Pulse: Fade in/out 1.5s

### Feedback Visual

- [ ] Ripple effect: Material ink
- [ ] Scale feedback: 98% ao pressionar
- [ ] Color change: 200ms transition

---

## 🌙 Dark Mode – Validação

### Cores Ajustadas

- [ ] Background: darkBackground (#0B1220)
- [ ] Surface: darkSurface (#111827)
- [ ] Texto: darkText (#E5E7EB)
- [ ] Subtexto: darkSubText (#9CA3AF)
- [ ] Primária: Mesmo primaryOrange (contrasta bem)
- [ ] Secundária: Mesmo primaryBlue

### Legibilidade em Dark Mode

- [ ] Contraste: ✅ WCAG AA mínimo
- [ ] Ícones visíveis
- [ ] Badges legíveis
- [ ] Inputs usáveis

### Shimmer em Dark Mode

- [ ] Base color: darkSurface
- [ ] Highlight: Cinza mais claro (~30% lighter)

---

## ♿ Acessibilidade – Validação

### Semântica

- [ ] Labels em todos inputs
- [ ] Alt text em imagens/ícones
- [ ] Headings em ordem (H1 → H2 → H3)
- [ ] Botões com descrição clara

### Interatividade

- [ ] Touch targets: ≥ 48x48px
- [ ] Focus visible: Ring outline ou highlight
- [ ] Keyboard navigation: Tab funciona
- [ ] Screen reader: Semantic HTML/widgets

### Cores

- [ ] Não depender APENAS de cor para significado
- [ ] Status indicators: Icon + color
- [ ] Links: Underline + blue (não apenas cor)

---

## 📱 Responsividade – Validação

### Mobile (< 600px)

- [ ] Telas fullwidth (sem margens largas)
- [ ] Botões: Fullwidth onde faz sentido
- [ ] Layouts: Stacked (não lado a lado)
- [ ] Texto: Legível em 360px
- [ ] Imagens: Escaladas para 100vw

### Tablet (600px-1200px)

- [ ] Grid: 2-3 colunas
- [ ] Layouts: Duas colunas possível
- [ ] Margens: 24px-32px laterais
- [ ] Texto: 1.2x maior que mobile

### Desktop (> 1200px)

- [ ] Grid: 3-4 colunas
- [ ] Layouts: Sidebar + content
- [ ] Margens: 48px-64px laterais
- [ ] Widgetss: Max-width 1400px (centrado)

---

## 🖥️ Telas por Implementar

### 1. Login Screen
- [ ] Logo centralizado (48x48)
- [ ] Campos com validação visual
- [ ] Botão primário fullwidth 56px
- [ ] Links em primaryBlue
- [ ] No dark mode: Fundo escuro, texto claro

### 2. Dashboard ✅
- [ ] SliverAppBar com gradient 3-cores
- [ ] Stats cards animadas
- [ ] Quick actions 3x1 grid
- [ ] Recent solicitações list
- [ ] Verificar spacing e alinhamento

### 3. Maintenance List
- [ ] SearchBar no topo
- [ ] Filtro chips (scrollable)
- [ ] Cards com left border colorido
- [ ] Status badge
- [ ] Pagination ou infinite scroll

### 4. Maintenance Detail
- [ ] SliverAppBar gradient header
- [ ] Seções bem separadas
- [ ] Timeline vertical
- [ ] Comentários estilo chat
- [ ] Buttons fixos na base

### 5. Create Maintenance
- [ ] Formulário em sections
- [ ] Validação em tempo real
- [ ] Date picker nativo
- [ ] File picker para anexos
- [ ] Save e Cancel buttons

### 6. Profile ✅
- [ ] Avatar animado
- [ ] Informações em cards
- [ ] Botões logout
- [ ] Verify spacing e animations

### 7. Notifications ✅
- [ ] Type-based colors
- [ ] Animated cards
- [ ] Badges para unread
- [ ] Verify staggered animations

### 8. Settings ✅
- [ ] Sections com emojis
- [ ] Switches e dropdowns
- [ ] Staggered fade animations
- [ ] Verify após correção Windows

### 9. Apartments
- [ ] Grid de apartments
- [ ] Filtro por estado
- [ ] Cards com info resumida
- [ ] Status badge colorida

### 10. Apartment Detail
- [ ] Seções de informação
- [ ] Lista de moradores
- [ ] Items do apartamento
- [ ] Edit/Delete buttons

---

## 🧪 Testes de UX

### Fluxo de Usar

- [ ] Login → Dashboard: Transição suave
- [ ] Dashboard → Criar solicitação: Abre form
- [ ] Form → Salvar: Spinner, sucesso, voltar
- [ ] Solicitação → Detalhe: Abrir modal/tela
- [ ] Comentar → Enviar: Atualizar lista
- [ ] Logout: Volta para login

### Estados de Erro

- [ ] Campo vazio: Error message
- [ ] Servidor offline: Friendly message
- [ ] Timeout: Retry button
- [ ] 403/401: Logout automático

### Estados de Vazio

- [ ] Nenhuma solicitação: EmptyState
- [ ] Nenhum resultado de busca: EmptyState
- [ ] Nenhum comentário: EmptyState com botão CTA

### Performance

- [ ] Primeira carga: < 2s
- [ ] Scroll 100 items: Suave (60fps)
- [ ] Animações: Sem stutter
- [ ] Memory: < 200MB

---

## 🎨 Estilos Visuales – Screenshot

Antes de publicar, validar screenshots em:

### Mobile (360px, Portrait)
- [ ] Login screen
- [ ] Dashboard completo
- [ ] Maintenance list
- [ ] Maintenance detail
- [ ] Create form

### Mobile (800px, Landscape)
- [ ] Dashboard layout
- [ ] Maintenance list
- [ ] Verificar se layout se adapta

### Tablet (1024px)
- [ ] Dashboard com 3 colunas
- [ ] Maintenance list com 2 colunas
- [ ] Margens adequadas

### Dark Mode
- [ ] Login em dark
- [ ] Dashboard em dark
- [ ] Todas cores visíveis
- [ ] Shimmer funcionando

---

## 📋 Checklist Final Antes do Release

- [ ] ✅ Todos componentes usando OwanyTheme
- [ ] ✅ Nenhuma cor hardcoded (todos const)
- [ ] ✅ Espaçamento consistente (16px padrão)
- [ ] ✅ Tipografia em hierarquia (7 níveis)
- [ ] ✅ Ícones com `_rounded` suffix
- [ ] ✅ Cards com border + sombra padrão
- [ ] ✅ Botões: Primary (orange), Secondary (outlined)
- [ ] ✅ Status badges: Pendente (amber), Andamento (indigo), Concluído (green)
- [ ] ✅ SliverAppBar em todas pages com gradient
- [ ] ✅ Animações staggered em lists
- [ ] ✅ Empty states em todas listas vazias
- [ ] ✅ Loading shimmer para async data
- [ ] ✅ Error dialogs com retry
- [ ] ✅ Dark mode: Todos themes testados
- [ ] ✅ Responsive: Mobile/Tablet/Desktop
- [ ] ✅ Acessibilidade: Contraste, keyboard nav
- [ ] ✅ Performance: < 2s load, 60fps scroll
- [ ] ✅ I18n: Strings em PT-BR
- [ ] ✅ Flutter analyze: 0 warnings
- [ ] ✅ No hardcoded strings (usar constants)
- [ ] ✅ Comentários no código (quando complexo)

---

## 🚀 Próximas Fases

### Phase 1: Core Screens (Current)
- Login, Dashboard, Solicitações, Perfil, Notificações, Configurações

### Phase 2: Secondary Screens
- Apartamentos, Moradores, Itens, Usuários

### Phase 3: Polish
- Micro-interactions, additional animations, transitions

### Phase 4: Performance
- Lazy loading, caching, pagination

---

**Last Updated**: 21 January 2026  
**Version**: 1.0  
**Status**: ✅ Ready for QA

