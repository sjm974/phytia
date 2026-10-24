import 'dart:io';

import 'package:phytia/data/manifest.dart';
import 'package:test/test.dart';

void main() {
  test('le manifeste livré décrit fidèlement les fichiers', () {
    final manifest = UpdateManifest.parse(
      File('assets/data/manifest.json').readAsBytesSync(),
    );

    expect(manifest.schema, 1);
    expect(manifest.version, matches(r'^\d{4}-\d{2}-\d{2}$'));
    expect(manifest.usageCount, greaterThan(19000));
    expect(manifest.productCount, greaterThan(15000));

    final core = File('assets/data/phytia_core.json.gz').readAsBytesSync();
    final details = File('assets/data/phytia_details.json.gz')
        .readAsBytesSync();

    expect(manifest.core.verify(core), isTrue);
    expect(manifest.details.verify(details), isTrue);
    expect(manifest.core.bytes, core.length);
  });

  test('une corruption du fichier est détectée', () {
    final manifest = UpdateManifest.parse(
      File('assets/data/manifest.json').readAsBytesSync(),
    );
    final core = File('assets/data/phytia_core.json.gz').readAsBytesSync();

    final corrupted = List<int>.from(core);
    corrupted[100] = corrupted[100] ^ 0xFF;

    expect(manifest.core.verify(corrupted), isFalse);
    expect(manifest.core.verify(core.sublist(0, core.length - 10)), isFalse);
  });

  test('comparaison de versions', () {
    const manifest = UpdateManifest(
      schema: 1,
      version: '2026-10-28',
      generatedAt: '',
      source: '',
      core: DataFileRef(name: 'a', bytes: 0, sha256: ''),
      details: DataFileRef(name: 'b', bytes: 0, sha256: ''),
      usageCount: 0,
      productCount: 0,
      cultureCount: 0,
    );

    expect(manifest.isNewerThan('2026-10-20'), isTrue);
    expect(manifest.isNewerThan('2026-10-28'), isFalse);
    expect(manifest.isNewerThan('2026-11-03'), isFalse);
    expect(manifest.isNewerThan(''), isTrue);
    expect(manifest.versionLabel, '28/10/2026');
  });

  test('parse tolère un manifeste incomplet', () {
    final manifest = UpdateManifest.parse('{"version":"2026-10-25"}'.codeUnits);
    expect(manifest.version, '2026-10-25');
    expect(manifest.core.sha256, isEmpty);
    expect(manifest.usageCount, 0);
  });
}
