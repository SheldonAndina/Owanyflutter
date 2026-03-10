// ============================================================
// DTOs DE NÍVEIS DE ACESSO
// Request/Response DTOs para a API de Níveis de Acesso
// ============================================================

import '../utils/app_date_time.dart';

/// DTO para verificar permissão de um usuário
class VerificarPermissaoRequest {
  final String usuarioId;
  final String permissao;

  VerificarPermissaoRequest({
    required this.usuarioId,
    required this.permissao,
  });

  Map<String, dynamic> toJson() => {
        'usuarioId': usuarioId,
        'permissao': permissao,
      };
}

/// DTO para atualizar o role de um usuário
class AtualizarRoleRequest {
  final String novoRole;
  final String? motivo;

  AtualizarRoleRequest({
    required this.novoRole,
    this.motivo,
  });

  Map<String, dynamic> toJson() => {
        'NovoRol': novoRole,
        if (motivo != null) 'Motivo': motivo,
      };
}

/// Resposta de listagem de permissões
class ListaPermissoesResponse {
  final List<PermissaoResponse> permissoes;
  final int total;
  final Map<String, int> porCategoria;

  ListaPermissoesResponse({
    required this.permissoes,
    required this.total,
    required this.porCategoria,
  });

  factory ListaPermissoesResponse.fromJson(Map<String, dynamic> json) {
    return ListaPermissoesResponse(
      permissoes: (json['permissoes'] as List<dynamic>?)
              ?.map((e) => PermissaoResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      porCategoria: (json['porCategoria'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }
}

/// Resposta de uma permissão individual
class PermissaoResponse {
  final String codigo;
  final String nome;
  final String descricao;
  final String categoria;

  PermissaoResponse({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.categoria,
  });

  factory PermissaoResponse.fromJson(Map<String, dynamic> json) {
    return PermissaoResponse(
      codigo: json['codigo'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] ?? '',
    );
  }
}

/// Resposta de listagem de roles
class ListaRolesResponse {
  final List<RoleResponse> roles;
  final int total;

  ListaRolesResponse({
    required this.roles,
    required this.total,
  });

  factory ListaRolesResponse.fromJson(Map<String, dynamic> json) {
    return ListaRolesResponse(
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => RoleResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

/// Resposta de um role individual
class RoleResponse {
  final String role;
  final String descricao;
  final int nivelAcesso;
  final int totalPermissoes;

  RoleResponse({
    required this.role,
    required this.descricao,
    required this.nivelAcesso,
    required this.totalPermissoes,
  });

  factory RoleResponse.fromJson(Map<String, dynamic> json) {
    return RoleResponse(
      // Backend uses 'rol' (Portuguese) but we also check 'role' for compatibility
      role: json['rol'] ?? json['role'] ?? json['nome'] ?? '',
      descricao: json['descricao'] ?? json['description'] ?? '',
      nivelAcesso: json['nivelAcesso'] ?? json['nivel'] ?? 0,
      totalPermissoes: json['totalPermissoes'] ?? json['permissoes']?.length ?? 0,
    );
  }
}

/// Resposta do endpoint meu-acesso
class MeuAcessoResponse {
  final String usuarioId;
  final String nome;
  final String nomeLogin;
  final String role;
  final String roleDescricao;
  final List<String> permissoes;
  final int totalPermissoes;
  final DateTime consultadoEm;

  MeuAcessoResponse({
    required this.usuarioId,
    required this.nome,
    required this.nomeLogin,
    required this.role,
    required this.roleDescricao,
    required this.permissoes,
    required this.totalPermissoes,
    required this.consultadoEm,
  });

  factory MeuAcessoResponse.fromJson(Map<String, dynamic> json) {
    // Try multiple field names for permissions list
    List<String> permissoesList = [];
    final possiblePerms = json['permissoes'] ?? json['permissao'] ?? json['Permissoes'] ?? json['permissions'] ?? [];
    if (possiblePerms is List) {
      permissoesList = possiblePerms.map((e) => e.toString()).toList();
    }
    
    return MeuAcessoResponse(
      usuarioId: json['usuarioId'] ?? json['id'] ?? '',
      nome: json['nome'] ?? json['nomeCompleto'] ?? '',
      nomeLogin: json['nomeLogin'] ?? json['login'] ?? json['email'] ?? '',
      role: json['rol'] ?? json['role'] ?? json['tipo'] ?? '',
      roleDescricao: json['rolDescricao'] ?? json['roleDescricao'] ?? json['tipoDescricao'] ?? '',
      permissoes: permissoesList,
      totalPermissoes: json['totalPermissoes'] ?? json['quantidadePermissoes'] ?? permissoesList.length,
      consultadoEm: parseBackendDateTimeToLocal(json['consultadoEm']),
    );
  }
}

/// Resposta da verificação de permissão
class VerificarPermissaoResponse {
  final bool temPermissao;
  final String usuarioId;
  final String permissao;
  final String role;
  final String mensagem;

  VerificarPermissaoResponse({
    required this.temPermissao,
    required this.usuarioId,
    required this.permissao,
    required this.role,
    required this.mensagem,
  });

  factory VerificarPermissaoResponse.fromJson(Map<String, dynamic> json) {
    return VerificarPermissaoResponse(
      temPermissao: json['temPermissao'] ?? false,
      usuarioId: json['usuarioId'] ?? '',
      permissao: json['permissao'] ?? '',
      role: json['rol'] ?? json['role'] ?? '',
      mensagem: json['mensagem'] ?? '',
    );
  }
}

/// Resposta de listagem de usuários com roles
class ListaUsuariosRolesResponse {
  final List<UsuarioRoleResponse> usuarios;
  final int total;
  final int pagina;
  final int totalPaginas;

  ListaUsuariosRolesResponse({
    required this.usuarios,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
  });

  factory ListaUsuariosRolesResponse.fromJson(Map<String, dynamic> json) {
    return ListaUsuariosRolesResponse(
      usuarios: (json['usuarios'] as List<dynamic>?)
              ?.map((e) => UsuarioRoleResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      pagina: json['pagina'] ?? 1,
      totalPaginas: json['totalPaginas'] ?? 1,
    );
  }
}

/// Resposta de um usuário com role
class UsuarioRoleResponse {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String role;
  final String roleDescricao;
  final bool ativo;
  final DateTime? ultimoLoginEm;
  final int totalPermissoes;

  UsuarioRoleResponse({
    required this.id,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.role,
    required this.roleDescricao,
    required this.ativo,
    this.ultimoLoginEm,
    required this.totalPermissoes,
  });

  factory UsuarioRoleResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioRoleResponse(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? '',
      role: json['rol'] ?? json['role'] ?? json['tipo'] ?? '',
      roleDescricao: json['rolDescricao'] ?? json['roleDescricao'] ?? json['tipoDescricao'] ?? '',
      ativo: json['ativo'] ?? false,
      ultimoLoginEm: tryParseBackendDateTimeToLocal(json['ultimoLoginEm']),
      totalPermissoes: json['totalPermissoes'] ?? 0,
    );
  }
}

/// Resposta de atualização de role
class AtualizarRoleResponse {
  final bool sucesso;
  final String mensagem;
  final String usuarioId;
  final String roleAnterior;
  final String roleNovo;
  final DateTime atualizadoEm;

  AtualizarRoleResponse({
    required this.sucesso,
    required this.mensagem,
    required this.usuarioId,
    required this.roleAnterior,
    required this.roleNovo,
    required this.atualizadoEm,
  });

  factory AtualizarRoleResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns data directly without 'sucesso' field on success
    // Consider successful if we have a usuarioId
    final hasUsuario = (json['usuarioId'] ?? '').toString().isNotEmpty;
    return AtualizarRoleResponse(
      sucesso: json['sucesso'] ?? hasUsuario,
      mensagem: json['mensagem'] ?? (hasUsuario ? 'Role atualizado com sucesso' : ''),
      usuarioId: json['usuarioId'] ?? '',
      roleAnterior: json['rolAnterior'] ?? json['roleAnterior'] ?? '',
      roleNovo: json['rolNovo'] ?? json['roleNovo'] ?? '',
      atualizadoEm: parseBackendDateTimeToLocal(json['atualizadoEm']),
    );
  }
}

/// Resposta de permissões de um role específico
class RolePermissoesResponse {
  final String role;
  final String descricao;
  final int nivelAcesso;
  final List<String> permissoes;
  final int totalPermissoes;
  final Map<String, List<String>> permissoesPorCategoria;

  RolePermissoesResponse({
    required this.role,
    required this.descricao,
    required this.nivelAcesso,
    required this.permissoes,
    required this.totalPermissoes,
    required this.permissoesPorCategoria,
  });

  factory RolePermissoesResponse.fromJson(Map<String, dynamic> json) {
    // Parse permissions list - API returns objects with codigo, descricao, grupo
    final permissoesList = <String>[];
    final Map<String, List<String>> porCategoria = {};
    
    if (json['permissoes'] != null && json['permissoes'] is List) {
      for (final item in json['permissoes'] as List) {
        if (item is Map<String, dynamic>) {
          final codigo = item['codigo']?.toString() ?? '';
          final grupo = item['grupo']?.toString() ?? 'Outros';
          
          if (codigo.isNotEmpty) {
            permissoesList.add(codigo);
            porCategoria.putIfAbsent(grupo, () => []).add(codigo);
          }
        } else if (item is String) {
          permissoesList.add(item);
          porCategoria.putIfAbsent('Outros', () => []).add(item);
        }
      }
    }
    
    // Also try permissoesPorCategoria if provided directly
    if (json['permissoesPorCategoria'] != null) {
      final map = json['permissoesPorCategoria'] as Map<String, dynamic>;
      map.forEach((key, value) {
        if (value is List) {
          porCategoria[key] = value.map((e) => e.toString()).toList();
        }
      });
    }

    return RolePermissoesResponse(
      role: json['rol'] ?? json['role'] ?? '',
      descricao: json['descricao'] ?? '',
      nivelAcesso: json['nivelAcesso'] ?? 0,
      permissoes: permissoesList,
      totalPermissoes: json['totalPermissoes'] ?? permissoesList.length,
      permissoesPorCategoria: porCategoria,
    );
  }
}
