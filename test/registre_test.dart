import 'dart:convert';

import 'package:phytia/data/journal_models.dart';
import 'package:phytia/data/registre_export.dart';
import 'package:test/test.dart';

void main() {
  Traitement traitement({
    String siret = '12345678901234',
    String dose = '1,6',
    String mode = modeConventionnel,
    int? rentree = 6,
    double? surface = 1400,
  }) => Traitement(
    id: 't1',
    parcelleId: 'p1',
    date: DateTime(2026, 5, 12),
    amm: '2180631',
    produit: 'OROCIDE',
    culture: 'Vigne',
    cible: 'Mildiou(s)',
    dose: dose,
    doseUnite: 'L/ha',
    surfaceTraiteeM2: surface,
    darJours: 21,
    modeConduite: mode,
    siret: siret,
    delaiRentreeHeures: rentree,
    heureDebut: '08:30',
    heureFin: '10:15',
    volumeBouillie: 28,
    latitude: 45.123456,
    longitude: 5.654321,
    note: 'Parcelle humide; ruissellement',
  );

  test('la ligne reprend les intitulés de l\'annexe', () {
    final ligne = RegistreExport.ligne(traitement(), nomParcelle: 'Les Hauts');

    expect(ligne.keys.toList(), RegistreExport.champs);
    expect(ligne['siretApplicateur'], '12345678901234');
    expect(ligne['numeroAMMProduit'], '2180631');
    expect(ligne['dateUtilisation'], '2026-05-12');
    expect(ligne['doseProduitValeur'], 1.6);
    expect(ligne['doseProduitUnite'], 'L/ha');
    expect(ligne['surfaceTraiteeValeur'], 1400);
    expect(ligne['surfaceTraiteeUnite'], 'm2');
    expect(ligne['modeConduite'], modeConventionnel);
    expect(ligne['delaiRentreeHeures'], 6);
    expect(ligne['volumeBouillieLitres'], 28);
    expect(ligne['nomParcelle'], 'Les Hauts');
    expect(ligne['identifiantIntervention'], 't1');
  });

  test('les mentions obligatoires manquantes sont signalées', () {
    expect(RegistreExport.champsManquants(traitement()), isEmpty);

    final incomplete = traitement(siret: '', dose: '', surface: null, mode: '');
    expect(
      RegistreExport.champsManquants(incomplete),
      containsAll([
        'siretApplicateur',
        'doseProduitValeur',
        'surfaceTraiteeValeur',
        'modeConduite',
      ]),
    );
  });

  test('CSV : en-tête, séparateur et échappement', () {
    final csv = RegistreExport.toCsv(
      [traitement()],
      parcelles: {'p1': 'Les Hauts'},
    );
    final lignes = const LineSplitter().convert(csv);

    expect(lignes.first, RegistreExport.champs.join(';'));
    expect(lignes[1], contains('2026-05-12'));
    expect(lignes[1], contains('1.6'));
    expect(lignes[1], contains('"Parcelle humide; ruissellement"'));
    expect(lignes.length, 2);
  });

  test('JSON : structure et valeurs typées', () {
    final json = jsonDecode(
      RegistreExport.toJson(
        [traitement()],
        parcelles: {'p1': 'Les Hauts'},
        genereLe: DateTime.utc(2026, 10, 24),
      ),
    ) as Map<String, dynamic>;

    expect(json['version'], 1);
    expect(json['source'], contains('E-Phy'));
    final lignes = (json['lignes'] as List).cast<Map<String, dynamic>>();
    expect(lignes.length, 1);
    expect(lignes.first['numeroAMMProduit'], '2180631');
    expect(lignes.first['doseProduitValeur'], 1.6);
    expect(lignes.first['surfaceTraiteeValeur'], 1400);
  });

  test('date ISO courte', () {
    expect(isoDate(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
