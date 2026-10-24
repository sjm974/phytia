import 'dart:io';
import 'dart:typed_data';

import 'dataset.dart';
import 'manifest.dart';

class DataUpdateException implements Exception {
  DataUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Télécharge et installe une nouvelle version du catalogue publiée en release
/// GitHub, sans passer par le magasin d'applications.
class DataUpdater {
  DataUpdater({required this.baseUrl, required this.directory});

  final String baseUrl;
  final Directory directory;

  Uri _uri(String name) =>
      Uri.parse(baseUrl.endsWith('/') ? '$baseUrl$name' : '$baseUrl/$name');

  Future<UpdateManifest> fetchManifest() async {
    final bytes = await _get(_uri('manifest.json'));
    try {
      return UpdateManifest.parse(bytes);
    } catch (_) {
      throw DataUpdateException('Manifeste illisible');
    }
  }

  /// Télécharge les deux fichiers, vérifie leur empreinte, les écrit dans le
  /// dossier de données puis renvoie le catalogue rechargé.
  Future<PhytiaDataset> install(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    final coreBytes = await _get(
      _uri(manifest.core.name),
      expectedBytes: manifest.core.bytes,
      onProgress: onProgress,
    );
    if (!manifest.core.verify(coreBytes)) {
      throw DataUpdateException('Fichier corrompu : ${manifest.core.name}');
    }

    final detailsBytes = await _get(
      _uri(manifest.details.name),
      expectedBytes: manifest.details.bytes,
    );
    if (!manifest.details.verify(detailsBytes)) {
      throw DataUpdateException('Fichier corrompu : ${manifest.details.name}');
    }

    try {
      directory.createSync(recursive: true);
      _writeAtomic(manifest.core.name, coreBytes);
      _writeAtomic(manifest.details.name, detailsBytes);
    } on FileSystemException catch (error) {
      throw DataUpdateException('Écriture impossible : ${error.message}');
    }

    try {
      return PhytiaDataset.fromBytes(coreBytes);
    } catch (error) {
      throw DataUpdateException('Catalogue illisible : $error');
    }
  }

  void _writeAtomic(String name, Uint8List bytes) {
    final target = File('${directory.path}/$name');
    final temporary = File('${target.path}.tmp');
    temporary.writeAsBytesSync(bytes, flush: true);
    if (target.existsSync()) target.deleteSync();
    temporary.renameSync(target.path);
  }

  Future<Uint8List> _get(
    Uri uri, {
    int expectedBytes = 0,
    void Function(double progress)? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'Phytia/0.1');
      request.followRedirects = true;
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw DataUpdateException(
          'Téléchargement impossible (HTTP ${response.statusCode})',
        );
      }

      final total = response.contentLength > 0
          ? response.contentLength
          : expectedBytes;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress((builder.length / total).clamp(0.0, 1.0));
        }
      }
      return builder.takeBytes();
    } on SocketException {
      throw DataUpdateException('Pas de connexion internet');
    } on HttpException {
      throw DataUpdateException('Téléchargement interrompu');
    } finally {
      client.close(force: true);
    }
  }
}
