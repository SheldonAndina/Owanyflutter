import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../theme/owany_theme.dart';
import '../../services/api_service.dart';
import '../../providers/agendamentos_provider.dart';
import '../../dto/agendamentos_dtos.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../utils/app_date_time.dart';

class EditarAgendamentoScreen extends StatefulWidget {
  final AgendamentoMaintenanceDto agendamento;
  const EditarAgendamentoScreen({super.key, required this.agendamento});

  @override
  State<EditarAgendamentoScreen> createState() => _EditarAgendamentoScreenState();
}

class _EditarAgendamentoScreenState extends State<EditarAgendamentoScreen> {
  late TextEditingController _titulo;
  late TextEditingController _descricao;
  DateTime? _data;
  String? _hora;
  String? _responsavelId;
  bool _isSaving = false;

  final List<String> _horas = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: widget.agendamento.titulo);
    _descricao = TextEditingController(text: widget.agendamento.descricao);
    _data = widget.agendamento.dataAgendada;
    _hora = '${_data!.hour.toString().padLeft(2, '0')}:${_data!.minute.toString().padLeft(2, '0')}';
    _responsavelId = widget.agendamento.responsavelTecnicoId;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _data = picked);
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context)!;
    if (_titulo.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.agendamentos_title_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    if (_data == null || _hora == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.agendamentos_date_required), backgroundColor: OwanyTheme.error));
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      final horaParts = (_hora ?? '08:00').split(':');
      final hora = int.tryParse(horaParts[0]) ?? 8;
      final minuto = int.tryParse(horaParts[1]) ?? 0;
      final dataAgendada = DateTime(_data!.year, _data!.month, _data!.day, hora, minuto);

      final body = {
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'dataAgendada': toBackendUtcIsoString(dataAgendada),
        'duracaoEstimadaHoras': widget.agendamento.duracaoEstimadaHoras ?? 1,
        'responsavelTecnicoId': _responsavelId,
      };

      await ApiService().request<void>(
        'agendamentosmanutencao/${widget.agendamento.id}',
        method: 'PUT',
        body: body,
        fromJson: (_) {},
      );

      // Refresh provider item
      await context.read<AgendamentosProvider>().carregarAgendamento(widget.agendamento.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.agendamentos_created_success),
            backgroundColor: OwanyTheme.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.common_error}: $e'),
            backgroundColor: OwanyTheme.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: OwanyTheme.cardColor(context),
        elevation: 0,
        title: Text(l10n.agendamentos_new_title, style: TextStyle(color: OwanyTheme.textPrimary(context))),
        iconTheme: IconThemeData(color: OwanyTheme.textPrimary(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.agendamentos_title_field,
              style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titulo,
              decoration: InputDecoration(
                hintText: l10n.agendamentos_title_hint,
                filled: true,
                fillColor: OwanyTheme.surfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.2)),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              l10n.agendamentos_description_optional,
              style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descricao,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.agendamentos_description_hint,
                filled: true,
                fillColor: OwanyTheme.surfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.2)),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              l10n.agendamentos_schedule_section,
              style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OwanyTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        _data != null ? DateFormat('dd/MM/yyyy').format(_data!) : l10n.agendamentos_select_date,
                        style: TextStyle(color: OwanyTheme.textPrimary(context)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: OwanyTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.15)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonFormField<String>(
                      initialValue: _hora,
                      items: _horas.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                      onChanged: (v) => setState(() => _hora = v),
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OwanyTheme.textPrimary(context),
                      backgroundColor: OwanyTheme.cardColor(context),
                      side: BorderSide(color: OwanyTheme.borderColor(context).withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.common_cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwanyTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: OwanyTheme.white),
                          )
                        : Text(
                            l10n.agendamentos_create_button,
                            style: TextStyle(color: OwanyTheme.white, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
