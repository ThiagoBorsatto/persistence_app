// =============================================================================
// TESTE DE INTEGRAÇÃO / ROTEIRO DA DEMONSTRAÇÃO — Estante de Jogos
// -----------------------------------------------------------------------------
// Diferente de `test/widget_test.dart`, aqui NÃO existe repositório fake: o app
// sobe inteiro, com o SQLite REAL da plataforma (o arquivo .db no celular, ou o
// sqlite3.wasm + IndexedDB no navegador) e o SharedPreferences REAL.
//
// O teste percorre o roteiro completo do app e tira um print em cada etapa —
// são esses prints que montam o GIF da demonstração.
//
// Como rodar (navegador):
//   chromedriver --port=4444
//   flutter drive --driver=test_driver/integration_test.dart \
//                 --target=integration_test/demo_test.dart -d chrome
//
// Como rodar (celular/emulador Android conectado):
//   flutter drive --driver=test_driver/integration_test.dart \
//                 --target=integration_test/demo_test.dart
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:persistence_app/app.dart';
import 'package:persistence_app/data/db_platform.dart';
import 'package:persistence_app/data/jogo_repository.dart';
import 'package:persistence_app/data/ordenacao_preferences.dart';
import 'package:persistence_app/models/ordem_jogos.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('roteiro da demonstração de ponta a ponta', (tester) async {
    // Mesmo bootstrap do main(): escolhe o SQLite nativo ou o WebAssembly.
    await configurarBancoDaPlataforma();

    // Estado limpo, para a demonstração ser sempre igual.
    final repo = JogoRepository();
    for (final j in await repo.getAll()) {
      await repo.delete(j.id!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Contador de prints, para os arquivos saírem na ordem do roteiro.
    var passo = 0;
    Future<void> print_(String nome) async {
      passo++;
      final numero = passo.toString().padLeft(2, '0');
      await binding.takeScreenshot('$numero-$nome');
    }

    /// Preenche e salva um jogo pelo formulário (BottomSheet).
    Future<void> cadastrar(
      String titulo,
      String plataforma,
      String genero,
      String nota, {
      String? printDoFormulario,
    }) async {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), titulo);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plataforma'), plataforma);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Gênero'), genero);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), nota);
      await tester.pumpAndSettle();
      if (printDoFormulario != null) await print_(printDoFormulario);
      await tester.tap(find.text('Salvar no banco offline'));
      await tester.pumpAndSettle();
    }

    // -----------------------------------------------------------------------
    // 1) App abre vazio, lendo um banco recém-criado.
    // -----------------------------------------------------------------------
    await tester.pumpWidget(const EstanteJogosApp(
      temaInicialEscuro: false,
      ordemInicial: OrdemJogos.padrao,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);
    await print_('estado-vazio');

    // -----------------------------------------------------------------------
    // 2) CREATE — três jogos, o primeiro mostrando o formulário preenchido.
    // -----------------------------------------------------------------------
    await cadastrar('The Witcher 3', 'PC', 'RPG', '10',
        printDoFormulario: 'formulario-preenchido');
    expect(find.text('The Witcher 3'), findsOneWidget);
    await print_('primeiro-jogo-salvo');

    await cadastrar('Hollow Knight', 'Nintendo Switch', 'Metroidvania', '9');
    await cadastrar('Forza Horizon 5', 'Xbox Series X', 'Corrida', '7');
    expect(find.byType(Card), findsNWidgets(3));
    await print_('lista-com-tres-jogos');

    // -----------------------------------------------------------------------
    // 3) READ / pesquisa — filtra pelo gênero.
    // -----------------------------------------------------------------------
    await tester.enterText(find.byType(TextField), 'corrida');
    await tester.pumpAndSettle();
    expect(find.text('Forza Horizon 5'), findsOneWidget);
    expect(find.text('The Witcher 3'), findsNothing);
    await print_('pesquisa-por-genero');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // -----------------------------------------------------------------------
    // 4) ⭐ NOVA PREFERÊNCIA — troca a ordenação (menu -> ORDER BY -> prefs).
    // -----------------------------------------------------------------------
    await tester.tap(find.byType(PopupMenuButton<OrdemJogos>));
    await tester.pumpAndSettle();
    await print_('menu-de-ordenacao');

    await tester.tap(find.widgetWithText(
      CheckedPopupMenuItem<OrdemJogos>,
      'Nota (maior primeiro)',
    ));
    await tester.pumpAndSettle();
    // A escolha foi gravada no SharedPreferences — sobrevive ao fechar o app.
    expect(await OrdenacaoPreferences().loadOrdem(), OrdemJogos.notaDesc);
    await print_('ordenado-por-nota');

    // -----------------------------------------------------------------------
    // 5) UPDATE — edita a nota do Forza (7 -> 9) e a lista se reordena.
    // -----------------------------------------------------------------------
    await tester.tap(find.widgetWithText(Card, 'Forza Horizon 5'));
    await tester.pumpAndSettle();
    expect(find.text('Editar jogo'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '9');
    await tester.pumpAndSettle();
    await print_('editando-a-nota');

    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    await print_('nota-atualizada');

    // -----------------------------------------------------------------------
    // 6) TEMA — a outra preferência persistida.
    // -----------------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    await print_('tema-escuro');

    // -----------------------------------------------------------------------
    // 7) DELETE — com diálogo de confirmação.
    // -----------------------------------------------------------------------
    final cardHollow = find.ancestor(
      of: find.text('Hollow Knight'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(
      of: cardHollow,
      matching: find.byIcon(Icons.delete_outline),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Remover jogo?'), findsOneWidget);
    await print_('confirmar-remocao');

    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Hollow Knight'), findsNothing);
    expect(find.byType(Card), findsNWidgets(2));
    await print_('apos-remover');

    // -----------------------------------------------------------------------
    // 8) REABRIR O APP — prova que TUDO sobreviveu: os jogos (SQLite) e as
    //    duas preferências (SharedPreferences).
    // -----------------------------------------------------------------------
    final temaSalvo = prefs.getBool('is_dark_mode') ?? false;
    final ordemSalva = await OrdenacaoPreferences().loadOrdem();
    expect(temaSalvo, isTrue);
    expect(ordemSalva, OrdemJogos.notaDesc);

    // Descarta a árvore e monta o app de novo, como faria o main() na 2ª
    // abertura: lendo tema e ordenação do disco.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(EstanteJogosApp(
      temaInicialEscuro: temaSalvo,
      ordemInicial: ordemSalva,
    ));
    await tester.pumpAndSettle();

    // Reabriu escuro, ordenado por nota, com os 2 jogos que restaram no banco.
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Nota (maior primeiro)'), findsOneWidget);
    await print_('reaberto-preferencias-mantidas');
  });
}
