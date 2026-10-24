import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Choisit un produit du catalogue et renvoie sa fiche.
Future<Product?> pickProduct(BuildContext context) => Navigator.of(context)
    .push<Product>(MaterialPageRoute(builder: (_) => const _ProductPicker()));

/// Choisit une culture du catalogue.
Future<String?> pickCulture(BuildContext context) => Navigator.of(context)
    .push<String>(MaterialPageRoute(builder: (_) => const _CulturePicker()));

class _ProductPicker extends StatefulWidget {
  const _ProductPicker();

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
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
    final products = data.searchProducts(_query, limit: 60);

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un produit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: PhytiaSearchField(
              controller: _controller,
              autofocus: true,
              hint: 'Nom commercial du produit',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _query.trim().length < 2
                ? const EmptyState(
                    icon: Icons.science_outlined,
                    title: 'Tapez au moins 2 lettres',
                    message: 'Le nom exact figure sur l\'étiquette.',
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
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

class _CulturePicker extends StatefulWidget {
  const _CulturePicker();

  @override
  State<_CulturePicker> createState() => _CulturePickerState();
}

class _CulturePickerState extends State<_CulturePicker> {
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
    final cultures = data.searchCultures(_query, limit: 200);

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une culture')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: PhytiaSearchField(
              controller: _controller,
              autofocus: true,
              hint: 'Blé, vigne, tomate…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: cultures.length,
              itemBuilder: (context, index) {
                final culture = cultures[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(culture),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.of(context).pop(culture),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
