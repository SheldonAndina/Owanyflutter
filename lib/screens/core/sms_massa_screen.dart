import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../models/dtos_complementares.dart';
import '../../providers/sms_massa_provider.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/standard_glass_app_bar.dart';
import '../../generated_l10n/app_localizations.dart';

/// Tela consolidada de SMS em Massa
/// Endpoints: GET /api/smsmassa/destinatarios, POST /api/smsmassa/enviar, GET /api/smsmassa/historico
class SmsMassaScreen extends StatefulWidget {
  const SmsMassaScreen({super.key});

  @override
  State<SmsMassaScreen> createState() => _SmsMassaScreenState();
}

class _SmsMassaScreenState extends State<SmsMassaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mensagemController = TextEditingController();

  bool _enviarNotificacaoApp = true;
  int _modoSelecao = 0; // 0 = por tipo, 1 = específicos
  final Set<String> _tiposSelecionados = {};
  final Set<String> _usuariosSelecionados = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SmsMassaProvider>().carregarDestinatarios();
        context.read<SmsMassaProvider>().carregarHistorico();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _enviarSms() async {
    final l10n = AppLocalizations.of(context)!;
    if (_mensagemController.text.isEmpty) {
      _mostrarSnackBar(l10n.sms_massa_type_message_error, isError: true);
      return;
    }

    if (_mensagemController.text.length > 500) {
      _mostrarSnackBar(l10n.sms_massa_message_too_long, isError: true);
      return;
    }

    final provider = context.read<SmsMassaProvider>();

    try {
      ResultadoEnvioSmsMassaDto? resultado;

      if (_modoSelecao == 0) {
        // Enviar por tipos de usuário
        if (_tiposSelecionados.isEmpty) {
          _mostrarSnackBar(l10n.sms_massa_select_user_type_error, isError: true);
          return;
        }
        resultado = await provider.enviarSmsTipoUsuario(
          mensagem: _mensagemController.text,
          tiposUsuario: _tiposSelecionados.toList(),
          enviarNotificacao: _enviarNotificacaoApp,
        );
      } else {
        // Enviar para usuários específicos
        if (_usuariosSelecionados.isEmpty) {
          _mostrarSnackBar(l10n.sms_massa_select_user_error, isError: true);
          return;
        }
        resultado = await provider.enviarSmsMassa(
          mensagem: _mensagemController.text,
          destinatarioIds: _usuariosSelecionados.toList(),
          enviarNotificacao: _enviarNotificacaoApp,
        );
      }

      if (resultado != null && mounted) {
        _mensagemController.clear();
        _tiposSelecionados.clear();
        _usuariosSelecionados.clear();
        setState(() {});
        _mostrarSnackBar(l10n.sms_massa_success(resultado.smsEnviados, resultado.totalDestinatarios), isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          _tabController.animateTo(1);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar(l10n.sms_massa_error_sending(e.toString()), isError: true);
      }
    }
  }

  void _mostrarSnackBar(String mensagem, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? OwanyTheme.error : OwanyTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatarDataRelativa(DateTime data) {
    final l10n = AppLocalizations.of(context)!;
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inSeconds < 60) return l10n.sms_massa_time_now;
    if (diferenca.inMinutes < 60) return l10n.sms_massa_time_minutes_ago(diferenca.inMinutes);
    if (diferenca.inHours < 24) return l10n.sms_massa_time_hours_ago(diferenca.inHours);
    if (diferenca.inDays == 1) return l10n.sms_massa_yesterday;
    if (diferenca.inDays < 7) return l10n.sms_massa_time_days_ago(diferenca.inDays);
    return intl.DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: StandardGlassAppBar(title: l10n.sms_massa_title, icon: Icons.send_rounded, showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
          TabBar(
            controller: _tabController,
            indicatorColor: OwanyTheme.primaryOrange,
            indicatorWeight: 3,
            labelColor: OwanyTheme.primaryOrange,
            unselectedLabelColor: OwanyTheme.textSecondary,
            tabs: [
              Tab(text: l10n.sms_massa_tab_send, icon: Icon(Icons.send_rounded, size: 20)),
              Tab(text: l10n.sms_massa_tab_history, icon: Icon(Icons.history_rounded, size: 20)),
            ],
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [_buildEnviarTab(), _buildHistoricoTab()]),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnviarTab() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SmsMassaProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwanyTheme.primaryOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: OwanyTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.info_outline_rounded, color: OwanyTheme.cardColor(context), size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sms_massa_info_text,
                        style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Modo de Seleção
              Text(
                l10n.sms_massa_selection_mode,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: OwanyTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildModoButton(l10n.sms_massa_by_type, Icons.group_outlined, 0)),
                    Container(width: 1, height: 40, color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
                    Expanded(child: _buildModoButton(l10n.sms_massa_specific, Icons.person_outline, 1)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Seleção de Destinatários
              if (_modoSelecao == 0) _buildSelecaoTipos() else _buildSelecaoUsuarios(provider),
              SizedBox(height: 20),

              // Mensagem
              Text(
                l10n.sms_massa_sms_message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _mensagemController,
                maxLength: 500,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.sms_massa_type_message,
                  filled: true,
                  fillColor: OwanyTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: OwanyTheme.primaryOrange, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Notificação no App
              Container(
                decoration: BoxDecoration(
                  color: OwanyTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _enviarNotificacaoApp,
                      onChanged: (val) => setState(() => _enviarNotificacaoApp = val),
                      title: Text(
                        l10n.sms_massa_send_app_notification,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.sms_massa_besides_sms,
                        style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                      ),
                      activeThumbColor: OwanyTheme.primaryOrange,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Botão Enviar
              ElevatedButton(
                onPressed: provider.isLoading ? null : _enviarSms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OwanyTheme.primaryOrange,
                  foregroundColor: OwanyTheme.cardColor(context),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: provider.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: OwanyTheme.cardColor(context), strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(l10n.sms_massa_send_button, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModoButton(String texto, IconData icone, int modo) {
    final isSelected = _modoSelecao == modo;
    return InkWell(
      onTap: () => setState(() => _modoSelecao = modo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 18, color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context)),
            SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoTipos() {
    final l10n = AppLocalizations.of(context)!;
    final tipos = [
      {'tipo': 'Administrador', 'label': l10n.sms_massa_administrator, 'icon': Icons.admin_panel_settings_rounded},
      {'tipo': 'Funcionario', 'label': l10n.sms_massa_employee, 'icon': Icons.work_rounded},
      {'tipo': 'Morador', 'label': l10n.sms_massa_resident, 'icon': Icons.person_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sms_massa_user_types,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 10),
        ...tipos.map((tipo) {
          final tipoStr = tipo['tipo'] as String;
          final labelStr = tipo['label'] as String;
          final icone = tipo['icon'] as IconData;
          final isSelected = _tiposSelecionados.contains(tipoStr);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tiposSelecionados.remove(tipoStr);
                  } else {
                    _tiposSelecionados.add(tipoStr);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? OwanyTheme.primaryOrange.withValues(alpha: 0.15) : OwanyTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? OwanyTheme.primaryOrange
                        : OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icone,
                      color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      labelStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected) Icon(Icons.check_circle_rounded, color: OwanyTheme.primaryOrange, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelecaoUsuarios(SmsMassaProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    if (provider.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: OwanyTheme.primaryOrange),
        ),
      );
    }

    if (provider.destinatarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: OwanyTheme.surfaceColor(context), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: OwanyTheme.textMutedColor(context)),
            SizedBox(height: 12),
            Text(
              l10n.sms_massa_no_recipients,
              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sms_massa_select_users(_usuariosSelecionados.length, provider.destinatarios.length),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: provider.destinatarios.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dest = provider.destinatarios[index];
              final isSelected = _usuariosSelecionados.contains(dest.id);

              return ListTile(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _usuariosSelecionados.remove(dest.id);
                    } else {
                      _usuariosSelecionados.add(dest.id);
                    }
                  });
                },
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? OwanyTheme.primaryOrange
                      : OwanyTheme.textMutedColor(context).withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: isSelected ? OwanyTheme.cardColor(context) : OwanyTheme.textMutedColor(context),
                    size: 20,
                  ),
                ),
                title: Text(
                  dest.nome,
                  style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                ),
                subtitle: Text(
                  '${dest.telefone} â€¢ ${dest.tipo}',
                  style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                ),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _usuariosSelecionados.add(dest.id);
                      } else {
                        _usuariosSelecionados.remove(dest.id);
                      }
                    });
                  },
                  activeColor: OwanyTheme.primaryOrange,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricoTab() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SmsMassaProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.historico.isEmpty) {
          return Center(child: CircularProgressIndicator(color: OwanyTheme.primaryOrange));
        }

        if (provider.historico.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: OwanyTheme.surfaceColor(context), shape: BoxShape.circle),
                  child: Icon(Icons.history_rounded, size: 60, color: OwanyTheme.textMutedColor(context)),
                ),
                SizedBox(height: 16),
                Text(
                  l10n.sms_massa_no_history,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OwanyTheme.textMutedColor(context),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  l10n.sms_massa_history_appear_here,
                  style: TextStyle(fontSize: 13, color: OwanyTheme.textMutedColor(context)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.carregarHistorico(),
          color: OwanyTheme.primaryOrange,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.historico.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = provider.historico[index];
              return _buildHistoricoCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoricoCard(HistoricoSmsMassaDto item) {
    final l10n = AppLocalizations.of(context)!;
    final sucessoRate = item.totalDestinatarios > 0
        ? (item.smsEnviados / item.totalDestinatarios * 100).toStringAsFixed(0)
        : '0';

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OwanyTheme.textMutedColor(context).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: OwanyTheme.primaryOrange.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OwanyTheme.primaryOrange.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: OwanyTheme.primaryOrange, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.sms_rounded, color: OwanyTheme.cardColor(context), size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tituloNotificacao.isNotEmpty ? item.tituloNotificacao : l10n.sms_massa_title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        l10n.sms_massa_by(item.enviadoPor),
                        style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatarDataRelativa(item.enviadoEm),
                  style: TextStyle(fontSize: 12, color: OwanyTheme.textMutedColor(context)),
                ),
              ],
            ),
          ),

          // Mensagem
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              item.mensagem,
              style: TextStyle(fontSize: 14, color: OwanyTheme.textPrimary(context), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: OwanyTheme.backgroundColor(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _buildStat(Icons.people_rounded, '${item.totalDestinatarios}', l10n.sms_massa_recipients),
                SizedBox(width: 16),
                _buildStat(
                  Icons.check_circle_rounded,
                  '${item.smsEnviados}',
                  l10n.sms_massa_sent,
                  color: OwanyTheme.success,
                ),
                SizedBox(width: 16),
                _buildStat(Icons.notifications_rounded, '${item.notificacoesEnviadas}', l10n.sms_massa_notifications),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OwanyTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$sucessoRate%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: OwanyTheme.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icone, String valor, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icone, size: 16, color: color ?? OwanyTheme.textMutedColor(context)),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? OwanyTheme.textPrimary(context),
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: OwanyTheme.textMutedColor(context))),
          ],
        ),
      ],
    );
  }
}
