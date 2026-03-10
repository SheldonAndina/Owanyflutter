import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// APARTMENT CARD - Widget Premium com Gradiente
/// Design System: OwanyTheme
/// ============================================================

class ApartmentCard extends StatelessWidget {
  final String number;
  final String block;
  final int floor;
  final ApartmentStatus status;
  final int residentCount;
  final String? ownerName;
  final String? ownerPhone;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const ApartmentCard({
    super.key,
    required this.number,
    required this.block,
    required this.floor,
    required this.status,
    this.residentCount = 0,
    this.ownerName,
    this.ownerPhone,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompactCard(context) : _buildFullCard(context);
  }

  /// Card Compacto (para listas longas)
  Widget _buildCompactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: OwanyTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ícone do Apartamento
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getStatusGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: OwanyTheme.adaptiveTextOverlay(context),
                  size: 24,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number - Bloco $block',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(),
                        SizedBox(width: 8),
                        Text(
                          'Andar $floor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Seta
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card Completo (com todas as informações)
  Widget _buildFullCard(BuildContext context) {
    final isDark = OwanyTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  OwanyTheme.darkSurfaceElevated,
                  OwanyTheme.darkSurface,
                ]
              : [
                  OwanyTheme.cardColor(context),
                  const Color(0xFFFBFAF8),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? OwanyTheme.textPrimary(context).withValues(alpha: 0.2) : OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com número e ações
                Row(
                  children: [
                    // Ícone com Gradiente
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient(),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        color: OwanyTheme.adaptiveTextOverlay(context),
                        size: 28,
                      ),
                    ),
                    
                    SizedBox(width: 12),
                    
                    // Número e Bloco
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            number,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bloco $block • Andar $floor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge de Status
                    _buildStatusBadge(),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OwanyTheme.borderColor(context).withValues(alpha: 0),
                        OwanyTheme.borderColor(context),
                        OwanyTheme.borderColor(context).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Informações do Proprietário
                if (ownerName != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF7A3D),
                              Color(0xFFFF9F5A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: OwanyTheme.adaptiveTextOverlay(context),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ownerName!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              color: OwanyTheme.textPrimary(context),
                            ),
                          ),
                          if (ownerPhone != null) ...[
                            SizedBox(height: 2),
                            Text(
                              ownerPhone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: OwanyTheme.textMutedColor(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
                
                // Estatísticas
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.people_rounded,
                      label: 'Moradores',
                      value: '$residentCount',
                    ),
                    SizedBox(width: 16),
                    _buildStatItem(
                      icon: Icons.meeting_room_rounded,
                      label: 'Andar',
                      value: '$floor',
                    ),
                  ],
                ),
                
                // Ações (se habilitadas)
                if (showActions && (onEdit != null || onDelete != null)) ...[
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OwanyTheme.borderColor(context).withValues(alpha: 0),
                          OwanyTheme.borderColor(context),
                          OwanyTheme.borderColor(context).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Editar',
                          color: OwanyTheme.primaryOrange,
                          onTap: onEdit!,
                        ),
                      if (onEdit != null && onDelete != null)
                        SizedBox(width: 8),
                      if (onDelete != null)
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          label: 'Deletar',
                          color: const Color(0xFFEF4444),
                          onTap: onDelete!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge de Status
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
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
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Item de Estatística
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFFF7A3D),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Botão de Ação
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cor do Status
  Color _getStatusColor() {
    switch (status) {
      case ApartmentStatus.occupied:
        return const Color(0xFF10B981); // Verde
      case ApartmentStatus.available:
        return const Color(0xFF3B82F6); // Azul
      case ApartmentStatus.maintenance:
        return const Color(0xFFF59E0B); // Amarelo
      case ApartmentStatus.reserved:
        return const Color(0xFF8B5CF6); // Roxo
    }
  }

  /// Gradiente do Status
  LinearGradient _getStatusGradient() {
    switch (status) {
      case ApartmentStatus.occupied:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case ApartmentStatus.available:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
      case ApartmentStatus.maintenance:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      case ApartmentStatus.reserved:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
    }
  }

  /// Texto do Status
  String _getStatusText() {
    switch (status) {
      case ApartmentStatus.occupied:
        return 'OCUPADO';
      case ApartmentStatus.available:
        return 'DISPONÍVEL';
      case ApartmentStatus.maintenance:
        return 'MANUTENÇÃO';
      case ApartmentStatus.reserved:
        return 'RESERVADO';
    }
  }
}

/// ============================================================
/// ENUM - Status do Apartamento
/// ============================================================
enum ApartmentStatus {
  occupied,     // Ocupado
  available,    // Disponível
  maintenance,  // Manutenção
  reserved,     // Reservado
}

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================
class ApartmentCardExample extends StatelessWidget {
  const ApartmentCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF8),
      appBar: AppBar(
        title: Text('Apartment Cards'),
        backgroundColor: OwanyTheme.cardColor(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Card Completo - Ocupado
          ApartmentCard(
            number: '1201',
            block: 'A',
            floor: 12,
            status: ApartmentStatus.occupied,
            residentCount: 3,
            ownerName: 'João Silva',
            ownerPhone: '(11) 98765-4321',
            showActions: true,
            onTap: () => debugPrintLog('Tap no apartamento'),
            onEdit: () => debugPrintLog('Editar'),
            onDelete: () => debugPrintLog('Deletar'),
          ),

          // Card Completo - Disponível
          ApartmentCard(
            number: '1202',
            block: 'A',
            floor: 12,
            status: ApartmentStatus.available,
            residentCount: 0,
            showActions: true,
            onTap: () => debugPrintLog('Tap no apartamento'),
            onEdit: () => debugPrintLog('Editar'),
            onDelete: () => debugPrintLog('Deletar'),
          ),

          // Card Completo - Manutenção
          ApartmentCard(
            number: '1005',
            block: 'B',
            floor: 10,
            status: ApartmentStatus.maintenance,
            residentCount: 2,
            ownerName: 'Maria Santos',
            ownerPhone: '(11) 99876-5432',
            onTap: () => debugPrintLog('Tap no apartamento'),
          ),

          // Card Compacto - Reservado
          ApartmentCard(
            number: '805',
            block: 'C',
            floor: 8,
            status: ApartmentStatus.reserved,
            residentCount: 1,
            isCompact: true,
            onTap: () => debugPrintLog('Tap no apartamento'),
          ),

          // Card Compacto - Ocupado
          ApartmentCard(
            number: '601',
            block: 'D',
            floor: 6,
            status: ApartmentStatus.occupied,
            residentCount: 4,
            isCompact: true,
            onTap: () => printLog('Tap no apartamento'),
          ),
        ],
      ),
    );
  }
}










