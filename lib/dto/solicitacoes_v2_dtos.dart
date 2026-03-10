// ============================================================================
// SOLICITAÇÕES V2 - DTOs COMPLETOS
// Criado: 27/01/2026
// Status: ✅ PRONTO PARA PRODUÇÃO
// ============================================================================

import 'area_tecnica_dto.dart';
import '../utils/app_date_time.dart';

DateTime _parseBackendDateTimeToLocal(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return DateTime.now();

  // Alguns ambientes retornam datetime sem timezone; tratamos como UTC.
  final normalized = value.replaceFirst(' ', 'T');
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
  final toParse = hasTimezone ? normalized : '${normalized}Z';

  try {
    return DateTime.parse(toParse).toLocal();
  } catch (_) {
    return DateTime.tryParse(normalized)?.toLocal() ?? DateTime.now();
  }
}

// ============================================================================
// 1. SolicitacaoListaDto - Para listagem paginada
// ============================================================================
class SolicitacaoListaDto {
  final String id;
  final String titulo;
  final String status;
  final String nomeUsuarioCriador;
  final String? nomeResponsavel;
  final String? responsavelId;
  final String numeroApartamento;
  final String blocoApartamento;
  final DateTime criadoEm;
  final DateTime? prazoLimite;
  final int quantidadeComentarios;
  final int quantidadeAnexos;
  final String? tipoSolicitacaoNome;
  final String? areaTecnicaNome;
  final String? itemApartamentoId;
  final String? itemApartamentoNome;

  SolicitacaoListaDto({
    required this.id,
    required this.titulo,
    required this.status,
    required this.nomeUsuarioCriador,
    this.nomeResponsavel,
    this.responsavelId,
    required this.numeroApartamento,
    required this.blocoApartamento,
    required this.criadoEm,
    this.prazoLimite,
    required this.quantidadeComentarios,
    required this.quantidadeAnexos,
    this.tipoSolicitacaoNome,
    this.areaTecnicaNome,
    this.itemApartamentoId,
    this.itemApartamentoNome,
  });

  factory SolicitacaoListaDto.fromJson(Map<String, dynamic> json) {
    return SolicitacaoListaDto(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      status: json['status'] as String,
      nomeUsuarioCriador: json['nomeUsuarioCriador'] as String,
      nomeResponsavel: json['nomeResponsavel'] as String?,
      responsavelId: json['responsavelId'] as String?,
      numeroApartamento: json['numeroApartamento'] as String,
      blocoApartamento: json['blocoApartamento'] as String,
      criadoEm: _parseBackendDateTimeToLocal(json['criadoEm'] as String),
      prazoLimite: json['prazoLimite'] != null
          ? _parseBackendDateTimeToLocal(json['prazoLimite'] as String)
          : null,
      quantidadeComentarios: json['quantidadeComentarios'] as int? ?? 0,
      quantidadeAnexos: json['quantidadeAnexos'] as int? ?? 0,
      tipoSolicitacaoNome: json['tipoSolicitacaoNome'] as String? ??
          json['TipoSolicitacaoNome'] as String?,
      areaTecnicaNome: json['areaTecnicaNome'] as String? ??
          json['AreaTecnicaNome'] as String?,
      itemApartamentoId: json['itemApartamentoId'] as String?,
      itemApartamentoNome: json['itemApartamentoNome'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'status': status,
      'nomeUsuarioCriador': nomeUsuarioCriador,
      'nomeResponsavel': nomeResponsavel,
      'responsavelId': responsavelId,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
      'criadoEm': toBackendUtcIsoString(criadoEm),
      'prazoLimite': prazoLimite != null ? toBackendUtcIsoString(prazoLimite!) : null,
      'quantidadeComentarios': quantidadeComentarios,
      'quantidadeAnexos': quantidadeAnexos,
      'tipoSolicitacaoNome': tipoSolicitacaoNome,
      'areaTecnicaNome': areaTecnicaNome,
      'itemApartamentoId': itemApartamentoId,
      'itemApartamentoNome': itemApartamentoNome,
    };
  }

  @override
  String toString() =>
      'SolicitacaoListaDto(id: $id, titulo: $titulo, status: $status)';
}

// ============================================================================
// 2. SolicitacaoDto - Para detalhes completos
// ============================================================================
class SolicitacaoDto {
  final String id;
  final String titulo;
  final String? descricao;
  final String status;
  final String? tipoSolicitacaoId;
  final String? tipoSolicitacaoNome;
  final List<String> areaTecnicaIds;
  final List<String> areaTecnicaNomes;
  final String usuarioCriadorId;
  final String nomeUsuarioCriador;
  final String? responsavelId;
  final String? nomeResponsavel;
  final String moradorId;
  final String nomeMorador; // Mantido para compatibilidade
  final String apartamentoId;
  final String numeroApartamento;
  final String blocoApartamento;
  final String? itemApartamentoId;
  final String? itemApartamentoNome;
  final String? itemApartamentoCodigoPatrimonio;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final DateTime? concluidoEm;
  final DateTime? prazoLimite;
  final List<ComentarioDto> comentarios;
  final List<HistoricoStatusDto> historicoStatus;
  final List<AnexoDto> anexos;

  SolicitacaoDto({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    this.tipoSolicitacaoId,
    this.tipoSolicitacaoNome,
    this.areaTecnicaIds = const [],
    this.areaTecnicaNomes = const [],
    required this.usuarioCriadorId,
    required this.nomeUsuarioCriador,
    this.responsavelId,
    this.nomeResponsavel,
    required this.moradorId,
    required this.nomeMorador,
    required this.apartamentoId,
    required this.numeroApartamento,
    required this.blocoApartamento,
    this.itemApartamentoId,
    this.itemApartamentoNome,
    this.itemApartamentoCodigoPatrimonio,
    required this.criadoEm,
    this.atualizadoEm,
    this.concluidoEm,
    this.prazoLimite,
    required this.comentarios,
    required this.historicoStatus,
    required this.anexos,
  });

  factory SolicitacaoDto.fromJson(Map<String, dynamic> json) {
    String readText(dynamic value) => value?.toString().trim() ?? '';
    String? readNullable(dynamic value) {
      final text = readText(value);
      return text.isEmpty ? null : text;
    }

    // Extrai o nome do morador de formatos diferentes do backend
    String nomeMorador = '';
    final moradorRaw = json['morador'];
    if (moradorRaw is Map) {
      final moradorMap = Map<String, dynamic>.from(moradorRaw);
      final nestedCandidates = [
        readText(moradorMap['nome']),
        readText(moradorMap['nomeCompleto']),
        readText(moradorMap['nomeUsuario']),
        readText(moradorMap['nomeMorador']),
        readText(
          moradorMap['usuario'] is Map
              ? (moradorMap['usuario'] as Map)['nome']
              : null,
        ),
      ];
      for (final c in nestedCandidates) {
        if (c.isNotEmpty) {
          nomeMorador = c;
          break;
        }
      }
    }

    if (nomeMorador.isEmpty) {
      final directCandidates = [
        readText(json['nomeMorador']),
        readText(json['moradorNome']),
        readText(json['nomeUsuarioMorador']),
      ];
      for (final c in directCandidates) {
        if (c.isNotEmpty) {
          nomeMorador = c;
          break;
        }
      }
    }

    final tipoRaw = json['tipoSolicitacao'] ?? json['TipoSolicitacao'];
    final tipoSolicitacaoId = readNullable(
      json['tipoSolicitacaoId'] ??
          json['TipoSolicitacaoId'] ??
          json['tipoSolicitacaoID'] ??
          json['tipoId'] ??
          json['TipoId'] ??
          (tipoRaw is Map ? tipoRaw['id'] : null),
    );
    final tipoSolicitacaoNome = readNullable(
      json['tipoSolicitacaoNome'] ??
          json['TipoSolicitacaoNome'] ??
          json['nomeTipoSolicitacao'] ??
          json['NomeTipoSolicitacao'] ??
          json['tipoNome'] ??
          json['TipoNome'] ??
          (tipoRaw is Map ? tipoRaw['nome'] : null),
    );

    final areaIdSet = <String>{};
    final areaNomeSet = <String>{};

    void addAreaId(dynamic value) {
      final text = readText(value);
      if (text.isNotEmpty) areaIdSet.add(text);
    }

    void addAreaNome(dynamic value) {
      final text = readText(value);
      if (text.isNotEmpty) areaNomeSet.add(text);
    }

    void addFromRawList(dynamic raw) {
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            addAreaId(item['id']);
            addAreaId(item['areaTecnicaId']);
            addAreaNome(item['nome']);
            addAreaNome(item['nomeAreaTecnica']);
          } else {
            addAreaId(item);
            addAreaNome(item);
          }
        }
      } else if (raw is Map<String, dynamic>) {
        addAreaId(raw['id']);
        addAreaId(raw['areaTecnicaId']);
        addAreaNome(raw['nome']);
        addAreaNome(raw['nomeAreaTecnica']);
      } else if (raw is String) {
        raw
            .split(RegExp(r'[,;]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .forEach(addAreaNome);
      }
    }

    addAreaId(json['areaTecnicaId'] ?? json['AreaTecnicaId']);
    addAreaNome(json['areaTecnicaNome'] ?? json['AreaTecnicaNome']);
    addFromRawList(json['areaTecnicaIds'] ?? json['AreaTecnicaIds']);
    addFromRawList(json['areaTecnicaNomes'] ?? json['AreaTecnicaNomes']);
    addFromRawList(json['areasTecnicas'] ?? json['AreasTecnicas']);
    addFromRawList(json['areas'] ?? json['Areas']);
    addFromRawList(json['areasTecnica'] ?? json['AreasTecnica']);
    addFromRawList(json['areaTecnica'] ?? json['AreaTecnica']);

    return SolicitacaoDto(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      status: json['status'] as String,
      tipoSolicitacaoId: tipoSolicitacaoId,
      tipoSolicitacaoNome: tipoSolicitacaoNome,
      areaTecnicaIds: areaIdSet.toList(),
      areaTecnicaNomes: areaNomeSet.toList(),
      usuarioCriadorId: json['usuarioCriadorId'] as String,
      nomeUsuarioCriador: json['nomeUsuarioCriador'] as String,
      responsavelId: json['responsavelId'] as String?,
      nomeResponsavel: json['nomeResponsavel'] as String?,
      moradorId: json['moradorId'] as String,
      nomeMorador: nomeMorador,
      apartamentoId: json['apartamentoId'] as String,
      numeroApartamento: json['numeroApartamento'] as String,
      blocoApartamento: json['blocoApartamento'] as String,
      itemApartamentoId: json['itemApartamentoId'] as String?,
      itemApartamentoNome: json['itemApartamentoNome'] as String?,
      itemApartamentoCodigoPatrimonio: readNullable(
        json['itemApartamentoCodigoPatrimonio'] ??
            json['ItemApartamentoCodigoPatrimonio'] ??
            json['codigoPatrimonioItem'] ??
            json['CodigoPatrimonioItem'] ??
            json['itemCodigoPatrimonio'],
      ),
      criadoEm: _parseBackendDateTimeToLocal(json['criadoEm'] as String),
      atualizadoEm: json['atualizadoEm'] != null
          ? _parseBackendDateTimeToLocal(json['atualizadoEm'] as String)
          : null,
      concluidoEm: json['concluidoEm'] != null
          ? _parseBackendDateTimeToLocal(json['concluidoEm'] as String)
          : null,
      prazoLimite: json['prazoLimite'] != null
          ? _parseBackendDateTimeToLocal(json['prazoLimite'] as String)
          : null,
      comentarios:
          (json['comentarios'] as List<dynamic>?)
              ?.map((c) => ComentarioDto.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      historicoStatus:
          (json['historicoStatus'] as List<dynamic>?)
              ?.map(
                (h) => HistoricoStatusDto.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
      anexos:
          (json['anexos'] as List<dynamic>?)
              ?.map((a) => AnexoDto.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'status': status,
      'tipoSolicitacaoId': tipoSolicitacaoId,
      'tipoSolicitacaoNome': tipoSolicitacaoNome,
      'areaTecnicaIds': areaTecnicaIds,
      'areaTecnicaNomes': areaTecnicaNomes,
      'usuarioCriadorId': usuarioCriadorId,
      'nomeUsuarioCriador': nomeUsuarioCriador,
      'responsavelId': responsavelId,
      'nomeResponsavel': nomeResponsavel,
      'moradorId': moradorId,
      'nomeMorador': nomeMorador,
      'apartamentoId': apartamentoId,
      'numeroApartamento': numeroApartamento,
      'blocoApartamento': blocoApartamento,
      'itemApartamentoId': itemApartamentoId,
      'itemApartamentoNome': itemApartamentoNome,
      'itemApartamentoCodigoPatrimonio': itemApartamentoCodigoPatrimonio,
      'criadoEm': toBackendUtcIsoString(criadoEm),
      'atualizadoEm': atualizadoEm != null ? toBackendUtcIsoString(atualizadoEm!) : null,
      'concluidoEm': concluidoEm != null ? toBackendUtcIsoString(concluidoEm!) : null,
      'prazoLimite': prazoLimite != null ? toBackendUtcIsoString(prazoLimite!) : null,
      'comentarios': comentarios.map((c) => c.toJson()).toList(),
      'historicoStatus': historicoStatus.map((h) => h.toJson()).toList(),
      'anexos': anexos.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'SolicitacaoDto(id: $id, titulo: $titulo, status: $status)';
}

// ============================================================================
// 3. CriarSolicitacaoDto - Para criar nova solicitação
// ============================================================================
class CriarSolicitacaoDto {
  final String titulo;
  final String? descricao;
  final String? tipoId;
  final String? moradorId;
  final String? apartamentoId;
  final String? itemApartamentoId;
  final DateTime? prazoLimite;
  final String? areaTecnicaId; // opcional (backend com campo singular)
  final List<String>? areaTecnicaIds; // opcional

  CriarSolicitacaoDto({
    required this.titulo,
    this.descricao,
    this.tipoId,
    this.moradorId,
    this.apartamentoId,
    this.itemApartamentoId,
    this.prazoLimite,
    this.areaTecnicaId,
    this.areaTecnicaIds,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'titulo': titulo};
    // moradorId e apartamentoId: backend auto-popula para Morador
    if (moradorId != null && moradorId!.isNotEmpty) {
      json['moradorId'] = moradorId;
    }
    if (apartamentoId != null && apartamentoId!.isNotEmpty) {
      json['apartamentoId'] = apartamentoId;
    }
    // Apenas incluir campos opcionais se não forem nulos
    if (descricao != null && descricao!.isNotEmpty) {
      json['descricao'] = descricao;
    }
    final normalizedTipoId = tipoId?.trim();
    if (normalizedTipoId != null && normalizedTipoId.isNotEmpty) {
      // Compatibilidade entre nomes de propriedade do backend
      json['tipoSolicitacaoId'] = normalizedTipoId;
      json['TipoSolicitacaoId'] = normalizedTipoId;
      json['tipoId'] = normalizedTipoId;
    }
    if (prazoLimite != null) {
      json['prazoLimite'] = toBackendUtcIsoString(prazoLimite!);
    }
    if (itemApartamentoId != null && itemApartamentoId!.isNotEmpty) {
      json['itemApartamentoId'] = itemApartamentoId;
    }

    // Área técnica singular (modelo atual do banco)
    final normalizedAreaId = areaTecnicaId?.trim();
    final singleAreaId =
        (normalizedAreaId != null && normalizedAreaId.isNotEmpty)
        ? normalizedAreaId
        : ((areaTecnicaIds != null && areaTecnicaIds!.isNotEmpty)
              ? areaTecnicaIds!.first
              : null);
    if (singleAreaId != null && singleAreaId.isNotEmpty) {
      json['areaTecnicaId'] = singleAreaId;
      json['AreaTecnicaId'] = singleAreaId;
    }

    // Mantém também formato de lista para backends compatíveis
    final normalizedAreaIds = areaTecnicaIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (normalizedAreaIds != null && normalizedAreaIds.isNotEmpty) {
      json['areaTecnicaIds'] = normalizedAreaIds;
      json['AreaTecnicaIds'] = normalizedAreaIds;
    }
    return json;
  }

  @override
  String toString() => 'CriarSolicitacaoDto(titulo: $titulo)';
}

// ============================================================================
// 4. MudarStatusDto - Para mudar status
// ============================================================================
class MudarStatusDto {
  final String novoStatus;
  final String? comentario;

  MudarStatusDto({required this.novoStatus, this.comentario});

  Map<String, dynamic> toJson() {
    return {'novoStatus': novoStatus, 'comentario': comentario};
  }

  @override
  String toString() => 'MudarStatusDto(novoStatus: $novoStatus)';
}

// ============================================================================
// 5. CriarComentarioDto - Para adicionar comentário
// ============================================================================
class CriarComentarioDto {
  final String mensagem;
  final bool interno;

  CriarComentarioDto({required this.mensagem, this.interno = false});

  Map<String, dynamic> toJson() {
    return {'mensagem': mensagem, 'interno': interno};
  }

  @override
  String toString() =>
      'CriarComentarioDto(mensagem: $mensagem, interno: $interno)';
}

// ============================================================================
// 6. ComentarioDto - Comentário de solicitação
// ============================================================================
class ComentarioDto {
  final String id;
  final String solicitacaoId;
  final String usuarioId;
  final String nomeUsuario;
  final String tipoUsuario;
  final String mensagem;
  final bool interno;
  final DateTime criadoEm;
  final List<AnexoComentarioDto> anexos;

  ComentarioDto({
    required this.id,
    required this.solicitacaoId,
    required this.usuarioId,
    required this.nomeUsuario,
    required this.tipoUsuario,
    required this.mensagem,
    required this.interno,
    required this.criadoEm,
    List<AnexoComentarioDto>? anexos,
  }) : anexos = anexos ?? [];

  factory ComentarioDto.fromJson(Map<String, dynamic> json) {
    return ComentarioDto(
      id: json['id'] as String,
      solicitacaoId: json['solicitacaoId'] as String,
      usuarioId: json['usuarioId'] as String,
      nomeUsuario: json['nomeUsuario'] as String,
      tipoUsuario: json['tipoUsuario'] as String,
      mensagem: json['mensagem'] as String,
      interno: json['interno'] as bool? ?? false,
      criadoEm: _parseBackendDateTimeToLocal(json['criadoEm'] as String),
      anexos: (json['anexos'] as List<dynamic>?)
              ?.map((a) => AnexoComentarioDto.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
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
      'anexos': anexos.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'ComentarioDto(id: $id, nomeUsuario: $nomeUsuario, interno: $interno, anexos: ${anexos.length})';
}

// ============================================================================
// 6b. AnexoComentarioDto - Anexo vinculado a comentário
// ============================================================================
class AnexoComentarioDto {
  final String id;
  final String comentarioId;
  final String nomeArquivo;
  final String url;
  final int tamanhoBytes;
  final String tamanhoFormatado;
  final String tipoConteudo;
  final DateTime criadoEm;

  AnexoComentarioDto({
    required this.id,
    required this.comentarioId,
    required this.nomeArquivo,
    required this.url,
    required this.tamanhoBytes,
    required this.tamanhoFormatado,
    required this.tipoConteudo,
    required this.criadoEm,
  });

  factory AnexoComentarioDto.fromJson(Map<String, dynamic> json) {
    return AnexoComentarioDto(
      id: json['id']?.toString() ?? '',
      comentarioId: json['comentarioId']?.toString() ?? '',
      nomeArquivo: json['nomeArquivo']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      tamanhoBytes: (json['tamanhoBytes'] as num?)?.toInt() ?? 0,
      tamanhoFormatado: json['tamanhoFormatado']?.toString() ?? '',
      tipoConteudo: json['tipoConteudo']?.toString() ?? '',
      criadoEm: json['criadoEm'] != null
          ? _parseBackendDateTimeToLocal(json['criadoEm'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comentarioId': comentarioId,
      'nomeArquivo': nomeArquivo,
      'url': url,
      'tamanhoBytes': tamanhoBytes,
      'tamanhoFormatado': tamanhoFormatado,
      'tipoConteudo': tipoConteudo,
      'criadoEm': toBackendUtcIsoString(criadoEm),
    };
  }

  bool get isImagem =>
      tipoConteudo.startsWith('image/') ||
      nomeArquivo.toLowerCase().endsWith('.png') ||
      nomeArquivo.toLowerCase().endsWith('.jpg') ||
      nomeArquivo.toLowerCase().endsWith('.jpeg') ||
      nomeArquivo.toLowerCase().endsWith('.gif') ||
      nomeArquivo.toLowerCase().endsWith('.webp');

  bool get isPdf => nomeArquivo.toLowerCase().endsWith('.pdf');
  bool get isZip =>
      nomeArquivo.toLowerCase().endsWith('.zip') ||
      nomeArquivo.toLowerCase().endsWith('.rar');

  @override
  String toString() =>
      'AnexoComentarioDto(id: $id, nomeArquivo: $nomeArquivo, tamanho: $tamanhoFormatado)';
}

// ============================================================================
// 7. AnexoDto - Arquivo anexado
// ============================================================================
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

  factory AnexoDto.fromJson(Map<String, dynamic> json) {
    return AnexoDto(
      id: json['id'] as String,
      solicitacaoId: json['solicitacaoId'] as String,
      nomeArquivo: json['nomeArquivo'] as String,
      url: json['url'] as String,
      tamanhoBytes: json['tamanhoBytes'] as int,
      tamanhoFormatado: json['tamanhoFormatado'] as String,
      tipoConteudo: json['tipoConteudo'] as String,
      criadoEm: _parseBackendDateTimeToLocal(json['criadoEm'] as String),
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

  bool get isImagem =>
      tipoConteudo.startsWith('image/') ||
      nomeArquivo.endsWith('.png') ||
      nomeArquivo.endsWith('.jpg');

  @override
  String toString() =>
      'AnexoDto(id: $id, nomeArquivo: $nomeArquivo, tamanho: $tamanhoFormatado)';
}

// ============================================================================
// 8. HistoricoStatusDto - Histórico de mudanças de status
// ============================================================================
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

  factory HistoricoStatusDto.fromJson(Map<String, dynamic> json) {
    return HistoricoStatusDto(
      id: json['id'] as String,
      solicitacaoId: json['solicitacaoId'] as String,
      status: json['status'] as String,
      usuarioId: json['usuarioId'] as String,
      nomeUsuario: json['nomeUsuario'] as String,
      tipoUsuario: json['tipoUsuario'] as String,
      alteradoEm: _parseBackendDateTimeToLocal(json['alteradoEm'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'solicitacaoId': solicitacaoId,
      'status': status,
      'usuarioId': usuarioId,
      'nomeUsuario': nomeUsuario,
      'tipoUsuario': tipoUsuario,
      'alteradoEm': toBackendUtcIsoString(alteradoEm),
    };
  }

  @override
  String toString() =>
      'HistoricoStatusDto(status: $status, nomeUsuario: $nomeUsuario)';
}

// ============================================================================
// TipoSolicitacaoDto - tipo de solicitação (simples local model)
// ============================================================================
class TipoSolicitacaoDto {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final List<AreaTecnicaDto> areasTecnicas;

  TipoSolicitacaoDto({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.areasTecnicas = const [],
  });

  factory TipoSolicitacaoDto.fromJson(Map<String, dynamic> json) {
    final areasRaw =
        json['areasTecnicas'] ?? json['areas'] ?? json['areasTecnica'];
    List<AreaTecnicaDto> parsedAreas = [];
    if (areasRaw is List) {
      parsedAreas = areasRaw
          .whereType<Map<String, dynamic>>()
          .map((a) => AreaTecnicaDto.fromJson(a))
          .toList();
    }

    return TipoSolicitacaoDto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      areasTecnicas: parsedAreas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'areasTecnicas': areasTecnicas.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'TipoSolicitacaoDto(id: $id, nome: $nome, ativo: $ativo)';
}

// ============================================================================
// 9. PagedResult<T> - Resultado paginado genérico
// ============================================================================
class PagedResult<T> {
  final List<T> items;
  final int total;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PagedResult({
    required this.items,
    required this.total,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'items': items.map((item) => toJsonT(item)).toList(),
      'total': total,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() =>
      'PagedResult(total: $total, page: $pageNumber/$totalPages, items: ${items.length})';
}
