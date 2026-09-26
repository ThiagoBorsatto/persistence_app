// =============================================================================
// Bootstrap do banco — NAVEGADOR (web)
// -----------------------------------------------------------------------------
// Troca o factory padrão do sqflite pelo do `sqflite_common_ffi_web`, que carrega
// `web/sqlite3.wasm` (o mesmo SQLite, compilado para WebAssembly) e guarda o
// banco no IndexedDB do navegador — então os dados sobrevivem ao recarregar
// e ao fechar/reabrir a aba, como o arquivo .db sobrevive no celular.
//
// Usamos a variante SEM web worker: ela dispensa os cabeçalhos COOP/COEP que o
// worker compartilhado exigiria do servidor. Em troca, as consultas rodam na
// thread principal — irrelevante no volume deste app.
// =============================================================================
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Registra o SQLite WebAssembly como banco do app quando rodando no navegador.
Future<void> configurarBancoDaPlataforma() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
