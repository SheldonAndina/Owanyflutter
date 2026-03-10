import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../providers/agendamentos_provider.dart';

/// =====================================================================
/// â†©ï¸ RESPONDER AGENDAMENTO SCREEN â€” ULTRA PREMIUM PRO VERSION 1.0
/// =====================================================================
/// Interface para morador aceitar/recusar agendamento
/// Com opções de data/hora alternativa e mensagem personalizada
/// =====================================================================

class ResponderAgendamentoScreen extends StatefulWidget {
  final String agendamentoId;

  const ResponderAgendamentoScreen({required this.agendamentoId, super.key});

  @override
  State<ResponderAgendamentoScreen> createState() => _ResponderAgendamentoScreenState();
}

class _ResponderAgendamentoScreenState extends State<ResponderAgendamentoScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _expandController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  String? _selectedAction; // Will be set in initState/build with localized value
  final _mensagemController = TextEditingController();
  final List<String> horas = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);

    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart));

    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _expandController.dispose();
    _scrollController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Initialize with localized value if null
    _selectedAction ??= l10n.responder_accept;

    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Agendamento Original
                              _buildAgendamentoCard(),
                          SizedBox(height: 28),

                          // Action Selection
                          _buildActionSelector(),
                          SizedBox(height: 28),

                          // Conditional Content
                          if (_selectedAction == l10n.responder_decline) ...[
                            _buildMensagemRecusa(),
                            SizedBox(height: 28),
                          ],

                          // Buttons
                          _buildActionButtons(),
                              SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: OwanyTheme.adaptiveOverlay(context, opacity: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.3)),
        ),
        child: Center(
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: OwanyTheme.adaptiveTextOverlay(context), size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _scrollOffset > 50 ? 15.0 : 0.0, sigmaY: _scrollOffset > 50 ? 15.0 : 0.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _scrollOffset > 50
                    ? [OwanyTheme.info.withValues(alpha: 0.95), OwanyTheme.info.withValues(alpha: 0.9)]
                    : [OwanyTheme.info.withValues(alpha: 0.75), OwanyTheme.info.withValues(alpha: 0.6)],
              ),
              border: Border(bottom: BorderSide(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15), width: 1)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.responder_title,
                  style: TextStyle(
                    color: OwanyTheme.adaptiveTextOverlay(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned(
      top: -_scrollOffset * 0.5,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OwanyTheme.primaryOrange,
              OwanyTheme.primaryOrange.withValues(alpha: 0.8),
              OwanyTheme.primaryOrange.withValues(alpha: 0.6),
              OwanyTheme.backgroundColor(context),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [OwanyTheme.cardColor(context), OwanyTheme.cardColor(context).withValues(alpha: 0.95)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.responder_proposed_schedule,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                AppLocalizations.of(context)!.responder_service,
                AppLocalizations.of(context)!.responder_service_example,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                AppLocalizations.of(context)!.schedule_date,
                AppLocalizations.of(context)!.responder_date_example,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                AppLocalizations.of(context)!.responder_time_slot,
                AppLocalizations.of(context)!.responder_time_example,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                AppLocalizations.of(context)!.agendamentos_responsible,
                AppLocalizations.of(context)!.responder_responsible_example,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OwanyTheme.textMutedColor(context)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: OwanyTheme.textPrimary(context)),
        ),
      ],
    );
  }

  Widget _buildActionSelector() {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      ('❌"', l10n.responder_accept, OwanyTheme.success),
      ('❌•', l10n.responder_decline, OwanyTheme.error),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qual é sua resposta?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 16),
              Column(
                children: actions.map((action) {
                  final (emoji, text, cor) = action;
                  final isSelected = _selectedAction == text;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAction = text),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [cor, cor.withValues(alpha: 0.8)])
                              : LinearGradient(colors: [cor.withValues(alpha: 0.1), cor.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cor.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: TextStyle(fontSize: 24)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? OwanyTheme.adaptiveTextOverlay(context) : cor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: OwanyTheme.adaptiveTextOverlay(context)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMensagemRecusa() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.responder_message_optional,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: _mensagemController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.responder_decline_reason_hint,
                filled: true,
                fillColor: OwanyTheme.surface.withValues(alpha: 0.9),
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
                  borderSide: BorderSide(color: OwanyTheme.error, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [OwanyTheme.borderLight, OwanyTheme.borderLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    l10n.common_cancel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: OwanyTheme.textMutedColor(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final aceitar = _selectedAction == l10n.responder_accept;
                  final motivoRecusa = aceitar ? null : _mensagemController.text.trim();

                  final ok = await context.read<AgendamentosProvider>().responderAgendamento(
                    widget.agendamentoId,
                    aceitar: aceitar,
                    motivoRecusa: motivoRecusa?.isEmpty == true ? null : motivoRecusa,
                  );

                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(aceitar ? l10n.responder_schedule_accepted : l10n.responder_schedule_declined),
                        backgroundColor: OwanyTheme.success,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _selectedAction ?? l10n.responder_accept,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OwanyTheme.cardColor(context)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
