# 🛠️ Guia de Implementação Prática – OWANY
## Como Aplicar o Design System em Cada Tela

**Status**: 🚀 Ready to implement  
**Framework**: Flutter + Material 3  
**Package Versions**: flutter_3.x, provider 6.x

---

## 📋 Índice

1. [Estrutura de Arquivo](#estrutura-de-arquivo)
2. [Padrões de Tela](#padrões-de-tela)
3. [Exemplos Práticos](#exemplos-práticos)
4. [Troubleshooting](#troubleshooting)

---

# 📁 Estrutura de Arquivo

## Layout Recomendado

```
lib/
├── constants/
│   ├── idioma.dart                 # I18n strings
│   └── strings.dart                # NOVO: UI strings
│
├── theme/
│   ├── owany_theme.dart            # ✅ Existe
│   └── theme_extensions.dart       # NOVO: Extensions
│
├── widgets/                        # NOVO DIRETÓRIO
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   └── tertiary_button.dart
│   ├── cards/
│   │   ├── info_card.dart
│   │   ├── status_card.dart
│   │   └── section_card.dart
│   ├── dialogs/
│   │   └── confirm_dialog.dart
│   ├── empty_states/
│   │   └── empty_state_widget.dart
│   ├── loading/
│   │   ├── shimmer_card.dart
│   │   └── loading_overlay.dart
│   ├── badges/
│   │   └── status_badge.dart
│   └── common/
│       ├── app_bar_gradient.dart
│       ├── section_header.dart
│       └── custom_text_field.dart
│
├── screens/
│   ├── login_screen.dart           # ✅ Existe, refatorar
│   ├── dashboard_screen.dart       # ✅ Modernizado
│   ├── maintenance_list_screen.dart # TODO: Refazer
│   ├── maintenance_detail_screen.dart # TODO: Refazer
│   └── ...
```

---

# 🖼️ Padrões de Tela

## Padrão 1: Tela com CustomScrollView + SliverAppBar

```dart
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen>
    with SingleTickerProviderStateMixin {
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
          // 1. Header com Gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildGradientHeader(),
            ),
          ),
          // 2. Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(_buildContent()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OwanyTheme.primaryOrange,
            OwanyTheme.primaryOrange.withOpacity(0.7),
            OwanyTheme.softOrange.withOpacity(0.5),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subtítulo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Título Página',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      // Card exemplo
      Container(
        padding: const EdgeInsets.all(16),
        decoration: OwanyTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seção 1',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conteúdo aqui',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Botões
      PrimaryButton(
        label: 'Ação Principal',
        onPressed: () {},
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Ação Secundária',
        onPressed: () => Navigator.pop(context),
      ),
    ];
  }
}
```

---

## Padrão 2: Tela com ListView (Lista Simples)

```dart
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados
    Future.microtask(() {
      context.read<MyProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.background,
      appBar: AppBar(
        title: const Text('Minha Lista'),
        elevation: 0,
        backgroundColor: OwanyTheme.surface,
      ),
      body: Consumer<MyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (provider.items.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_rounded,
              title: 'Nenhum item',
              subtitle: 'Crie um novo para começar',
              actionLabel: 'Criar',
              onAction: () {},
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StatusCard(
                  title: item.title,
                  location: item.location,
                  status: item.status,
                  date: item.date,
                  onTap: () => _viewDetail(item.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: OwanyTheme.surface,
            highlightColor: Colors.grey[100]!,
            child: ShimmerCard(height: 100),
          ),
        );
      },
    );
  }

  void _viewDetail(String id) {
    Navigator.pushNamed(context, '/detail', arguments: id);
  }
}
```

---

## Padrão 3: Tela com Formulário

```dart
class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.background,
      appBar: AppBar(
        title: const Text('Nova Solicitação'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Salvando...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seção 1
                SectionHeader(
                  title: 'Informações Básicas',
                  subtitle: 'Preencha os dados principais',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Título',
                  hint: 'Ex: Vazamento na cozinha',
                  icon: Icons.build_rounded,
                  controller: _titleController,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Descrição Detalhada',
                  hint: 'Descreva o problema em detalhes',
                  controller: _descriptionController,
                  maxLines: 5,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 32),

                // Seção 2
                SectionHeader(
                  title: 'Detalhes Adicionais',
                  subtitle: 'Preencha informações complementares',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(value: 'apt1', child: Text('Apt 502')),
                    DropdownMenuItem(value: 'apt2', child: Text('Apt 601')),
                  ],
                  onChanged: (value) {},
                  decoration: OwanyTheme.inputDecoration(
                    label: 'Apartamento',
                    icon: Icons.home_rounded,
                  ),
                ),
                const SizedBox(height: 32),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cancelar',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Salvar',
                        isLoading: _isLoading,
                        onPressed: _submitForm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Chamar API
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('Solicitação criada com sucesso!'),
        );
        Navigator.pop(context);
      });
    }
  }
}
```

---

# 🔧 Troubleshooting

## Problema 1: Gradient não aparece

**Solução**:
```dart
// ❌ Errado
Container(
  decoration: BoxDecoration(gradient: ...),
  child: Text('Não aparece'),
)

// ✅ Correto
Container(
  decoration: BoxDecoration(gradient: ...),
  child: Padding(
    padding: ...,
    child: Text('Aparece'),
  ),
)

// ✅ Melhor (para SliverAppBar)
Container(
  decoration: BoxDecoration(gradient: ...),
)
```

## Problema 2: Texto branco não aparece bem em gradient

**Solução**:
```dart
// Usar softOrange no gradiente com opacidade
LinearGradient(
  colors: [
    primaryOrange,
    primaryOrange.withOpacity(0.7),
    softOrange.withOpacity(0.5), // ← Mais claro no final
  ],
)
```

## Problema 3: Cards com sombra muito forte

**Solução**:
```dart
// Usar OwanyTheme.cardDecoration() que já tem sombra correta
decoration: OwanyTheme.cardDecoration()

// Ou customizar
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.12), // Menos escuro
    blurRadius: 12, // Menos blur
    offset: const Offset(0, 4), // Menos offset
  ),
]
```

---

**Last Updated**: 21 January 2026  
**Version**: 1.0  
**Status**: ✅ Ready for Development

