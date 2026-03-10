import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../theme/owany_theme.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notificacoes_provider.dart';
import '../../providers/apartamentos_provider.dart';
import '../../providers/moradores_provider.dart';
import '../../providers/solicitacoes_provider.dart';
import '../../providers/agendamentos_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identificadorController = TextEditingController();
  final _senhaController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _mostrarSenha = false;
  String? _erroMensagem;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identificadorController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _realizarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _erroMensagem = null);

    final authProvider = context.read<AuthProvider>();
    final identificador = _identificadorController.text.trim();
    final senha = _senhaController.text;
    try {
      // Validações adicionais
      if (identificador.isEmpty || senha.isEmpty) {
        setState(() {
          _erroMensagem = AppLocalizations.of(context)!.login_required_field;
        });
        return;
      }

      final sucesso = await authProvider.login(identificador, senha);

      if (!mounted) return;

      if (sucesso) {
        // Clear controllers and redirect
        _identificadorController.clear();
        _senhaController.clear();

        // Conectar SignalR para notificações em tempo real
        try {
          if (mounted) {
            await context.read<NotificacoesProvider>().conectarSignalR();
            // Ativar sincronização em tempo real para cada provider
            if (mounted) {
              final apartamentoIdDoMorador = authProvider.apartamentoIdDoMorador;
              if (authProvider.isMorador || authProvider.isVisitante) {
                if (apartamentoIdDoMorador != null && apartamentoIdDoMorador.isNotEmpty) {
                  context
                      .read<ApartamentosProvider>()
                      .inicializarRealtimeSync(apartamentoIdRestrito: apartamentoIdDoMorador);
                } else {
                  context.read<ApartamentosProvider>().pararRealtimeSync();
                }
              } else {
                context.read<ApartamentosProvider>().inicializarRealtimeSync();
              }
              context.read<MoradoresProvider>().inicializarRealtimeSync();
              context.read<SolicitacoesProvider>().inicializarRealtimeSync();
              context
                  .read<AgendamentosProvider>()
                  .inicializarRealtimeSync(apartamentoIdRestrito: apartamentoIdDoMorador);
            }
          }
        } catch (_) {}

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() {
          _erroMensagem = authProvider.errorMessage ?? AppLocalizations.of(context)!.login_error_credentials;
        });

        // Show snackbar with error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            OwanyTheme.snackBar(
              _erroMensagem ?? AppLocalizations.of(context)!.login_error_credentials,
              type: SnackBarType.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      String mensagemErro = AppLocalizations.of(context)!.login_error_generic;
      if (e.toString().contains('Connection') || e.toString().contains('SocketException')) {
        mensagemErro = AppLocalizations.of(context)!.login_error_connection;
      }

      setState(() => _erroMensagem = mensagemErro);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(OwanyTheme.snackBar(mensagemErro, type: SnackBarType.error));
      }
    }
  }

  void _irParaForgot() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: OwanyTheme.backgroundColor(context),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),
                            _buildHeader(),
                            SizedBox(height: 48),
                            _buildFormulario(),
                            SizedBox(height: 24),
                            _buildLinkRegistro(),
                            SizedBox(height: 24),
                            _buildSeletorIdioma(),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo principal do app (ícone prédio padrão)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [OwanyTheme.primaryOrange, OwanyTheme.primaryOrange.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.apartment_rounded, size: 48, color: OwanyTheme.cardColor(context)),
        ),
        SizedBox(height: 24),

        // Título com cor Owany
        Text(
          AppLocalizations.of(context)!.login_app_name,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: OwanyTheme.primaryOrange,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        // Subtítulo
        Text(
          AppLocalizations.of(context)!.login_welcome,
          style: TextStyle(fontSize: 16, color: OwanyTheme.textMutedColor(context), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFormulario() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isLoading = authProvider.isLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Erro com design melhorado
              if (_erroMensagem != null) _buildMensagemErro(),
              if (_erroMensagem != null) SizedBox(height: 16),

              // Campo Identificador com OwanyTheme
              TextFormField(
                controller: _identificadorController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
                decoration: OwanyTheme.inputDecoration(
                  context: context,
                  label: AppLocalizations.of(context)!.login_identifier_label,
                  icon: Icons.person_outline,
                  dark: Theme.of(context).brightness == Brightness.dark,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppLocalizations.of(context)!.login_required_field;
                  }
                  return null;
                },
                // removido parâmetro 'name' (não existe em Flutter)
              ),
              SizedBox(height: 16),

              // Campo Senha com toggle
              TextFormField(
                controller: _senhaController,
                enabled: !isLoading,
                obscureText: !_mostrarSenha,
                style: TextStyle(color: OwanyTheme.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w500),
                decoration:
                    OwanyTheme.inputDecoration(
                      context: context,
                      label: AppLocalizations.of(context)!.login_password_label,
                      icon: Icons.lock_outline,
                      dark: Theme.of(context).brightness == Brightness.dark,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _mostrarSenha = !_mostrarSenha);
                        },
                        icon: Icon(
                          _mostrarSenha ? Icons.visibility : Icons.visibility_off,
                          color: OwanyTheme.textMutedColor(context),
                        ),
                      ),
                    ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppLocalizations.of(context)!.login_required_field;
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              // Link Esqueceu Senha
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : _irParaForgot,
                  style: TextButton.styleFrom(
                    foregroundColor: OwanyTheme.primaryOrange,
                    textStyle: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text(AppLocalizations.of(context)!.login_forgot_password),
                ),
              ),
              SizedBox(height: 28),

              // Botão Entrar com OwanyTheme
              PrimaryButton(
                text: isLoading
                    ? AppLocalizations.of(context)!.login_processing
                    : AppLocalizations.of(context)!.login_sign_in,
                onPressed: isLoading ? null : _realizarLogin,
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMensagemErro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.error.withValues(alpha: 0.1),
        border: Border.all(color: OwanyTheme.error.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: OwanyTheme.error, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _erroMensagem!,
              style: TextStyle(color: OwanyTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRegistro() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.login_need_access,
          textAlign: TextAlign.center,
          style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSeletorIdioma() {
    final languageProvider = context.watch<LanguageProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBotaoIdioma(AppLocalizations.of(context)!.login_language_pt, 'pt', languageProvider),
        Text(' | ', style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12)),
        _buildBotaoIdioma(AppLocalizations.of(context)!.login_language_en, 'en', languageProvider),
      ],
    );
  }

  Widget _buildBotaoIdioma(String label, String idiomaCode, LanguageProvider languageProvider) {
    final isSelected = languageProvider.idiomaCode == idiomaCode;

    return GestureDetector(
      onTap: () {
        languageProvider.setIdioma(idiomaCode);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? OwanyTheme.primaryOrange : OwanyTheme.textMutedColor(context),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
