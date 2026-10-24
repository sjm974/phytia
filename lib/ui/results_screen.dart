import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/scope.dart';
import 'product_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.culture,
    required this.target,
    this.type,
    this.stockOnly = false,
  });

  final String culture;
  final String target;
  final String? type;
  final bool stockOnly;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _stockOnly = false;
  bool _withoutZnt = false;
  bool _includeWithdrawn = false;

  @override
  void initState() {
    super.initState();
    _stockOnly = widget.stockOnly;
  }

  bool _hasZnt(ProductResult r) => r.usages.any(
    (u) =>
        u.zntWater.isNotEmpty ||
        u.zntArthropods.isNotEmpty ||
        u.zntPlants.isNotEmpty,
  );

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final data = scope.dataset;
    final store = scope.store;

    var results = data.resultsFor(
      widget.culture,
      widget.target,
      type: widget.type,
      includeWithdrawn: _includeWithdrawn,
    );

    if (_stockOnly) {
      results = results.where((r) => store.inStock(r.product.amm)).toList();
    }
    if (_withoutZnt) {
      results = results.where((r) => !_hasZnt(r)).toList();
    }

    results.sort((a, b) {
      final sa = store.inStock(a.product.amm) ? 0 : 1;
      final sb = store.inStock(b.product.amm) ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return a.product.name.compareTo(b.product.name);
    });

    final title = widget.target.isEmpty
        ? _typeLabel(widget.type)
        : widget.target;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.culture,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Column(
            children: [
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (store.stockCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('Mon stock (${store.stockCount})'),
                          selected: _stockOnly,
                          onSelected: (v) => setState(() => _stockOnly = v),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Sans ZNT'),
                        selected: _withoutZnt,
                        onSelected: (v) => setState(() => _withoutZnt = v),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Retraits'),
                      selected: _includeWithdrawn,
                      onSelected: (v) => setState(() => _includeWithdrawn = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                child: Row(
                  children: [
                    Text(
                      '${results.length} produit${results.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (_stockOnly)
                      const Pill(
                        'Priorité stock',
                        icon: Icons.inventory_2_outlined,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? EmptyState(
                        icon: Icons.science_outlined,
                        title: _stockOnly
                            ? 'Aucun produit de votre stock'
                            : 'Aucun produit homologué',
                        message: _stockOnly
                            ? 'Aucun des produits enregistrés dans votre stock n\'est autorisé pour cet usage. Désactivez le filtre pour voir tous les produits homologués.'
                            : 'Aucune spécialité commerciale n\'est autorisée en France pour cette culture et cette cible. Vérifiez l\'orthographe ou consultez E-Phy.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final r = results[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ResultCard(
                              result: r,
                              inStock: store.inStock(r.product.amm),
                              favorite: store.isFavorite(r.product.amm),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProductScreen(
                                    amm: r.product.amm,
                                    highlight: r.usages,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _typeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Usage';
    return Usage(
      amm: '',
      culture: '',
      typeTraitement: type,
      target: '',
      shortId: '',
      dose: '',
      doseUnit: '',
      darDays: '',
      darBbch: '',
      maxApplications: '',
      intervalDays: '',
      zntWater: '',
      zntArthropods: '',
      zntPlants: '',
      bbchMin: '',
      bbchMax: '',
      state: '',
      gamme: '',
      mentions: '',
      decisionDate: '',
    ).targetLabel;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.inStock,
    required this.favorite,
    required this.onTap,
  });

  final ProductResult result;
  final bool inStock;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = result.product;
    final usage = result.primary;
    final withdrawn = !result.usages.any((u) => u.isAuthorized);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: inStock
                  ? phytiaGreen.withValues(alpha: 0.45)
                  : scheme.outlineVariant,
              width: inStock ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (inStock)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFF2A93B),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: phytiaDark,
                      ),
                    ),
                  ),
                  if (favorite)
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Color(0xFFD9605A),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${product.shortFunctions} · ${product.formulation}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (withdrawn)
                    const Pill(
                      'Retiré',
                      icon: Icons.block,
                      color: Color(0xFFB3261E),
                      background: Color(0xFFFDECEA),
                    )
                  else ...[
                    if (result.doseSummary.isNotEmpty)
                      Pill(result.doseSummary, icon: Icons.science_outlined),
                    if (usage.darLabel != null)
                      Pill(usage.darLabel!, icon: Icons.schedule),
                    if (usage.zntLabel != null)
                      Pill(usage.zntLabel!, icon: Icons.water_drop_outlined),
                    if (result.hasSeveral)
                      Pill(
                        '${result.usages.length} prescriptions',
                        icon: Icons.list_alt,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
