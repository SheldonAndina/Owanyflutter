import 'package:flutter/material.dart';
import '../../generated_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/moradores_provider.dart';
import '../../services/api_service.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

/// Screen to view and edit resident details
class MoradorDetailScreen extends StatefulWidget {
  final String moradorId;

  const MoradorDetailScreen({
    required this.moradorId,
    super.key,
  });

  @override
  State<MoradorDetailScreen> createState() => _MoradorDetailScreenState();
}

class _MoradorDetailScreenState extends State<MoradorDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Morador> _moradorFuture;
  bool _isEditing = false;
  late TextEditingController _nomeController;
  bool _didLoadName = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _loadMorador();
  }

  void _loadMorador() {
    _moradorFuture = _apiService.getMorador(widget.moradorId);
    _didLoadName = false;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _updateMorador(Morador morador) async {
    if (_nomeController.text.isEmpty) {
      _showError(AppLocalizations.of(context)!.morador_name_required);
      return;
    }

    try {
      setState(() => _isEditing = true);

      await context.read<MoradoresProvider>().atualizarMorador(
        widget.moradorId,
        {'nome': _nomeController.text},
      );

      _isEditing = false;
      _loadMorador();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(AppLocalizations.of(context)!.morador_updated_success),
        );
      }
    } catch (e) {
      _showError(AppLocalizations.of(context)!.error_update_with_details(e.toString()));
      setState(() => _isEditing = false);
    }
  }

  Future<void> _deleteMorador() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        title: Text(l10n.morador_delete_confirm),
        content: Text(
          l10n.morador_delete_description,
        ),
        actions: [
          PrimaryButton.secondary(
            text: l10n.common_cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          PrimaryButton.error(
            text: l10n.action_delete,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<MoradoresProvider>().deletarMorador(widget.moradorId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            OwanyTheme.snackBar(AppLocalizations.of(context)!.morador_deleted_success),
          );
        }
      } catch (e) {
        _showError(AppLocalizations.of(context)!.error_delete_with_details(e.toString()));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      OwanyTheme.snackBar(message, type: SnackBarType.error),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: OwanyTheme.cardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: OwanyTheme.borderColor(context)),
      boxShadow: [
        BoxShadow(
          color: OwanyTheme.primaryOrange.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: OwanyTheme.textPrimary(context),
      ),
    );
  }

  Widget _infoRow({required String title, required String value, IconData? icon}) {
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
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: OwanyTheme.primaryOrange),
            ),
          if (icon != null) SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OwanyTheme.textPrimary(context),
                  ),
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
        title: AppLocalizations.of(context)!.morador_detail_title,
        icon: Icons.person_pin_circle_rounded,
        showBackButton: true,
      ),
      body: FutureBuilder<Morador>(
        future: _moradorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange),
              ),
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
                        AppLocalizations.of(context)!.morador_error_loading,
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
                        onPressed: () => setState(() => _loadMorador()),
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final morador = snapshot.data!;
          if (!_isEditing && !_didLoadName) {
            _nomeController.text = morador.nome;
            _didLoadName = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              OwanyTheme.primaryOrange,
                              OwanyTheme.primaryOrange.withValues(alpha: 0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: OwanyTheme.primaryOrange.withValues(alpha: 0.10),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.person_rounded, size: 42, color: OwanyTheme.cardColor(context)),
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        morador.nome,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ID: ${morador.id.length > 8 ? morador.id.substring(0, 8) : morador.id}...',
                        style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                        OwanyTheme.softOrange.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: OwanyTheme.primaryOrange.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.info_rounded, color: OwanyTheme.primaryOrange),
                          ),
                          SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.morador_data,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: OwanyTheme.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.morador_data_description,
                        style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(AppLocalizations.of(context)!.morador_name),
                      SizedBox(height: 8),
                      !_isEditing
                          ? Text(
                              morador.nome,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OwanyTheme.textPrimary(context),
                              ),
                            )
                          : TextField(
                              controller: _nomeController,
                              decoration: OwanyTheme.inputDecoration(
                                context: context,
                                label: AppLocalizations.of(context)!.morador_name,
                                hint: AppLocalizations.of(context)!.morador_name_hint,
                                icon: Icons.person_outline_rounded,
                                dark: Theme.of(context).brightness == Brightness.dark,
                              ),
                            ),
                    ],
                  ),
                ),

                SizedBox(height: 12),
                _infoRow(
                  title: AppLocalizations.of(context)!.morador_user_id,
                  value: morador.nomeUsuario ?? morador.usuarioId ?? 'N/A',
                  icon: Icons.badge_rounded,
                ),

                SizedBox(height: 12),
                _infoRow(
                  title: AppLocalizations.of(context)!.morador_registration_date,
                  value: '${morador.criadoEm.day}/${morador.criadoEm.month}/${morador.criadoEm.year}',
                  icon: Icons.calendar_month_rounded,
                ),

                SizedBox(height: 24),

                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isEditing ? () => _updateMorador(morador) : null,
                            style: OwanyTheme.primaryButtonStyle().copyWith(
                              minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
                            ),
                            icon: Icon(Icons.save_rounded, color: OwanyTheme.cardColor(context), size: 20),
                            label: Text(
                              AppLocalizations.of(context)!.morador_save_changes,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: OwanyTheme.cardColor(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: PrimaryButton.secondary(
                            text: AppLocalizations.of(context)!.common_cancel,
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _didLoadName = false;
                              });
                              _loadMorador();
                            },
                            icon: Icons.close_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: OwanyTheme.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OwanyTheme.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OwanyTheme.warning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: OwanyTheme.warning),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.morador_remove,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: OwanyTheme.textPrimary(context),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.morador_remove_warning,
                              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12, height: 1.4),
                            ),
                            SizedBox(height: 10),
                            PrimaryButton.error(
                              text: AppLocalizations.of(context)!.morador_delete_button,
                              onPressed: _deleteMorador,
                              icon: Icons.delete_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}




















