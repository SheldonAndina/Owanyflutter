# 🎯 Guia Rápido - Usar as Melhorias PRO

## 1️⃣ Imports Essenciais

```dart
// Constants
import 'package:owany_app/constants/app_constants.dart';

// Utils
import 'package:owany_app/utils/app_validator.dart';
import 'package:owany_app/utils/app_formatter.dart';
import 'package:owany_app/utils/app_logger.dart';
import 'package:owany_app/utils/app_exception.dart';
import 'package:owany_app/utils/extensions.dart';
import 'package:owany_app/utils/app_result.dart';

// Providers
import 'package:owany_app/providers/base_provider.dart';

// Services
import 'package:owany_app/services/advanced_api_service.dart';
```

---

## 2️⃣ Usar em Formulários

### Validação Profissional

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      // Email
      TextFormField(
        decoration: InputDecoration(hintText: 'Email'),
        validator: AppValidator.validateEmail,
      ),
      
      // Telefone
      TextFormField(
        decoration: InputDecoration(
          hintText: AppFormatter.formatPhone('11999999999'),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: AppValidator.validatePhone,
      ),
      
      // Senha forte
      TextFormField(
        decoration: InputDecoration(hintText: 'Senha'),
        obscureText: true,
        validator: AppValidator.validatePassword,
      ),
      
      // Nome
      TextFormField(
        decoration: InputDecoration(hintText: 'Nome'),
        validator: AppValidator.validateName,
      ),
    ],
  ),
)
```

---

## 3️⃣ Criar Provider Profissional

```dart
import 'package:flutter/material.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';

class UsuariosProvider extends BaseProvider with CacheMixin<List<Usuario>> {
  final _apiService = ApiService();
  
  List<Usuario> _usuarios = [];
  List<Usuario> get usuarios => _usuarios;

  /// Carregar usuários com cache
  Future<void> carregarUsuarios() async {
    await executeOperation(
      () async {
        // Verificar cache primeiro
        final cached = cachedData;
        if (cached != null) {
          _usuarios = cached;
          return;
        }

        // Se não, buscar da API
        _usuarios = await _apiService.getUsuarios();
        
        // Atualizar cache
        updateCache(_usuarios);
        return _usuarios;
      },
      operationName: 'carregarUsuarios',
    );
  }

  /// Buscar usuário específico
  Future<Usuario?> buscarUsuario(String id) async {
    return await executeOperation(
      () => _apiService.getUsuario(id),
      operationName: 'buscarUsuario($id)',
    );
  }

  /// Criar usuário
  Future<void> criarUsuario(Map<String, dynamic> dados) async {
    await executeOperation(
      () async {
        final novo = await _apiService.criarUsuario(dados);
        _usuarios.add(novo);
        invalidateCache(); // Invalidar cache após mudança
        return novo;
      },
      operationName: 'criarUsuario',
    );
  }
}
```

---

## 4️⃣ Usar Provider em Tela

```dart
class UsuariosScreen extends StatefulWidget {
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados na inicialização
    context.read<UsuariosProvider>().carregarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UsuariosProvider>(
        builder: (context, provider, _) {
          // Loading
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Erro
          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'Erro desconhecido'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.carregarUsuarios(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          // Sucesso
          return ListView.builder(
            itemCount: provider.usuarios.length,
            itemBuilder: (context, index) {
              final usuario = provider.usuarios[index];
              return ListTile(
                // Use extensions para iniciais
                leading: CircleAvatar(
                  child: Text(usuario.nome.initials),
                ),
                title: Text(usuario.nome.capitalized),
                subtitle: Text(usuario.telefone.formattedPhone),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 5️⃣ Usar Logging

```dart
import 'utils/app_logger.dart';

class MyService {
  static const _tag = 'MyService';

  Future<void> doSomething() async {
    try {
      AppLogger.info(_tag, 'Iniciando operação');
      
      // ... seu código
      
      AppLogger.debug(_tag, 'Operação intermediária completa');
      
      AppLogger.info(_tag, 'Operação finalizada com sucesso');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Erro durante operação', e, stackTrace);
      rethrow;
    }
  }

  // Ver logs
  void showLogs() {
    final logs = AppLogger.exportLogs();
    print(logs);
  }
}
```

---

## 6️⃣ Tratamento de Erros

```dart
Future<void> fazerRequisicao() async {
  try {
    final dados = await apiService.fetchData();
    // usar dados
  } on UnauthorizedException {
    // Redirecionar para login
    Navigator.pushNamed(context, '/login');
  } on NetworkException {
    // Mostrar diálogo de retry
    showErrorDialog('Sem conexão', 'Verifique sua internet');
  } on TimeoutException {
    // Timeout
    showErrorDialog('Timeout', 'Servidor não respondeu a tempo');
  } on ValidationException catch (e) {
    // Erro de validação com lista de erros
    showValidationErrors(e.errors);
  } on AppException catch (e) {
    // Qualquer outra exceção da app
    showErrorDialog('Erro', e.message);
  } catch (e) {
    // Erro inesperado
    AppLogger.error('MyScreen', 'Erro inesperado', e);
    showErrorDialog('Erro', 'Algo deu errado');
  }
}
```

---

## 7️⃣ Usar Formatadores

```dart
// Datas
Text(date.formatted); // "23/01/2026"
Text(date.formattedWithTime); // "23/01/2026 10:30"
Text(date.relativeTime); // "há 2 horas"

// Informações pessoais
Text(AppFormatter.formatPhone(phone)); // "(11) 99999-9999"
Text(AppFormatter.formatCPF(cpf)); // "123.456.789-00"

// Monetário
Text(AppFormatter.formatCurrency(valor)); // "R$ 1.500,00"

// Textos
Text(nome.capitalized); // "João Silva"
Text(nome.initials); // "JS"

// Tamanhos
Text(AppFormatter.formatFileSize(bytes));
```

---

## 8️⃣ Usar Extensions

```dart
// Strings
'email@example.com'.isValidEmail // true
'11999999999'.isValidPhone // true
'#FF5733'.toColor() // Color object

// Datas
date.isToday // true/false
date.ageInYears // 25
date.dayOfWeekName // "Segunda"

// Listas
list.chunk(10) // Dividir em grupos
list.removeDuplicates() // Remover duplicatas
list.flatten() // Achatar lista aninhada

// Maps
map.mapValues((v) => v.toUpperCase())
map.filterByKeys((k) => k.startsWith('user_'))

// Nullable
name?.let((n) => showName(n))
value ?? defaultValue
```

---

## 9️⃣ Usar Result Pattern

```dart
// Chamada com retry
final advancedApi = AdvancedApiService();
try {
  final result = await advancedApi.retryOperation(
    () => apiService.fetchUsers(),
    maxRetries: 3,
  );
  // usar result
} on AppException catch (e) {
  showError(e.message);
}
```

---

## 🔟 Arquivo de Configuração

Todas as constantes de app em um único lugar:

```dart
// Usar constantes
print(AppConstants.apiBaseUrl);
print(AppConstants.pageSize);
print(AppConstants.cacheDuration);

// Adicionar novas constantes conforme necessário
```

---

## 📋 Checklist de Implementação

Ao criar uma nova tela/feature:

- [ ] Importar `extensions.dart` para usar helpers
- [ ] Usar `AppValidator` para validações
- [ ] Usar `AppFormatter` para formatação
- [ ] Usar `AppLogger` para debug
- [ ] Herdar `BaseProvider` em providers
- [ ] Usar `AppConstants` ao invés de valores hardcoded
- [ ] Tratar erros com `AppException`
- [ ] Usar `executeOperation` em providers para state management
- [ ] Testar com diferentes cenários de erro

---

## 🎓 Exemplos Completos

### Tela de Login com Validação

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      await auth.login(
        _telefoneController.text,
        _senhaController.text,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on UnauthorizedException {
      showSnackBar('Telefone ou senha incorretos');
    } on NetworkException {
      showSnackBar('Sem conexão com internet');
    } catch (e) {
      showSnackBar('Erro ao fazer login');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 40),
              Text('Login', style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 32),
              
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  hintText: AppFormatter.formatPhone('11999999999'),
                  prefixIcon: Icon(Icons.phone),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: AppValidator.validatePhone,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: AppValidator.validatePassword,
              ),
              SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Entrar'),
                ),
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

**Pronto para usar! 🚀**

Todas as melhorias são acessíveis e prontas. Basta importar e usar os padrões acima.
