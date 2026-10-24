import 'dart:convert';

/// Un produit du catalogue E-Phy (fiche administrative).
class Product {
  const Product({
    required this.amm,
    required this.name,
    required this.holder,
    required this.substances,
    required this.functions,
    required this.formulation,
    required this.gamme,
    required this.state,
    required this.restrictions,
  });

  final String amm;
  final String name;
  final String holder;
  final String substances;
  final String functions;
  final String formulation;
  final String gamme;
  final String state;
  final String restrictions;

  factory Product.fromJson(String amm, List<dynamic> j) => Product(
    amm: amm,
    name: _s(j, 0),
    holder: _s(j, 1),
    substances: _s(j, 2),
    functions: _s(j, 3),
    formulation: _s(j, 4),
    gamme: _s(j, 5),
    state: _s(j, 6),
    restrictions: _s(j, 7),
  );

  bool get isWithdrawn {
    final s = state.toUpperCase();
    return s.contains('RETIR') || s.contains('WITHDRAWN');
  }

  bool get isAmateur => gamme.toLowerCase().contains('amateur');

  /// Substances actives, dédoublonnées et lisibles.
  List<String> get substanceList {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in substances.split('|')) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      if (seen.add(v.toLowerCase())) out.add(v);
    }
    return out;
  }

  String get shortFunctions => functions
      .split('|')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .join(' · ');
}

/// Une prescription : un produit utilisable sur une culture, contre une cible,
/// avec sa dose, son délai avant récolte et ses zones non traitées.
class Usage {
  const Usage({
    required this.amm,
    required this.culture,
    required this.typeTraitement,
    required this.target,
    required this.shortId,
    required this.dose,
    required this.doseUnit,
    required this.darDays,
    required this.darBbch,
    required this.maxApplications,
    required this.intervalDays,
    required this.zntWater,
    required this.zntArthropods,
    required this.zntPlants,
    required this.bbchMin,
    required this.bbchMax,
    required this.state,
    required this.gamme,
    required this.mentions,
    required this.decisionDate,
  });

  final String amm;
  final String culture;
  final String typeTraitement;
  final String target;
  final String shortId;
  final String dose;
  final String doseUnit;
  final String darDays;
  final String darBbch;
  final String maxApplications;
  final String intervalDays;
  final String zntWater;
  final String zntArthropods;
  final String zntPlants;
  final String bbchMin;
  final String bbchMax;
  final String state;
  final String gamme;
  final String mentions;
  final String decisionDate;

  factory Usage.fromJson(List<dynamic> j) => Usage(
    amm: _s(j, 0),
    culture: _s(j, 1),
    typeTraitement: _s(j, 2),
    target: _s(j, 3),
    shortId: _s(j, 4),
    dose: _s(j, 5),
    doseUnit: _s(j, 6),
    darDays: _s(j, 7),
    darBbch: _s(j, 8),
    maxApplications: _s(j, 9),
    intervalDays: _s(j, 10),
    zntWater: _s(j, 11),
    zntArthropods: _s(j, 12),
    zntPlants: _s(j, 13),
    bbchMin: _s(j, 14),
    bbchMax: _s(j, 15),
    state: _s(j, 16),
    gamme: _s(j, 17),
    mentions: _s(j, 18),
    decisionDate: _s(j, 19),
  );

  bool get isAuthorized => state.toLowerCase().startsWith('autoris');

  bool get isProvisional => state.toLowerCase().contains('provisoire');

  String get typeLabel {
    switch (typeTraitement) {
      case 'Trt Part.Aer.':
      case 'Trt Part. Aer.':
      case 'Trt  Part.Aer.':
        return 'Parties aériennes';
      case 'Trt Sol':
      case 'Trt sol':
        return 'Traitement du sol';
      case 'Trt Sem.':
      case 'Trt Sem. Plants':
      case 'Trt Tuber. Semences':
        return 'Semences';
      case 'Désherbage':
      case 'Désherbage (1)':
        return 'Désherbage';
      case 'Bouil. Herbicide':
        return 'Bouillie herbicide';
      case 'Bouil. Fongicide':
        return 'Bouillie fongicide';
      case 'Bouil. Insecticide':
        return 'Bouillie insecticide';
      case 'Trt Prod. Réc.':
      case 'Trt Prod.Réc.':
        return 'Produits récoltés';
      case 'Trt Irrigation loc.':
        return 'Irrigation localisée';
      default:
        return typeTraitement;
    }
  }

  /// Libellé de la cible, ou le type de traitement quand le produit n'agit pas
  /// sur une cible précise (désherbage notamment).
  String get targetLabel => target.isEmpty ? typeLabel : target;

  String? get doseLabel {
    if (dose.isEmpty) return null;
    final d = _prettyNumber(dose);
    return doseUnit.isEmpty ? d : '$d $doseUnit';
  }

  String? get darLabel =>
      darDays.isEmpty ? null : 'DAR ${_prettyNumber(darDays)} j';

  String? get zntLabel {
    final values = <String>[];
    if (zntWater.isNotEmpty) values.add('eau ${_prettyNumber(zntWater)} m');
    if (zntArthropods.isNotEmpty) {
      values.add('arthropodes ${_prettyNumber(zntArthropods)} m');
    }
    if (zntPlants.isNotEmpty) {
      values.add('plantes ${_prettyNumber(zntPlants)} m');
    }
    if (values.isEmpty) return null;
    return 'ZNT ${values.join(' · ')}';
  }

  String? get maxApplicationsLabel => maxApplications.isEmpty
      ? null
      : '${_prettyNumber(maxApplications)} appli. max';

  String? get intervalLabel => intervalDays.isEmpty
      ? null
      : 'Intervalle ${_prettyNumber(intervalDays)} j';

  String? get stageLabel {
    if (bbchMin.isEmpty && bbchMax.isEmpty) return null;
    if (bbchMin.isNotEmpty && bbchMax.isNotEmpty) {
      return 'BBCH $bbchMin–$bbchMax';
    }
    if (bbchMax.isNotEmpty) return 'BBCH ≤ $bbchMax';
    return 'BBCH ≥ $bbchMin';
  }

  List<dynamic> toJson() => [
    amm,
    culture,
    typeTraitement,
    target,
    shortId,
    dose,
    doseUnit,
    darDays,
    darBbch,
    maxApplications,
    intervalDays,
    zntWater,
    zntArthropods,
    zntPlants,
    bbchMin,
    bbchMax,
    state,
    gamme,
    mentions,
    decisionDate,
  ];
}

/// Un produit et toutes ses prescriptions correspondant à la recherche.
class ProductResult {
  const ProductResult({required this.product, required this.usages});

  final Product product;
  final List<Usage> usages;

  Usage get primary => usages.first;
  bool get hasSeveral => usages.length > 1;

  String get doseSummary {
    final set = <String>{};
    for (final u in usages) {
      final d = u.doseLabel;
      if (d != null) set.add(d);
    }
    return set.join(' ou ');
  }
}

String _s(List<dynamic> j, int i) =>
    i < j.length ? (j[i] as String? ?? '') : '';

String _prettyNumber(String raw) {
  final v = double.tryParse(raw);
  if (v == null) return raw;
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toStringAsFixed(1).replaceAll('.', ',');
}

/// Retire les accents et met en minuscules, pour une recherche tolérante.
String normalize(String input) {
  const map = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ì': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ÿ': 'y',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
  };
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

/// Encode une liste d'identifiants produits (stock, favoris).
String encodeProductIds(Iterable<String> ids) => jsonEncode(ids.toList());
