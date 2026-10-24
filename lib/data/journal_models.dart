import 'dart:math';

/// Modes de conduite reconnus par le registre phytosanitaire.
const String modeBiologique = 'biologique';
const String modeConversion = 'conversion';
const String modeConventionnel = 'conventionnel';

String libelleMode(String mode) {
  switch (mode) {
    case modeBiologique:
      return 'Agriculture biologique';
    case modeConversion:
      return 'Conversion bio';
    case modeConventionnel:
      return 'Conventionnel';
    default:
      return '';
  }
}

/// Une parcelle de l'exploitation.
class Parcelle {
  const Parcelle({
    required this.id,
    required this.nom,
    this.culture = '',
    this.surfaceM2,
    this.note = '',
    this.modeConduite = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String nom;
  final String culture;
  final double? surfaceM2;
  final String note;

  /// biologique, conversion ou conventionnel (vide = non renseigné).
  final String modeConduite;

  /// Position relevée au champ, si l'utilisateur l'a enregistrée.
  final double? latitude;
  final double? longitude;

  bool get aPosition => latitude != null && longitude != null;

  String get positionLabel {
    if (!aPosition) return '';
    final lat = latitude!.toStringAsFixed(6);
    final lon = longitude!.toStringAsFixed(6);
    return '$lat, $lon';
  }

  Parcelle copyWith({
    String? nom,
    String? culture,
    double? surfaceM2,
    String? note,
    String? modeConduite,
    double? latitude,
    double? longitude,
    bool effacerPosition = false,
  }) => Parcelle(
    id: id,
    nom: nom ?? this.nom,
    culture: culture ?? this.culture,
    surfaceM2: surfaceM2 ?? this.surfaceM2,
    note: note ?? this.note,
    modeConduite: modeConduite ?? this.modeConduite,
    latitude: effacerPosition ? null : (latitude ?? this.latitude),
    longitude: effacerPosition ? null : (longitude ?? this.longitude),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'culture': culture,
    'surface': surfaceM2,
    'note': note,
    'mode': modeConduite,
    'lat': latitude,
    'lon': longitude,
  };

  factory Parcelle.fromJson(Map<String, dynamic> json) => Parcelle(
    id: json['id'] as String? ?? '',
    nom: json['nom'] as String? ?? '',
    culture: json['culture'] as String? ?? '',
    surfaceM2: (json['surface'] as num?)?.toDouble(),
    note: json['note'] as String? ?? '',
    modeConduite: json['mode'] as String? ?? '',
    latitude: (json['lat'] as num?)?.toDouble(),
    longitude: (json['lon'] as num?)?.toDouble(),
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
    this.surfaceTraiteeM2,
    this.stadeBbch = '',
    this.darJours,
    this.operateur = '',
    this.note = '',
    this.modeConduite = '',
    this.latitude,
    this.longitude,
    this.heureDebut = '',
    this.heureFin = '',
    this.volumeBouillie,
    this.interventionId = '',
    this.siret = '',
    this.delaiRentreeHeures,
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
  final double? surfaceTraiteeM2;
  final String stadeBbch;
  final int? darJours;
  final String operateur;
  final String note;

  /// Mode de conduite au moment du traitement.
  final String modeConduite;

  /// Position de la parcelle, recopiée pour que le registre reste lisible seul.
  final double? latitude;
  final double? longitude;

  /// Heures de début et de fin, au format HH:mm.
  final String heureDebut;
  final String heureFin;

  /// Volume total de bouillie préparé pour cette parcelle, en litres.
  final double? volumeBouillie;

  /// Regroupe les produits appliqués dans le même passage (mélange).
  /// Vide pour un traitement seul : l'identifiant du traitement fait foi.
  final String interventionId;

  String get intervention => interventionId.isEmpty ? id : interventionId;

  /// SIRET de l'applicateur, recopié pour que la ligne soit autoportante.
  final String siret;

  /// Délai de rentrée sur la parcelle, en heures (distinct du DAR).
  final int? delaiRentreeHeures;

  String get rentreeLabel =>
      delaiRentreeHeures == null ? '' : '§{delaiRentreeHeures} h';

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

  String get heureLabel {
    if (heureDebut.isEmpty && heureFin.isEmpty) return '';
    if (heureFin.isEmpty) return heureDebut;
    if (heureDebut.isEmpty) return heureFin;
    return '$heureDebut – $heureFin';
  }

  String get volumeLabel =>
      volumeBouillie == null ? '' : '${formatLitres(volumeBouillie!)} L';

  /// Équivalent en litres par hectare, pour recouper avec la calibration.
  double? get volumeParHectare {
    final volume = volumeBouillie;
    final surface = surfaceTraiteeM2;
    if (volume == null || surface == null || surface <= 0) return null;
    return volume / surface * 10000;
  }

  String get positionLabel {
    if (latitude == null || longitude == null) return '';
    final lat = latitude!.toStringAsFixed(6);
    final lon = longitude!.toStringAsFixed(6);
    return '$lat, $lon';
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
    'surface': surfaceTraiteeM2,
    'bbch': stadeBbch,
    'dar': darJours,
    'operateur': operateur,
    'note': note,
    'mode': modeConduite,
    'lat': latitude,
    'lon': longitude,
    'debut': heureDebut,
    'fin': heureFin,
    'bouillie': volumeBouillie,
    'intervention': interventionId,
    'siret': siret,
    'rentree': delaiRentreeHeures,
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
    surfaceTraiteeM2: (json['surface'] as num?)?.toDouble(),
    stadeBbch: json['bbch'] as String? ?? '',
    darJours: (json['dar'] as num?)?.toInt(),
    operateur: json['operateur'] as String? ?? '',
    note: json['note'] as String? ?? '',
    modeConduite: json['mode'] as String? ?? '',
    latitude: (json['lat'] as num?)?.toDouble(),
    longitude: (json['lon'] as num?)?.toDouble(),
    heureDebut: json['debut'] as String? ?? '',
    heureFin: json['fin'] as String? ?? '',
    volumeBouillie: (json['bouillie'] as num?)?.toDouble(),
    interventionId: json['intervention'] as String? ?? '',
    siret: json['siret'] as String? ?? '',
    delaiRentreeHeures: (json['rentree'] as num?)?.toInt(),
  );
}

/// Litres formatés à la française (2 L, 2,5 L).
String formatLitres(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2).replaceAll('.', ',');
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

  /// Produits appliqués dans le même passage (mélange).
  List<Traitement> interventionDe(Traitement traitement) => traitements
      .where((t) => t.intervention == traitement.intervention)
      .toList();

  List<Traitement> get derniersTraitements {
    final list = [...traitements];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Parcelle addParcelle({
    required String nom,
    String culture = '',
    double? surfaceM2,
    String note = '',
    String modeConduite = '',
    double? latitude,
    double? longitude,
  }) {
    final parcelle = Parcelle(
      id: newId(),
      nom: nom.trim(),
      culture: culture,
      surfaceM2: surfaceM2,
      note: note,
      modeConduite: modeConduite,
      latitude: latitude,
      longitude: longitude,
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
