import 'dart:convert';

import 'package:phytia/data/journal_export.dart';
import 'package:phytia/data/journal_models.dart';
import 'package:test/test.dart';

void main() {
  Parcelle parcelle({String id = 'p1'}) =>
      Parcelle(id: id, nom: 'Les Hauts', culture: 'Vigne', surfaceHa: 1.4);

  Traitement traitement({
    String id = 't1',
    String parcelleId = 'p1',
    DateTime? date,
    int? dar = 21,
    String cible = 'Mildiou(s)',
    String note = '',
  }) => Traitement(
    id: id,
    parcelleId: parcelleId,
    date: date ?? DateTime(2026, 5, 12),
    amm: '2180631',
    produit: 'OROCIDE',
    culture: 'Vigne',
    cible: cible,
    dose: '1,6',
    doseUnite: 'L/ha',
    surfaceTraiteeHa: 1.4,
    stadeBbch: '12-77',
    darJours: dar,
    operateur: 'SJM',
    note: note,
  );

  group('modèle', () {
    test('aller-retour JSON', () {
      final source = traitement();
      final restored = Traitement.fromJson(
        jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
      );
      expect(restored.produit, 'OROCIDE');
      expect(restored.date, DateTime(2026, 5, 12));
      expect(restored.darJours, 21);
      expect(restored.surfaceTraiteeHa, 1.4);
    });

    test('date de récolte possible = date + DAR', () {
      final t = traitement(date: DateTime(2026, 5, 12), dar: 21);
      expect(t.recoltePossibleLe, DateTime(2026, 6, 2));
      expect(t.recoltePossible(DateTime(2026, 6, 1)), isFalse);
      expect(t.recoltePossible(DateTime(2026, 6, 2)), isTrue);
      expect(traitement(dar: null).recoltePossibleLe, isNull);
    });
  });

  group('carnet', () {
    test('ajout, tri et suppression en cascade', () {
      final journal = Journal();
      final p = journal.addParcelle(nom: 'Les Hauts', culture: 'Vigne');
      journal.addTraitement(
        traitement(id: 'a', parcelleId: p.id, date: DateTime(2026, 4, 1)),
      );
      journal.addTraitement(
        traitement(id: 'b', parcelleId: p.id, date: DateTime(2026, 6, 1)),
      );

      expect(journal.parcelles.length, 1);
      expect(journal.traitements.length, 2);
      expect(journal.traitementsFor(p.id).first.id, 'b');
      expect(journal.derniersTraitements.first.id, 'b');

      journal.deleteParcelle(p.id);
      expect(journal.parcelles, isEmpty);
      expect(journal.traitements, isEmpty);
    });

    test('sérialisation complète du carnet', () {
      final journal = Journal();
      final p = journal.addParcelle(
        nom: 'Les Hauts',
        culture: 'Vigne',
        surfaceHa: 1.4,
      );
      journal.addTraitement(traitement(id: 'a', parcelleId: p.id));

      final restored = Journal.fromJson(
        jsonDecode(jsonEncode(journal.toJson())) as Map<String, dynamic>,
      );

      expect(restored.parcelles.single.id, p.id);
      expect(restored.traitements.single.id, 'a');
      expect(restored.traitements.single.parcelleId, p.id);
    });
  });

  group('export', () {
    test('CSV : en-tête, BOM, ligne et échappement', () {
      final csv = JournalExport.toCsv(
        parcelles: [parcelle()],
        traitements: [traitement(note: 'Parcelle humide; ne pas traiter')],
      );

      expect(csv.startsWith('\uFEFFDate;Parcelle;Culture'), isTrue);
      expect(
        csv.contains('12/05/2026;Les Hauts;Vigne;OROCIDE;2180631;Mildiou(s)'),
        isTrue,
      );
      expect(csv.contains('02/06/2026'), isTrue);
      expect(csv.contains('"Parcelle humide; ne pas traiter"'), isTrue);
    });

    test('PDF : document valide', () async {
      final bytes = await JournalExport.toPdf(
        parcelles: [parcelle()],
        traitements: [
          traitement(),
          traitement(id: 't2', date: DateTime(2026, 6, 3)),
        ],
        versionDonnees: '2026-10-20',
        aujourdhui: DateTime(2026, 10, 24),
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1000));
    });
  });

  test('pdfSafe remplace les caractères hors Latin-1', () {
    expect(pdfSafe('Œufs d’acariens — test'), "OEufs d'acariens - test");
  });
}
