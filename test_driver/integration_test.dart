// =============================================================================
// DRIVER dos testes de integração
// -----------------------------------------------------------------------------
// Roda na máquina (não no device/navegador) e recebe cada print que o teste
// pede via `binding.takeScreenshot(nome)`, gravando em `.demo_frames/`.
//
// Essa pasta fica FORA do controle de versão (veja o .gitignore): ela é só a
// matéria-prima do GIF da demonstração.
// =============================================================================
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String nome,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final arquivo = File('.demo_frames/$nome.png');
      await arquivo.parent.create(recursive: true);
      await arquivo.writeAsBytes(bytes);
      stdout.writeln('print salvo: ${arquivo.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
