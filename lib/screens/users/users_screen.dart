import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../providers/auth_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  late Future<List<Usuario>> _usuariosFuture;
  UsuarioTipo? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _carregarUsuarios();
  }

  Future<List<Usuario>> _carregarUsuarios() async {
    try {
      return await _apiService.getUsuarios();
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
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
                    colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withValues(alpha: 0.85)],
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
                          child: Icon(Icons.people_alt_rounded, color: OwanyTheme.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.users_title,
                                style: TextStyle(color: OwanyTheme.white, fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<List<Usuario>>(
                                future: _usuariosFuture,
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return Text(
                                    '$count ${count == 1 ? 'usuário' : 'usuários'} cadastrados',
                                    style: TextStyle(color: OwanyTheme.white.withValues(alpha: 0.8), fontSize: 14),
                                  );
                                },
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
                onPressed: () {
                  setState(() => _usuariosFuture = _carregarUsuarios());
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.users_reload,
              ),
            ],
          ),
        ],
        body: FutureBuilder<List<Usuario>>(
          future: _usuariosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: SkeletonListLoader(itemCount: 5));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: OwanyTheme.error),
                      const SizedBox(height: 16),
                      Text(snapshot.error.toString()),
                      const SizedBox(height: 24),
                      PrimaryButton.primary(
                        text: l10n.users_try_again,
                        onPressed: () => setState(() => _usuariosFuture = _carregarUsuarios()),
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  ),
                ),
              );
            }

            final allUsuarios = snapshot.data ?? [];
            final usuarios = allUsuarios
                .where((u) => u.nome.toLowerCase().contains(_searchController.text.toLowerCase()))
                .where((u) => _filtroTipo == null || u.tipo == _filtroTipo)
                .toList();

            return Column(
              children: [
                // Search + Filter bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OwanyTheme.cardColor(context),
                    border: Border(bottom: BorderSide(color: OwanyTheme.borderColor(context))),
                  ),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l10n.users_search_placeholder,
                          hintStyle: TextStyle(color: OwanyTheme.textMutedColor(context)),
                          prefixIcon: Icon(Icons.search, color: OwanyTheme.textMutedColor(context)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: OwanyTheme.backgroundColor(context),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(null, 'Todos', allUsuarios.length),
                            const SizedBox(width: 8),
                            ...UsuarioTipo.values.map((tipo) {
                              final count = allUsuarios.where((u) => u.tipo == tipo).length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(tipo, _getTipoLabel(tipo), count),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: usuarios.isEmpty
                      ? EmptyUsuarios(onAddNew: () => Navigator.pushNamed(context, '/usuarios-novo'))
                      : RefreshIndicator(
                          color: OwanyTheme.primaryOrange,
                          onRefresh: () async {
                            setState(() => _usuariosFuture = _carregarUsuarios());
                            await _usuariosFuture;
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: usuarios.length,
                            itemBuilder: (context, index) => _buildUserCard(usuarios[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      // FAB só para Admin - apenas admin pode criar usuários
      floatingActionButton: context.watch<AuthProvider>().usuarioAtual?.tipo == UsuarioTipo.Administrador
          ? FloatingActionButton(
              heroTag: 'users_fab',
              onPressed: () => Navigator.pushNamed(context, '/usuarios-novo'),
              backgroundColor: OwanyTheme.primaryOrange,
              child: Icon(Icons.add_rounded, color: OwanyTheme.white),
            )
          : null,
    );
  }

  Widget _buildFilterChip(UsuarioTipo? tipo, String label, int count) {
    final isSelected = _filtroTipo == tipo;
    final color = tipo != null ? _getTipoCor(tipo) : OwanyTheme.primaryOrange;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? OwanyTheme.white.withValues(alpha: 0.3) : OwanyTheme.borderColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? OwanyTheme.white : OwanyTheme.textMutedColor(context),
              ),
            ),
          ),
        ],
      ),
      selectedColor: color,
      backgroundColor: OwanyTheme.cardColor(context),
      checkmarkColor: OwanyTheme.white,
      labelStyle: TextStyle(
        color: isSelected ? OwanyTheme.white : OwanyTheme.textPrimary(context),
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: isSelected ? color : OwanyTheme.borderColor(context)),
      onSelected: (_) => setState(() => _filtroTipo = isSelected ? null : tipo),
    );
  }

  Widget _buildUserCard(Usuario usuario) {
    final tipoCor = _getTipoCor(usuario.tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OwanyTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(color: OwanyTheme.primaryBrown.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/usuarios-detalhe', arguments: usuario.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tipoCor, tipoCor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : 'U',
                      style: TextStyle(color: OwanyTheme.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              usuario.nome,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: OwanyTheme.textPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: tipoCor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getTipoLabel(usuario.tipo),
                              style: TextStyle(color: tipoCor, fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.alternate_email, size: 14, color: OwanyTheme.textMutedColor(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              usuario.nomeLogin,
                              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: OwanyTheme.textMutedColor(context)),
                          const SizedBox(width: 4),
                          Text(
                            usuario.telefone,
                            style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: OwanyTheme.textMutedColor(context), size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTipoCor(UsuarioTipo tipo) {
    switch (tipo) {
      case UsuarioTipo.Administrador:
        return OwanyTheme.error;
      case UsuarioTipo.Funcionario:
        return OwanyTheme.primaryOrange;
      case UsuarioTipo.Sindico:
        return OwanyTheme.primaryBrown;
      case UsuarioTipo.Portaria:
        return OwanyTheme.primaryBlue;
      case UsuarioTipo.Morador:
        return OwanyTheme.success;
      case UsuarioTipo.Visitante:
        return OwanyTheme.textSecondary;
    }
  }

  String _getTipoLabel(UsuarioTipo tipo) {
    final l10n = AppLocalizations.of(context)!;
    switch (tipo) {
      case UsuarioTipo.Administrador:
        return l10n.users_type_admin;
      case UsuarioTipo.Funcionario:
        return l10n.users_type_employee;
      case UsuarioTipo.Sindico:
        return l10n.users_type_manager;
      case UsuarioTipo.Portaria:
        return l10n.users_type_doorman;
      case UsuarioTipo.Morador:
        return l10n.users_type_resident;
      case UsuarioTipo.Visitante:
        return l10n.users_type_visitor;
    }
  }
}
