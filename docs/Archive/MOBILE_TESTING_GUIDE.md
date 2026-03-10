# 📱 Guia de Testes Responsividade Mobile

## 🎯 Objetivo
Verificar que a aplicação Owany funciona perfeitamente em dispositivos móveis (iOS e Android) com diferentes tamanhos de tela.

---

## 📊 Dispositivos Testados

### iPhone
- [ ] iPhone 12 Pro (6.1" - 390x844)
- [ ] iPhone 13 Pro Max (6.7" - 428x926)
- [ ] iPhone SE (4.7" - 375x667)

### Android
- [ ] Pixel 4 (5.7" - 412x869)
- [ ] Pixel 5 (6.0" - 432x900)
- [ ] Samsung Galaxy S21 (6.2" - 360x800)
- [ ] Dispositivo com menor tela: 320x480

---

## ✅ Checklist de Testes

### 1. **Dashboard** (/dashboard)
- [ ] Header com nome completo está legível
- [ ] Metrics cards não overflow em telas pequenas
- [ ] Botão + está proporcionado (não muito grande)
- [ ] Modal de adicionar abre/fecha smoothly
- [ ] Status consolidado cabe na tela
- [ ] Solicitações recentes scrollam corretamente

### 2. **Solicitações** (/solicitacoes)
- [ ] Lista com skeleton loading animado
- [ ] Empty state com ícone + botão CTA
- [ ] Filtros/search não cobrem a lista
- [ ] Cards de solicitação têm bom padding
- [ ] Status bar lateral legível
- [ ] Pull-to-refresh funciona

### 3. **Apartamentos** (/apartamentos)
- [ ] Grid de apartamentos responsivo
- [ ] Cards com 1 coluna em mobile, 2 em tablet
- [ ] Criar novo apartamento acessível
- [ ] Empty state exibido corretamente

### 4. **Usuários** (/usuarios)
- [ ] Lista exibida corretamente
- [ ] Skeleton loading durante fetch
- [ ] Empty state aparece quando vazio
- [ ] Botões ação (editar/deletar) tocáveis

### 5. **Configurações** (/configuracoes)
- [ ] Seções stacked verticalmente
- [ ] Switch toggles funcionam
- [ ] Dropdown acessível
- [ ] Botão Sair com tamanho apropriado
- [ ] Alterar Senha link funciona

### 6. **Alterar Senha** (/change-password)
- [ ] Inputs têm boa altura para touch (48px+)
- [ ] Toggle mostrar/ocultar senha funciona
- [ ] Botão enviar visível sem scroll
- [ ] Validações aparecem inline

### 7. **Navegação**
- [ ] Drawer abre/fecha smoothly
- [ ] Menu items têm boa altura (56px+)
- [ ] AppBar não está muito alto
- [ ] Back button sempre visível/funciona

### 8. **Animações**
- [ ] Transições slide entre telas são suaves
- [ ] Skeleton loading não trava
- [ ] Empty state animações não são pesadas
- [ ] Modal bottom sheet desliza smoothly

### 9. **Teclado Virtual**
- [ ] Inputs não são cobertos pelo teclado
- [ ] FocusNode funciona corretamente
- [ ] Form submit funciona com teclado

### 10. **Performance**
- [ ] Scroll FPS > 50 fps
- [ ] Sem memory leaks visíveis
- [ ] Nenhuma lag ao carregar dados

---

## 🚀 Como Testar

### iOS (via Simulator)
```bash
flutter run -d "iPhone 12 Pro"    # Lista dispositivos com: flutter devices
```

### Android (via Emulator)
```bash
flutter run -d emulator-5554      # Lista com: flutter devices
```

### Web Preview (Responsive)
```bash
flutter run -d chrome --web-port 5000
# Usar Chrome DevTools (F12 → Toggle device toolbar)
```

### Build para Real Device
```bash
# iOS
flutter build ios

# Android
flutter build apk --release
```

---

## 📐 Breakpoints Suportados

| Device Type | Width | Columns |
|------------|-------|---------|
| Mobile    | < 600 | 1       |
| Tablet    | 600-1200 | 2   |
| Desktop   | > 1200 | 3       |

---

## 🔍 Problemas Comuns & Soluções

### Problema: Elementos overflow em tela pequena
**Solução**: Usar `Expanded`, `Flexible`, ou `SingleChildScrollView`

### Problema: Texto pequeno demais em mobile
**Solução**: Aumentar tamanho com `MediaQuery.of(context).size.width`

### Problema: Botões difíceis de tocar
**Solução**: Mínimo 48px altura, 8px de padding

### Problema: Teclado cobre inputs
**Solução**: `Scaffold` com `resizeToAvoidBottomInset: true`

---

## 📝 Relatório de Teste

Após testar todos os itens, preencher:

**Data**: ___/___/_____  
**Testador**: _______________  
**Devices Testados**: _______________  

**Problemas Encontrados**:
```
1. [Dispositivo] - [Tela] - Descrição
2. ...
```

**Nota Geral**: ________________________

---

## 📚 Referências

- [Flutter Responsive Design](https://flutter.dev/docs/development/ui/layout/responsive)
- [Material Design Mobile Guidelines](https://material.io/design/platform-guidance/android-bars.html)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/)

---

**Status**: ✅ Pronto para testes  
**Última atualização**: 21/01/2026
