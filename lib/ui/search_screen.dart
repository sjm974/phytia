import 'package:flutter/material.dart';

import '../data/dataset.dart';
import '../data/models.dart';
import '../data/scope.dart';
import 'product_screen.dart';
import 'results_screen.dart';
import 'target_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
    final q = _query.trim();
    final empty = q.isEmpty;

    final cultures = data.searchCultures(q, limit: 8);
    final targets = data.searchTargets(q, limit: 10);
    final products = data.searchProducts(q, limit: 25);

    final popular = [...data.cultures]
      ..sort(
        (a, b) => data
            .usagesForCulture(b)
            .length
            .compareTo(data.usagesForCulture(a).length),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: PhytiaSearchField(
              controller: _controller,
              autofocus: true,
              hint: 'Culture, maladie, produit…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              children: [
                if (empty) ...[
                  SectionHeader(
                    'Cultures les plus consultées',
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in popular.take(8))
                        ActionChip(
                          label: Text(c),
                          onPressed: () => _openCulture(c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Astuce : cherchez « mildiou », « pucerons » ou le nom d\'un produit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  if (cultures.isNotEmpty) ...[
                    SectionHeader(
                      'Cultures',
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                    ),
                    for (final c in cultures)
                      _SearchTile(
                        icon: Icons.agriculture_outlined,
                        title: c,
                        subtitle: '${data.targetsForCulture(c).length} cibles',
                        onTap: () => _openCulture(c),
                      ),
                  ],
                  if (targets.isNotEmpty) ...[
                    SectionHeader(
                      'Maladies et ravageurs',
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
                    ),
                    for (final t in targets)
                      _SearchTile(
                        icon: Icons.coronavirus_outlined,
                        title: t.label,
                        subtitle: '${t.culture} · ${t.typeLabel}',
                        onTap: () => _openTarget(t),
                      ),
                  ],
                  if (products.isNotEmpty) ...[
                    SectionHeader(
                      'Produits',
                      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
                    ),
                    for (final p in products)
                      _SearchTile(
                        icon: Icons.science_outlined,
                        title: p.name,
                        subtitle: '${p.shortFunctions} · AMM ${p.amm}',
                        onTap: () => _openProduct(p),
                      ),
                  ],
                  if (cultures.isEmpty && targets.isEmpty && products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: 'Aucun résultat',
                        message: 'Essayez un nom de culture, une maladie ou un nom commercial.',
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCulture(String culture) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TargetScreen(culture: culture)),
    );
  }

  void _openTarget(TargetEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          culture: entry.culture,
          target: entry.target,
          type: entry.type,
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductScreen(amm: product.amm)),
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: phytiaGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: phytiaDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
