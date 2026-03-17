import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:owany_app/theme/owany_theme.dart';
import 'package:owany_app/providers/auth_provider.dart';
import 'package:owany_app/providers/agendamentos_provider.dart';

/// ============================================================
/// APP DRAWER - Widget Premium com Gradiente
/// Design System: OwanyTheme
/// ============================================================

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final usuario = authProvider.usuarioAtual;
        
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFBFAF8),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header com Gradiente Premium
                _buildHeader(context, usuario),
                
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      // PRINCIPAL - Dashboard para todos, Solicitações não para Portaria/Visitante
                      _buildMenuSection(
                        title: 'PRINCIPAL',
                        items: [
                          _DrawerItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Dashboard',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7A3D), Color(0xFFFF9F5A)],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, '/dashboard');
                            },
                          ),
                          // Solicitações - Não para Portaria nem Visitante
                          if (!authProvider.isPortaria && !authProvider.isVisitante)
                            _DrawerItem(
                              icon: Icons.build_rounded,
                              label: authProvider.isMorador ? 'Minhas Solicitações' : 'Solicitações',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/solicitacoes');
                              },
                            ),
                                    // Agendamentos - Admin, Síndico, Portaria, Morador
                                    if (!authProvider.isVisitante && !authProvider.isFuncionario)
                                      Builder(builder: (ctx) {
                                        final agendProvider = ctx.watch<AgendamentosProvider>();
                                        final agendPendentes = agendProvider.agendamentos
                                            .where((a) => a.isPendenteAceitacao)
                                            .length;
                                        return _DrawerItem(
                                          icon: Icons.calendar_month_rounded,
                                          label: authProvider.isMorador ? 'Meus Agendamentos' : 'Agendamentos',
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.pushReplacementNamed(context, '/agendamentos');
                                          },
                                          badge: agendPendentes > 0 ? (agendPendentes > 9 ? '9+' : '$agendPendentes') : null,
                                        );
                                      }),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // GERENCIAMENTO - Visibilidade baseada no role
                      _buildMenuSection(
                        title: 'GERENCIAMENTO',
                        items: [
                          // Apartamentos - Não para Visitante (Staff, Morador e Portaria)
                          if (!authProvider.isVisitante)
                            _DrawerItem(
                              icon: Icons.apartment_rounded,
                              label: authProvider.isMorador ? 'Meu Apartamento' : 'Apartamentos',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/apartamentos');
                              },
                            ),
                          // Usuários - Apenas Admin e Síndico
                          if (authProvider.isAdmin || authProvider.isSindico)
                            _DrawerItem(
                              icon: Icons.person_rounded,
                              label: 'Usuários',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/usuarios');
                              },
                            ),
                          // Comunicados - Não para Visitante
                          if (!authProvider.isVisitante)
                            _DrawerItem(
                              icon: Icons.campaign_rounded,
                              label: 'Comunicados',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comunicados em breve')),
              );
                            },
                          ),
                          // QR Codes - Admin, Síndico, Funcionário
                          if (authProvider.isStaff)
                            _DrawerItem(
                              icon: Icons.qr_code_rounded,
                              label: 'QR Codes',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/qr-batch');
                              },
                            ),
                          // Relatórios - Admin, Síndico, Funcionário  
                          if (authProvider.isStaff)
                            _DrawerItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Relatórios',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/relatorios');
                              },
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // ADMINISTRAÇÃO - Apenas Admin e Síndico
                      if (authProvider.isAdmin || authProvider.isSindico)
                        _buildMenuSection(
                          title: 'ADMINISTRAÇÃO',
                          items: [
                            _DrawerItem(
                              icon: Icons.category_rounded,
                              label: 'Tipos de Solicitação',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFB923C), Color(0xFFF59E42)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/manage_request_types');
                              },
                            ),
                            // Gestão de Ativos - Admin, Síndico
                            _DrawerItem(
                              icon: Icons.inventory_2_rounded,
                              label: 'Gestão de Ativos',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, '/gestao-ativos');
                              },
                            ),
                          ],
                        ),
                      
                      if (authProvider.isAdmin || authProvider.isSindico)
                        SizedBox(height: 8),
                      
                      _buildMenuSection(
                        title: 'CONFIGURAÇÕES',
                        items: [
                          _DrawerItem(
                            icon: Icons.settings_rounded,
                            label: 'Configurações',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, '/configuracoes');
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.help_rounded,
                            label: 'Ajuda & Suporte',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showHelpDialog(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Divider Gradiente
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE5E7EB).withValues(alpha: 0),
                        const Color(0xFFE5E7EB),
                        const Color(0xFFE5E7EB).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                
                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Sair',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    isDestructive: true,
                      onTap: () async {
                        Navigator.pop(context);
                        final navigator = Navigator.of(context);
                        await context.read<AuthProvider>().logout(context);
                        navigator.pushReplacementNamed('/login');
                    },
                  ),
                ),
                
                // Versão do App
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.textMuted.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Header Premium com Avatar e Info
  Widget _buildHeader(BuildContext context, dynamic usuario) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1714),
            Color(0xFF2D2320),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 24,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar com Gradiente
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF7A3D),
                  Color(0xFFFF9F5A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                  BoxShadow(
                  color: const Color(0xFFFF7A3D).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                (usuario?.nome?.isNotEmpty == true && usuario?.nome != null)
                    ? usuario.nome![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Nome do Usuário
          Text(
            usuario?.nome ?? 'Usuário',
            style: TextStyle(
              color: OwanyTheme.adaptiveTextOverlay(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 4),
          
          // Telefone ou Email
          if (usuario?.telefone != null && usuario?.telefone?.isNotEmpty == true)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: OwanyTheme.adaptiveOverlay(context, opacity: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    size: 12,
                      color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  usuario.telefone!,
                  style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context).withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          
          SizedBox(height: 12),
          
          // Badge do Tipo de Usuário
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.15),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF7A3D),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _getUserTypeLabel(usuario),
                  style: TextStyle(
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seção do Menu com Título
  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  /// Label do Tipo de Usuário
  String _getUserTypeLabel(dynamic usuario) {
    if (usuario == null) return 'USUÁRIO';
    
    // Adapte conforme sua estrutura de dados
    final tipo = usuario.tipo?.toString() ?? '';
    
    if (tipo.contains('admin')) return 'ADMINISTRADOR';
    if (tipo.contains('funcionario')) return 'FUNCIONÁRIO';
    if (tipo.contains('sindico')) return 'SÍNDICO';
    if (tipo.contains('portaria')) return 'PORTARIA';
    if (tipo.contains('morador')) return 'MORADOR';
    
    return 'USUÁRIO';
  }

  /// Dialog de Ajuda
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                OwanyTheme.cardColor(context),
                OwanyTheme.cardColor(context).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.help_rounded,
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Ajuda & Suporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Entre em contato conosco:\nsuporte@owany.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: OwanyTheme.primaryButtonStyle(),
                child: Text('Entendi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// DRAWER ITEM - Item do Menu com Gradiente
/// ============================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool isDestructive;
  final String? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.isDestructive = false,
    // ignore: unused_element_parameter
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.5),
                  OwanyTheme.adaptiveOverlay(context, opacity: 0.0),
                ],
              ),
            ),
            child: Row(
              children: [
                // Ícone com Gradiente
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    size: 20,
                  ),
                ),
                
                SizedBox(width: 14),
                
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive 
                          ? OwanyTheme.error 
                          : OwanyTheme.textDark,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                
                // Badge (se houver)
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                      ),
                    ),
                  ),
                
                // Seta
                if (badge == null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: OwanyTheme.textMuted.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}










