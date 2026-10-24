import 'dart:convert';

import 'journal_models.dart';

/// Export au format du registre phytosanitaire numérique (échéance 2027).
///
/// Les intitulés reprennent ceux de la notice du ministère du 22 septembre 2026
/// (numeroAMMProduit, doseProduitValeur, surfaceTraitee…). Ils doivent être
/// revérifiés sur l'annexe officielle avant un contrôle : c'est l'annexe qui
/// fait foi en cas d'écart avec la notice.
class RegistreExport {
  static const int version = 1;

  /// Une ligne par produit appliqué ; un mélange produit plusieurs lignes
  /// partageant le même identifiantIntervention.
  static const List<String> champs = [
    'identifiantIntervention',
    'siretApplicateur',
    'nomProduit',
    'numeroAMMProduit',
    'dateUtilisation',
    'heureDebut',
    'heureFin',
    'doseProduitValeur',
    'doseProduitUnite',
    'surfaceTraiteeValeur',
    'surfaceTraiteeUnite',
    'culture',
    'stadeBBCH',
    'modeConduite',
    'delaiRentreeHeures',
    'volumeBouillieLitres',
    'identifiantParcelle',
    'nomParcelle',
    'latitude',
    'longitude',
    'commentaire',
  ];

  /// Mentions obligatoires absentes de l'enregistrement.
  static List<String> champsManquants(Traitement traitement) {
    final manquants = <String>[];
    if (traitement.siret.trim().isEmpty) manquants.add('siretApplicateur');
    if (traitement.amm.trim().isEmpty) manquants.add('numeroAMMProduit');
    if (traitement.produit.trim().isEmpty) manquants.add('nomProduit');
    if (traitement.dose.trim().isEmpty) manquants.add('doseProduitValeur');
    if (traitement.doseUnite.trim().isEmpty) manquants.add('doseProduitUnite');
    if (traitement.surfaceTraiteeM2 == null) {
      manquants.add('surfaceTraiteeValeur');
    }
    if (traitement.culture.trim().isEmpty) manquants.add('culture');
    if (traitement.modeConduite.trim().isEmpty) manquants.add('modeConduite');
    return manquants;
  }

  /// Ligne du registre, sous les intitulés de l'annexe.
  static Map<String, Object?> ligne(Traitement t, {String nomParcelle = ''}) =>
      {
        'identifiantIntervention': t.intervention,
        'siretApplicateur': t.siret,
        'nomProduit': t.produit,
        'numeroAMMProduit': t.amm,
        'dateUtilisation': isoDate(t.date),
        'heureDebut': t.heureDebut,
        'heureFin': t.heureFin,
        'doseProduitValeur': _nombre(t.dose),
        'doseProduitUnite': t.doseUnite,
        'surfaceTraiteeValeur': t.surfaceTraiteeM2,
        'surfaceTraiteeUnite': 'm2',
        'culture': t.culture,
        'stadeBBCH': t.stadeBbch,
        'modeConduite': t.modeConduite,
        'delaiRentreeHeures': t.delaiRentreeHeures,
        'volumeBouillieLitres': t.volumeBouillie,
        'identifiantParcelle': t.parcelleId,
        'nomParcelle': nomParcelle,
        'latitude': t.latitude,
        'longitude': t.longitude,
        'commentaire': t.note,
      };

  /// CSV point-virgule, nombres à point décimal (lisible par machine).
  static String toCsv(
    List<Traitement> traitements, {
    Map<String, String> parcelles = const {},
  }) {
    final buffer = StringBuffer()..writeln(champs.join(';'));
    for (final t in traitements) {
      final ligne = RegistreExport.ligne(
        t,
        nomParcelle: parcelles[t.parcelleId] ?? '',
      );
      buffer.writeln(champs.map((c) => _cellule(ligne[c])).join(';'));
    }
    return buffer.toString();
  }

  /// JSON structuré : un objet par ligne, plus l'en-tête du fichier.
  static String toJson(
    List<Traitement> traitements, {
    Map<String, String> parcelles = const {},
    DateTime? genereLe,
  }) {
    final date = (genereLe ?? DateTime.now()).toUtc().toIso8601String();
    return const JsonEncoder.withIndent('  ').convert({
      'version': version,
      'genereLe': date,
      'source': 'Données E-Phy — Anses',
      'lignes': [
        for (final t in traitements)
          ligne(t, nomParcelle: parcelles[t.parcelleId] ?? ''),
      ],
    });
  }

  static String _cellule(Object? valeur) {
    if (valeur == null) return '';
    final texte = valeur.toString();
    if (texte.contains(';') || texte.contains('"') || texte.contains('\n')) {
      return '"${texte.replaceAll('"', '""')}"';
    }
    return texte;
  }

  static Object _nombre(String valeur) {
    final nombre = double.tryParse(valeur.replaceAll(',', '.').trim());
    if (nombre == null) return valeur.trim();
    if (nombre == nombre.roundToDouble()) return nombre.round();
    return nombre;
  }
}

/// Date ISO courte (AAAA-MM-JJ).
String isoDate(DateTime date) {
  final mois = date.month.toString().padLeft(2, '0');
  final jour = date.day.toString().padLeft(2, '0');
  return '${date.year}-$mois-$jour';
}
