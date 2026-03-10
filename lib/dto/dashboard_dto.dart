// lib/dto/dashboard_dto.dart

class DashboardDto {
  final int totalUsuarios;
  final int usuariosAtivos;
  final int usuariosInativos;
  final int totalChamados;
  final int chamadosAbertos;
  final int chamadosEmAndamento;
  final int chamadosConcluidos;
  final int chamadosCancelados;
  final double tempoMedioResolucaoHoras;
  final int chamadosUltimos7Dias;
  final int chamadosUltimos30Dias;
  final int totalApartamentos;
  final int apartamentosComChamadosAbertos;
  final int notificacoesNaoLidas;

  DashboardDto({
    required this.totalUsuarios,
    required this.usuariosAtivos,
    required this.usuariosInativos,
    required this.totalChamados,
    required this.chamadosAbertos,
    required this.chamadosEmAndamento,
    required this.chamadosConcluidos,
    required this.chamadosCancelados,
    required this.tempoMedioResolucaoHoras,
    required this.chamadosUltimos7Dias,
    required this.chamadosUltimos30Dias,
    required this.totalApartamentos,
    required this.apartamentosComChamadosAbertos,
    required this.notificacoesNaoLidas,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      totalUsuarios: json['totalUsuarios'] ?? json['TotalUsuarios'] ?? 0,
      usuariosAtivos: json['usuariosAtivos'] ?? json['UsuariosAtivos'] ?? json['UsuariosAtivos'] ?? 0,
      usuariosInativos: json['usuariosInativos'] ?? json['UsuariosInativos'] ?? 0,
      totalChamados: json['totalChamados'] ?? json['TotalChamados'] ?? 0,
      chamadosAbertos: json['chamadosAbertos'] ?? json['ChamadosAbertos'] ?? 0,
      chamadosEmAndamento: json['chamadosEmAndamento'] ?? json['ChamadosEmAndamento'] ?? 0,
      chamadosConcluidos: json['chamadosConcluidos'] ?? json['ChamadosConcluidos'] ?? 0,
      chamadosCancelados: json['chamadosCancelados'] ?? json['ChamadosCancelados'] ?? 0,
      tempoMedioResolucaoHoras: ((json['tempoMedioResolucaoHoras'] ?? json['TempoMedioResolucaoHoras'] ?? 0) as num)
          .toDouble(),
      chamadosUltimos7Dias: json['chamadosUltimos7Dias'] ?? json['ChamadosUltimos7Dias'] ?? 0,
      chamadosUltimos30Dias: json['chamadosUltimos30Dias'] ?? json['ChamadosUltimos30Dias'] ?? 0,
      totalApartamentos: json['totalApartamentos'] ?? json['TotalApartamentos'] ?? 0,
      apartamentosComChamadosAbertos:
          json['apartamentosComChamadosAbertos'] ?? json['ApartamentosComChamadosAbertos'] ?? 0,
      notificacoesNaoLidas: json['notificacoesNaoLidas'] ?? json['NotificacoesNaoLidas'] ?? 0,
    );
  }
}
