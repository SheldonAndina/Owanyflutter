import 'package:flutter/foundation.dart';
import '../dto/blocos_dtos.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_logger.dart';

/// BlocosProvider gerencia estado dos blocos do condomínio
/// CRUD completo: listar, criar, atualizar, deletar
class BlocosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BlocoDto> _blocos = [];
  BlocoDto? _blocoAtual;
  List<Apartamento> _apartamentosDoBloco = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<BlocoDto> get blocos => _blocos;
  BlocoDto? get blocoAtual => _blocoAtual;
  List<Apartamento> get apartamentosDoBloco => _apartamentosDoBloco;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Carrega todos os blocos
  Future<void> carregarBlocos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _blocos = await _apiService.listarBlocos();
      AppLogger.info('BlocosProvider', 'Carregados ${_blocos.length} blocos');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar blocos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega detalhes de um bloco específico
  Future<void> carregarBloco(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _blocoAtual = await _apiService.getBloco(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar bloco: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega apartamentos de um bloco
  Future<void> carregarApartamentosDoBloco(String blocoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _apartamentosDoBloco = await _apiService.getApartamentosDoBloco(blocoId);
      AppLogger.info('BlocosProvider', 'Carregados ${_apartamentosDoBloco.length} apartamentos do bloco $blocoId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar apartamentos do bloco: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria um novo bloco
  Future<BlocoDto?> criarBloco({required String nome, String? descricao}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final novoBloco = await _apiService.criarBloco(
        CriarBlocoRequest(nome: nome, descricao: descricao),
      );
      _blocos.add(novoBloco);
      AppLogger.info('BlocosProvider', 'Bloco criado: ${novoBloco.nome}');
      _isLoading = false;
      notifyListeners();
      return novoBloco;
    } catch (e) {
      _errorMessage = 'Erro ao criar bloco: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Atualiza um bloco existente
  Future<BlocoDto?> atualizarBloco(String id, {required String nome, String? descricao}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final blocoAtualizado = await _apiService.atualizarBloco(
        id,
        AtualizarBlocoRequest(nome: nome, descricao: descricao),
      );
      final idx = _blocos.indexWhere((b) => b.id == id);
      if (idx != -1) {
        _blocos[idx] = blocoAtualizado;
      }
      if (_blocoAtual?.id == id) {
        _blocoAtual = blocoAtualizado;
      }
      AppLogger.info('BlocosProvider', 'Bloco atualizado: ${blocoAtualizado.nome}');
      _isLoading = false;
      notifyListeners();
      return blocoAtualizado;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar bloco: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Deleta um bloco (impede se houver apartamentos vinculados)
  Future<bool> deletarBloco(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletarBloco(id);
      _blocos.removeWhere((b) => b.id == id);
      if (_blocoAtual?.id == id) {
        _blocoAtual = null;
      }
      AppLogger.info('BlocosProvider', 'Bloco deletado: $id');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao deletar bloco: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpa mensagem de erro
  void limparErro() {
    _errorMessage = null;
    notifyListeners();
  }
}
