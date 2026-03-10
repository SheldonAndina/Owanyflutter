import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/niveis_acesso_provider.dart';
import '../providers/auth_provider.dart';
import '../models/niveis_acesso.dart';
import '../models/enums.dart';
import '../theme/owany_theme.dart';

/// Widget que renderiza seu child apenas se o usuário tiver a permissão necessária.
/// Caso contrário, mostra um widget de acesso negado ou fica invisível.
/// 
/// Exemplo de uso:
/// ```dart
/// PermissaoGuard(
///   permissao: Permissoes.usuariosCreate,
///   child: ElevatedButton(
///     onPressed: _criarUsuario,
///     child: Text('Criar Usuário'),
///   ),
/// )
/// ```
class PermissaoGuard extends StatelessWidget {
  /// Permissão necessária para exibir o child
  final String permissao;

  /// Widget a ser exibido se tiver permissão
  final Widget child;

  /// Widget alternativo quando não tem permissão (opcional)
  /// Se não fornecido, o widget fica invisível
  final Widget? semPermissaoWidget;

  /// Se true, usa verificação local baseada no role
  /// Se false, usa verificação do backend via provider
  final bool usarVerificacaoLocal;

  const PermissaoGuard({
    super.key,
    required this.permissao,
    required this.child,
    this.semPermissaoWidget,
    this.usarVerificacaoLocal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (usarVerificacaoLocal) {
      return _buildComVerificacaoLocal(context);
    }
    return _buildComProvider(context);
  }

  Widget _buildComVerificacaoLocal(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    
    if (usuario == null) {
      return semPermissaoWidget ?? const SizedBox.shrink();
    }

    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    final temPermissao = permissoesDoRole.contains(permissao);

    if (temPermissao) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }

  Widget _buildComProvider(BuildContext context) {
    final provider = context.watch<NiveisAcessoProvider>();
    final temPermissao = provider.temPermissao(permissao);

    if (temPermissao) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }
}

/// Widget que renderiza seu child apenas se o usuário tiver TODAS as permissões.
class TodasPermissoesGuard extends StatelessWidget {
  final List<String> permissoes;
  final Widget child;
  final Widget? semPermissaoWidget;
  final bool usarVerificacaoLocal;

  const TodasPermissoesGuard({
    super.key,
    required this.permissoes,
    required this.child,
    this.semPermissaoWidget,
    this.usarVerificacaoLocal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (usarVerificacaoLocal) {
      return _buildComVerificacaoLocal(context);
    }
    return _buildComProvider(context);
  }

  Widget _buildComVerificacaoLocal(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    
    if (usuario == null) {
      return semPermissaoWidget ?? const SizedBox.shrink();
    }

    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    final temTodas = permissoes.every((p) => permissoesDoRole.contains(p));

    if (temTodas) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }

  Widget _buildComProvider(BuildContext context) {
    final provider = context.watch<NiveisAcessoProvider>();
    final temTodas = provider.temTodasPermissoes(permissoes);

    if (temTodas) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }
}

/// Widget que renderiza seu child se o usuário tiver QUALQUER UMA das permissões.
class AlgumaPermissaoGuard extends StatelessWidget {
  final List<String> permissoes;
  final Widget child;
  final Widget? semPermissaoWidget;
  final bool usarVerificacaoLocal;

  const AlgumaPermissaoGuard({
    super.key,
    required this.permissoes,
    required this.child,
    this.semPermissaoWidget,
    this.usarVerificacaoLocal = true,
  });

  @override
  Widget build(BuildContext context) {
    if (usarVerificacaoLocal) {
      return _buildComVerificacaoLocal(context);
    }
    return _buildComProvider(context);
  }

  Widget _buildComVerificacaoLocal(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    
    if (usuario == null) {
      return semPermissaoWidget ?? const SizedBox.shrink();
    }

    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    final temAlguma = permissoes.any((p) => permissoesDoRole.contains(p));

    if (temAlguma) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }

  Widget _buildComProvider(BuildContext context) {
    final provider = context.watch<NiveisAcessoProvider>();
    final temAlguma = provider.temAlgumaPermissao(permissoes);

    if (temAlguma) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }
}

/// Widget que renderiza seu child apenas se o usuário tiver um dos roles especificados.
class RoleGuard extends StatelessWidget {
  final List<UsuarioTipo> roles;
  final Widget child;
  final Widget? semPermissaoWidget;

  const RoleGuard({
    super.key,
    required this.roles,
    required this.child,
    this.semPermissaoWidget,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    
    if (usuario == null) {
      return semPermissaoWidget ?? const SizedBox.shrink();
    }

    if (roles.contains(usuario.tipo)) {
      return child;
    }
    
    return semPermissaoWidget ?? const SizedBox.shrink();
  }
}

/// Widget padronizado para mostrar quando o acesso é negado
class AcessoNegadoWidget extends StatelessWidget {
  final String? titulo;
  final String? mensagem;
  final IconData? icone;
  final VoidCallback? onVoltar;

  const AcessoNegadoWidget({
    super.key,
    this.titulo,
    this.mensagem,
    this.icone,
    this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: OwanyTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone ?? Icons.lock_outline,
                size: 48,
                color: OwanyTheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              titulo ?? 'Acesso Restrito',
              style: OwanyTheme.titleStyle(context, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensagem ?? 'Você não tem permissão para acessar esta funcionalidade.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OwanyTheme.textMutedColor(context),
                fontSize: 14,
              ),
            ),
            if (onVoltar != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: OwanyTheme.primaryButtonStyle(),
                onPressed: onVoltar,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tela completa de acesso negado
class AcessoNegadoScreen extends StatelessWidget {
  final String? titulo;
  final String? mensagem;

  const AcessoNegadoScreen({
    super.key,
    this.titulo,
    this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwanyTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: OwanyTheme.primaryOrange,
        foregroundColor: OwanyTheme.white,
        title: const Text('Acesso Restrito'),
      ),
      body: AcessoNegadoWidget(
        titulo: titulo,
        mensagem: mensagem,
        onVoltar: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Extensão para verificar permissões diretamente no BuildContext
extension PermissaoContextExtension on BuildContext {
  /// Verifica se o usuário atual tem uma permissão específica (verificação local)
  bool temPermissaoLocal(String permissao) {
    final authProvider = read<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    if (usuario == null) return false;
    
    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    return permissoesDoRole.contains(permissao);
  }

  /// Verifica se o usuário atual tem uma permissão específica (via provider)
  bool temPermissao(String permissao) {
    final provider = read<NiveisAcessoProvider>();
    return provider.temPermissao(permissao);
  }

  /// Verifica se o usuário atual tem todas as permissões (verificação local)
  bool temTodasPermissoesLocal(List<String> permissoes) {
    final authProvider = read<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    if (usuario == null) return false;
    
    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    return permissoes.every((p) => permissoesDoRole.contains(p));
  }

  /// Verifica se o usuário atual tem alguma das permissões (verificação local)
  bool temAlgumaPermissaoLocal(List<String> permissoes) {
    final authProvider = read<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    if (usuario == null) return false;
    
    final permissoesDoRole = RolePermissoes.getPermissoesParaRole(usuario.tipo);
    return permissoes.any((p) => permissoesDoRole.contains(p));
  }

  /// Verifica se o usuário atual tem um dos roles especificados
  bool temRole(List<UsuarioTipo> roles) {
    final authProvider = read<AuthProvider>();
    final usuario = authProvider.usuarioAtual;
    if (usuario == null) return false;
    
    return roles.contains(usuario.tipo);
  }

  /// Acesso rápido ao role atual do usuário
  UsuarioTipo? get roleAtual {
    final authProvider = read<AuthProvider>();
    return authProvider.usuarioAtual?.tipo;
  }
}

/// Mixin para adicionar verificações de permissão em StatefulWidgets
mixin PermissaoMixin<T extends StatefulWidget> on State<T> {
  /// Verifica se o usuário atual tem uma permissão específica
  bool temPermissao(String permissao) {
    return context.temPermissaoLocal(permissao);
  }

  /// Verifica se o usuário atual tem todas as permissões
  bool temTodasPermissoes(List<String> permissoes) {
    return context.temTodasPermissoesLocal(permissoes);
  }

  /// Verifica se o usuário atual tem alguma das permissões
  bool temAlgumaPermissao(List<String> permissoes) {
    return context.temAlgumaPermissaoLocal(permissoes);
  }

  /// Verifica se o usuário atual tem um dos roles especificados
  bool temRole(List<UsuarioTipo> roles) {
    return context.temRole(roles);
  }

  /// Verifica e executa uma ação se tiver permissão
  void executarSePermitido(String permissao, VoidCallback acao, {VoidCallback? semPermissao}) {
    if (temPermissao(permissao)) {
      acao();
    } else if (semPermissao != null) {
      semPermissao();
    } else {
      _mostrarMensagemSemPermissao();
    }
  }

  void _mostrarMensagemSemPermissao() {
    ScaffoldMessenger.of(context).showSnackBar(
      OwanyTheme.snackBar(
        'Você não tem permissão para esta ação',
        type: SnackBarType.warning,
      ),
    );
  }
}
