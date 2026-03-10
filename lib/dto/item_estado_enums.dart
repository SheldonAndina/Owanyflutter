/// =====================================================================
/// ENUMS DE ESTADO DE ITEM PATRIMONIAL
/// Define os estados físicos e operacionais dos itens
/// Baseado na especificação do backend .NET 8
/// =====================================================================
library;

import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// Estado físico REAL do item (armazenado no banco)
enum EstadoFisicoItem {
  disponivel,   // 0
  danificado,   // 1
  emManutencao, // 2
  inutilizado,  // 3
  extraviado,   // 4
}

extension EstadoFisicoItemExtension on EstadoFisicoItem {
  /// Valor inteiro para enviar ao backend
  int get valor {
    switch (this) {
      case EstadoFisicoItem.disponivel: return 0;
      case EstadoFisicoItem.danificado: return 1;
      case EstadoFisicoItem.emManutencao: return 2;
      case EstadoFisicoItem.inutilizado: return 3;
      case EstadoFisicoItem.extraviado: return 4;
    }
  }

  /// Label em português para UI
  String toPortuguese() {
    switch (this) {
      case EstadoFisicoItem.disponivel: return 'Disponível';
      case EstadoFisicoItem.danificado: return 'Danificado';
      case EstadoFisicoItem.emManutencao: return 'Em Manutenção';
      case EstadoFisicoItem.inutilizado: return 'Inutilizado';
      case EstadoFisicoItem.extraviado: return 'Extraviado';
    }
  }

  /// Valor string para backend
  String toBackendValue() {
    switch (this) {
      case EstadoFisicoItem.disponivel: return 'Disponivel';
      case EstadoFisicoItem.danificado: return 'Danificado';
      case EstadoFisicoItem.emManutencao: return 'EmManutencao';
      case EstadoFisicoItem.inutilizado: return 'Inutilizado';
      case EstadoFisicoItem.extraviado: return 'Extraviado';
    }
  }

  /// Cor para UI (usando OwanyTheme)
  Color get cor {
    switch (this) {
      case EstadoFisicoItem.disponivel: return OwanyTheme.success;
      case EstadoFisicoItem.danificado: return OwanyTheme.error;
      case EstadoFisicoItem.emManutencao: return OwanyTheme.warning;
      case EstadoFisicoItem.inutilizado: return OwanyTheme.gray;
      case EstadoFisicoItem.extraviado: return OwanyTheme.purple;
    }
  }

  /// Ícone para UI
  IconData get icone {
    switch (this) {
      case EstadoFisicoItem.disponivel: return Icons.check_circle;
      case EstadoFisicoItem.danificado: return Icons.warning;
      case EstadoFisicoItem.emManutencao: return Icons.build;
      case EstadoFisicoItem.inutilizado: return Icons.cancel;
      case EstadoFisicoItem.extraviado: return Icons.help_outline;
    }
  }

  /// Parse de string do backend
  static EstadoFisicoItem fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'disponivel': return EstadoFisicoItem.disponivel;
      case 'danificado': return EstadoFisicoItem.danificado;
      case 'emmanutencao': return EstadoFisicoItem.emManutencao;
      case 'inutilizado': return EstadoFisicoItem.inutilizado;
      case 'extraviado': return EstadoFisicoItem.extraviado;
      default: return EstadoFisicoItem.disponivel;
    }
  }

  /// Parse de int do backend
  static EstadoFisicoItem fromInt(int value) {
    switch (value) {
      case 0: return EstadoFisicoItem.disponivel;
      case 1: return EstadoFisicoItem.danificado;
      case 2: return EstadoFisicoItem.emManutencao;
      case 3: return EstadoFisicoItem.inutilizado;
      case 4: return EstadoFisicoItem.extraviado;
      default: return EstadoFisicoItem.disponivel;
    }
  }
}

/// Status operacional CALCULADO pelo backend (não armazenado)
enum StatusOperacionalItem {
  emStock,      // 0 - Disponível e não alocado
  emUso,        // 1 - Alocado a um apartamento
  danificado,   // 2
  emManutencao, // 3 - Estado físico ou tem solicitação ativa
  inutilizado,  // 4
  extraviado,   // 5
}

extension StatusOperacionalItemExtension on StatusOperacionalItem {
  /// Valor inteiro para filtros
  int get valor {
    switch (this) {
      case StatusOperacionalItem.emStock: return 0;
      case StatusOperacionalItem.emUso: return 1;
      case StatusOperacionalItem.danificado: return 2;
      case StatusOperacionalItem.emManutencao: return 3;
      case StatusOperacionalItem.inutilizado: return 4;
      case StatusOperacionalItem.extraviado: return 5;
    }
  }

  /// Label em português para UI
  String toPortuguese() {
    switch (this) {
      case StatusOperacionalItem.emStock: return 'Em Stock';
      case StatusOperacionalItem.emUso: return 'Em Uso';
      case StatusOperacionalItem.danificado: return 'Danificado';
      case StatusOperacionalItem.emManutencao: return 'Em Manutenção';
      case StatusOperacionalItem.inutilizado: return 'Inutilizado';
      case StatusOperacionalItem.extraviado: return 'Extraviado';
    }
  }

  /// Valor string para backend
  String toBackendValue() {
    switch (this) {
      case StatusOperacionalItem.emStock: return 'EmStock';
      case StatusOperacionalItem.emUso: return 'EmUso';
      case StatusOperacionalItem.danificado: return 'Danificado';
      case StatusOperacionalItem.emManutencao: return 'EmManutencao';
      case StatusOperacionalItem.inutilizado: return 'Inutilizado';
      case StatusOperacionalItem.extraviado: return 'Extraviado';
    }
  }

  /// Cor para UI (usando OwanyTheme)
  Color get cor {
    switch (this) {
      case StatusOperacionalItem.emStock: return OwanyTheme.info;
      case StatusOperacionalItem.emUso: return OwanyTheme.primaryBlue;
      case StatusOperacionalItem.danificado: return OwanyTheme.error;
      case StatusOperacionalItem.emManutencao: return OwanyTheme.warning;
      case StatusOperacionalItem.inutilizado: return OwanyTheme.gray;
      case StatusOperacionalItem.extraviado: return OwanyTheme.purple;
    }
  }

  /// Ícone para UI
  IconData get icone {
    switch (this) {
      case StatusOperacionalItem.emStock: return Icons.inventory;
      case StatusOperacionalItem.emUso: return Icons.home;
      case StatusOperacionalItem.danificado: return Icons.warning;
      case StatusOperacionalItem.emManutencao: return Icons.build;
      case StatusOperacionalItem.inutilizado: return Icons.cancel;
      case StatusOperacionalItem.extraviado: return Icons.help_outline;
    }
  }

  /// Parse de string do backend
  static StatusOperacionalItem fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'emstock': return StatusOperacionalItem.emStock;
      case 'emuso': return StatusOperacionalItem.emUso;
      case 'danificado': return StatusOperacionalItem.danificado;
      case 'emmanutencao': return StatusOperacionalItem.emManutencao;
      case 'inutilizado': return StatusOperacionalItem.inutilizado;
      case 'extraviado': return StatusOperacionalItem.extraviado;
      default: return StatusOperacionalItem.emStock;
    }
  }

  /// Parse de int do backend
  static StatusOperacionalItem fromInt(int value) {
    switch (value) {
      case 0: return StatusOperacionalItem.emStock;
      case 1: return StatusOperacionalItem.emUso;
      case 2: return StatusOperacionalItem.danificado;
      case 3: return StatusOperacionalItem.emManutencao;
      case 4: return StatusOperacionalItem.inutilizado;
      case 5: return StatusOperacionalItem.extraviado;
      default: return StatusOperacionalItem.emStock;
    }
  }
}

/// Frequência de manutenção preventiva
enum FrequenciaManutencao {
  semanal,    // 0
  quinzenal,  // 1
  mensal,     // 2
  bimestral,  // 3
  trimestral, // 4
  semestral,  // 5
  anual,      // 6
}

extension FrequenciaManutencaoExtension on FrequenciaManutencao {
  /// Valor inteiro
  int get valor {
    switch (this) {
      case FrequenciaManutencao.semanal: return 0;
      case FrequenciaManutencao.quinzenal: return 1;
      case FrequenciaManutencao.mensal: return 2;
      case FrequenciaManutencao.bimestral: return 3;
      case FrequenciaManutencao.trimestral: return 4;
      case FrequenciaManutencao.semestral: return 5;
      case FrequenciaManutencao.anual: return 6;
    }
  }

  /// Label em português
  String toPortuguese() {
    switch (this) {
      case FrequenciaManutencao.semanal: return 'Semanal';
      case FrequenciaManutencao.quinzenal: return 'Quinzenal';
      case FrequenciaManutencao.mensal: return 'Mensal';
      case FrequenciaManutencao.bimestral: return 'Bimestral';
      case FrequenciaManutencao.trimestral: return 'Trimestral';
      case FrequenciaManutencao.semestral: return 'Semestral';
      case FrequenciaManutencao.anual: return 'Anual';
    }
  }

  /// Valor string para backend
  String toBackendValue() {
    switch (this) {
      case FrequenciaManutencao.semanal: return 'Semanal';
      case FrequenciaManutencao.quinzenal: return 'Quinzenal';
      case FrequenciaManutencao.mensal: return 'Mensal';
      case FrequenciaManutencao.bimestral: return 'Bimestral';
      case FrequenciaManutencao.trimestral: return 'Trimestral';
      case FrequenciaManutencao.semestral: return 'Semestral';
      case FrequenciaManutencao.anual: return 'Anual';
    }
  }

  /// Parse de string
  static FrequenciaManutencao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'semanal': return FrequenciaManutencao.semanal;
      case 'quinzenal': return FrequenciaManutencao.quinzenal;
      case 'mensal': return FrequenciaManutencao.mensal;
      case 'bimestral': return FrequenciaManutencao.bimestral;
      case 'trimestral': return FrequenciaManutencao.trimestral;
      case 'semestral': return FrequenciaManutencao.semestral;
      case 'anual': return FrequenciaManutencao.anual;
      default: return FrequenciaManutencao.mensal;
    }
  }
}

/// Status de manutenção preventiva
enum StatusManutencaoPreventiva {
  agendada,     // 0
  emAndamento,  // 1
  concluida,    // 2
  atrasada,     // 3
  cancelada,    // 4
}

extension StatusManutencaoPreventivaExtension on StatusManutencaoPreventiva {
  /// Valor inteiro
  int get valor {
    switch (this) {
      case StatusManutencaoPreventiva.agendada: return 0;
      case StatusManutencaoPreventiva.emAndamento: return 1;
      case StatusManutencaoPreventiva.concluida: return 2;
      case StatusManutencaoPreventiva.atrasada: return 3;
      case StatusManutencaoPreventiva.cancelada: return 4;
    }
  }

  /// Label em português
  String toPortuguese() {
    switch (this) {
      case StatusManutencaoPreventiva.agendada: return 'Agendada';
      case StatusManutencaoPreventiva.emAndamento: return 'Em Andamento';
      case StatusManutencaoPreventiva.concluida: return 'Concluída';
      case StatusManutencaoPreventiva.atrasada: return 'Atrasada';
      case StatusManutencaoPreventiva.cancelada: return 'Cancelada';
    }
  }

  /// Valor string para backend
  String toBackendValue() {
    switch (this) {
      case StatusManutencaoPreventiva.agendada: return 'Agendada';
      case StatusManutencaoPreventiva.emAndamento: return 'EmAndamento';
      case StatusManutencaoPreventiva.concluida: return 'Concluida';
      case StatusManutencaoPreventiva.atrasada: return 'Atrasada';
      case StatusManutencaoPreventiva.cancelada: return 'Cancelada';
    }
  }

  /// Cor para UI
  Color get cor {
    switch (this) {
      case StatusManutencaoPreventiva.agendada: return Colors.blue;
      case StatusManutencaoPreventiva.emAndamento: return Colors.orange;
      case StatusManutencaoPreventiva.concluida: return Colors.green;
      case StatusManutencaoPreventiva.atrasada: return Colors.red;
      case StatusManutencaoPreventiva.cancelada: return Colors.grey;
    }
  }

  /// Parse de string
  static StatusManutencaoPreventiva fromString(String value) {
    switch (value.toLowerCase().replaceAll(' ', '')) {
      case 'agendada': return StatusManutencaoPreventiva.agendada;
      case 'emandamento': return StatusManutencaoPreventiva.emAndamento;
      case 'concluida': return StatusManutencaoPreventiva.concluida;
      case 'atrasada': return StatusManutencaoPreventiva.atrasada;
      case 'cancelada': return StatusManutencaoPreventiva.cancelada;
      default: return StatusManutencaoPreventiva.agendada;
    }
  }
}

/// Status de agendamento de manutenção em apartamento
enum StatusAgendamentoManutencao {
  pendenteAceitacao, // 0
  aceito,            // 1
  recusado,          // 2
  agendado,          // 3
  emAndamento,       // 4
  concluido,         // 5
  cancelado,         // 6
}

extension StatusAgendamentoManutencaoExtension on StatusAgendamentoManutencao {
  /// Valor inteiro
  int get valor {
    switch (this) {
      case StatusAgendamentoManutencao.pendenteAceitacao: return 0;
      case StatusAgendamentoManutencao.aceito: return 1;
      case StatusAgendamentoManutencao.recusado: return 2;
      case StatusAgendamentoManutencao.agendado: return 3;
      case StatusAgendamentoManutencao.emAndamento: return 4;
      case StatusAgendamentoManutencao.concluido: return 5;
      case StatusAgendamentoManutencao.cancelado: return 6;
    }
  }

  /// Label em português
  String toPortuguese() {
    switch (this) {
      case StatusAgendamentoManutencao.pendenteAceitacao: return 'Pendente Aceitação';
      case StatusAgendamentoManutencao.aceito: return 'Aceito';
      case StatusAgendamentoManutencao.recusado: return 'Recusado';
      case StatusAgendamentoManutencao.agendado: return 'Agendado';
      case StatusAgendamentoManutencao.emAndamento: return 'Em Andamento';
      case StatusAgendamentoManutencao.concluido: return 'Concluído';
      case StatusAgendamentoManutencao.cancelado: return 'Cancelado';
    }
  }

  /// Valor string para backend
  String toBackendValue() {
    switch (this) {
      case StatusAgendamentoManutencao.pendenteAceitacao: return 'PendenteAceitacao';
      case StatusAgendamentoManutencao.aceito: return 'Aceito';
      case StatusAgendamentoManutencao.recusado: return 'Recusado';
      case StatusAgendamentoManutencao.agendado: return 'Agendado';
      case StatusAgendamentoManutencao.emAndamento: return 'EmAndamento';
      case StatusAgendamentoManutencao.concluido: return 'Concluido';
      case StatusAgendamentoManutencao.cancelado: return 'Cancelado';
    }
  }

  /// Cor para UI
  Color get cor {
    switch (this) {
      case StatusAgendamentoManutencao.pendenteAceitacao: return Colors.blue;
      case StatusAgendamentoManutencao.aceito: return Colors.teal;
      case StatusAgendamentoManutencao.recusado: return Colors.red.shade300;
      case StatusAgendamentoManutencao.agendado: return Colors.teal;
      case StatusAgendamentoManutencao.emAndamento: return Colors.orange;
      case StatusAgendamentoManutencao.concluido: return Colors.green;
      case StatusAgendamentoManutencao.cancelado: return Colors.grey;
    }
  }

  /// Ícone para UI
  IconData get icone {
    switch (this) {
      case StatusAgendamentoManutencao.pendenteAceitacao: return Icons.pending;
      case StatusAgendamentoManutencao.aceito: return Icons.thumb_up;
      case StatusAgendamentoManutencao.recusado: return Icons.thumb_down;
      case StatusAgendamentoManutencao.agendado: return Icons.calendar_today;
      case StatusAgendamentoManutencao.emAndamento: return Icons.build;
      case StatusAgendamentoManutencao.concluido: return Icons.check_circle;
      case StatusAgendamentoManutencao.cancelado: return Icons.cancel;
    }
  }

  /// Parse de string
  static StatusAgendamentoManutencao fromString(String value) {
    switch (value.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'pendenteaceitacao': return StatusAgendamentoManutencao.pendenteAceitacao;
      case 'aceito': return StatusAgendamentoManutencao.aceito;
      case 'recusado': return StatusAgendamentoManutencao.recusado;
      case 'agendado': return StatusAgendamentoManutencao.agendado;
      case 'emandamento': return StatusAgendamentoManutencao.emAndamento;
      case 'concluido': return StatusAgendamentoManutencao.concluido;
      case 'cancelado': return StatusAgendamentoManutencao.cancelado;
      default: return StatusAgendamentoManutencao.pendenteAceitacao;
    }
  }

  /// Parse de int
  static StatusAgendamentoManutencao fromInt(int value) {
    switch (value) {
      case 0: return StatusAgendamentoManutencao.pendenteAceitacao;
      case 1: return StatusAgendamentoManutencao.aceito;
      case 2: return StatusAgendamentoManutencao.recusado;
      case 3: return StatusAgendamentoManutencao.agendado;
      case 4: return StatusAgendamentoManutencao.emAndamento;
      case 5: return StatusAgendamentoManutencao.concluido;
      case 6: return StatusAgendamentoManutencao.cancelado;
      default: return StatusAgendamentoManutencao.pendenteAceitacao;
    }
  }
}

/// Helper para obter cor de status genérico
Color getCorStatus(String status) {
  switch (status.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
    case 'agendada':
    case 'pendenteaceitacao':
      return Colors.blue;
    case 'emandamento':
      return Colors.orange;
    case 'concluida':
    case 'concluido':
      return Colors.green;
    case 'atrasada':
      return Colors.red;
    case 'cancelada':
    case 'cancelado':
      return Colors.grey;
    case 'aceito':
    case 'agendado':
      return Colors.teal;
    case 'recusado':
      return Colors.red.shade300;
    default:
      return Colors.grey;
  }
}
