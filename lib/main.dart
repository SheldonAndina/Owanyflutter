import 'dart:async';
import 'screens/editar_ativo_screen.dart';
import 'screens/historico_ativo_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/utility/qr_code_batch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'generated_l10n/app_localizations.dart';
import 'theme/owany_theme.dart';
import 'models/ativo.dart';
import 'models/enums.dart';
import 'providers/auth_provider.dart';
import 'providers/solicitacoes_provider.dart';
import 'providers/apartamentos_provider.dart';
import 'providers/notificacoes_provider.dart';
import 'providers/usuarios_provider.dart';
import 'providers/moradores_provider.dart';
import 'providers/historico_ocupacao_provider.dart';
import 'providers/item_movimentacao_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/sms_massa_provider.dart';
import 'providers/language_provider.dart';
import 'providers/ativos_provider.dart';
import 'providers/itens_provider.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_navigation_service.dart';
import 'services/solicitacoes_service.dart';
import 'screens/utility/manage_request_types_screen.dart';
import 'package:owany_app/widgets/themed_alert_dialog.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Core screens
import 'screens/core/dashboard_screen_moderno.dart';
import 'screens/core/maintenance_list_screen_v2.dart';
import 'screens/core/maintenance_detail_screen.dart';
import 'screens/core/maintenance_request_screen.dart';
import 'screens/core/notifications_screen.dart';

// Apartment screens
import 'screens/apartments/apartments_screen.dart';
import 'screens/apartments/apartment_detail_screen.dart';
import 'screens/apartments/create_apartment_screen.dart';
import 'screens/apartments/manage_apartment_items_screen.dart';

// User screens
import 'screens/users/users_screen.dart';
import 'screens/users/user_detail_screen.dart';
import 'screens/users/add_user_screen.dart';
import 'screens/users/edit_user_screen.dart';
import 'screens/users/manage_residents_screen.dart';
// create_morador_screen removido — morador é criado ao cadastrar usuário
import 'screens/users/morador_detail_screen.dart';

// Utility screens
import 'screens/utility/profile_screen.dart';
import 'screens/utility/settings_screen.dart';
import 'screens/utility/change_password_screen.dart';
import 'screens/utility/reports_screen.dart';
import 'screens/utility/historico_itens_screen.dart';
import 'screens/core/sms_massa_screen.dart';
import 'screens/detalhe_ativo_screen.dart';
import 'screens/gestao_ativos_screen.dart';
import 'utils/patrimonio_deep_link.dart';

// Preventive Maintenance screens
import 'screens/maintenance/manutencao_preventiva_lista_screen.dart';
import 'screens/maintenance/manutencao_preventiva_detalhes_screen.dart';
import 'screens/maintenance/manutencao_preventiva_form_screen.dart';
import 'screens/maintenance/manutencao_alertas_screen.dart';
import 'screens/agendamentos/criar_agendamento_manutencao_simples_screen.dart';
import 'providers/manutencao_preventiva_provider.dart';
import 'providers/theme_provider.dart';

// Dashboard Premium Screens

// Agendamentos Screens
import 'screens/agendamentos/agendamentos_lista_screen.dart';
import 'screens/agendamentos/agendamento_detalhes_screen.dart';
import 'screens/agendamentos/responder_agendamento_screen.dart';
import 'screens/agendamentos/avaliar_agendamento_screen.dart';
import 'providers/agendamentos_provider.dart';
import 'providers/niveis_acesso_provider.dart';
import 'providers/blocos_provider.dart';
import 'screens/users/niveis_acesso_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'dart:io' show Platform;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore: initialization errors will be handled on foreground.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientação: só bloqueia em mobile nativo (iOS/Android)
  // Desktop e Web podem usar qualquer orientação
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    } catch (_) {
      // Platform não suportada - ignora
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    } catch (_) {
      // Firebase config might be missing; keep app running.
    }
  }

  final apiService = ApiService();
  await apiService.loadToken();

  runApp(const OwanyApp());
}

class OwanyApp extends StatefulWidget {
  // When `skipInit` is true the app will skip long-running
  // initializations (deep-links, notifications, auth init).
  // This is useful for tests that instantiate the widget tree.
  final bool skipInit;

  const OwanyApp({super.key, this.skipInit = false});

  @override
  State<OwanyApp> createState() => _OwanyAppState();
}

class _OwanyAppState extends State<OwanyApp> {
  late AuthProvider _authProvider;
  late ThemeProvider _themeProvider;
  late LanguageProvider _languageProvider;
  final FcmService _fcmService = FcmService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingPatrimonioCode;
  bool _isNavigatingPendingPatrimonio = false;
  final NotificationNavigationService _notificationNavigationService =
      NotificationNavigationService();

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider();
    _languageProvider = LanguageProvider();
    _authProvider.addListener(_handleAuthChanged);
    // In test mode we avoid heavy platform/plugin initialization.
    if (widget.skipInit) {
      // Mark as initialized so the regular UI is shown in tests.
      _isInitialized = true;
      return;
    }

    _setupDeepLinks();
    _setupNotificationNavigation();
    _initializeAll();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAll() async {
    // Load language first to ensure correct locale on first render
    await _languageProvider.loadIdioma();
    await _themeProvider.loadThemeMode();
    await _authProvider.init();
    await _fcmService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    _tryNavigateToPendingPatrimonio();
    _notificationNavigationService.tryProcessPending();
  }

  Future<void> _setupNotificationNavigation() async {
    await _notificationNavigationService.initialize(
      navigatorKey: _navigatorKey,
      isMorador: () => _authProvider.isMorador,
      canNavigate: () =>
          _isInitialized &&
          _authProvider.isAuthenticated &&
          _authProvider.usuarioAtual != null,
    );
  }

  Future<void> _setupDeepLinks() async {
    if (kIsWeb) {
      _capturePatrimonioFromUri(Uri.base);
      _capturePatrimonioFromRouteName(Uri.base.fragment);
      return;
    }

    try {
      _appLinks = AppLinks();
      // Use getInitialLink() to get the initial deep link
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) {
        _capturePatrimonioFromUri(initial);
      }
      _linkSubscription = _appLinks!.uriLinkStream.listen(
        _capturePatrimonioFromUri,
        onError: (Object error) {
          debugPrint('[DeepLink] uriLinkStream error: $error');
        },
      );
    } catch (e) {
      debugPrint('[DeepLink] setup failed: $e');
    }
  }

  void _capturePatrimonioFromUri(Uri uri) {
    final code = PatrimonioDeepLink.extractCodigoFromUri(uri);
    if (code == null || code.trim().isEmpty) return;
    _pendingPatrimonioCode = code.trim();
    _tryNavigateToPendingPatrimonio();
  }

  void _capturePatrimonioFromRouteName(String? routeName) {
    if (routeName == null || routeName.trim().isEmpty) return;
    final normalized = routeName.startsWith('/') ? routeName : '/$routeName';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    _capturePatrimonioFromUri(uri);
  }

  void _handleAuthChanged() {
    _tryNavigateToPendingPatrimonio();
    _notificationNavigationService.tryProcessPending();
    _fcmService.refreshTokenRegistration();
  }

  void _tryNavigateToPendingPatrimonio() {
    if (!_isInitialized) return;
    if (_isNavigatingPendingPatrimonio) return;
    if (!_authProvider.isAuthenticated || _authProvider.usuarioAtual == null)
      return;

    final code = _pendingPatrimonioCode?.trim();
    if (code == null || code.isEmpty) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    _pendingPatrimonioCode = null;
    _isNavigatingPendingPatrimonio = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.pushNamed('/patrimonio-detalhe', arguments: code).whenComplete(
        () {
          _isNavigatingPendingPatrimonio = false;
        },
      );
    });
  }

  Ativo _buildAtivoDeepLink(String codigoPatrimonio) {
    return Ativo(
      id: '',
      codigoPatrimonio: codigoPatrimonio.trim(),
      nome: 'Patrimônio ${codigoPatrimonio.trim()}',
      descricao: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: OwanyTheme.primaryOrange,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.apartment_rounded,
                    size: 80,
                    color: OwanyTheme.white,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: _languageProvider,
        ),
        ChangeNotifierProvider<SolicitacoesProvider>(
          create: (_) => SolicitacoesProvider(SolicitacoesService()),
        ),
        ChangeNotifierProvider<ApartamentosProvider>(
          create: (_) => ApartamentosProvider(),
        ),
        ChangeNotifierProvider<NotificacoesProvider>(
          create: (_) => NotificacoesProvider(),
        ),
        ChangeNotifierProvider<UsuariosProvider>(
          create: (_) => UsuariosProvider(),
        ),
        ChangeNotifierProvider<MoradoresProvider>(
          create: (context) =>
              MoradoresProvider(context.read<ApartamentosProvider>()),
        ),
        ChangeNotifierProvider<HistoricoOcupacaoProvider>(
          create: (_) => HistoricoOcupacaoProvider(),
        ),
        ChangeNotifierProvider<ItemMovimentacaoProvider>(
          create: (_) => ItemMovimentacaoProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider<SmsMassaProvider>(
          create: (_) => SmsMassaProvider(),
        ),
        ChangeNotifierProvider<AtivosProvider>(create: (_) => AtivosProvider()),
        ChangeNotifierProvider<ItensProvider>(create: (_) => ItensProvider()),
        ChangeNotifierProvider<ManutencaoPreventivaProvider>(
          create: (_) => ManutencaoPreventivaProvider(),
        ),
        ChangeNotifierProvider<AgendamentosProvider>(
          create: (_) => AgendamentosProvider(),
        ),
        ChangeNotifierProvider<NiveisAcessoProvider>(
          create: (_) => NiveisAcessoProvider(),
        ),
        ChangeNotifierProvider<BlocosProvider>(
          create: (_) => BlocosProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'Owany',
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            locale: Locale(languageProvider.idiomaCode == 'en' ? 'en' : 'pt'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt'), Locale('en')],
            theme: _buildModernTheme(),
            darkTheme: OwanyTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _buildHome(),
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  ThemeData _buildModernTheme() {
    // Use static colors - do NOT use context-dependent OwanyTheme methods here!
    // Theme definition happens before context has a theme, causing circular issues.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: OwanyTheme.primaryOrange,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: OwanyTheme.primaryOrange,
        secondary: OwanyTheme.accent,
        surface: Colors.white,
        error: OwanyTheme.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: OwanyTheme.primaryBrown,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: OwanyTheme.primaryBrown,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: OwanyTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OwanyTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // Dialog theme for light mode
      dialogTheme: DialogThemeData(
        backgroundColor: OwanyTheme.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: OwanyTheme.primaryBrown,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: OwanyTheme.textDark,
        ),
      ),
      // TextButton in dialogs
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OwanyTheme.textMuted,
        ),
      ),
    );
  }

  /// Tela de acesso negado para rotas protegidas
  Widget _buildAcessoNegadoScreen(BuildContext context, String roleNecessario) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: OwanyTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: OwanyTheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Acesso Restrito',
                style: OwanyTheme.titleStyle(context, fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Você não tem permissão para acessar esta área.\n'
                'Nível necessário: $roleNecessario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: OwanyTheme.textMutedColor(context),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao Início'),
                style: OwanyTheme.primaryButtonStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _buildRoute(settings, context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildRoute(RouteSettings settings, BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final routeName = settings.name ?? '';
    final routeUri = routeName.isNotEmpty ? Uri.tryParse(routeName) : null;
    final deepLinkRouteCode = routeUri != null
        ? PatrimonioDeepLink.extractCodigoFromUri(routeUri)
        : null;
    final isPatrimonioDeepLinkRoute =
        deepLinkRouteCode != null && deepLinkRouteCode.trim().isNotEmpty;

    if (isPatrimonioDeepLinkRoute) {
      _pendingPatrimonioCode = deepLinkRouteCode.trim();
    }

    // Public routes (sem scaffold)
    final publicRoutes = <String, Widget>{
      '/login': const LoginScreen(),
      // '/register' removido — guia pede sem criação de conta pública
      '/forgot-password': const ForgotPasswordScreen(),
    };

    if (publicRoutes.containsKey(settings.name)) {
      return publicRoutes[settings.name]!;
    }

    // Verificar autenticação e presença de usuário carregado
    if (!authProvider.isAuthenticated || authProvider.usuarioAtual == null) {
      // se o token expirou ou usuário não carregou, força logout seguro
      if (authProvider.isAuthenticated && !authProvider.isLoggingOut) {
        Future.microtask(() => authProvider.logout(null));
      }
      return const LoginScreen();
    }

    // Role checks para proteção de rotas
    final userType = authProvider.usuarioAtual?.tipo;
    final isAdmin = userType == UsuarioTipo.Administrador;
    final isSindico = userType == UsuarioTipo.Sindico;
    final isFuncionario = userType == UsuarioTipo.Funcionario;
    final isPortaria = userType == UsuarioTipo.Portaria;
    final isVisitante = userType == UsuarioTipo.Visitante;

    final isGestor = isAdmin || isSindico;
    final isStaff = isAdmin || isSindico || isFuncionario;

    // Rotas que requerem permissão específica
    // Usuários: listagem = Admin/Síndico; criação = Admin/Síndico; edição/delete = Admin
    final rotasUsuariosView = ['/usuarios', '/usuarios-detalhe'];
    final rotasUsuariosCriar = ['/usuarios-novo'];
    final rotasUsuariosEditar = ['/usuarios-editar'];
    // Relatórios e gestão: Admin/Síndico (Gestor)
    final rotasGestor = ['/relatorios', '/smsmassa'];
    // Ativos: Admin/Sindico/Func (staff)
    final rotasAtivos = ['/ativos'];
    // Staff: Admin/Síndico/Funcionário
    final rotasStaff = [
      '/manutencoes-preventivas',
      '/manutencoes-preventivas-nova',
      '/manutencoes-preventivas-editar',
      '/qr-batch',
      '/manage_request_types',
    ];
    // Moradores: Admin/Síndico/Func para listagem; Admin/Síndico para criar (conforme API spec)
    final rotasMoradoresView = ['/moradores'];
    final rotasMoradoresCriar = ['/moradores-novo'];
    // Apartamentos: criar/editar = Admin/Síndico
    final rotasAptCriar = ['/apartamentos-novo', '/apartamentos-editar'];
    // Agendamentos: criar = Admin/Síndico/Func (conforme API spec)
    final rotasAgendCriar = [
      '/criar-agendamento-manutencao',
    ];
    // Solicitações: criar = Admin/Síndico/Func/Morador
    final rotasSolicitNova = ['/solicitacoes-nova'];

    // ========== Verificações de rota ==========
    // Usuários — view (Admin/Síndico)
    if (rotasUsuariosView.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isGestor) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador ou Síndico'),
      );
    }
    // Usuários — criar
    if (rotasUsuariosCriar.any((r) => settings.name?.startsWith(r) ?? false) &&
        !(isAdmin || isSindico)) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador ou Síndico'),
      );
    }
    // Usuários — editar
    if (rotasUsuariosEditar.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isAdmin) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador'),
      );
    }
    // Gestor routes (relatórios, SMS)
    if (rotasGestor.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isGestor) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador ou Síndico'),
      );
    }
    // Ativos — Staff (Admin/Síndico/Func)
    if (rotasAtivos.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isStaff) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Funcionário'),
      );
    }
    // Staff routes
    if (rotasStaff.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isStaff) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Funcionário'),
      );
    }
    // Moradores — view (Admin/Síndico/Func/Portaria)
    if (rotasMoradoresView.any((r) => settings.name?.startsWith(r) ?? false) &&
        !(isStaff || isPortaria)) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Funcionário ou Portaria'),
      );
    }
    // Apartamentos — portaria não pode acessar
    if (settings.name?.startsWith('/apartamentos') == true && isPortaria) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Morador ou Staff'),
      );
    }
    // Moradores — criar (Admin/Síndico conforme API spec)
    if (rotasMoradoresCriar.any((r) => settings.name?.startsWith(r) ?? false) &&
        !(isAdmin || isSindico)) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador ou Síndico'),
      );
    }
    // Apartamentos — criar/editar (Admin/Síndico)
    if (rotasAptCriar.any((r) => settings.name?.startsWith(r) ?? false) &&
        !(isAdmin || isSindico)) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Administrador ou Síndico'),
      );
    }
    // Agendamentos — criar (Admin/Síndico/Func conforme API spec)
    if (rotasAgendCriar.any((r) => settings.name?.startsWith(r) ?? false) &&
        !isStaff) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Funcionário'),
      );
    }
    // Solicitações — criar: Admin/Síndico/Func/Morador
    if (rotasSolicitNova.any((r) => settings.name?.startsWith(r) ?? false) &&
        !(isAdmin ||
            isSindico ||
            isFuncionario ||
            userType == UsuarioTipo.Morador)) {
      return MainScaffold(
        child: _buildAcessoNegadoScreen(context, 'Morador ou Staff'),
      );
    }

    // Visitante só pode acessar dashboard, perfil e configurações
    if (isVisitante &&
        !isPatrimonioDeepLinkRoute &&
        ![
          '/dashboard',
          '/perfil',
          '/configuracoes',
          '/change-password',
          '/notificacoes',
          '/patrimonio-detalhe',
        ].contains(settings.name)) {
      return MainScaffold(child: _buildAcessoNegadoScreen(context, 'Morador'));
    }

    if (isPatrimonioDeepLinkRoute) {
      final code = deepLinkRouteCode.trim();
      _pendingPatrimonioCode = null;
      return MainScaffold(
        child: DetalheAtivoScreen(codigoPatrimonio: code),
      );
    }

    // Protected routes (com scaffold)
    Widget screen;
    switch (settings.name) {
      case '/editar-ativo':
        final itemId = settings.arguments as String;
        screen = EditarAtivoScreen(itemId: itemId);
        break;
      case '/historico-ativo':
        final itemId = settings.arguments as String;
        screen = HistoricoAtivoScreen(itemId: itemId);
        break;
      case '/qr-scan':
        screen = QRScanScreen();
        break;
      case '/ativos':
      case '/gestao-ativos':
        screen = const GestaoAtivosScreen();
        break;
      case '/qr-batch':
        screen = const QrCodeBatchScreen();
        break;
      case '/solicitacoes':
        screen = const MaintenanceListScreenV2();
        break;
      case '/patrimonio-detalhe':
        final codigo = (settings.arguments as String? ?? '').trim();
        screen = codigo.isEmpty
            ? DashboardScreenModerno()
            : DetalheAtivoScreen(codigoPatrimonio: codigo);
        break;
      // Core
      case '/dashboard':
        screen = DashboardScreenModerno();
        break;
      // Utility
      case '/perfil':
        screen = const ProfileScreen();
        break;
      case '/configuracoes':
        screen = const SettingsScreen();
        break;
      case '/change-password':
        screen = const ChangePasswordScreen();
        break;
      case '/relatorios':
        screen = const ReportsScreen();
        break;
      case '/notificacoes':
        screen = const NotificationsScreen();
        break;
      case '/historico-itens':
        screen = const HistoricoItensScreen();
        break;
      case '/smsmassa':
        screen = const SmsMassaScreen();
        break;
      case '/manage_request_types':
        screen = const ManageRequestTypesScreen();
        break;
      case '/solicitacoes-nova':
      case '/solicitacao-criar': // Nova rota para solicitações
        screen = const MaintenanceRequestScreen();
        break;
      case '/solicitacoes-detalhe':
      case '/solicitacao-detalhes': // Nova rota para solicitações
        final args = settings.arguments;
        String solicitacaoId = '';
        String? comentarioId;
        if (args is Map) {
          solicitacaoId = args['solicitacaoId']?.toString() ?? '';
          comentarioId = args['comentarioId']?.toString();
        } else if (args is String) {
          solicitacaoId = args;
        }
        screen = MaintenanceDetailScreen(
          solicitacaoId: solicitacaoId,
          comentarioId: comentarioId,
        );
        break;

      // Apartamentos
      case '/apartamentos':
        screen = const ApartmentsScreen();
        break;
      case '/apartamentos-detalhe':
        screen = ApartmentDetailScreen(
          apartamentoId: settings.arguments as String? ?? '',
        );
        break;
      case '/apartamentos-novo':
        screen = const CreateApartmentScreen();
        break;
      case '/apartamentos-editar':
        // Rota de edição de apartamento — usa tela de criação (futuro: tela de edição dedicada)
        screen = const CreateApartmentScreen();
        break;
      case '/apartamentos-itens':
        final args = settings.arguments as Map<String, dynamic>?;
        screen = ManageApartmentItemsScreen(
          apartamentoId: args?['id'] as String? ?? '',
          apartamentoNome: args?['nome'] as String? ?? 'Apartamento',
        );
        break;

      // Usuários
      case '/usuarios':
        screen = const UsersScreen();
        break;
      case '/usuarios-detalhe':
        screen = UserDetailScreen(
          usuarioId: settings.arguments as String? ?? '',
        );
        break;
      case '/usuarios-novo':
        screen = const AddUserScreen();
        break;
      case '/usuarios-editar':
        screen = EditUserScreen(usuarioId: settings.arguments as String? ?? '');
        break;
      case '/niveis-acesso':
        screen = const NiveisAcessoScreen();
        break;

      // Moradores
      case '/moradores':
        screen = const ManageResidentsScreen();
        break;
      case '/moradores-novo':
        // Morador é criado ao cadastrar um usuário
        screen = const ManageResidentsScreen();
        break;
      case '/moradores-detalhe':
      case '/utility-morador-detalhe':
        final moradorId = settings.arguments as String? ?? '';
        screen = MoradorDetailScreen(moradorId: moradorId);
        break;

      // Manutenções Preventivas/Gerais
      case '/manutencoes-preventivas':
      case '/manutencoes': // Nova rota unificada
        screen = const ManutencaoPreventivaListaScreen();
        break;
      case '/manutencoes-preventivas-alertas':
      case '/manutencao-alertas': // Nova rota
        screen = const ManutencaoAlertasScreen();
        break;
      case '/manutencoes-preventivas-detalhes':
      case '/manutencao-detalhes': // Nova rota
        screen = ManutencaoPreventivaDetalhesScreen(
          manutencaoId: settings.arguments as String? ?? '',
        );
        break;
      case '/manutencoes-preventivas-nova':
      case '/manutencao-criar': // Nova rota
        screen = const ManutencaoPreventivaFormScreen();
        break;
      case '/manutencoes-preventivas-editar':
      case '/manutencao-editar': // Nova rota
        screen = ManutencaoPreventivaFormScreen(
          manutencaoId: settings.arguments as String?,
        );
        break;

      // ============ DASHBOARD PREMIUM SCREENS ============
      case '/dashboard-kpis':
        screen = const ReportsScreen();
        break;
      case '/dashboard-alertas':
        screen = const ReportsScreen();
        break;
      case '/dashboard-manutencoes':
        screen = const ReportsScreen();
        break;
      case '/dashboard-ocupacao':
        screen = const ReportsScreen();
        break;
      case '/dashboard-satisfacao':
        screen = const ReportsScreen();
        break;
      case '/dashboard-areas':
        screen = const ReportsScreen();
        break;

      // ============ AGENDAMENTOS SCREENS ============
      case '/agendamentos':
      case '/agendamentos-lista': // Alias
        screen = const AgendamentosListaScreen();
        break;
      case '/agendamento-detalhes':
        screen = AgendamentoDetalhesScreen(
          agendamentoId: settings.arguments as String? ?? '',
        );
        break;
      case '/criar-agendamento-manutencao':
      case '/agendamento-criar': // Nova rota
      case '/agendamento-form': // Alias usado em algumas screens
        screen = const CriarAgendamentoManutencaoSimplesScreen();
        break;
      case '/responder-agendamento':
        screen = ResponderAgendamentoScreen(
          agendamentoId: settings.arguments as String? ?? '',
        );
        break;
      case '/avaliar-agendamento':
        screen = AvaliarAgendamentoScreen(
          agendamentoId: settings.arguments as String? ?? '',
        );
        break;

      // ============ ATIVOS SCREENS ============
      // Rotas de ativos movidas para o switch principal acima

      default:
        screen = DashboardScreenModerno();
    }

    return MainScaffold(child: screen);
  }

  Widget _buildHome() {
    final hasUser =
        _authProvider.isAuthenticated && _authProvider.usuarioAtual != null;
    return hasUser
        ? MainScaffold(child: DashboardScreenModerno())
        : const LoginScreen();
  }
}

/// ==========================
/// MAIN SCAFFOLD - Layout Completo
/// ==========================
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Obtém a inicial do nome do usuário (primeira letra maiúscula)
  String _getInitial(String? nome) {
    if (nome == null || nome.isEmpty) return 'U';
    return nome[0].toUpperCase();
  }

  /// Obtém o label traduzido do tipo de usuário
  String _getUserTypeLabel(UsuarioTipo? userType, AppLocalizations l10n) {
    if (userType == null) return l10n.drawer_resident_default;
    switch (userType) {
      case UsuarioTipo.Administrador:
        return l10n.role_administrator;
      case UsuarioTipo.Funcionario:
        return l10n.role_employee;
      case UsuarioTipo.Morador:
        return l10n.role_resident;
      case UsuarioTipo.Sindico:
        return l10n.role_syndic;
      case UsuarioTipo.Portaria:
        return l10n.role_doorman;
      case UsuarioTipo.Visitante:
        return l10n.role_visitor;
    }
  }

  /// Constrói o header do drawer com perfil do usuário
  Widget _buildDrawerHeader(
    BuildContext context,
    dynamic usuario,
    UsuarioTipo? userType,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      color: OwanyTheme.backgroundColor(context),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            },
            child: Hero(
              tag: 'user_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: OwanyTheme.primaryOrange.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: OwanyTheme.primaryOrange,
                  child: Text(
                    _getInitial(usuario?.nome),
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OwanyTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: OwanyTheme.borderColor(context),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  usuario?.nome ?? l10n.drawer_user_default,
                  style: TextStyle(
                    color: OwanyTheme.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getUserTypeLabel(userType, l10n),
                    style: TextStyle(
                      color: OwanyTheme.primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
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
    final authProvider = context.watch<AuthProvider>();
    final notificacoesProvider = context.watch<NotificacoesProvider>();

    // Se o usuário desaparecer (token inválido), força logout e mostra loader breve
    if (!authProvider.isAuthenticated || authProvider.usuarioAtual == null) {
      if (authProvider.isAuthenticated && !authProvider.isLoggingOut) {
        Future.microtask(() => authProvider.logout(null));
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(OwanyTheme.primaryOrange),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: _buildModernAppBar(context, authProvider, notificacoesProvider),
      drawer: _buildModernDrawer(context, authProvider),
      body: widget.child,
      bottomNavigationBar: _buildModernBottomNav(context),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// AppBar Moderna e Completa
  PreferredSizeWidget _buildModernAppBar(
    BuildContext context,
    AuthProvider authProvider,
    NotificacoesProvider notificacoesProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    String title = l10n.dashboard_title;

    // Determinar título baseado na rota
    if (currentRoute.contains('solicitacoes'))
      title = l10n.dashboard_maintenance;
    if (currentRoute.contains('apartamentos'))
      title = l10n.apartments_list_title;
    if (currentRoute.contains('manutencoes-preventivas'))
      title = l10n.mp_list_title;
    if (currentRoute.contains('agendamentos')) title = l10n.agendamentos_title;
    if (currentRoute.contains('areas-comuns') ||
        currentRoute.contains('area-comum'))
      title = l10n.reports_common_areas;
    if (currentRoute.contains('reservas-apartamento') ||
        currentRoute.contains('reserva-apartamento') ||
        currentRoute.contains('portaria'))
      title = l10n.agendamentos_title;
    if (currentRoute.contains('usuarios')) title = l10n.users_title;
    if (currentRoute.contains('moradores')) title = l10n.common_residents;
    if (currentRoute.contains('perfil')) title = l10n.profile_title;
    if (currentRoute.contains('configuracoes')) title = l10n.settings_title;
    if (currentRoute.contains('notificacoes'))
      title = l10n.settings_notifications;
    if (currentRoute.contains('relatorios')) title = l10n.reports_title;

    final notificationCount = notificacoesProvider.totalNaoLidas;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: OwanyTheme.cardColor(context),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.menu_rounded, size: 24),
        color: OwanyTheme.textPrimary(context),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: OwanyTheme.textPrimary(context),
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        // Notificações
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, size: 24),
              color: OwanyTheme.textPrimary(context),
              onPressed: () => Navigator.pushNamed(context, '/notificacoes'),
            ),
            if (notificationCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: OwanyTheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationCount > 9 ? '9+' : '$notificationCount',
                    style: TextStyle(
                      color: OwanyTheme.adaptiveTextOverlay(context),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 4),

        // Perfil
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/perfil'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: OwanyTheme.backgroundColor(context),
              child: Text(
                _getInitial(authProvider.usuarioAtual?.nome),
                style: TextStyle(
                  color: OwanyTheme.primaryOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: OwanyTheme.borderColor(context)),
      ),
    );
  }

  /// Drawer Moderno - Layout lateral de navegação
  Widget _buildModernDrawer(BuildContext context, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    final usuario = authProvider.usuarioAtual;
    final userType = usuario?.tipo;

    // Role checks mais granulares
    final isAdmin = userType == UsuarioTipo.Administrador;
    final isSindico = userType == UsuarioTipo.Sindico;
    final isFuncionario = userType == UsuarioTipo.Funcionario;
    final isPortaria = userType == UsuarioTipo.Portaria;

    // Permissões por nível
    final isGestor = isAdmin || isSindico; // Pode gerenciar tudo
      final isStaff =
          isAdmin || isSindico || isFuncionario; // Pode ver mais coisas
      final podeVerTudo = isAdmin || isSindico || isFuncionario;

    final solicitacoesProvider = context.watch<SolicitacoesProvider>();
    final notificacoesProvider = context.watch<NotificacoesProvider>();
    final pendentes = solicitacoesProvider.solicitacoes
        .where((s) => s.status.toString().toLowerCase().contains('pendente'))
        .length;
    final notifCount = notificacoesProvider.totalNaoLidas;

    return Drawer(
      backgroundColor: OwanyTheme.backgroundColor(context),
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header com gradiente suave
            _buildDrawerHeader(context, usuario, userType, l10n),
            SizedBox(height: 4),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _DrawerSectionLabel(
                    text: l10n.drawer_main,
                    icon: Icons.home_rounded,
                  ),
                  SizedBox(height: 8),
                  // Dashboard - todos podem ver
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: l10n.dashboard_title,
                    route: '/dashboard',
                    isSelected: currentRoute == '/dashboard',
                  ),
                    // Solicitações — Admin/Síndico/Func veem todas; Morador vê só as suas
                    if (isStaff)
                      _DrawerItem(
                        icon: Icons.build_rounded,
                        title: l10n.dashboard_maintenance,
                        route: '/solicitacoes',
                        isSelected: currentRoute.contains('solicitacoes'),
                      badge: (isStaff && pendentes > 0)
                          ? (pendentes > 9 ? '9+' : '$pendentes')
                          : null,
                      badgeColor: OwanyTheme.warning,
                    ),
                  if (userType == UsuarioTipo.Morador)
                    _DrawerItem(
                      icon: Icons.build_rounded,
                      title: l10n.dashboard_maintenance,
                      route: '/solicitacoes',
                      isSelected: currentRoute.contains('solicitacoes'),
                    ),
                    // Apartamentos — Admin/Síndico/Func veem lista; Morador vê "Meu Apartamento"
                    if (podeVerTudo)
                      _DrawerItem(
                        icon: Icons.apartment_rounded,
                        title: l10n.apartments_list_title,
                        route: '/apartamentos',
                        isSelected: currentRoute.contains('apartamentos'),
                    ),
                  if (userType == UsuarioTipo.Morador)
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      title: l10n.apartments_list_title,
                      route: '/apartamentos',
                      isSelected: currentRoute.contains('apartamentos'),
                    ),
                  // Manutenções Preventivas - staff apenas
                  if (isStaff)
                    _DrawerItem(
                      icon: Icons.build_circle_rounded,
                      title: l10n.mp_list_title,
                      route: '/manutencoes-preventivas-alertas',
                      isSelected: currentRoute.contains(
                        'manutencoes-preventivas',
                      ),
                    ),
                  // Agendamentos — Admin/Síndico/Func/Morador (NÃO Portaria/Visitante)
                  if (isStaff || userType == UsuarioTipo.Morador)
                    _DrawerItem(
                      icon: Icons.calendar_today_rounded,
                      title: l10n.agendamentos_title,
                      route: '/agendamentos',
                      isSelected: currentRoute.contains('agendamentos'),
                    ),
                  // Gestão de Ativos - admin, síndico e funcionário (conforme API spec)
                  if (isStaff) ...[
                    _DrawerItem(
                      icon: Icons.inventory_2_rounded,
                      title: l10n.drawer_asset_management,
                      route: '/ativos',
                      isSelected: currentRoute == '/ativos',
                    ),
                  ],
                  // QR Codes em Lote - admin, síndico, funcionário
                  if (isStaff)
                    _DrawerItem(
                      icon: Icons.qr_code_2_rounded,
                      title: l10n.assets_generate_batch_qr,
                      route: '/qr-batch',
                      isSelected: currentRoute == '/qr-batch',
                    ),
                  // Administração — seção visível para Admin, Síndico e Funcionário com itens condicionais
                  if (isStaff) ...[
                    SizedBox(height: 20),
                    _DrawerSectionLabel(
                      text: l10n.drawer_administration,
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    SizedBox(height: 8),
                    // Usuários — somente Admin e Síndico podem listar
                    if (isGestor)
                      _DrawerItem(
                        icon: Icons.people_rounded,
                        title: l10n.users_title,
                        route: '/usuarios',
                        isSelected: currentRoute.contains('usuarios'),
                      ),
                    // Relatórios — Admin e Síndico apenas (Gestor)
                    if (isGestor)
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        title: l10n.reports_title,
                        route: '/relatorios',
                        isSelected: currentRoute.contains('relatorios'),
                      ),
                    // Tipos de Solicitação — Staff (Admin/Síndico/Func)
                    _DrawerItem(
                      icon: Icons.category_rounded,
                      title: l10n.drawer_request_types,
                      route: '/manage_request_types',
                      isSelected: currentRoute == '/manage_request_types',
                    ),
                  ],
                    // Gestão de Moradores — Admin/Síndico/Func
                    if (isStaff) ...[
                      SizedBox(height: 20),
                      _DrawerSectionLabel(
                        text: l10n.drawer_resident_management,
                        icon: Icons.groups_rounded,
                      ),
                    SizedBox(height: 8),
                      _DrawerItem(
                        icon: Icons.group_rounded,
                        title: l10n.common_residents,
                        route: '/moradores',
                        isSelected: currentRoute.contains('moradores'),
                      ),
                    ],
                    if (isPortaria) ...[
                      SizedBox(height: 20),
                      _DrawerSectionLabel(
                        text: l10n.drawer_resident_management,
                        icon: Icons.groups_rounded,
                      ),
                      SizedBox(height: 8),
                      _DrawerItem(
                        icon: Icons.group_rounded,
                        title: l10n.common_residents,
                        route: '/moradores',
                        isSelected: currentRoute.contains('moradores'),
                      ),
                    ],
                  SizedBox(height: 24),
                  Divider(
                    color: Colors.grey.withValues(alpha: 0.2),
                    thickness: 1,
                  ),
                  SizedBox(height: 20),
                  _DrawerSectionLabel(
                    text: l10n.drawer_account,
                    icon: Icons.person_outline_rounded,
                  ),
                  SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: l10n.profile_title,
                    route: '/perfil',
                    isSelected: currentRoute == '/perfil',
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: l10n.settings_title,
                    route: '/configuracoes',
                    isSelected: currentRoute == '/configuracoes',
                    badge: notifCount > 0
                        ? (notifCount > 9 ? '9+' : '$notifCount')
                        : null,
                    badgeColor: OwanyTheme.error,
                  ),
                ],
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _LogoutButton(authProvider: authProvider, l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation - Barra de navegação inferior suave e minimalista
  Widget _buildModernBottomNav(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/dashboard';
    final authProvider = context.read<AuthProvider>();
    final isPortaria = authProvider.usuarioAtual?.tipo == UsuarioTipo.Portaria;
    final currentIndex = _getCurrentNavIndex(currentRoute);

    return Container(
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Builder(
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
                if (isPortaria) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: l10n.nav_home,
                        isSelected: currentRoute == '/dashboard',
                        onTap: () => _navigateToRoute(context, '/dashboard'),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: l10n.nav_profile,
                        isSelected: currentRoute.contains('perfil') ||
                            currentRoute.contains('configuracoes'),
                        onTap: () => _navigateToRoute(context, '/perfil'),
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: l10n.nav_home,
                      isSelected: currentIndex == 0,
                      onTap: () => _navigateToRoute(context, '/dashboard'),
                    ),
                    _NavItem(
                      icon: Icons.build_circle_rounded,
                      label: l10n.nav_services,
                      isSelected: currentIndex == 1,
                      onTap: () => _navigateToRoute(context, '/solicitacoes'),
                    ),
                    _NavItem(
                      icon: Icons.apartment_rounded,
                      label: l10n.nav_properties,
                      isSelected: currentIndex == 2,
                      onTap: () => _navigateToRoute(context, '/apartamentos'),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: l10n.nav_profile,
                      isSelected: currentIndex == 3,
                      onTap: () => _navigateToRoute(context, '/perfil'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
  }

  /// Determina o índice ativo da navegação baseado na rota
  int _getCurrentNavIndex(String route) {
    if (route.contains('solicitacoes')) return 1;
    if (route.contains('apartamentos')) return 2;
    if (route.contains('perfil') || route.contains('configuracoes')) return 3;
    return 0;
  }

  /// Navega para uma rota evitando navegação redundante
  void _navigateToRoute(BuildContext context, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  /// FAB — só visível para perfis que podem criar algo
  Widget? _buildFAB(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userType = authProvider.usuarioAtual?.tipo;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    // Portaria e Visitante não têm ações de criação
    if (userType == UsuarioTipo.Portaria ||
        userType == UsuarioTipo.Visitante ||
        userType == null) {
      return null;
    }

    // Evita FAB duplicado quando a tela já possui FAB próprio.
    final hasLocalFab = currentRoute.contains('/agendamentos') ||
        currentRoute.contains('/apartamentos') ||
        currentRoute.contains('/ativos') ||
        currentRoute.contains('/usuarios') ||
        currentRoute.contains('/moradores') ||
        currentRoute.contains('/manutencoes-preventivas');
    if (hasLocalFab) return null;

    return FloatingActionButton(
      heroTag: 'main_fab',
      onPressed: () => _showAddModal(context),
      child: Icon(Icons.add_rounded, size: 28),
    );
  }

  /// Modal de Adicionar — com checagem de perfil por ação
  void _showAddModal(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userType = authProvider.usuarioAtual?.tipo;
    if (userType == null) return;

    final isAdmin = userType == UsuarioTipo.Administrador;
    final isSindico = userType == UsuarioTipo.Sindico;
    final isFuncionario = userType == UsuarioTipo.Funcionario;
    final isMorador = userType == UsuarioTipo.Morador;
    final isStaff = isAdmin || isSindico || isFuncionario;

    // Permissões por ação conforme guia
    final podeCriarSolicitacao =
        isAdmin || isSindico || isFuncionario || isMorador;
    final podeCriarManutencaoPreventiva = isStaff;
    final podeCriarAgendamento =
        isAdmin || isSindico || isFuncionario; // Admin, Síndico, Func (conforme API spec)
    final podeCriarApartamento = isAdmin || isSindico;
    final podeCriarUsuario = isAdmin || isSindico;
    final podeEnviarSMS = isAdmin || isSindico;

    // Se nenhuma ação disponível, não mostra o modal
    if (!podeCriarSolicitacao &&
        !podeCriarManutencaoPreventiva &&
        !podeCriarAgendamento &&
        !podeCriarApartamento &&
        !podeCriarUsuario &&
        !podeEnviarSMS) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        final l10n = AppLocalizations.of(modalContext)!;
        return Container(
          decoration: BoxDecoration(
            color: OwanyTheme.cardColor(context),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fab_add,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Solicitação — Admin, Síndico, Funcionário, Morador
                        if (podeCriarSolicitacao) ...[
                          _AddOption(
                            icon: Icons.build_rounded,
                            title: l10n.fab_apartment_maintenance_title,
                            subtitle: l10n.fab_apartment_maintenance_subtitle,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(
                                context,
                                '/solicitacoes-nova',
                              );
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                        // Manutenção Preventiva — Staff only
                        if (podeCriarManutencaoPreventiva) ...[
                          _AddOption(
                            icon: Icons.build_circle_rounded,
                            title: l10n.fab_preventive_maintenance_title,
                            subtitle: l10n.fab_preventive_maintenance_subtitle,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(
                                context,
                                '/manutencoes-preventivas-nova',
                              );
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                        // Agendamento — Admin, Síndico
                        if (podeCriarAgendamento) ...[
                          _AddOption(
                            icon: Icons.event_available_rounded,
                            title: l10n.agendamentos_new_title,
                            subtitle: l10n.agendamentos_schedule_maintenance,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(
                                context,
                                '/criar-agendamento-manutencao',
                              );
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                        // Apartamento — Admin, Síndico
                        if (podeCriarApartamento) ...[
                          _AddOption(
                            icon: Icons.apartment_rounded,
                            title: l10n.fab_new_apartment,
                            subtitle: l10n.fab_new_apartment_subtitle,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(
                                context,
                                '/apartamentos-novo',
                              );
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                        // Usuário — Admin, Síndico
                        if (podeCriarUsuario) ...[
                          _AddOption(
                            icon: Icons.person_add_rounded,
                            title: l10n.fab_new_user,
                            subtitle: l10n.fab_new_user_subtitle,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(context, '/usuarios-novo');
                            },
                          ),
                          SizedBox(height: 8),
                        ],
                        // SMS em Massa — Admin, Síndico
                        if (podeEnviarSMS) ...[
                          _AddOption(
                            icon: Icons.campaign_rounded,
                            title: l10n.fab_general_announcement,
                            subtitle: l10n.fab_general_announcement_subtitle,
                            onTap: () {
                              Navigator.pop(modalContext);
                              Navigator.pushNamed(context, '/smsmassa');
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ==========================
/// COMPONENTES
/// ==========================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSelected;
  final String? badge;
  final Color? badgeColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.isSelected,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: OwanyTheme.primaryOrange.withValues(alpha: 0.06),
          highlightColor: OwanyTheme.primaryOrange.withValues(alpha: 0.04),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? OwanyTheme.primaryOrange.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? OwanyTheme.primaryOrange.withValues(alpha: 0.28)
                    : OwanyTheme.borderColor(context).withValues(alpha: 0.0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  width: isSelected ? 4 : 0,
                  height: 28,
                  margin: EdgeInsets.only(right: isSelected ? 10 : 0),
                  decoration: BoxDecoration(
                    color: OwanyTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? OwanyTheme.primaryOrange.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? OwanyTheme.primaryOrange
                        : OwanyTheme.textMutedColor(context),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      color: isSelected
                          ? OwanyTheme.primaryOrange
                          : OwanyTheme.textMutedColor(context),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                if (badge != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? OwanyTheme.primaryOrange)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (badgeColor ?? OwanyTheme.primaryOrange)
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: badgeColor ?? OwanyTheme.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )
                else if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: OwanyTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthProvider authProvider;
  final AppLocalizations l10n;

  const _LogoutButton({required this.authProvider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleLogout(context),
      borderRadius: BorderRadius.circular(16),
      splashColor: OwanyTheme.error.withValues(alpha: 0.05),
      highlightColor: OwanyTheme.error.withValues(alpha: 0.03),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              OwanyTheme.error.withValues(alpha: 0.08),
              OwanyTheme.error.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: OwanyTheme.error.withValues(alpha: 0.22),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: OwanyTheme.error.withValues(alpha: 0.85),
                size: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.drawer_logout,
                style: TextStyle(
                  color: OwanyTheme.error.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: OwanyTheme.error.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ThemedAlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.drawer_logout_confirm_title,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l10n.drawer_logout_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OwanyTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.common_exit,
              style: TextStyle(color: OwanyTheme.adaptiveTextOverlay(context)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final navigator = Navigator.of(context);
      await authProvider.logout(context);
      navigator.pushReplacementNamed('/login');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
          highlightColor: OwanyTheme.primaryOrange.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? OwanyTheme.primaryOrange.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? OwanyTheme.primaryOrange
                        : OwanyTheme.textMutedColor(context),
                    size: 24,
                  ),
                ),
                SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: isSelected
                        ? OwanyTheme.primaryOrange
                        : OwanyTheme.textMutedColor(context),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OwanyTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OwanyTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: OwanyTheme.primaryOrange, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _DrawerSectionLabel({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: Color(0xFFB0B0B0),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: icon == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: OwanyTheme.textMutedColor(context)),
                SizedBox(width: 8),
                label,
              ],
            ),
    );
  }
}
