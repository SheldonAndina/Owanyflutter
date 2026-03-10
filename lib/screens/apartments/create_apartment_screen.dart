import 'package:flutter/material.dart';
import '../../generated_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/apartamentos_provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/standard_glass_app_bar.dart';

class CreateApartmentScreen extends StatefulWidget {
  const CreateApartmentScreen({super.key});

  @override
  State<CreateApartmentScreen> createState() => _CreateApartmentScreenState();
}

class _CreateApartmentScreenState extends State<CreateApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _blocoController = TextEditingController();
  final _andarController = TextEditingController();
  final _quartosController = TextEditingController();
  final _observacoesController = TextEditingController();
  String _estadoSelecionado = 'Disponivel';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ApartamentosProvider>();

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: StandardGlassAppBar(
        title: AppLocalizations.of(context)!.apartments_create_title,
        icon: Icons.apartment_rounded,
        showBackButton: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = isWide ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(isWide: isWide),
                    SizedBox(height: 18),

                    Container(
                      padding: EdgeInsets.all(isWide ? 22 : 16),
                      decoration: BoxDecoration(
                        color: OwanyTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: OwanyTheme.textPrimary(context).withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.apartments_details,
                            style: OwanyTheme.headlineSmall.copyWith(color: OwanyTheme.textPrimary(context)),
                          ),
                          SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.apartments_fill_fields,
                            style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.textMutedColor(context)),
                          ),
                          SizedBox(height: 18),

                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_name,
                                child: TextFormField(
                                  controller: _nomeController,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_name_hint,
                                    icon: Icons.home_rounded,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? AppLocalizations.of(context)!.common_required_field
                                      : null,
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_number,
                                child: TextFormField(
                                  controller: _numeroController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_number_hint,
                                    icon: Icons.confirmation_number_rounded,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? AppLocalizations.of(context)!.common_required_field
                                      : null,
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_block,
                                child: TextFormField(
                                  controller: _blocoController,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_block_hint,
                                    icon: Icons.apartment_rounded,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? AppLocalizations.of(context)!.common_required_field
                                      : null,
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_floor,
                                child: TextFormField(
                                  controller: _andarController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_floor_hint,
                                    icon: Icons.stairs_rounded,
                                  ),
                                  validator: (v) {
                                    final value = int.tryParse(v ?? '');
                                    if (value == null) return AppLocalizations.of(context)!.apartments_valid_number;
                                    if (value < 0) return AppLocalizations.of(context)!.apartments_not_negative;
                                    return null;
                                  },
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_state,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _estadoSelecionado,
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_state_hint,
                                    icon: Icons.verified_user_rounded,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Disponivel',
                                      child: Text(AppLocalizations.of(context)!.apartments_list_available),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Ocupado',
                                      child: Text(AppLocalizations.of(context)!.apartments_list_occupied),
                                    ),
                                    DropdownMenuItem(
                                      value: 'EmManutencao',
                                      child: Text(AppLocalizations.of(context)!.apartments_list_maintenance),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Inativo',
                                      child: Text(AppLocalizations.of(context)!.apartments_inactive),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _estadoSelecionado = v ?? 'Disponivel'),
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_rooms,
                                child: TextFormField(
                                  controller: _quartosController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_rooms_hint,
                                    icon: Icons.meeting_room_rounded,
                                  ),
                                  validator: (v) {
                                    final value = int.tryParse(v ?? '');
                                    if (value == null || value < 0)
                                      return AppLocalizations.of(context)!.apartments_valid_number;
                                    return null;
                                  },
                                ),
                              ),
                              _FieldCard(
                                label: AppLocalizations.of(context)!.apartments_notes,
                                fullWidth: true,
                                child: TextFormField(
                                  controller: _observacoesController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: OwanyTheme.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: AppLocalizations.of(context)!.apartments_notes_hint,
                                    icon: Icons.notes_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton.secondary(
                            text: AppLocalizations.of(context)!.common_cancel,
                            onPressed: prov.isLoading ? null : () => Navigator.pop(context),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton.primary(
                            text: AppLocalizations.of(context)!.apartments_create_button,
                            onPressed: prov.isLoading ? null : _criarApartamento,
                            isLoading: prov.isLoading,
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _numeroController.dispose();
    _blocoController.dispose();
    _andarController.dispose();
    _quartosController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _criarApartamento() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<ApartamentosProvider>();
    final sucesso = await prov.criarApartamento(
      nome: _nomeController.text.trim(),
      numero: _numeroController.text.trim(),
      bloco: _blocoController.text.trim(),
      andar: int.tryParse(_andarController.text.trim()) ?? 0,
      estado: _estadoSelecionado,
      quartos: int.tryParse(_quartosController.text.trim()) ?? 0,
      banheiros: 0,
      areaMetrosQuadrados: null,
      descricao: null,
      observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(OwanyTheme.snackBar(AppLocalizations.of(context)!.apartments_created_success));
      Navigator.pop(context);
    } else if (prov.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(prov.errorMessage!, type: SnackBarType.error));
    }
  }

  InputDecoration _buildInputDecoration({required IconData icon, required String hint}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: OwanyTheme.primaryOrange),
      filled: true,
      fillColor: OwanyTheme.cardColor(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OwanyTheme.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OwanyTheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OwanyTheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.7)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isWide;

  const _HeroCard({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.primaryOrange.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OwanyTheme.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.add_business_rounded, color: OwanyTheme.cardColor(context), size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.apartments_premium_register,
                  style: OwanyTheme.labelLarge.copyWith(color: OwanyTheme.cardColor(context)),
                ),
                SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.apartments_organize_blocks,
                  style: OwanyTheme.bodySmall.copyWith(color: OwanyTheme.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  final bool fullWidth;

  const _FieldCard({required this.label, required this.child, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: fullWidth ? 0 : 260, maxWidth: fullWidth ? double.infinity : 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
