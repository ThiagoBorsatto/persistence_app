// =============================================================================
// DOMÍNIO — OrdemJogos (opções de ordenação da lista)
// -----------------------------------------------------------------------------
// Enum "enriquecido" (Dart 3) que reúne, em um só lugar, as três faces de cada
// opção de ordenação:
//
//   • `id`      -> string curta e ESTÁVEL, é o que gravamos no SharedPreferences
//                  (nunca gravamos o `index`: se um dia reordenarmos o enum, a
//                   preferência já salva passaria a apontar para outra opção);
//   • `label`   -> texto exibido no menu da AppBar;
//   • `orderBy` -> fragmento SQL usado no `ORDER BY` da consulta ao SQLite.
//
// Este enum NÃO importa Flutter: é domínio puro, compartilhado entre a camada
// de dados (que monta o SQL) e a UI (que desenha o menu).
// =============================================================================
enum OrdemJogos {
  tituloAsc(
    id: 'titulo_asc',
    label: 'Título (A → Z)',
    orderBy: 'titulo COLLATE NOCASE ASC',
  ),
  tituloDesc(
    id: 'titulo_desc',
    label: 'Título (Z → A)',
    orderBy: 'titulo COLLATE NOCASE DESC',
  ),
  notaDesc(
    id: 'nota_desc',
    label: 'Nota (maior primeiro)',
    // Desempate por título para a ordem ser sempre determinística.
    orderBy: 'nota DESC, titulo COLLATE NOCASE ASC',
  ),
  plataformaAsc(
    id: 'plataforma_asc',
    label: 'Plataforma (A → Z)',
    orderBy: 'plataforma COLLATE NOCASE ASC, titulo COLLATE NOCASE ASC',
  );

  const OrdemJogos({
    required this.id,
    required this.label,
    required this.orderBy,
  });

  /// Chave persistida no SharedPreferences.
  final String id;

  /// Texto mostrado no menu de ordenação.
  final String label;

  /// Fragmento SQL do `ORDER BY`. É uma CONSTANTE do código (nunca vem do
  /// usuário), por isso pode ser interpolada na query sem risco de SQL Injection.
  final String orderBy;

  /// Opção usada na primeira execução (ou se a preferência salva for inválida).
  static const OrdemJogos padrao = OrdemJogos.tituloAsc;

  /// Converte o `id` lido do SharedPreferences de volta para o enum.
  /// Se o valor não existir mais (app atualizado, dado inválido), cai no padrão.
  static OrdemJogos fromId(String? id) {
    return OrdemJogos.values.firstWhere(
      (o) => o.id == id,
      orElse: () => padrao,
    );
  }
}
