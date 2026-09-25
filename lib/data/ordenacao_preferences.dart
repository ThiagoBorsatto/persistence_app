// =============================================================================
// CAMADA DE DADOS — OrdenacaoPreferences (SharedPreferences)  ⭐ NOVA PREFERÊNCIA
// -----------------------------------------------------------------------------
// Segunda configuração persistida do app (a primeira é o tema, em
// `theme_preferences.dart`). Guarda a ORDENAÇÃO preferida da lista de jogos.
//
// Por que SharedPreferences e não SQLite?
//   São dados de natureza diferente. A estante de jogos é um conjunto de
//   registros estruturados e relacionáveis -> SQLite. "Como eu gosto de ver a
//   lista" é um único valor chave-valor de configuração -> SharedPreferences.
//
// Gravamos o `id` (String) do enum, e não o `index` (int): assim a preferência
// salva continua válida mesmo que a ordem das opções do enum mude no futuro.
// =============================================================================
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ordem_jogos.dart';

class OrdenacaoPreferences {
  // Chave centralizada (evita erro de digitação espalhado pelo código).
  static const String _kOrdemLista = 'ordem_lista_jogos';

  /// Carrega a ordenação preferida.
  /// Na 1ª execução (chave ausente) devolve `OrdemJogos.padrao` (Título A → Z).
  Future<OrdemJogos> loadOrdem() async {
    final prefs = await SharedPreferences.getInstance();
    return OrdemJogos.fromId(prefs.getString(_kOrdemLista));
  }

  /// Persiste a ordenação escolhida — é isso que faz a escolha sobreviver
  /// ao fechar e reabrir o app.
  Future<void> saveOrdem(OrdemJogos ordem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOrdemLista, ordem.id);
  }
}
