import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';

/// Une cible (maladie, ravageur, adventice) disponible pour une culture.
class TargetEntry {
  const TargetEntry({
    required this.culture,
    required this.target,
    required this.type,
    required this.typeLabel,
    required this.count,
  });

  final String culture;
  final String target;
  final String type;
  final String typeLabel;
  final int count;

  String get label => target.isEmpty ? typeLabel : target;
}

/// Le catalogue E-Phy embarqué, indexé en mémoire pour une recherche instantanée.
class PhytiaDataset {
  PhytiaDataset._({
    required this.products,
    required this.usages,
    required this.source,
    required this.updatedAt,
    required this.version,
  });

  final Map<String, Product> products;
  final List<Usage> usages;
  final String source;
  final String updatedAt;
  final int version;

  late final Map<String, List<Usage>> _byCulture = _buildCultureIndex();
  late final Map<String, List<Usage>> _byProduct = _buildProductIndexByAmm();
  late final Map<String, List<Product>> _bySubstance = _buildSubstanceIndex();
  late final Map<String, List<TargetEntry>> _targets = _buildTargetIndex();
  late final List<String> _cultures = (_byCulture.keys.toList()..sort());
  late final List<_NamedProduct> _productNames = _buildProductIndex();

  Map<String, List<Usage>> _buildCultureIndex() {
    final map = <String, List<Usage>>{};
    for (final u in usages) {
      (map[u.culture] ??= <Usage>[]).add(u);
    }
    return map;
  }

  Map<String, List<Usage>> _buildProductIndexByAmm() {
    final map = <String, List<Usage>>{};
    for (final u in usages) {
      (map[u.amm] ??= <Usage>[]).add(u);
    }
    return map;
  }

  /// Classes d'équivalence : même composition déclarée (substance + dose).
  Map<String, List<Product>> _buildSubstanceIndex() {
    final map = <String, List<Product>>{};
    for (final p in products.values) {
      final key = normalize(p.substances);
      if (key.isEmpty) continue;
      (map[key] ??= <Product>[]).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  Map<String, List<TargetEntry>> _buildTargetIndex() {
    final out = <String, List<TargetEntry>>{};
    _byCulture.forEach((culture, list) {
      final counts = <String, int>{};
      final types = <String, String>{};
      for (final u in list) {
        final key = '${u.typeTraitement}|${u.target}';
        counts.update(key, (v) => v + 1, ifAbsent: () => 1);
        types[key] = u.typeLabel;
      }
      final entries = <TargetEntry>[];
      counts.forEach((key, count) {
        final parts = key.split('|');
        entries.add(
          TargetEntry(
            culture: culture,
            type: parts[0],
            target: parts.length > 1 ? parts[1] : '',
            typeLabel: types[key] ?? parts[0],
            count: count,
          ),
        );
      });
      entries.sort((a, b) {
        final t = a.typeLabel.compareTo(b.typeLabel);
        return t != 0 ? t : a.label.compareTo(b.label);
      });
      out[culture] = entries;
    });
    return out;
  }

  List<_NamedProduct> _buildProductIndex() {
    final list = products.values
        .map((p) => _NamedProduct(normalize(p.name), p))
        .toList();
    list.sort((a, b) => a.normalized.compareTo(b.normalized));
    return list;
  }

  // ---------------------------------------------------------------- chargement

  /// Construit le catalogue à partir du fichier gzippé embarqué dans l'app.
  static PhytiaDataset fromBytes(Uint8List bytes) {
    final decoded =
        jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;

    final productsJson = decoded['produits'] as Map<String, dynamic>;
    final products = <String, Product>{};
    productsJson.forEach((amm, value) {
      products[amm] = Product.fromJson(amm, (value as List).cast<dynamic>());
    });

    final usagesJson = (decoded['usages'] as List).cast<List<dynamic>>();
    final usages = usagesJson.map(Usage.fromJson).toList();

    return PhytiaDataset._(
      products: products,
      usages: usages,
      source: decoded['source'] as String? ?? 'Anses — E-Phy',
      updatedAt: decoded['date'] as String? ?? '',
      version: (decoded['v'] as num?)?.toInt() ?? 1,
    );
  }

  // ------------------------------------------------------------------- accès

  List<String> get cultures => _cultures;

  int get productCount => products.length;
  int get usageCount => usages.length;
  int get authorizedUsageCount => usages.where((u) => u.isAuthorized).length;

  int get targetCount =>
      _targets.values.fold(0, (sum, list) => sum + list.length);

  /// Date de mise à jour du jeu de données au format jj/mm/aaaa.
  String get updatedAtLabel {
    final parts = updatedAt.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return updatedAt;
  }

  List<Usage> usagesForCulture(String culture) =>
      _byCulture[culture] ?? const [];

  List<TargetEntry> targetsForCulture(String culture) =>
      _targets[culture] ?? const [];

  bool hasCulture(String culture) => _byCulture.containsKey(culture);

  Product? product(String amm) => products[amm];

  /// Résultats pour une culture et une cible, regroupés par produit.
  List<ProductResult> resultsFor(
    String culture,
    String target, {
    String? type,
    bool includeWithdrawn = false,
  }) {
    final byProduct = <String, List<Usage>>{};
    for (final u in usagesForCulture(culture)) {
      if (u.target != target) continue;
      if (type != null && type.isNotEmpty && u.typeTraitement != type) continue;
      if (!includeWithdrawn && !u.isAuthorized) continue;
      (byProduct[u.amm] ??= <Usage>[]).add(u);
    }
    final results = <ProductResult>[];
    byProduct.forEach((amm, list) {
      final p = products[amm];
      if (p == null) return;
      list.sort((a, b) => a.dose.compareTo(b.dose));
      results.add(ProductResult(product: p, usages: list));
    });
    results.sort((a, b) => a.product.name.compareTo(b.product.name));
    return results;
  }

  /// Toutes les prescriptions d'un produit.
  List<Usage> usagesForProduct(String amm, {bool includeWithdrawn = true}) {
    final list = _byProduct[amm] ?? const <Usage>[];
    if (includeWithdrawn) return list;
    return list.where((u) => u.isAuthorized).toList();
  }

  /// Produits à composition déclarée identique (même substance active, même dose).
  /// Ce sont les seuls substituts réellement interchangeables en pratique.
  List<Product> equivalentProducts(String amm) {
    final reference = products[amm];
    if (reference == null) return const [];
    final key = normalize(reference.substances);
    if (key.isEmpty) return const [];
    return (_bySubstance[key] ?? const <Product>[])
        .where((p) => p.amm != amm)
        .toList();
  }

  // ---------------------------------------------------------------- recherche

  List<String> searchCultures(String query, {int limit = 25}) {
    final q = normalize(query.trim());
    if (q.isEmpty) return cultures.take(limit).toList();
    final starts = <String>[];
    final contains = <String>[];
    for (final c in cultures) {
      final n = normalize(c);
      if (n.startsWith(q)) {
        starts.add(c);
      } else if (n.contains(q)) {
        contains.add(c);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  List<Product> searchProducts(String query, {int limit = 40}) {
    final q = normalize(query.trim());
    if (q.length < 2) return const [];
    final out = <Product>[];
    for (final entry in _productNames) {
      if (entry.normalized.contains(q)) {
        out.add(entry.product);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  List<TargetEntry> searchTargets(String query, {int limit = 30}) {
    final q = normalize(query.trim());
    if (q.length < 2) return const [];
    final seen = <String>{};
    final out = <TargetEntry>[];
    for (final entries in _targets.values) {
      for (final e in entries) {
        if (e.target.isEmpty) continue;
        if (!normalize(e.label).contains(q)) continue;
        if (!seen.add(e.label)) continue;
        out.add(e);
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  /// Premier produit de la liste (utilisé pour les raccourcis).
  String? cultureWithMostUsages() {
    if (_cultures.isEmpty) return null;
    return _cultures.reduce(
      (a, b) =>
          usagesForCulture(a).length >= usagesForCulture(b).length ? a : b,
    );
  }
}

class _NamedProduct {
  const _NamedProduct(this.normalized, this.product);
  final String normalized;
  final Product product;
}
