import 'dart:ui';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../generated_l10n/app_localizations.dart';
import '../theme/owany_theme.dart';
import '../utils/patrimonio_deep_link.dart';

/// Tela de leitura de QR code com visual premium.
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen>
    with TickerProviderStateMixin {
  MobileScannerController? _controller;
  late final AnimationController _feedbackController;
  late final AnimationController _scanLineController;
  bool _flashEnabled = false;
  bool _scanned = false;
  bool _scannerReady = false;
  bool _manualMode = false;
  final List<String> _scanHistory = [];

  bool get _supportsNativeScanner {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_supportsNativeScanner) {
      _controller = MobileScannerController();
      _initializeScanner();
    } else {
      _manualMode = true;
    }
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1650),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeScanner() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.start();
      if (!mounted) return;
      setState(() {
        _scannerReady = true;
        _manualMode = false;
      });
    } on MissingPluginException {
      _activateManualMode();
    } on MobileScannerException {
      _activateManualMode();
    } catch (_) {
      _activateManualMode();
    }
  }

  void _activateManualMode() {
    if (!mounted) return;
    _controller?.dispose();
    _controller = null;
    setState(() {
      _manualMode = true;
      _scannerReady = false;
      _flashEnabled = false;
    });
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (!_scannerReady || controller == null) return;
    try {
      await controller.toggleTorch();
      if (!mounted) return;
      setState(() => _flashEnabled = !_flashEnabled);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    final controller = _controller;
    if (!_scannerReady || controller == null) return;
    try {
      await controller.switchCamera();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    _feedbackController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() => _scanned = true);
    _feedbackController.forward(from: 0);

    final parsed = PatrimonioDeepLink.extractCodigo(
          code,
          allowStandaloneCode: true,
        ) ??
        code;

    _scanHistory.insert(0, parsed);
    if (_scanHistory.length > 3) _scanHistory.removeLast();

    await Future.delayed(const Duration(milliseconds: 560));
    if (!mounted) return;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final useManualMode = _manualMode || !_supportsNativeScanner;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.assets_scan_qr),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.75),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: useManualMode
          ? _buildManualFallback(context, l10n)
          : !_scannerReady
              ? _buildScannerLoading(context, l10n)
              : Stack(
              children: [
                Positioned.fill(
                  child: MobileScanner(
                    controller: _controller!,
                    onDetect: _onDetect,
                  ),
                ),
                _buildScannerOverlay(context),
                _buildTopInfoPanel(context),
                _buildControls(context, l10n),
                _buildFeedbackLayer(),
              ],
            ),
    );
  }

  Widget _buildScannerLoading(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            const Text(
              'Inicializando câmera...',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openManualEntry,
              icon: const Icon(Icons.keyboard_rounded),
              label: const Text('Inserir código manual'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              label: Text(l10n.common_close),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoPanel(BuildContext context) {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: OwanyTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Posicione o QR code dentro da moldura',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_scanHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _scanHistory
                    .map(
                      (code) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    const double scannerAreaSize = 260;

    return Positioned.fill(
      child: CustomPaint(
        painter: QRScannerOverlayPainter(
          scannerAreaSize: scannerAreaSize,
          borderColor: OwanyTheme.primaryOrange,
          borderWidth: 3,
        ),
        child: Center(
          child: SizedBox(
            width: scannerAreaSize,
            height: scannerAreaSize,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: OwanyTheme.primaryOrange.withOpacity(0.55),
                      width: 1.2,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(0, (_scanLineController.value * 2) - 1),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              OwanyTheme.primaryOrange.withOpacity(0.6),
                              OwanyTheme.primaryOrange,
                              OwanyTheme.primaryOrange.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: OwanyTheme.primaryOrange.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          36,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.66),
              Colors.black.withOpacity(0.92),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _flashEnabled
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  label: 'Flash',
                  onTap: _scannerReady
                      ? () {
                          _toggleTorch();
                        }
                      : null,
                  active: _flashEnabled,
                ),
                SizedBox(
                  width: 62,
                  height: 62,
                  child: FloatingActionButton(
                    onPressed: _scannerReady
                        ? () {
                            _switchCamera();
                          }
                        : null,
                    elevation: 0,
                    backgroundColor: OwanyTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.flip_camera_android_rounded),
                  ),
                ),
                _buildControlButton(
                  icon: Icons.keyboard_rounded,
                  label: 'Manual',
                  onTap: _openManualEntry,
                  active: false,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l10n.common_close),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool active,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? OwanyTheme.primaryOrange.withOpacity(0.9)
                : (onTap == null ? Colors.white12.withOpacity(0.4) : Colors.white10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? OwanyTheme.primaryOrange
                  : (onTap == null ? Colors.white24.withOpacity(0.45) : Colors.white24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Colors.white54 : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackLayer() {
    return Positioned.fill(
      child: IgnorePointer(
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.2).animate(
            CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.75, end: 0).animate(
              CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
            ),
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: OwanyTheme.primaryOrange,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openManualEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inserir código manualmente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: OwanyTheme.textPrimary(ctx),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: OwanyTheme.adaptiveInputDecoration(
                  ctx,
                  label: 'Código de patrimônio',
                  icon: Icons.keyboard_rounded,
                ),
                onSubmitted: (value) {
                  final parsed = PatrimonioDeepLink.extractCodigo(
                        value.trim(),
                        allowStandaloneCode: true,
                      ) ??
                      value.trim();
                  if (parsed.isNotEmpty) Navigator.pop(ctx, parsed);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final raw = controller.text.trim();
                        if (raw.isEmpty) return;
                        final parsed = PatrimonioDeepLink.extractCodigo(
                              raw,
                              allowStandaloneCode: true,
                            ) ??
                            raw;
                        Navigator.pop(ctx, parsed);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OwanyTheme.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.common_confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null || result.isEmpty) return;
    Navigator.pop(context, result);
  }

  Widget _buildManualFallback(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    final mensagem = kIsWeb
        ? 'Leitura por câmera não está disponível no navegador.'
        : 'Leitura por câmera não está disponível neste dispositivo.';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OwanyTheme.borderColor(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 34,
                    color: OwanyTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mensagem,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Digite o código de patrimônio para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: OwanyTheme.textMutedColor(context)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: OwanyTheme.adaptiveInputDecoration(
                    context,
                    label: 'Código de patrimônio',
                    icon: Icons.keyboard_rounded,
                  ),
                  onSubmitted: (value) {
                    final parsed = PatrimonioDeepLink.extractCodigo(
                          value.trim(),
                          allowStandaloneCode: true,
                        ) ??
                        value.trim();
                    if (parsed.isNotEmpty) Navigator.pop(context, parsed);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final raw = controller.text.trim();
                          if (raw.isEmpty) return;
                          final parsed = PatrimonioDeepLink.extractCodigo(
                                raw,
                                allowStandaloneCode: true,
                              ) ??
                              raw;
                          Navigator.pop(context, parsed);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: Text(l10n.common_confirm),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OwanyTheme.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(l10n.common_cancel),
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
}

class QRScannerOverlayPainter extends CustomPainter {
  final double scannerAreaSize;
  final Color borderColor;
  final double borderWidth;

  QRScannerOverlayPainter({
    required this.scannerAreaSize,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scannerLeft = (size.width - scannerAreaSize) / 2;
    final scannerTop = (size.height - scannerAreaSize) / 2;
    final scannerRect = Rect.fromLTWH(
      scannerLeft,
      scannerTop,
      scannerAreaSize,
      scannerAreaSize,
    );
    final scannerRRect = RRect.fromRectAndRadius(scannerRect, const Radius.circular(22));

    path.addRRect(scannerRRect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withOpacity(0.68),
    );

    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double corner = 26;
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + const Offset(corner, 0), cornerPaint);
    canvas.drawLine(scannerRect.topLeft, scannerRect.topLeft + const Offset(0, corner), cornerPaint);
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight + const Offset(-corner, 0), cornerPaint);
    canvas.drawLine(scannerRect.topRight, scannerRect.topRight + const Offset(0, corner), cornerPaint);
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft + const Offset(corner, 0), cornerPaint);
    canvas.drawLine(scannerRect.bottomLeft, scannerRect.bottomLeft + const Offset(0, -corner), cornerPaint);
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight + const Offset(-corner, 0), cornerPaint);
    canvas.drawLine(scannerRect.bottomRight, scannerRect.bottomRight + const Offset(0, -corner), cornerPaint);
  }

  @override
  bool shouldRepaint(QRScannerOverlayPainter oldDelegate) {
    return oldDelegate.scannerAreaSize != scannerAreaSize ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
