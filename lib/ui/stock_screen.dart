import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/scope.dart';
import 'culture_screen.dart';
import 'product_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes produits'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mon stock'),
              Tab(text: 'Favoris'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductList(
              ids: () => scope.store.stock,
              emptyIcon: Icons.inventory_2_outlined,
              emptyTitle: 'Votre stock est vide',
              emptyMessage: 'Ajoutez les produits que vous avez dans votre cabane. Ils passeront en tête des résultats et vous saurez immédiatement ce que vous pouvez traiter.',
              actionLabel: 'Ajouter un produit',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddProductScreen(),
                ),
              ),
              stockTab: true,
            ),
            _ProductList(
              ids: () => scope.store.favorites,
              emptyIcon: Icons.star_outline,
              emptyTitle: 'Aucun favori',
              emptyMessage: 'Touchez le cœur sur une fiche produit pour la retrouver ici, hors connexion.',
              stockTab: false,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddProductScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.ids,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.actionLabel,
    this.onAction,
    required this.stockTab,
  });

  final List<String> Function() ids;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool stockTab;

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    return AnimatedBuilder(
      animation: scope.store,
      builder: (context, _) {
        final products = ids()
            .map((id) => scope.dataset.product(id))
            .whereType<Product>()
            .toList();

        if (products.isEmpty) {
          return EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
            action: actionLabel == null
                ? null
                : FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add),
                    label: Text(actionLabel!),
                  ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (stockTab)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CultureScreen(stockOnly: true),
                      ),
                    ),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Avec mon stock, que puis-je traiter ?'),
                  ),
                ),
              ),
            for (final product in products)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StockTile(
                  product: product,
                  inStock: scope.store.inStock(product.amm),
                  favorite: scope.store.isFavorite(product.amm),
                  stockTab: stockTab,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({
    required this.product,
    required this.inStock,
    required this.favorite,
    required this.stockTab,
  });

  final Product product;
  final bool inStock;
  final bool favorite;
  final bool stockTab;

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductScreen(amm: product.amm),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
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
                    const SizedBox(height: 3),
                    Text(
                      '${product.shortFunctions} · ${product.formulation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (product.isWithdrawn) ...[
                      const SizedBox(height: 6),
                      const Pill(
                        'Retiré',
                        icon: Icons.block,
                        color: Color(0xFFB3261E),
                        background: Color(0xFFFDECEA),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: stockTab ? 'Retirer du stock' : 'Retirer des favoris',
                onPressed: () {
                  if (stockTab) {
                    scope.store.toggleStock(product.amm);
                  } else {
                    scope.store.toggleFavorite(product.amm);
                  }
                },
                icon: Icon(
                  stockTab
                      ? Icons.remove_circle_outline
                      : Icons.heart_broken_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final products = scope.dataset.searchProducts(_query, limit: 60);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: AnimatedBuilder(
        animation: scope.store,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: PhytiaSearchField(
                  controller: _controller,
                  autofocus: true,
                  hint: 'Nom du produit ou début du nom',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: _query.trim().length < 2
                    ? const EmptyState(
                        icon: Icons.search,
                        title: 'Tapez au moins 2 lettres',
                        message: 'Le nom exact figure sur l\'étiquette du produit. Vous pouvez aussi le retrouver par sa fiche dans les résultats de recherche.',
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
                          final inStock = scope.store.inStock(p.amm);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  scope.store.toggleStock(p.amm);
                                  if (!inStock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${p.name} ajouté au stock',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: inStock
                                          ? phytiaGreen.withValues(alpha: 0.5)
                                          : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
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
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.shortFunctions} · AMM ${p.amm}',
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
                                      Icon(
                                        inStock
                                            ? Icons.check_circle
                                            : Icons.add_circle_outline,
                                        color: inStock
                                            ? phytiaGreen
                                            : Colors.black26,
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
          );
        },
      ),
    );
  }
}
