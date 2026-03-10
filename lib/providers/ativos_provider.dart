import 'package:flutter/material.dart';

import '../models/ativo.dart';
import '../services/api_service.dart';

class AtivosProvider extends ChangeNotifier {
  final List<Ativo> _ativos = [];

  List<Ativo> get ativos => _ativos;

  Future<void> corrigirAtivosSemCodigo() async {
    for (var i = 0; i < _ativos.length; i++) {
      final ativo = _ativos[i];
      if (ativo.codigoPatrimonio.isEmpty) {
        final novoCodigo = _gerarCodigoPatrimonio();
        final dto = {
          'nome': ativo.nome,
          'descricao': ativo.descricao,
          'codigoPatrimonio': novoCodigo,
        };

        final atualizado = await ApiService().request<Ativo>(
          'itemapartamento/${ativo.id}',
          method: 'PUT',
          body: dto,
          fromJson: (json) => Ativo.fromJson(json),
        );

        _ativos[i] = atualizado;
      }
    }
    notifyListeners();
  }

  String _gerarCodigoPatrimonio() {
    final now = DateTime.now();
    final rand = (1000 + (now.microsecond % 9000)).toString().padLeft(4, '0');
    return 'PAT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand';
  }

  Future<void> cadastrarAtivo(String nome, String descricao) async {
    final novoAtivo = Ativo.novo(nome, descricao);
    final ativo = await ApiService().request<Ativo>(
      'itemapartamento/patrimonio/${novoAtivo.codigoPatrimonio}',
      method: 'POST',
      body: novoAtivo.toJson(),
      fromJson: (json) => Ativo.fromJson(json),
    );
    _ativos.add(ativo);
    notifyListeners();
  }

  Future<void> consultarAtivo(String codigo) async {
    final codigoNormalizado = codigo.trim();
    final ativo = await ApiService().request<Ativo>(
      'itemapartamento/patrimonio/${Uri.encodeComponent(codigoNormalizado)}',
      method: 'GET',
      fromJson: (json) => Ativo.fromJson(json),
    );

    final idx = _ativos.indexWhere(
      (a) => a.codigoPatrimonio == codigoNormalizado,
    );
    if (idx >= 0) {
      _ativos[idx] = ativo;
    } else {
      _ativos.add(ativo);
    }
    notifyListeners();
  }

  Future<void> atualizarAtivo({
    required String id,
    required String nome,
    required String descricao,
  }) async {
    final index = _ativos.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final dto = {
      'nome': nome,
      'descricao': descricao,
      'codigoPatrimonio': _ativos[index].codigoPatrimonio,
    };

    final ativoAtualizado = await ApiService().request<Ativo>(
      'itemapartamento/$id',
      method: 'PUT',
      body: dto,
      fromJson: (json) => Ativo.fromJson(json),
    );

    _ativos[index] = ativoAtualizado;
    notifyListeners();
  }

  Future<void> removerAtivo(String codigo) async {
    await ApiService().request<void>(
      'itemapartamento/patrimonio/$codigo',
      method: 'DELETE',
      fromJson: (_) {},
    );
    _ativos.removeWhere((a) => a.codigoPatrimonio == codigo);
    notifyListeners();
  }
}
