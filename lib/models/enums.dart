// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Tipos de usuário no sistema
enum UsuarioTipo {
  Administrador,
  Funcionario,
  Sindico,
  Portaria,
  Morador,
  Visitante,
}

extension UsuarioTipoExtension on UsuarioTipo {
  String toPortuguese() {
    switch (this) {
      case UsuarioTipo.Administrador:
        return 'Administrador';
      case UsuarioTipo.Funcionario:
        return 'Funcionário';
      case UsuarioTipo.Sindico:
        return 'Síndico';
      case UsuarioTipo.Portaria:
        return 'Portaria';
      case UsuarioTipo.Morador:
        return 'Morador';
      case UsuarioTipo.Visitante:
        return 'Visitante';
    }
  }

  /// Backend-safe value without acentos
  String toApiValue() {
    switch (this) {
      case UsuarioTipo.Administrador:
        return 'Administrador';
      case UsuarioTipo.Funcionario:
        return 'Funcionario';
      case UsuarioTipo.Sindico:
        return 'Sindico';
      case UsuarioTipo.Portaria:
        return 'Portaria';
      case UsuarioTipo.Morador:
        return 'Morador';
      case UsuarioTipo.Visitante:
        return 'Visitante';
    }
  }

  static UsuarioTipo fromString(String value) {
    switch (value.toLowerCase()) {
      case 'administrador':
        return UsuarioTipo.Administrador;
      case 'funcionario':
      case 'funcionário':
        return UsuarioTipo.Funcionario;
      case 'sindico':
      case 'síndico':
        return UsuarioTipo.Sindico;
      case 'portaria':
        return UsuarioTipo.Portaria;
      case 'morador':
        return UsuarioTipo.Morador;
      case 'visitante':
        return UsuarioTipo.Visitante;
      default:
        AppLogger.error('Enums', '[ERROR] Unknown user type received from backend: "$value"');
        // Instead of silently defaulting to Morador, throw an error
        // This helps catch backend issues early
        throw ArgumentError('Unknown user type: "$value". Check backend response.');
    }
  }
}

/// Status de solicitação de manutenção (Backend enum values 0-6)
enum StatusSolicitacao {
  Pendente,       // 0
  EmAndamento,    // 1
  EmAnalise,      // 2
  Aguardando,     // 3
  Concluido,      // 4
  Cancelado,      // 5
  Rejeitado,      // 6
}

extension StatusSolicitacaoExtension on StatusSolicitacao {
  String toPortuguese() {
    switch (this) {
      case StatusSolicitacao.Pendente:
        return 'Pendente';
      case StatusSolicitacao.EmAndamento:
        return 'Em andamento';
      case StatusSolicitacao.EmAnalise:
        return 'Em análise';
      case StatusSolicitacao.Aguardando:
        return 'Aguardando';
      case StatusSolicitacao.Concluido:
        return 'Concluído';
      case StatusSolicitacao.Cancelado:
        return 'Cancelado';
      case StatusSolicitacao.Rejeitado:
        return 'Rejeitado';
    }
  }

  static StatusSolicitacao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pendente':
        return StatusSolicitacao.Pendente;
      case 'emandamento':
      case 'em andamento':
        return StatusSolicitacao.EmAndamento;
      case 'emanalise':
      case 'em análise':
        return StatusSolicitacao.EmAnalise;
      case 'aguardando':
        return StatusSolicitacao.Aguardando;
      case 'concluido':
      case 'concluído':
        return StatusSolicitacao.Concluido;
      case 'cancelado':
        return StatusSolicitacao.Cancelado;
      case 'rejeitado':
        return StatusSolicitacao.Rejeitado;
      default:
        AppLogger.error('Enums', '[ERROR] Unknown status received from backend: "$value"');
        return StatusSolicitacao.Pendente;
    }
  }
}

/// Prioridade de solicitação (v2 API: Baixa, Media, Alta, Urgente)
enum PrioridadeSolicitacao {
  Baixa,
  Media,
  Alta,
  Urgente,
}

extension PrioridadeSolicitacaoExtension on PrioridadeSolicitacao {
  String toPortuguese() {
    switch (this) {
      case PrioridadeSolicitacao.Baixa:
        return 'Baixa';
      case PrioridadeSolicitacao.Media:
        return 'Média';
      case PrioridadeSolicitacao.Alta:
        return 'Alta';
      case PrioridadeSolicitacao.Urgente:
        return 'Urgente';
    }
  }

  static PrioridadeSolicitacao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'baixa':
        return PrioridadeSolicitacao.Baixa;
      case 'media':
      case 'média':
        return PrioridadeSolicitacao.Media;
      case 'alta':
        return PrioridadeSolicitacao.Alta;
      case 'urgente':
        return PrioridadeSolicitacao.Urgente;
      default:
        return PrioridadeSolicitacao.Media;
    }
  }
}

/// Estado do apartamento (Backend enum values 0-3)
enum EstadoApartamento {
  Disponivel,     // 0
  Ocupado,        // 1
  EmManutencao,   // 2
  Inativo,        // 3
}

extension EstadoApartamentoExtension on EstadoApartamento {
  String toPortuguese() {
    switch (this) {
      case EstadoApartamento.Disponivel:
        return 'Disponível';
      case EstadoApartamento.Ocupado:
        return 'Ocupado';
      case EstadoApartamento.EmManutencao:
        return 'Em Manutenção';
      case EstadoApartamento.Inativo:
        return 'Inativo';
    }
  }

  static EstadoApartamento fromString(String value) {
    switch (value.toLowerCase()) {
      case 'disponivel':
        return EstadoApartamento.Disponivel;
      case 'ocupado':
        return EstadoApartamento.Ocupado;
      case 'emmanutencao':
      case 'em manutencao':
      case 'em manutenção':
      case 'manutencao':  // backward compatibility
      case 'manutenção':  // backward compatibility
        return EstadoApartamento.EmManutencao;
      case 'inativo':
        return EstadoApartamento.Inativo;
      default:
        AppLogger.error('Enums', '[ERROR] Unknown apartment state received from backend: "$value"');
        return EstadoApartamento.Disponivel;
    }
  }
}

/// Tipo de notificação
enum TipoNotificacao {
  NovoComentario,
  AberturaSolicitacao,
  MudancaStatus,
  AtribuicaoResponsavel,
  AlteracaoPrazo,
  NovasolicitacaoCriada,
  Aviso,
  Sistema,
}

extension TipoNotificacaoExtension on TipoNotificacao {
  String toPortuguese() {
    switch (this) {
      case TipoNotificacao.NovoComentario:
        return 'Novo Comentário';
      case TipoNotificacao.AberturaSolicitacao:
        return 'Abertura de Solicitação';
      case TipoNotificacao.MudancaStatus:
        return 'Mudança de Status';
      case TipoNotificacao.AtribuicaoResponsavel:
        return 'Atribuição de Responsável';
      case TipoNotificacao.AlteracaoPrazo:
        return 'Alteração de Prazo';
      case TipoNotificacao.NovasolicitacaoCriada:
        return 'Nova Solicitação';
      case TipoNotificacao.Aviso:
        return 'Aviso';
      case TipoNotificacao.Sistema:
        return 'Sistema';
    }
  }

  IconData getIcon() {
    switch (this) {
      case TipoNotificacao.NovoComentario:
        return Icons.comment_rounded;
      case TipoNotificacao.AberturaSolicitacao:
        return Icons.note_add_rounded;
      case TipoNotificacao.MudancaStatus:
        return Icons.update_rounded;
      case TipoNotificacao.AtribuicaoResponsavel:
        return Icons.assignment_rounded;
      case TipoNotificacao.AlteracaoPrazo:
        return Icons.schedule_rounded;
      case TipoNotificacao.NovasolicitacaoCriada:
        return Icons.build_rounded;
      case TipoNotificacao.Aviso:
        return Icons.warning_rounded;
      case TipoNotificacao.Sistema:
        return Icons.notifications_rounded;
    }
  }
}

/// Converte valor de backend (string) para `TipoNotificacao` de forma robusta.
TipoNotificacao parseTipoNotificacao(String value) {
  final v = value.toLowerCase();

  if (v.contains('novocomentario') || v.contains('novo comentario')) return TipoNotificacao.NovoComentario;
  if (v.contains('aberturasolicitacao') || v.contains('abertura') || v.contains('aberturasolicitação')) return TipoNotificacao.AberturaSolicitacao;
  if (v.contains('mudancastatus') || v.contains('mudanca') || v.contains('status')) return TipoNotificacao.MudancaStatus;
  if (v.contains('atribuicaoresponsavel') || v.contains('atribuicao') || v.contains('responsavel')) return TipoNotificacao.AtribuicaoResponsavel;
  if (v.contains('alteracaoprazo') || v.contains('prazo')) return TipoNotificacao.AlteracaoPrazo;
  if (v.contains('novasolicitacao') || v.contains('novasolicitacaocriada') || v.contains('agendamento')) return TipoNotificacao.NovasolicitacaoCriada;
  if (v.contains('manutencao') || v.contains('manutencaopreventiva') || v.contains('manutencao_preventiva')) return TipoNotificacao.NovasolicitacaoCriada;
  if (v.contains('sms') || v.contains('sms_massa') || v.contains('smsmassa') || v.contains('comunicado')) return TipoNotificacao.Sistema;
  if (v.contains('aviso') || v.contains('warning')) return TipoNotificacao.Aviso;

  return TipoNotificacao.Sistema;
}

/// Tipos de equipamento para manutenção preventiva
enum TipoManutencao {
  Elevador,
  BombaAgua,
  Geradores,
  ArCondicionado,
  Pintura,
  Impermeabilizacao,
  Eletrica,
  Hidraulica,
  Jardim,
  Limpeza,
  Incendio,
  PortaoAutomatico,
  Interfone,
  CFTV,
  Outros,
}

extension TipoManutencaoExtension on TipoManutencao {
  /// Retorna o valor inteiro do enum esperado pelo backend.
  /// Usa mapeamento explícito e mapeia `Outros` para 99 por segurança.
  int toBackendInt() {
    switch (this) {
      case TipoManutencao.Elevador:
        return 0;
      case TipoManutencao.BombaAgua:
        return 1;
      case TipoManutencao.Geradores:
        return 2;
      case TipoManutencao.ArCondicionado:
        return 3;
      case TipoManutencao.Pintura:
        return 4;
      case TipoManutencao.Impermeabilizacao:
        return 5;
      case TipoManutencao.Eletrica:
        return 6;
      case TipoManutencao.Hidraulica:
        return 7;
      case TipoManutencao.Jardim:
        return 8;
      case TipoManutencao.Limpeza:
        return 9;
      case TipoManutencao.Incendio:
        return 10;
      case TipoManutencao.PortaoAutomatico:
        return 11;
      case TipoManutencao.Interfone:
        return 12;
      case TipoManutencao.CFTV:
        return 13;
      case TipoManutencao.Outros:
      default:
        return 99;
    }
  }

  /// Retorna o valor string para enviar ao backend
  String toBackendValue() {
    switch (this) {
      case TipoManutencao.Elevador:
        return 'Elevador';
      case TipoManutencao.BombaAgua:
        return 'BombaAgua';
      case TipoManutencao.Geradores:
        return 'Geradores';
      case TipoManutencao.ArCondicionado:
        return 'ArCondicionado';
      case TipoManutencao.Pintura:
        return 'Pintura';
      case TipoManutencao.Impermeabilizacao:
        return 'Impermeabilizacao';
      case TipoManutencao.Eletrica:
        return 'Eletrica';
      case TipoManutencao.Hidraulica:
        return 'Hidraulica';
      case TipoManutencao.Jardim:
        return 'Jardim';
      case TipoManutencao.Limpeza:
        return 'Limpeza';
      case TipoManutencao.Incendio:
        return 'Incendio';
      case TipoManutencao.PortaoAutomatico:
        return 'PortaoAutomatico';
      case TipoManutencao.Interfone:
        return 'Interfone';
      case TipoManutencao.CFTV:
        return 'CFTV';
      case TipoManutencao.Outros:
        return 'Outros';
    }
  }

  /// Retorna o label em português para exibição
  String toPortuguese() {
    switch (this) {
      case TipoManutencao.Elevador:
        return 'Elevador';
      case TipoManutencao.BombaAgua:
        return 'Bomba de Água';
      case TipoManutencao.Geradores:
        return 'Geradores';
      case TipoManutencao.ArCondicionado:
        return 'Ar Condicionado';
      case TipoManutencao.Pintura:
        return 'Pintura';
      case TipoManutencao.Impermeabilizacao:
        return 'Impermeabilização';
      case TipoManutencao.Eletrica:
        return 'Elétrica';
      case TipoManutencao.Hidraulica:
        return 'Hidráulica';
      case TipoManutencao.Jardim:
        return 'Jardim';
      case TipoManutencao.Limpeza:
        return 'Limpeza';
      case TipoManutencao.Incendio:
        return 'Sistema de Incêndio';
      case TipoManutencao.PortaoAutomatico:
        return 'Portão Automático';
      case TipoManutencao.Interfone:
        return 'Interfone';
      case TipoManutencao.CFTV:
        return 'CFTV';
      case TipoManutencao.Outros:
        return 'Outros';
    }
  }

  static TipoManutencao fromString(String value) {
    switch (value) {
      case 'Elevador':
        return TipoManutencao.Elevador;
      case 'BombaAgua':
        return TipoManutencao.BombaAgua;
      case 'Geradores':
        return TipoManutencao.Geradores;
      case 'ArCondicionado':
        return TipoManutencao.ArCondicionado;
      case 'Pintura':
        return TipoManutencao.Pintura;
      case 'Impermeabilizacao':
        return TipoManutencao.Impermeabilizacao;
      case 'Eletrica':
        return TipoManutencao.Eletrica;
      case 'Hidraulica':
        return TipoManutencao.Hidraulica;
      case 'Jardim':
        return TipoManutencao.Jardim;
      case 'Limpeza':
        return TipoManutencao.Limpeza;
      case 'Incendio':
        return TipoManutencao.Incendio;
      case 'PortaoAutomatico':
        return TipoManutencao.PortaoAutomatico;
      case 'Interfone':
        return TipoManutencao.Interfone;
      case 'CFTV':
        return TipoManutencao.CFTV;
      case 'Outros':
      default:
        return TipoManutencao.Outros;
    }
  }
}






