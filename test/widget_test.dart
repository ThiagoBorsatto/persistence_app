// =============================================================================
// TESTES — Estante de Jogos
// -----------------------------------------------------------------------------
// Provam que o app funciona SEM device físico, cobrindo as três camadas:
//
//   1) CAMADA DE DADOS (SQLite real, em memória via `sqflite_common_ffi`):
//      testa o CRUD do JogoRepository e o ORDER BY de cada opção de ordenação.
//
//   2) PREFERÊNCIAS (SharedPreferences com store de teste): prova que a nova
//      preferência de ordenação é gravada e relida — é isso que faz a escolha
//      sobreviver ao fechar e reabrir o app.
//
//   3) CAMADA DE UI (FutureBuilder + estados): usa um repositório FAKE em
//      memória (Dart puro). Fazemos isso porque o SQLite via FFI usa I/O
//      assíncrono real, incompatível com o "fake async" do testWidgets —
//      então injetamos um fake, que é a prática recomendada para testar UI.
//
// Rode com  ->  flutter test
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:persistence_app/app.dart';
import 'package:persistence_app/data/i_jogo_repository.dart';
import 'package:persistence_app/data/jogo_repository.dart';
import 'package:persistence_app/data/ordenacao_preferences.dart';
import 'package:persistence_app/models/jogo_model.dart';
import 'package:persistence_app/models/ordem_jogos.dart';
import 'package:persistence_app/ui/widgets/jogo_card.dart';

/// Repositório FAKE em memória — implementa o mesmo contrato do real.
/// Resolve os Futures instantaneamente, o que funciona com o testWidgets.
class FakeJogoRepository implements IJogoRepository {
  final List<JogoModel> _dados = [];
  int _seq = 0;

  @override
  Future<int> insert(JogoModel jogo) async {
    _seq++;
    _dados.add(jogo.copyWith(id: _seq));
    return _seq;
  }

  /// Reproduz em Dart a mesma ordenação que o SQLite faria no `ORDER BY`.
  @override
  Future<List<JogoModel>> getAll({OrdemJogos ordem = OrdemJogos.padrao}) async {
    int porTitulo(JogoModel a, JogoModel b) =>
        a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());

    final Comparator<JogoModel> comparador = switch (ordem) {
      OrdemJogos.tituloAsc => porTitulo,
      OrdemJogos.tituloDesc => (a, b) => porTitulo(b, a),
      OrdemJogos.notaDesc => (a, b) {
          final c = b.nota.compareTo(a.nota);
          return c != 0 ? c : porTitulo(a, b);
        },
      OrdemJogos.plataformaAsc => (a, b) {
          final c = a.plataforma.toLowerCase().compareTo(
                b.plataforma.toLowerCase(),
              );
          return c != 0 ? c : porTitulo(a, b);
        },
    };

    return [..._dados]..sort(comparador);
  }

  @override
  Future<int> update(JogoModel jogo) async {
    final i = _dados.indexWhere((j) => j.id == jogo.id);
    if (i < 0) return 0;
    _dados[i] = jogo;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    final antes = _dados.length;
    _dados.removeWhere((j) => j.id == id);
    return antes - _dados.length;
  }
}

void main() {
  // -------------------------------------------------------------------------
  // 1) CAMADA DE DADOS — SQLite REAL em memória
  // -------------------------------------------------------------------------
  group('CRUD no SQLite real (Repository)', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    /// Deixa a tabela vazia antes de cada teste (isolamento).
    Future<JogoRepository> repoLimpo() async {
      final repo = JogoRepository();
      for (final j in await repo.getAll()) {
        await repo.delete(j.id!);
      }
      return repo;
    }

    test('insere, lista e remove um jogo', () async {
      final repo = await repoLimpo();

      // CREATE
      final id = await repo.insert(
        const JogoModel(
          titulo: 'The Witcher 3',
          plataforma: 'PC',
          genero: 'RPG',
          nota: 10,
        ),
      );
      expect(id, greaterThan(0));

      // READ
      var lista = await repo.getAll();
      expect(lista.length, 1);
      expect(lista.first.titulo, 'The Witcher 3');
      expect(lista.first.plataforma, 'PC');
      expect(lista.first.genero, 'RPG');
      expect(lista.first.nota, 10);

      // DELETE
      final removidos = await repo.delete(lista.first.id!);
      expect(removidos, 1);
      lista = await repo.getAll();
      expect(lista, isEmpty);
    });

    test('atualiza (UPDATE) um jogo existente', () async {
      final repo = await repoLimpo();

      final id = await repo.insert(
        const JogoModel(
          titulo: 'Titulo Antigo',
          plataforma: 'PS4',
          genero: 'Ação',
          nota: 6,
        ),
      );

      // Atualiza mantendo o mesmo id.
      final linhas = await repo.update(
        JogoModel(
          id: id,
          titulo: 'Titulo Novo',
          plataforma: 'PS5',
          genero: 'Aventura',
          nota: 9,
        ),
      );
      expect(linhas, 1);

      final lista = await repo.getAll();
      expect(lista.length, 1);
      expect(lista.first.id, id); // mesmo registro, não duplicou
      expect(lista.first.titulo, 'Titulo Novo');
      expect(lista.first.plataforma, 'PS5');
      expect(lista.first.genero, 'Aventura');
      expect(lista.first.nota, 9);
    });

    // A ordenação é responsabilidade do BANCO (ORDER BY), não da tela.
    test('respeita a ordenação escolhida (ORDER BY do SQLite)', () async {
      final repo = await repoLimpo();

      await repo.insert(const JogoModel(
          titulo: 'Celeste', plataforma: 'Switch', genero: 'Plataforma', nota: 9));
      await repo.insert(const JogoModel(
          titulo: 'Athena', plataforma: 'Xbox One', genero: 'Ação', nota: 5));
      await repo.insert(const JogoModel(
          titulo: 'Bastion', plataforma: 'PC', genero: 'RPG', nota: 10));

      Future<List<String>> titulosNaOrdem(OrdemJogos ordem) async {
        final lista = await repo.getAll(ordem: ordem);
        return lista.map((j) => j.titulo).toList();
      }

      expect(await titulosNaOrdem(OrdemJogos.tituloAsc),
          ['Athena', 'Bastion', 'Celeste']);
      expect(await titulosNaOrdem(OrdemJogos.tituloDesc),
          ['Celeste', 'Bastion', 'Athena']);
      expect(await titulosNaOrdem(OrdemJogos.notaDesc),
          ['Bastion', 'Celeste', 'Athena']); // 10, 9, 5
      expect(await titulosNaOrdem(OrdemJogos.plataformaAsc),
          ['Bastion', 'Celeste', 'Athena']); // PC, Switch, Xbox One
    });
  });

  // -------------------------------------------------------------------------
  // MAPEAMENTO DO MODELO
  // -------------------------------------------------------------------------
  group('Mapeamento do modelo', () {
    test('toMap/fromMap são simétricos', () {
      const original = JogoModel(
        id: 7,
        titulo: 'Hollow Knight',
        plataforma: 'Nintendo Switch',
        genero: 'Metroidvania',
        nota: 10,
      );
      final recriado = JogoModel.fromMap(original.toMap());
      expect(recriado.id, 7);
      expect(recriado.titulo, 'Hollow Knight');
      expect(recriado.plataforma, 'Nintendo Switch');
      expect(recriado.genero, 'Metroidvania');
      expect(recriado.nota, 10);
    });

    test('toMap omite o id quando ainda é null (deixa o AUTOINCREMENT agir)',
        () {
      const novo = JogoModel(
        titulo: 'Stardew Valley',
        plataforma: 'PC',
        genero: 'Simulação',
        nota: 9,
      );
      expect(novo.toMap().containsKey('id'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // 2) NOVA PREFERÊNCIA — ordenação persistida no SharedPreferences
  // -------------------------------------------------------------------------
  group('Nova SharedPreference (ordenação)', () {
    test('sem nada salvo, cai no padrão (Título A → Z)', () async {
      SharedPreferences.setMockInitialValues({});
      final ordem = await OrdenacaoPreferences().loadOrdem();
      expect(ordem, OrdemJogos.padrao);
      expect(ordem, OrdemJogos.tituloAsc);
    });

    test('salva e relê a ordenação escolhida', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = OrdenacaoPreferences();

      await prefs.saveOrdem(OrdemJogos.notaDesc);
      expect(await prefs.loadOrdem(), OrdemJogos.notaDesc);

      await prefs.saveOrdem(OrdemJogos.plataformaAsc);
      expect(await prefs.loadOrdem(), OrdemJogos.plataformaAsc);
    });

    test('um valor salvo inválido não quebra o app — volta ao padrão',
        () async {
      SharedPreferences.setMockInitialValues(
        {'ordem_lista_jogos': 'opcao_que_nao_existe_mais'},
      );
      expect(await OrdenacaoPreferences().loadOrdem(), OrdemJogos.padrao);
    });

    test('persistimos o id (String), não o index do enum', () {
      // Garante que a preferência salva continue válida se um dia a ordem
      // das opções do enum mudar.
      expect(OrdemJogos.fromId('nota_desc'), OrdemJogos.notaDesc);
      expect(OrdemJogos.fromId(null), OrdemJogos.padrao);
    });
  });

  // -------------------------------------------------------------------------
  // 3) CAMADA DE UI — com repositório FAKE
  // -------------------------------------------------------------------------
  group('UI (FutureBuilder)', () {
    // A HomePage grava a ordenação no SharedPreferences — nos testes usamos
    // o store em memória para não depender de plugin nativo.
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('mostra estado vazio quando não há jogos', (tester) async {
      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle(); // aguarda o FutureBuilder resolver

      expect(find.text('Estante de Jogos'), findsOneWidget); // AppBar
      expect(find.text('SQLite ativo'), findsOneWidget); // indicador do banco
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('exibe jogo salvo na lista', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
        titulo: 'Elden Ring',
        plataforma: 'PS5',
        genero: 'RPG',
        nota: 10,
      ));

      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Elden Ring'), findsOneWidget);
      expect(find.text('RPG • PS5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // selo da nota
    });

    testWidgets('filtra a lista pela busca', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Hades', plataforma: 'PC', genero: 'Roguelike', nota: 9));
      await fake.insert(const JogoModel(
          titulo: 'Forza Horizon 5',
          plataforma: 'Xbox Series X',
          genero: 'Corrida',
          nota: 8));

      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      // Ambos aparecem inicialmente.
      expect(find.text('Hades'), findsOneWidget);
      expect(find.text('Forza Horizon 5'), findsOneWidget);

      // Digita na busca -> filtra (aqui, pelo gênero).
      await tester.enterText(find.byType(TextField), 'corrida');
      await tester.pumpAndSettle();

      expect(find.text('Hades'), findsNothing);
      expect(find.text('Forza Horizon 5'), findsOneWidget);
    });

    // REGRESSÃO: garante que, ao cadastrar pelo formulário, a lista atualiza
    // SEM precisar reabrir o app. Esse teste teria pego o bug do `setState`
    // que retornava um Future (o refresh não era aplicado).
    testWidgets('cadastrar pelo formulário atualiza a lista na hora',
        (tester) async {
      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle();

      // Começa vazio.
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);

      // Abre o formulário (FAB).
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Preenche os campos.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'God of War');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plataforma'), 'PS5');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Gênero'), 'Ação');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '9');

      // Salva.
      await tester.tap(find.text('Salvar no banco offline'));
      await tester.pumpAndSettle();

      // A lista atualizou sem reabrir o app.
      expect(find.text('Nenhum jogo salvo offline'), findsNothing);
      expect(find.text('God of War'), findsOneWidget);
      expect(find.text('Ação • PS5'), findsOneWidget);
    });

    testWidgets('o formulário recusa nota fora da faixa 0..10',
        (tester) async {
      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: FakeJogoRepository(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'Jogo Qualquer');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Plataforma'), 'PC');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Gênero'), 'Indie');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nota'), '42');

      await tester.tap(find.text('Salvar no banco offline'));
      await tester.pumpAndSettle();

      // O form continua aberto, com a mensagem de validação...
      expect(find.text('A nota vai de 0 a 10.'), findsOneWidget);
      expect(find.text('Cadastrar jogo'), findsOneWidget);
      // ...e nada foi gravado: nenhum card na lista atrás do formulário.
      expect(find.byType(JogoCard), findsNothing);
    });

    testWidgets('editar pelo formulário atualiza o card', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
        titulo: 'Titulo Antigo',
        plataforma: 'PC',
        genero: 'RPG',
        nota: 7,
      ));

      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Titulo Antigo'), findsOneWidget);

      // Abre a edição pelo botão de lápis.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // O formulário abre em modo edição, pré-preenchido.
      expect(find.text('Editar jogo'), findsOneWidget);

      // Altera o título e salva.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'), 'Titulo Novo');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      // O card reflete a alteração, sem duplicar registros.
      expect(find.text('Titulo Antigo'), findsNothing);
      expect(find.text('Titulo Novo'), findsOneWidget);
    });

    testWidgets('remover pede confirmação e apaga o card', (tester) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Cuphead', plataforma: 'PC', genero: 'Run and gun', nota: 9));

      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        repository: fake,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remover jogo?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
      await tester.pumpAndSettle();

      expect(find.text('Cuphead'), findsNothing);
      expect(find.text('Nenhum jogo salvo offline'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // A NOVA PREFERÊNCIA NA PRÁTICA — do menu até o SharedPreferences
  // -------------------------------------------------------------------------
  group('UI da ordenação (nova SharedPreference)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// Monta o app já com três jogos, para dar o que ordenar.
    Future<void> montarComTresJogos(
      WidgetTester tester, {
      OrdemJogos ordemInicial = OrdemJogos.padrao,
    }) async {
      final fake = FakeJogoRepository();
      await fake.insert(const JogoModel(
          titulo: 'Celeste', plataforma: 'Switch', genero: 'Plataforma', nota: 9));
      await fake.insert(const JogoModel(
          titulo: 'Athena', plataforma: 'Xbox One', genero: 'Ação', nota: 5));
      await fake.insert(const JogoModel(
          titulo: 'Bastion', plataforma: 'PC', genero: 'RPG', nota: 10));

      await tester.pumpWidget(EstanteJogosApp(
        temaInicialEscuro: false,
        ordemInicial: ordemInicial,
        repository: fake,
      ));
      await tester.pumpAndSettle();
    }

    /// Lê os títulos na ORDEM em que os cards aparecem na tela.
    List<String> titulosNaTela(WidgetTester tester) {
      return tester
          .widgetList<JogoCard>(find.byType(JogoCard))
          .map((card) => card.jogo.titulo)
          .toList();
    }

    testWidgets('trocar a ordenação no menu reordena a lista E persiste',
        (tester) async {
      await montarComTresJogos(tester);

      // Começa em Título A → Z (o padrão), indicado no chip e na lista.
      expect(find.text('Título (A → Z)'), findsOneWidget);
      expect(titulosNaTela(tester), ['Athena', 'Bastion', 'Celeste']);

      // Abre o menu de ordenação e escolhe "Nota (maior primeiro)".
      await tester.tap(find.byType(PopupMenuButton<OrdemJogos>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(
        CheckedPopupMenuItem<OrdemJogos>,
        'Nota (maior primeiro)',
      ));
      await tester.pumpAndSettle();

      // O chip mostra a nova ordenação...
      expect(find.text('Nota (maior primeiro)'), findsOneWidget);
      // ...a lista foi relida do banco já reordenada (notas 10, 9, 5)...
      expect(titulosNaTela(tester), ['Bastion', 'Celeste', 'Athena']);
      // ...e a escolha FOI GRAVADA no SharedPreferences (sobrevive ao restart).
      expect(await OrdenacaoPreferences().loadOrdem(), OrdemJogos.notaDesc);
    });

    testWidgets('ao reabrir, o app usa a ordenação que estava salva',
        (tester) async {
      // Simula a 2ª abertura do app: a preferência já está no disco.
      SharedPreferences.setMockInitialValues(
        {'ordem_lista_jogos': 'titulo_desc'},
      );
      final ordemSalva = await OrdenacaoPreferences().loadOrdem();
      expect(ordemSalva, OrdemJogos.tituloDesc);

      // O main() passaria exatamente esse valor para o app.
      await montarComTresJogos(tester, ordemInicial: ordemSalva);

      // Abre já em Z → A, sem o usuário tocar em nada.
      expect(find.text('Título (Z → A)'), findsOneWidget);
      expect(titulosNaTela(tester), ['Celeste', 'Bastion', 'Athena']);
    });
  });
}
