import 'dart:io';

import 'package:phytia/data/dataset.dart';
import 'package:phytia/data/models.dart';
import 'package:test/test.dart';

/// Vérifie le catalogue réellement embarqué (assets/data/phytia_core.json.gz).
void main() {
  late PhytiaDataset data;

  setUpAll(() {
    final bytes = File('assets/data/phytia_core.json.gz').readAsBytesSync();
    data = PhytiaDataset.fromBytes(bytes);
  });

  test('le catalogue embarqué est complet', () {
    expect(data.products.length, greaterThan(15000));
    expect(data.usages.length, greaterThan(19000));
    expect(data.cultures.length, greaterThan(120));
    expect(data.targetCount, greaterThan(1200));
    expect(data.authorizedUsageCount, greaterThan(18000));
  });

  test('chaque usage possède un produit et une culture', () {
    for (final u in data.usages) {
      expect(u.culture, isNotEmpty, reason: 'usage sans culture: ${u.amm}');
      expect(
        data.products.containsKey(u.amm),
        isTrue,
        reason: 'produit manquant pour ${u.amm}',
      );
    }
  });

  test('vigne × mildiou : produits homologués avec dose, DAR et ZNT', () {
    final results = data.resultsFor('Vigne', 'Mildiou(s)');

    expect(results, isNotEmpty);
    expect(results.every((r) => r.usages.any((u) => u.isAuthorized)), isTrue);
    expect(results.every((r) => r.product.name.isNotEmpty), isTrue);

    final withDose = results.where((r) => r.doseSummary.isNotEmpty);
    expect(withDose, isNotEmpty);

    final withDar = results.where(
      (r) => r.usages.any((u) => u.darLabel != null),
    );
    expect(withDar, isNotEmpty);

    final withZnt = results.where(
      (r) => r.usages.any((u) => u.zntLabel != null),
    );
    expect(withZnt, isNotEmpty);
  });

  test('les usages retirés sont exclus par défaut', () {
    final authorizedOnly = data.resultsFor('Vigne', 'Mildiou(s)');
    final withWithdrawn = data.resultsFor(
      'Vigne',
      'Mildiou(s)',
      includeWithdrawn: true,
    );

    expect(withWithdrawn.length, greaterThanOrEqualTo(authorizedOnly.length));
    expect(
      authorizedOnly.every((r) => r.usages.any((u) => u.isAuthorized)),
      isTrue,
    );
  });

  test('le filtre par type de traitement isole le désherbage', () {
    final entries = data.targetsForCulture('Blé');
    final desherbage = entries.where((e) => e.target.isEmpty).toList();
    expect(desherbage, isNotEmpty);

    final results = data.resultsFor('Blé', '', type: desherbage.first.type);
    expect(results, isNotEmpty);
    expect(
      results.every(
        (r) => r.usages.every((u) => u.typeTraitement == desherbage.first.type),
      ),
      isTrue,
    );
  });

  test('recherche de produit insensible aux accents et à la casse', () {
    expect(data.searchProducts('bordelaise'), isNotEmpty);
    expect(data.searchProducts('BORDELAISE'), isNotEmpty);
    expect(data.searchProducts('cuivre'), isNotEmpty);
  });

  test('recherche de culture', () {
    expect(data.searchCultures('ble'), contains('Blé'));
    expect(data.searchCultures('vigne'), contains('Vigne'));
    expect(data.searchCultures('zzzz'), isEmpty);
  });

  test('normalize retire les accents', () {
    expect(normalize('Blé tendre d\'hiver'), 'ble tendre d\'hiver');
    expect(normalize('Oïdium(s)'), 'oidium(s)');
  });

  test('les produits ont des substances actives lisibles', () {
    final sample = data.products.values.where(
      (p) => p.substanceList.isNotEmpty,
    );
    expect(sample.length, greaterThan(10000));
  });

  group("cas réel : Essen'ciel vs Limocide J", () {
    String key(Usage u) => '${u.culture}|${u.typeTraitement}|${u.target}';

    test('même substance, deux AMM et deux gammes', () {
      final essen = data.product('2090127')!;
      final limocide = data.product('2200059')!;

      expect(normalize(essen.substances), normalize(limocide.substances));
      expect(normalize(essen.substances), contains('orange'));
      expect(essen.amm, isNot(equals(limocide.amm)));
      expect(limocide.isAmateur, isTrue);
      expect(essen.isAmateur, isFalse);
    });

    test('les usages autorisés ne se recouvrent pas entièrement', () {
      final a = data.usagesForProduct('2090127', includeWithdrawn: false);
      final b = data.usagesForProduct('2200059', includeWithdrawn: false);

      final sa = a.map(key).toSet();
      final sb = b.map(key).toSet();

      expect(sa.intersection(sb).length, 55);
      expect(sa.difference(sb), isNotEmpty);
      expect(sb.difference(sa), isNotEmpty);
      expect(sa, contains('Vigne|Trt Part.Aer.|Mildiou(s)'));
      expect(sb, contains('Vigne|Trt Part.Aer.|Mildiou(s)'));
      expect(sa, isNot(contains('Rosier|Trt Part.Aer.|Pucerons')));
      expect(sb, contains('Rosier|Trt Part.Aer.|Pucerons'));
    });

    test('les équivalents partagent la composition déclarée', () {
      final reference = data.product('2090127')!;
      final equivalents = data.equivalentProducts('2090127');

      expect(equivalents, isNotEmpty);
      expect(equivalents.any((p) => p.name == 'LIMOCIDE J'), isTrue);
      expect(equivalents.any((p) => p.name.startsWith('OROCIDE')), isTrue);
      for (final p in equivalents) {
        expect(p.amm, isNot(equals('2090127')));
        expect(normalize(p.substances), normalize(reference.substances));
      }
    });

    test('une composition unique n\'a aucun équivalent', () {
      expect(data.equivalentProducts('8800006'), isEmpty);
    });

    test('un équivalent n\'est pas forcément autorisé pour le même usage', () {
      bool authorizedForVineMildew(Product p) => data
          .usagesForProduct(p.amm, includeWithdrawn: false)
          .any(
            (u) =>
                u.culture == 'Vigne' &&
                u.target == 'Mildiou(s)' &&
                u.typeTraitement == 'Trt Part.Aer.',
          );

      final equivalents = data.equivalentProducts('2090127');
      expect(equivalents.any(authorizedForVineMildew), isTrue);
      expect(equivalents.every(authorizedForVineMildew), isFalse);
    });
  });
}
