import 'package:flutter/material.dart';

import '../data/dataset.dart';
import '../data/scope.dart';
import 'about_screen.dart';
import 'culture_screen.dart';
import 'search_screen.dart';
import 'stock_screen.dart';
import 'target_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final data = scope.dataset;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: scope.store,
          builder: (context, _) {
            final store = scope.store;
            final recent = store.recentCultures
                .where((c) => data.hasCulture(c))
                .toList();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(
                  onSearch: () => _push(context, const SearchScreen()),
                  onAbout: () => _push(context, const AboutScreen()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BigCard(
                        title: 'Chercher par culture',
                        subtitle:
                            '${data.cultures.length} cultures · ${data.targetCount} maladies et ravageurs',
                        onTap: () => _push(context, const CultureScreen()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SmallCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Mon stock',
                              value: store.stockCount == 0
                                  ? 'À remplir'
                                  : '${store.stockCount} produit${store.stockCount > 1 ? 's' : ''}',
                              onTap: () => _push(context, const StockScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SmallCard(
                              icon: Icons.star_outline,
                              title: 'Favoris',
                              value: store.favoriteCount == 0
                                  ? 'Aucun'
                                  : '${store.favoriteCount} produit${store.favoriteCount > 1 ? 's' : ''}',
                              onTap: () => _push(
                                context,
                                const StockScreen(initialTab: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (recent.isNotEmpty) ...[
                        const SectionHeader(
                          'Reprendre',
                          padding: EdgeInsets.fromLTRB(0, 26, 0, 10),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final culture in recent)
                              ActionChip(
                                avatar: const Icon(Icons.history, size: 16),
                                label: Text(culture),
                                onPressed: () => _push(
                                  context,
                                  TargetScreen(culture: culture),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      _DataFooter(data: data),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onAbout});

  final VoidCallback onSearch;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF175638), Color(0xFF2C8659)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phytia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Le bon produit, sur la bonne culture',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAbout,
                tooltip: 'À propos',
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 22, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Text(
                      'Culture, maladie, produit…',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.agriculture_outlined,
                  color: phytiaGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: phytiaDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: phytiaGreen),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: phytiaDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataFooter extends StatelessWidget {
  const _DataFooter({required this.data});

  final PhytiaDataset data;

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
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 16, color: phytiaGreen),
              const SizedBox(width: 6),
              Text(
                'Catalogue officiel E-Phy — Anses',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${data.usageCount} usages · ${data.productCount} produits · données du ${data.updatedAtLabel}',
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          SourceNote(date: data.updatedAtLabel, compact: true),
        ],
      ),
    );
  }
}
