// =============================================================================
// CAMADA DE DADOS — ThemePreferences (SharedPreferences)
// -----------------------------------------------------------------------------
// Encapsula o acesso ao SharedPreferences para a configuração de TEMA.
// A UI não lida com chaves de string soltas — pede load()/save() num tipo claro.
//
// É uma das DUAS preferências persistidas do app; a outra é a ordenação da
// lista, em `ordenacao_preferences.dart`.
// =============================================================================
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  // Chave centralizada (evita erro de digitação espalhado).
  static const String _kIsDarkMode = 'is_dark_mode';

  /// Carrega a preferência de tema. Default = false (Modo Claro) na 1ª execução.
  Future<bool> loadIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsDarkMode) ?? false;
  }

  /// Persiste a preferência de tema.
  Future<void> saveIsDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDarkMode, isDark);
  }
}
