import 'package:flutter/foundation.dart';
import '../dto/reservas_areas_dtos.dart';
import '../services/api_service.dart';
import '../utils/app_date_time.dart';
import '../utils/app_logger.dart';

/// Provider para gerenciar estado de reservas de áreas comuns
class ReservasAreasProvider extends ChangeNotifier {
  List<ReservaAreaComumDto> reservas = [];
  ReservaAreaComumDto? reservaAtual;
  bool isLoading = false;
  String? erro;

  final ApiService _apiService = ApiService();

  /// Carrega lista de reservas
  Future<void> carregarReservas({String? status, String? areaId, int pageNumber = 1, int pageSize = 20}) async {
    isLoading = true;
    erro = null;
    notifyListeners();

    try {
      final response = await _apiService.request<List<ReservaAreaComumDto>>(
        'reservasareacomum',
        method: 'GET',
        fromJson: (json) => (json as List).map((item) => ReservaAreaComumDto.fromJson(item)).toList(),
      );

      reservas = response;
      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Carregadas ${reservas.length} reservas');
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao carregar: $e');
    }
  }

  /// Carrega reserva específica
  Future<void> carregarReserva(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.request<ReservaAreaComumDto>(
        'reservasareacomum/$id',
        method: 'GET',
        fromJson: (json) => ReservaAreaComumDto.fromJson(json),
      );

      reservaAtual = response;
      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Reserva carregada: $id');
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao carregar reserva: $e');
    }
  }

  /// Cria nova reserva
  Future<bool> criarReserva({
    required String areaComumId,
    required String moradorId,
    required String apartamentoId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required int horaInicio,
    required int horaFim,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {
        'areaComumId': areaComumId,
        'moradorId': moradorId,
        'apartamentoId': apartamentoId,
        'dataInicio': toBackendUtcIsoString(dataInicio),
        'dataFim': toBackendUtcIsoString(dataFim),
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'status': 'Pendente',
      };

      final response = await _apiService.request<ReservaAreaComumDto>(
        'reservasareacomum',
        method: 'POST',
        body: body,
        fromJson: (json) => ReservaAreaComumDto.fromJson(json),
      );

      reservas.add(response);
      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Reserva criada: ${response.id}');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao criar: $e');
      return false;
    }
  }

  /// Aprova ou rejeita reserva
  Future<bool> aprovarReserva(String id, bool aprovada, {String? motivoRejeicao}) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'reservaId': id, 'aprovada': aprovada, 'motivoRejeicao': motivoRejeicao};

      await _apiService.request<void>('reservasareacomum/$id/aprovar', method: 'POST', body: body, fromJson: (json) {});

      final index = reservas.indexWhere((r) => r.id == id);
      if (index >= 0) {
        final status = aprovada ? 'Aprovada' : 'Rejeitada';
        reservas[index] = ReservaAreaComumDto(
          id: reservas[index].id,
          areaComumId: reservas[index].areaComumId,
          moradorId: reservas[index].moradorId,
          apartamentoId: reservas[index].apartamentoId,
          dataInicio: reservas[index].dataInicio,
          dataFim: reservas[index].dataFim,
          horaInicio: reservas[index].horaInicio,
          horaFim: reservas[index].horaFim,
          status: status,
          checkIn: reservas[index].checkIn,
          checkOut: reservas[index].checkOut,
          criadoEm: reservas[index].criadoEm,
          nomeArea: reservas[index].nomeArea,
          nomeApartamento: reservas[index].nomeApartamento,
          nomeMorador: reservas[index].nomeMorador,
        );
      }

      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Reserva ${aprovada ? 'aprovada' : 'rejeitada'}: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao aprovar: $e');
      return false;
    }
  }

  /// Registra check-in em reserva
  Future<bool> registrarCheckIn(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'reservaId': id, 'momentoRegistro': toBackendUtcIsoString(DateTime.now())};

      await _apiService.request<void>('reservasareacomum/$id/checkin', method: 'POST', body: body, fromJson: (json) {});

      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Check-in registrado: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao fazer check-in: $e');
      return false;
    }
  }

  /// Registra check-out em reserva
  Future<bool> registrarCheckOut(String id) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'reservaId': id, 'momentoRegistro': toBackendUtcIsoString(DateTime.now())};

      await _apiService.request<void>(
        'reservasareacomum/$id/checkout',
        method: 'POST',
        body: body,
        fromJson: (json) {},
      );

      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Check-out registrado: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao fazer check-out: $e');
      return false;
    }
  }

  /// Avalia reserva
  Future<bool> avaliarReserva(String id, int nota, String comentario, List<String> aspectoPositivos) async {
    isLoading = true;
    notifyListeners();

    try {
      final body = {'reservaId': id, 'nota': nota, 'comentario': comentario, 'aspectos_positivos': aspectoPositivos};

      await _apiService.request<void>('reservasareacomum/$id/avaliar', method: 'POST', body: body, fromJson: (json) {});

      isLoading = false;
      notifyListeners();

      AppLogger.info('ReservasAreasProvider', 'Avaliação registrada: $id');
      return true;
    } catch (e) {
      erro = e.toString();
      isLoading = false;
      notifyListeners();
      AppLogger.error('ReservasAreasProvider', 'Erro ao avaliar: $e');
      return false;
    }
  }
}
