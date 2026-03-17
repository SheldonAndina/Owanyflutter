import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/niveis_acesso_provider.dart';
import '../../providers/auth_provider.dart';
import '../../dto/niveis_acesso_dtos.dart';
import '../../services/api_service.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../models/niveis_acesso.dart';
import '../../models/enums.dart';

/// Locale-aware text helper accessible from all widgets in this file.
String _txCtx(BuildContext context, String pt, String en) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code.startsWith('en') ? en : pt;
}

/// Tela de gerenciamento de Níveis de Acesso
/// Permite visualizar roles, permissões e gerenciar acessos de usuários
class NiveisAcessoScreen extends StatefulWidget {
  const NiveisAcessoScreen({super.key});

  @override
  State<NiveisAcessoScreen> createState() => _NiveisAcessoScreenState();
}

class _NiveisAcessoScreenState extends State<NiveisAcessoScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _searchController = TextEditingController();
  int _tabCount = 1;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    _initTabController();
    _carregarDados();
  }

  void _initTabController() {
    final authProvider = context.read<AuthProvider>();
    final userRole = authProvider.usuarioAtual?.tipo;
    
    // Define quantas tabs mostrar baseado no role
    if (userRole == UsuarioTipo.Administrador) {
      _tabCount = 3; // Meu Acesso, Roles, Usuários
    } else if (userRole == UsuarioTipo.Sindico) {
      _tabCount = 2; // Meu Acesso, Roles
    } else {
      _tabCount = 1; // Apenas Meu Acesso
    }
    
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  void _carregarDados() {
    final provider = context.read<NiveisAcessoProvider>();
    provider.carregarMeuAcesso();
    
    final authProvider = context.read<AuthProvider>();
    final userRole = authProvider.usuarioAtual?.tipo;
    
    // Só carrega roles e usuários se tiver permissão
    if (userRole == UsuarioTipo.Administrador || userRole == UsuarioTipo.Sindico) {
      provider.carregarRoles();
    }
    if (userRole == UsuarioTipo.Administrador) {
      provider.carregarUsuarios();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Tab> _buildTabs() {
    final tabs = <Tab>[
      Tab(text: _tx('Meu Acesso', 'My Access'), icon: const Icon(Icons.person_outlined)),
    ];
    
    if (_tabCount >= 2) {
      tabs.add(Tab(text: _tx('Roles', 'Roles'), icon: const Icon(Icons.shield_outlined)));
    }
    if (_tabCount >= 3) {
      tabs.add(Tab(text: _tx('Usuários', 'Users'), icon: const Icon(Icons.people_outlined)));
    }
    
    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      _buildMeuAcessoTab(),
    ];
    
    if (_tabCount >= 2) {
      views.add(_buildRolesTab());
    }
    if (_tabCount >= 3) {
      views.add(_buildUsuariosTab());
    }
    
    return views;
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context),
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: OwanyTheme.primaryOrange,
                unselectedLabelColor: OwanyTheme.textMutedColor(context),
                indicatorColor: OwanyTheme.primaryOrange,
                indicatorWeight: 3,
                tabs: _buildTabs(),
              ),
              backgroundColor: OwanyTheme.cardColor(context),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _buildTabViews(),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: OwanyTheme.primaryOrange,
      foregroundColor: OwanyTheme.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                OwanyTheme.primaryOrange,
                OwanyTheme.primaryOrange.withValues(alpha: 0.85)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OwanyTheme.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.security, color: OwanyTheme.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tx('Níveis de Acesso', 'Access Levels'),
                          style: TextStyle(
                            color: OwanyTheme.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tx('Gerencie permissões e roles', 'Manage permissions and roles'),
                          style: TextStyle(
                            color: OwanyTheme.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _carregarDados,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: _tx('Atualizar', 'Refresh'),
        ),
      ],
    );
  }

  Widget _buildMeuAcessoTab() {
    return Consumer<NiveisAcessoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.meuAcesso == null) {
          return const Center(child: SkeletonListLoader(itemCount: 5));
        }

        final meuAcesso = provider.meuAcesso;
        if (meuAcesso == null) {
          return EmptyState(
            icon: Icons.lock_outline,
            title: _tx('Não foi possível carregar', 'Could not load'),
            subtitle: provider.errorMessage ?? _tx('Tente novamente', 'Try again'),
            actionLabel: _tx('Tentar Novamente', 'Try Again'),
            onAction: () => provider.carregarMeuAcesso(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeuAcessoCard(meuAcesso, provider),
              const SizedBox(height: 24),
              _buildMinhasPermissoesSection(meuAcesso, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeuAcessoCard(MeuAcesso meuAcesso, NiveisAcessoProvider provider) {
    final corRole = provider.getCorRole(meuAcesso.role);
    final iconeRole = provider.getIconeRole(meuAcesso.role);

    return Container(
      decoration: OwanyTheme.elevatedCardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: corRole.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconeRole, size: 36, color: corRole),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meuAcesso.nome,
                      style: OwanyTheme.titleStyle(context, fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${meuAcesso.nomeLogin}',
                      style: TextStyle(
                        color: OwanyTheme.textMutedColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: corRole.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: corRole.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: corRole, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meuAcesso.roleDescricao,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: corRole,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${meuAcesso.totalPermissoes} ${_tx('permissões', 'permissions')}',
                        style: TextStyle(
                          color: corRole.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: corRole,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meuAcesso.role,
                    style: const TextStyle(
                      color: OwanyTheme.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinhasPermissoesSection(MeuAcesso meuAcesso, NiveisAcessoProvider provider) {
    final permissoesPorCategoria = provider.agruparPermissoesPorCategoria(meuAcesso.permissoes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.key, color: OwanyTheme.primaryOrange),
            const SizedBox(width: 8),
            Text(
              'Minhas Permissões',
              style: OwanyTheme.titleStyle(context, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...permissoesPorCategoria.entries.map((entry) => _buildCategoriaPermissoes(
          entry.key,
          entry.value,
        )),
      ],
    );
  }

  Widget _buildCategoriaPermissoes(String categoria, List<String> permissoes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: OwanyTheme.cardDecoration(context),
      child: ExpansionTile(
        leading: Icon(
          _getIconeCategoria(categoria),
          color: OwanyTheme.primaryOrange,
        ),
        title: Text(
          categoria,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${permissoes.length} permissões',
          style: TextStyle(
            color: OwanyTheme.textMutedColor(context),
            fontSize: 12,
          ),
        ),
        children: permissoes.map((permissao) => ListTile(
          dense: true,
          leading: const Icon(Icons.check_circle, color: OwanyTheme.success, size: 20),
          title: Text(
            Permissoes.getDescricao(permissao),
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            permissao,
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        )).toList(),
      ),
    );
  }

  IconData _getIconeCategoria(String categoria) {
    final icones = {
      'Usuários': Icons.people,
      'Apartamentos': Icons.apartment,
      'Solicitações': Icons.assignment,
      'Manutenções': Icons.build,
      'Agendamentos': Icons.calendar_today,
      'Itens': Icons.inventory,
      'Notificações': Icons.notifications,
      'Auditoria': Icons.history,
      'Dashboard': Icons.dashboard,
      'Relatórios': Icons.assessment,
      'Sistema': Icons.settings,
    };
    return icones[categoria] ?? Icons.folder;
  }

  Widget _buildRolesTab() {
    return Consumer<NiveisAcessoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRoles && provider.roles.isEmpty) {
          return const Center(child: SkeletonListLoader(itemCount: 6));
        }

        if (provider.roles.isEmpty) {
          return EmptyState(
            icon: Icons.shield_outlined,
            title: _tx('Nenhum role encontrado', 'No role found'),
            subtitle: provider.errorMessage ?? _tx('Tente novamente', 'Try again'),
            actionLabel: _tx('Tentar Novamente', 'Try Again'),
            onAction: () => provider.carregarRoles(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.roles.length,
          itemBuilder: (context, index) {
            final role = provider.roles[index];
            return _buildRoleCard(role, provider);
          },
        );
      },
    );
  }

  Widget _buildRoleCard(RoleResponse role, NiveisAcessoProvider provider) {
    final corRole = provider.getCorRole(role.role);
    final iconeRole = provider.getIconeRole(role.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: OwanyTheme.cardDecoration(context),
      child: InkWell(
        onTap: () => _mostrarPermissoesDoRole(role.role),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: corRole.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconeRole, color: corRole, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.descricao,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: corRole.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role.role,
                            style: TextStyle(
                              color: corRole,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.key, size: 14, color: OwanyTheme.textMutedColor(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${role.totalPermissoes} permissões',
                          style: TextStyle(
                            color: OwanyTheme.textMutedColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: OwanyTheme.surfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nível ${role.nivelAcesso}',
                      style: TextStyle(
                        color: OwanyTheme.textMutedColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: OwanyTheme.primaryOrange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogResetarSenha(UsuarioRoleResponse usuario) {
    final senhaController = TextEditingController();
    final confirmarController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool obscureNova = true;
    bool obscureConfirmar = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: OwanyTheme.cardColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: OwanyTheme.warning, size: 22),
              const SizedBox(width: 10),
              Text(_tx('Resetar Senha', 'Reset Password'),
                  style: TextStyle(color: OwanyTheme.textPrimary(ctx))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_tx('Usuário', 'User')}: ${usuario.nome}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: OwanyTheme.textPrimary(ctx),
                  )),
              Text(
                '${_tx('Login', 'Login')}: ${usuario.nomeLogin}',
                style: TextStyle(
                  color: OwanyTheme.textMutedColor(ctx),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: senhaController,
                obscureText: obscureNova,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: _tx('Nova Senha', 'New Password'),
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscureNova ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: OwanyTheme.textMutedColor(ctx)),
                    onPressed: () => setDialogState(() => obscureNova = !obscureNova),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmarController,
                obscureText: obscureConfirmar,
                style: TextStyle(color: OwanyTheme.textPrimary(ctx)),
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: _tx('Confirmar Nova Senha', 'Confirm New Password'),
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirmar ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: OwanyTheme.textMutedColor(ctx)),
                    onPressed: () => setDialogState(() => obscureConfirmar = !obscureConfirmar),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_tx('Cancelar', 'Cancel'),
                  style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_reset_rounded, size: 18),
              label: Text(_tx('Resetar', 'Reset')),
              style: ElevatedButton.styleFrom(
                backgroundColor: OwanyTheme.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final novaSenha = senhaController.text.trim();
                final confirmar = confirmarController.text.trim();

                if (novaSenha.isEmpty || confirmar.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      _tx('Preencha todos os campos', 'Fill in all fields'),
                      type: SnackBarType.error,
                    ),
                  );
                  return;
                }
                if (novaSenha != confirmar) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      _tx('As senhas não coincidem', 'Passwords do not match'),
                      type: SnackBarType.error,
                    ),
                  );
                  return;
                }
                if (novaSenha.length < 6) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      _tx(
                        'A senha deve ter pelo menos 6 caracteres',
                        'Password must be at least 6 characters',
                      ),
                      type: SnackBarType.error,
                    ),
                  );
                  return;
                }

                try {
                  await ApiService().resetSenhaAdmin(
                    usuario.id,
                    novaSenha: novaSenha,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      '${_tx('Senha de', 'Password for')} ${usuario.nome} ${_tx('resetada com sucesso!', 'reset successfully!')}',
                      type: SnackBarType.success,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      '${_tx('Erro ao resetar senha', 'Error resetting password')}: $e',
                      type: SnackBarType.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPermissoesDoRole(String role) {
    final provider = context.read<NiveisAcessoProvider>();
    provider.carregarPermissoesDoRole(role);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RolePermissoesSheet(role: role),
    );
  }

  Widget _buildUsuariosTab() {
    return Consumer<NiveisAcessoProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingUsuarios && provider.usuarios.isEmpty) {
          return const Center(child: SkeletonListLoader(itemCount: 5));
        }

        return Column(
          children: [
            _buildFiltrosUsuarios(provider),
            Expanded(
              child: provider.usuarios.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outlined,
                      title: _tx('Nenhum usuário encontrado', 'No users found'),
                      subtitle: provider.errorMessage ?? _tx('Tente novamente', 'Try again'),
                      actionLabel: _tx('Tentar Novamente', 'Try Again'),
                      onAction: () => provider.carregarUsuarios(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.usuarios.length,
                      itemBuilder: (context, index) {
                        final usuario = provider.usuarios[index];
                        return _buildUsuarioCard(usuario, provider);
                      },
                    ),
            ),
            if (provider.totalPaginas > 1) _buildPaginacao(provider),
          ],
        );
      },
    );
  }

  Widget _buildFiltrosUsuarios(NiveisAcessoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: OwanyTheme.adaptiveInputDecoration(
                context,
                label: _tx('Buscar usuário', 'Search user'),
                hint: _tx('Nome ou login', 'Name or login'),
                icon: Icons.search,
              ),
              onChanged: (value) {
                // Implementar filtro local se necessário
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: OwanyTheme.cardDecoration(context),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: _tx('Filtrar por role', 'Filter by role'),
              onSelected: (role) {
                // Filtro desabilitado temporariamente
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: '', child: Text(_tx('Todos', 'All'))),
                ...provider.roles.map((r) => PopupMenuItem(
                      value: r.role,
                      child: Text(r.descricao),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioCard(UsuarioRoleResponse usuario, NiveisAcessoProvider provider) {
    final corRole = provider.getCorRole(usuario.role);
    final iconeRole = provider.getIconeRole(usuario.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: OwanyTheme.cardDecoration(context),
      child: InkWell(
        onTap: () => _mostrarOpcoesUsuario(usuario),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: corRole.withValues(alpha: 0.1),
                    child: Icon(iconeRole, color: corRole, size: 24),
                  ),
                  if (!usuario.ativo)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: OwanyTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.block, color: OwanyTheme.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${usuario.nomeLogin}',
                      style: TextStyle(
                        color: OwanyTheme.textMutedColor(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: corRole.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            usuario.roleDescricao,
                            style: TextStyle(
                              color: corRole,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!usuario.ativo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: OwanyTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Inativo',
                              style: TextStyle(
                                color: OwanyTheme.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: OwanyTheme.textMutedColor(context),
                onPressed: () => _mostrarOpcoesUsuario(usuario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoesUsuario(UsuarioRoleResponse usuario) {
    final provider = context.read<NiveisAcessoProvider>();
    final authProvider = context.read<AuthProvider>();
    final isAdmin = authProvider.usuarioAtual?.tipo == UsuarioTipo.Administrador;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: OwanyTheme.cardColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: OwanyTheme.borderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: provider.getCorRole(usuario.role).withValues(alpha: 0.1),
                    child: Icon(
                      provider.getIconeRole(usuario.role),
                      color: provider.getCorRole(usuario.role),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nome,
                          style: OwanyTheme.titleStyle(context, fontSize: 16),
                        ),
                        Text(
                          usuario.roleDescricao,
                          style: TextStyle(
                            color: provider.getCorRole(usuario.role),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Só Admin pode alterar roles
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: OwanyTheme.primaryOrange),
                title: Text(_tx('Alterar Role', 'Change Role')),
                subtitle: Text(_tx('Modificar nível de acesso', 'Modify access level')),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogAlterarRole(usuario);
                },
              ),
            ListTile(
              leading: const Icon(Icons.key, color: OwanyTheme.info),
              title: Text(_tx('Ver Permissões', 'View Permissions')),
              subtitle: Text('${usuario.totalPermissoes} ${_tx('permissões', 'permissions')}'),
              onTap: () {
                Navigator.pop(context);
                _mostrarPermissoesDoRole(usuario.role);
              },
            ),
            // Reset de senha removido: senha deve ser tratada em Configurações
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogAlterarRole(UsuarioRoleResponse usuario) {
    final provider = context.read<NiveisAcessoProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String? novoRoleSelecionado = usuario.role;
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OwanyTheme.cardColor(dialogContext),
        title: Text(_tx('Alterar Role', 'Change Role'),
            style: TextStyle(color: OwanyTheme.textPrimary(dialogContext))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_tx('Usuário', 'User')}: ${usuario.nome}',
                style: TextStyle(color: OwanyTheme.textPrimary(dialogContext))),
            Text(
              '${_tx('Role atual', 'Current role')}: ${usuario.roleDescricao}',
              style: TextStyle(color: OwanyTheme.textMutedColor(dialogContext)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: novoRoleSelecionado,
              dropdownColor: OwanyTheme.cardColor(dialogContext),
              style: TextStyle(color: OwanyTheme.textPrimary(dialogContext)),
              decoration: OwanyTheme.adaptiveInputDecoration(
                dialogContext,
                label: _tx('Novo Role', 'New Role'),
                icon: Icons.shield,
              ),
              items: provider.roles.map((role) {
                return DropdownMenuItem(
                  value: role.role,
                  child: Row(
                    children: [
                      Icon(
                        provider.getIconeRole(role.role),
                        color: provider.getCorRole(role.role),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(role.descricao),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                novoRoleSelecionado = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              style: TextStyle(color: OwanyTheme.textPrimary(dialogContext)),
              decoration: OwanyTheme.adaptiveInputDecoration(
                dialogContext,
                label: _tx('Motivo (opcional)', 'Reason (optional)'),
                hint: _tx('Descreva o motivo da alteração', 'Describe the reason for the change'),
                icon: Icons.note,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_tx('Cancelar', 'Cancel'),
                style: TextStyle(color: OwanyTheme.textMutedColor(dialogContext))),
          ),
          ElevatedButton(
            style: OwanyTheme.primaryButtonStyle(),
            onPressed: () async {
              if (novoRoleSelecionado != null && novoRoleSelecionado != usuario.role) {
                Navigator.pop(dialogContext);
                final sucesso = await provider.atualizarRoleUsuario(
                  usuarioId: usuario.id,
                  novoRole: novoRoleSelecionado!,
                  motivo: motivoController.text.isNotEmpty ? motivoController.text : null,
                );
                if (sucesso && mounted) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      _tx('Role atualizado com sucesso', 'Role updated successfully'),
                      type: SnackBarType.success,
                    ),
                  );
                } else if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    OwanyTheme.snackBar(
                      provider.errorMessage ?? _tx('Erro ao atualizar role', 'Error updating role'),
                      type: SnackBarType.error,
                    ),
                  );
                }
              }
            },
            child: Text(_tx('Confirmar', 'Confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacao(NiveisAcessoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        border: Border(
          top: BorderSide(color: OwanyTheme.borderColor(context)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.paginaAtual > 1
                ? () => provider.carregarPaginaAnterior()
                : null,
          ),
          Text(
            'Página ${provider.paginaAtual} de ${provider.totalPaginas}',
            style: TextStyle(
              color: OwanyTheme.textMutedColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.paginaAtual < provider.totalPaginas
                ? () => provider.carregarProximaPagina()
                : null,
          ),
        ],
      ),
    );
  }
}

/// Delegate para a TabBar fixa
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}

/// Sheet para mostrar permissões de um role
class _RolePermissoesSheet extends StatelessWidget {
  final String role;

  const _RolePermissoesSheet({required this.role});

  @override
  Widget build(BuildContext context) {
    return Consumer<NiveisAcessoProvider>(
      builder: (context, provider, _) {
        final corRole = provider.getCorRole(role);
        final iconeRole = provider.getIconeRole(role);
        final rolePermissoes = provider.rolePermissoesSelecionado;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OwanyTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: corRole.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconeRole, color: corRole, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rolePermissoes?.descricao ?? role,
                              style: OwanyTheme.titleStyle(context, fontSize: 18),
                            ),
                            if (rolePermissoes != null)
                              Text(
                                '${rolePermissoes.totalPermissoes} permissões • Nível ${rolePermissoes.nivelAcesso}',
                                style: TextStyle(
                                  color: OwanyTheme.textMutedColor(context),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : rolePermissoes == null
                          ? Center(child: Text(_txCtx(context, 'Erro ao carregar permissões', 'Failed to load permissions')))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: rolePermissoes.permissoesPorCategoria.length,
                              itemBuilder: (context, index) {
                                final categoria = rolePermissoes.permissoesPorCategoria.keys.elementAt(index);
                                final permissoes = rolePermissoes.permissoesPorCategoria[categoria]!;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: OwanyTheme.cardDecoration(context),
                                  child: ExpansionTile(
                                    initiallyExpanded: index == 0,
                                    leading: Icon(
                                      _getIconeCategoria(categoria),
                                      color: OwanyTheme.primaryOrange,
                                    ),
                                    title: Text(
                                      categoria,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${permissoes.length} permissões',
                                      style: TextStyle(
                                        color: OwanyTheme.textMutedColor(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                    children: permissoes.map((permissao) => ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.check_circle,
                                        color: OwanyTheme.success,
                                        size: 20,
                                      ),
                                      title: Text(
                                        Permissoes.getDescricao(permissao),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        permissao,
                                        style: TextStyle(
                                          color: OwanyTheme.textMutedColor(context),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconeCategoria(String categoria) {
    final icones = {
      'Usuários': Icons.people,
      'Apartamentos': Icons.apartment,
      'Solicitações': Icons.assignment,
      'Manutenções': Icons.build,
      'Agendamentos': Icons.calendar_today,
      'Itens': Icons.inventory,
      'Notificações': Icons.notifications,
      'Auditoria': Icons.history,
      'Dashboard': Icons.dashboard,
      'Relatórios': Icons.assessment,
      'Sistema': Icons.settings,
    };
    return icones[categoria] ?? Icons.folder;
  }
}
