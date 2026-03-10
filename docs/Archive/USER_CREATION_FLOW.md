# 🔐 Fluxo de Criação de Usuários - Owany App

## ✅ Implementação Completa

### Arquitetura
```
Admin/Síndico
    ↓
AddUserScreen (form com rol & SMS checkbox)
    ↓
ApiService.criarFuncionario()
    ↓
POST /api/usuarios (com enviarSMS flag)
    ↓
Backend valida & cria user
    ↓
[Opcional] Envia SMS com credenciais
    ↓
Usuário faz login no app
    ↓
[Opcional no backend] Força troca de senha
```

---

## 📋 Fluxo Passo-a-Passo

### 1️⃣ **Admin acessa painel**
- Login com credenciais de admin
- Navega para "Usuários" → "Novo Usuário"

### 2️⃣ **Admin cria novo usuário**
**AddUserScreen** com campos:
- **Nome Completo** (obrigatório)
- **Nome de Login** (obrigatório, unique)
- **Telefone** (9 dígitos, +258 prefix automático)
- **Tipo de Usuário** (dropdown):
  - Funcionário
  - Síndico
  - Portaria
  - Administrador
  - *(Morador pode ser criado também)*
- **Senha** (mínimo 6 caracteres)
- **Confirmar Senha** (validação)
- **☑️ Enviar SMS com credenciais** (checkbox - opcional)

### 3️⃣ **Sistema submete dados**
```dart
await _apiService.criarFuncionario(
  nome: 'João Silva',
  nomeLogin: 'joaosilva',
  telefone: '+258847895941',
  tipo: 'Funcionário',
  senha: 'TempPassword123!',
  enviarSMS: true,  // ← Flag opcional
);
```

### 4️⃣ **Backend processa**
- Valida dados
- Cria usuário com `ativo: true`
- Se `enviarSMS: true`: Envia SMS
  ```
  SMS: "Bem-vindo! Login: joaosilva | Senha: TempPassword123!"
  ```
- Retorna usuário criado (HTTP 201)

### 5️⃣ **Usuário faz login**
- Recebe SMS (se checkbox estava marcado)
- App: Login Screen
- Digita: `joaosilva` / `TempPassword123!`
- Backend valida credenciais + JWT token

### 6️⃣ **[Opcional] Troca de senha obrigatória**
- Backend pode marcar `senhaExpirada: true`
- App mostra ChangePasswordScreen no 1º login
- Força user a criar nova senha antes de usar app

---

## 🔄 Fluxo para Moradores (Special Case)

Se Admin cria **Tipo: Morador**:
1. Usuário criado com `tipo: 'Morador'`
2. **Admin deve vincular a Apartamento** em painel separado
3. Depois morador faz login
4. Só pode ver dados do seu apartamento

---

## 🛠️ Implementação Técnica

### Files Modificados

#### 1. **ApiService** (`lib/services/api_service.dart`)
```dart
Future<Usuario> criarFuncionario({
  required String nome,
  required String nomeLogin,
  required String telefone,
  required String tipo,
  required String senha,
  bool enviarSMS = false,  // ← NEW
}) async {
  final body = {
    'nome': nome,
    'nomeLogin': nomeLogin,
    'telefone': telefone,
    'tipo': tipo,
    'senha': senha,
    'ativo': true,
    'enviarSMS': enviarSMS,  // ← Sent to backend
  };
  
  return request<Usuario>(
    'usuarios',
    method: 'POST',
    body: body,
    fromJson: (json) => Usuario.fromJson(json),
  );
}
```

#### 2. **AddUserScreen** (`lib/screens/users/add_user_screen.dart`)
```dart
class _AddUserScreenState extends State<AddUserScreen> {
  bool _enviarSMS = false;  // ← NEW state
  
  List<UsuarioTipo> get _rolesDisponiveis => [
    UsuarioTipo.Funcionario,
    UsuarioTipo.Sindico,
    UsuarioTipo.Portaria,
    UsuarioTipo.Administrador,
  ];
  
  Future<void> _criarUsuario() async {
    // ... validation ...
    
    await _apiService.criarFuncionario(
      nome: _nomeController.text.trim(),
      nomeLogin: _nomeLoginController.text.trim(),
      telefone: telefoneFormatado,
      tipo: _tipoSelecionado.toPortuguese(),
      senha: _senhaController.text,
      enviarSMS: _enviarSMS,  // ← Include SMS flag
    );
  }
}
```

**UI com checkbox:**
```dart
CheckboxListTile(
  value: _enviarSMS,
  onChanged: (value) => setState(() => _enviarSMS = value ?? false),
  title: Text('Enviar SMS com credenciais'),
  subtitle: Text('Usuário receberá login e senha temporária por SMS'),
  activeColor: OwanyTheme.primaryOrange,
)
```

#### 3. **main.dart** (routes)
```dart
// Public routes (sem auth)
'/login'           → LoginScreen()
'/register'        → RegisterScreen()
'/forgot-password' → ForgotPasswordScreen()

// Protected routes (com auth)
'/usuarios'        → UsersScreen()
'/usuarios/novo'   → AddUserScreen()  ← Admin only
```

---

## 📱 User Stories

### ✅ Admin Creates Funcionário
```
1. Admin login → Dashboard
2. Menu → Usuários → "Novo Usuário"
3. Preenche: João Silva | joaosilva | +258847895941 | Funcionário | Senha123!
4. ☑️ Marca "Enviar SMS com credenciais"
5. Clica "Criar Usuário"
6. Backend: Cria user + envia SMS
7. João recebe: "Login: joaosilva | Senha: Senha123!"
8. João faz login no app
```

### ✅ Admin Creates Morador (sem SMS)
```
1. Admin → "Novo Usuário"
2. Preenche: Maria Silva | marisilva | +258827654321 | Morador | Senha456!
3. ☐ NÃO marca SMS (admin entrega senha pessoalmente)
4. Clica "Criar Usuário"
5. Backend: Cria Morador
6. Admin depois vincula a Apartamento
7. Maria faz login quando admin avisar
```

---

## 🔒 Validações

### Frontend (AddUserScreen)
- ✅ Nome Completo: não vazio
- ✅ Nome Login: não vazio, sem espaços
- ✅ Telefone: 9 dígitos, auto-format +258
- ✅ Tipo: não vazio (dropdown obrigatório)
- ✅ Senha: mínimo 6 caracteres
- ✅ Confirmar Senha: deve bater com Senha

### Backend (esperado)
- ✅ Autenticação: Bearer token (admin only)
- ✅ Validação: nome único? login único?
- ✅ Tipo válido: enum UsuarioTipo
- ✅ SMS: Se `enviarSMS: true`, envia SMS com credenciais

---

## 📌 Status de Implementação

| Feature | Status | Notas |
|---------|--------|-------|
| Form com campos obrigatórios | ✅ Completo | AddUserScreen com validação |
| Dropdown de tipos | ✅ Completo | Exclui Morador/Visitante (opcional) |
| Checkbox SMS | ✅ Completo | Bool `enviarSMS` enviado ao backend |
| API POST /api/usuarios | ✅ Integrado | Com parâmetro `enviarSMS` |
| Rota /usuarios/novo | ✅ Integrado | Protected (requer auth) |
| Mensagem de sucesso | ✅ Integrado | Snackbar verde + volta à lista |
| Mensagem de erro | ✅ Integrado | Snackbar vermelho + stack trace |
| SMS backend | ⏳ Backend | Aguarda implementação |
| Change password no 1º login | ⏳ Backend | Opcional - depende de backend |

---

## 🚀 Próximos Passos

1. **Backend implementar:**
   - ✅ POST /api/usuarios (já existe)
   - Validar `enviarSMS` flag
   - Se true: Enviar SMS via Twilio/similiar

2. **Frontend testes:**
   - Testar com backend em execução
   - Criar usuário com SMS = true/false
   - Verificar se aparece em lista de usuários

3. **Opcional:**
   - Implementar força de mudança de senha no 1º login
   - Adicionar campo "Temporária" na senha (backend)
   - Página de reset de senha por SMS/email

---

## 💬 Estrutura do Request

### POST /api/usuarios
```json
{
  "nome": "João Silva",
  "nomeLogin": "joaosilva",
  "telefone": "+258847895941",
  "tipo": "Funcionário",
  "senha": "TempPassword123!",
  "ativo": true,
  "enviarSMS": true
}
```

### Response (Sucesso)
```json
{
  "sucesso": true,
  "mensagem": "Usuário criado com sucesso",
  "dados": {
    "id": "uuid-aqui",
    "nome": "João Silva",
    "nomeLogin": "joaosilva",
    "telefone": "+258847895941",
    "tipo": "Funcionário",
    "ativo": true,
    "criadoEm": "2026-01-26T14:30:00Z"
  },
  "erros": []
}
```

---

**Last Updated**: 26 January 2026  
**Status**: 🟢 Ready for Testing  
**Backend Dependency**: SMS implementation in progress
