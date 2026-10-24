import 'package:flutter/material.dart';

import '../../data/journal_export.dart';
import '../../data/scope.dart';

/// Avertit quand la cible saisie ne figure pas parmi les usages autorisés du
/// produit pour cette culture. Jamais bloquant : c'est un garde-fou, pas une
/// interdiction (dérogations, cibles voisines, cas particuliers existent).
class CibleWarning extends StatelessWidget {
  const CibleWarning({
    super.key,
    required this.amm,
    required this.culture,
    required this.cible,
  });

  final String amm;
  final String culture;
  final String cible;

  @override
  Widget build(BuildContext context) {
    if (amm.isEmpty || culture.isEmpty || cible.trim().length < 3) {
      return const SizedBox.shrink();
    }

    final data = PhytiaScope.of(context).dataset;
    final usages = data
        .usagesForProduct(amm, includeWithdrawn: false)
        .where((u) => u.culture == culture)
        .toList();

    final String? message;
    if (usages.isEmpty) {
      message =
          'Aucun usage autorisé de ce produit sur $culture. Vérifiez la '
          'culture ou le produit choisi.';
    } else if (!usages.any((u) => cibleCorrespond(cible, u.targetLabel))) {
      message =
          'Ce produit n\'est pas homologué pour « $cible » sur $culture. '
          'Vérifiez l\'étiquette avant de traiter.';
    } else {
      message = null;
    }

    if (message == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D9A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFF8A4B00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF6B4A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
