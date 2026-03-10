# 🎯 Como Usar as Melhorias PRO 2.0 em Suas Telas

## 5 Passos Simples para Modernizar Qualquer Screen

### Passo 1: Importe os Utilitários
```dart
import 'package:your_app/utils/app_logger.dart';
import 'package:your_app/utils/app_validator.dart';
import 'package:your_app/utils/app_formatter.dart';
import 'package:your_app/providers/base_provider.dart';
```

### Passo 2: Use AppLogger em Métodos Principais
```dart
Future<void> minhaOperacao() async {
  AppLogger.info('MyScreen', 'Iniciando operação');
  
  try {
    // seu código aqui
    AppLogger.debug('MyScreen', 'Operação concluída com sucesso');
  } catch (e) {
    AppLogger.error('MyScreen', 'Erro: $e');
  }
}
```

### Passo 3: Use Validadores em Formulários
```dart
TextFormField(
  validator: AppValidator.validateEmail,  // ✨ Pronto!
)

TextFormField(
  validator: AppValidator.validatePhone,  // ✨ Pronto!
)

TextFormField(
  validator: AppValidator.validatePassword,  // ✨ Pronto!
)
```

### Passo 4: Use Formatadores para Exibição
```dart
// Antes:
Text(data.toString())

// Depois:
Text(AppFormatter.formatDate(data))          // 23/01/2026
Text(AppFormatter.formatPhone(numero))       // (11) 98765-4321
Text(AppFormatter.formatCurrency(valor))     // R$ 1.234,56
Text(AppFormatter.formatRelativeTime(data))  // há 2 horas
```

### Passo 5: Atualize seu Provider
```dart
// Antes
class MeuProvider extends ChangeNotifier { ... }

// Depois
class MeuProvider extends BaseProvider { ... }

// E altere seus métodos:
Future<void> carregarDados() async {
  await executeOperation(() async {
    _dados = await api.fetch();
    // isLoading, errorMessage e notifyListeners automáticos!
  });
}
```

---

## 📋 Validadores Prontos para Usar

```dart
AppValidator.validateEmail(value)           // Email válido
AppValidator.validatePhone(value)           // Telefone (11 dígitos)
AppValidator.validatePassword(value)        // Senha (6+ chars, maiúscula, número)
AppValidator.validateName(value)            // Nome (mínimo 3 chars)
AppValidator.validateCPF(value)             // CPF com verificação
AppValidator.validateCNPJ(value)            // CNPJ com verificação
AppValidator.validateURL(value)             // URL válida
AppValidator.validateNumeric(value)         // Apenas números
AppValidator.validateMinLength(value, 5)    // Mínimo 5 caracteres
AppValidator.validateMaxLength(value, 50)   // Máximo 50 caracteres
```

**Todos retornam `String?` para uso direto em formulários!**

---

## 🎨 Formatadores Prontos para Usar

```dart
// Datas (Formato Brasileiro)
AppFormatter.formatDate(DateTime.now())                    // 23/01/2026
AppFormatter.formatDateTime(DateTime.now())               // 23/01/2026 14:30
AppFormatter.formatTime(DateTime.now())                   // 14:30
AppFormatter.formatRelativeTime(DateTime.now())           // há 2 horas

// Telefone e Documentos
AppFormatter.formatPhone('11987654321')                   // (11) 98765-4321
AppFormatter.formatCPF('12345678901')                     // 123.456.789-01
AppFormatter.formatCNPJ('12345678901234')                 // 12.345.678/0001-34

// Valores
AppFormatter.formatCurrency(1234.56)                      // R$ 1.234,56
AppFormatter.formatPercentage(0.75)                       // 75%
AppFormatter.formatFileSize(1024000)                      // 1 MB

// Strings
AppFormatter.capitalize('joão da silva')                  // João da silva
AppFormatter.truncate('texto muito longo...', 20)         // texto muito long...
```

---

## 📝 Logging Estruturado

```dart
// Diferentes níveis
AppLogger.debug('Tag', 'Mensagem de debug')
AppLogger.info('Tag', 'Informação importante')
AppLogger.warning('Tag', 'Aviso de problema')
AppLogger.error('Tag', 'Erro crítico')
AppLogger.critical('Tag', 'Falha total')

// Com stack trace automático
try {
  riskyOperation();
} catch (e, stack) {
  AppLogger.error('MyTag', 'Erro em riskyOperation', stackTrace: stack);
}

// Filtrar por tag
// Exemplo: AppLogger.tag = 'MyTag' para ver apenas logs dessa tag
```

**Logs armazenados em memória (1000 últimas entradas) e podem ser exportados!**

---

## 🧠 Extensions Úteis

```dart
// Strings
"joão".capitalized                           // João
"email@test".isValidEmail                    // true
"11987654321".formattedPhone                 // (11) 98765-4321

// Datas
DateTime.now().isToday                       // true
DateTime.now().isFuture                      // false
DateTime.now().ageInYears                    // 25
DateTime.now().formatted                     // 23/01/2026

// Listas
[1, 2, 3].chunk(2)                           // [[1,2], [3]]
['a', 'a', 'b'].removeDuplicates()           // ['a', 'b']
['a', 'b', 'c'].joinWith(', ')               // a, b, c

// Maps
{'a': 1, 'b': 2}.mapValues((v) => v * 2)    // {'a': 2, 'b': 4}
{'a': 1, 'b': null}.filterByKeys(['a'])      // {'a': 1}

// Nullables
nullable?.let((value) => process(value))     // Só executa se não null
nullable.ifNull('default')                   // Retorna default se null
nullable.isNull                              // true se null
```

---

## 🚨 Tratamento de Erros

### Antes
```dart
try {
  await api.fetch();
} catch (e) {
  print('Erro: $e');  // ❌ Genérico, sem logging
}
```

### Depois
```dart
try {
  await api.fetch();
} catch (e) {
  AppLogger.error('MyScreen', 'Erro na busca: $e');  // ✅ Estruturado
  
  // Tipos específicos!
  if (e is UnauthorizedException) {
    Navigator.pushReplacementNamed(context, '/login');
  } else if (e is NetworkException) {
    showSnackBar('Verifique sua conexão');
  } else if (e is TimeoutException) {
    showSnackBar('Conexão expirou');
  }
}
```

---

## ✨ Exemplo Completo: LoginScreen Modernizada

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';
import '../utils/app_validator.dart';
import '../utils/app_formatter.dart';
import '../providers/base_provider.dart';

class ModernLoginScreen extends StatefulWidget {
  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    AppLogger.info('LoginScreen', 'Tentativa de login');

    try {
      await context.read<AuthProvider>().login(
        _emailController.text,
        _passwordController.text,
      );

      AppLogger.debug('LoginScreen', 'Login bem-sucedido');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      AppLogger.error('LoginScreen', 'Erro no login: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('Erro no login', type: SnackBarType.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Email com validador pronto
              TextFormField(
                controller: _emailController,
                validator: AppValidator.validateEmail,  // ✨ Pronto!
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 16),
              
              // Senha com validador pronto
              TextFormField(
                controller: _passwordController,
                validator: AppValidator.validatePassword,  // ✨ Pronto!
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha'),
              ),
              SizedBox(height: 24),
              
              // Botão de login
              ElevatedButton(
                onPressed: _handleLogin,
                child: Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 Checklist: Modernizando uma Screen

- [ ] Importar `app_logger.dart`
- [ ] Importar `app_validator.dart` (se tem formulário)
- [ ] Importar `app_formatter.dart` (se mostra dados)
- [ ] Adicionar `AppLogger.info()` em métodos principais
- [ ] Trocar validação manual por `AppValidator.*`
- [ ] Trocar formatação manual por `AppFormatter.*`
- [ ] Atualizar provider se herda de `ChangeNotifier`
- [ ] Testar compilação
- [ ] Testar em device/emulador
- [ ] ✅ Pronto!

---

## 📊 Benefícios Imediatos

| Benefício | Antes | Depois |
|-----------|-------|--------|
| **Linhas de validação** | 30+ | 1 |
| **Linhas de logging** | 0 | 3-5 |
| **Type safety** | Médio | Alto |
| **Tempo de dev** | 2h | 30min |
| **Bugs potenciais** | Alto | Baixo |
| **Manutenibilidade** | Difícil | Fácil |

---

## 💡 Dicas Pro

1. **Use tags únicas por screen**: `AppLogger.info('LoginScreen', ...)`
2. **Log em pontos críticos**: entrada, sucesso, erro
3. **Use tipos de erro específicos**: `UnauthorizedException`, `NetworkException`
4. **Valide no form, não no submit**: validador retorna `String?`
5. **Estenda BaseProvider sempre**: automação = menos bugs

---

**Pronto para usar! 🚀**

Comece por 1 screen hoje. Amanhã 3 a mais. Semana que vem toda app modernizada! ⭐
