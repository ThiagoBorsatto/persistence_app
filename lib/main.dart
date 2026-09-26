// =============================================================================
// ESTANTE DE JOGOS (OFFLINE)
// -----------------------------------------------------------------------------
// Ponto de entrada do app. Responsabilidade ÚNICA: inicializar o binding,
// carregar as PREFERÊNCIAS salvas (SharedPreferences) e subir o app.
//
// Duas preferências são lidas aqui, ANTES do primeiro frame — assim o app já
// abre no tema e na ordenação que o usuário escolheu na última sessão:
//   1) tema claro/escuro   -> ThemePreferences
//   2) ordenação da lista  -> OrdenacaoPreferences  (⭐ nova preferência)
//
// Arquitetura em camadas (cada arquivo tem uma responsabilidade):
//   lib/
//   ├── main.dart                        -> bootstrap (este arquivo)
//   ├── app.dart                         -> MaterialApp + gestão de tema
//   ├── models/
//   │   ├── jogo_model.dart              -> entidade imutável (toMap/fromMap)
//   │   └── ordem_jogos.dart             -> enum das opções de ordenação
//   ├── data/
//   │   ├── database_helper.dart         -> Singleton SQLite (abertura + schema)
//   │   ├── db_platform*.dart            -> escolhe o SQLite nativo ou o WebAssembly
//   │   ├── i_jogo_repository.dart       -> contrato do repositório
//   │   ├── jogo_repository.dart         -> CRUD (isola o sqflite da UI)
//   │   ├── theme_preferences.dart       -> SharedPreferences (tema)
//   │   └── ordenacao_preferences.dart   -> SharedPreferences (ordenação)
//   └── ui/
//       ├── home_page.dart               -> FutureBuilder + lista + busca
//       └── widgets/                     -> Card, formulário, estado vazio
// =============================================================================
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/db_platform.dart';
import 'data/ordenacao_preferences.dart';
import 'data/theme_preferences.dart';
import 'models/ordem_jogos.dart';

Future<void> main() async {
  // Obrigatório: usamos código assíncrono (SharedPreferences) antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Em Android/iOS não faz nada (o SQLite é nativo). No navegador, registra o
  // SQLite WebAssembly como banco do app. Precisa vir ANTES da primeira query.
  await configurarBancoDaPlataforma();

  // Carrega as preferências persistidas (defaults na 1ª execução:
  // Modo Claro e ordenação por Título A → Z).
  final bool isDark = await ThemePreferences().loadIsDarkMode();
  final OrdemJogos ordem = await OrdenacaoPreferences().loadOrdem();

  runApp(EstanteJogosApp(
    temaInicialEscuro: isDark,
    ordemInicial: ordem,
  ));
}
