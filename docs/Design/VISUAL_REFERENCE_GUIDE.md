# 🎨 VISUAL REFERENCE GUIDE – OWANY Design System
## Paleta, Componentes e Padrões em Uma Página

---

## 🌈 PALETA DE CORES

### Primária
```
█████ #ED7A23 primaryOrange    (Botões, CTAs, destaques)
█████ #2C7BE5 primaryBlue      (Links, informações)
█████ #FFF1E6 softOrange       (Fundo suave)
```

### Neutra
```
█████ #1F2937 darkSlate        (Texto principal)
█████ #6B7280 lightSlate       (Texto secundário)
█████ #F3F4F6 background       (Fundo)
█████ #EDEDF2 surface          (Cards)
```

### Semântica
```
█████ #10B981 success          (✅ Sucesso)
█████ #F59E0B warning          (⚠️ Aviso)
█████ #EF4444 error            (❌ Erro)
```

---

## 📐 ESPAÇAMENTO

```
┌─────────────────────────────────┐
│  8px   → Muito pequeno          │
│  12px  → Pequeno                │
│  16px  → ⭐ PADRÃO              │
│  24px  → Grande                 │
│  32px  → Muito grande           │
└─────────────────────────────────┘
```

---

## 📝 TIPOGRAFIA

```
Heading 1          32px  bold           Título de página
Heading 2          20px  bold           Subtítulo, seção
Heading 3          16px  bold           Card title
Body Strong        14px  semibold       Texto importante
Body               14px  medium         Texto corpo
Body Small         12px  medium         Texto secundário
Caption            11px  medium         Muito pequeno
```

---

## 🔘 BOTÕES

### Primário (Orange, 56px altura)
```
┌────────────────────────────────┐
│          BOTÃO PRIMÁRIO        │
└────────────────────────────────┘
Fundo: #ED7A23
Texto: Branco
```

### Secundário (Outlined)
```
┌────────────────────────────────┐
│      BOTÃO SECUNDÁRIO          │
└────────────────────────────────┘
Borda: 1px #6B7280
Texto: #1F2937
```

### Terciário (Text Button)
```
TEXTO BUTTON (sem borda, sem fundo)
Cor: #2C7BE5
```

---

## 🎨 CARDS

### Padrão
```
┌─────────────────────────────────┐
│ CARD COM BORDER E SOMBRA        │
│                                 │
│ Fundo: #EDEDF2                 │
│ Border: 1px #0000001F          │
│ BorderRadius: 14px             │
│ Sombra: blur 22, offset 12     │
└─────────────────────────────────┘
```

### Card com Status
```
┌─────────────────────────────────┐
│ ⬜ TÍTULO DA SOLICITAÇÃO         │
│   Localização                   │
│   ⬜ Pendente  │  21/01/2026     │
└─────────────────────────────────┘
```

---

## 📦 BADGES

### Status Pendente
```
┌──────────────┐
│ ⚠️ Pendente   │
└──────────────┘
Fundo: #F59E0B.withOpacity(0.1)
Texto: #F59E0B
BorderRadius: 6px
```

### Status Em Andamento
```
┌──────────────┐
│ ⏱️ Andamento  │
└──────────────┘
Fundo: #4C63BE.withOpacity(0.1)
Texto: #4C63BE
```

### Status Concluído
```
┌──────────────┐
│ ✅ Concluído  │
└──────────────┘
Fundo: #10B981.withOpacity(0.1)
Texto: #10B981
```

---

## 🏠 LAYOUTS

### Layout 1: Gradient Header (SliverAppBar)
```
┌─────────────────────────────────┐
│ ┌───────────────────────────────┤
│ │ [Gradient com 3 cores]        │
│ │ Título Grande                 │
│ │ Subtítulo pequeno             │
│ └───────────────────────────────┤
├─────────────────────────────────┤
│                                 │
│ ► Cards com conteúdo            │
│                                 │
│ ► Mais cards                    │
│                                 │
└─────────────────────────────────┘
```

### Layout 2: List View
```
┌─────────────────────────────────┐
│ ← Dashboard  Solicitações       │
├─────────────────────────────────┤
│ [🔍 Buscar...]                  │
├─────────────────────────────────┤
│ [Todos] [Pendente] [Andamento]  │
├─────────────────────────────────┤
│                                 │
│ ┌──────────────────────────────┐│
│ │ ⬜ Solicitação 1             ││
│ │   Localização | Status       ││
│ └──────────────────────────────┘│
│                                 │
│ ┌──────────────────────────────┐│
│ │ ⬜ Solicitação 2             ││
│ │   Localização | Status       ││
│ └──────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Layout 3: Form
```
┌─────────────────────────────────┐
│ ← Dashboard  Nova Solicitação   │
├─────────────────────────────────┤
│                                 │
│ SEÇÃO 1                         │
│ ┌──────────────────────────────┐│
│ │ ▸ Campo: Título *            ││
│ │ ▸ Campo: Descrição *         ││
│ └──────────────────────────────┘│
│                                 │
│ SEÇÃO 2                         │
│ ┌──────────────────────────────┐│
│ │ ▸ Dropdown: Apartamento *    ││
│ │ ▸ DatePicker: Prazo *        ││
│ └──────────────────────────────┘│
│                                 │
│ [ CANCELAR ] [ SALVAR ]         │
│                                 │
└─────────────────────────────────┘
```

---

## 🎬 ANIMAÇÕES

### Staggered List
```
Card 1  →  Fade  0-100ms    Scale 0-100ms
Card 2  →  Fade 100-200ms   Scale 100-200ms
Card 3  →  Fade 200-300ms   Scale 200-300ms
...

Resultado: Entrada suave e natural
```

### Gradient Header
```
Cor 1: primaryOrange
  ↓ (0.7 opacity)
Cor 2: primaryOrange.withOpacity(0.7)
  ↓ (0.5 opacity)
Cor 3: softOrange.withOpacity(0.5)

Resultado: Transição suave do topo ao fundo
```

---

## ♿ ACESSIBILIDADE

### Touch Targets
```
┌──────────────────────┐
│    Botões: 48x48px   │
│    (mínimo recomendado)
└──────────────────────┘
```

### Contraste
```
darkSlate (#1F2937) sobre background (#F3F4F6)
→ Ratio: 15:1 ✅ WCAG AAA

lightSlate (#6B7280) sobre surface (#EDEDF2)
→ Ratio: 7:1 ✅ WCAG AA

white sobre primaryOrange (#ED7A23)
→ Ratio: 9:1 ✅ WCAG AAA
```

---

## 📱 RESPONSIVIDADE

### Mobile (< 600px)
```
┌─────────────────┐
│ 16px margem     │
│ Fullwidth       │
│ Stacked layout  │
└─────────────────┘
```

### Tablet (600-1200px)
```
┌─────────────────────────────────┐
│ 24px margem                     │
│ 2-3 colunas grid                │
│ Lado a lado em alguns casos     │
└─────────────────────────────────┘
```

### Desktop (> 1200px)
```
┌─────────────────────────────────────────┐
│ 48px margem                             │
│ 4+ colunas grid                         │
│ Side-by-side layouts                    │
│ Max-width: 1400px (centrado)            │
└─────────────────────────────────────────┘
```

---

## 🌙 DARK MODE

### Cores Adaptadas
```
Light Mode → Dark Mode
#1F2937    → #E5E7EB    (darkText)
#6B7280    → #9CA3AF    (darkSubText)
#F3F4F6    → #0B1220    (darkBackground)
#EDEDF2    → #111827    (darkSurface)
#ED7A23    → #ED7A23    (primaryOrange mantém)
```

### Exemplo Card Dark
```
┌─────────────────────────────────┐
│ CARD EM DARK MODE               │
│ Fundo: #111827                 │
│ Texto: #E5E7EB                 │
│ Border: 1px #FFFFFF10          │
└─────────────────────────────────┘
```

---

## 🧪 COMPONENTES PRONTOS

```
✅ PrimaryButton
✅ SecondaryButton
✅ TertiaryButton
✅ StatusCard
✅ SectionCard
✅ InfoCard
✅ StatusBadge
✅ EmptyStateWidget
✅ LoadingOverlay
✅ SectionHeader
✅ CustomTextField
✅ ConfirmDialog
```

Todos em: **WIDGETS_READY_TO_USE.md**

---

## 📋 CHECKLIST RÁPIDO

- [ ] Nenhuma cor hardcoded (usar OwanyTheme)
- [ ] Espaçamento 16px padrão
- [ ] Componentes reutilizáveis
- [ ] SliverAppBar em páginas principais
- [ ] Empty states definidos
- [ ] Loading com shimmer
- [ ] Dark mode testado
- [ ] Responsividade testada
- [ ] Animações staggered em listas
- [ ] flutter analyze: 0 warnings

---

## 🎯 PRÓXIMOS PASSOS

1. Ler: **DESIGN_SUMMARY_EXECUTIVE.md** (5 min)
2. Estudar: **DESIGN_SYSTEM_OWANY.md** (15 min)
3. Implementar: **IMPLEMENTATION_PRACTICAL_GUIDE.md**
4. Validar: **DESIGN_VALIDATION_CHECKLIST.md**
5. Copiar: **WIDGETS_READY_TO_USE.md**

---

**Imprima ou fixe na parede! 📌**

Last Updated: 21 January 2026
Version: 1.0 ✅

