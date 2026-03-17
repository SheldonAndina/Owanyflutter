import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/owany_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_logger.dart';
import '../providers/moradores_provider.dart';

class VincularMoradorDialog extends StatefulWidget {
  final String apartamentoId;
  final String? moradorAtualId;
  final VoidCallback onSuccess;

  const VincularMoradorDialog({super.key, 
    required this.apartamentoId,
    this.moradorAtualId,
    required this.onSuccess,
  });

  @override
  State<VincularMoradorDialog> createState() => _VincularMoradorDialogState();
}

class _VincularMoradorDialogState extends State<VincularMoradorDialog> {
  late Future<List<Usuario>> _usuariosMorador;
  Usuario? _usuarioSelecionado;
  bool _isLoading = false;
  bool _deixarSemMorador = false;
  String _filtroNome = '';
  String? _errorText;

  String _formatException(dynamic error) {
    final msg = error.toString();
    return msg.replaceAll('Exception: ', '').trim();
  }

  @override
  void initState() {
    super.initState();
    // Carregar TODOS os usuários com tipo Morador
    _usuariosMorador = _carregarUsuariosMorador();
  }


  Future<List<Usuario>> _carregarUsuariosMorador() async {
    try {
      final usuarios = await ApiService().getUsuarios(tipo: 'Morador');
      // Filtro adicional robusto no front - apenas Moradores (exclui Funcionarios)
      // E também exclui moradores já vinculados a OUTROS apartamentos
      final apenasMoreadores = usuarios
          .where((u) {
            final tipoString = u.tipo.toString();
            final isMorador = tipoString == 'UsuarioTipo.Morador' || 
                   tipoString == 'Morador' ||
                   tipoString.toLowerCase() == 'morador';
            if (!isMorador) return false;
            
            // Excluir moradores já vinculados a OUTROS apartamentos
            // Permitir apenas: sem moradorInfo, ou moradorInfo sem apartamentoId,
            // ou moradorInfo com apartamentoId igual ao atual (para re-vincular mesma pessoa)
            final moradorInfo = u.moradorInfo;
            if (moradorInfo == null) return true;
            if (moradorInfo.apartamentoId.isEmpty) return true;
            // Se já está vinculado ao apartamento atual, pode aparecer na lista
            if (moradorInfo.apartamentoId == widget.apartamentoId) return true;
            // Se está vinculado a outro apartamento, esconder da lista
            return false;
          })
          .toList();
      AppLogger.info('VincularMorador', 'Carregados ${apenasMoreadores.length} usuários disponíveis para vincular (de ${usuarios.length} total)');
      return apenasMoreadores;
    } catch (e) {
      AppLogger.error('VincularMorador', 'Erro ao carregar usuários: $e');
      rethrow;
    }
  }

  Future<void> _desvincularMoradorAtual() async {
    if (widget.moradorAtualId == null || widget.moradorAtualId!.isEmpty) {
      return;
    }

    try {
      final atual = await ApiService().getMorador(widget.moradorAtualId!);
      final dados = {
        'id': atual.id,
        'nome': atual.nome,
        'usuarioId': atual.usuarioId,
        'apartamentoId': null, // null = desvincular (backend remove automatically)
      };
      // Use MoradoresProvider to perform update so providers stay in sync
      await context.read<MoradoresProvider>().atualizarMorador(widget.moradorAtualId!, dados);
      AppLogger.info('VincularMorador', 'Morador anterior desvinculado via MoradoresProvider');
    } catch (e) {
      AppLogger.error('VincularMorador', 'Erro ao desvincular morador anterior: $e');
      // Não propaga erro - permite continuar com vinculação do novo morador
    }
  }

  Future<void> _vincular() async {
    if (_deixarSemMorador) {
      // Apenas desvincular, sem vincular novo morador
      setState(() => _isLoading = true);
      try {
        setState(() => _errorText = null);
        await _desvincularMoradorAtual();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            OwanyTheme.snackBar('Apartamento disponibilizado com sucesso!'),
          );
          widget.onSuccess();
          Navigator.pop(context);
        }
      } catch (e) {
        AppLogger.error('VincularMorador', 'Erro ao disponibilizar apartamento: $e');
        final mensagem = _formatException(e);
        if (mounted) {
          setState(() => _errorText = mensagem);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            OwanyTheme.snackBar(
              'Erro ao disponibilizar apartamento: $mensagem',
              type: SnackBarType.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    if (_usuarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OwanyTheme.snackBar('Selecione um usuário morador', type: SnackBarType.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      setState(() => _errorText = null);
      await _desvincularMoradorAtual();

      // Vincular usuário como morador ao apartamento via MoradoresProvider
      final moradorCriado = await context.read<MoradoresProvider>().criarMorador({
        'usuarioId': _usuarioSelecionado!.id,
        'apartamentoId': widget.apartamentoId,
      });
      AppLogger.info(
        'VincularMorador',
        'Morador criado: ${moradorCriado.nome} vinculado ao apartamento',
      );

      // Notificar morador em tempo real que foi vinculado a um apartamento
      try {
        await ApiService().criarNotificacao(
          usuarioId: _usuarioSelecionado!.id,
          titulo: 'Você foi vinculado a um apartamento',
          mensagem: 'Você foi adicionado como morador ao apartamento ${widget.apartamentoId}. Acesse o app para ver os detalhes.',
          tipo: 'Sistema',
        );
        AppLogger.info('VincularMorador', 'Notificação enviada para morador ${_usuarioSelecionado!.id}');
      } catch (e) {
        AppLogger.error('VincularMorador', 'Erro ao notificar morador: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar('Morador vinculado com sucesso!'),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('VincularMorador', 'Erro ao vincular: $e');
      if (mounted) {
        final providerMsg =
            context.read<MoradoresProvider>().errorMessage;
        final mensagem =
            providerMsg != null && providerMsg.isNotEmpty
                ? providerMsg
                : _formatException(e);
        setState(() => _errorText = mensagem);
        ScaffoldMessenger.of(context).showSnackBar(
          OwanyTheme.snackBar(
            'Erro ao vincular morador: $mensagem',
            type: SnackBarType.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OwanyTheme.primaryOrange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.moradorAtualId != null && widget.moradorAtualId!.isNotEmpty
                        ? Icons.swap_horiz_rounded
                        : Icons.person_add_rounded,
                    color: OwanyTheme.cardColor(context),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.moradorAtualId != null && widget.moradorAtualId!.isNotEmpty
                              ? 'Trocar Morador'
                              : 'Vincular Morador',
                          style: TextStyle(
                            color: OwanyTheme.cardColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Selecione um morador ou deixe o apartamento disponível',
                          style: TextStyle(
                            color: OwanyTheme.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: OwanyTheme.cardColor(context)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorText != null && _errorText!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OwanyTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: OwanyTheme.error.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: OwanyTheme.error),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: TextStyle(
                                color: OwanyTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  FutureBuilder<List<Usuario>>(
                    future: _usuariosMorador,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(color: OwanyTheme.primaryOrange),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: OwanyTheme.error),
                            SizedBox(height: 12),
                            Text(
                              'Erro ao carregar moradores',
                              style: TextStyle(color: OwanyTheme.error, fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: OwanyTheme.textMutedColor(context), fontSize: 12),
                            ),
                          ],
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Column(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: OwanyTheme.softOrange,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Nenhum usuário morador disponível',
                              style: TextStyle(
                                color: OwanyTheme.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }

                      final todosOsUsuarios = snapshot.data!;
                      final usuariosFiltrados = _filtroNome.isEmpty
                          ? todosOsUsuarios
                          : todosOsUsuarios
                              .where((u) =>
                                  u.nome.toLowerCase().contains(_filtroNome.toLowerCase()))
                              .toList();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Campo de busca
                          TextField(
                            onChanged: (value) => setState(() => _filtroNome = value),
                            decoration: InputDecoration(
                              hintText: 'Buscar usuário morador por nome...',
                              prefixIcon: Icon(Icons.search, color: OwanyTheme.primaryOrange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: OwanyTheme.borderColor(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: OwanyTheme.primaryOrange),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),

                          if (usuariosFiltrados.isEmpty && _filtroNome.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                'Nenhum usuário encontrado com "$_filtroNome"',
                                style: TextStyle(
                                  color: OwanyTheme.textMutedColor(context),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else ...[
                            SizedBox(height: 16),
                            // Lista de usuários
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: usuariosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final usuario = usuariosFiltrados[index];
                                  final isSelected = _usuarioSelecionado?.id == usuario.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      child: InkWell(
                                        onTap: () => setState(() {
                                          _usuarioSelecionado =
                                              isSelected ? null : usuario;
                                          _deixarSemMorador = false;
                                        }),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? OwanyTheme.primaryOrange.withValues(alpha: 0.1)
                                                : OwanyTheme.background,
                                            border: Border.all(
                                              color: isSelected
                                                  ? OwanyTheme.primaryOrange
                                                  : OwanyTheme.borderColor(context),
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: OwanyTheme.primaryOrange
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    usuario.nome[0].toUpperCase(),
                                                    style: TextStyle(
                                                      color: OwanyTheme
                                                          .primaryOrange,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      usuario.nome,
                                                      style: TextStyle(
                                                        color: OwanyTheme
                                                            .primaryBrown,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      usuario.nomeLogin,
                                                      style: TextStyle(
                                                        color: OwanyTheme.textMutedColor(context),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: OwanyTheme.primaryOrange,
                                                  size: 24,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 16),

                            // Opção: Deixar sem morador
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: OwanyTheme.error.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: _deixarSemMorador
                                      ? OwanyTheme.error
                                      : OwanyTheme.borderColor(context),
                                  width: _deixarSemMorador ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _deixarSemMorador = !_deixarSemMorador;
                                  if (_deixarSemMorador) {
                                    _usuarioSelecionado = null;
                                  }
                                }),
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _deixarSemMorador,
                                      onChanged: (value) => setState(() {
                                        _deixarSemMorador = value ?? false;
                                        if (_deixarSemMorador) {
                                          _usuarioSelecionado = null;
                                        }
                                      }),
                                      activeColor: OwanyTheme.error,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Deixar apartamento sem morador',
                                            style: TextStyle(
                                              color: OwanyTheme.textPrimary(context),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Disponibilizar o apartamento',
                                            style: TextStyle(
                                              color: OwanyTheme.textMutedColor(context),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botões de ação
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: _isLoading
                              ? OwanyTheme.textMutedColor(context)
                              : OwanyTheme.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                        onPressed:
                          _isLoading || (!_deixarSemMorador && _usuarioSelecionado == null)
                            ? null
                            : _vincular,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(OwanyTheme.cardColor(context)),
                              ),
                            )
                          : Icon(
                              _deixarSemMorador
                                  ? Icons.logout_rounded
                                  : Icons.check_rounded,
                            ),
                      label: Text(
                        _deixarSemMorador ? 'Disponibilizar' : 'Vincular',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deixarSemMorador
                            ? OwanyTheme.error
                            : OwanyTheme.primaryOrange,
                        foregroundColor: OwanyTheme.cardColor(context),
                        disabledBackgroundColor:
                            OwanyTheme.borderColor(context).withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}










