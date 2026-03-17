import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/owany_theme.dart';
import '../../providers/agendamentos_provider.dart';
import '../../generated_l10n/app_localizations.dart';

/// =====================================================================
/// â­ AVALIAR AGENDAMENTO SCREEN â€” ULTRA PREMIUM PRO VERSION 1.0
/// =====================================================================
/// Formulário de avaliação pós-agendamento com stars, aspectos
/// e recomendação de profissional
/// =====================================================================

class AvaliarAgendamentoScreen extends StatefulWidget {
  final String agendamentoId;

  const AvaliarAgendamentoScreen({required this.agendamentoId, super.key});

  @override
  State<AvaliarAgendamentoScreen> createState() => _AvaliarAgendamentoScreenState();
}

class _AvaliarAgendamentoScreenState extends State<AvaliarAgendamentoScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _starController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  final _scrollOffset = ValueNotifier<double>(0.0);

  int _rating = 0;
  bool _recomenda = false;
  final _comentarioController = TextEditingController();

  List<(String, IconData)> _getAspectos(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (l10n.avaliar_aspect_punctuality, Icons.schedule_rounded),
      (l10n.avaliar_aspect_quality, Icons.done_all_rounded),
      (l10n.avaliar_aspect_politeness, Icons.sentiment_satisfied_rounded),
      (l10n.avaliar_aspect_cleanliness, Icons.cleaning_services_rounded),
    ];
  }

  Map<String, bool> aspectosChecked = {
    'punctuality': false,
    'quality': false,
    'politeness': false,
    'cleanliness': false,
  };

  String _getAspectoKey(int index) {
    const keys = ['punctuality', 'quality', 'politeness', 'cleanliness'];
    return keys[index];
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
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

    _starController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

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
    _starController.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (_, offset, __) => Scaffold(
        backgroundColor: OwanyTheme.backgroundColor(context),
        extendBodyBehindAppBar: true,
        appBar: _buildGlassAppBar(offset),
        body: Stack(
          children: [
            _buildAnimatedBackground(offset),
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
                                // Agendamento Info
                                _buildAgendamentoInfo(),
                                SizedBox(height: 28),

                                // Rating Stars
                                _buildRatingStars(),
                                SizedBox(height: 28),

                                // Rating Label
                                _buildRatingLabel(),
                                SizedBox(height: 28),

                                // Aspectos
                                _buildAspectos(),
                                SizedBox(height: 28),

                                // Recomendação
                                _buildRecomendacao(),
                                SizedBox(height: 28),

                                // Comentário
                                _buildComentario(),
                                SizedBox(height: 28),

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
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar(double offset) {
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
          filter: ImageFilter.blur(
            sigmaX: offset > 50 ? 15.0 : 0.0,
            sigmaY: offset > 50 ? 15.0 : 0.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: offset > 50
                    ? [OwanyTheme.warning.withValues(alpha: 0.95), OwanyTheme.primaryOrange.withValues(alpha: 0.9)]
                    : [OwanyTheme.warning.withValues(alpha: 0.75), OwanyTheme.primaryOrange.withValues(alpha: 0.6)],
              ),
              border: Border(bottom: BorderSide(color: OwanyTheme.adaptiveOverlay(context, opacity: 0.15), width: 1)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.avaliar_rate_service,
                  style: const TextStyle(
                    color: OwanyTheme.white,
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

  Widget _buildAnimatedBackground(double offset) {
    return Positioned(
      top: -offset * 0.5,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [OwanyTheme.warning, OwanyTheme.warning.withValues(alpha: 0.8), OwanyTheme.primaryOrange, OwanyTheme.backgroundColor(context)],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentoInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [OwanyTheme.cardColor(context), OwanyTheme.cardColor(context).withValues(alpha: 0.95)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OwanyTheme.borderColor(context).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.avaliar_service_completed,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
              ),
              SizedBox(height: 16),
              _buildInfoRow(
                AppLocalizations.of(context)!.avaliar_service,
                AppLocalizations.of(context)!.avaliar_general_cleaning,
              ),
              SizedBox(height: 12),
              _buildInfoRow(AppLocalizations.of(context)!.schedule_date, '15 de Janeiro de 2026'),
              SizedBox(height: 12),
              _buildInfoRow(
                AppLocalizations.of(context)!.agendamentos_responsible,
                AppLocalizations.of(context)!.avaliar_placeholder_name,
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

  Widget _buildRatingStars() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final isFilled = i < _rating;
          return GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: isFilled ? 0 : 1, end: isFilled ? 1 : 0),
                duration: const Duration(milliseconds: 300),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: 1.0 + (scale * 0.2),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFilled ? OwanyTheme.warning : OwanyTheme.borderLight,
                      size: 56,
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingLabel() {
    final l10n = AppLocalizations.of(context)!;
    String label = l10n.avaliar_select_rating;
    Color cor = OwanyTheme.textMutedColor(context);

    if (_rating == 1) {
      label = l10n.avaliar_very_dissatisfied;
      cor = OwanyTheme.error;
    } else if (_rating == 2) {
      label = l10n.avaliar_dissatisfied;
      cor = OwanyTheme.primaryOrange;
    } else if (_rating == 3) {
      label = l10n.avaliar_neutral;
      cor = OwanyTheme.warning;
    } else if (_rating == 4) {
      label = l10n.avaliar_satisfied;
      cor = OwanyTheme.success;
    } else if (_rating == 5) {
      label = l10n.avaliar_very_satisfied;
      cor = OwanyTheme.success;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cor.withValues(alpha: 0.15), cor.withValues(alpha: 0.08)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cor),
        ),
      ),
    );
  }

  Widget _buildAspectos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.avaliar_what_worked_well,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _getAspectos(context).asMap().entries.map((entry) {
            final index = entry.key;
            final aspecto = entry.value;
            final (nome, icon) = aspecto;
            final key = _getAspectoKey(index);
            final isChecked = aspectosChecked[key] ?? false;

            return GestureDetector(
              onTap: () => setState(() => aspectosChecked[key] = !isChecked),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isChecked
                            ? [OwanyTheme.success.withValues(alpha: 0.15), OwanyTheme.success.withValues(alpha: 0.08)]
                            : [
                                OwanyTheme.adaptiveOverlay(context, opacity: 0.9),
                                OwanyTheme.adaptiveOverlay(context, opacity: 0.85),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked
                            ? OwanyTheme.success.withValues(alpha: 0.3)
                            : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                        width: isChecked ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isChecked ? OwanyTheme.success : OwanyTheme.textMutedColor(context),
                          size: 28,
                        ),
                        SizedBox(height: 8),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isChecked ? OwanyTheme.success : OwanyTheme.textPrimary(context),
                          ),
                        ),
                        if (isChecked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_rounded, color: OwanyTheme.success, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecomendacao() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _recomenda
                  ? [OwanyTheme.success.withValues(alpha: 0.1), OwanyTheme.success.withValues(alpha: 0.05)]
                  : [
                      OwanyTheme.adaptiveOverlay(context, opacity: 0.9),
                      OwanyTheme.adaptiveOverlay(context, opacity: 0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _recomenda
                  ? OwanyTheme.success.withValues(alpha: 0.3)
                  : OwanyTheme.borderColor(context).withValues(alpha: 0.3),
              width: _recomenda ? 2 : 1,
            ),
          ),
          child: GestureDetector(
            onTap: () => setState(() => _recomenda = !_recomenda),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _recomenda
                          ? [OwanyTheme.success, OwanyTheme.success.withValues(alpha: 0.8)]
                          : [OwanyTheme.borderLight, OwanyTheme.borderLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _recomenda ? Icons.check_rounded : Icons.add_rounded,
                      color: OwanyTheme.adaptiveTextOverlay(context),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.avaliar_recommend_professional,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: OwanyTheme.textPrimary(context),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _recomenda
                            ? AppLocalizations.of(context)!.avaliar_yes_definitely
                            : AppLocalizations.of(context)!.common_not_informed,
                        style: TextStyle(
                          fontSize: 12,
                          color: _recomenda ? OwanyTheme.success : OwanyTheme.textMutedColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComentario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.avaliar_leave_comment,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OwanyTheme.textPrimary(context)),
        ),
        SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.avaliar_share_experience,
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
                  borderSide: BorderSide(color: OwanyTheme.warning, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [OwanyTheme.borderColor(context), OwanyTheme.borderColor(context).withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.avaliar_skip,
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
                  if (_rating <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.avaliar_select_classification),
                        backgroundColor: OwanyTheme.warning,
                      ),
                    );
                    return;
                  }

                  final ok = await context.read<AgendamentosProvider>().avaliarAgendamento(
                    widget.agendamentoId,
                    _rating,
                    _comentarioController.text.trim(),
                  );

                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.avaliar_thank_you),
                        backgroundColor: OwanyTheme.success,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.avaliar_send,
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
