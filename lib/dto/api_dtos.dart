import '../utils/app_logger.dart';
import '../utils/app_date_time.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool sucesso;
  final String mensagem;
  final T? dados;
  final List<String>? erros;

  ApiResponse({
    required this.sucesso,
    required this.mensagem,
    this.dados,
    this.erros,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      sucesso: json['sucesso'] ?? false,
      mensagem: json['mensagem'] ?? '',
      dados: json['dados'] != null ? fromJson(json['dados']) : null,
      erros: (json['erros'] as List<dynamic>?)?.cast<String>(),
    );
  }

  bool get hasErrors => erros != null && erros!.isNotEmpty;
  String get errorMessage => erros?.first ?? mensagem;
}

/// Login/Auth DTOs
class LoginRequest {
  final String nomeLogin;
  final String senha;

  LoginRequest({
    required this.nomeLogin,
    required this.senha,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomeLogin': nomeLogin,
      'senha': senha,
    };
  }
}



class MoradorInfoDto {
  final String moradorId;
  final String apartamentoId;
  final int numeroApartamento;
  final String blocoApartamento;

  MoradorInfoDto({
    required this.moradorId,
    required this.apartamentoId,
    required this.numeroApartamento,
    required this.blocoApartamento,
  });

  factory MoradorInfoDto.fromJson(Map<String, dynamic> json) {
    return MoradorInfoDto(
      moradorId: json['moradorId'] ?? '',
      apartamentoId: json['apartamentoId'] ?? '',
      numeroApartamento: json['numeroApartamento'] ?? 0,
      blocoApartamento: json['blocoApartamento'] ?? '',
    );
  }
}

class RegisterRequest {
  final String nome;
  final String nomeLogin;
  final String telefone;
  final String senha;
  final String confirmarSenha;
  final String tipo;

  RegisterRequest({
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.senha,
    required this.confirmarSenha,
    required this.tipo,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'nomeLogin': nomeLogin,
      'telefone': telefone,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'tipo': tipo,
    };
  }
}

class ResetPasswordRequest {
  final String? usuarioId;
  final String telefone;
  final String otp;
  final String novaSenha;
  final String confirmarNovaSenha;

  ResetPasswordRequest({
    this.usuarioId,
    required this.telefone,
    required this.otp,
    required this.novaSenha,
    required this.confirmarNovaSenha,
  });

  Map<String, dynamic> toJson() {
    AppLogger.debug('ResetPasswordRequest', '[DEBUG] ResetPasswordRequest.toJson - usuarioId: "$usuarioId" (length: ${usuarioId?.length ?? 0})');
    final map = {
      'telefone': telefone,
      'otp': otp,
      'novaSenha': novaSenha,
      'confirmarNovaSenha': confirmarNovaSenha,
    };
    // Só adiciona se não for null E não for string vazia
    if (usuarioId != null && usuarioId!.isNotEmpty) {
      map['usuarioId'] = usuarioId!;
      AppLogger.debug('ResetPasswordRequest', '[DEBUG] ResetPasswordRequest - Incluindo usuarioId no map: $usuarioId');
    } else {
      AppLogger.debug('ResetPasswordRequest', '[DEBUG] ResetPasswordRequest - usuarioId vazio ou null, não incluindo no map');
    }
    return map;
  }
}

class ResetSenhaResponseDto {
  final String usuarioId;
  final String telefoneMascarado;
  final String telefoneCompleto;

  ResetSenhaResponseDto({
    required this.usuarioId,
    required this.telefoneMascarado,
    required this.telefoneCompleto,
  });

  factory ResetSenhaResponseDto.fromJson(Map<String, dynamic> json) {
    return ResetSenhaResponseDto(
      usuarioId: json['usuarioId'] ?? '',
      telefoneMascarado: json['telefoneMascarado'] ?? '',
      telefoneCompleto: json['telefoneCompleto'] ?? '',
    );
  }
}

/// Dashboard DTOs
class DashboardEstatisticas {
  final int totalApartamentos;
  final int apartamentosOcupados;
  final int apartamentosDisponiveis;
  final int apartamentosEmManutencao; // Quantidade de apartamentos com solicitações em andamento
  final int totalSolicitacoes;
  final int solicitacoesPendentes;
  final int solicitacoesEmAndamento;
  final int solicitacoesConcluidas;
  final int solicitacoesEmAnalise;
  final int solicitacoesAguardando;
  final int solicitacoesRejeitadas;
  final int solicitacoesCanceladas;
  final int totalMoradores;
  final int totalUsuarios;

  DashboardEstatisticas({
    required this.totalApartamentos,
    required this.apartamentosOcupados,
    required this.apartamentosDisponiveis,
    required this.apartamentosEmManutencao,
    required this.totalSolicitacoes,
    required this.solicitacoesPendentes,
    required this.solicitacoesEmAndamento,
    required this.solicitacoesConcluidas,
    required this.solicitacoesEmAnalise,
    required this.solicitacoesAguardando,
    required this.solicitacoesRejeitadas,
    required this.solicitacoesCanceladas,
    required this.totalMoradores,
    required this.totalUsuarios,
  });

  factory DashboardEstatisticas.fromJson(Map<String, dynamic> json) {
    return DashboardEstatisticas(
      totalApartamentos: json['totalApartamentos'] ?? 0,
      apartamentosOcupados: json['apartamentosOcupados'] ?? 0,
      apartamentosDisponiveis: json['apartamentosDisponiveis'] ?? 0,
      apartamentosEmManutencao: json['apartamentosEmManutencao'] ?? 0,
      totalSolicitacoes: json['totalSolicitacoes'] ?? 0,
      solicitacoesPendentes: json['solicitacoesPendentes'] ?? 0,
      solicitacoesEmAndamento: json['solicitacoesEmAndamento'] ?? 0,
      solicitacoesConcluidas: json['solicitacoesConcluidas'] ?? 0,
      solicitacoesEmAnalise: json['solicitacoesEmAnalise'] ?? 0,
      solicitacoesAguardando: json['solicitacoesAguardando'] ?? 0,
      solicitacoesRejeitadas: json['solicitacoesRejeitadas'] ?? 0,
      solicitacoesCanceladas: json['solicitacoesCanceladas'] ?? 0,
      totalMoradores: json['totalMoradores'] ?? 0,
      totalUsuarios: json['totalUsuarios'] ?? 0,
    );
  }
}

class SolicitacaoRecenteDto {
  final String id;
  final String titulo;
  final String status;
  final String? nomeUsuarioCriador;
  final String? nomeResponsavel;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final DateTime criadoEm;
  final DateTime? prazoLimite;
  final int quantidadeComentarios;
  final int quantidadeAnexos;

  SolicitacaoRecenteDto({
    required this.id,
    required this.titulo,
    required this.status,
    this.nomeUsuarioCriador,
    this.nomeResponsavel,
    this.numeroApartamento,
    this.blocoApartamento,
    required this.criadoEm,
    this.prazoLimite,
    required this.quantidadeComentarios,
    required this.quantidadeAnexos,
  });

  factory SolicitacaoRecenteDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoRecenteDto(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      status: json['status'] ?? '',
      nomeUsuarioCriador: json['nomeUsuarioCriador'],
      nomeResponsavel: json['nomeResponsavel'],
      numeroApartamento: json['numeroApartamento'],
      blocoApartamento: json['blocoApartamento'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      prazoLimite: tryParseBackendDateTimeToLocal(json['prazoLimite']),
      quantidadeComentarios: json['quantidadeComentarios'] ?? 0,
      quantidadeAnexos: json['quantidadeAnexos'] ?? 0,
    );
  }
}

class StatusGraficoDto {
  final String status;
  final int quantidade;

  StatusGraficoDto({
    required this.status,
    required this.quantidade,
  });

  factory StatusGraficoDto.fromJson(Map<String, dynamic> json) {
    return StatusGraficoDto(
      status: json['status'] ?? '',
      quantidade: json['quantidade'] ?? 0,
    );
  }
}

class GraficoStatusDto {
  final List<StatusGraficoDto> dados;

  GraficoStatusDto({required this.dados});

  factory GraficoStatusDto.fromJson(Map<String, dynamic> json) {
    return GraficoStatusDto(
      dados: (json['dados'] as List<dynamic>?)
              ?.map((d) => StatusGraficoDto.fromJson(d))
              .toList() ??
          [],
    );
  }
}

/// Notificação DTOs
class NotificacaoResumoDto {
  final int totalNaoLidas;
  final int totalManutencao;
  final int totalAviso;
  final int totalSistema;

  NotificacaoResumoDto({
    required this.totalNaoLidas,
    required this.totalManutencao,
    required this.totalAviso,
    required this.totalSistema,
  });

  factory NotificacaoResumoDto.fromJson(Map<String, dynamic> json) {
    return NotificacaoResumoDto(
      totalNaoLidas: json['totalNaoLidas'] ?? 0,
      totalManutencao: json['totalManutencao'] ?? 0,
      totalAviso: json['totalAviso'] ?? 0,
      totalSistema: json['totalSistema'] ?? 0,
    );
  }
}

class NotificacaoDto {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensagem;
  final String tipo;
  final bool lida;
  final DateTime criadoEm;

  NotificacaoDto({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    required this.criadoEm,
  });

  factory NotificacaoDto.fromJson(Map<String, dynamic> json) {
    return NotificacaoDto(
      id: json['id'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      tipo: json['tipo'] ?? '',
      lida: json['lida'] ?? false,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }
}

/// Solicitação create/update DTOs
class CriarSolicitacaoRequest {
  final String titulo;
  final String? descricao;
  final String? moradorId;
  final String apartamentoId;
  final DateTime? prazoLimite;

  CriarSolicitacaoRequest({
    required this.titulo,
    this.descricao,
    this.moradorId,
    required this.apartamentoId,
    this.prazoLimite,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      if (moradorId != null) 'moradorId': moradorId,
      'apartamentoId': apartamentoId,
      'prazoLimite': prazoLimite != null ? toBackendUtcIsoString(prazoLimite!) : null,
    };
  }
}

class AtualizarSolicitacaoRequest {
  final String? titulo;
  final String? descricao;
  final String? status;
  final String? responsavelId;
  final String? nomeResponsavel;
  final DateTime? prazoLimite;
  final String? areaTecnicaId;
  final List<String>? areaTecnicaIds;

  AtualizarSolicitacaoRequest({
    this.titulo,
    this.descricao,
    this.status,
    this.responsavelId,
    this.nomeResponsavel,
    this.prazoLimite,
    this.areaTecnicaId,
    this.areaTecnicaIds,
  });

  Map<String, dynamic> toJson() {
    return {
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (status != null) 'status': status,
      if (responsavelId != null) 'responsavelId': responsavelId,
      if (nomeResponsavel != null) 'nomeResponsavel': nomeResponsavel,
      if (prazoLimite != null) 'prazoLimite': toBackendUtcIsoString(prazoLimite!),
      if (areaTecnicaId != null) 'areaTecnicaId': areaTecnicaId,
      // Backwards compatibility: some backends expect capitalized key
      if (areaTecnicaId != null) 'AreaTecnicaId': areaTecnicaId,
      if (areaTecnicaIds != null) 'areaTecnicaIds': areaTecnicaIds,
    };
  }
}

class AtribuirSolicitacaoRequest {
  final String responsavelId;
  final String? comentario;

  AtribuirSolicitacaoRequest({
    required this.responsavelId,
    this.comentario,
  });

  Map<String, dynamic> toJson() {
    return {
      'responsavelId': responsavelId,
      if (comentario != null) 'comentario': comentario,
    };
  }
}

/// Comentário DTOs
class CriarComentarioRequest {
  final String solicitacaoId;
  final String mensagem;
  final bool interno;

  CriarComentarioRequest({
    required this.solicitacaoId,
    required this.mensagem,
    required this.interno,
  });

  Map<String, dynamic> toJson() {
    return {
      'solicitacaoId': solicitacaoId,
      'mensagem': mensagem,
      'interno': interno,
    };
  }
}

class AtualizarComentarioRequest {
  final String mensagem;
  final bool interno;

  AtualizarComentarioRequest({
    required this.mensagem,
    required this.interno,
  });

  Map<String, dynamic> toJson() {
    return {
      'mensagem': mensagem,
      'interno': interno,
    };
  }
}

/// Apartamento DTOs
class CriarApartamentoRequest {
  final String nome;
  final String? descricao;
  final String numero;
  final int andar;
  final String bloco;
  final String estado;
  final int quartos;
  final int banheiros;
  final double? areaMetrosQuadrados;
  final String? observacoes;

  CriarApartamentoRequest({
    required this.nome,
    this.descricao,
    required this.numero,
    required this.andar,
    required this.bloco,
    required this.estado,
    required this.quartos,
    required this.banheiros,
    this.areaMetrosQuadrados,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descricao': descricao,
      'numero': numero,
      'andar': andar,
      'bloco': bloco,
      'estado': estado,
      'quartos': quartos,
      'banheiros': banheiros,
      'areaMetrosQuadrados': areaMetrosQuadrados,
      'observacoes': observacoes,
    };
  }
}

class AtualizarApartamentoRequest {
  final String? nome;
  final String? descricao;
  final String? numero;
  final int? andar;
  final String? bloco;
  final String? estado;
  final int? quartos;
  final int? banheiros;
  final double? areaMetrosQuadrados;
  final String? observacoes;

  AtualizarApartamentoRequest({
    this.nome,
    this.descricao,
    this.numero,
    this.andar,
    this.bloco,
    this.estado,
    this.quartos,
    this.banheiros,
    this.areaMetrosQuadrados,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nome != null) 'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (numero != null) 'numero': numero,
      if (andar != null) 'andar': andar,
      if (bloco != null) 'bloco': bloco,
      if (estado != null) 'estado': estado,
      if (quartos != null) 'quartos': quartos,
      if (banheiros != null) 'banheiros': banheiros,
      if (areaMetrosQuadrados != null) 'areaMetrosQuadrados': areaMetrosQuadrados,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}

class CriarItemApartamentoRequest {
  final String? apartamentoId;
  final String nome;
  final String? descricao;
  final String? tipo;
  final int? quantidade;
  final double? valorEstimado;
  final String? status;
  final String? codigoIdentificador;
  final String? codigoPatrimonio;
  final String? estadoAtual;
  final DateTime? dataAquisicao;
  final DateTime? dataEntradaNoApto;

  CriarItemApartamentoRequest({
    this.apartamentoId,
    required this.nome,
    this.descricao,
    this.tipo,
    this.quantidade,
    this.valorEstimado,
    this.status,
    this.codigoIdentificador,
    this.codigoPatrimonio,
    this.estadoAtual,
    this.dataAquisicao,
    this.dataEntradaNoApto,
  });

  Map<String, dynamic> toJson() {
    final estadoFinal = estadoAtual ?? status;
    // CodigoPatrimonio is server-generated — do not send it in create
    return {
      if (apartamentoId != null && apartamentoId!.trim().isNotEmpty)
        'apartamentoId': apartamentoId,
      'nome': nome,
      'descricao': descricao,
      if (tipo != null) 'tipo': tipo,
      if (quantidade != null) 'quantidade': quantidade,
      'estadoAtual': ?estadoFinal,
      if (dataAquisicao != null) 'dataAquisicao': toBackendUtcIsoString(dataAquisicao!),
      if (dataEntradaNoApto != null) 'dataEntradaNoApto': toBackendUtcIsoString(dataEntradaNoApto!),
    };
  }
}

/// Usuario DTOs
class AtualizarUsuarioRequest {
  final String? nome;
  final String? telefone;
  final String? tipo;
  final bool? ativo;

  AtualizarUsuarioRequest({
    this.nome,
    this.telefone,
    this.tipo,
    this.ativo,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nome != null) 'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (tipo != null) 'tipo': tipo,
      if (ativo != null) 'ativo': ativo,
    };
  }
}

class MudarSenhaRequest {
  final String senhaAtual;
  final String novaSenha;
  final String confirmarNovaSenha;

  MudarSenhaRequest({
    required this.senhaAtual,
    required this.novaSenha,
    required this.confirmarNovaSenha,
  });

  Map<String, dynamic> toJson() {
    return {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
      'confirmarNovaSenha': confirmarNovaSenha,
    };
  }
}

class SolicitarResetPasswordRequest {
  final String nomeLogin;

  SolicitarResetPasswordRequest({required this.nomeLogin});

  Map<String, dynamic> toJson() {
    return {'nomeLogin': nomeLogin};
  }
}

/// Create Morador (Resident) Request DTO
class CriarMoradorDto {
  final String nome;
  final String usuarioId;
  final String? apartamentoId;
  final bool? proprietario;
  final DateTime? dataEntrada;

  CriarMoradorDto({
    required this.nome,
    required this.usuarioId,
    this.apartamentoId,
    this.proprietario,
    this.dataEntrada,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'usuarioId': usuarioId,
      if (apartamentoId != null) 'apartamentoId': apartamentoId,
      if (proprietario != null) 'proprietario': proprietario,
      if (dataEntrada != null) 'dataEntrada': toBackendUtcIsoString(dataEntrada!),
    };
  }
}

/// Adicionar comentário a solicitação v2
class AdicionarComentarioV2Request {
  final String texto;

  AdicionarComentarioV2Request({required this.texto});

  Map<String, dynamic> toJson() {
    return {'texto': texto};
  }
}

/// Mudar status de solicitação v2
class MudarStatusSolicitacaoV2Request {
  final String status;

  MudarStatusSolicitacaoV2Request({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

/// Comentário v2 response (com autor e timestamp)
class ComentarioV2Dto {
  final String id;
  final String solicitacaoId;
  final String texto;
  final String usuarioId;
  final String nomeAutor;
  final DateTime criadoEm;

  ComentarioV2Dto({
    required this.id,
    required this.solicitacaoId,
    required this.texto,
    required this.usuarioId,
    required this.nomeAutor,
    required this.criadoEm,
  });

  factory ComentarioV2Dto.fromJson(Map<String, dynamic> json) {
    return ComentarioV2Dto(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      texto: json['texto'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      nomeAutor: json['nomeAutor'] ?? json['autor']?['nome'] ?? 'Anônimo',
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }

  ComentarioV2Dto copyWith({
    String? id,
    String? solicitacaoId,
    String? texto,
    String? usuarioId,
    String? nomeAutor,
    DateTime? criadoEm,
  }) {
    return ComentarioV2Dto(
      id: id ?? this.id,
      solicitacaoId: solicitacaoId ?? this.solicitacaoId,
      texto: texto ?? this.texto,
      usuarioId: usuarioId ?? this.usuarioId,
      nomeAutor: nomeAutor ?? this.nomeAutor,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}

/// Anexo v2 response
class AnexoV2Dto {
  final String id;
  final String solicitacaoId;
  final String nomeArquivo;
  final String url;
  final int tamanhoBytes;
  final String? tipoConteudo;
  final DateTime criadoEm;

  AnexoV2Dto({
    required this.id,
    required this.solicitacaoId,
    required this.nomeArquivo,
    required this.url,
    required this.tamanhoBytes,
    this.tipoConteudo,
    required this.criadoEm,
  });

  factory AnexoV2Dto.fromJson(Map<String, dynamic> json) {
    return AnexoV2Dto(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      nomeArquivo: json['nomeArquivo'] ?? '',
      url: json['url'] ?? '',
      tamanhoBytes: json['tamanhoBytes'] ?? 0,
      tipoConteudo: json['tipoConteudo'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }
}

/// Solicitação v2 list response (paged)
class SolicitacaoV2ListaDto {
  final List<SolicitacaoV2Resumo> items;
  final int total;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  SolicitacaoV2ListaDto({
    required this.items,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory SolicitacaoV2ListaDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoV2ListaDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SolicitacaoV2Resumo.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}

/// Solicitação v2 resumida (para lista)
class SolicitacaoV2Resumo {
  final String id;
  final String titulo;
  final String? descricao;
  final String status;
  final String? prioridade;
  final String? apartamentoId;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final String? nomeSolicitante;
  final String? nomeResponsavel;
  final String? nomeMorador;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final DateTime? prazoLimite;
  final int totalComentarios;
  final int totalAnexos;
  final String? nomeUsuarioCriador;

  SolicitacaoV2Resumo({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    this.prioridade,
    this.apartamentoId,
    this.numeroApartamento,
    this.blocoApartamento,
    this.nomeSolicitante,
    this.nomeResponsavel,
    this.nomeMorador,
    required this.criadoEm,
    this.atualizadoEm,
    this.prazoLimite,
    required this.totalComentarios,
    required this.totalAnexos,
    this.nomeUsuarioCriador,
  });

  factory SolicitacaoV2Resumo.fromJson(Map<String, dynamic> json) {
    return SolicitacaoV2Resumo(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      status: json['status'] ?? 'Pendente',
      prioridade: json['prioridade'],
      apartamentoId: json['apartamento']?['id'],
      numeroApartamento: json['apartamento']?['numero'],
      blocoApartamento: json['apartamento']?['bloco'],
      nomeSolicitante: json['solicitante']?['nome'],
      nomeResponsavel: json['responsavel']?['nome'],
      nomeMorador: json['morador']?['nome'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
      prazoLimite: tryParseBackendDateTimeToLocal(json['prazoLimite']),
      totalComentarios: json['totalComentarios'] ?? 0,
      totalAnexos: json['totalAnexos'] ?? 0,
      nomeUsuarioCriador: json['usuarioCriador']?['nome'] ?? json['nomeUsuarioCriador'],
    );
  }

  SolicitacaoV2Resumo copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? status,
    String? prioridade,
    String? apartamentoId,
    String? numeroApartamento,
    String? blocoApartamento,
    String? nomeSolicitante,
    String? nomeResponsavel,
    String? nomeMorador,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    DateTime? prazoLimite,
    int? totalComentarios,
    int? totalAnexos,
    String? nomeUsuarioCriador,
  }) {
    return SolicitacaoV2Resumo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      apartamentoId: apartamentoId ?? this.apartamentoId,
      numeroApartamento: numeroApartamento ?? this.numeroApartamento,
      blocoApartamento: blocoApartamento ?? this.blocoApartamento,
      nomeSolicitante: nomeSolicitante ?? this.nomeSolicitante,
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      nomeMorador: nomeMorador ?? this.nomeMorador,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      prazoLimite: prazoLimite ?? this.prazoLimite,
      totalComentarios: totalComentarios ?? this.totalComentarios,
      totalAnexos: totalAnexos ?? this.totalAnexos,
      nomeUsuarioCriador: nomeUsuarioCriador ?? this.nomeUsuarioCriador,
    );
  }
}

/// DTO para vincular morador ao apartamento
class VincularMoradorRequest {
  final String moradorId;
  final String apartamentoId;

  VincularMoradorRequest({
    required this.moradorId,
    required this.apartamentoId,
  });

  Map<String, dynamic> toJson() {
    return {
      'moradorId': moradorId,
      'apartamentoId': apartamentoId,
    };
  }
}

/// DTO para resposta de morador
class MoradorDto {
  final String id;
  final String nome;
  final String usuarioId;
  final String nomeUsuario;
  final DateTime criadoEm;

  MoradorDto({
    required this.id,
    required this.nome,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.criadoEm,
  });

  factory MoradorDto.fromJson(Map<String, dynamic> json) {
    return MoradorDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      nomeUsuario: json['nomeUsuario'] ?? '',
      criadoEm: json['criadoEm'] != null 
          ? parseBackendDateTimeToLocal(json['criadoEm']) 
          : DateTime.now(),
    );
  }
}







