import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';

class _MainStage {
  const _MainStage(this.code, this.label);
  final int code;
  final String label;
}

const List<_MainStage> _stages = [
  _MainStage(0, 'Germination, débourrement'),
  _MainStage(1, 'Développement des feuilles'),
  _MainStage(2, 'Tallage, formation des ramifications'),
  _MainStage(3, 'Élongation de la tige, montaison'),
  _MainStage(4, 'Développement des organes de reproduction'),
  _MainStage(5, 'Apparition de l\'inflorescence, épiaison'),
  _MainStage(6, 'Floraison'),
  _MainStage(7, 'Développement des fruits'),
  _MainStage(8, 'Maturation des fruits et des graines'),
  _MainStage(9, 'Sénescence, récolte'),
];

String _family(String code) {
  if (code.isEmpty) return '';
  final digit = int.tryParse(code.substring(0, 1));
  if (digit == null || digit < 0 || digit > 9) return '';
  return _stages[digit].label;
}

Future<void> showBbchSheet(BuildContext context, {required Usage usage}) {
  final min = usage.bbchMin;
  final max = usage.bbchMax;
  final digits = <int>{
    if (int.tryParse(min.isEmpty ? '' : min.substring(0, 1)) != null)
      int.parse(min.substring(0, 1)),
    if (int.tryParse(max.isEmpty ? '' : max.substring(0, 1)) != null)
      int.parse(max.substring(0, 1)),
  };

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Row(
              children: [
                const Icon(Icons.grass, color: phytiaGreen, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Le stade BBCH',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: phytiaDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'BBCH est l\'échelle phénologique commune à toutes les plantes '
              'cultivées. Elle décrit l\'avancement de la culture avec 10 stades '
              'principaux (0 à 9), eux-mêmes subdivisés en codes à deux chiffres '
              '(00 à 99) : 00 pour la semence, 99 pour la récolte.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sur une fiche Phytia, le stade indique la fenêtre pendant laquelle '
              'l\'emploi est couvert par l\'autorisation de mise sur le marché. '
              'En dehors, le traitement n\'est pas homologué — et souvent moins '
              'efficace.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            if (min.isNotEmpty || max.isNotEmpty) ...[
              const SizedBox(height: 16),
              _WindowCard(usage: usage, min: min, max: max),
            ],
            const SizedBox(height: 20),
            Text(
              'Les 10 stades principaux',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: phytiaDark),
            ),
            const SizedBox(height: 8),
            for (final stage in _stages)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: digits.contains(stage.code)
                      ? const Color(0xFFE4F1E7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${stage.code}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: digits.contains(stage.code)
                              ? phytiaGreen
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: digits.contains(stage.code)
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Le libellé précis de chaque code dépend de la culture (échelle '
                'BBCH vigne, blé, olivier…). Les bornes affichées ici sont celles '
                'de la décision d\'autorisation : c\'est l\'étiquette du produit '
                'qui fait foi.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.usage,
    required this.min,
    required this.max,
  });

  final Usage usage;
  final String min;
  final String max;

  @override
  Widget build(BuildContext context) {
    final String titre;
    if (min.isNotEmpty && max.isNotEmpty) {
      titre = 'De BBCH $min à BBCH $max';
    } else if (max.isNotEmpty) {
      titre = 'Jusqu\'à BBCH $max';
    } else {
      titre = 'À partir de BBCH $min';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F1E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            usage.culture.isEmpty ? 'Votre usage' : usage.culture,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: phytiaDark,
            ),
          ),
          if (min.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '$min — ${_family(min)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF3F5B4A)),
            ),
          ],
          if (max.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '$max — ${_family(max)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF3F5B4A)),
            ),
          ],
        ],
      ),
    );
  }
}
