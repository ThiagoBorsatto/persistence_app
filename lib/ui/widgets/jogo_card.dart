// =============================================================================
// WIDGET — JogoCard
// -----------------------------------------------------------------------------
// Representa UM jogo na lista: Card + ListTile + avatar com a sigla da
// plataforma + selo da nota + botões de editar e remover.
// Recebe callbacks para não acoplar à HomePage.
// =============================================================================
import 'package:flutter/material.dart';
import '../../models/jogo_model.dart';

class JogoCard extends StatelessWidget {
  final JogoModel jogo;
  final VoidCallback onRemover;
  final VoidCallback onEditar;

  const JogoCard({
    super.key,
    required this.jogo,
    required this.onRemover,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        // Tocar no card também abre a edição (atalho comum em apps).
        onTap: onEditar,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(
            siglaPlataforma(jogo.plataforma),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          jogo.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${jogo.genero} • ${jogo.plataforma}'),
        // Selo da nota + dois botões: editar (lápis) e remover (lixeira).
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SeloNota(nota: jogo.nota),
            IconButton(
              tooltip: 'Editar',
              icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
              onPressed: onEditar,
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onRemover,
            ),
          ],
        ),
      ),
    );
  }

  /// Gera a sigla curta da plataforma para o avatar.
  ///
  /// Primeiro tenta um apelido conhecido ("PlayStation 5" -> "PS5"); se não
  /// conhecer, cai numa regra genérica:
  ///   • uma palavra    -> 3 primeiras letras ("Steam" -> "STE")
  ///   • várias palavras -> iniciais, no máximo 3 ("Nintendo Switch 2" -> "NS2")
  static String siglaPlataforma(String plataforma) {
    final limpo = plataforma.trim();
    if (limpo.isEmpty) return '?';

    final conhecida = _apelidos[limpo.toLowerCase()];
    if (conhecida != null) return conhecida;

    final palavras =
        limpo.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (palavras.length == 1) {
      final unica = palavras.first;
      return unica.substring(0, unica.length >= 3 ? 3 : unica.length)
          .toUpperCase();
    }
    return palavras.map((w) => w[0].toUpperCase()).take(3).join();
  }

  /// Apelidos das plataformas mais comuns (chave sempre em minúsculas).
  static const Map<String, String> _apelidos = {
    'pc': 'PC',
    'steam': 'PC',
    'playstation': 'PS',
    'playstation 4': 'PS4',
    'ps4': 'PS4',
    'playstation 5': 'PS5',
    'ps5': 'PS5',
    'xbox': 'XBO',
    'xbox one': 'XBO',
    'xbox series x': 'XSX',
    'xbox series s': 'XSS',
    'nintendo switch': 'SWI',
    'switch': 'SWI',
    'android': 'AND',
    'ios': 'IOS',
  };
}

/// Selo arredondado com a nota do jogo (0 a 10).
/// A cor muda conforme a faixa — leitura visual rápida ao ordenar por nota.
class _SeloNota extends StatelessWidget {
  final int nota;

  const _SeloNota({required this.nota});

  @override
  Widget build(BuildContext context) {
    final Color cor = switch (nota) {
      >= 8 => Colors.green.shade600,
      >= 5 => Colors.orange.shade700,
      _ => Colors.red.shade600,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: cor),
          const SizedBox(width: 2),
          Text(
            '$nota',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
