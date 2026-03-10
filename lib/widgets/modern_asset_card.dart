import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';
import '../models/models.dart';
import '../models/item_estado.dart';
import '../widgets/qr_code_widget.dart';
import 'package:intl/intl.dart';

/// Modern Asset Card - Displays asset with QR code and status
class ModernAssetCard extends StatefulWidget {
  final ItemApartamento asset;
  final VoidCallback? onTap;
  final VoidCallback? onTransfer;
  final VoidCallback? onViewDetails;
  final bool showQRCode;
  final bool compact;

  const ModernAssetCard({
    required this.asset,
    this.onTap,
    this.onTransfer,
    this.onViewDetails,
    this.showQRCode = true,
    this.compact = false,
    super.key,
  });

  @override
  State<ModernAssetCard> createState() => _ModernAssetCardState();
}

class _ModernAssetCardState extends State<ModernAssetCard> {
  bool _showQR = false;

  Color _estadoColor(ItemEstado estado) {
    switch (estado) {
      case ItemEstado.Disponivel:
        return OwanyTheme.success;
      case ItemEstado.EmUso:
        return OwanyTheme.primaryOrange;
      case ItemEstado.Manutencao:
        return OwanyTheme.warning;
      case ItemEstado.Danificado:
        return OwanyTheme.error;
      case ItemEstado.Inutilizado:
        return OwanyTheme.textMuted;
      case ItemEstado.Extraviado:
        return const Color(0xFF7B1FA2); // Roxo
      case ItemEstado.EmStock:
        return OwanyTheme.info;
      case ItemEstado.Desconhecido:
        return OwanyTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = OwanyTheme.isDark(context);
    final estado = estadoFromString(widget.asset.estadoAtual);
    final estadoColor = _estadoColor(estado);

    if (widget.compact) {
      return _buildCompactCard(context, dark, estado, estadoColor);
    } else {
      return _buildFullCard(context, dark, estado, estadoColor);
    }
  }

  Widget _buildCompactCard(
    BuildContext context,
    bool dark,
    ItemEstado estado,
    Color estadoColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap ?? widget.onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? OwanyTheme.darkSurface : OwanyTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: OwanyTheme.borderColor(context),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Small QR preview
              if (widget.showQRCode)
                GestureDetector(
                  onTap: () => setState(() => _showQR = !_showQR),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dark
                          ? OwanyTheme.darkSurfaceElevated
                          : OwanyTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: OwanyTheme.borderColor(context),
                      ),
                    ),
                    child: _showQR
                        ? QRCodeWidget(
                      data: widget.asset.codigoPatrimonio ??
                          widget.asset.id,
                      size: 48,
                    )
                        : Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 24,
                        color: OwanyTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              // Asset info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.asset.nome,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.asset.codigoPatrimonio ??
                          widget.asset.id.substring(0, 8),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: OwanyTheme.textMutedColor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        estadoToUiLabel(estado),
                        style: TextStyle(
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              if (widget.onTransfer != null || widget.onViewDetails != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onViewDetails != null)
                      GestureDetector(
                        onTap: widget.onViewDetails,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: OwanyTheme.primaryOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    if (widget.onTransfer != null &&
                        estado != ItemEstado.Inutilizado)
                      Tooltip(
                        message: 'Transferir',
                        child: GestureDetector(
                          onTap: widget.onTransfer,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.compare_arrows_rounded,
                              color: OwanyTheme.primaryOrange,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullCard(
    BuildContext context,
    bool dark,
    ItemEstado estado,
    Color estadoColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap ?? widget.onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? OwanyTheme.darkSurfaceElevated : OwanyTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OwanyTheme.borderColor(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: dark ? 0.2 : 0.06,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code section
              if (widget.showQRCode)
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: dark
                        ? OwanyTheme.darkSurface
                        : OwanyTheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // QR Code
                      QRCodeWidget(
                        data: widget.asset.codigoPatrimonio ??
                            widget.asset.id,
                        size: 140,
                      ),
                      // Overlay gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.asset.nome,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Code and type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.asset.codigoPatrimonio ??
                                    widget.asset.id.substring(0, 12),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tipo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: OwanyTheme.textMutedColor(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.asset.tipo ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: OwanyTheme.primaryOrange,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: estadoColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: estadoColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            estadoToUiLabel(estado),
                            style: TextStyle(
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Date info
                    if (widget.asset.dataAquisicao != null)
                      Text(
                        'Adquirido em ${DateFormat('dd/MM/yyyy').format(widget.asset.dataAquisicao!)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: OwanyTheme.textMutedColor(context),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Action buttons
                    if (widget.onViewDetails != null ||
                        widget.onTransfer != null)
                      Row(
                        children: [
                          if (widget.onViewDetails != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onViewDetails,
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 16,
                                ),
                                label: const Text('Ver'),
                                style: OwanyTheme.secondaryButtonStyle(),
                              ),
                            ),
                          if (widget.onTransfer != null &&
                              estado != ItemEstado.Inutilizado)
                            ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onTransfer,
                                  icon: const Icon(
                                    Icons.compare_arrows_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Transferir'),
                                  style: OwanyTheme.primaryButtonStyle(),
                                ),
                              ),
                            ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
