// ==========================================
// APARTMENT DTOs
// ==========================================
import '../utils/app_date_time.dart';
class CriarApartamentoRequest {
  final String nome;
  final String? descricao;
  final String numero;
  final int andar;
  final String bloco;

  CriarApartamentoRequest({
    required this.nome,
    this.descricao,
    required this.numero,
    required this.andar,
    required this.bloco,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
    'numero': numero,
    'andar': andar,
    'bloco': bloco,
  };
}

class AtualizarApartamentoRequest {
  final String? nome;
  final String? descricao;
  final String? numero;
  final int? andar;
  final String? bloco;
  final String? estado;

  AtualizarApartamentoRequest({this.nome, this.descricao, this.numero, this.andar, this.bloco, this.estado});

  Map<String, dynamic> toJson() => {
    if (nome != null) 'nome': nome,
    if (descricao != null) 'descricao': descricao,
    if (numero != null) 'numero': numero,
    if (andar != null) 'andar': andar,
    if (bloco != null) 'bloco': bloco,
    if (estado != null) 'estado': estado,
  };
}

class ApartamentoListaDto {
  final String id;
  final String nome;
  final String numero;
  final int andar;
  final String bloco;
  final String estado;
  final int quantidadeMoradores;
  final bool emManutencao; // Flag automatica baseada em solicitacoes em andamento

  ApartamentoListaDto({
    required this.id,
    required this.nome,
    required this.numero,
    required this.andar,
    required this.bloco,
    required this.estado,
    required this.quantidadeMoradores,
    this.emManutencao = false,
  });

  factory ApartamentoListaDto.fromJson(Map<String, dynamic> json) => ApartamentoListaDto(
    id: json['id'] as String? ?? '',
    nome: json['nome'] as String? ?? '',
    numero: json['numero'] as String? ?? '',
    andar: json['andar'] as int? ?? 0,
    bloco: json['bloco'] as String? ?? '',
    estado: json['estado'] as String? ?? '',
    quantidadeMoradores: json['quantidadeMoradores'] as int? ?? 0,
    emManutencao: json['emManutencao'] as bool? ?? false,
  );
}

class ItemApartamentoDto {
  final String id;
  final String nome;
  final String? descricao;

  ItemApartamentoDto({required this.id, required this.nome, this.descricao});

  factory ItemApartamentoDto.fromJson(Map<String, dynamic> json) => ItemApartamentoDto(
    id: json['id'] as String? ?? '',
    nome: json['nome'] as String? ?? '',
    descricao: json['descricao'] as String?,
  );
}

class CriarItemApartamentoRequest {
  final String apartamentoId;
  final String nome;
  final String? descricao;

  CriarItemApartamentoRequest({required this.apartamentoId, required this.nome, this.descricao});

  Map<String, dynamic> toJson() => {'apartamentoId': apartamentoId, 'nome': nome, 'descricao': descricao};
}

class OcupacaoApartamentoDto {
  final String id;
  final String apartamentoId;
  final String nomeApartamento;
  final String usuarioId;
  final String nomeUsuario;
  final DateTime dataEntrada;
  final DateTime? dataSaida;
  final bool ativo;

  OcupacaoApartamentoDto({
    required this.id,
    required this.apartamentoId,
    required this.nomeApartamento,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.dataEntrada,
    this.dataSaida,
    required this.ativo,
  });

  factory OcupacaoApartamentoDto.fromJson(Map<String, dynamic> json) => OcupacaoApartamentoDto(
    id: json['id'] as String? ?? '',
    apartamentoId: json['apartamentoId'] as String? ?? '',
    nomeApartamento: json['nomeApartamento'] as String? ?? '',
    usuarioId: json['usuarioId'] as String? ?? '',
    nomeUsuario: json['nomeUsuario'] as String? ?? '',
    dataEntrada: parseBackendDateTimeToLocal(json['dataEntrada']),
    dataSaida: tryParseBackendDateTimeToLocal(json['dataSaida']),
    ativo: json['ativo'] as bool? ?? true,
  );
}

// ==========================================
// ANEXO DTOs
// ==========================================
class AnexoDto {
  final String id;
  final String solicitacaoId;
  final String nomeArquivo;
  final String url;
  final int tamanhoBytes;
  final String tamanhoFormatado;
  final String tipoConteudo;
  final DateTime criadoEm;

  AnexoDto({
    required this.id,
    required this.solicitacaoId,
    required this.nomeArquivo,
    required this.url,
    required this.tamanhoBytes,
    required this.tamanhoFormatado,
    required this.tipoConteudo,
    required this.criadoEm,
  });

  factory AnexoDto.fromJson(Map<String, dynamic> json) => AnexoDto(
    id: json['id'] as String? ?? '',
    solicitacaoId: json['solicitacaoId'] as String? ?? '',
    nomeArquivo: json['nomeArquivo'] as String? ?? '',
    url: json['url'] as String? ?? '',
    tamanhoBytes: json['tamanhoBytes'] as int? ?? 0,
    tamanhoFormatado: json['tamanhoFormatado'] as String? ?? '',
    tipoConteudo: json['tipoConteudo'] as String? ?? '',
    criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
  );
}

class CriarAnexoRequest {
  final String solicitacaoId;
  final String nomeArquivo;
  final String url;
  final int tamanhoBytes;
  final String tipoConteudo;

  CriarAnexoRequest({
    required this.solicitacaoId,
    required this.nomeArquivo,
    required this.url,
    required this.tamanhoBytes,
    required this.tipoConteudo,
  });

  Map<String, dynamic> toJson() => {
    'solicitacaoId': solicitacaoId,
    'nomeArquivo': nomeArquivo,
    'url': url,
    'tamanhoBytes': tamanhoBytes,
    'tipoConteudo': tipoConteudo,
  };
}

// ==========================================
// DASHBOARD DTOs
// ==========================================
class DashboardDto {
  final int totalApartamentos;
  final int apartamentosOcupados;
  final int apartamentosDisponiveis;
  final int totalSolicitacoes;
  final int solicitacoesPendentes;
  final int solicitacoesEmAndamento;
  final int solicitacoesConcluidas;
  final int totalMoradores;
  final int totalUsuarios;

  DashboardDto({
    required this.totalApartamentos,
    required this.apartamentosOcupados,
    required this.apartamentosDisponiveis,
    required this.totalSolicitacoes,
    required this.solicitacoesPendentes,
    required this.solicitacoesEmAndamento,
    required this.solicitacoesConcluidas,
    required this.totalMoradores,
    required this.totalUsuarios,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) => DashboardDto(
    totalApartamentos: json['totalApartamentos'] as int? ?? 0,
    apartamentosOcupados: json['apartamentosOcupados'] as int? ?? 0,
    apartamentosDisponiveis: json['apartamentosDisponiveis'] as int? ?? 0,
    totalSolicitacoes: json['totalSolicitacoes'] as int? ?? 0,
    solicitacoesPendentes: json['solicitacoesPendentes'] as int? ?? 0,
    solicitacoesEmAndamento: json['solicitacoesEmAndamento'] as int? ?? 0,
    solicitacoesConcluidas: json['solicitacoesConcluidas'] as int? ?? 0,
    totalMoradores: json['totalMoradores'] as int? ?? 0,
    totalUsuarios: json['totalUsuarios'] as int? ?? 0,
  );
}

// ==========================================
// HISTÓRICO STATUS DTOs
// ==========================================
class HistoricoStatusDto {
  final String id;
  final String solicitacaoId;
  final String status;
  final String usuarioId;
  final String nomeUsuario;
  final String tipoUsuario;
  final DateTime alteradoEm;

  HistoricoStatusDto({
    required this.id,
    required this.solicitacaoId,
    required this.status,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.tipoUsuario,
    required this.alteradoEm,
  });

  factory HistoricoStatusDto.fromJson(Map<String, dynamic> json) => HistoricoStatusDto(
    id: json['id'] as String? ?? '',
    solicitacaoId: json['solicitacaoId'] as String? ?? '',
    status: json['status'] as String? ?? '',
    usuarioId: json['usuarioId'] as String? ?? '',
    nomeUsuario: json['nomeUsuario'] as String? ?? '',
    tipoUsuario: json['tipoUsuario'] as String? ?? '',
    alteradoEm: parseBackendDateTimeToLocal(json['alteradoEm']),
  );
}

class HistoricoStatusListaDto {
  final String id;
  final String status;
  final String nomeUsuario;
  final DateTime alteradoEm;

  HistoricoStatusListaDto({
    required this.id,
    required this.status,
    required this.nomeUsuario,
    required this.alteradoEm,
  });

  factory HistoricoStatusListaDto.fromJson(Map<String, dynamic> json) => HistoricoStatusListaDto(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? '',
    nomeUsuario: json['nomeUsuario'] as String? ?? '',
    alteradoEm: parseBackendDateTimeToLocal(json['alteradoEm']),
  );
}

// ==========================================
// HISTÓRICO OCUPAÇÃO DTOs
// ==========================================
class HistoricoOcupacaoResumoDto {
  final String id;
  final String tipoMovimentacao; // "Entrada", "Saida", "Transferencia"
  final DateTime dataMovimentacao;
  final String nomeMorador;
  final String numeroApartamento;
  final String blocoApartamento;
  final String? numeroApartamentoOrigem;
  final String? blocoApartamentoOrigem;
  final String? numeroApartamentoDestino;
  final String? blocoApartamentoDestino;
  final String nomeExecutor;
  final String? observacoes;

  HistoricoOcupacaoResumoDto({
    required this.id,
    required this.tipoMovimentacao,
    required this.dataMovimentacao,
    required this.nomeMorador,
    required this.numeroApartamento,
    required this.blocoApartamento,
    this.numeroApartamentoOrigem,
    this.blocoApartamentoOrigem,
    this.numeroApartamentoDestino,
    this.blocoApartamentoDestino,
    required this.nomeExecutor,
    this.observacoes,
  });

  factory HistoricoOcupacaoResumoDto.fromJson(Map<String, dynamic> json) => HistoricoOcupacaoResumoDto(
    id: json['id'] as String? ?? '',
    tipoMovimentacao: json['tipoMovimentacao'] as String? ?? '',
    dataMovimentacao: json['dataMovimentacao'] != null
        ? parseBackendDateTimeToLocal(json['dataMovimentacao'] as String)
        : DateTime.now(),
    nomeMorador: json['nomeMorador'] as String? ?? '',
    numeroApartamento: json['numeroApartamento'] as String? ?? '',
    blocoApartamento: json['blocoApartamento'] as String? ?? '',
    numeroApartamentoOrigem: json['numeroApartamentoOrigem'] as String?,
    blocoApartamentoOrigem: json['blocoApartamentoOrigem'] as String?,
    numeroApartamentoDestino: json['numeroApartamentoDestino'] as String?,
    blocoApartamentoDestino: json['blocoApartamentoDestino'] as String?,
    nomeExecutor: json['nomeExecutor'] as String? ?? '',
    observacoes: json['observacoes'] as String?,
  );
}

class HistoricoOcupacaoDetalhadoDto extends HistoricoOcupacaoResumoDto {
  final String apartamentoId;
  final String moradorId;
  final String? apartamentoOrigemId;
  final String? apartamentoDestinoId;
  final String executadoPorId;
  final DateTime criadoEm;
  final String telefoneMorador;
  final String nomeLoginMorador;

  HistoricoOcupacaoDetalhadoDto({
    required super.id,
    required super.tipoMovimentacao,
    required super.dataMovimentacao,
    required super.nomeMorador,
    required super.numeroApartamento,
    required super.blocoApartamento,
    super.numeroApartamentoOrigem,
    super.blocoApartamentoOrigem,
    super.numeroApartamentoDestino,
    super.blocoApartamentoDestino,
    required super.nomeExecutor,
    super.observacoes,
    required this.apartamentoId,
    required this.moradorId,
    this.apartamentoOrigemId,
    this.apartamentoDestinoId,
    required this.executadoPorId,
    required this.criadoEm,
    required this.telefoneMorador,
    required this.nomeLoginMorador,
  });

  factory HistoricoOcupacaoDetalhadoDto.fromJson(Map<String, dynamic> json) => HistoricoOcupacaoDetalhadoDto(
    id: json['id'] as String? ?? '',
    tipoMovimentacao: json['tipoMovimentacao'] as String? ?? '',
    dataMovimentacao: json['dataMovimentacao'] != null
        ? parseBackendDateTimeToLocal(json['dataMovimentacao'] as String)
        : DateTime.now(),
    nomeMorador: json['nomeMorador'] as String? ?? '',
    numeroApartamento: json['numeroApartamento'] as String? ?? '',
    blocoApartamento: json['blocoApartamento'] as String? ?? '',
    numeroApartamentoOrigem: json['numeroApartamentoOrigem'] as String?,
    blocoApartamentoOrigem: json['blocoApartamentoOrigem'] as String?,
    numeroApartamentoDestino: json['numeroApartamentoDestino'] as String?,
    blocoApartamentoDestino: json['blocoApartamentoDestino'] as String?,
    nomeExecutor: json['nomeExecutor'] as String? ?? '',
    observacoes: json['observacoes'] as String?,
    apartamentoId: json['apartamentoId'] as String? ?? '',
    moradorId: json['moradorId'] as String? ?? '',
    apartamentoOrigemId: json['apartamentoOrigemId'] as String?,
    apartamentoDestinoId: json['apartamentoDestinoId'] as String?,
    executadoPorId: json['executadoPorId'] as String? ?? '',
    criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    telefoneMorador: json['telefoneMorador'] as String? ?? '',
    nomeLoginMorador: json['nomeLoginMorador'] as String? ?? '',
  );
}

class CriarHistoricoOcupacaoRequest {
  final String apartamentoId;
  final String moradorId;
  final String tipoMovimentacao; // "Entrada", "Saida", "Transferencia"
  final DateTime? dataMovimentacao;
  final String? apartamentoOrigemId;
  final String? apartamentoDestinoId;
  final String? observacoes;

  CriarHistoricoOcupacaoRequest({
    required this.apartamentoId,
    required this.moradorId,
    required this.tipoMovimentacao,
    this.dataMovimentacao,
    this.apartamentoOrigemId,
    this.apartamentoDestinoId,
    this.observacoes,
  });

  Map<String, dynamic> toJson() => {
    'apartamentoId': apartamentoId,
    'moradorId': moradorId,
    'tipoMovimentacao': tipoMovimentacao,
    if (dataMovimentacao != null) 'dataMovimentacao': toBackendUtcIsoString(dataMovimentacao!),
    if (apartamentoOrigemId != null) 'apartamentoOrigemId': apartamentoOrigemId,
    if (apartamentoDestinoId != null) 'apartamentoDestinoId': apartamentoDestinoId,
    if (observacoes != null) 'observacoes': observacoes,
  };
}

// ==========================================
// MANUTENÇÃO GERAL DTOs
// ==========================================
class ManutencaoPreventivaDto {
  final String id;
  final String titulo;
  final String? descricao;
  final String tipo;
  final String frequencia;
  final DateTime proximaManutencao;
  final DateTime? ultimaManutencao;
  final double? custoEstimado;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final int diasAlerta;
  final bool ativa;
  final String? observacoes;
  final String? responsavelId;
  final String? responsavelNome;
  final String? localDescricao;
  final int diasFaltantes;
  final bool vencida;
  final bool alerta;
  final DateTime criadoEm;
  final String criadoPorNome;
  final DateTime? atualizadoEm;
  final String? atualizadoPorNome;
  final int totalExecucoes;
  final DateTime? ultimaExecucao;
  final String? tipoSolicitacaoId;
  final String? tipoSolicitacaoNome;
  final String? areaTecnicaId;
  final String? areaTecnicaNome;

  ManutencaoPreventivaDto({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.tipo,
    required this.frequencia,
    required this.proximaManutencao,
    this.ultimaManutencao,
    this.custoEstimado,
    this.fornecedor,
    this.telefoneFornecedor,
    required this.diasAlerta,
    required this.ativa,
    this.observacoes,
    this.responsavelId,
    this.responsavelNome,
    this.localDescricao,
    required this.diasFaltantes,
    required this.vencida,
    required this.alerta,
    required this.criadoEm,
    required this.criadoPorNome,
    this.atualizadoEm,
    this.atualizadoPorNome,
    required this.totalExecucoes,
    this.ultimaExecucao,
    this.tipoSolicitacaoId,
    this.tipoSolicitacaoNome,
    this.areaTecnicaId,
    this.areaTecnicaNome,
  });

  factory ManutencaoPreventivaDto.fromJson(Map<String, dynamic> json) => ManutencaoPreventivaDto(
    id: json['id'] as String? ?? '',
    titulo: json['titulo'] as String? ?? '',
    descricao: json['descricao'] as String?,
    tipo: json['tipo'] as String? ?? '',
    frequencia: json['frequencia'] as String? ?? '',
    proximaManutencao: json['proximaManutencao'] != null
        ? parseBackendDateTimeToLocal(json['proximaManutencao'] as String)
        : DateTime.now(),
    ultimaManutencao: tryParseBackendDateTimeToLocal(json['ultimaManutencao']),
    custoEstimado: (json['custoEstimado'] as num?)?.toDouble(),
    fornecedor: json['fornecedor'] as String?,
    telefoneFornecedor: json['telefoneFornecedor'] as String?,
    diasAlerta: json['diasAlerta'] as int? ?? 7,
    ativa: json['ativa'] as bool? ?? true,
    observacoes: json['observacoes'] as String?,
    responsavelId: json['responsavelId'] as String?,
    responsavelNome: json['responsavelNome'] as String?,
    localDescricao: json['localDescricao'] as String?,
    diasFaltantes: json['diasFaltantes'] as int? ?? 0,
    vencida: json['vencida'] as bool? ?? false,
    alerta: json['alerta'] as bool? ?? false,
    criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    criadoPorNome: json['criadoPorNome'] as String? ?? '',
    atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
    atualizadoPorNome: json['atualizadoPorNome'] as String?,
    totalExecucoes: json['totalExecucoes'] as int? ?? 0,
    ultimaExecucao: tryParseBackendDateTimeToLocal(json['ultimaExecucao']),
    tipoSolicitacaoId: json['tipoSolicitacaoId'] as String?,
    tipoSolicitacaoNome: json['tipoSolicitacaoNome'] as String?,
    areaTecnicaId: json['areaTecnicaId'] as String?,
    areaTecnicaNome: json['areaTecnicaNome'] as String?,
  );
}

// Status enum for preventive maintenance (UI-friendly mapping)
enum StatusManutencaoPreventiva {
  Agendada,
  EmAndamento,
  Concluida,
  Atrasada,
  Cancelada,
}

extension StatusManutencaoPreventivaExt on StatusManutencaoPreventiva {
  String toPortuguese() {
    switch (this) {
      case StatusManutencaoPreventiva.Agendada:
        return 'Agendada';
      case StatusManutencaoPreventiva.EmAndamento:
        return 'Em andamento';
      case StatusManutencaoPreventiva.Concluida:
        return 'Concluída';
      case StatusManutencaoPreventiva.Atrasada:
        return 'Atrasada';
      case StatusManutencaoPreventiva.Cancelada:
        return 'Cancelada';
    }
  }
}

// Heuristic to compute status from fields available on DTO
StatusManutencaoPreventiva statusFromManutencao(ManutencaoPreventivaDto m) {
  // Priority: use available flags
  if (m.vencida) return StatusManutencaoPreventiva.Atrasada;
  if (m.alerta) return StatusManutencaoPreventiva.Agendada;
  return StatusManutencaoPreventiva.Agendada;
}

class CriarManutencaoPreventivaRequest {
  final String titulo;
  final String? descricao;
  final String tipo; // Tipo de manutenção
  final String? frequencia;
  final DateTime proximaManutencao;
  final double? custoEstimado;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final int diasAlerta;
  final bool alertarAdministradores;
  final bool alertarFuncionarios;
  final bool alertarSindico;
  final String? responsavelId;
  final String? observacoes;
  final String? apartamentoId;
  final String? itemApartamentoId;
  final String? tipoSolicitacaoId;
  final String? areaTecnicaId;

  CriarManutencaoPreventivaRequest({
    required this.titulo,
    this.descricao,
    required this.tipo,
    this.frequencia, // Opcional para manutenções pontuais
    required this.proximaManutencao,
    this.custoEstimado,
    this.fornecedor,
    this.telefoneFornecedor,
    this.diasAlerta = 7,
    this.alertarAdministradores = true,
    this.alertarFuncionarios = false,
    this.alertarSindico = false,
    this.responsavelId,
    this.observacoes,
    this.apartamentoId,
    this.itemApartamentoId,
    this.tipoSolicitacaoId,
    this.areaTecnicaId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'titulo': titulo,
      'tipo': tipo,
      'proximaManutencao': toBackendUtcIsoString(proximaManutencao),
      'diasAlerta': diasAlerta,
      'alertarAdministradores': alertarAdministradores,
      'alertarFuncionarios': alertarFuncionarios,
      'alertarSindico': alertarSindico,
    };

    // Adiciona campos opcionais apenas se preenchidos
    if (frequencia != null && frequencia!.trim().isNotEmpty) {
      json['frequencia'] = frequencia;
    }
    if (descricao != null && descricao!.trim().isNotEmpty) {
      json['descricao'] = descricao;
    }
    if (custoEstimado != null && custoEstimado! > 0) {
      json['custoEstimado'] = custoEstimado;
    }
    if (fornecedor != null && fornecedor!.trim().isNotEmpty) {
      json['fornecedor'] = fornecedor;
    }
    if (telefoneFornecedor != null && telefoneFornecedor!.trim().isNotEmpty) {
      json['telefoneFornecedor'] = telefoneFornecedor;
    }
    if (responsavelId != null && responsavelId!.trim().isNotEmpty) {
      json['responsavelId'] = responsavelId;
    }
    if (observacoes != null && observacoes!.trim().isNotEmpty) {
      json['observacoes'] = observacoes;
    }
    if (apartamentoId != null &&
        apartamentoId!.trim().isNotEmpty &&
        apartamentoId != 'GERAL' &&
        apartamentoId != 'CONDOMINIO') {
      json['apartamentoId'] = apartamentoId;
    }
    if (itemApartamentoId != null && itemApartamentoId!.trim().isNotEmpty) {
      json['itemApartamentoId'] = itemApartamentoId;
    }
    if (tipoSolicitacaoId != null && tipoSolicitacaoId!.trim().isNotEmpty) {
      json['tipoSolicitacaoId'] = tipoSolicitacaoId;
    }
    if (areaTecnicaId != null && areaTecnicaId!.trim().isNotEmpty) {
      json['areaTecnicaId'] = areaTecnicaId;
    }

    return json;
  }
}

class HistoricoManutencaoPreventivaDto {
  final String id;
  final String manutencaoPreventivaId;
  final String manutencaoTitulo;
  final DateTime dataRealizacao;
  final String status;
  final int? statusCodigo;
  final double? custoReal;
  final String? descricaoExecucao;
  final String? observacoes;
  final String? notaFiscal;
  final List<String>? fotosAntes;
  final List<String>? fotosDepois;
  final String realizadoPorNome;
  final String? realizadoPorId;
  final String? solicitacaoId;
  final DateTime criadoEm;

  HistoricoManutencaoPreventivaDto({
    required this.id,
    required this.manutencaoPreventivaId,
    required this.manutencaoTitulo,
    required this.dataRealizacao,
    required this.status,
    this.statusCodigo,
    this.custoReal,
    this.descricaoExecucao,
    this.observacoes,
    this.notaFiscal,
    this.fotosAntes,
    this.fotosDepois,
    required this.realizadoPorNome,
    this.realizadoPorId,
    this.solicitacaoId,
    required this.criadoEm,
  });

  factory HistoricoManutencaoPreventivaDto.fromJson(Map<String, dynamic> json) => HistoricoManutencaoPreventivaDto(
    id: json['id'] as String? ?? '',
    manutencaoPreventivaId: json['manutencaoPreventivaId'] as String? ?? '',
    manutencaoTitulo: json['manutencaoTitulo'] as String? ?? '',
    dataRealizacao: parseBackendDateTimeToLocal(json['dataRealizacao']),
    status: _parseStatusLabel(json['status']),
    statusCodigo: _parseStatusCode(json['status']),
    custoReal: (json['custoReal'] as num?)?.toDouble(),
    descricaoExecucao: json['descricaoExecucao'] as String?,
    observacoes: json['observacoes'] as String?,
    notaFiscal: json['notaFiscal'] as String?,
    fotosAntes: _parseFotos(json['fotosAntes']),
    fotosDepois: _parseFotos(json['fotosDepois']),
    realizadoPorNome: json['realizadoPorNome'] as String? ?? '',
    realizadoPorId: json['realizadoPorId'] as String?,
    solicitacaoId: json['solicitacaoId'] as String?,
    criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
  );

  static int? _parseStatusCode(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  static String _parseStatusLabel(dynamic raw) {
    if (raw is String) return raw;
    if (raw is num) {
      return _statusCodeToLabel(raw.toInt());
    }
    return raw?.toString() ?? '';
  }

  static String _statusCodeToLabel(int code) {
    switch (code) {
      case 2:
        return 'Concluida';
      case 1:
        return 'Cancelada';
      case 0:
        return 'EmAndamento';
      default:
        return 'Status $code';
    }
  }

  static List<String>? _parseFotos(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
    return null;
  }
}

class RegistrarExecucaoManutencaoRequest {
  final DateTime dataRealizacao;
  final String status;
  final double? custoReal;
  final String? descricaoExecucao;
  final String? observacoes;
  final String? notaFiscal;
  final List<String>? fotosAntes;
  final List<String>? fotosDepois;
  final String? solicitacaoId;

  RegistrarExecucaoManutencaoRequest({
    required this.dataRealizacao,
    required this.status,
    this.custoReal,
    this.descricaoExecucao,
    this.observacoes,
    this.notaFiscal,
    this.fotosAntes,
    this.fotosDepois,
    this.solicitacaoId,
  });

  Map<String, dynamic> toJson() => {
    'dataRealizacao': toBackendUtcIsoString(dataRealizacao),
    'status': status,
    if (custoReal != null) 'custoReal': custoReal,
    if (descricaoExecucao != null) 'descricaoExecucao': descricaoExecucao,
    if (observacoes != null) 'observacoes': observacoes,
    if (notaFiscal != null) 'notaFiscal': notaFiscal,
    if (fotosAntes != null) 'fotosAntes': fotosAntes,
    if (fotosDepois != null) 'fotosDepois': fotosDepois,
    if (solicitacaoId != null) 'solicitacaoId': solicitacaoId,
  };
}

class DashboardManutencoesPreventivasDto {
  final int totalManutencoes;
  final int manutencoesAtivas;
  final int manutencoesVencidas;
  final int manutencoesComAlerta;
  final int manutencoesProximos7Dias;
  final int manutencoesProximos30Dias;
  final double custoEstimadoMensal;
  final double custoRealMensal;
  final List<ManutencaoPreventivaDto> proximasManutencoes;
  final List<ManutencaoPreventivaDto> manutencoesAtrasadas;

  DashboardManutencoesPreventivasDto({
    required this.totalManutencoes,
    required this.manutencoesAtivas,
    required this.manutencoesVencidas,
    required this.manutencoesComAlerta,
    required this.manutencoesProximos7Dias,
    required this.manutencoesProximos30Dias,
    required this.custoEstimadoMensal,
    required this.custoRealMensal,
    required this.proximasManutencoes,
    required this.manutencoesAtrasadas,
  });

  factory DashboardManutencoesPreventivasDto.fromJson(Map<String, dynamic> json) => DashboardManutencoesPreventivasDto(
    totalManutencoes: json['totalManutencoes'] as int? ?? 0,
    manutencoesAtivas: json['manutencoesAtivas'] as int? ?? 0,
    manutencoesVencidas: json['manutencoesVencidas'] as int? ?? 0,
    manutencoesComAlerta: json['manutencoesComAlerta'] as int? ?? 0,
    manutencoesProximos7Dias: json['manutencoesProximos7Dias'] as int? ?? 0,
    manutencoesProximos30Dias: json['manutencoesProximos30Dias'] as int? ?? 0,
    custoEstimadoMensal: (json['custoEstimadoMensal'] as num?)?.toDouble() ?? 0.0,
    custoRealMensal: (json['custoRealMensal'] as num?)?.toDouble() ?? 0.0,
    proximasManutencoes:
        (json['proximasManutencoes'] as List<dynamic>?)
            ?.map((e) => ManutencaoPreventivaDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    manutencoesAtrasadas:
        (json['manutencoesAtrasadas'] as List<dynamic>?)
            ?.map((e) => ManutencaoPreventivaDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

// ==========================================
// SMS MASSA DTOs
// ==========================================
class EnviarSmsMassaRequest {
  final String mensagem;
  final List<String>? tiposUsuario; // null = todos
  final List<String>? usuarioIds;
  final bool enviarNotificacaoApp;
  final String? tituloNotificacao;

  EnviarSmsMassaRequest({
    required this.mensagem,
    this.tiposUsuario,
    this.usuarioIds,
    this.enviarNotificacaoApp = true,
    this.tituloNotificacao,
  });

  Map<String, dynamic> toJson() => {
    'mensagem': mensagem,
    if (tiposUsuario != null) 'tiposUsuario': tiposUsuario,
    if (usuarioIds != null) 'usuarioIds': usuarioIds,
    'enviarNotificacaoApp': enviarNotificacaoApp,
    if (tituloNotificacao != null) 'tituloNotificacao': tituloNotificacao,
  };
}

class ResultadoEnvioSmsMassaDto {
  final int totalDestinatarios;
  final int smsEnviados;
  final int smsFalhas;
  final int notificacoesEnviadas;
  final List<String> erros;
  final List<DestinatarioResultadoDto> destinatarios;

  ResultadoEnvioSmsMassaDto({
    required this.totalDestinatarios,
    required this.smsEnviados,
    required this.smsFalhas,
    required this.notificacoesEnviadas,
    required this.erros,
    required this.destinatarios,
  });

  factory ResultadoEnvioSmsMassaDto.fromJson(Map<String, dynamic> json) => ResultadoEnvioSmsMassaDto(
    totalDestinatarios: json['totalDestinatarios'] as int? ?? 0,
    smsEnviados: json['smsEnviados'] as int? ?? 0,
    smsFalhas: json['smsFalhas'] as int? ?? 0,
    notificacoesEnviadas: json['notificacoesEnviadas'] as int? ?? 0,
    erros: (json['erros'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    destinatarios:
        (json['destinatarios'] as List<dynamic>?)
            ?.map((e) => DestinatarioResultadoDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class DestinatarioResultadoDto {
  final String usuarioId;
  final String nome;
  final String telefone;
  final bool smsEnviado;
  final bool notificacaoEnviada;
  final String? mensagemErro;

  DestinatarioResultadoDto({
    required this.usuarioId,
    required this.nome,
    required this.telefone,
    required this.smsEnviado,
    required this.notificacaoEnviada,
    this.mensagemErro,
  });

  factory DestinatarioResultadoDto.fromJson(Map<String, dynamic> json) => DestinatarioResultadoDto(
    usuarioId: json['usuarioId'] as String? ?? '',
    nome: json['nome'] as String? ?? '',
    telefone: json['telefone'] as String? ?? '',
    smsEnviado: json['smsEnviado'] as bool? ?? false,
    notificacaoEnviada: json['notificacaoEnviada'] as bool? ?? false,
    mensagemErro: json['mensagemErro'] as String?,
  );
}

class DestinatarioSmsMassaDto {
  final String id;
  final String nome;
  final String telefone;
  final String tipo;
  final bool ativo;

  DestinatarioSmsMassaDto({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.tipo,
    required this.ativo,
  });

  factory DestinatarioSmsMassaDto.fromJson(Map<String, dynamic> json) => DestinatarioSmsMassaDto(
    id: json['id'] as String? ?? '',
    nome: json['nome'] as String? ?? '',
    telefone: json['telefone'] as String? ?? '',
    tipo: json['tipo'] as String? ?? '',
    ativo: json['ativo'] as bool? ?? true,
  );
}

class HistoricoSmsMassaDto {
  final String id;
  final String mensagem;
  final String tituloNotificacao;
  final int totalDestinatarios;
  final int smsEnviados;
  final int notificacoesEnviadas;
  final String enviadoPor;
  final DateTime enviadoEm;
  final List<String> tiposUsuario;

  HistoricoSmsMassaDto({
    required this.id,
    required this.mensagem,
    required this.tituloNotificacao,
    required this.totalDestinatarios,
    required this.smsEnviados,
    required this.notificacoesEnviadas,
    required this.enviadoPor,
    required this.enviadoEm,
    required this.tiposUsuario,
  });

  factory HistoricoSmsMassaDto.fromJson(Map<String, dynamic> json) => HistoricoSmsMassaDto(
    id: json['id'] as String? ?? '',
    mensagem: json['mensagem'] as String? ?? '',
    tituloNotificacao: json['tituloNotificacao'] as String? ?? '',
    totalDestinatarios: json['totalDestinatarios'] as int? ?? 0,
    smsEnviados: json['smsEnviados'] as int? ?? 0,
    notificacoesEnviadas: json['notificacoesEnviadas'] as int? ?? 0,
    enviadoPor: json['enviadoPor'] as String? ?? '',
    enviadoEm: parseBackendDateTimeToLocal(json['enviadoEm']),
    tiposUsuario: (json['tiposUsuario'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  );
}

class EditarManutencaoPreventivaRequest {
  final String titulo;
  final String? descricao;
  final String tipo;
  final String? frequencia; // Opcional para manutenções pontuais
  final DateTime proximaManutencao;
  final double custoEstimado;
  final String? fornecedor;
  final String? telefoneFornecedor;
  final int diasAlerta;
  final bool alertarAdministradores;
  final bool alertarFuncionarios;
  final bool alertarSindico;
  final String? responsavelId;
  final bool ativa;
  final String? observacoes;
  final String? apartamentoId;
  final bool enviarMensagemMorador;
  final String? tipoSolicitacaoId;
  final String? areaTecnicaId;

  EditarManutencaoPreventivaRequest({
    required this.titulo,
    this.descricao,
    required this.tipo,
    this.frequencia, // Opcional para manutenções pontuais
    required this.proximaManutencao,
    required this.custoEstimado,
    this.fornecedor,
    this.telefoneFornecedor,
    this.diasAlerta = 7,
    this.alertarAdministradores = true,
    this.alertarFuncionarios = false,
    this.alertarSindico = false,
    this.responsavelId,
    required this.ativa,
    this.observacoes,
    this.apartamentoId,
    this.enviarMensagemMorador = false,
    this.tipoSolicitacaoId,
    this.areaTecnicaId,
  });

  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'descricao': descricao,
    'tipo': tipo,
    if (frequencia != null) 'frequencia': frequencia,
    'proximaManutencao': toBackendUtcIsoString(proximaManutencao),
    'custoEstimado': custoEstimado,
    'fornecedor': fornecedor,
    'telefoneFornecedor': telefoneFornecedor,
    'diasAlerta': diasAlerta,
    'alertarAdministradores': alertarAdministradores,
    'alertarFuncionarios': alertarFuncionarios,
    'alertarSindico': alertarSindico,
    'responsavelId': responsavelId,
    'ativa': ativa,
    'observacoes': observacoes,
    if (apartamentoId != null) 'apartamentoId': apartamentoId,
    'enviarMensagemMorador': enviarMensagemMorador,
    if (tipoSolicitacaoId != null) 'tipoSolicitacaoId': tipoSolicitacaoId,
    if (areaTecnicaId != null) 'areaTecnicaId': areaTecnicaId,
  };
}
