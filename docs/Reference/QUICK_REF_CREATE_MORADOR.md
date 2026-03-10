# Quick Reference: Create Morador Screen

## 🎯 What Was Built?
A professional Flutter screen that allows administrators to create a new Morador (resident) by:
1. Entering the resident's name
2. Selecting a user from dropdown
3. Selecting an apartment from dropdown
4. Submitting to create the record

---

## 📂 Key Files

| File | Purpose |
|------|---------|
| `lib/screens/users/create_morador_screen.dart` | Main screen widget |
| `lib/dto/api_dtos.dart` | CriarMoradorDto class (added) |
| `lib/main.dart` | Route registration (modified) |

---

## 🔗 Navigation

```dart
// From anywhere in the app:
Navigator.pushNamed(context, '/moradores-novo');

// Or programmatically:
Navigator.of(context).pushNamed('/moradores-novo');
```

---

## 🎨 Visual Components

### Dropdowns
**User Dropdown:**
- Shows avatar + name + phone
- Pre-filtered to "Morador" type users only

**Apartment Dropdown:**
- Shows apartment number + block + floor
- Only shows available (unoccupied) apartments

### Buttons
- **Create Morador** - Orange button (primary action)
- **Cancel** - Orange outline button (secondary action)

---

## 📡 API Flow

1. **Load Data** (on screen init):
   - GET `/api/usuarios?tipo=Morador`
   - GET `/api/apartamentos?estado=Disponivel`

2. **Create** (on submit):
   - POST `/api/moradores`
   - Body: `{ nome, usuarioId, apartamentoId }`

3. **Response**:
   - Success → Close screen + refresh parent
   - Error → Show error message + stay on screen

---

## 🏗️ Architecture

```
CreateMoradorScreen
├── UsuariosProvider (load users)
├── ApartamentosProvider (load apartments)
└── MoradoresProvider (create morador)
```

---

## ✅ Features

- ✅ Dropdown selection for users
- ✅ Dropdown selection for apartments
- ✅ Form validation
- ✅ Loading indicators
- ✅ Error handling
- ✅ Success feedback
- ✅ Theme-compliant styling
- ✅ Smooth animations
- ✅ Empty state handling
- ✅ Portuguese labels

---

## 🚨 Important Notes

1. **Authorization**: Only Administrador role can create moradores (enforced by backend)
2. **User Filter**: Only shows users of type "Morador"
3. **Apartment Filter**: Only shows apartments with status "Disponivel"
4. **After Creation**: Apartment automatically changes to "Ocupado"

---

## 🔄 Provider Methods Used

```dart
// UsuariosProvider
await context.read<UsuariosProvider>()
    .carregarUsuarios(tipo: 'Morador');

// ApartamentosProvider
await context.read<ApartamentosProvider>()
    .carregarApartamentos(estado: 'Disponivel');

// MoradoresProvider
await context.read<MoradoresProvider>()
    .criarMorador(moradorData.toJson());
```

---

## 💻 Code Example: Adding Button to Link Screen

```dart
// In ManageResidentsScreen or similar:
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/moradores-novo');
  },
  child: const Text('Criar Novo Morador'),
),
```

---

## 🎨 Theme Colors Used

- Primary Orange: `#FF7A3D` - Buttons, icons, focus states
- Primary Brown: `#2D1B0E` - AppBar
- Background: `#FAFAF8` - Screen background
- Success: `#10B981` - Success messages
- Error: `#EF4444` - Error messages

---

**Documentation:** [MORADOR_CREATION_SCREEN.md](MORADOR_CREATION_SCREEN.md)  
**Last Updated:** January 23, 2026
