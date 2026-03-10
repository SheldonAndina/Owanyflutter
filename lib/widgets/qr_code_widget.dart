import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/ativo.dart';
import '../utils/patrimonio_deep_link.dart';

class QRCodeWidget extends StatelessWidget {
  final Ativo? ativo;
  final double size;
  final Uint8List? imageBytes; // raster or decoded base64
  final String? base64String; // base64 string (SVG or raster)
  final String? data; // fallback raw data to generate QR

  const QRCodeWidget({
    super.key,
    this.ativo,
    this.size = 200,
    this.imageBytes,
    this.base64String,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rawPayload = (data ?? ativo?.codigoPatrimonio ?? '').trim();
    final qrPayload = PatrimonioDeepLink.buildQrPayload(rawPayload);

    // Prefer explicit bytes
    final bytes =
        imageBytes ??
        (base64String != null && base64String!.isNotEmpty
            ? base64Decode(base64String!)
            : null);

    if (bytes != null && bytes.isNotEmpty) {
      // Try decode as UTF8 to detect SVG
      try {
        final text = utf8.decode(bytes);
        if (text.trimLeft().startsWith('<svg')) {
          try {
            return SizedBox(
              width: size,
              height: size,
              child: SvgPicture.memory(bytes, width: size, height: size),
            );
          } catch (e, st) {
            debugPrint('[QRCodeWidget] SVG render failed: $e\n$st');
            // fallback to rendering raw image or QR
            // continue to image.memory fallback
          }
        }
      } catch (_) {
        // not valid UTF8, fall through to image
      }

      try {
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } catch (e, st) {
        debugPrint('[QRCodeWidget] Image.memory failed: $e\n$st');
        // final fallback: generate QR from code
        if (qrPayload.trim().isNotEmpty) {
          return QrImageView(data: qrPayload, size: size);
        }
        return SizedBox(width: size, height: size);
      }
    }

    if (qrPayload.trim().isEmpty) {
      debugPrint('[QRCodeWidget] sem dados de QR (codigo ou bytes)');
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text('Código não gerado', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return QrImageView(data: qrPayload, size: size);
  }
}
