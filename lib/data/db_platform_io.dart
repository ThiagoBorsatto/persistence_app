// =============================================================================
// Bootstrap do banco — ANDROID / iOS / desktop
// -----------------------------------------------------------------------------
// Nada a fazer: o `sqflite` já registra o factory nativo do dispositivo.
// Este arquivo existe só para o `db_platform.dart` ter um par simétrico ao da
// web, mantendo `main()` com uma única chamada, igual nas duas plataformas.
// =============================================================================

/// Não faz nada em Android/iOS — o SQLite nativo já é o padrão.
Future<void> configurarBancoDaPlataforma() async {}
