import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/app_logger.dart';

/// Helper para downloads de arquivos com opção de escolha de local
class FileDownloadHelper {
  static const String _tag = 'FileDownload';

  /// Baixa arquivo e permite usuário escolher local para salvar
  /// 
  /// Parâmetros:
  /// - [fileBytes]: bytes do arquivo
  /// - [fileName]: nome do arquivo (ex: "solicitacoes.xlsx")
  /// - [fileExtension]: extensão sem ponto (ex: "xlsx", "pdf")
  /// 
  /// Retorna: true se sucesso, false se cancelado ou erro
  static Future<bool> saveFileWithPicker(
    BuildContext context, {
    required List<int> fileBytes,
    required String fileName,
    required String fileExtension,
  }) async {
    try {
      AppLogger.info(_tag, '📥 Iniciando download de arquivo: $fileName');
      AppLogger.info(_tag, '  Tamanho: ${fileBytes.length} bytes');
      
      // Remover extensão do fileName se houver
      String fileNameWithoutExt = fileName.replaceAll(RegExp(r'\.\w+$'), '');
      
      AppLogger.info(_tag, '  Nome: $fileNameWithoutExt');
      AppLogger.info(_tag, '  Extensão: $fileExtension');

      // Abrir diálogo para usuário escolher onde salvar
      AppLogger.info(_tag, '  ⏳ Abrindo diálogo para escolher local...');
      
      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar arquivo',
        fileName: '$fileNameWithoutExt.$fileExtension',
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );
      
      if (selectedPath == null) {
        AppLogger.info(_tag, '  ❌ Download cancelado pelo usuário');
        return false;
      }
      
      // Garantir que o arquivo tem a extensão correta
      String filePath = selectedPath;
      if (!filePath.toLowerCase().endsWith('.$fileExtension')) {
        filePath = '$selectedPath.$fileExtension';
      }
      
      AppLogger.info(_tag, '  ✅ Local escolhido: $filePath');

      // Escrever bytes no arquivo
      AppLogger.info(_tag, '  📝 Escrevendo bytes no arquivo...');
      final file = File(filePath);
      // Converter para Uint8List para garantir escrita correta de bytes binários
      final Uint8List bytesToWrite = fileBytes is Uint8List
          ? fileBytes
          : Uint8List.fromList(fileBytes);
      await file.writeAsBytes(bytesToWrite, flush: true);
      
      AppLogger.info(_tag, '  ✅ Arquivo escrito com sucesso');
      AppLogger.info(_tag, '  📁 Localização: $filePath');
      AppLogger.info(_tag, '  📊 Tamanho final: ${file.lengthSync()} bytes');

      // Mostrar sucesso
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Arquivo salvo em $filePath'),
            backgroundColor: const Color(0xFF059669), // OwanyTheme.success
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, '❌ Erro ao salvar arquivo', e, stackTrace);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626), // OwanyTheme.error
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      return false;
    }
  }
}
