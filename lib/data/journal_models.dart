import 'dart:math';

/// Une parcelle de l'exploitation.
class Parcelle {
  const Parcelle({
    required this.id,
    required this.nom,
    this.culture = '',
    this.surfaceHa,
    this.note = '',
  });

  final String id;
  final String nom;
  final String culture;
  final double? surfaceHa;
  final String note;

  Parcelle copyWith({
    String? nom,
    String? culture,
    double? surfaceHa,
    String? note,
  }) => Parcelle(
    id: id,
    nom: nom ?? this.nom,
    culture: culture ?? this.culture,
    surfaceHa: surfaceHa ?? this.surfaceHa,
    note: note ?? this.note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'culture': culture,
    'surface': surfaceHa,
    'note': note,
  };

  factory Parcelle.fromJson(Map<String, dynamic> json) => Parcelle(
    id: json['id'] as String? ?? '',
    nom: json['nom'] as String? ?? '',
    culture: json['culture'] as String? ?? '',
    surfaceHa: (json['surface'] as num?)?.toDouble(),
    note: json['note'] as String? ?? '',
  );
}

/// Un traitement appliqué : les valeurs sont figées au moment de la saisie
/// (le catalogue, lui, change).
class Traitement {
  const Traitement({
    required this.id,
    required this.parcelleId,
    required this.date,
    required this.amm,
    required this.produit,
    required this.culture,
    this.cible = '',
    this.dose = '',
    this.doseUnite = '',
    this.surfaceTraiteeHa,
    this.stadeBbch = '',
    this.darJours,
    this.operateur = '',
    this.note = '',
  });

  final String id;
  final String parcelleId;
  final DateTime date;
  final String amm;
  final String produit;
  final String culture;
  final String cible;
  final String dose;
  final String doseUnite;
  final double? surfaceTraiteeHa;
  final String stadeBbch;
  final int? darJours;
  final String operateur;
  final String note;

  /// Date à partir de laquelle la récolte est possible sur cette parcelle.
  DateTime? get recoltePossibleLe =>
      darJours == null ? null : date.add(Duration(days: darJours!));

  /// Vrai si la récolte est déjà possible à la date indiquée.
  bool recoltePossible(DateTime when) {
    final date = recoltePossibleLe;
    return date == null || !date.isAfter(when);
  }

  String get doseLabel {
    if (dose.isEmpty) return '';
    return doseUnite.isEmpty ? dose : '$dose $doseUnite';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelle': parcelleId,
    'date': date.toIso8601String().substring(0, 10),
    'amm': amm,
    'produit': produit,
    'culture': culture,
    'cible': cible,
    'dose': dose,
    'unite': doseUnite,
    'surface': surfaceTraiteeHa,
    'bbch': stadeBbch,
    'dar': darJours,
    'operateur': operateur,
    'note': note,
  };

  factory Traitement.fromJson(Map<String, dynamic> json) => Traitement(
    id: json['id'] as String? ?? '',
    parcelleId: json['parcelle'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2000),
    amm: json['amm'] as String? ?? '',
    produit: json['produit'] as String? ?? '',
    culture: json['culture'] as String? ?? '',
    cible: json['cible'] as String? ?? '',
    dose: json['dose'] as String? ?? '',
    doseUnite: json['unite'] as String? ?? '',
    surfaceTraiteeHa: (json['surface'] as num?)?.toDouble(),
    stadeBbch: json['bbch'] as String? ?? '',
    darJours: (json['dar'] as num?)?.toInt(),
    operateur: json['operateur'] as String? ?? '',
    note: json['note'] as String? ?? '',
  );
}

/// Le carnet lui-même : parcelles et traitements, sans dépendance à Flutter.
class Journal {
  Journal({List<Parcelle>? parcelles, List<Traitement>? traitements})
    : parcelles = parcelles ?? <Parcelle>[],
      traitements = traitements ?? <Traitement>[];

  final List<Parcelle> parcelles;
  final List<Traitement> traitements;

  Parcelle? parcelle(String id) {
    for (final p in parcelles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Traitements d'une parcelle, du plus récent au plus ancien.
  List<Traitement> traitementsFor(String parcelleId) {
    final list = traitements.where((t) => t.parcelleId == parcelleId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Traitement> get derniersTraitements {
    final list = [...traitements];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Parcelle addParcelle({
    required String nom,
    String culture = '',
    double? surfaceHa,
    String note = '',
  }) {
    final parcelle = Parcelle(
      id: newId(),
      nom: nom.trim(),
      culture: culture,
      surfaceHa: surfaceHa,
      note: note,
    );
    parcelles.add(parcelle);
    return parcelle;
  }

  void updateParcelle(Parcelle parcelle) {
    final index = parcelles.indexWhere((p) => p.id == parcelle.id);
    if (index >= 0) parcelles[index] = parcelle;
  }

  void deleteParcelle(String id) {
    parcelles.removeWhere((p) => p.id == id);
    traitements.removeWhere((t) => t.parcelleId == id);
  }

  void addTraitement(Traitement traitement) => traitements.add(traitement);

  void updateTraitement(Traitement traitement) {
    final index = traitements.indexWhere((t) => t.id == traitement.id);
    if (index >= 0) traitements[index] = traitement;
  }

  void deleteTraitement(String id) {
    traitements.removeWhere((t) => t.id == id);
  }

  Map<String, dynamic> toJson() => {
    'parcelles': parcelles.map((p) => p.toJson()).toList(),
    'traitements': traitements.map((t) => t.toJson()).toList(),
  };

  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
    parcelles: [
      for (final raw in (json['parcelles'] as List? ?? const []))
        Parcelle.fromJson((raw as Map).cast<String, dynamic>()),
    ],
    traitements: [
      for (final raw in (json['traitements'] as List? ?? const []))
        Traitement.fromJson((raw as Map).cast<String, dynamic>()),
    ],
  );

  static String newId() {
    final random = Random();
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = random.nextInt(1 << 20).toRadixString(36);
    return '$stamp-$suffix';
  }
}
