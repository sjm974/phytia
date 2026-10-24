import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Empreinte SHA-256 en hexadécimal.
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Un fichier publié dans une release du catalogue.
class DataFileRef {
  const DataFileRef({
    required this.name,
    required this.bytes,
    required this.sha256,
  });

  final String name;
  final int bytes;
  final String sha256;

  factory DataFileRef.fromJson(Map<String, dynamic> json) => DataFileRef(
    name: json['name'] as String? ?? '',
    bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
  );

  /// Vérifie la taille et l'empreinte du fichier téléchargé.
  bool verify(List<int> content) =>
      content.length == bytes && sha256Hex(content) == sha256;
}

/// Manifeste décrivant une version du catalogue E-Phy.
class UpdateManifest {
  const UpdateManifest({
    required this.schema,
    required this.version,
    required this.generatedAt,
    required this.source,
    required this.core,
    required this.details,
    required this.usageCount,
    required this.productCount,
    required this.cultureCount,
  });

  final int schema;

  /// Date du jeu de données Anses, au format AAAA-MM-JJ.
  final String version;
  final String generatedAt;
  final String source;
  final DataFileRef core;
  final DataFileRef details;
  final int usageCount;
  final int productCount;
  final int cultureCount;

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final files = json['files'] as Map<String, dynamic>? ?? const {};
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    return UpdateManifest(
      schema: (json['schema'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
      generatedAt: json['generated_at'] as String? ?? '',
      source: json['source'] as String? ?? 'Anses — E-Phy',
      core: DataFileRef.fromJson(
        (files['core'] as Map<String, dynamic>?) ?? const {},
      ),
      details: DataFileRef.fromJson(
        (files['details'] as Map<String, dynamic>?) ?? const {},
      ),
      usageCount: (counts['usages'] as num?)?.toInt() ?? 0,
      productCount: (counts['produits'] as num?)?.toInt() ?? 0,
      cultureCount: (counts['cultures'] as num?)?.toInt() ?? 0,
    );
  }

  static UpdateManifest parse(List<int> bytes) => UpdateManifest.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );

  /// Vrai si ce manifeste est plus récent que la version embarquée.
  /// Les versions sont des dates ISO : la comparaison lexicographique suffit.
  bool isNewerThan(String currentVersion) =>
      version.isNotEmpty && version.compareTo(currentVersion) > 0;

  String get versionLabel {
    final parts = version.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return version;
  }
}
