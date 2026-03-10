import 'package:flutter/material.dart';
import '../utils/log_shim.dart';
import '../theme/owany_theme.dart';

/// ============================================================
/// SOLICITACAO CARD - Card Premium de Solicitação/Manutenção
/// Design System: OwanyTheme
/// Múltiplos estilos e informações detalhadas
/// ============================================================

class SolicitacaoCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final SolicitacaoStatus status;
  final String? apartment;
  final String? responsavel;
  final String? criador;
  final DateTime? createdAt;
  final DateTime? deadline;
  final int? commentCount;
  final int? attachmentCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;
  final PrioridadeLevel? prioridade;

  const SolicitacaoCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.apartment,
    this.responsavel,
    this.criador,
    this.createdAt,
    this.deadline,
    this.commentCount,
    this.attachmentCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.isCompact = false,
    this.prioridade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OwanyTheme.cardColor(context), OwanyTheme.background],
        ),
        borderRadius: BorderRadius.circular(16),
        border: prioridade == PrioridadeLevel.urgent ? Border.all(color: OwanyTheme.error, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (prioridade == PrioridadeLevel.urgent)
            BoxShadow(color: OwanyTheme.error.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
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
            child: isCompact ? _buildCompactContent(context) : _buildFullContent(context),
          ),
        ),
      ),
    );
  }

  /// Conteúdo Compacto
  Widget _buildCompactContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Ícone de Status
            _buildStatusIcon(),
            SizedBox(width: 12),

            // Título
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: OwanyTheme.textDark,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(width: 8),

            // Badge de Status
            _buildStatusBadge(),
          ],
        ),

        SizedBox(height: 12),

        // Descrição
        Text(
          description,
          style: TextStyle(fontSize: 14, color: OwanyTheme.textMuted, height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        if (apartment != null) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.apartment_rounded, size: 14, color: OwanyTheme.textMuted),
              SizedBox(width: 6),
              Text(
                apartment!,
                style: TextStyle(fontSize: 12, color: OwanyTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Conteúdo Completo
  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone de Status com Gradiente
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _getStatusGradient(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: _getStatusColor().withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(_getStatusIconData(), color: OwanyTheme.adaptiveTextOverlay(context), size: 24),
            ),

            SizedBox(width: 14),

            // Título e Prioridade
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (prioridade != null) ...[_buildPrioridadeBadge(), SizedBox(width: 8)],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: OwanyTheme.textDark,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ID: #$id',
                    style: TextStyle(
                      fontSize: 11,
                      color: OwanyTheme.textMuted.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8),

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
                OwanyTheme.borderLight.withValues(alpha: 0),
                OwanyTheme.borderLight,
                OwanyTheme.borderLight.withValues(alpha: 0),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Descrição
        Text(
          description,
          style: TextStyle(fontSize: 14, color: OwanyTheme.textMuted, height: 1.5),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: 16),

        // Informações
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            if (apartment != null)
              _buildInfoChip(icon: Icons.apartment_rounded, label: apartment!, color: OwanyTheme.primaryOrange),
            if (criador != null)
              _buildInfoChip(icon: Icons.person_rounded, label: criador!, color: const Color(0xFF8B5CF6)),
            if (responsavel != null)
              _buildInfoChip(icon: Icons.engineering_rounded, label: responsavel!, color: const Color(0xFF3B82F6)),
          ],
        ),

        SizedBox(height: 16),

        // Footer com Metadados
        Row(
          children: [
            // Data de Criação
            if (createdAt != null) _buildMetaItem(icon: Icons.access_time_rounded, text: _formatDate(createdAt!)),

            // Prazo
            if (deadline != null) ...[
              SizedBox(width: 16),
              _buildMetaItem(
                icon: Icons.flag_rounded,
                text: _formatDate(deadline!),
                color: _isOverdue() ? OwanyTheme.error : OwanyTheme.warning,
              ),
            ],

            const Spacer(),

            // Contadores
            if (commentCount != null && commentCount! > 0)
              _buildCounter(icon: Icons.comment_rounded, count: commentCount!),

            if (attachmentCount != null && attachmentCount! > 0) ...[
              SizedBox(width: 12),
              _buildCounter(icon: Icons.attach_file_rounded, count: attachmentCount!),
            ],
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
                  OwanyTheme.borderLight.withValues(alpha: 0),
                  OwanyTheme.borderLight,
                  OwanyTheme.borderLight.withValues(alpha: 0),
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
                  color: const Color(0xFF3B82F6),
                  onTap: onEdit!,
                ),
              if (onEdit != null && onDelete != null) SizedBox(width: 8),
              if (onDelete != null)
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Deletar',
                  color: OwanyTheme.error,
                  onTap: onDelete!,
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Ícone de Status Simples
  Widget _buildStatusIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_getStatusIconData(), color: _getStatusColor(), size: 20),
    );
  }

  /// Badge de Status
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _getStatusColor(), shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getStatusColor(), letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  /// Badge de Prioridade
  Widget _buildPrioridadeBadge() {
    if (prioridade == null) return const SizedBox.shrink();

    Color color;
    IconData icon;

    switch (prioridade!) {
      case PrioridadeLevel.low:
        color = const Color(0xFF10B981);
        icon = Icons.arrow_downward_rounded;
        break;
      case PrioridadeLevel.medium:
        color = OwanyTheme.warning;
        icon = Icons.remove_rounded;
        break;
      case PrioridadeLevel.high:
        color = OwanyTheme.error;
        icon = Icons.arrow_upward_rounded;
        break;
      case PrioridadeLevel.urgent:
        color = OwanyTheme.error;
        icon = Icons.priority_high_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 12, color: color),
    );
  }

  /// Chip de Informação
  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  /// Item de Metadado
  Widget _buildMetaItem({required IconData icon, required String text, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? OwanyTheme.textMuted),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? OwanyTheme.textMuted),
        ),
      ],
    );
  }

  /// Contador
  Widget _buildCounter({required IconData icon, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: OwanyTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: OwanyTheme.textMuted),
          SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OwanyTheme.textDark),
          ),
        ],
      ),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
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
      case SolicitacaoStatus.pendente:
        return OwanyTheme.warning;
      case SolicitacaoStatus.emAndamento:
        return const Color(0xFF3B82F6);
      case SolicitacaoStatus.concluida:
        return OwanyTheme.success;
      case SolicitacaoStatus.cancelada:
        return OwanyTheme.error;
    }
  }

  /// Gradiente do Status
  LinearGradient _getStatusGradient() {
    switch (status) {
      case SolicitacaoStatus.pendente:
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
      case SolicitacaoStatus.emAndamento:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case SolicitacaoStatus.concluida:
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      case SolicitacaoStatus.cancelada:
        return const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]);
    }
  }

  /// Ícone do Status
  IconData _getStatusIconData() {
    switch (status) {
      case SolicitacaoStatus.pendente:
        return Icons.pending_rounded;
      case SolicitacaoStatus.emAndamento:
        return Icons.engineering_rounded;
      case SolicitacaoStatus.concluida:
        return Icons.check_circle_rounded;
      case SolicitacaoStatus.cancelada:
        return Icons.cancel_rounded;
    }
  }

  /// Texto do Status
  String _getStatusText() {
    switch (status) {
      case SolicitacaoStatus.pendente:
        return 'PENDENTE';
      case SolicitacaoStatus.emAndamento:
        return 'EM ANDAMENTO';
      case SolicitacaoStatus.concluida:
        return 'CONCLUÍDA';
      case SolicitacaoStatus.cancelada:
        return 'CANCELADA';
    }
  }

  /// Formatar Data
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoje ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Verificar se está atrasada
  bool _isOverdue() {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }
}

/// ============================================================
/// ENUMS
/// ============================================================

enum SolicitacaoStatus { pendente, emAndamento, concluida, cancelada }

enum PrioridadeLevel { low, medium, high, urgent }

/// ============================================================
/// EXEMPLO DE USO
/// ============================================================

class SolicitacaoCardExample extends StatelessWidget {
  const SolicitacaoCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(title: Text('Solicitações')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Card Completo - Pendente
          SolicitacaoCard(
            id: '001',
            title: 'Vazamento na cozinha',
            description: 'Há um vazamento embaixo da pia da cozinha. A água está começando a molhar o armário.',
            status: SolicitacaoStatus.pendente,
            apartment: '1201 - Bloco A',
            criador: 'João Silva',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            deadline: DateTime.now().add(const Duration(days: 2)),
            commentCount: 3,
            attachmentCount: 2,
            prioridade: PrioridadeLevel.high,
            showActions: true,
            onTap: () => debugPrintLog('Tap'),
            onEdit: () => debugPrintLog('Edit'),
            onDelete: () => debugPrintLog('Delete'),
          ),

          // Card Completo - Em Andamento
          SolicitacaoCard(
            id: '002',
            title: 'Manutenção do elevador',
            description: 'Elevador fazendo barulho estranho e parando entre andares.',
            status: SolicitacaoStatus.emAndamento,
            apartment: '805 - Bloco B',
            criador: 'Maria Santos',
            responsavel: 'Pedro Costa',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            deadline: DateTime.now().add(const Duration(days: 5)),
            commentCount: 8,
            prioridade: PrioridadeLevel.urgent,
            onTap: () => debugPrintLog('Tap'),
          ),

          // Card Completo - Concluída
          SolicitacaoCard(
            id: '003',
            title: 'Troca de lâmpada',
            description: 'Lâmpada queimada no corredor do 10º andar.',
            status: SolicitacaoStatus.concluida,
            apartment: '1005 - Bloco C',
            criador: 'Ana Costa',
            responsavel: 'Carlos Oliveira',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            deadline: DateTime.now().subtract(const Duration(days: 1)),
            commentCount: 1,
            prioridade: PrioridadeLevel.low,
            onTap: () => debugPrintLog('Tap'),
          ),

          // Card Compacto
          SolicitacaoCard(
            id: '004',
            title: 'Portão da garagem',
            description: 'Portão não está abrindo com o controle remoto.',
            status: SolicitacaoStatus.pendente,
            apartment: '601 - Bloco D',
            isCompact: true,
            onTap: () => debugPrintLog('Tap'),
          ),
        ],
      ),
    );
  }
}
