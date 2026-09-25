// =============================================================================
// WIDGET RAIZ — EstanteJogosApp
// -----------------------------------------------------------------------------
// Configura o MaterialApp e gerencia o estado do TEMA (claro/escuro),
// persistindo cada alternância no SharedPreferences via ThemePreferences.
//
// A ordenação da lista chega aqui apenas como valor INICIAL (lido no main) e é
// repassada à HomePage, que a gerencia e persiste — porque só a lista depende
// dela, enquanto o tema afeta o MaterialApp inteiro.
// =============================================================================
import 'package:flutter/material.dart';

import 'data/i_jogo_repository.dart';
import 'data/theme_preferences.dart';
import 'models/ordem_jogos.dart';
import 'ui/home_page.dart';

class EstanteJogosApp extends StatefulWidget {
  final bool temaInicialEscuro;

  /// Ordenação lida do SharedPreferences no bootstrap.
  final OrdemJogos ordemInicial;

  /// Repositório injetável (opcional). Usado nos testes de UI.
  final IJogoRepository? repository;

  const EstanteJogosApp({
    super.key,
    required this.temaInicialEscuro,
    this.ordemInicial = OrdemJogos.padrao,
    this.repository,
  });

  @override
  State<EstanteJogosApp> createState() => _EstanteJogosAppState();
}

class _EstanteJogosAppState extends State<EstanteJogosApp> {
  final ThemePreferences _themePrefs = ThemePreferences();
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.temaInicialEscuro; // valor lido no main()
  }

  /// Alterna o tema e PERSISTE a escolha no SharedPreferences.
  Future<void> _alternarTema() async {
    setState(() => _isDarkMode = !_isDarkMode);
    await _themePrefs.saveIsDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    // Roxo "gamer" como cor semente do Material 3.
    const Color seed = Color(0xFF6A1B9A);

    return MaterialApp(
      title: 'Estante de Jogos',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(
        isDarkMode: _isDarkMode,
        onAlternarTema: _alternarTema,
        ordemInicial: widget.ordemInicial,
        repository: widget.repository,
      ),
    );
  }
}
