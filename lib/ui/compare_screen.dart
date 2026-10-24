import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/scope.dart';
import 'product_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Comparaison de deux spécialités commerciales : ce que chacune est autorisée
/// à faire. Deux produits à composition identique n'ont pas forcément les mêmes
/// usages : l'autorisation est attachée au produit (AMM), pas à la substance.
class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key, required this.ammA, required this.ammB});

  final String ammA;
  final String ammB;

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final a = data.product(ammA);
    final b = data.product(ammB);

    if (a == null || b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comparer')),
        body: const EmptyState(
          icon: Icons.help_outline,
          title: 'Produit introuvable',
          message: 'Ce produit ne figure pas dans le catalogue embarqué.',
        ),
      );
    }

    final usagesA = data.usagesForProduct(ammA, includeWithdrawn: false);
    final usagesB = data.usagesForProduct(ammB, includeWithdrawn: false);

    String key(Usage u) => '${u.culture}|${u.typeTraitement}|${u.target}';

    final mapA = <String, Usage>{for (final u in usagesA) key(u): u};
    final mapB = <String, Usage>{for (final u in usagesB) key(u): u};

    final common = mapA.keys.where(mapB.containsKey).toList()..sort();
    final onlyA = mapA.keys.where((k) => !mapB.containsKey(k)).toList()..sort();
    final onlyB = mapB.keys.where((k) => !mapA.containsKey(k)).toList()..sort();

    final sameComposition = normalize(a.substances) == normalize(b.substances);

    return Scaffold(
      appBar: AppBar(title: const Text('Comparer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _MiniCard(product: a),
          const SizedBox(height: 10),
          _MiniCard(product: b),
          const SizedBox(height: 14),
          _Verdict(
            common: common.length,
            onlyA: onlyA.length,
            onlyB: onlyB.length,
            sameComposition: sameComposition,
            nameA: a.name,
            nameB: b.name,
          ),
          SectionHeader(
            'Usages communs (${common.length})',
            padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
          ),
          if (common.isEmpty)
            Text(
              'Aucun usage en commun.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final k in common) _UseRow(usage: mapA[k]!),
          SectionHeader(
            'Seulement ${a.name}',
            padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
          ),
          if (onlyA.isEmpty)
            Text(
              'Aucun usage propre.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            const Text(
              'Ces usages ne sont pas autorisés pour l\'autre produit.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFB3261E)),
            ),
            const SizedBox(height: 6),
            for (final k in onlyA) _UseRow(usage: mapA[k]!, warning: true),
          ],
          SectionHeader(
            'Seulement ${b.name}',
            padding: const EdgeInsets.fromLTRB(0, 22, 0, 8),
          ),
          if (onlyB.isEmpty)
            Text(
              'Aucun usage propre.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            const Text(
              'Ces usages ne sont pas autorisés pour l\'autre produit.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFB3261E)),
            ),
            const SizedBox(height: 6),
            for (final k in onlyB) _UseRow(usage: mapB[k]!, warning: true),
          ],
          const SizedBox(height: 24),
          SourceNote(date: data.updatedAtLabel),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.product});

  final Product product;

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
            'AMM ${product.amm} · ${product.holder}',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            '${product.formulation} · ${product.gamme}',
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

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.common,
    required this.onlyA,
    required this.onlyB,
    required this.sameComposition,
    required this.nameA,
    required this.nameB,
  });

  final int common;
  final int onlyA;
  final int onlyB;
  final bool sameComposition;
  final String nameA;
  final String nameB;

  @override
  Widget build(BuildContext context) {
    final identical = onlyA == 0 && onlyB == 0;
    final color = identical ? const Color(0xFFE4F1E7) : const Color(0xFFFFF7E6);
    final border = identical
        ? const Color(0xFFB7DEC2)
        : const Color(0xFFF0D9A8);
    final text = identical
        ? 'Usages strictement identiques : les deux produits sont interchangeables.'
        : '$common usages en commun, mais ${onlyA + onlyB} usages différents : '
              'les produits ne sont pas interchangeables.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                identical
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 18,
                color: identical ? phytiaGreen : const Color(0xFF8A4B00),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: identical ? phytiaDark : const Color(0xFF6B4A00),
                  ),
                ),
              ),
            ],
          ),
          if (sameComposition) ...[
            const SizedBox(height: 8),
            const Text(
              'Même composition déclarée, mais deux AMM distinctes : ce sont les '
              'usages de l\'étiquette qui font foi, pas la substance active.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF6B4A00),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UseRow extends StatelessWidget {
  const _UseRow({required this.usage, this.warning = false});

  final Usage usage;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Icon(
              warning
                  ? Icons.remove_circle_outline
                  : Icons.check_circle_outline,
              size: 14,
              color: warning ? const Color(0xFFB3261E) : phytiaGreen,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurface,
                  height: 1.35,
                ),
                children: [
                  TextSpan(text: '${usage.culture} — '),
                  TextSpan(
                    text: usage.targetLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choisit le second produit à comparer.
class ComparePickerScreen extends StatefulWidget {
  const ComparePickerScreen({super.key, required this.amm, required this.name});

  final String amm;
  final String name;

  @override
  State<ComparePickerScreen> createState() => _ComparePickerScreenState();
}

class _ComparePickerScreenState extends State<ComparePickerScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final products = data
        .searchProducts(_query, limit: 60)
        .where((p) => p.amm != widget.amm)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Comparer ${widget.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: PhytiaSearchField(
              controller: _controller,
              autofocus: true,
              hint: 'Nom du produit à comparer',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _query.trim().length < 2
                ? const EmptyState(
                    icon: Icons.compare_arrows,
                    title: 'Choisissez un second produit',
                    message:
                        'Deux produits à composition identique peuvent avoir '
                        'des usages autorisés différents. La comparaison le montre.',
                  )
                : products.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun produit trouvé',
                    message: 'Vérifiez l\'orthographe du nom commercial.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final scheme = Theme.of(context).colorScheme;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => CompareScreen(
                                  ammA: widget.amm,
                                  ammB: p.amm,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: phytiaDark,
                                          ),
                                        ),
                                        Text(
                                          'AMM ${p.amm} · ${p.shortFunctions}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Voir la fiche',
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            ProductScreen(amm: p.amm),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
