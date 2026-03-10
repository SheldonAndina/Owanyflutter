/// =====================================================================
/// BLOCOS DTOs - CRUD completo de Blocos
/// =====================================================================
library;

/// DTO para Bloco (resposta da API)
import '../utils/app_date_time.dart';

class BlocoDto {
  final String id;
  final String nome;
  final String? descricao;
  final int quantidadeApartamentos;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  BlocoDto({
    required this.id,
    required this.nome,
    this.descricao,
    this.quantidadeApartamentos = 0,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory BlocoDto.fromJson(Map<String, dynamic> json) {
    return BlocoDto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      quantidadeApartamentos: json['quantidadeApartamentos'] ?? json['totalApartamentos'] ?? 0,
      criadoEm: tryParseBackendDateTimeToLocal(json['criadoEm']),
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'quantidadeApartamentos': quantidadeApartamentos,
    'criadoEm': criadoEm != null ? toBackendUtcIsoString(criadoEm!) : null,
    'atualizadoEm': atualizadoEm != null ? toBackendUtcIsoString(atualizadoEm!) : null,
  };

  @override
  String toString() => 'BlocoDto(id: $id, nome: $nome, apts: $quantidadeApartamentos)';
}

/// Request para criar um novo bloco
class CriarBlocoRequest {
  final String nome;
  final String? descricao;

  CriarBlocoRequest({
    required this.nome,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    if (descricao != null) 'descricao': descricao,
  };
}

/// Request para atualizar um bloco existente
class AtualizarBlocoRequest {
  final String nome;
  final String? descricao;

  AtualizarBlocoRequest({
    required this.nome,
    this.descricao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    if (descricao != null) 'descricao': descricao,
  };
}
