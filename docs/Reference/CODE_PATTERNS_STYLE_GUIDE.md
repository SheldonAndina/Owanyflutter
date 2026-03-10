# 📐 Padrões de Código - Guia de Estilo Owany

**Versão**: 2.0 - Modernizada  
**Data**: 21 de Janeiro de 2026  
**Tipo**: Referência de Implementação

---

## 🎯 Princípios Fundamentais

### 1. **Design System Unificado**
Todos os componentes usam **EXCLUSIVAMENTE** o `OwanyTheme`.

```dart
// ❌ ERRADO - Material colors
backgroundColor: Colors.orange,

// ✅ CORRETO - Owany Theme
backgroundColor: OwanyTheme.primaryOrange,
```

### 2. **Componentes Reutilizáveis**
Use os 18 componentes modernos ao invés de criar novos.

```dart
// ❌ ERRADO - Criar novo AppBar
AppBar(title: Text('Title'))

// ✅ CORRETO - Usar ModernAppBar
ModernAppBar(title: 'Title')
```

### 3. **Null Safety Obrigatória**
100% null-safe, sem brincadeiras com `!`.

```dart
// ❌ ERRADO
final name = user!.name;

// ✅ CORRETO
final name = user?.name ?? 'N/A';
```

### 4. **Provider para Estado**
Não use `setState` em ningém lugar.

```dart
// ❌ ERRADO
setState(() => _loading = true);

// ✅ CORRETO
Provider.read<MyProvider>(context).load();
```

### 5. **Logging em Todas as Ações**
Use `AppLogger` para rastrear tudo.

```dart
// ❌ ERRADO
void _load() {
  print('Loading...');
}

// ✅ CORRETO
void _load() {
  _logger.info('Tag', 'Carregando dados');
}
```

---

## 📦 Estrutura de Screen

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Imports em ordem: 1) Flutter/Dart, 2) Package, 3) Local
import '../../theme/owany_theme.dart';
import '../../widgets/modern_components.dart';
import '../../providers/my_provider.dart';
import '../../utils/app_logger.dart';

// 2. StatefulWidget (se necessário)
class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

// 3. State com late logger
class _MyScreenState extends State<MyScreen> {
  late AppLogger _logger;

  @override
  void initState() {
    super.initState();
    _logger = AppLogger();
    _carregarDados();
  }

  void _carregarDados() {
    _logger.info('MyScreen', 'Iniciando carregamento');
    Future.microtask(() {
      context.read<MyProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: 'Title'),
      body: Consumer<MyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoading();
          }
          if (provider.hasError) {
            return _buildError(provider);
          }
          return _buildContent(provider);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          OwanyTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildError(MyProvider provider) {
    return ModernEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Erro',
      message: provider.errorMessage,
      onRetry: _carregarDados,
    );
  }

  Widget _buildContent(MyProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Content here
        ],
      ),
    );
  }
}
```

---

## 🎨 Padrões de Cores

### Uso Correto de Cores

```dart
// 1. Texto Primário
Text('Title', style: TextStyle(color: OwanyTheme.textDefault))

// 2. Texto Secundário
Text('Subtitle', style: TextStyle(color: OwanyTheme.textMuted))

// 3. Fundo Principal
Container(color: OwanyTheme.background)

// 4. Cards/Surfaces
Container(color: OwanyTheme.surface)

// 5. Ações (Botões, Links)
Container(color: OwanyTheme.primaryOrange)

// 6. Estados
// Success: Color(0xFF7BA57E)
// Warning: Color(0xFFD9A85C)
// Error: Color(0xFFE85D46)
```

### Mapa de Cores Completo

```dart
class OwanyTheme {
  // Primárias
  static const primaryOrange = Color(0xFFFF7A3D);  // Ações
  static const primaryBrown = Color(0xFF2D1B0E);   // Headers
  
  // Neutras
  static const background = Color(0xFFFAFAF8);     // Fundo
  static const surface = Color(0xFFF5F1ED);        // Cards
  static const borderLight = Color(0xFFE8E3DC);    // Borders
  
  // Texto
  static const textDefault = Color(0xFF2D1B0E);    // Primário
  static const textMuted = Color(0xFF6B5E54);      // Secundário
  
  // Status
  static const success = Color(0xFF7BA57E);        // Verde
  static const warning = Color(0xFFD9A85C);        // Amarelo
  static const error = Color(0xFFE85D46);          // Vermelho
}
```

---

## 📏 Spacing & Sizing

### Spacing Padrão (8px base)

```dart
const SizedBox(height: 8)   // Pequeno
const SizedBox(height: 12)  // Normal
const SizedBox(height: 16)  // Médio
const SizedBox(height: 24)  // Grande
const SizedBox(height: 32)  // Extra Grande
```

### Padding Padrão

```dart
// Dentro de cards
padding: const EdgeInsets.all(16)

// Horizontais em screens
padding: const EdgeInsets.symmetric(horizontal: 16)

// Verticais em screens
padding: const EdgeInsets.symmetric(vertical: 24)

// Completo
padding: const EdgeInsets.all(24)
```

### Tamanhos de Componentes

```dart
// Botões
height: 48  // Padrão (móvel)
height: 44  // Pequeno (compacto)
height: 56  // Grande

// BorderRadius
radius: 8   // Pequeno
radius: 10  // Normal
radius: 12  // Grande
radius: 20  // Muito redondo

// Ícones
size: 20    // Pequeno
size: 24    // Normal
size: 32    // Grande
```

---

## 🔘 Padrões de Botões

### Botão Primário (Orange)
```dart
ModernButton(
  label: 'Enviar',
  onPressed: () {},
  icon: Icons.send_rounded,
)
```

### Botão Secundário (Outline)
```dart
ModernOutlineButton(
  label: 'Cancelar',
  onPressed: () {},
)
```

### Botão com Loading
```dart
ModernButton(
  label: isLoading ? 'Enviando...' : 'Enviar',
  isLoading: isLoading,
  onPressed: isLoading ? null : () {},
)
```

### Botão Desabilitado
```dart
ModernButton(
  label: 'Salvar',
  isEnabled: formValid,
  onPressed: () {},
)
```

---

## 📋 Padrões de Listas

### Lista Simples
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ModernListItem(
      icon: Icons.item_rounded,
      title: item.title,
      subtitle: item.subtitle,
      onTap: () => _handleTap(item),
    );
  },
)
```

### Lista com Divisor
```dart
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (context, index) => Divider(
    color: OwanyTheme.borderLight,
    height: 1,
  ),
  itemBuilder: (context, index) {
    return ModernListItem(...)
  },
)
```

### Lista Vazia
```dart
if (items.isEmpty)
  ModernEmptyState(
    icon: Icons.inbox_rounded,
    title: 'Nenhum item',
    message: 'Adicione um novo item para começar',
    onRetry: _load,
  )
else
  ListView.builder(...)
```

---

## 📐 Padrões de Cards

### Card Simples
```dart
ModernCard(
  child: Text('Conteúdo'),
  padding: const EdgeInsets.all(16),
)
```

### Card com Ação
```dart
ModernCard(
  child: Column(
    children: [
      Text('Título'),
      SizedBox(height: 8),
      Text('Subtítulo'),
    ],
  ),
  onTap: () => _handleTap(),
  clickable: true,
)
```

### Card com Métrica
```dart
MetricCard(
  icon: Icons.build_rounded,
  value: '12',
  label: 'Manutenções',
  subtitle: '3 Pendentes',
  percentage: 75,
  onTap: () {},
)
```

---

## 🔄 Padrões de State Management

### Carregamento com Provider

```dart
// 1. Ler provider
final provider = context.read<MyProvider>();

// 2. Chamar método
await provider.load();

// 3. Atualizar UI automaticamente (Consumer faz isso)
Consumer<MyProvider>(
  builder: (context, provider, _) {
    // Rebuilds automaticamente quando notifyListeners() é chamado
    return Text(provider.data.toString());
  },
)
```

### Provider com BaseProvider (Moderno)

```dart
class MyProvider extends BaseProvider {
  Future<void> load() async {
    await executeOperation(
      () async {
        // Seu código aqui
        // isLoading, errorMessage são gerenciados automaticamente
      },
      operationName: 'load', // Logging automático
    );
  }
}
```

---

## 🔒 Padrões de Validação

### Validação em Forms

```dart
TextFormField(
  validator: (value) => AppValidator.validateEmail(value),
  // Retorna String? (null = válido, String = erro)
)

// Usando em forma simples
final isValid = AppValidator.validateEmail(email) == null;
```

### Validadores Disponíveis

```dart
AppValidator.validateEmail(value)
AppValidator.validatePhoneNumber(value)
AppValidator.validatePassword(value)
AppValidator.validateName(value)
AppValidator.validateCPF(value)
AppValidator.validateCNPJ(value)
AppValidator.validateZipCode(value)
AppValidator.validateURL(value)
AppValidator.validateMinLength(value, min)
AppValidator.validateMaxLength(value, max)
```

---

## 🎯 Padrões de Formatação

### Datas
```dart
// Parsing
final dt = DateTime.parse("2026-01-21T08:54:44Z");

// Formatting
AppFormatter.formatDate(dt)           // "21/01/2026"
AppFormatter.formatDateTime(dt)       // "21/01/2026 08:54"
AppFormatter.formatTime(dt)           // "08:54"
AppFormatter.formatRelativeDate(dt)   // "Há 2 dias"
```

### Telefone
```dart
AppFormatter.formatPhoneNumber("11987654321")
// "(11) 98765-4321"
```

### Moeda
```dart
AppFormatter.formatCurrency(1234.56)
// "R$ 1.234,56"
```

### Texto
```dart
AppFormatter.capitalize("texto")           // "Texto"
AppFormatter.truncate("Texto muito longo") // "Texto muito..."
```

---

## 📝 Padrões de Logging

### Logging Básico

```dart
final _logger = AppLogger();

_logger.debug('MyScreen', 'Mensagem de debug');
_logger.info('MyScreen', 'Informação importante');
_logger.warning('MyScreen', 'Aviso!');
_logger.error('MyScreen', 'Erro encontrado');
_logger.critical('MyScreen', 'Erro crítico!');
```

### Em Métodos

```dart
void _load() {
  _logger.info('MyScreen', 'Iniciando carregamento');
  
  try {
    // ... código ...
    _logger.debug('MyScreen', 'Dados carregados');
  } catch (e) {
    _logger.error('MyScreen', 'Erro ao carregar: $e');
  }
}
```

---

## 🧪 Padrões de Tratamento de Erro

### Com Try-Catch
```dart
try {
  await provider.load();
} catch (e) {
  _logger.error('MyScreen', 'Erro: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro ao carregar')),
  );
}
```

### Com Result Pattern
```dart
final result = await provider.load();
result.fold(
  (error) => _logger.error('MyScreen', error.toString()),
  (data) => setState(() => _data = data),
);
```

### Com BaseProvider
```dart
// Erros são tratados automaticamente por BaseProvider
// Acesse via provider.errorMessage
Consumer<MyProvider>(
  builder: (context, provider, _) {
    if (provider.hasError) {
      return Text(provider.errorMessage ?? 'Erro desconhecido');
    }
    return SizedBox.shrink();
  },
)
```

---

## 📞 Padrões de API

### Request Simples

```dart
final data = await ApiService().request<List<Item>>(
  'items',
  method: 'GET',
  fromJson: (json) => (json as List)
      .map((item) => Item.fromJson(item))
      .toList(),
);
```

### POST com Body

```dart
final item = await ApiService().request<Item>(
  'items',
  method: 'POST',
  body: {
    'name': 'Novo Item',
    'description': 'Descrição',
  },
  fromJson: (json) => Item.fromJson(json),
);
```

### Com Erros

```dart
try {
  final data = await ApiService().request<Item>(...);
} on HttpException catch (e) {
  _logger.error('API', 'HTTP Error: ${e.statusCode}');
} on TimeoutException catch (e) {
  _logger.error('API', 'Timeout: $e');
} catch (e) {
  _logger.error('API', 'Unknown error: $e');
}
```

---

## 🚫 Anti-Patterns (NÃO FAÇA)

### ❌ Usar Colors do Material
```dart
backgroundColor: Colors.orange  // ❌ ERRADO
backgroundColor: OwanyTheme.primaryOrange  // ✅ CORRETO
```

### ❌ Usar setState
```dart
setState(() => _data = newData)  // ❌ ERRADO
context.read<Provider>().setData(newData)  // ✅ CORRETO
```

### ❌ Ignorar Null Safety
```dart
final name = user!.name  // ❌ ERRADO
final name = user?.name ?? 'N/A'  // ✅ CORRETO
```

### ❌ Logging com print()
```dart
print('Loading...')  // ❌ ERRADO
_logger.info('Tag', 'Loading...')  // ✅ CORRETO
```

### ❌ AppBar antigo
```dart
AppBar(title: Text('Title'))  // ❌ ERRADO
ModernAppBar(title: 'Title')  // ✅ CORRETO
```

### ❌ Criar componentes duplicados
```dart
Container(  // ❌ ERRADO (use ModernCard)
  decoration: BoxDecoration(...),
  child: Text('...'),
)

ModernCard(child: Text('...'))  // ✅ CORRETO
```

---

## ✅ Checklist de Código

Antes de fazer commit, valide:

- [ ] Todas as cores usam `OwanyTheme`
- [ ] Usados componentes modernos (não custom)
- [ ] 100% null-safe (sem `!`)
- [ ] AppLogger usado em métodos principais
- [ ] Nenhum `setState` presente
- [ ] Provider usado para estado
- [ ] Spacing consistente (8px base)
- [ ] Sem código duplicado
- [ ] Tratamento de erros implementado
- [ ] Imports organizados por categoria

---

## 📚 Referências

- **OwanyTheme**: `lib/theme/owany_theme.dart`
- **Componentes**: `lib/widgets/modern_components.dart`
- **Validadores**: `lib/utils/app_validator.dart`
- **Formatadores**: `lib/utils/app_formatter.dart`
- **Logging**: `lib/utils/app_logger.dart`

---

**Versão**: 2.0 - Modernizada  
**Última Atualização**: 21 de Janeiro de 2026  
**Status**: ✅ Em Vigência

