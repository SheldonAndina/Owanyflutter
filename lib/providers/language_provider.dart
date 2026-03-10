import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _idiomaCode = 'pt';

  String get idiomaCode => _idiomaCode;

  Future<void> loadIdioma() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _idiomaCode = prefs.getString(_languageKey) ?? 'pt';
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar idioma: $e');
    }
  }

  Future<void> setIdioma(String idiomaCode) async {
    if (_idiomaCode == idiomaCode) return;
    _idiomaCode = idiomaCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, idiomaCode);
    } catch (e) {
      debugPrint('Erro ao salvar idioma: $e');
    }
  }
}
