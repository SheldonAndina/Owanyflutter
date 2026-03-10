import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dto/qr_code_batch_dtos.dart';
import '../../models/enums.dart';
import '../../models/item_estado.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/owany_theme.dart';
import '../../utils/file_download_helper.dart';
import '../../widgets/standard_glass_app_bar.dart';

/// Tela para geração de QR Codes em lote
/// Permite baixar QR codes de itens de apartamento em ZIP, HTML ou JSON
class QrCodeBatchScreen extends StatefulWidget {
  const QrCodeBatchScreen({super.key});

  @override
  State<QrCodeBatchScreen> createState() => _QrCodeBatchScreenState();
}

class _QrCodeBatchScreenState extends State<QrCodeBatchScreen> {
  final ApiService _apiService = ApiService();

  String _tx(String pt, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en') ? en : pt;
  }

  // Opções
  String? _estadoSelecionado;
  String _formatoSelecionado = 'svg';

  // Estado de carregamento
  bool _loadingOpcoes = true;
  bool _loadingDownload = false;
  bool _loadingRelatorio = false;

  // Dados
  QrCodeBatchRelatorioDto? _relatorio;
  String? _errorMessage;

  final List<String> _estadosDisponiveis = [
    '',
    'Disponivel',
    'Manutencao',
    'Danificado',
    'EmStock',
  ];
  final List<String> _formatosDisponiveis = ['svg', 'png', 'pdf'];

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  List<String> _fallbackEstadosApi() {
    return estadosParaFiltro.map(estadoToString).toList(growable: false);
  }

  List<String> _normalizarEstados(List<String> estadosRaw) {
    final normalized = <String>{};
    for (final raw in estadosRaw) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      normalized.add(normalizeEstadoForApi(t));
    }

    if (normalized.isEmpty) {
      normalized.addAll(_fallbackEstadosApi());
    }

    const preferencia = [
      'Disponivel',
      'EmUso',
      'Manutencao',
      'Danificado',
      'Inutilizado',
      'Extraviado',
      'EmStock',
    ];
    final ordered = <String>[];
    for (final e in preferencia) {
      if (normalized.remove(e)) ordered.add(e);
    }
    final extras = normalized.toList()..sort();
    ordered.addAll(extras);
    return ordered;
  }

  List<String> _normalizarFormatos(List<String> formatosRaw) {
    final normalized = formatosRaw
        .map((e) => e.trim().toLowerCase())
        .where((e) => e == 'svg' || e == 'png' || e == 'pdf')
        .toSet()
        .toList();
    if (normalized.isEmpty) return ['svg', 'png', 'pdf'];
    const ordem = ['svg', 'png', 'pdf'];
    normalized.sort(
      (a, b) => ordem.indexOf(a).compareTo(ordem.indexOf(b)),
    );
    return normalized;
  }

  Future<void> _carregarOpcoes() async {
    setState(() => _loadingOpcoes = true);
    var estados = <String>['', ..._fallbackEstadosApi()];
    var formatos = <String>['svg', 'png', 'pdf'];

    try {
      final opcoes = await _apiService.getQrCodesBatchOpcoes();
      estados = ['', ..._normalizarEstados(opcoes.estados)];
      formatos = _normalizarFormatos(opcoes.formatos);
    } catch (e) {
      debugPrint('[QrCodeBatch] Erro ao carregar opções: $e');
    }

    if (!mounted) return;
    setState(() {
      _estadosDisponiveis
        ..clear()
        ..addAll(estados);
      _formatosDisponiveis
        ..clear()
        ..addAll(formatos);

      if (!_formatosDisponiveis.contains(_formatoSelecionado)) {
        _formatoSelecionado = _formatosDisponiveis.first;
      }

      if (_estadoSelecionado != null &&
          !_estadosDisponiveis.contains(_estadoSelecionado)) {
        _estadoSelecionado = '';
      }

      _loadingOpcoes = false;
    });
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _loadingRelatorio = true;
      _errorMessage = null;
    });
    try {
      _relatorio = await _apiService.getQrCodesRelatorio(
        estado: _estadoSelecionado?.isNotEmpty == true
            ? _estadoSelecionado
            : null,
      );
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRelatorio = false);
    }
  }

  Future<void> _baixarZip() async {
    setState(() {
      _loadingDownload = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _apiService.downloadQrCodesBatch(
        estado: _estadoSelecionado?.isNotEmpty == true
            ? _estadoSelecionado
            : null,
        formato: _formatoSelecionado,
      );

      if (!mounted) return;

      // Formato PDF → guardar como .pdf; SVG/PNG → ZIP com múltiplos ficheiros
      final extensao = _formatoSelecionado == 'pdf' ? 'pdf' : 'zip';
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final nomeArquivo = 'QRCodes_$timestamp';

      await FileDownloadHelper.saveFileWithPicker(
        context,
        fileBytes: bytes,
        fileName: nomeArquivo,
        fileExtension: extensao,
      );
      if (!mounted) return;
      // FileDownloadHelper já exibe snackbar de sucesso com o caminho do arquivo
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${_tx('Erro', 'Error')}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDownload = false);
    }
  }

  Future<void> _abrirHtmlImpressao() async {
    setState(() {
      _loadingDownload = true;
      _errorMessage = null;
    });

    try {
      final html = await _apiService.getQrCodesHtmlImpressao(
        estado: _estadoSelecionado?.isNotEmpty == true
            ? _estadoSelecionado
            : null,
      );

      if (!mounted) return;

      // Salvar HTML em arquivo temporário e abrir
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final nomeArquivo = 'QRCodes_Impressao_$timestamp';

      // Salvar arquivo HTML com encoding UTF-8 correto
      await FileDownloadHelper.saveFileWithPicker(
        context,
        fileBytes: utf8.encode(html),
        fileName: nomeArquivo,
        fileExtension: 'html',
      );
      if (!mounted) return;
      // FileDownloadHelper já exibe snackbar de sucesso
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('${_tx('Erro', 'Error')}: $e', type: SnackBarType.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingDownload = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<AuthProvider>().usuarioAtual?.tipo;

    // Verificar permissão
    final temPermissao =
        userType == UsuarioTipo.Administrador ||
        userType == UsuarioTipo.Sindico ||
        userType == UsuarioTipo.Funcionario;

    if (!temPermissao) {
      return Scaffold(
        backgroundColor: OwanyTheme.backgroundColor(context),
        appBar: StandardGlassAppBar(
          title: _tx('QR Codes em Lote', 'Batch QR Codes'),
          icon: Icons.qr_code_2_rounded,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: OwanyTheme.textMutedColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                _tx('Acesso Negado', 'Access Denied'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: OwanyTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tx(
                  'Você não tem permissão para acessar esta funcionalidade.',
                  'You do not have permission to access this feature.',
                ),
                style: TextStyle(color: OwanyTheme.textMutedColor(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: _tx('QR Codes em Lote', 'Batch QR Codes'),
        icon: Icons.qr_code_2_rounded,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: OwanyTheme.white,
            onPressed: _carregarOpcoes,
            tooltip: _tx('Recarregar opções', 'Reload options'),
          ),
        ],
      ),
      body: _loadingOpcoes
          ? Center(child: CircularProgressIndicator(color: OwanyTheme.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho informativo
                  _buildInfoCard(),

                  const SizedBox(height: 20),

                  // Filtros
                  _buildFiltrosCard(),

                  const SizedBox(height: 20),

                  // Ações de download
                  _buildAcoesCard(),

                  const SizedBox(height: 20),

                  // Relatório (se carregado)
                  if (_relatorio != null) _buildRelatorioCard(),

                  // Mensagem de erro
                  if (_errorMessage != null) _buildErrorCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: OwanyTheme.surfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_2,
                  color: OwanyTheme.primaryOrange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _tx('Geração de QR Codes em Lote', 'Batch QR Code Generation'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Gere QR codes de todos os itens de apartamento para impressão em adesivos. '
              'Os códigos contêm o patrimônio do item e podem ser escaneados para consulta rápida.',
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('ZIP com arquivos', Icons.archive_outlined),
                _buildChip('HTML para impressão', Icons.print_outlined),
                _buildChip('Relatório JSON', Icons.data_object_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: OwanyTheme.primaryBrown),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: OwanyTheme.softOrange.withValues(alpha: 0.3),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFiltrosCard() {
    return Card(
      color: OwanyTheme.surfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: OwanyTheme.primaryBrown),
                const SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtro por estado
            Text(
              'Estado do Item',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _estadoSelecionado ?? '',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: OwanyTheme.backgroundColor(context),
              ),
              items: _estadosDisponiveis.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(
                    estado.isEmpty
                        ? 'Todos os estados'
                        : _formatarEstado(estado),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _estadoSelecionado = value),
            ),

            const SizedBox(height: 16),

            // Filtro por formato (para ZIP)
            Text(
              'Formato dos Arquivos (ZIP)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _formatosDisponiveis.map((formato) {
                return ButtonSegment(
                  value: formato,
                  label: Text(formato.toUpperCase()),
                  icon: Icon(_getFormatoIcon(formato)),
                );
              }).toList(),
              selected: {_formatoSelecionado},
              onSelectionChanged: (selection) {
                setState(() => _formatoSelecionado = selection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return OwanyTheme.primaryOrange;
                  }
                  return OwanyTheme.surfaceColor(context);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormatoIcon(String formato) {
    switch (formato) {
      case 'svg':
        return Icons.image_outlined;
      case 'png':
        return Icons.photo_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.file_present_outlined;
    }
  }

  String _formatarEstado(String estado) {
    return estadoToUiLabel(estadoFromString(estado));
  }

  Widget _buildAcoesCard() {
    return Card(
      color: OwanyTheme.surfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: OwanyTheme.primaryBrown),
                const SizedBox(width: 8),
                Text(
                  'Ações',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botões de ação
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Baixar ZIP
                _buildActionButton(
                  label: 'Baixar ZIP',
                  icon: Icons.archive,
                  description:
                      'Arquivos ${_formatoSelecionado.toUpperCase()} + índice CSV',
                  onPressed: _loadingDownload ? null : _baixarZip,
                  isLoading: _loadingDownload,
                  isPrimary: true,
                ),

                // HTML para impressão
                _buildActionButton(
                  label: 'HTML Impressão',
                  icon: Icons.print,
                  description: 'Grid 3x4 otimizado para A4',
                  onPressed: _loadingDownload ? null : _abrirHtmlImpressao,
                  isLoading: _loadingDownload,
                ),

                // Relatório JSON
                _buildActionButton(
                  label: 'Ver Relatório',
                  icon: Icons.analytics,
                  description: 'Resumo com totais por estado',
                  onPressed: _loadingRelatorio ? null : _carregarRelatorio,
                  isLoading: _loadingRelatorio,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required String description,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? OwanyTheme.primaryOrange
              : OwanyTheme.primaryBrown,
          foregroundColor: OwanyTheme.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: OwanyTheme.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: OwanyTheme.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatorioCard() {
    final rel = _relatorio!;
    return Card(
      color: OwanyTheme.surfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: OwanyTheme.primaryBrown),
                    const SizedBox(width: 8),
                    Text(
                      'Relatório',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: OwanyTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _relatorio = null),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Totais
            Row(
              children: [
                _buildStatCard(
                  'Total de Itens',
                  rel.totalItens.toString(),
                  Icons.inventory_2,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Quantidade',
                  rel.quantidade.toString(),
                  Icons.numbers,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Por estado
            Text(
              'Por Estado:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: OwanyTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rel.agrupadoPorEstado.entries.map((entry) {
                return Chip(
                  label: Text('${_formatarEstado(entry.key)}: ${entry.value}'),
                  backgroundColor: _getCorEstado(
                    entry.key,
                  ).withValues(alpha: 0.2),
                  side: BorderSide(color: _getCorEstado(entry.key)),
                );
              }).toList(),
            ),

            // Lista de itens (primeiros 10)
            if (rel.itens.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Primeiros ${rel.itens.length > 10 ? 10 : rel.itens.length} itens:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: OwanyTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              ...rel.itens.take(10).map((item) => _buildItemTile(item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OwanyTheme.softOrange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: OwanyTheme.primaryOrange, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: OwanyTheme.textPrimary(context),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCorEstado(String estado) {
    switch (estadoFromString(estado)) {
      case ItemEstado.Disponivel:
        return OwanyTheme.success;
      case ItemEstado.EmUso:
        return OwanyTheme.primaryBlue;
      case ItemEstado.Manutencao:
        return OwanyTheme.warning;
      case ItemEstado.Danificado:
        return OwanyTheme.error;
      case ItemEstado.Inutilizado:
        return OwanyTheme.gray;
      case ItemEstado.Extraviado:
        return OwanyTheme.purple;
      case ItemEstado.EmStock:
        return OwanyTheme.info;
      case ItemEstado.Desconhecido:
        return OwanyTheme.textMuted;
    }
  }

  Widget _buildItemTile(QrCodeBatchItemDto item) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _getCorEstado(item.estado).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.qr_code, color: _getCorEstado(item.estado), size: 20),
      ),
      title: Text(
        item.nome,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: OwanyTheme.textPrimary(context),
        ),
      ),
      subtitle: Text(
        '${item.codigoPatrimonio} • Apt ${item.apartamentoNumero}/${item.apartamentoBloco}',
        style: TextStyle(
          fontSize: 12,
          color: OwanyTheme.textMutedColor(context),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getCorEstado(item.estado).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatarEstado(item.estado),
          style: TextStyle(fontSize: 11, color: _getCorEstado(item.estado)),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: OwanyTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Erro desconhecido',
              style: TextStyle(color: OwanyTheme.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: OwanyTheme.error),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }
}
