/// =====================================================================
/// USUÁRIOS DTOs - Conformidade com Backend API
/// =====================================================================
library;

/// DTO para usuário em lista
class UsuarioListaDto {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String role;
  final bool ativo;
  final bool receberSms;
  final String criadoEm;

  UsuarioListaDto({
    required this.id,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.role,
    required this.ativo,
    this.receberSms = true,
    required this.criadoEm,
  });

  factory UsuarioListaDto.fromJson(Map<String, dynamic> json) {
    String role = 'Morador';
    final rawRole = json['role'];
    final rawTipo = json['tipo'];
    if (rawRole is String && rawRole.isNotEmpty) {
      role = rawRole;
    } else if (rawTipo is String && rawTipo.isNotEmpty) {
      role = rawTipo;
    } else if (rawTipo is int) {
      const map = ['Administrador', 'Funcionario', 'Sindico', 'Portaria', 'Morador', 'Visitante'];
      if (rawTipo >= 0 && rawTipo < map.length) role = map[rawTipo];
    }
    return UsuarioListaDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? '',
      role: role,
      ativo: json['ativo'] ?? true,
      receberSms: json['receberSms'] ?? true,
      criadoEm: json['criadoEm'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'nomeLogin': nomeLogin,
    'telefone': telefone,
    'role': role,
    'ativo': ativo,
    'receberSms': receberSms,
    'criadoEm': criadoEm,
  };
}

/// DTO para usuário detalhado
class UsuarioDetalheDto {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String role;
  final bool ativo;
  final bool receberSms;
  final String criadoEm;
  final String? atualizadoEm;

  UsuarioDetalheDto({
    required this.id,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.role,
    required this.ativo,
    this.receberSms = true,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory UsuarioDetalheDto.fromJson(Map<String, dynamic> json) {
    // Backend pode retornar 'role' (string), 'tipo' (string) ou 'tipo' (int 0-5)
    String role = 'Morador';
    final rawRole = json['role'];
    final rawTipo = json['tipo'];
    if (rawRole is String && rawRole.isNotEmpty) {
      role = rawRole;
    } else if (rawTipo is String && rawTipo.isNotEmpty) {
      role = rawTipo;
    } else if (rawTipo is int) {
      // 0=Admin, 1=Funcionario, 2=Sindico, 3=Portaria, 4=Morador, 5=Visitante
      const map = ['Administrador', 'Funcionario', 'Sindico', 'Portaria', 'Morador', 'Visitante'];
      if (rawTipo >= 0 && rawTipo < map.length) role = map[rawTipo];
    }
    return UsuarioDetalheDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? '',
      role: role,
      ativo: json['ativo'] ?? true,
      receberSms: json['receberSms'] ?? true,
      criadoEm: json['criadoEm'] ?? '',
      atualizadoEm: json['atualizadoEm'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'nomeLogin': nomeLogin,
    'telefone': telefone,
    'role': role,
    'ativo': ativo,
    'receberSms': receberSms,
    'criadoEm': criadoEm,
    'atualizadoEm': atualizadoEm,
  };
}

/// DTO para resposta paginada de usuários
class UsuariosPagedResponseDto {
  final List<UsuarioListaDto> items;
  final int total;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  UsuariosPagedResponseDto({
    required this.items,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory UsuariosPagedResponseDto.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return UsuariosPagedResponseDto(
      items: itemsList.map((item) => UsuarioListaDto.fromJson(item)).toList(),
      total: json['total'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      hasNextPage: json['hasNextPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'pageNumber': pageNumber,
    'pageSize': pageSize,
    'totalPages': totalPages,
    'hasPreviousPage': hasPreviousPage,
    'hasNextPage': hasNextPage,
  };
}

/// Request para criar/atualizar usuário
class CriarAtualizarUsuarioRequest {
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String? senha;
  final String role;

  CriarAtualizarUsuarioRequest({
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    this.senha,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'nomeLogin': nomeLogin,
    'telefone': telefone,
    if (senha != null) 'senha': senha,
    'role': role,
  };
}
