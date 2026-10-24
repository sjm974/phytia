import 'dart:io';

import 'package:flutter/services.dart';

/// Accès aux fichiers du catalogue : priorité au cache téléchargé, repli sur
/// les assets embarqués dans l'application.
class DataFiles {
  DataFiles({required this.bundle, required this.cacheDir});

  final AssetBundle bundle;
  final Directory? cacheDir;

  static const String coreName = 'phytia_core.json.gz';
  static const String detailsName = 'phytia_details.json.gz';

  Future<Uint8List> core() => _read(coreName);
  Future<Uint8List> details() => _read(detailsName);

  Future<Uint8List> coreAsset() => asset(coreName);

  Future<Uint8List> _read(String name) async {
    final file = _cacheFile(name);
    if (file != null) {
      try {
        return file.readAsBytesSync();
      } catch (_) {
        // Fichier illisible : on repart de l'asset embarqué.
      }
    }
    return asset(name);
  }

  Future<Uint8List> asset(String name) async {
    final data = await bundle.load('assets/data/$name');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  File? _cacheFile(String name) {
    final dir = cacheDir;
    if (dir == null) return null;
    final file = File('${dir.path}/$name');
    return file.existsSync() ? file : null;
  }

  bool get hasCache =>
      _cacheFile(coreName) != null && _cacheFile(detailsName) != null;

  void clearCache() {
    final dir = cacheDir;
    if (dir == null || !dir.existsSync()) return;
    for (final name in [coreName, detailsName]) {
      final file = File('${dir.path}/$name');
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }
}
