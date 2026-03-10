import 'package:flutter/material.dart';
import '../dto/niveis_acesso_dtos.dart';
import '../models/niveis_acesso.dart';
import '../models/enums.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

/// Provider para gerenciamento de Níveis de Acesso
/// Gerencia permissões, roles e controle de acesso no app
class NiveisAcessoProvider extends ChangeNotifier with BaseProviderMixin {
  final ApiService _apiService = ApiService();

  // Estado
  MeuAcesso? _meuAcesso;
  List<RoleResponse> _roles = [];
  List<PermissaoResponse> _permissoes = [];
  List<UsuarioRoleResponse> _usuarios = [];
  RolePermissoesResponse? _rolePermissoesSelecionado;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingRoles = false;
  bool _isLoadingPermissoes = false;
  bool _isLoadingUsuarios = false;

  // Error state
  String? _errorMessage;

  // Paginação
  int _paginaAtual = 1;
  int _totalPaginas = 1;
  int _totalUsuarios = 0;

  // Getters
  MeuAcesso? get meuAcesso => _meuAcesso;
  List<RoleResponse> get roles => _roles;
  List<PermissaoResponse> get permissoes => _permissoes;
  List<UsuarioRoleResponse> get usuarios => _usuarios;
  RolePermissoesResponse? get rolePermissoesSelecionado => _rolePermissoesSelecionado;

  bool get isLoading => _isLoading;
  bool get isLoadingRoles => _isLoadingRoles;
  bool get isLoadingPermissoes => _isLoadingPermissoes;
  bool get isLoadingUsuarios => _isLoadingUsuarios;
  String? get errorMessage => _errorMessage;

  int get paginaAtual => _paginaAtual;
  int get totalPaginas => _totalPaginas;
  int get totalUsuarios => _totalUsuarios;

  /// Verifica se o usuário atual tem uma permissão específica
  bool temPermissao(String permissao) {
    return _meuAcesso?.temPermissao(permissao) ?? false;
  }

  /// Verifica se o usuário atual tem todas as permissões listadas
  bool temTodasPermissoes(List<String> permissoes) {
    return _meuAcesso?.temTodasPermissoes(permissoes) ?? false;
  }

  /// Verifica se o usuário atual tem pelo menos uma das permissões listadas
  bool temAlgumaPermissao(List<String> permissoes) {
    return _meuAcesso?.temAlgumaPermissao(permissoes) ?? false;
  }

  /// Verifica permissão baseado no role local (fallback)
  bool temPermissaoLocal(String permissao, UsuarioTipo role) {
    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(role);
    return permissoesDoRole.contains(permissao);
  }

  /// Carrega as permissões do usuário atual
  Future<void> carregarMeuAcesso() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.request<MeuAcessoResponse>(
        'niveisacesso/meu-acesso',
        method: 'GET',
        fromJson: (json) {
          log('Raw meu-acesso response keys: ${json.keys.toList()}');
          log('Raw meu-acesso response: $json');
          return MeuAcessoResponse.fromJson(json);
        },
      );

      _meuAcesso = MeuAcesso(
        usuarioId: response.usuarioId,
        nome: response.nome,
        nomeLogin: response.nomeLogin,
        role: response.role,
        roleDescricao: response.roleDescricao,
        permissoes: response.permissoes,
        totalPermissoes: response.totalPermissoes,
        consultadoEm: response.consultadoEm,
      );

      log('Acesso carregado: role=${_meuAcesso!.role}, permissões=${_meuAcesso!.totalPermissoes}, lista=${_meuAcesso!.permissoes}');
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao carregar meu acesso', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega todos os roles disponíveis
  Future<void> carregarRoles() async {
    _isLoadingRoles = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.request<List<RoleResponse>>(
        'niveisacesso/rols',
        method: 'GET',
        fromJson: (json) {
          // Handle both list and wrapped response
          if (json is List) {
            return json.map((e) => RoleResponse.fromJson(e as Map<String, dynamic>)).toList();
          }
          if (json is Map<String, dynamic>) {
            final roles = json['roles'] ?? json['items'] ?? json['data'] ?? [];
            if (roles is List) {
              return roles.map((e) => RoleResponse.fromJson(e as Map<String, dynamic>)).toList();
            }
          }
          return <RoleResponse>[];
        },
      );

      _roles = response;
      log('Roles carregados: ${_roles.length}');
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao carregar roles', e);
    } finally {
      _isLoadingRoles = false;
      notifyListeners();
    }
  }

  /// Carrega todas as permissões disponíveis
  Future<void> carregarPermissoes() async {
    _isLoadingPermissoes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.request<List<PermissaoResponse>>(
        'niveisacesso/permissoes',
        method: 'GET',
        fromJson: (json) {
          // Handle both list and wrapped response
          if (json is List) {
            return json.map((e) => PermissaoResponse.fromJson(e as Map<String, dynamic>)).toList();
          }
          if (json is Map<String, dynamic>) {
            final permissoes = json['permissoes'] ?? json['items'] ?? json['data'] ?? [];
            if (permissoes is List) {
              return permissoes.map((e) => PermissaoResponse.fromJson(e as Map<String, dynamic>)).toList();
            }
          }
          return <PermissaoResponse>[];
        },
      );

      _permissoes = response;
      log('Permissões carregadas: ${_permissoes.length}');
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao carregar permissões', e);
    } finally {
      _isLoadingPermissoes = false;
      notifyListeners();
    }
  }

  /// Carrega as permissões de um role específico
  Future<void> carregarPermissoesDoRole(String role) async {
    _isLoading = true;
    _errorMessage = null;
    _rolePermissoesSelecionado = null;
    notifyListeners();

    try {
      final response = await _apiService.request<RolePermissoesResponse>(
        'niveisacesso/rols/$role/permissoes',
        method: 'GET',
        fromJson: (json) => RolePermissoesResponse.fromJson(json),
      );

      _rolePermissoesSelecionado = response;
      log('Permissões do role $role carregadas: ${response.totalPermissoes}');
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao carregar permissões do role', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega a lista de usuários com seus roles
  Future<void> carregarUsuarios({int pagina = 1, int tamanhoPagina = 20}) async {
    _isLoadingUsuarios = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.request<List<UsuarioRoleResponse>>(
        'niveisacesso/usuarios?pagina=$pagina&tamanhoPagina=$tamanhoPagina',
        method: 'GET',
        fromJson: (json) {
          // Handle both list and paginated response
          if (json is List) {
            return json.map((e) => UsuarioRoleResponse.fromJson(e as Map<String, dynamic>)).toList();
          }
          if (json is Map<String, dynamic>) {
            final usuarios = json['usuarios'] ?? json['items'] ?? json['data'] ?? [];
            if (usuarios is List) {
              return usuarios.map((e) => UsuarioRoleResponse.fromJson(e as Map<String, dynamic>)).toList();
            }
          }
          return <UsuarioRoleResponse>[];
        },
      );

      _usuarios = response;
      _paginaAtual = pagina;
      _totalPaginas = 1;
      _totalUsuarios = response.length;

      log('Usuários carregados: ${_usuarios.length}');
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao carregar usuários', e);
    } finally {
      _isLoadingUsuarios = false;
      notifyListeners();
    }
  }

  /// Verifica se um usuário específico tem uma permissão
  Future<VerificarPermissaoResponse?> verificarPermissaoUsuario({
    required String usuarioId,
    required String permissao,
  }) async {
    try {
      final response = await _apiService.request<VerificarPermissaoResponse>(
        'niveisacesso/verificar-permissao',
        method: 'POST',
        body: VerificarPermissaoRequest(
          usuarioId: usuarioId,
          permissao: permissao,
        ).toJson(),
        fromJson: (json) => VerificarPermissaoResponse.fromJson(json),
      );

      log('Verificação: usuário $usuarioId ${response.temPermissao ? "tem" : "não tem"} $permissao');
      return response;
    } catch (e) {
      logError('Erro ao verificar permissão', e);
      return null;
    }
  }

  /// Atualiza o role de um usuário (somente admin)
  Future<bool> atualizarRoleUsuario({
    required String usuarioId,
    required String novoRole,
    String? motivo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.request<AtualizarRoleResponse>(
        'niveisacesso/usuarios/$usuarioId/rol',
        method: 'PUT',
        body: AtualizarRoleRequest(
          novoRole: novoRole,
          motivo: motivo,
        ).toJson(),
        fromJson: (json) {
          log('Raw atualizar-role response: $json');
          return AtualizarRoleResponse.fromJson(json);
        },
      );

      log('Role update result: sucesso=${response.sucesso}, anterior=${response.roleAnterior}, novo=${response.roleNovo}');
      
      if (response.sucesso) {
        // Atualiza o usuário na lista local
        final index = _usuarios.indexWhere((u) => u.id == usuarioId);
        if (index != -1) {
          await carregarUsuarios(pagina: _paginaAtual);
        }
        log('Role atualizado: ${response.roleAnterior} → ${response.roleNovo}');
      }

      return response.sucesso;
    } catch (e) {
      _errorMessage = formatErrorMessage(e);
      logError('Erro ao atualizar role', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtém detalhes de um usuário específico
  Future<UsuarioRoleResponse?> obterDetalhesUsuario(String usuarioId) async {
    try {
      final response = await _apiService.request<UsuarioRoleResponse>(
        'niveisacesso/usuarios/$usuarioId',
        method: 'GET',
        fromJson: (json) => UsuarioRoleResponse.fromJson(json),
      );

      return response;
    } catch (e) {
      logError('Erro ao obter detalhes do usuário', e);
      return null;
    }
  }

  /// Carrega próxima página de usuários
  Future<void> carregarProximaPagina() async {
    if (_paginaAtual < _totalPaginas) {
      await carregarUsuarios(pagina: _paginaAtual + 1);
    }
  }

  /// Carrega página anterior de usuários
  Future<void> carregarPaginaAnterior() async {
    if (_paginaAtual > 1) {
      await carregarUsuarios(pagina: _paginaAtual - 1);
    }
  }

  /// Limpa os dados de acesso (usar no logout)
  void limparDados() {
    _meuAcesso = null;
    _roles = [];
    _permissoes = [];
    _usuarios = [];
    _rolePermissoesSelecionado = null;
    _errorMessage = null;
    _paginaAtual = 1;
    _totalPaginas = 1;
    _totalUsuarios = 0;
    notifyListeners();
  }

  /// Retorna o ícone apropriado para o role
  IconData getIconeRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'sindico':
      case 'síndico':
        return Icons.business;
      case 'funcionario':
      case 'funcionário':
        return Icons.engineering;
      case 'portaria':
        return Icons.door_front_door;
      case 'morador':
        return Icons.person;
      case 'visitante':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  /// Retorna a cor apropriada para o role
  Color getCorRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'administrador':
        return const Color(0xFFDC2626); // Red
      case 'sindico':
      case 'síndico':
        return const Color(0xFF7C3AED); // Purple
      case 'funcionario':
      case 'funcionário':
        return const Color(0xFF2563EB); // Blue
      case 'portaria':
        return const Color(0xFF059669); // Green
      case 'morador':
        return const Color(0xFFD97706); // Amber
      case 'visitante':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// Agrupa permissões por categoria
  Map<String, List<String>> agruparPermissoesPorCategoria(List<String> permissoes) {
    final grupos = <String, List<String>>{};
    
    for (final permissao in permissoes) {
      final partes = permissao.split('.');
      final categoria = partes.isNotEmpty ? _capitalizarCategoria(partes[0]) : 'Outros';
      
      if (!grupos.containsKey(categoria)) {
        grupos[categoria] = [];
      }
      grupos[categoria]!.add(permissao);
    }
    
    return grupos;
  }

  String _capitalizarCategoria(String categoria) {
    final mapeamento = {
      'usuarios': 'Usuários',
      'apartamentos': 'Apartamentos',
      'solicitacoes': 'Solicitações',
      'manutencoes': 'Manutenções',
      'agendamentos': 'Agendamentos',
      'itens': 'Itens',
      'notificacoes': 'Notificações',
      'auditoria': 'Auditoria',
      'dashboard': 'Dashboard',
      'relatorios': 'Relatórios',
      'sistema': 'Sistema',
    };
    return mapeamento[categoria.toLowerCase()] ?? categoria;
  }
}
