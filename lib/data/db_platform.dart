// =============================================================================
// CAMADA DE DADOS — Bootstrap do banco por PLATAFORMA
// -----------------------------------------------------------------------------
// O `sqflite` é NATIVO em Android e iOS: lá não há nada a configurar. No
// navegador não existe SQLite nativo, então usamos o `sqflite_common_ffi_web`,
// que roda o MESMO SQLite compilado para WebAssembly e persiste em IndexedDB.
//
// A escolha é feita em tempo de COMPILAÇÃO por export condicional: o arquivo
// web (que importa bibliotecas de JS interop) nunca entra no build do Android,
// e vice-versa. Assim o app roda no emulador/celular e também no Chrome, sem
// `if` de plataforma espalhado pelo código.
//
//   dart.library.js_interop presente  -> db_platform_web.dart
//   caso contrário (Android/iOS/desktop) -> db_platform_io.dart
// =============================================================================
export 'db_platform_io.dart' if (dart.library.js_interop) 'db_platform_web.dart';
