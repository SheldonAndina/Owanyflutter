import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class AuthService {
  static const String _usuarioKey = 'usuario_logado';
  static const String _tokenKey = 'jwt_token';

  /// Salva o usuário logado localmente
  static Future<void> salvarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = jsonEncode(usuario.toJson());
    await prefs.setString(_usuarioKey, usuarioJson);
  }

  /// Carrega o usuário logado do armazenamento local
  static Future<Usuario?> carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString(_usuarioKey);

    if (usuarioJson == null) return null;

    try {
      final usuarioMap = jsonDecode(usuarioJson) as Map<String, dynamic>;
      return Usuario.fromJson(usuarioMap);
    } catch (e) {
      return null;
    }
  }

  /// Salva o token JWT
  static Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Carrega o token JWT
  static Future<String?> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove os dados de login (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usuarioKey);
    await prefs.remove(_tokenKey);
  }

  /// Verifica se há um usuário logado
  static Future<bool> temUsuarioLogado() async {
    final usuario = await carregarUsuario();
    return usuario != null;
  }
}
