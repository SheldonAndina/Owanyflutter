import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../utils/patrimonio_deep_link.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  bool _alreadyScanned = false;
  final _manualController = TextEditingController();

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

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  @override
  void initState() {
    super.initState();
    if (_supportsNativeScanner) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_alreadyScanned) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    _alreadyScanned = true;
    final parsed =
        PatrimonioDeepLink.extractCodigo(code, allowStandaloneCode: true) ??
        code.trim();
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assets_scan_qr)),
      body: _supportsNativeScanner ? _buildScanner(l10n) : _buildWebFallback(l10n),
    );
  }

  Widget _buildWebFallback(AppLocalizations l10n) {
    final unavailableText = kIsWeb
        ? _tx(
            'Leitura de QR code não disponível no navegador.',
            'QR code scanning is not available in the browser.',
          )
        : _tx(
            'Leitura de QR code não disponível neste dispositivo.',
            'QR code scanning is not available on this device.',
          );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                unavailableText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _tx(
                  'Digite o código de patrimônio manualmente:',
                  'Enter the asset code manually:',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _manualController,
                decoration: InputDecoration(
                  labelText: _tx('Código de patrimônio', 'Asset code'),
                  prefixIcon: const Icon(Icons.keyboard),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context, value.trim());
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final code = _manualController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.pop(context, code);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: Text(l10n.common_confirm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.common_cancel),
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

  Widget _buildScanner(AppLocalizations l10n) {
    return Stack(
      children: [
        MobileScanner(controller: _controller!, onDetect: _handleDetection),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: Text(l10n.common_cancel),
            ),
          ),
        ),
      ],
    );
  }
}
