/// =====================================================================
/// RESERVAS AREAS DTOs
/// Representam reservas de áreas comuns
/// =====================================================================
library;

import '../utils/app_date_time.dart';

class ReservaAreaComumDto {
  final String id;
  final String areaComumId;
  final String moradorId;
  final String apartamentoId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final int horaInicio;
  final int horaFim;
  final String status; // Pendente, Aprovada, Rejeitada, Cancelada, EmUso, Finalizada
  final String? motivos_rejeicao;
  final bool checkIn;
  final bool checkOut;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? nomeArea;
  final String? nomeApartamento;
  final String? nomeMorador;

  ReservaAreaComumDto({
    required this.id,
    required this.areaComumId,
    required this.moradorId,
    required this.apartamentoId,
    required this.dataInicio,
    required this.dataFim,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
    this.motivos_rejeicao,
    required this.checkIn,
    required this.checkOut,
    this.checkInTime,
    this.checkOutTime,
    required this.criadoEm,
    this.atualizadoEm,
    this.nomeArea,
    this.nomeApartamento,
    this.nomeMorador,
  });

  factory ReservaAreaComumDto.fromJson(Map<String, dynamic> json) {
    return ReservaAreaComumDto(
      id: json['id'] ?? '',
      areaComumId: json['areaComumId'] ?? '',
      moradorId: json['moradorId'] ?? '',
      apartamentoId: json['apartamentoId'] ?? '',
      dataInicio: parseBackendDateTimeToLocal(json['dataInicio']),
      dataFim: parseBackendDateTimeToLocal(json['dataFim']),
      horaInicio: json['horaInicio'] ?? 0,
      horaFim: json['horaFim'] ?? 0,
      status: json['status'] ?? 'Pendente',
      motivos_rejeicao: json['motivos_rejeicao'],
      checkIn: json['checkIn'] ?? false,
      checkOut: json['checkOut'] ?? false,
      checkInTime: tryParseBackendDateTimeToLocal(json['checkInTime']),
      checkOutTime: tryParseBackendDateTimeToLocal(json['checkOutTime']),
      criadoEm: parseBackendDateTimeToLocal(json['criadoEm']),
      atualizadoEm: tryParseBackendDateTimeToLocal(json['atualizadoEm']),
      nomeArea: json['nomeArea'],
      nomeApartamento: json['nomeApartamento'],
      nomeMorador: json['nomeMorador'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'areaComumId': areaComumId,
    'moradorId': moradorId,
    'apartamentoId': apartamentoId,
    'dataInicio': toBackendUtcIsoString(dataInicio),
    'dataFim': toBackendUtcIsoString(dataFim),
    'horaInicio': horaInicio,
    'horaFim': horaFim,
    'status': status,
    'motivos_rejeicao': motivos_rejeicao,
    'checkIn': checkIn,
    'checkOut': checkOut,
  };
}

class AprovarReservaDto {
  final String reservaId;
  final bool aprovada;
  final String? motivoRejeicao;

  AprovarReservaDto({required this.reservaId, required this.aprovada, this.motivoRejeicao});

  Map<String, dynamic> toJson() => {'reservaId': reservaId, 'aprovada': aprovada, 'motivoRejeicao': motivoRejeicao};
}

class CheckInOutDto {
  final String reservaId;
  final DateTime momentoRegistro;

  CheckInOutDto({required this.reservaId, required this.momentoRegistro});

  Map<String, dynamic> toJson() => {'reservaId': reservaId, 'momentoRegistro': toBackendUtcIsoString(momentoRegistro)};
}

class AvaliacaoReservaAreaDto {
  final String reservaId;
  final int nota; // 1-5
  final String comentario;
  final List<String> aspositivos; // Limpeza, Conforto, Atendimento, etc.

  AvaliacaoReservaAreaDto({
    required this.reservaId,
    required this.nota,
    required this.comentario,
    required this.aspositivos,
  });

  Map<String, dynamic> toJson() => {
    'reservaId': reservaId,
    'nota': nota,
    'comentario': comentario,
    'aspectos_positivos': aspositivos,
  };
}
