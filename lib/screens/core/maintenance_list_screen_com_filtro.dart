import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/solicitacoes_provider.dart';
import 'maintenance_list_screen.dart';

/// Tela wrapper para MaintenanceListScreen filtrando por apartamentoId
class MaintenanceListScreenComFiltroApartamento extends StatelessWidget {
  final String apartamentoId;
  const MaintenanceListScreenComFiltroApartamento({required this.apartamentoId, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<SolicitacoesProvider>(context, listen: false),
      child: MaintenanceListScreen(apartamentoId: apartamentoId),
    );
  }
}
