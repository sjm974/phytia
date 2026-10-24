import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ConditionInfo {
  const ConditionInfo(this.category, this.label);
  final String category;
  final String label;
}

class RiskInfo {
  const RiskInfo(this.code, this.label);
  final String code;
  final String label;
}

class DangerInfo {
  const DangerInfo(this.code, this.label);
  final String code;
  final String label;
}

/// Conditions d'emploi, phrases de risque et mentions de danger d'un produit.
/// Chargées à la demande : l'accueil et la recherche restent instantanés.
class ProductDetails {
  const ProductDetails({
    this.conditions = const [],
    this.risks = const [],
    this.dangers = const [],
  });

  final List<ConditionInfo> conditions;
  final List<RiskInfo> risks;
  final List<DangerInfo> dangers;

  bool get isEmpty => conditions.isEmpty && risks.isEmpty && dangers.isEmpty;

  static const ProductDetails empty = ProductDetails();

  /// Conditions regroupées par catégorie (protection de l'opérateur, milieu…).
  Map<String, List<ConditionInfo>> get conditionsByCategory {
    final map = <String, List<ConditionInfo>>{};
    for (final c in conditions) {
      (map[c.category.isEmpty ? 'Conditions d\'emploi' : c.category] ??= [])
          .add(c);
    }
    return map;
  }
}

class DetailsRepository {
  DetailsRepository(this._loadBytes);

  /// Charge le fichier de détails : cache téléchargé ou asset embarqué.
  final Future<Uint8List> Function() _loadBytes;
  Map<String, dynamic>? _data;
  Future<void>? _future;

  Future<void> ensureLoaded() => _future ??= _load();

  /// Force le rechargement au prochain accès (après une mise à jour).
  void reset() {
    _data = null;
    _future = null;
  }

  Future<void> _load() async {
    final bytes = await _loadBytes();
    _data = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
  }

  ProductDetails forProduct(String amm) {
    final data = _data;
    if (data == null) return ProductDetails.empty;

    final conditions = <ConditionInfo>[];
    for (final raw in _list(data['conditions'], amm)) {
      if (raw.length < 2) continue;
      final label = raw[1].trim();
      if (label.isEmpty) continue;
      conditions.add(ConditionInfo(raw[0].trim(), label));
    }

    final risks = <RiskInfo>[];
    for (final raw in _list(data['risques'], amm)) {
      if (raw.length < 2) continue;
      risks.add(RiskInfo(raw[0].trim(), raw[1].trim()));
    }

    final dangers = <DangerInfo>[];
    for (final raw in _list(data['danger'], amm)) {
      if (raw.length < 2) continue;
      dangers.add(DangerInfo(raw[0].trim(), raw[1].trim()));
    }

    return ProductDetails(
      conditions: conditions,
      risks: risks,
      dangers: dangers,
    );
  }

  static List<List<String>> _list(Map<String, dynamic> data, String amm) {
    final entry = data[amm];
    if (entry is! List) return const [];
    return entry
        .whereType<List>()
        .map((e) => e.map((v) => v.toString()).toList())
        .toList();
  }
}
