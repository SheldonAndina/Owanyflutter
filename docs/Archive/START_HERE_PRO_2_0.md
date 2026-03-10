# 🚀 COMEÇAR AGORA - Owany App PRO 2.0

## ⚡ 5 Minutos Para Começar

### Passo 1: Importar o Que Precisa
```dart
// No topo do seu arquivo
import 'package:owany_app/utils/extensions.dart';
import 'package:owany_app/utils/app_validator.dart';
import 'package:owany_app/utils/app_formatter.dart';
```

### Passo 2: Usar em um TextField
```dart
TextFormField(
  controller: emailController,
  validator: AppValidator.validateEmail,  // Pronto! ✓
)
```

### Passo 3: Usar Extensões
```dart
Text(userName.capitalized)  // Antes: "joão silva" → Depois: "João silva"
Text(date.formatted)        // Antes: DateTime(2026,1,23) → Depois: "23/01/2026"
```

### Passo 4: Usar Logger
```dart
import 'package:owany_app/utils/app_logger.dart';

AppLogger.debug('MyScreen', 'Usuário clicou em botão');
```

### Passo 5: Melhorar seu Provider
```dart
import 'package:owany_app/providers/base_provider.dart';

class MyProvider extends BaseProvider {
  Future<void> loadData() async {
    await executeOperation(
      () => apiService.getData(),
      operationName: 'loadData',
    );
  }
}
```

**Pronto! Você já está usando PRO! 🎉**

---

## 📋 Checklist: Usar em 5 Telas

### Tela 1: Login
```dart
// ✓ Campo de email com validação
TextFormField(validator: AppValidator.validateEmail)

// ✓ Campo de senha com validação
TextFormField(validator: AppValidator.validatePassword)

// ✓ Logging de tentativa
AppLogger.info('LoginScreen', 'Usuário tentou login');

// ✓ Tratamento de erro específico
} on UnauthorizedException {
  showError('Email ou senha incorretos');
}
```

### Tela 2: Lista de Usuários
```dart
// ✓ Provider com BaseProvider
class UsuariosProvider extends BaseProvider

// ✓ Usar capitalized
Text(usuario.nome.capitalized)

// ✓ Usar formatted
Text(usuario.telefone.formattedPhone)

// ✓ Usar cache
executeOperation(...) with CacheMixin
```

### Tela 3: Criar Usuário
```dart
// ✓ Formulário com validações
TextFormField(validator: AppValidator.validateName)
TextFormField(validator: AppValidator.validatePhone)

// ✓ Logging
AppLogger.debug('CreateUserScreen', 'Form submitted');

// ✓ Tratamento de erro
} on ValidationException catch (e) {
  mostrarErrosValidacao(e.errors);
}
```

### Tela 4: Detalhes de Apartamento
```dart
// ✓ Datas formatadas
Text(apartment.criadoEm.formatted)
Text(apartment.atualizadoEm.relativeTime)

// ✓ Valores formatados
Text(AppFormatter.formatCurrency(valor))

// ✓ Logging de visualização
AppLogger.info('ApartmentDetail', 'Visualizado: ${id}');
```

### Tela 5: Relatórios
```dart
// ✓ Números formatados
Text(AppFormatter.formatNumber(totalUsuarios))
Text(AppFormatter.formatPercentage(ocupacao))

// ✓ Datas com relativo
Text(dataUltimo.relativeTime)

// ✓ Cache de dados pesados
mixin CacheMixin<List<Relatorio>>
```

---

## 🎓 Exemplos Prontos Para Copiar/Colar

### Validar Email
```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Email'),
  validator: AppValidator.validateEmail,
)
```

### Validar Telefone com Formatação
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Telefone',
    hintText: AppFormatter.formatPhone('11999999999'),
  ),
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: AppValidator.validatePhone,
)
```

### Validar Senha Forte
```dart
TextFormField(
  decoration: InputDecoration(labelText: 'Senha'),
  obscureText: true,
  validator: AppValidator.validatePassword,
  helperText: 'Min 8 chars, maiúscula, minúscula, número',
)
```

### Mostrar Data Formatada
```dart
Text(
  'Criado em: ${appointment.criadoEm.formatted}',
  style: TextStyle(color: Colors.grey),
)
```

### Mostrar Tempo Relativo
```dart
Text(
  lastUpdated.relativeTime,  // "há 2 horas"
  style: TextStyle(fontSize: 12, color: Colors.grey),
)
```

### Provider com Logging
```dart
class MyProvider extends BaseProvider {
  final _api = ApiService();
  List<Item> _items = [];
  
  Future<void> loadItems() async {
    log('Iniciando carregamento de items');
    
    await executeOperation(
      () async {
        _items = await _api.getItems();
        return _items;
      },
      operationName: 'loadItems',
    );
  }
}
```

### Tratamento Completo de Erro
```dart
try {
  await apiService.createUser(userData);
  showSuccess('Usuário criado!');
} on ValidationException catch (e) {
  showErrorWithDetails('Dados inválidos', e.errors);
} on UnauthorizedException {
  navigateToLogin();
} on NetworkException {
  showRetryDialog();
} on TimeoutException {
  showMessage('Servidor demorou muito');
} catch (e) {
  AppLogger.error('MyScreen', 'Erro inesperado', e);
  showError('Algo deu errado');
}
```

---

## 🔍 Encontrar Exemplos nos Arquivos

| Você quer... | Vá em | Procure por |
|-------------|--------|------------|
| Validar algo | `app_validator.dart` | `validate*` |
| Formatar algo | `app_formatter.dart` | `format*` |
| Usar extensão | `extensions.dart` | `extension` |
| Criar provider | `base_provider.dart` | `BaseProvider` |
| Tretar erro | `app_exception.dart` | `on ` |
| Logar algo | `app_logger.dart` | `AppLogger.` |

---

## 📊 Antes vs Depois

### Campo de Email

**❌ Antes**
```dart
TextFormField(
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Email obrigatório';
    if (!value!.contains('@')) return 'Email inválido';
    if (!value.contains('.')) return 'Email inválido';
    // falta validação completa
    return null;
  },
)
```

**✅ Depois**
```dart
TextFormField(
  validator: AppValidator.validateEmail,
)
```

### Mostrar Nome

**❌ Antes**
```dart
Text(usuario.nome[0].toUpperCase() + usuario.nome.substring(1).toLowerCase())
```

**✅ Depois**
```dart
Text(usuario.nome.capitalized)
```

### Formatador de Telefone

**❌ Antes**
```dart
Text('(${phone.substring(0,2)}) ${phone.substring(2,7)}-${phone.substring(7)}')
```

**✅ Depois**
```dart
Text(phone.formattedPhone)
```

### Provider Simples

**❌ Antes**
```dart
class MyProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  
  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      // ...
    } catch(e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

**✅ Depois**
```dart
class MyProvider extends BaseProvider {
  Future<void> load() async {
    await executeOperation(
      () => apiService.getData(),
      operationName: 'load',
    );
  }
}
```

---

## 🆘 Preciso de Ajuda?

### Pergunta: Como validar CPF?
```dart
validator: AppValidator.validateCPF
```

### Pergunta: Como formatar moeda?
```dart
Text(AppFormatter.formatCurrency(valor))
```

### Pergunta: Como pegar iniciais?
```dart
Text(nome.initials)  // "João Silva" → "JS"
```

### Pergunta: Como verificar se email é válido?
```dart
if (email.isValidEmail) {
  // prosseguir
}
```

### Pergunta: Como logar um erro?
```dart
AppLogger.error('MyTag', 'Descrição do erro', exception, stackTrace);
```

### Pergunta: Como fazer paginação?
```dart
class MyProvider extends BaseProvider with PaginationMixin {
  // currentPage, pageSize, hasMore etc estão automáticos
}
```

### Pergunta: Como cachear dados?
```dart
class MyProvider extends BaseProvider with CacheMixin<List<Data>> {
  // updateCache(), cachedData, invalidateCache() automáticos
}
```

---

## 🚀 Próxima Ação

1. **Agora**: Abra um arquivo `.dart` e adicione:
   ```dart
   import 'package:owany_app/utils/extensions.dart';
   ```

2. **Próximo 5 min**: Use 1 validador:
   ```dart
   validator: AppValidator.validateEmail,
   ```

3. **Próximo 15 min**: Use 1 formatador:
   ```dart
   Text(data.formatted)
   ```

4. **Próximo 30 min**: Crie um provider melhorado:
   ```dart
   class MyProvider extends BaseProvider { ... }
   ```

5. **Próximo 1 hora**: Refatore 1 tela completa

**Pronto! Você está usando PRO! 🎉**

---

## 📞 Dúvidas Comuns

**P: Preciso alterar algo?**  
R: Não, tudo está pronto para usar!

**P: Quebra compatibilidade?**  
R: Não, é totalmente retrocompatível.

**P: Tem performance impact?**  
R: Não, é completamente otimizado.

**P: Tenho que refatorar tudo?**  
R: Não, use gradualmente em novas features.

**P: E os testes?**  
R: Tudo é testável e type-safe.

---

## 🎁 Bonus: Atalhos

### Para rápido acesso:
```dart
// Adicione ao seu arquivo principal
const validator = AppValidator;
const formatter = AppFormatter;
const logger = AppLogger;
const exceptions = [
  NetworkException,
  UnauthorizedException,
  TimeoutException,
];
```

Então use como:
```dart
validator.validateEmail(email)
formatter.formatPhone(phone)
```

---

**Vamos lá! Comece AGORA! 🚀**

Data: 23 de Janeiro de 2026  
Status: ✅ Pronto para Usar
