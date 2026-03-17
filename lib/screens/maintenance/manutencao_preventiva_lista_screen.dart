import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dtos_complementares.dart';
import '../../providers/manutencao_preventiva_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/standard_glass_app_bar.dart';

class ManutencaoPreventivaListaScreen extends StatefulWidget {
  const ManutencaoPreventivaListaScreen({super.key});

  @override
  State<ManutencaoPreventivaListaScreen> createState() => _ManutencaoPreventivaListaScreenState();
}

class _ManutencaoPreventivaListaScreenState extends State<ManutencaoPreventivaListaScreen> with TickerProviderStateMixin {
  String _filtroTipo = 'todos';
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, bool> _expandedGroups = {};

  bool _isImediata(ManutencaoPreventivaDto m) {
    final f = (m.frequencia ?? '').trim();
    return f.isEmpty || f.toLowerCase() == 'null';
  }

  List<ManutencaoPreventivaDto> _getFiltered(List<ManutencaoPreventivaDto> all) {
    var resultado = List<ManutencaoPreventivaDto>.from(all);

    if (_filtroTipo == 'eventuais') {
      resultado = resultado.where((m) => _isImediata(m)).toList();
    } else if (_filtroTipo == 'gerais') {
      resultado = resultado.where((m) => !_isImediata(m)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      resultado = resultado.where((m) {
        final q = _searchQuery.toLowerCase();
        return m.titulo.toLowerCase().contains(q) || (m.descricao ?? '').toLowerCase().contains(q);
      }).toList();
    }

    resultado.sort((a, b) => a.proximaManutencao.compareTo(b.proximaManutencao));
    return resultado;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManutencaoPreventivaProvider, LanguageProvider>(
      builder: (context, provider, lang, _) {
        final items = _getFiltered(provider.manutencoes);

        return Scaffold(
          backgroundColor: OwanyTheme.backgroundColor(context),
          appBar: StandardGlassAppBar(
            title: 'Manutenções',
            icon: Icons.handyman_rounded,
            showBackButton: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 8),
                      Row(children: [
                        ChoiceChip(label: const Text('Todas'), selected: _filtroTipo == 'todos', onSelected: (_) => setState(() => _filtroTipo = 'todos')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('Pontuais'), selected: _filtroTipo == 'eventuais', onSelected: (_) => setState(() => _filtroTipo = 'eventuais')),
                        const SizedBox(width: 8),
                        ChoiceChip(label: const Text('Recorrentes'), selected: _filtroTipo == 'gerais', onSelected: (_) => setState(() => _filtroTipo = 'gerais')),
                      ]),
                    ],
                  ),
                ),
                Expanded(child: _buildTabList(items)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/manutencao-criar'),
            backgroundColor: OwanyTheme.primaryOrange,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Nova Manutenção', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar manutenções...',
          prefixIcon: Icon(Icons.search_rounded, color: OwanyTheme.textMutedColor(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildTabList(List<ManutencaoPreventivaDto> items) {
    if (items.isEmpty) return Center(child: Text('Nenhuma manutenção encontrada', style: TextStyle(color: OwanyTheme.textMutedColor(context))));

    final semFrequencia = items.where((m) => _isImediata(m)).toList();
    // Para manutenções pontuais (sem frequência) separamos concluídas e pendentes
    final semFrequenciaConcluidas = semFrequencia.where((m) => m.totalExecucoes > 0 || m.ultimaExecucao != null).toList();
    final semFrequenciaPendentes = semFrequencia.where((m) => !(m.totalExecucoes > 0 || m.ultimaExecucao != null)).toList();
    final restantes = items.where((m) => !_isImediata(m)).toList();

    final vencidas = restantes.where((m) => m.vencida).toList();
    final emAlerta = restantes.where((m) => m.alerta && !m.vencida).toList();
    final proximas = restantes.where((m) => m.diasFaltantes >= 0 && m.diasFaltantes <= 7 && !m.vencida && !m.alerta).toList();
    final normais = restantes.where((m) => !m.vencida && !m.alerta && m.diasFaltantes > 7).toList();

    // Sempre mostramos todos os grupos (mesmo que vazios) — cabeçalhos permanecem visíveis e colapsados por padrão
    final groups = <Map<String, dynamic>>[
      {'label': 'Concluídas', 'items': semFrequenciaConcluidas, 'icon': Icons.check_circle_rounded, 'color': OwanyTheme.success},
      {'label': 'Imediatas', 'items': semFrequenciaPendentes, 'icon': Icons.flash_on_rounded, 'color': OwanyTheme.primaryOrange},
      {'label': 'Vencidas', 'items': vencidas, 'icon': Icons.warning_amber_rounded, 'color': OwanyTheme.error},
      {'label': 'Em Alerta', 'items': emAlerta, 'icon': Icons.notification_important_rounded, 'color': OwanyTheme.warning},
      {'label': 'Próximas (7 dias)', 'items': proximas, 'icon': Icons.schedule_rounded, 'color': OwanyTheme.info},
      {'label': 'Normais', 'items': normais, 'icon': Icons.check_circle_outline_rounded, 'color': OwanyTheme.success},
    ];

    // Debug: mostrar no log as contagens para diagnóstico
    try {
      debugPrint('MP groups: ' + groups.map((g) => '${g['label']}: ${(g['items'] as List).length}').join(' | '));
    } catch (e) {
      debugPrint('MP groups: erro ao calcular contagens: $e');
    }

    return RefreshIndicator(
      color: OwanyTheme.primaryOrange,
      onRefresh: () => context.read<ManutencaoPreventivaProvider>().carregarManutencoes(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: groups.fold<int>(0, (acc, g) {
          final label = g['label'] as String;
          acc += 1;
          if (_expandedGroups[label] ?? false) acc += (g['items'] as List).length;
          return acc;
        }),
        itemBuilder: (context, index) {
          int cursor = 0;
          for (final g in groups) {
            final label = g['label'] as String;
            final list = g['items'] as List<ManutencaoPreventivaDto>;
            final color = g['color'] as Color;
            final icon = g['icon'] as IconData;
            final expanded = _expandedGroups[label] ?? false;

            if (index == cursor) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: InkWell(
                  onTap: () => setState(() {
                    _expandedGroups[label] = !(expanded);
                    debugPrint('MP toggle group: $label -> ${_expandedGroups[label]}');
                  }),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildSectionHeader(label, list.length, icon, color)),
                      Transform.rotate(angle: expanded ? 0 : -3.1415 / 2, child: Icon(Icons.chevron_left_rounded, color: OwanyTheme.textMutedColor(context))),
                    ],
                  ),
                ),
              );
            }
            cursor++;

            if (expanded) {
              if (index < cursor + list.length) {
                final item = list[index - cursor];
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildManutencaoCard(item, color));
              }
              cursor += list.length;
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text('$label ($count)', style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)))),
      ],
    );
  }

  Widget _buildManutencaoCard(ManutencaoPreventivaDto m, Color statusColor) {
    final status = statusFromManutencao(m);
    Color statusBadgeColor;
    switch (status) {
      case StatusManutencaoPreventiva.Atrasada:
        statusBadgeColor = OwanyTheme.error;
        break;
      case StatusManutencaoPreventiva.Concluida:
        statusBadgeColor = OwanyTheme.success;
        break;
      case StatusManutencaoPreventiva.EmAndamento:
        statusBadgeColor = OwanyTheme.info;
        break;
      case StatusManutencaoPreventiva.Cancelada:
        statusBadgeColor = OwanyTheme.textMutedColor(context);
        break;
      case StatusManutencaoPreventiva.Agendada:
      default:
        statusBadgeColor = OwanyTheme.primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.handyman_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      m.titulo,
                      style: TextStyle(fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toPortuguese(),
                      style: TextStyle(color: statusBadgeColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  )
                ],
              ),
              if ((m.descricao ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(m.descricao ?? '', style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 13))
              ]
            ]),
          ),
          const SizedBox(width: 8),
          Column(children: [
            Text('${m.diasFaltantes}d', style: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Icon(Icons.chevron_right_rounded, color: OwanyTheme.textMutedColor(context))
          ])
        ],
      ),
    );
  }
}
