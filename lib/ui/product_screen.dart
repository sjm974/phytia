import 'package:flutter/material.dart';

import '../data/details.dart';
import '../data/models.dart';
import '../data/scope.dart';
import 'bbch_sheet.dart';
import 'compare_screen.dart';
import 'equivalents_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.amm, this.highlight});

  final String amm;

  /// Prescriptions qui ont amené l'utilisateur ici (résultats de recherche).
  final List<Usage>? highlight;

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final product = scope.dataset.product(amm);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche produit')),
        body: const EmptyState(
          icon: Icons.help_outline,
          title: 'Produit introuvable',
          message: 'Ce produit ne figure pas dans le catalogue embarqué.',
        ),
      );
    }

    final store = scope.store;
    final details = scope.details;

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche produit')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final inStock = store.inStock(product.amm);
          final favorite = store.isFavorite(product.amm);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _ProductHeader(product: product),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        store.toggleStock(product.amm);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              inStock
                                  ? 'Retiré de votre stock'
                                  : 'Ajouté à votre stock',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        inStock ? Icons.inventory_2 : Icons.add_box_outlined,
                      ),
                      label: Text(
                        inStock ? 'Dans mon stock' : 'Ajouter à mon stock',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () => store.toggleFavorite(product.amm),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? const Color(0xFFD9605A) : null,
                    ),
                    tooltip: favorite
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EquivalentsScreen(
                            amm: product.amm,
                            usage: highlight != null && highlight!.isNotEmpty
                                ? highlight!.first
                                : null,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Équivalents'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ComparePickerScreen(
                            amm: product.amm,
                            name: product.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.compare_arrows, size: 18),
                      label: const Text('Comparer'),
                    ),
                  ),
                ],
              ),
              if (highlight != null && highlight!.isNotEmpty) ...[
                const SectionHeader(
                  'Votre usage',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
                ),
                for (final usage in highlight!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UsageCard(
                      usage: usage,
                      showCulture: true,
                      product: product,
                    ),
                  ),
              ] else ...[
                const SectionHeader(
                  'Usages autorisés',
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
                ),
                _UsageSummary(amm: product.amm),
              ],
              const SectionHeader(
                'Composition',
                padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
              ),
              _Composition(product: product),
              _DetailsSection(details: details, amm: product.amm),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              SourceNote(date: scope.dataset.updatedAtLabel),
              const SizedBox(height: 6),
              Text(
                'AMM n° ${product.amm} · fiche E-Phy',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: product.isWithdrawn
              ? const Color(0xFFE7B4AF)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.shortFunctions} · ${product.formulation}',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          if (product.holder.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              product.holder,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill('AMM ${product.amm}', icon: Icons.tag),
              if (product.isAmateur)
                const Pill('Amateur', icon: Icons.home_outlined)
              else
                const Pill('Professionnel', icon: Icons.agriculture_outlined),
              if (product.isWithdrawn)
                const Pill(
                  'Produit retiré',
                  icon: Icons.block,
                  color: Color(0xFFB3261E),
                  background: Color(0xFFFDECEA),
                )
              else
                const Pill(
                  'Autorisé',
                  icon: Icons.verified_outlined,
                  color: Color(0xFF1E6B45),
                  background: Color(0xFFE4F1E7),
                ),
            ],
          ),
          if (product.restrictions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              product.restrictions,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF8A4B00),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.usage,
    required this.showCulture,
    required this.product,
  });

  final Usage usage;
  final bool showCulture;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (usage.doseLabel != null)
        _row(Icons.science_outlined, 'Dose', usage.doseLabel!),
      if (usage.maxApplicationsLabel != null)
        _row(Icons.repeat, 'Applications', usage.maxApplicationsLabel!),
      if (usage.intervalLabel != null)
        _row(Icons.timelapse, 'Intervalle', usage.intervalLabel!),
      if (usage.darLabel != null)
        _row(Icons.schedule, 'Délai avant récolte', usage.darLabel!),
      if (usage.zntLabel != null)
        _row(Icons.water_drop_outlined, 'Zones non traitées', usage.zntLabel!),
      if (usage.stageLabel != null)
        _row(
          Icons.grass,
          'Stade',
          usage.stageLabel!,
          onTap: () => showBbchSheet(context, usage: usage),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  showCulture
                      ? '${usage.culture} — ${usage.targetLabel}'
                      : usage.targetLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: phytiaDark,
                  ),
                ),
              ),
              if (usage.isProvisional)
                const Pill(
                  'Provisoire',
                  icon: Icons.hourglass_empty,
                  color: Color(0xFF8A4B00),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(usage.typeLabel, icon: Icons.category_outlined),
              if (usage.decisionDate.isNotEmpty)
                Pill(
                  'Décision ${usage.decisionDate}',
                  icon: Icons.event_outlined,
                ),
            ],
          ),
          if (rows.isNotEmpty) ...[const SizedBox(height: 10), ...rows],
          if (usage.mentions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              usage.mentions,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: phytiaGreen),
        const SizedBox(width: 8),
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A70)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: phytiaDark,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF9AA79F),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 6), child: content);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: content,
        ),
      ),
    );
  }
}

class _UsageSummary extends StatelessWidget {
  const _UsageSummary({required this.amm});

  final String amm;

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final scheme = Theme.of(context).colorScheme;
    final usages = data.usagesForProduct(amm, includeWithdrawn: false);

    if (usages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Aucun usage autorisé : ce produit est retiré ou son usage n\'est plus valide. Il ne doit plus être employé.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: Color(0xFFB3261E),
          ),
        ),
      );
    }

    final byCulture = <String, List<Usage>>{};
    for (final u in usages) {
      (byCulture[u.culture] ??= <Usage>[]).add(u);
    }
    final cultures = byCulture.keys.toList()
      ..sort((a, b) => byCulture[b]!.length.compareTo(byCulture[a]!.length));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${usages.length} usages sur ${cultures.length} cultures',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          for (final culture in cultures.take(12))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      culture,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${byCulture[culture]!.length}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (cultures.length > 12)
            Text(
              'et ${cultures.length - 12} autres cultures',
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _Composition extends StatelessWidget {
  const _Composition({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final substances = product.substanceList;
    if (substances.isEmpty) {
      return Text(
        'Composition non renseignée.',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in substances)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 14,
                    color: phytiaGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s, style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.details, required this.amm});

  final DetailsRepository details;
  final String amm;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: details.ensureLoaded(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final info = details.forProduct(amm);
        if (info.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.conditions.isNotEmpty) ...[
              const SectionHeader(
                'Conditions d\'emploi',
                padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
              ),
              for (final category in info.conditionsByCategory.entries)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: phytiaGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final c in category.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5, right: 7),
                                child: Icon(
                                  Icons.circle,
                                  size: 5,
                                  color: Color(0xFF9AA79F),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  c.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            if (info.risks.isNotEmpty) ...[
              const SectionHeader(
                'Phrases de risque',
                padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
              ),
              for (final r in info.risks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(
                        r.code,
                        background: const Color(0xFFFFF1D6),
                        color: const Color(0xFF8A4B00),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.label,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (info.dangers.isNotEmpty) ...[
              const SectionHeader(
                'Mentions de danger',
                padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (final d in info.dangers)
                    Pill(d.label, icon: Icons.warning_amber_rounded),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
