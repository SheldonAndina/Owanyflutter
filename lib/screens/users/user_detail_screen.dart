import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../models/enums.dart';
import '../../theme/owany_theme.dart';
import '../../utils/app_date_time.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';

class UserDetailScreen extends StatefulWidget {
  final String usuarioId;

  const UserDetailScreen({required this.usuarioId, super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _apiService = ApiService();
  late Future<Usuario> _usuarioFuture;
  Apartamento? _apartamentoModador;
  bool _isTogglingActive = false;

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  /// Parse role string to UsuarioTipo using the extension method that handles accents
  UsuarioTipo _parseUsuarioTipo(String role) {
    try {
      return UsuarioTipoExtension.fromString(role);
    } catch (e) {
      // Fallback for unknown roles
      return UsuarioTipo.Morador;
    }
  }

  @override
  void initState() {
    super.initState();
    _usuarioFuture = _apiService
        .getUsuario(widget.usuarioId)
        .then(
          (dto) => Usuario(
            id: dto.id,
            nome: dto.nome,
            nomeLogin: dto.nomeLogin,
            telefone: dto.telefone,
            tipo: _parseUsuarioTipo(dto.role),
            ativo: dto.ativo,
            criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
          ),
        )
        .then((usuario) async {
          // Se for morador, buscar apartamento vinculado
          if (usuario.tipo == UsuarioTipo.Morador) {
            try {
              _apartamentoModador = await _buscarApartamentoModador(usuario.id);
            } catch (e) {
              // Silenciosamente ignora se não encontrar
            }
          }
          return usuario;
        });
  }

  Future<Apartamento?> _buscarApartamentoModador(String usuarioId) async {
    try {
      // Buscar moradores para encontrar o apartamento associado
      final moradores = await _apiService.request<List<dynamic>>(
        'moradores?usuarioId=$usuarioId',
        method: 'GET',
        fromJson: (json) => json as List<dynamic>,
      );

      if (moradores.isEmpty) return null;

      // Procurar o morador que tem apartamentoId E pertence a este usuarioId específico
      final morador = moradores.firstWhere(
        (m) => m['apartamentoId'] != null && m['usuarioId'] == usuarioId,
        orElse: () => null,
      );

      if (morador == null) return null;

      final apartamentoId = morador['apartamentoId'];

      if (apartamentoId == null) return null;

      // Buscar detalhes do apartamento
      final apartamento = await _apiService.request<Apartamento>(
        'apartamentos/$apartamentoId',
        method: 'GET',
        fromJson: (json) => Apartamento.fromJson(json),
      );

      return apartamento;
    } catch (e) {
      return null;
    }
  }


  Future<void> _toggleAtivo(BuildContext context, Usuario usuario) async {
    final l10n = AppLocalizations.of(context)!;
    final desejaDesativar = usuario.ativo;
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OwanyTheme.cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          desejaDesativar ? l10n.users_deactivate : l10n.common_activate,
          style: TextStyle(color: OwanyTheme.textPrimary(ctx), fontWeight: FontWeight.w700),
        ),
        content: Text(
          desejaDesativar
              ? l10n.users_deactivate_description(usuario.nome)
              : _tx('Deseja ativar este usuário?', 'Do you want to activate this user?'),
          style: TextStyle(color: OwanyTheme.textMutedColor(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tx('Cancelar', 'Cancel'),
                style: TextStyle(color: OwanyTheme.textMutedColor(ctx))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: desejaDesativar
                ? OwanyTheme.destructiveButtonStyle()
                : OwanyTheme.primaryButtonStyle(),
            child: Text(desejaDesativar ? l10n.users_deactivate_button : l10n.common_activate),
          ),
        ],
      ),
    );

    if (confirma != true || !mounted) return;

    setState(() => _isTogglingActive = true);
    try {
      if (desejaDesativar) {
        await _apiService.desativarUsuario(usuario.id);
      } else {
        await _apiService.atualizarUsuario(
          usuario.id,
          nome: usuario.nome,
          telefone: usuario.telefone,
          ativo: true,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar(
          desejaDesativar
              ? AppLocalizations.of(context)!.users_deactivated_success
              : _tx('Usuário ativado com sucesso.', 'User activated successfully.'),
          type: SnackBarType.success,
        ),
      );
      setState(() {
        _usuarioFuture = _apiService
            .getUsuario(widget.usuarioId)
            .then(
              (dto) => Usuario(
                id: dto.id,
                nome: dto.nome,
                nomeLogin: dto.nomeLogin,
                telefone: dto.telefone,
                tipo: _parseUsuarioTipo(dto.role),
                ativo: dto.ativo,
                criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
              ),
            );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar('${AppLocalizations.of(context)!.common_error}: $e',
            type: SnackBarType.error),
      );
    } finally {
      if (mounted) setState(() => _isTogglingActive = false);
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: OwanyTheme.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OwanyTheme.borderColor(context)),
      boxShadow: [
        BoxShadow(color: OwanyTheme.primaryOrange.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
      ],
    );
  }

  Widget _infoRow({required String label, required String value, IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? OwanyTheme.primaryOrange).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? OwanyTheme.primaryOrange),
            ),
          if (icon != null) SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.users_detail_title,
        icon: Icons.person_rounded,
        showBackButton: true,
      ),
      body: FutureBuilder<Usuario>(
        future: _usuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange)),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OwanyTheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.error_rounded, color: OwanyTheme.error),
                      ),
                      SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.users_error_loading,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13, height: 1.4),
                      ),
                      SizedBox(height: 14),
                      PrimaryButton.primary(
                        text: AppLocalizations.of(context)!.common_retry,
                        onPressed: () => setState(() {
                          _usuarioFuture = _apiService
                              .getUsuario(widget.usuarioId)
                              .then(
                                (dto) => Usuario(
                                  id: dto.id,
                                  nome: dto.nome,
                                  nomeLogin: dto.nomeLogin,
                                  telefone: dto.telefone,
                                  tipo: _parseUsuarioTipo(dto.role),
                                  ativo: dto.ativo,
                                  criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
                                ),
                              );
                        }),
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final usuario = snapshot.data;
          if (usuario == null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.all(24),
                decoration: _cardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, color: OwanyTheme.textMutedColor(context), size: 32),
                    SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.users_not_found,
                      style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getTipoCor(usuario.tipo).withValues(alpha: 0.12), OwanyTheme.cardColor(context)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: OwanyTheme.borderColor(context)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _getTipoCor(usuario.tipo),
                        child: Text(
                          usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: OwanyTheme.cardColor(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nome,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: OwanyTheme.textPrimary(context),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              usuario.nomeLogin,
                              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getTipoCor(usuario.tipo).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getTipoCor(usuario.tipo).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _getTipoLabel(usuario.tipo),
                                style: TextStyle(
                                  color: _getTipoCor(usuario.tipo),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  AppLocalizations.of(context)!.users_information,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                ),
                SizedBox(height: 12),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_name,
                  value: usuario.nome,
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 10),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_login,
                  value: usuario.nomeLogin,
                  icon: Icons.badge_outlined,
                ),
                SizedBox(height: 10),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_phone,
                  value: usuario.telefone,
                  icon: Icons.phone_rounded,
                ),
                SizedBox(height: 10),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_type,
                  value: _getTipoLabel(usuario.tipo),
                  icon: Icons.verified_user_rounded,
                  iconColor: _getTipoCor(usuario.tipo),
                ),
                SizedBox(height: 10),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_status,
                  value: usuario.ativo
                      ? AppLocalizations.of(context)!.common_active
                      : AppLocalizations.of(context)!.common_inactive,
                  icon: usuario.ativo ? Icons.check_circle_rounded : Icons.block_rounded,
                  iconColor: usuario.ativo ? OwanyTheme.success : OwanyTheme.error,
                ),
                SizedBox(height: 10),
                _infoRow(
                  label: AppLocalizations.of(context)!.users_created_at,
                  value: '${usuario.criadoEm.day}/${usuario.criadoEm.month}/${usuario.criadoEm.year}',
                  icon: Icons.calendar_today_rounded,
                  iconColor: OwanyTheme.primaryOrange,
                ),

                if (usuario.tipo == UsuarioTipo.Morador && _apartamentoModador != null) ...[
                  SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.users_linked_apartment,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [OwanyTheme.primaryOrange.withValues(alpha: 0.08), OwanyTheme.cardColor(context)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: OwanyTheme.primaryOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.apartment_rounded, color: OwanyTheme.primaryOrange, size: 20),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apartamento ${_apartamentoModador!.numero}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: OwanyTheme.textPrimary(context),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.of(context)!.apartments_block_floor_label(
                                      _apartamentoModador!.bloco,
                                      _apartamentoModador!.andar,
                                    ),
                                    style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _apartamentoInfoItem(
                                icon: Icons.people_rounded,
                                label: AppLocalizations.of(context)!.users_residents,
                                value: _apartamentoModador!.quantidadeMoradores.toString(),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _apartamentoInfoItem(
                                icon: Icons.check_circle_rounded,
                                label: AppLocalizations.of(context)!.users_state,
                                value: _getEstadoLabel(_apartamentoModador!.estado),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Ações administrativas (admin/síndico)
                if (context.read<AuthProvider>().isAdmin || context.read<AuthProvider>().isSindico) ...[  
                  SizedBox(height: 24),
                  Text(
                    'Ações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.textPrimary(context),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTogglingActive
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    '/usuarios-editar',
                                    arguments: usuario.id,
                                  ).then((value) {
                                    if (value == true && mounted) {
                                      setState(() {
                                        _usuarioFuture = _apiService
                                            .getUsuario(widget.usuarioId)
                                            .then(
                                              (dto) => Usuario(
                                                id: dto.id,
                                                nome: dto.nome,
                                                nomeLogin: dto.nomeLogin,
                                                telefone: dto.telefone,
                                                tipo: _parseUsuarioTipo(dto.role),
                                                ativo: dto.ativo,
                                                criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
                                              ),
                                            );
                                      });
                                    }
                                  }),
                          icon: Icon(Icons.edit_rounded, size: 18),
                          label: Text(_tx('Editar', 'Edit')),
                          style: OwanyTheme.primaryButtonStyle(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTogglingActive
                              ? null
                              : () => _toggleAtivo(context, usuario),
                          icon: _isTogglingActive
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: OwanyTheme.white,
                                  ),
                                )
                              : Icon(
                                  usuario.ativo
                                      ? Icons.block_rounded
                                      : Icons.check_circle_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            usuario.ativo
                                ? AppLocalizations.of(context)!.users_deactivate_button
                                : AppLocalizations.of(context)!.common_activate,
                          ),
                          style: usuario.ativo
                              ? OwanyTheme.destructiveButtonStyle()
                              : OwanyTheme.primaryButtonStyle(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _apartamentoInfoItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: OwanyTheme.primaryOrange),
              SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, color: OwanyTheme.textMutedColor(context))),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
          ),
        ],
      ),
    );
  }

  String _getEstadoLabel(EstadoApartamento estado) {
    return estado.toPortuguese();
  }

  Color _getTipoCor(UsuarioTipo tipo) {
    switch (tipo) {
      case UsuarioTipo.Administrador:
        return OwanyTheme.error;
      case UsuarioTipo.Funcionario:
        return OwanyTheme.primaryOrange;
      case UsuarioTipo.Sindico:
        return OwanyTheme.textPrimary(context);
      case UsuarioTipo.Portaria:
        return OwanyTheme.primaryBlue;
      case UsuarioTipo.Morador:
        return OwanyTheme.success;
      case UsuarioTipo.Visitante:
        return OwanyTheme.textMutedColor(context);
    }
  }

  String _getTipoLabel(UsuarioTipo tipo) {
    final l10n = AppLocalizations.of(context)!;
    switch (tipo) {
      case UsuarioTipo.Administrador:
        return l10n.common_administrator;
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
