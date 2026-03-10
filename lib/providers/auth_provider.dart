import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dto/api_dtos.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../models/niveis_acesso.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../utils/app_logger.dart';
import 'notificacoes_provider.dart';
import 'solicitacoes_provider.dart';
import 'apartamentos_provider.dart';
import 'agendamentos_provider.dart';
import 'usuarios_provider.dart';
import 'moradores_provider.dart';
import 'dashboard_provider.dart';
import 'manutencao_preventiva_provider.dart';

/// AuthProvider manages user authentication state globally
/// Handles login, logout, token persistence, and role-based access
class AuthProvider extends ChangeNotifier {
  Usuario? _usuarioAtual;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _tempTelefone;
  String? _tempTelefoneMascarado;
  String? _tempNomeLogin;
  String? _tempUsuarioId;
  StreamSubscription<Map<String, dynamic>>? _moradorDataChangedSub;

  // Getters
  Usuario? get usuarioAtual => _usuarioAtual;
  bool get isLoading => _isLoading;
  bool get isLoggingOut => _isLoggingOut;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get tempTelefone => _tempTelefone;
  String? get tempTelefoneMascarado => _tempTelefoneMascarado;
  String? get tempNomeLogin => _tempNomeLogin;
  String? get tempUsuarioId => _tempUsuarioId;

  // Role helpers
  bool get isAdmin => _usuarioAtual?.tipo == UsuarioTipo.Administrador;
  bool get isSindico => _usuarioAtual?.tipo == UsuarioTipo.Sindico;
  bool get isGestor => isAdmin || isSindico;
  bool get isFuncionario => _usuarioAtual?.tipo == UsuarioTipo.Funcionario;
  bool get isPortaria => _usuarioAtual?.tipo == UsuarioTipo.Portaria;
  bool get isMorador => _usuarioAtual?.tipo == UsuarioTipo.Morador;
  bool get isVisitante => _usuarioAtual?.tipo == UsuarioTipo.Visitante;
  bool get isStaff => isAdmin || isSindico || isFuncionario; // Staff com acesso ampliado
  bool get isResponsavel => isAdmin || isFuncionario; // Pode ser responsável por manutenção
  bool get usuarioAtivo => _usuarioAtual?.ativo == true;
  
  // Permissões específicas de manutenção
  bool get podeAtribuirResponsavel => isAdmin || isSindico || isFuncionario; // Admin/Síndico/Func pode atribuir responsável
  bool get podeDefinirPrazo => isResponsavel || isGestor; // Admin/Síndico/Func pode definir prazo
  bool get podeEdicionarSolicitacao => isGestor || (isFuncionario && isResponsavel);

  // ==================== SISTEMA DE PERMISSÕES RBAC ====================
  
  /// Verifica se o usuário tem uma permissão específica
  bool hasPermission(String permissao) {
    if (_usuarioAtual == null) return false;
    final permissoes = RolePermissoes.getPermissoesParaRole(_usuarioAtual!.tipo);
    return permissoes.contains(permissao);
  }
  
  /// Verifica se pode ver todos os recursos de um tipo
  bool canViewAll(String recurso) {
    return hasPermission('$recurso.viewall');
  }
  
  /// Verifica se pode criar um recurso
  bool canCreate(String recurso) {
    return hasPermission('$recurso.create');
  }
  
  /// Verifica se pode editar um recurso
  bool canEdit(String recurso) {
    return hasPermission('$recurso.edit');
  }
  
  /// Verifica se pode deletar um recurso
  bool canDelete(String recurso) {
    return hasPermission('$recurso.delete');
  }
  
  /// Retorna o apartamentoId do morador (se for morador)
  String? get apartamentoIdDoMorador => _usuarioAtual?.moradorInfo?.apartamentoId;
  
  /// Log de tentativa de acesso negado (para auditoria)
  void logAcessoNegado(String recurso, String acao) {
    AppLogger.warning('AuthProvider', 
      '🔒 ACESSO NEGADO: ${_usuarioAtual?.nome} (${_usuarioAtual?.tipo}) tentou $acao em $recurso');
  }

  final ApiService _apiService = ApiService();

  /// Initialize auth on app start - load persisted token
  Future<void> init() async {
    await _apiService.loadToken();
    if (_apiService.token != null) {
      _isAuthenticated = true;
      try {
        // Try to get current user profile with existing token
        _usuarioAtual = await _apiService.getPerfilAtual();
        notifyListeners();

        // Conectar SignalR se token válido
        try {
          await SignalRService().conectar();
        } catch (e) {
          AppLogger.error('AuthProvider', 'Erro ao conectar SignalR no init: $e');
        }
      } catch (e) {
        // Token expired or invalid - clear auth state
        _usuarioAtual = null;
        _isAuthenticated = false;
        _errorMessage = null;
        notifyListeners();
      }
    }
  }

  /// Login with credentials
  Future<bool> login(String nomeLogin, String senha) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(nomeLogin, senha);
      
      // Após login bem-sucedido, buscar perfil completo (inclui moradorInfo)
      try {
        _usuarioAtual = await _apiService.getPerfilAtual();
        final mi = _usuarioAtual?.moradorInfo;
        AppLogger.info('AuthProvider', 'Perfil carregado: tipo=${_usuarioAtual?.tipo}, moradorInfo=${mi != null}, apartamentoId=${mi?.apartamentoId ?? "null"}, moradorId=${mi?.moradorId ?? "null"}');
      } catch (e) {
        // Fallback: usar dados do login response se getPerfilAtual falhar
        AppLogger.warning('AuthProvider', 'Não foi possível carregar perfil completo, usando dados do login: $e');
        _usuarioAtual = Usuario(
          id: response.usuarioId,
          nome: response.nome,
          nomeLogin: response.nomeLogin,
          telefone: response.telefone,
          tipo: _parseUsuarioTipo(response.role),
          ativo: true,
          criadoEm: DateTime.now(),
          ultimoLoginEm: response.ultimoLoginEm,
        );
      }
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      // Conectar SignalR para notificações em tempo real
      try {
        await SignalRService().conectar();
        // Subscrever DataChanged para atualizar moradorInfo em tempo real
        _moradorDataChangedSub?.cancel();
        _moradorDataChangedSub =
            SignalRService().onDataChanged.listen((data) {
          if (data['entidade']?.toString() == 'Morador' &&
              _usuarioAtual?.tipo == UsuarioTipo.Morador) {
            recarregarPerfil();
          }
        });
      } catch (e) {
        AppLogger.error('AuthProvider', 'Erro ao conectar SignalR após login: $e');
      }

      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String nome,
    required String nomeLogin,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    String tipo = 'Morador',
  }) async {
    if (senha != confirmarSenha) {
      _errorMessage = 'As senhas não correspondem.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        nome: nome,
        nomeLogin: nomeLogin,
        telefone: telefone,
        senha: senha,
        confirmarSenha: confirmarSenha,
        tipo: tipo,
      );
      
      _usuarioAtual = await _apiService.register(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> mudarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    if (novaSenha != confirmarNovaSenha) {
      _errorMessage = 'As senhas não correspondem.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = MudarSenhaRequest(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
        confirmarNovaSenha: confirmarNovaSenha,
      );
      
      await _apiService.mudarSenha(request);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request password reset via nomeLogin
  Future<bool> solicitarReset(String nomeLogin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.solicitarReset(nomeLogin);
      if (response == null || response.telefoneCompleto.isEmpty) {
        _errorMessage = 'Não foi possível identificar o telefone cadastrado.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _tempNomeLogin = nomeLogin;
      _tempUsuarioId = response.usuarioId;
      _tempTelefone = response.telefoneCompleto;
      _tempTelefoneMascarado = response.telefoneMascarado;
      AppLogger.debug('AuthProvider', '[DEBUG] solicitarReset armazenou _tempUsuarioId: "$_tempUsuarioId" (length: ${_tempUsuarioId?.length ?? 0})');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validate SMS code
  Future<bool> validarCodigo(String codigo) async {
    if (_tempUsuarioId == null && (_tempTelefone == null || _tempTelefone!.isEmpty)) {
      _errorMessage = 'Sessão expirada. Reinicie o processo.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call API to validate code with usuarioId (prioritized) and telefone as fallback
      AppLogger.debug('AuthProvider', '[DEBUG] validarCodigo chamando API com _tempUsuarioId: "$_tempUsuarioId" (length: ${_tempUsuarioId?.length ?? 0})');
      await _apiService.validarCodigoSenha(_tempUsuarioId, _tempTelefone!, codigo);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password with token from SMS
  Future<bool> resetarSenha({
    required String codigo,
    required String novaSenha,
  }) async {
    if (_tempUsuarioId == null && (_tempTelefone == null || _tempTelefone!.isEmpty)) {
      _errorMessage = 'Sessão expirada. Reinicie o processo.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resetarSenha(_tempTelefone!, codigo, novaSenha);
      
      // After successful password reset, clear authenticated session
      // User must login with new password
      _tempTelefone = null;
      _tempTelefoneMascarado = null;
      _tempNomeLogin = null;
      _tempUsuarioId = null;
      
      // If user was authenticated, logout them (optional but recommended)
      if (_isAuthenticated) {
        AppLogger.debug('AuthProvider', '[DEBUG] resetarSenha: Clearing authenticated session, user must login with new password');
        _usuarioAtual = null;
        _isAuthenticated = false;
        await _apiService.logout();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout - Clear user data and ALL cached data from other providers
  Future<void> logout(BuildContext? context) async {
    if (_isLoggingOut) {
      return;
    }
    _isLoggingOut = true;
    try {
      AppLogger.info('AuthProvider', '🔴 LOGOUT INICIADO - Limpando estado...');
        // Cancelar subscription de DataChanged
        _moradorDataChangedSub?.cancel();
        _moradorDataChangedSub = null;
      // using BuildContext after awaits (use_build_context_synchronously).
      SolicitacoesProvider? solicitacoesProvider;
      ApartamentosProvider? apartamentosProvider;
      AgendamentosProvider? agendamentosProvider;
      UsuariosProvider? usuariosProvider;
      MoradoresProvider? moradoresProvider;
      DashboardProvider? dashboardProvider;
      ManutencaoPreventivaProvider? manutencaoPreventivaProvider;
      NotificacoesProvider? notificacoesProvider;

      if (context != null) {
        try {
          solicitacoesProvider = context.read<SolicitacoesProvider>();
        } catch (_) {}
        try {
          apartamentosProvider = context.read<ApartamentosProvider>();
        } catch (_) {}
        try {
          agendamentosProvider = context.read<AgendamentosProvider>();
        } catch (_) {}
        try {
          usuariosProvider = context.read<UsuariosProvider>();
        } catch (_) {}
        try {
          moradoresProvider = context.read<MoradoresProvider>();
        } catch (_) {}
        try {
          dashboardProvider = context.read<DashboardProvider>();
        } catch (_) {}
        try {
          manutencaoPreventivaProvider = context.read<ManutencaoPreventivaProvider>();
        } catch (_) {}
        try {
          notificacoesProvider = context.read<NotificacoesProvider>();
        } catch (_) {}
        AppLogger.info('AuthProvider', '🔄 Providers capturados antes do logout async');
      } else {
        AppLogger.warning('AuthProvider', '⚠️ Context é nulo - Não foi possível capturar providers');
      }

      // Desconectar SignalR antes de limpar token
      try {
        await notificacoesProvider?.desconectarSignalR();
        await SignalRService().desconectar();
      } catch (e) {
        AppLogger.error('AuthProvider', 'Erro ao desconectar SignalR: $e');
      }

      await _apiService.logout();
      AppLogger.info('AuthProvider', '✅ Token limpo da API');

      // 2. Clear all auth state
      _usuarioAtual = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _tempTelefone = null;
      _tempTelefoneMascarado = null;
      _tempNomeLogin = null;
      _tempUsuarioId = null;
      AppLogger.info('AuthProvider', '✅ Estado AuthProvider limpo');

      // 3. Reset captured providers (if any)
      if (solicitacoesProvider != null ||
          apartamentosProvider != null ||
          agendamentosProvider != null ||
          usuariosProvider != null ||
          moradoresProvider != null ||
          dashboardProvider != null ||
          manutencaoPreventivaProvider != null) {
        AppLogger.info('AuthProvider', '🔄 Resetando providers capturados...');
        try {
          solicitacoesProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ SolicitacoesProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'SolicitacoesProvider reset skipped: $e');
        }
        try {
          apartamentosProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ ApartamentosProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'ApartamentosProvider reset skipped: $e');
        }
        try {
          agendamentosProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ AgendamentosProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'AgendamentosProvider reset skipped: $e');
        }
        try {
          usuariosProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ UsuariosProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'UsuariosProvider reset skipped: $e');
        }
        try {
          moradoresProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ MoradoresProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'MoradoresProvider reset skipped: $e');
        }
        try {
          dashboardProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ DashboardProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'DashboardProvider reset skipped: $e');
        }
        try {
          manutencaoPreventivaProvider?.reset();
          AppLogger.debug('AuthProvider', '✅ ManutencaoPreventivaProvider resetado');
        } catch (e) {
          AppLogger.debug('AuthProvider', 'ManutencaoPreventivaProvider reset skipped: $e');
        }
        AppLogger.info('AuthProvider', '✅ Providers resetados (quando disponíveis)');
      } else {
        AppLogger.info('AuthProvider', 'ℹ️ Nenhum provider capturado para resetar');
      }
      
      notifyListeners();
      AppLogger.info('AuthProvider', '✅ LOGOUT COMPLETO - App pronta para novo login');
    } catch (e) {
      AppLogger.error('AuthProvider', 'Erro durante logout: $e');
      rethrow;
    } finally {
      _isLoggingOut = false;
    }
  }

  /// Format error messages to user-friendly Portuguese
  String _formatError(dynamic error) {
    final msg = error.toString();
    
    if (msg.contains('Connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    } else if (msg.contains('Sessão expirada')) {
      return 'Sessão expirada. Faça login novamente.';
    } else if (msg.contains('login') && msg.contains('inválido')) {
      return 'Usuário ou senha incorretos.';
    } else if (msg.contains('já existe')) {
      return 'Esse usuário já está cadastrado.';
    } else if (msg.contains('não encontrado')) {
      return 'Usuário não encontrado.';
    } else if (msg.contains('timeout')) {
      return 'Conexão perdida. Tente novamente.';
    }
    
    return msg;
  }

  /// Recarrega o perfil do usuário atual da API (e.g. após vincular apartamento em tempo real)
  Future<void> recarregarPerfil() async {
    try {
      _usuarioAtual = await _apiService.getPerfilAtual();
      notifyListeners();
      AppLogger.info('AuthProvider',
          '🔄 Perfil recarregado: apt=${_usuarioAtual?.moradorInfo?.apartamentoId ?? "null"}');
    } catch (e) {
      AppLogger.error('AuthProvider', 'Erro ao recarregar perfil: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Parse usuario tipo string to enum
  UsuarioTipo _parseUsuarioTipo(String tipo) {
    AppLogger.debug('AuthProvider', 'Parsing user type: "$tipo"');
    final parsed = UsuarioTipoExtension.fromString(tipo);
    AppLogger.debug('AuthProvider', 'Parsed as: ${parsed.toPortuguese()}');
    return parsed;
  }

  /// Update SMS notification preference
  /// Calls PUT /api/usuarios/me/toggle-sms
  Future<bool> updateSmsPreference(bool receberSms) async {
    if (_usuarioAtual == null) {
      _errorMessage = 'Usuário não autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.request<void>(
        'usuarios/me/toggle-sms',
        method: 'PUT',
        body: {'receberSms': receberSms},
        fromJson: (_) {},
      );
      
      // Update local user state
      _usuarioAtual = _usuarioAtual!.copyWith(receberSms: receberSms);
      _isLoading = false;
      notifyListeners();
      AppLogger.info('AuthProvider', '✅ SMS preference updated to: $receberSms');
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      AppLogger.error('AuthProvider', '❌ Failed to update SMS preference: $e');
      return false;
    }
  }
}






