// ============================================================
// SISTEMA DE NÍVEIS DE ACESSO - MODELOS
// Permissões e Roles para controle de acesso no app
// ============================================================

import 'enums.dart';
import '../utils/app_date_time.dart';

/// Classe estática com todas as permissões disponíveis no sistema
/// Espelha as permissões do backend C#
class Permissoes {
  // Usuários (8 permissões)
  static const String usuariosView = 'usuarios.view';
  static const String usuariosCreate = 'usuarios.create';
  static const String usuariosEdit = 'usuarios.edit';
  static const String usuariosDelete = 'usuarios.delete';
  static const String usuariosActivate = 'usuarios.activate';
  static const String usuariosDeactivate = 'usuarios.deactivate';
  static const String usuariosChangeRole = 'usuarios.changerole';
  static const String usuariosViewAll = 'usuarios.viewall';

  // Apartamentos (6 permissões)
  static const String apartamentosView = 'apartamentos.view';
  static const String apartamentosCreate = 'apartamentos.create';
  static const String apartamentosEdit = 'apartamentos.edit';
  static const String apartamentosDelete = 'apartamentos.delete';
  static const String apartamentosViewAll = 'apartamentos.viewall';
  static const String apartamentosManageResidents = 'apartamentos.manageresidents';

  // Solicitações (8 permissões)
  static const String solicitacoesView = 'solicitacoes.view';
  static const String solicitacoesCreate = 'solicitacoes.create';
  static const String solicitacoesEdit = 'solicitacoes.edit';
  static const String solicitacoesDelete = 'solicitacoes.delete';
  static const String solicitacoesViewAll = 'solicitacoes.viewall';
  static const String solicitacoesAssign = 'solicitacoes.assign';
  static const String solicitacoesChangeStatus = 'solicitacoes.changestatus';
  static const String solicitacoesApprove = 'solicitacoes.approve';

  // Manutenções Preventivas (6 permissões)
  static const String manutencoesView = 'manutencoes.view';
  static const String manutencoesCreate = 'manutencoes.create';
  static const String manutencoesEdit = 'manutencoes.edit';
  static const String manutencoesDelete = 'manutencoes.delete';
  static const String manutencoesViewAll = 'manutencoes.viewall';
  static const String manutencoesExecute = 'manutencoes.execute';

  // Agendamentos (7 permissões)
  static const String agendamentosView = 'agendamentos.view';
  static const String agendamentosCreate = 'agendamentos.create';
  static const String agendamentosEdit = 'agendamentos.edit';
  static const String agendamentosDelete = 'agendamentos.delete';
  static const String agendamentosViewAll = 'agendamentos.viewall';
  static const String agendamentosApprove = 'agendamentos.approve';
  static const String agendamentosReject = 'agendamentos.reject';

  // Itens Apartamento (7 permissões)
  static const String itensView = 'itens.view';
  static const String itensCreate = 'itens.create';
  static const String itensEdit = 'itens.edit';
  static const String itensDelete = 'itens.delete';
  static const String itensViewAll = 'itens.viewall';
  static const String itensTransfer = 'itens.transfer';
  static const String itensGenerateQr = 'itens.generateqr';

  // Notificações (3 permissões)
  static const String notificacoesView = 'notificacoes.view';
  static const String notificacoesSend = 'notificacoes.send';
  static const String notificacoesSendMass = 'notificacoes.sendmass';

  // Auditoria (2 permissões)
  static const String auditoriaView = 'auditoria.view';
  static const String auditoriaExport = 'auditoria.export';

  // Dashboard e Relatórios (3 permissões)
  static const String dashboardView = 'dashboard.view';
  static const String dashboardViewFull = 'dashboard.viewfull';
  static const String relatoriosExport = 'relatorios.export';

  // Sistema (3 permissões)
  static const String sistemaConfig = 'sistema.config';
  static const String sistemaBackup = 'sistema.backup';
  static const String sistemaLogs = 'sistema.logs';

  /// Lista de todas as permissões
  static List<String> getAll() => [
        // Usuários
        usuariosView, usuariosCreate, usuariosEdit, usuariosDelete,
        usuariosActivate, usuariosDeactivate, usuariosChangeRole, usuariosViewAll,
        // Apartamentos
        apartamentosView, apartamentosCreate, apartamentosEdit, apartamentosDelete,
        apartamentosViewAll, apartamentosManageResidents,
        // Solicitações
        solicitacoesView, solicitacoesCreate, solicitacoesEdit, solicitacoesDelete,
        solicitacoesViewAll, solicitacoesAssign, solicitacoesChangeStatus, solicitacoesApprove,
        // Manutenções
        manutencoesView, manutencoesCreate, manutencoesEdit, manutencoesDelete,
        manutencoesViewAll, manutencoesExecute,
        // Agendamentos
        agendamentosView, agendamentosCreate, agendamentosEdit, agendamentosDelete,
        agendamentosViewAll, agendamentosApprove, agendamentosReject,
        // Itens
        itensView, itensCreate, itensEdit, itensDelete,
        itensViewAll, itensTransfer, itensGenerateQr,
        // Notificações
        notificacoesView, notificacoesSend, notificacoesSendMass,
        // Auditoria
        auditoriaView, auditoriaExport,
        // Dashboard
        dashboardView, dashboardViewFull, relatoriosExport,
        // Sistema
        sistemaConfig, sistemaBackup, sistemaLogs,
      ];

  /// Agrupa permissões por categoria
  static Map<String, List<String>> getByCategory() => {
        'Usuários': [usuariosView, usuariosCreate, usuariosEdit, usuariosDelete,
                     usuariosActivate, usuariosDeactivate, usuariosChangeRole, usuariosViewAll],
        'Apartamentos': [apartamentosView, apartamentosCreate, apartamentosEdit, apartamentosDelete,
                         apartamentosViewAll, apartamentosManageResidents],
        'Solicitações': [solicitacoesView, solicitacoesCreate, solicitacoesEdit, solicitacoesDelete,
                         solicitacoesViewAll, solicitacoesAssign, solicitacoesChangeStatus, solicitacoesApprove],
        'Manutenções': [manutencoesView, manutencoesCreate, manutencoesEdit, manutencoesDelete,
                        manutencoesViewAll, manutencoesExecute],
        'Agendamentos': [agendamentosView, agendamentosCreate, agendamentosEdit, agendamentosDelete,
                         agendamentosViewAll, agendamentosApprove, agendamentosReject],
        'Itens': [itensView, itensCreate, itensEdit, itensDelete,
                  itensViewAll, itensTransfer, itensGenerateQr],
        'Notificações': [notificacoesView, notificacoesSend, notificacoesSendMass],
        'Auditoria': [auditoriaView, auditoriaExport],
        'Dashboard': [dashboardView, dashboardViewFull, relatoriosExport],
        'Sistema': [sistemaConfig, sistemaBackup, sistemaLogs],
      };

  /// Retorna descrição amigável da permissão
  static String getDescricao(String permissao) {
    final descricoes = {
      // Usuários
      usuariosView: 'Visualizar usuários',
      usuariosCreate: 'Criar usuários',
      usuariosEdit: 'Editar usuários',
      usuariosDelete: 'Excluir usuários',
      usuariosActivate: 'Ativar usuários',
      usuariosDeactivate: 'Desativar usuários',
      usuariosChangeRole: 'Alterar role de usuários',
      usuariosViewAll: 'Visualizar todos os usuários',
      // Apartamentos
      apartamentosView: 'Visualizar apartamentos',
      apartamentosCreate: 'Criar apartamentos',
      apartamentosEdit: 'Editar apartamentos',
      apartamentosDelete: 'Excluir apartamentos',
      apartamentosViewAll: 'Visualizar todos os apartamentos',
      apartamentosManageResidents: 'Gerenciar moradores',
      // Solicitações
      solicitacoesView: 'Visualizar solicitações',
      solicitacoesCreate: 'Criar solicitações',
      solicitacoesEdit: 'Editar solicitações',
      solicitacoesDelete: 'Excluir solicitações',
      solicitacoesViewAll: 'Visualizar todas as solicitações',
      solicitacoesAssign: 'Atribuir responsável',
      solicitacoesChangeStatus: 'Alterar status',
      solicitacoesApprove: 'Aprovar solicitações',
      // Manutenções
      manutencoesView: 'Visualizar manutenções',
      manutencoesCreate: 'Criar manutenções',
      manutencoesEdit: 'Editar manutenções',
      manutencoesDelete: 'Excluir manutenções',
      manutencoesViewAll: 'Visualizar todas as manutenções',
      manutencoesExecute: 'Executar manutenções',
      // Agendamentos
      agendamentosView: 'Visualizar agendamentos',
      agendamentosCreate: 'Criar agendamentos',
      agendamentosEdit: 'Editar agendamentos',
      agendamentosDelete: 'Excluir agendamentos',
      agendamentosViewAll: 'Visualizar todos os agendamentos',
      agendamentosApprove: 'Aprovar agendamentos',
      agendamentosReject: 'Rejeitar agendamentos',
      // Itens
      itensView: 'Visualizar itens',
      itensCreate: 'Criar itens',
      itensEdit: 'Editar itens',
      itensDelete: 'Excluir itens',
      itensViewAll: 'Visualizar todos os itens',
      itensTransfer: 'Transferir itens',
      itensGenerateQr: 'Gerar QR Code',
      // Notificações
      notificacoesView: 'Visualizar notificações',
      notificacoesSend: 'Enviar notificações',
      notificacoesSendMass: 'Enviar em massa',
      // Auditoria
      auditoriaView: 'Visualizar auditoria',
      auditoriaExport: 'Exportar auditoria',
      // Dashboard
      dashboardView: 'Visualizar dashboard',
      dashboardViewFull: 'Dashboard completo',
      relatoriosExport: 'Exportar relatórios',
      // Sistema
      sistemaConfig: 'Configurar sistema',
      sistemaBackup: 'Backup do sistema',
      sistemaLogs: 'Visualizar logs',
    };
    return descricoes[permissao] ?? permissao;
  }
}

/// Classe helper para mapear roles localmente
/// Útil para verificações offline ou cache
class RolePermissoes {
  /// Retorna todas as permissões para o role do usuário
  static List<String> getPermissoesParaRole(UsuarioTipo role) {
    switch (role) {
      case UsuarioTipo.Administrador:
        return Permissoes.getAll(); // Admin tem todas
      case UsuarioTipo.Sindico:
        return _permissoesSindico;
      case UsuarioTipo.Funcionario:
        return _permissoesFuncionario;
      case UsuarioTipo.Portaria:
        return _permissoesPortaria;
      case UsuarioTipo.Morador:
        return _permissoesMorador;
      case UsuarioTipo.Visitante:
        return _permissoesVisitante;
    }
  }

  static final List<String> _permissoesSindico = [
    // Usuários — Síndico pode criar usuários, visualizar e listar todos
    Permissoes.usuariosView, Permissoes.usuariosCreate, Permissoes.usuariosViewAll,
    // Apartamentos — CRUD (criar, editar, visualizar, gerenciar moradores). NÃO deletar
    Permissoes.apartamentosView, Permissoes.apartamentosCreate, Permissoes.apartamentosEdit,
    Permissoes.apartamentosViewAll, Permissoes.apartamentosManageResidents,
    // Solicitações — criar, editar, visualizar todas. NÃO deletar, NÃO assign, NÃO changeStatus
    Permissoes.solicitacoesView, Permissoes.solicitacoesCreate, Permissoes.solicitacoesEdit,
    Permissoes.solicitacoesViewAll, Permissoes.solicitacoesApprove,
    // Manutenções — CRUD + executar
    Permissoes.manutencoesView, Permissoes.manutencoesCreate, Permissoes.manutencoesEdit,
    Permissoes.manutencoesDelete, Permissoes.manutencoesViewAll, Permissoes.manutencoesExecute,
    // Agendamentos — criar, editar, visualizar. NÃO deletar
    Permissoes.agendamentosView, Permissoes.agendamentosCreate, Permissoes.agendamentosEdit,
    Permissoes.agendamentosViewAll,
    // Itens — CRUD (deletar incluído por guia)
    Permissoes.itensView, Permissoes.itensCreate, Permissoes.itensEdit,
    Permissoes.itensDelete, Permissoes.itensViewAll, Permissoes.itensTransfer, Permissoes.itensGenerateQr,
    // Notificações — enviar inclusive em massa
    Permissoes.notificacoesView, Permissoes.notificacoesSend, Permissoes.notificacoesSendMass,
    // Dashboard — completo + relatórios
    Permissoes.dashboardView, Permissoes.dashboardViewFull, Permissoes.relatoriosExport,
    // Auditoria
    Permissoes.auditoriaView, Permissoes.auditoriaExport,
  ];

  static final List<String> _permissoesFuncionario = [
    // Usuários — visualizar (listagem). NÃO criar/editar/deletar
    Permissoes.usuariosView, Permissoes.usuariosViewAll,
    // Apartamentos — somente leitura. NÃO criar/editar/deletar
    Permissoes.apartamentosView, Permissoes.apartamentosViewAll,
    // Solicitações — foco principal: criar, editar, visualizar, atribuir, mudar status. NÃO deletar, NÃO aprovar
    Permissoes.solicitacoesView, Permissoes.solicitacoesCreate, Permissoes.solicitacoesEdit,
    Permissoes.solicitacoesViewAll, Permissoes.solicitacoesAssign,
    Permissoes.solicitacoesChangeStatus,
    // Manutenções — criar, editar, executar. NÃO deletar
    Permissoes.manutencoesView, Permissoes.manutencoesCreate, Permissoes.manutencoesEdit,
    Permissoes.manutencoesViewAll, Permissoes.manutencoesExecute,
    // Agendamentos — somente leitura. NÃO criar/editar/deletar
    Permissoes.agendamentosView, Permissoes.agendamentosViewAll,
    // Itens — somente leitura. NÃO criar/editar/transferir/QR
    Permissoes.itensView, Permissoes.itensViewAll,
    // Notificações — visualizar e enviar
    Permissoes.notificacoesView, Permissoes.notificacoesSend,
    // Dashboard — básico (sem ViewFull e sem relatórios gerais)
    Permissoes.dashboardView,
  ];

  static final List<String> _permissoesPortaria = [
    // Usuários — visualizar contatos de moradores
    Permissoes.usuariosView,
    // Apartamentos — visualizar (contatos/moradores)
    Permissoes.apartamentosView, Permissoes.apartamentosViewAll,
    // Notificações — somente visualizar (sem enviar)
    Permissoes.notificacoesView,
    // Dashboard — básico
    Permissoes.dashboardView,
  ];

  static final List<String> _permissoesMorador = [
    // Apartamentos (apenas seu)
    Permissoes.apartamentosView,
    // Solicitações — criar e visualizar as suas. NÃO editar, NÃO criar agendamentos
    Permissoes.solicitacoesView, Permissoes.solicitacoesCreate,
    // Agendamentos — visualizar e responder/avaliar (aceitar/recusar). NÃO criar
    Permissoes.agendamentosView,
    Permissoes.agendamentosApprove, Permissoes.agendamentosReject,
    // Itens — somente visualizar (sem editar)
    Permissoes.itensView,
    // Notificações (apenas suas)
    Permissoes.notificacoesView,
    // Dashboard básico
    Permissoes.dashboardView,
  ];

  static final List<String> _permissoesVisitante = [
    Permissoes.dashboardView,
  ];
}

/// Modelo para representar informações de acesso do usuário atual
class MeuAcesso {
  final String usuarioId;
  final String nome;
  final String nomeLogin;
  final String role;
  final String roleDescricao;
  final List<String> permissoes;
  final int totalPermissoes;
  final DateTime consultadoEm;

  MeuAcesso({
    required this.usuarioId,
    required this.nome,
    required this.nomeLogin,
    required this.role,
    required this.roleDescricao,
    required this.permissoes,
    required this.totalPermissoes,
    required this.consultadoEm,
  });

  factory MeuAcesso.fromJson(Map<String, dynamic> json) {
    return MeuAcesso(
      usuarioId: json['usuarioId'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      role: json['role'] ?? '',
      roleDescricao: json['roleDescricao'] ?? '',
      permissoes: (json['permissoes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalPermissoes: json['totalPermissoes'] ?? 0,
      consultadoEm: json['consultadoEm'] != null
          ? parseBackendDateTimeToLocal(json['consultadoEm'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'usuarioId': usuarioId,
        'nome': nome,
        'nomeLogin': nomeLogin,
        'role': role,
        'roleDescricao': roleDescricao,
        'permissoes': permissoes,
        'totalPermissoes': totalPermissoes,
        'consultadoEm': toBackendUtcIsoString(consultadoEm),
      };

  /// Verifica se possui uma permissão específica
  bool temPermissao(String permissao) => permissoes.contains(permissao);

  /// Verifica se possui todas as permissões listadas
  bool temTodasPermissoes(List<String> lista) =>
      lista.every((p) => permissoes.contains(p));

  /// Verifica se possui pelo menos uma das permissões listadas
  bool temAlgumaPermissao(List<String> lista) =>
      lista.any((p) => permissoes.contains(p));
}

/// Modelo para informações de permissão
class PermissaoInfo {
  final String codigo;
  final String nome;
  final String descricao;
  final String categoria;

  PermissaoInfo({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.categoria,
  });

  factory PermissaoInfo.fromJson(Map<String, dynamic> json) {
    return PermissaoInfo(
      codigo: json['codigo'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nome': nome,
        'descricao': descricao,
        'categoria': categoria,
      };
}

/// Modelo para role com suas permissões
class RolComPermissoes {
  final String role;
  final String descricao;
  final int nivelAcesso;
  final List<String> permissoes;
  final int totalPermissoes;

  RolComPermissoes({
    required this.role,
    required this.descricao,
    required this.nivelAcesso,
    required this.permissoes,
    required this.totalPermissoes,
  });

  factory RolComPermissoes.fromJson(Map<String, dynamic> json) {
    return RolComPermissoes(
      role: json['role'] ?? '',
      descricao: json['descricao'] ?? '',
      nivelAcesso: json['nivelAcesso'] ?? 0,
      permissoes: (json['permissoes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalPermissoes: json['totalPermissoes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'descricao': descricao,
        'nivelAcesso': nivelAcesso,
        'permissoes': permissoes,
        'totalPermissoes': totalPermissoes,
      };
}

/// Modelo para usuário com informações de role
class UsuarioComRole {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String role;
  final String roleDescricao;
  final bool ativo;
  final DateTime? ultimoLoginEm;
  final int totalPermissoes;

  UsuarioComRole({
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

  factory UsuarioComRole.fromJson(Map<String, dynamic> json) {
    return UsuarioComRole(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? '',
      role: json['role'] ?? '',
      roleDescricao: json['roleDescricao'] ?? '',
      ativo: json['ativo'] ?? false,
      ultimoLoginEm: json['ultimoLoginEm'] != null
          ? parseBackendDateTimeToLocal(json['ultimoLoginEm'])
          : null,
      totalPermissoes: json['totalPermissoes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'nomeLogin': nomeLogin,
        'telefone': telefone,
        'role': role,
        'roleDescricao': roleDescricao,
        'ativo': ativo,
        'ultimoLoginEm': ultimoLoginEm != null ? toBackendUtcIsoString(ultimoLoginEm!) : null,
        'totalPermissoes': totalPermissoes,
      };
}

/// Resultado da verificação de permissão
class ResultadoVerificacao {
  final bool temPermissao;
  final String usuarioId;
  final String permissao;
  final String role;
  final String mensagem;

  ResultadoVerificacao({
    required this.temPermissao,
    required this.usuarioId,
    required this.permissao,
    required this.role,
    required this.mensagem,
  });

  factory ResultadoVerificacao.fromJson(Map<String, dynamic> json) {
    return ResultadoVerificacao(
      temPermissao: json['temPermissao'] ?? false,
      usuarioId: json['usuarioId'] ?? '',
      permissao: json['permissao'] ?? '',
      role: json['role'] ?? '',
      mensagem: json['mensagem'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'temPermissao': temPermissao,
        'usuarioId': usuarioId,
        'permissao': permissao,
        'role': role,
        'mensagem': mensagem,
      };
}
