import '../models/models.dart';
import '../models/enums.dart';
import '../services/api_service.dart';
import '../utils/app_date_time.dart';
import '../utils/app_logger.dart';
import 'base_provider.dart';

/// UsuariosProvider manages users/usuarios state
class UsuariosProvider extends BaseProvider {
  final ApiService _apiService = ApiService();

  List<Usuario> _usuarios = [];
  List<Usuario> _funcionarios = [];
  Usuario? _usuarioAtual;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Usuario> get usuarios => _usuarios;
  List<Usuario> get funcionarios => _funcionarios;
  Usuario? get usuarioAtual => _usuarioAtual;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  /// Parse role string to UsuarioTipo using the extension method that handles accents
  UsuarioTipo _parseUsuarioTipo(String role) {
    try {
      return UsuarioTipoExtension.fromString(role);
    } catch (e) {
      return UsuarioTipo.Morador;
    }
  }

  /// Load all users with optional type filter
  Future<void> carregarUsuarios({String? tipo}) async {
    await executeOperation(() async {
      AppLogger.info('Usuarios Provider', 'Carregando usuários (tipo: $tipo)');
      _usuarios = await _apiService.getUsuarios(tipo: tipo);
      AppLogger.debug('UsuariosProvider', 'Carregados ${_usuarios.length} usuários');
    });
  }

  /// Load a single user
  Future<void> carregarUsuario(String id) async {
    await executeOperation(() async {
      AppLogger.info('UsuariosProvider', 'Carregando usuário: $id');
      final dto = await _apiService.getUsuario(id);
      // Convert UsuarioDetalheDto to Usuario
      _usuarioAtual = Usuario(
        id: dto.id,
        nome: dto.nome,
        nomeLogin: dto.nomeLogin,
        telefone: dto.telefone,
        tipo: _parseUsuarioTipo(dto.role),
        ativo: dto.ativo,
        criadoEm: tryParseBackendDateTimeToLocal(dto.criadoEm) ?? DateTime.now(),
      );
      AppLogger.debug('UsuariosProvider', 'Usuário carregado: ${_usuarioAtual?.nome}');
    });
  }

  /// Load all funcionarios (staff)
  Future<void> carregarFuncionarios() async {
    await executeOperation(() async {
      AppLogger.info('UsuariosProvider', 'Carregando funcionários');
      _funcionarios = await _apiService.listarFuncionarios();
      AppLogger.debug('UsuariosProvider', 'Carregados ${_funcionarios.length} funcionários');
    });
  }

  /// Load funcionarios and return the list (for immediate use)
  Future<List<Usuario>> carregarFuncionariosComRetorno() async {
    try {
      AppLogger.info('UsuariosProvider', 'Carregando funcionários com retorno');
      _funcionarios = await _apiService.listarFuncionarios();
      AppLogger.debug('UsuariosProvider', 'Carregados ${_funcionarios.length} funcionários');
      return _funcionarios;
    } catch (e) {
      AppLogger.error('UsuariosProvider', 'Erro ao carregar funcionários: $e');
      return [];
    }
  }

  /// Load current user profile
  Future<Usuario?> carregarPerfilAtual() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usuario = await _apiService.getPerfilAtual();
      _usuarioAtual = usuario;
      _isLoading = false;
      notifyListeners();
      return usuario;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a user
  Future<void> atualizarUsuario(
    String id, {
    required String nome,
    required String telefone,
    required UsuarioTipo tipo,
    required bool ativo,
  }) async {
    try {
      await _apiService.atualizarUsuario(
        id, // primeiro parâmetro posicional
        nome: nome,
        telefone: telefone,
        ativo: ativo,
      );

      // Update local list
      final index = _usuarios.indexWhere((u) => u.id == id);
      if (index != -1) {
        _usuarios[index] = Usuario(
          id: _usuarios[index].id,
          nome: nome,
          nomeLogin: _usuarios[index].nomeLogin,
          telefone: telefone,
          tipo: tipo,
          ativo: ativo,
          criadoEm: _usuarios[index].criadoEm,
          ultimoLoginEm: _usuarios[index].ultimoLoginEm,
          moradorInfo: _usuarios[index].moradorInfo,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deletarUsuario(String id) async {
    try {
      await _apiService.deletarUsuario(id);

      // Remove from local list
      _usuarios.removeWhere((u) => u.id == id);

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Activate a user
  Future<void> ativarUsuario(String id) async {
    try {
      await _apiService.ativarUsuario(id);

      // Update local list
      final index = _usuarios.indexWhere((u) => u.id == id);
      if (index != -1) {
        _usuarios[index] = Usuario(
          id: _usuarios[index].id,
          nome: _usuarios[index].nome,
          nomeLogin: _usuarios[index].nomeLogin,
          telefone: _usuarios[index].telefone,
          tipo: _usuarios[index].tipo,
          ativo: true,
          criadoEm: _usuarios[index].criadoEm,
          ultimoLoginEm: _usuarios[index].ultimoLoginEm,
          moradorInfo: _usuarios[index].moradorInfo,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Deactivate a user
  Future<void> desativarUsuario(String id) async {
    try {
      await _apiService.desativarUsuario(id);

      // Update local list
      final index = _usuarios.indexWhere((u) => u.id == id);
      if (index != -1) {
        _usuarios[index] = Usuario(
          id: _usuarios[index].id,
          nome: _usuarios[index].nome,
          nomeLogin: _usuarios[index].nomeLogin,
          telefone: _usuarios[index].telefone,
          tipo: _usuarios[index].tipo,
          ativo: false,
          criadoEm: _usuarios[index].criadoEm,
          ultimoLoginEm: _usuarios[index].ultimoLoginEm,
          moradorInfo: _usuarios[index].moradorInfo,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// PUT /api/usuarios/{id}/reset-senha-admin
  /// Admin reseta senha de qualquer usuário diretamente
  /// Não permite resetar própria senha
  Future<bool> resetSenhaAdmin(
    String id, {
    required String novaSenha,
    required String confirmarNovaSenha,
    bool enviarSms = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resetSenhaAdmin(
        id,
        novaSenha: novaSenha,
        enviarSms: enviarSms,
      );
      AppLogger.info('UsuariosProvider', 'Senha resetada pelo admin para usuário: $id');
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

  String _formatError(dynamic error) {
    if (error is Exception) {
      final msg = error.toString().replaceAll('Exception: ', '');
      return msg;
    }
    return 'Erro ao processar usuários';
  }

  /// Reset all state (used on logout)
  @override
  void reset() {
    _usuarios = [];
    _funcionarios = [];
    _usuarioAtual = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
