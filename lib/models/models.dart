import 'enums.dart';
import '../utils/app_date_time.dart';

/// Usuário do sistema
class Usuario {
  final String id;
  final String nome;
  final String nomeLogin;
  final String telefone;
  final UsuarioTipo tipo;
  final bool ativo;
  final bool receberSms;
  final DateTime criadoEm;
  final DateTime? ultimoLoginEm;
  final MoradorInfo? moradorInfo;

  Usuario({
    required this.id,
    required this.nome,
    required this.nomeLogin,
    required this.telefone,
    required this.tipo,
    required this.ativo,
    this.receberSms = true,
    required this.criadoEm,
    this.ultimoLoginEm,
    this.moradorInfo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Converter tipo: pode ser string ou int (0=Admin, 1=Func, 2=Sindico, 3=Portaria, 4=Morador, 5=Visitante)
    UsuarioTipo tipo = UsuarioTipo.Morador;
    final tipoValue = json['tipo'];

    if (tipoValue is int) {
      // Se for número, mapear direto para o enum
      if (tipoValue >= 0 && tipoValue < UsuarioTipo.values.length) {
        tipo = UsuarioTipo.values[tipoValue];
      }
    } else if (tipoValue is String) {
      // Se for string, usar a conversão existente
      tipo = UsuarioTipoExtension.fromString(tipoValue);
    }

    return Usuario(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      nomeLogin: json['nomeLogin'] ?? '',
      telefone: json['telefone'] ?? '',
      tipo: tipo,
      ativo: json['ativo'] ?? false,
      receberSms: json['receberSms'] ?? true,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      ultimoLoginEm: tryParseBackendDateTimeToLocal(json['ultimoLoginEm']),
      moradorInfo: json['moradorInfo'] != null ? MoradorInfo.fromJson(json['moradorInfo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nomeLogin': nomeLogin,
      'telefone': telefone,
      'tipo': tipo.toPortuguese(),
      'ativo': ativo,
      'receberSms': receberSms,
      'criadoEm': toBackendUtcIsoString(criadoEm),
      'ultimoLoginEm': ultimoLoginEm != null ? toBackendUtcIsoString(ultimoLoginEm!) : null,
      'moradorInfo': moradorInfo?.toJson(),
    };
  }

  /// Creates a copy of Usuario with updated fields
  Usuario copyWith({
    String? id,
    String? nome,
    String? nomeLogin,
    String? telefone,
    UsuarioTipo? tipo,
    bool? ativo,
    bool? receberSms,
    DateTime? criadoEm,
    DateTime? ultimoLoginEm,
    MoradorInfo? moradorInfo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      nomeLogin: nomeLogin ?? this.nomeLogin,
      telefone: telefone ?? this.telefone,
      tipo: tipo ?? this.tipo,
      ativo: ativo ?? this.ativo,
      receberSms: receberSms ?? this.receberSms,
      criadoEm: criadoEm ?? this.criadoEm,
      ultimoLoginEm: ultimoLoginEm ?? this.ultimoLoginEm,
      moradorInfo: moradorInfo ?? this.moradorInfo,
    );
  }
}

/// Informações do morador para usuário
class MoradorInfo {
  final String moradorId;
  final String apartamentoId;
  final int numeroApartamento;
  final String blocoApartamento;

  MoradorInfo({
    required this.moradorId,
    required this.apartamentoId,
    required this.numeroApartamento,
    required this.blocoApartamento,
  });

  factory MoradorInfo.fromJson(Map<String, dynamic> json) {
    return MoradorInfo(
      moradorId: json['moradorId'] ?? '',
      apartamentoId: json['apartamentoId'] ?? '',
      numeroApartamento: json['numeroApartamento'] ?? 0,
      blocoApartamento: json['blocoApartamento'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moradorId': moradorId,
      'apartamentoId': apartamentoId,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
    };
  }
}

/// Apartamento
class Apartamento {
  final String id;
  final String nome;
  final String? descricao;
  final String numero;
  final int andar;
  final String bloco;
  final EstadoApartamento estado;
  final int quantidadeMoradores;
  final int? quartos;
  final int? banheiros;
  final double? areaMetrosQuadrados;
  final String? observacoes;
  final DateTime? criadoEm;
  final List<ItemApartamento>? itens;
  final List<Morador>? moradores;
  final bool emManutencao; // Flag automatica baseada em solicitacoes em andamento

  Apartamento({
    required this.id,
    required this.nome,
    this.descricao,
    required this.numero,
    required this.andar,
    required this.bloco,
    required this.estado,
    required this.quantidadeMoradores,
    this.quartos,
    this.banheiros,
    this.areaMetrosQuadrados,
    this.observacoes,
    this.criadoEm,
    this.itens,
    this.moradores,
    this.emManutencao = false,
  });

  factory Apartamento.fromJson(Map<String, dynamic> json) {
    return Apartamento(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? json['observacoes'],
      numero: json['numero'] ?? '',
      andar: json['andar'] ?? 0,
      bloco: json['bloco'] ?? '',
      estado: EstadoApartamentoExtension.fromString(json['estado'] ?? 'Disponivel'),
      quantidadeMoradores: json['quantidadeMoradores'] ?? 0,
      quartos: json['quartos'],
      banheiros: json['banheiros'],
      areaMetrosQuadrados: (json['areaMetrosQuadrados'] is num)
          ? (json['areaMetrosQuadrados'] as num).toDouble()
          : null,
      observacoes: json['observacoes'],
      criadoEm: tryParseBackendDateTimeToLocal(json['criadoEm']),
      itens: (json['itens'] as List<dynamic>?)?.map((item) => ItemApartamento.fromJson(item)).toList(),
      moradores: ((json['moradores'] ?? json['ocupantes']) as List<dynamic>?)?.map((m) => Morador.fromJson(m)).toList(),
      emManutencao: json['emManutencao'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'numero': numero,
      'andar': andar,
      'bloco': bloco,
      'estado': estado.toPortuguese(),
      'quantidadeMoradores': quantidadeMoradores,
      'quartos': quartos,
      'banheiros': banheiros,
      'areaMetrosQuadrados': areaMetrosQuadrados,
      'observacoes': observacoes,
      'criadoEm': criadoEm != null ? toBackendUtcIsoString(criadoEm!) : null,
      'itens': itens?.map((i) => i.toJson()).toList(),
      'moradores': moradores?.map((m) => m.toJson()).toList(),
      'emManutencao': emManutencao,
    };
  }

  Apartamento copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? numero,
    int? andar,
    String? bloco,
    EstadoApartamento? estado,
    int? quantidadeMoradores,
    int? quartos,
    int? banheiros,
    double? areaMetrosQuadrados,
    String? observacoes,
    DateTime? criadoEm,
    List<ItemApartamento>? itens,
    List<Morador>? moradores,
    bool? emManutencao,
  }) {
    return Apartamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      numero: numero ?? this.numero,
      andar: andar ?? this.andar,
      bloco: bloco ?? this.bloco,
      estado: estado ?? this.estado,
      quantidadeMoradores: quantidadeMoradores ?? this.quantidadeMoradores,
      quartos: quartos ?? this.quartos,
      banheiros: banheiros ?? this.banheiros,
      areaMetrosQuadrados: areaMetrosQuadrados ?? this.areaMetrosQuadrados,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      itens: itens ?? this.itens,
      moradores: moradores ?? this.moradores,
      emManutencao: emManutencao ?? this.emManutencao,
    );
  }
}

/// Morador
class Morador {
  final String id;
  final String nome;
  final String? usuarioId; // Nullable: morador pode estar sem conta vinculada
  final String? nomeUsuario;
  final String? apartamentoId;
  final bool? proprietario;
  final DateTime? dataEntrada;
  final DateTime criadoEm;

  Morador({
    required this.id,
    required this.nome,
    this.usuarioId, // Optional
    this.nomeUsuario,
    this.apartamentoId,
    this.proprietario,
    this.dataEntrada,
    required this.criadoEm,
  });

  factory Morador.fromJson(Map<String, dynamic> json) {
    String resolveNome(Map<String, dynamic> data) {
      String readText(dynamic value) => value?.toString().trim() ?? '';

      final direto = [
        readText(data['nome']),
        readText(data['nomeCompleto']),
        readText(data['nomeMorador']),
        readText(data['moradorNome']),
        readText(data['nomeUsuario']),
      ];
      for (final item in direto) {
        if (item.isNotEmpty) return item;
      }

      final usuario = data['usuario'];
      if (usuario is Map) {
        final nestedNome = readText(usuario['nome']);
        if (nestedNome.isNotEmpty) return nestedNome;
        final nestedNomeUsuario = readText(usuario['nomeUsuario']);
        if (nestedNomeUsuario.isNotEmpty) return nestedNomeUsuario;
      }

      return '';
    }

    return Morador(
      id: json['id'] ?? '',
      nome: resolveNome(json),
      usuarioId: json['usuarioId'], // Pode ser null
      nomeUsuario: json['nomeUsuario'] ?? json['usuario']?['nomeUsuario'],
      apartamentoId: json['apartamentoId'],
      proprietario: json['proprietario'],
      dataEntrada: tryParseBackendDateTimeToLocal(json['dataEntrada']),
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'usuarioId': usuarioId,
      'nomeUsuario': nomeUsuario,
      'apartamentoId': apartamentoId,
      'proprietario': proprietario,
      'dataEntrada': dataEntrada != null ? toBackendUtcIsoString(dataEntrada!) : null,
      'criadoEm': toBackendUtcIsoString(criadoEm),
    };
  }
}

class ItemApartamentoMovimentacaoResumo {
  final String id;
  final String? apartamentoOrigemId;
  final String? apartamentoDestinoId;
  final String? estadoAnterior;
  final String? estadoNovo;
  final String? motivo;
  final String? observacoes;
  final DateTime? criadoEm;

  const ItemApartamentoMovimentacaoResumo({
    required this.id,
    this.apartamentoOrigemId,
    this.apartamentoDestinoId,
    this.estadoAnterior,
    this.estadoNovo,
    this.motivo,
    this.observacoes,
    this.criadoEm,
  });

  factory ItemApartamentoMovimentacaoResumo.fromJson(Map<String, dynamic> json) {
    return ItemApartamentoMovimentacaoResumo(
      id: (json['id'] ?? '').toString(),
      apartamentoOrigemId: json['apartamentoOrigemId']?.toString(),
      apartamentoDestinoId: json['apartamentoDestinoId']?.toString(),
      estadoAnterior: json['estadoAnterior']?.toString(),
      estadoNovo: json['estadoNovo']?.toString(),
      motivo: json['motivo']?.toString(),
      observacoes: json['observacoes']?.toString(),
      criadoEm: _parseDateTime(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'apartamentoOrigemId': apartamentoOrigemId,
    'apartamentoDestinoId': apartamentoDestinoId,
    'estadoAnterior': estadoAnterior,
    'estadoNovo': estadoNovo,
    'motivo': motivo,
    'observacoes': observacoes,
    'criadoEm': criadoEm != null ? toBackendUtcIsoString(criadoEm!) : null,
  };
}

class ItemApartamentoManutencaoResumo {
  final String id;
  final String? status;
  final String? tipo;
  final String? descricao;
  final String? observacoes;
  final DateTime? dataAgendada;
  final DateTime? dataExecucao;
  final DateTime? criadoEm;

  const ItemApartamentoManutencaoResumo({
    required this.id,
    this.status,
    this.tipo,
    this.descricao,
    this.observacoes,
    this.dataAgendada,
    this.dataExecucao,
    this.criadoEm,
  });

  factory ItemApartamentoManutencaoResumo.fromJson(Map<String, dynamic> json) {
    return ItemApartamentoManutencaoResumo(
      id: (json['id'] ?? '').toString(),
      status: json['status']?.toString(),
      tipo: json['tipo']?.toString(),
      descricao: json['descricao']?.toString(),
      observacoes: json['observacoes']?.toString(),
      dataAgendada: _parseDateTime(json['dataAgendada']),
      dataExecucao: _parseDateTime(json['dataExecucao']),
      criadoEm: _parseDateTime(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'tipo': tipo,
    'descricao': descricao,
    'observacoes': observacoes,
    'dataAgendada': dataAgendada != null ? toBackendUtcIsoString(dataAgendada!) : null,
    'dataExecucao': dataExecucao != null ? toBackendUtcIsoString(dataExecucao!) : null,
    'criadoEm': criadoEm != null ? toBackendUtcIsoString(criadoEm!) : null,
  };
}

DateTime? _parseDateTime(dynamic value) {
  return tryParseBackendDateTimeToLocal(value);
}

/// Item de apartamento
class ItemApartamento {
  final String id;
  final String nome;
  final String? descricao;
  final String? apartamentoId;
  final String? tipo;
  final int? quantidade;
  final String? status;
  final double? valorEstimado;
  final DateTime? criadoEm;
  final String? codigoIdentificador;
  final String? codigoPatrimonio;
  final DateTime? ultimaMovimentacao;
  final String? estadoDesgaste;
  final String? estadoAtual;
  final DateTime? dataAquisicao;
  final DateTime? dataEntradaNoApto;
  final List<ItemApartamentoMovimentacaoResumo> historicoMovimentacoes;
  final List<ItemApartamentoManutencaoResumo> manutencoes;

  ItemApartamento({
    required this.id,
    required this.nome,
    this.descricao,
    this.apartamentoId,
    this.tipo,
    this.quantidade,
    this.status,
    this.valorEstimado,
    this.criadoEm,
    this.codigoIdentificador,
    this.codigoPatrimonio,
    this.ultimaMovimentacao,
    this.estadoDesgaste,
    this.estadoAtual,
    this.dataAquisicao,
    this.dataEntradaNoApto,
    this.historicoMovimentacoes = const [],
    this.manutencoes = const [],
  });

  factory ItemApartamento.fromJson(Map<String, dynamic> json) {
    final historicoRaw = json['historicoMovimentacoes'] ?? json['historico'] ?? json['movimentacoes'];
    final manutencoesRaw = json['manutencoes'] ?? json['historicoManutencoes'];

    return ItemApartamento(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      apartamentoId: json['apartamentoId']?.toString()
          ?? (json['apartamento'] is Map ? json['apartamento']['id']?.toString() : null),
      tipo: json['tipo']?.toString(),
      quantidade: json['quantidade'] is num ? (json['quantidade'] as num).toInt() : null,
      status: json['status']?.toString(),
      valorEstimado: (json['valorEstimado'] is num) ? (json['valorEstimado'] as num).toDouble() : null,
      criadoEm: _parseDateTime(json['criadoEm']),
      codigoIdentificador: json['codigoIdentificador']?.toString() ?? json['codigoPatrimonio']?.toString(),
      codigoPatrimonio: json['codigoPatrimonio']?.toString() ?? json['codigoIdentificador']?.toString(),
      ultimaMovimentacao: _parseDateTime(json['ultimaMovimentacao']),
      estadoDesgaste: json['estadoDesgaste']?.toString() ?? json['estadoAtual']?.toString(),
      estadoAtual: json['estadoAtual']?.toString() ?? json['estadoDesgaste']?.toString(),
      dataAquisicao: _parseDateTime(json['dataAquisicao']),
      dataEntradaNoApto: _parseDateTime(json['dataEntradaNoApto'] ?? json['dataEntradaNoApartamento']),
      historicoMovimentacoes: historicoRaw is List
          ? historicoRaw
                .whereType<Map<String, dynamic>>()
                .map(ItemApartamentoMovimentacaoResumo.fromJson)
                .toList()
          : const [],
      manutencoes: manutencoesRaw is List
          ? manutencoesRaw
                .whereType<Map<String, dynamic>>()
                .map(ItemApartamentoManutencaoResumo.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'apartamentoId': apartamentoId,
      'tipo': tipo,
      'quantidade': quantidade,
      'status': status,
      'valorEstimado': valorEstimado,
      'criadoEm': criadoEm != null ? toBackendUtcIsoString(criadoEm!) : null,
      'codigoIdentificador': codigoIdentificador,
      'codigoPatrimonio': codigoPatrimonio,
      'ultimaMovimentacao': ultimaMovimentacao != null ? toBackendUtcIsoString(ultimaMovimentacao!) : null,
      'estadoDesgaste': estadoDesgaste,
      'estadoAtual': estadoAtual,
      'dataAquisicao': dataAquisicao != null ? toBackendUtcIsoString(dataAquisicao!) : null,
      'dataEntradaNoApto': dataEntradaNoApto != null ? toBackendUtcIsoString(dataEntradaNoApto!) : null,
      'historicoMovimentacoes': historicoMovimentacoes.map((e) => e.toJson()).toList(),
      'manutencoes': manutencoes.map((e) => e.toJson()).toList(),
    };
  }

  ItemApartamento copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? apartamentoId,
    String? tipo,
    int? quantidade,
    String? status,
    double? valorEstimado,
    DateTime? criadoEm,
    String? codigoIdentificador,
    String? codigoPatrimonio,
    DateTime? ultimaMovimentacao,
    String? estadoDesgaste,
    String? estadoAtual,
    DateTime? dataAquisicao,
    DateTime? dataEntradaNoApto,
    List<ItemApartamentoMovimentacaoResumo>? historicoMovimentacoes,
    List<ItemApartamentoManutencaoResumo>? manutencoes,
  }) {
    return ItemApartamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      apartamentoId: apartamentoId ?? this.apartamentoId,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      status: status ?? this.status,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      criadoEm: criadoEm ?? this.criadoEm,
      codigoIdentificador: codigoIdentificador ?? this.codigoIdentificador,
      codigoPatrimonio: codigoPatrimonio ?? this.codigoPatrimonio,
      ultimaMovimentacao: ultimaMovimentacao ?? this.ultimaMovimentacao,
      estadoDesgaste: estadoDesgaste ?? this.estadoDesgaste,
      estadoAtual: estadoAtual ?? this.estadoAtual,
      dataAquisicao: dataAquisicao ?? this.dataAquisicao,
      dataEntradaNoApto: dataEntradaNoApto ?? this.dataEntradaNoApto,
      historicoMovimentacoes: historicoMovimentacoes ?? this.historicoMovimentacoes,
      manutencoes: manutencoes ?? this.manutencoes,
    );
  }
}

/// Solicitação de manutenção
class Solicitacao {
  final String id;
  final String titulo;
  final String? descricao;
  final StatusSolicitacao status;
  final String? usuarioCriadorId;
  final String? nomeUsuarioCriador;
  final String? responsavelId;
  final String? nomeResponsavel;
  final String? moradorId;
  final String? nomeMorador;
  final String? apartamentoId;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final DateTime? concluidoEm;
  final DateTime? prazoLimite;
  final List<Comentario>? comentarios;
  final List<HistoricoStatus>? historicoStatus;
  final List<Anexo>? anexos;
  final int? quantidadeComentarios;
  final int? quantidadeAnexos;

  Solicitacao({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    this.usuarioCriadorId,
    this.nomeUsuarioCriador,
    this.responsavelId,
    this.nomeResponsavel,
    this.moradorId,
    this.nomeMorador,
    this.apartamentoId,
    this.numeroApartamento,
    this.blocoApartamento,
    required this.criadoEm,
    this.atualizadoEm,
    this.concluidoEm,
    this.prazoLimite,
    this.comentarios,
    this.historicoStatus,
    this.anexos,
    this.quantidadeComentarios,
    this.quantidadeAnexos,
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      status: StatusSolicitacaoExtension.fromString(json['status'] ?? 'Pendente'),
      usuarioCriadorId: json['usuarioCriadorId'],
      nomeUsuarioCriador: json['nomeUsuarioCriador'],
      responsavelId: json['responsavelId'],
      nomeResponsavel: json['nomeResponsavel'],
      moradorId: json['moradorId'],
      nomeMorador: json['nomeMorador'],
      apartamentoId: json['apartamentoId'],
      numeroApartamento: json['numeroApartamento'],
      blocoApartamento: json['blocoApartamento'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
      concluidoEm: tryParseBackendDateTimeToLocal(json['concluidoEm']),
      prazoLimite: tryParseBackendDateTimeToLocal(json['prazoLimite']),
      comentarios: (json['comentarios'] as List<dynamic>?)?.map((c) => Comentario.fromJson(c)).toList(),
      historicoStatus: (json['historicoStatus'] as List<dynamic>?)?.map((h) => HistoricoStatus.fromJson(h)).toList(),
      anexos: (json['anexos'] as List<dynamic>?)?.map((a) => Anexo.fromJson(a)).toList(),
      quantidadeComentarios: json['quantidadeComentarios'],
      quantidadeAnexos: json['quantidadeAnexos'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'status': status.toPortuguese(),
      'usuarioCriadorId': usuarioCriadorId,
      'nomeUsuarioCriador': nomeUsuarioCriador,
      'responsavelId': responsavelId,
      'nomeResponsavel': nomeResponsavel,
      'moradorId': moradorId,
      'nomeMorador': nomeMorador,
      'apartamentoId': apartamentoId,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
      'criadoEm': toBackendUtcIsoString(criadoEm),
      'atualizadoEm': atualizadoEm != null ? toBackendUtcIsoString(atualizadoEm!) : null,
      'concluidoEm': concluidoEm != null ? toBackendUtcIsoString(concluidoEm!) : null,
      'prazoLimite': prazoLimite != null ? toBackendUtcIsoString(prazoLimite!) : null,
      'comentarios': comentarios?.map((c) => c.toJson()).toList(),
      'historicoStatus': historicoStatus?.map((h) => h.toJson()).toList(),
      'anexos': anexos?.map((a) => a.toJson()).toList(),
    };
  }

  /// Calcula os dias restantes até o prazo limite
  int? get diasRestantes {
    if (prazoLimite == null) return null;
    return prazoLimite!.difference(DateTime.now()).inDays;
  }

  /// Verifica se o prazo está vencido
  bool get prazoVencido {
    if (prazoLimite == null) return false;
    return DateTime.now().isAfter(prazoLimite!);
  }

  /// Verifica se o prazo está próximo de vencer (3 dias)
  bool get prazoProximoVencer {
    if (prazoLimite == null) return false;
    final diasRestantes = this.diasRestantes ?? 0;
    return diasRestantes <= 3 && diasRestantes > 0;
  }
}

/// Comentário de solicitação
class Comentario {
  final String id;
  final String solicitacaoId;
  final String usuarioId;
  final String nomeUsuario;
  final String tipoUsuario;
  final String mensagem;
  final bool interno;
  final DateTime criadoEm;

  Comentario({
    required this.id,
    required this.solicitacaoId,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.tipoUsuario,
    required this.mensagem,
    required this.interno,
    required this.criadoEm,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      nomeUsuario: json['nomeUsuario'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      mensagem: json['mensagem'] ?? '',
      interno: json['interno'] ?? false,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solicitacaoId': solicitacaoId,
      'usuarioId': usuarioId,
      'nomeUsuario': nomeUsuario,
      'tipoUsuario': tipoUsuario,
      'mensagem': mensagem,
      'interno': interno,
      'criadoEm': toBackendUtcIsoString(criadoEm),
    };
  }
}

/// Histórico de status de solicitação
class HistoricoStatus {
  final String id;
  final String solicitacaoId;
  final StatusSolicitacao status;
  final String usuarioId;
  final String nomeUsuario;
  final String tipoUsuario;
  final DateTime alteradoEm;

  HistoricoStatus({
    required this.id,
    required this.solicitacaoId,
    required this.status,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.tipoUsuario,
    required this.alteradoEm,
  });

  factory HistoricoStatus.fromJson(Map<String, dynamic> json) {
    return HistoricoStatus(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      status: StatusSolicitacaoExtension.fromString(json['status'] ?? 'Pendente'),
      usuarioId: json['usuarioId'] ?? '',
      nomeUsuario: json['nomeUsuario'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      alteradoEm: parseBackendDateTimeToLocal(json['alteradoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solicitacaoId': solicitacaoId,
      'status': status.toPortuguese(),
      'usuarioId': usuarioId,
      'nomeUsuario': nomeUsuario,
      'tipoUsuario': tipoUsuario,
      'alteradoEm': toBackendUtcIsoString(alteradoEm),
    };
  }
}

/// Anexo de solicitação
class Anexo {
  final String id;
  final String solicitacaoId;
  final String nomeArquivo;
  final String url;
  final int tamanhoBytes;
  final String? tamanhoFormatado;
  final String tipoConteudo;
  final DateTime criadoEm;

  Anexo({
    required this.id,
    required this.solicitacaoId,
    required this.nomeArquivo,
    required this.url,
    required this.tamanhoBytes,
    this.tamanhoFormatado,
    required this.tipoConteudo,
    required this.criadoEm,
  });

  factory Anexo.fromJson(Map<String, dynamic> json) {
    return Anexo(
      id: json['id'] ?? '',
      solicitacaoId: json['solicitacaoId'] ?? '',
      nomeArquivo: json['nomeArquivo'] ?? '',
      url: json['url'] ?? '',
      tamanhoBytes: json['tamanhoBytes'] ?? 0,
      tamanhoFormatado: json['tamanhoFormatado'],
      tipoConteudo: json['tipoConteudo'] ?? '',
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solicitacaoId': solicitacaoId,
      'nomeArquivo': nomeArquivo,
      'url': url,
      'tamanhoBytes': tamanhoBytes,
      'tamanhoFormatado': tamanhoFormatado,
      'tipoConteudo': tipoConteudo,
      'criadoEm': toBackendUtcIsoString(criadoEm),
    };
  }
}

/// Notificação
class Notificacao {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensagem;
  final TipoNotificacao tipo;
  final String? tipoRaw;
  final bool lida;
  final DateTime criadoEm;
  final String? solicitacaoId;
  final String? comentarioId;
  final String? apartamentoId;
  final String? agendamentoId;
  final String? nomeRemetente;

  Notificacao({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    this.tipoRaw,
    required this.lida,
    required this.criadoEm,
    this.solicitacaoId,
    this.comentarioId,
    this.apartamentoId,
    this.agendamentoId,
    this.nomeRemetente,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    String? normalizeId(String? raw) {
      if (raw == null) return null;
      var value = raw.trim();
      if (value.isEmpty) return null;

      const uuidPattern =
          r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
      final uuidRegex = RegExp(uuidPattern);
      final uuid = uuidRegex.firstMatch(value)?.group(0);
      if (uuid != null) return uuid;

      bool looksLikeId(String candidate) {
        if (candidate.length < 8) return false;
        if (!RegExp(r'[0-9]').hasMatch(candidate)) return false;
        return RegExp(r'^[a-zA-Z0-9\-]+$').hasMatch(candidate);
      }

      if (value.contains('?')) {
        value = value.split('?').first;
      }

      final parts =
          value.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final last = parts.last.trim();
        if (last.isNotEmpty) {
          final uuidLast = uuidRegex.firstMatch(last)?.group(0);
          if (uuidLast != null) return uuidLast;
          if (looksLikeId(last)) return last;
        }
      }

      return looksLikeId(value) ? value : null;
    }

    Map<String, String?> extractIdsFromLink(String? raw) {
      String? solicitacaoId;
      String? comentarioId;

      if (raw == null || raw.trim().isEmpty) {
        return {'solicitacaoId': null, 'comentarioId': null};
      }

      var value = raw.trim();
      if (value.contains('?')) {
        value = value.split('?').first;
      }

      final segments = value.split('/').where((s) => s.trim().isNotEmpty).toList();
      for (var i = 0; i < segments.length - 1; i++) {
        final key = segments[i].toLowerCase();
        final next = segments[i + 1];
        if (key.contains('solicit')) {
          solicitacaoId ??= normalizeId(next);
        } else if (key.contains('coment')) {
          comentarioId ??= normalizeId(next);
        }
      }

      const uuidPattern =
          r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
      final matches =
          RegExp(uuidPattern).allMatches(raw).map((m) => m.group(0)!).toList();

      if (solicitacaoId == null && matches.isNotEmpty) {
        solicitacaoId = matches.first;
      }
      if (comentarioId == null && matches.length > 1) {
        comentarioId = matches.last;
      }

      return {'solicitacaoId': solicitacaoId, 'comentarioId': comentarioId};
    }

    final rawTipo = (json['tipo'] ?? 'Sistema').toString();
    final link = (json['solicitacaoId'] ??
            json['entidadeRelacionadaId'] ??
            json['link'])
        ?.toString();
    final tipoContexto = '$rawTipo ${link ?? ''}'.trim();
    final parsedIds = extractIdsFromLink(link);
    final tipoLower = rawTipo.toLowerCase();
    // Determine entity IDs based on notification type
    String? solicId;
    String? agendId;
    String? comentarioId = normalizeId(json['comentarioId']?.toString()) ??
        parsedIds['comentarioId'];
    String? aptoId = normalizeId(json['apartamentoId']?.toString());
    if (tipoLower.contains('agendamento')) {
      agendId = normalizeId(json['agendamentoId']?.toString()) ?? normalizeId(link);
    } else if (tipoLower.contains('apartamento')) {
      aptoId ??= normalizeId(link);
    } else {
      solicId = normalizeId(json['solicitacaoId']?.toString()) ??
          parsedIds['solicitacaoId'] ??
          normalizeId(link);
    }
    return Notificacao(
      id: json['id'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      tipo: _getTipoNotificacao(rawTipo),
      tipoRaw: tipoContexto.isNotEmpty ? tipoContexto : rawTipo,
      lida: json['lida'] ?? false,
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      apartamentoId: aptoId,
      solicitacaoId: solicId,
      comentarioId: comentarioId,
      agendamentoId: agendId,
      nomeRemetente: json['nomeRemetente'] ?? json['remetente']?['nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo.toPortuguese(),
      'lida': lida,
      'criadoEm': toBackendUtcIsoString(criadoEm),
      if (solicitacaoId != null) 'solicitacaoId': solicitacaoId,
      if (comentarioId != null) 'comentarioId': comentarioId,
      if (apartamentoId != null) 'apartamentoId': apartamentoId,
      if (agendamentoId != null) 'agendamentoId': agendamentoId,
    };
  }
}

TipoNotificacao _getTipoNotificacao(String value) {
  final v = value.toLowerCase();

  if (v.contains('novocomentario') || v.contains('novocomentario')) return TipoNotificacao.NovoComentario;
  if (v.contains('aberturasolicitacao') || v.contains('abertura') || v.contains('aberturasolicitação')) return TipoNotificacao.AberturaSolicitacao;
  if (v.contains('mudancastatus') || v.contains('mudanca') || v.contains('status')) return TipoNotificacao.MudancaStatus;
  if (v.contains('atribuicaoresponsavel') || v.contains('atribuicao') || v.contains('responsavel')) return TipoNotificacao.AtribuicaoResponsavel;
  if (v.contains('alteracaoprazo') || v.contains('prazo')) return TipoNotificacao.AlteracaoPrazo;
  if (v.contains('novasolicitacao') || v.contains('novasolicitacaocriada')) return TipoNotificacao.NovasolicitacaoCriada;
  // Backend may send maintenance / preventive maintenance types — map to 'Nova Solicitação' icon
  if (v.contains('manutencao') || v.contains('manutencaopreventiva') || v.contains('manutencao_preventiva')) return TipoNotificacao.NovasolicitacaoCriada;
  // Agendamento notifications map to new solicitation / appointment icon
  if (v.contains('agendamento') || v.contains('agendamentomanutencao') || v.contains('agendamento_manutencao')) return TipoNotificacao.NovasolicitacaoCriada;
  if (v.contains('sms') || v.contains('sms_massa') || v.contains('smsmassa') || v.contains('comunicado')) return TipoNotificacao.Sistema;
  if (v.contains('aviso')) return TipoNotificacao.Aviso;

  return TipoNotificacao.Sistema;
}

/// Histórico de Ocupação (Morador em Apartamento)
class HistoricoOcupacao {
  final String id;
  final String moradorId;
  final String nomeMorador;
  final String apartamentoId;
  final String? numeroApartamento;
  final String? blocoApartamento;
  final DateTime dataEntrada;
  final DateTime? dataSaida;
  final String? motivoSaida;
  final DateTime criadoEm;

  HistoricoOcupacao({
    required this.id,
    required this.moradorId,
    required this.nomeMorador,
    required this.apartamentoId,
    this.numeroApartamento,
    this.blocoApartamento,
    required this.dataEntrada,
    this.dataSaida,
    this.motivoSaida,
    required this.criadoEm,
  });

  factory HistoricoOcupacao.fromJson(Map<String, dynamic> json) {
    // Parse nomeMorador with fallbacks for different backend naming conventions
    final nomeMorador = json['nomeMorador'] as String? ??
        json['NomeMorador'] as String? ??
        json['nome_morador'] as String? ??
        json['nomeResidente'] as String? ??
        json['NomeResidente'] as String? ??
        json['residenteNome'] as String? ??
        json['moradorNome'] as String? ??
        json['MoradorNome'] as String? ??
        '';

    return HistoricoOcupacao(
      id: json['id'] ?? json['Id'] ?? '',
      moradorId: json['moradorId'] ?? json['MoradorId'] ?? '',
      nomeMorador: nomeMorador,
      apartamentoId: json['apartamentoId'] ?? json['ApartamentoId'] ?? '',
      numeroApartamento: json['numeroApartamento'] ?? json['NumeroApartamento'],
      blocoApartamento: json['blocoApartamento'] ?? json['BlocoApartamento'],
      dataEntrada: parseBackendDateTimeToLocal(json['dataEntrada'] ?? json['DataEntrada']),
      dataSaida: json['dataSaida'] != null 
          ? parseBackendDateTimeToLocal(json['dataSaida']) 
          : json['DataSaida'] != null 
              ? parseBackendDateTimeToLocal(json['DataSaida']) 
              : null,
      motivoSaida: json['motivoSaida'] ?? json['MotivoSaida'],
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm'] ?? json['CriadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moradorId': moradorId,
      'nomeMorador': nomeMorador,
      'apartamentoId': apartamentoId,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
      'dataEntrada': toBackendUtcIsoString(dataEntrada),
      'dataSaida': dataSaida != null ? toBackendUtcIsoString(dataSaida!) : null,
      'motivoSaida': motivoSaida,
      'criadoEm': toBackendUtcIsoString(criadoEm),
    };
  }

  HistoricoOcupacao copyWith({
    String? id,
    String? moradorId,
    String? nomeMorador,
    String? apartamentoId,
    String? numeroApartamento,
    String? blocoApartamento,
    DateTime? dataEntrada,
    DateTime? dataSaida,
    String? motivoSaida,
    DateTime? criadoEm,
  }) {
    return HistoricoOcupacao(
      id: id ?? this.id,
      moradorId: moradorId ?? this.moradorId,
      nomeMorador: nomeMorador ?? this.nomeMorador,
      apartamentoId: apartamentoId ?? this.apartamentoId,
      numeroApartamento: numeroApartamento ?? this.numeroApartamento,
      blocoApartamento: blocoApartamento ?? this.blocoApartamento,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      dataSaida: dataSaida ?? this.dataSaida,
      motivoSaida: motivoSaida ?? this.motivoSaida,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  /// Calcula quantos dias o morador ficou/está no apartamento
  int get diasOcupacao {
    final fim = dataSaida ?? DateTime.now();
    return fim.difference(dataEntrada).inDays;
  }

  /// Verifica se o morador ainda está ocupando o apartamento
  bool get estaAtivo => dataSaida == null;

  /// Retorna texto formatado da duração
  String get duracaoFormatada {
    final dias = diasOcupacao;
    if (dias < 30) return '$dias dias';
    if (dias < 365) return '${(dias / 30).floor()} meses';
    return '${(dias / 365).floor()} anos';
  }
}
