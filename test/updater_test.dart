import 'dart:io';

import 'package:phytia/data/updater.dart';
import 'package:test/test.dart';

/// Vérifie le cycle complet de mise à jour contre un serveur HTTP local :
/// lecture du manifeste, téléchargement, contrôle SHA-256, écriture, rechargement.
void main() {
  late HttpServer server;
  late Directory temp;
  late String baseUrl;
  final files = <String, List<int>>{};
  var corruptCore = false;

  setUpAll(() async {
    files['manifest.json'] = File('assets/data/manifest.json')
        .readAsBytesSync();
    files['phytia_core.json.gz'] = File('assets/data/phytia_core.json.gz')
        .readAsBytesSync();
    files['phytia_details.json.gz'] = File('assets/data/phytia_details.json.gz')
        .readAsBytesSync();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      final name = path.startsWith('/') ? path.substring(1) : path;
      var body = files[name];
      if (body == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      if (name == 'phytia_core.json.gz' && corruptCore) {
        body = List<int>.from(body);
        body[body.length ~/ 2] ^= 0xFF;
      }
      request.response.headers.contentType = ContentType.binary;
      request.response.contentLength = body.length;
      request.response.add(body);
      await request.response.close();
    });
    baseUrl = 'http://127.0.0.1:${server.port}/';
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  setUp(() {
    corruptCore = false;
    temp = Directory.systemTemp.createTempSync('phytia_update');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('installe une nouvelle version et recharge le catalogue', () async {
    final updater = DataUpdater(baseUrl: baseUrl, directory: temp);
    final manifest = await updater.fetchManifest();

    expect(manifest.version, matches(r'^\d{4}-\d{2}-\d{2}$'));
    expect(manifest.usageCount, greaterThan(19000));

    final progress = <double>[];
    final dataset = await updater.install(manifest, onProgress: progress.add);

    expect(dataset.usageCount, manifest.usageCount);
    expect(dataset.productCount, manifest.productCount);
    expect(File('${temp.path}/phytia_core.json.gz').existsSync(), isTrue);
    expect(File('${temp.path}/phytia_details.json.gz').existsSync(), isTrue);
    expect(progress, isNotEmpty);
    expect(progress.last, closeTo(1.0, 0.001));
  });

  test('refuse un fichier dont l\'empreinte ne correspond pas', () async {
    final updater = DataUpdater(baseUrl: baseUrl, directory: temp);
    final manifest = await updater.fetchManifest();

    corruptCore = true;
    await expectLater(
      updater.install(manifest),
      throwsA(isA<DataUpdateException>()),
    );
    expect(File('${temp.path}/phytia_core.json.gz').existsSync(), isFalse);
  });

  test('signale un manifeste absent', () async {
    final updater = DataUpdater(
      baseUrl: 'http://127.0.0.1:${server.port}/inexistant/',
      directory: temp,
    );
    await expectLater(
      updater.fetchManifest(),
      throwsA(isA<DataUpdateException>()),
    );
  });
}
