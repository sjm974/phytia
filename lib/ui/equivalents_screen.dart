import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/scope.dart';
import 'product_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Produits à composition déclarée identique : les substituts possibles.
/// Si un usage est fourni, on distingue ceux qui sont autorisés pour ce même
/// usage de ceux qui ne le sont pas — car une même substance ne garantit pas
/// les mêmes usages.
class EquivalentsScreen extends StatelessWidget {
  const EquivalentsScreen({super.key, required this.amm, this.usage});

  final String amm;
  final Usage? usage;

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final reference = data.product(amm);
    if (reference == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produits équivalents')),
        body: const EmptyState(
          icon: Icons.help_outline,
          title: 'Produit introuvable',
          message: 'Ce produit ne figure pas dans le catalogue embarqué.',
        ),
      );
    }

    final refUsages = data.usagesForProduct(amm, includeWithdrawn: false);
    final refKeys = refUsages.map(_key).toSet();
    final focusUsage = usage;

    final rows = <_Equivalent>[];
    for (final candidate in data.equivalentProducts(amm)) {
      final usagesOfCandidate = data.usagesForProduct(
        candidate.amm,
        includeWithdrawn: false,
      );
      final keys = usagesOfCandidate.map(_key).toSet();
      final common = keys.where(refKeys.contains).length;
      final authorizedForUsage = focusUsage == null
          ? false
          : usagesOfCandidate.any((u) => _key(u) == _key(focusUsage));
      rows.add(
        _Equivalent(
          product: candidate,
          common: common,
          authorizedForUsage: authorizedForUsage,
        ),
      );
    }

    rows.sort((a, b) {
      if (focusUsage != null && a.authorizedForUsage != b.authorizedForUsage) {
        return a.authorizedForUsage ? -1 : 1;
      }
      if (a.common != b.common) return b.common.compareTo(a.common);
      return a.product.name.compareTo(b.product.name);
    });

    final authorized = focusUsage == null
        ? rows
        : rows.where((r) => r.authorizedForUsage).toList();
    final others = focusUsage == null
        ? const <_Equivalent>[]
        : rows.where((r) => !r.authorizedForUsage).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Produits équivalents')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _ReferenceCard(product: reference, usages: refUsages.length),
          if (focusUsage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    size: 18,
                    color: phytiaGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pour ${focusUsage.culture} — ${focusUsage.targetLabel}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: phytiaDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (rows.isEmpty) ...[
            const SizedBox(height: 30),
            const EmptyState(
              icon: Icons.science_outlined,
              title: 'Aucun équivalent',
              message:
                  'Aucun autre produit du catalogue ne déclare exactement '
                  'la même composition. Il n\'existe pas de substitut direct.',
            ),
          ] else ...[
            SectionHeader(
              focusUsage == null
                  ? 'Même composition (${rows.length})'
                  : 'Autorisés pour cet usage (${authorized.length})',
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
            ),
            if (focusUsage != null && authorized.isEmpty)
              Text(
                'Aucun produit de même composition n\'est autorisé pour cet usage. '
                'Vérifiez les usages de chaque équivalent avant de substituer.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final row in authorized)
                _EquivTile(row: row, reference: reference),
            if (others.isNotEmpty) ...[
              SectionHeader(
                'Même composition, autre usage (${others.length})',
                padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
              ),
              Text(
                'Ces produits ne sont pas autorisés pour cet usage précis : '
                'ne les substituez pas sans vérifier l\'étiquette.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              for (final row in others)
                _EquivTile(row: row, reference: reference),
            ],
          ],
          const SizedBox(height: 22),
          SourceNote(date: data.updatedAtLabel),
        ],
      ),
    );
  }

  static String _key(Usage u) => '${u.culture}|${u.typeTraitement}|${u.target}';
}

class _Equivalent {
  const _Equivalent({
    required this.product,
    required this.common,
    required this.authorizedForUsage,
  });

  final Product product;
  final int common;
  final bool authorizedForUsage;
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.product, required this.usages});

  final Product product;
  final int usages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: phytiaDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'AMM ${product.amm} · $usages usages autorisés',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in product.substanceList.take(3))
                Pill(s, icon: Icons.science_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _EquivTile extends StatelessWidget {
  const _EquivTile({required this.row, required this.reference});

  final _Equivalent row;
  final Product reference;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final differentGamme = row.product.isAmateur != reference.isAmateur;
    final differentFunction =
        row.product.shortFunctions != reference.shortFunctions;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductScreen(amm: row.product.amm),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: phytiaDark,
                        ),
                      ),
                    ),
                    if (row.authorizedForUsage)
                      const Pill(
                        'Autorisé',
                        icon: Icons.check_circle_outline,
                        color: Color(0xFF1E6B45),
                        background: Color(0xFFE4F1E7),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'AMM ${row.product.amm} · ${row.product.formulation}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(
                      '${row.common} usages en commun',
                      icon: Icons.compare_arrows,
                    ),
                    if (differentGamme)
                      Pill(
                        row.product.isAmateur
                            ? 'Gamme amateur'
                            : 'Gamme professionnelle',
                        icon: Icons.info_outline,
                        color: const Color(0xFF8A4B00),
                        background: const Color(0xFFFFF1D6),
                      ),
                    if (differentFunction)
                      Pill(
                        row.product.shortFunctions,
                        icon: Icons.category_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
