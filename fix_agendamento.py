#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re

file_path = r'c:\Users\c0644449\Documents\Projetos\owany_app\lib\screens\agendamentos\criar_agendamento_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the _salvar function start and end
salvar_start = None
salvar_end = None
indent_level = None

for i, line in enumerate(lines):
    if 'Future<void> _salvar() async {' in line:
        salvar_start = i
        indent_level = len(line) - len(line.lstrip())
    elif salvar_start is not None and indent_level is not None:
        # Check if this line starts a new function at the same indentation
        if line.strip() and not line.startswith(' ' * (indent_level + 2)) and line.strip().startswith('Future') or line.strip().startswith('@'):
            salvar_end = i
            break

if salvar_start is None or salvar_end is None:
    print("Could not find _salvar function boundaries")
    exit(1)

print(f"Found _salvar from line {salvar_start+1} to {salvar_end}")

# Build the new function
new_function = '''  Future<void> _salvar() async {
    setState(() => _isSubmitting = true);
    try {
      final horaParts = _selectedHora!.split(':');
      final hora = int.tryParse(horaParts.first) ?? 0;
      final minuto = int.tryParse(horaParts.length > 1 ? horaParts[1] : '0') ?? 0;

      final dataAgendada = DateTime(
        _proximaManutencao!.year,
        _proximaManutencao!.month,
        _proximaManutencao!.day,
        hora,
        minuto,
      );

      final localId = _localSelecionado == 'GERAL' || _localSelecionado == 'CONDOMINIO'
          ? null
          : _localSelecionado;

      final sucesso = await context.read<AgendamentosProvider>().criarAgendamento(
        apartamentoId: localId ?? '',
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? 'Agendamento de manutenção'
            : _descricaoController.text.trim(),
        dataAgendada: dataAgendada,
        duracaoEstimadaHoras: 2,
        responsavelTecnicoId: _responsavelIdSelecionado ?? '',
        tipoSolicitacaoId: _tipoSelecionadoId,
        areaTecnicaId: _areaSelecionadoId,
        itemApartamentoId: _itemApartamentoSelecionadoId,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
      );

      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.agendamentos_created_success),
            backgroundColor: OwanyTheme.success,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.common_error),
            backgroundColor: OwanyTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: OwanyTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

'''

# Replace the function
lines = lines[:salvar_start] + [new_function] + lines[salvar_end:]

# Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("File updated successfully!")
