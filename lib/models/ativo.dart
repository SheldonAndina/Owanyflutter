import 'package:uuid/uuid.dart';

class Ativo {
  final String id;
  final String codigoPatrimonio;
  final String nome;
  final String descricao;
  // Adicione outros campos conforme necessário

  Ativo({
    required this.id,
    required this.codigoPatrimonio,
    required this.nome,
    required this.descricao,
  });

  factory Ativo.novo(String nome, String descricao) {
    final uuid = Uuid();
    final codigo = uuid.v4(); // Gera código único
    return Ativo(
      id: '',
      codigoPatrimonio: codigo,
      nome: nome,
      descricao: descricao,
    );
  }

  factory Ativo.fromJson(Map<String, dynamic> json) {
    return Ativo(
      id: json['id']?.toString() ?? '',
      codigoPatrimonio: json['codigoPatrimonio'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigoPatrimonio': codigoPatrimonio,
      'nome': nome,
      'descricao': descricao,
    };
  }
}
