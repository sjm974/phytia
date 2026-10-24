import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Convertit l'archive CSV E-Phy (Anses) en assets JSON gzippés + manifeste.
///
///   dart tool/build_dataset.dart --csv=_data/csv --out=assets/data --date=2026-10-20
///
/// --csv   dossier contenant les fichiers *_utf8.csv (defaut : _data/csv)
/// --out   dossier de sortie (defaut : assets/data)
/// --date  version du jeu de donnees, format AAAA-MM-JJ (defaut : aujourd'hui)
void main(List<String> args) {
  final csvDir = _arg(args, 'csv') ?? _defaultCsvDir();
  final outDir = _arg(args, 'out') ?? 'assets/data';
  final date = _arg(args, 'date') ?? _today();

  if (!Directory(csvDir).existsSync()) {
    stderr.writeln('Dossier CSV introuvable : ' + csvDir);
    exitCode = 1;
    return;
  }
  Directory(outDir).createSync(recursive: true);

  List<String> readCsv(String name) => const LineSplitter()
      .convert(File(csvDir + '/' + name).readAsStringSync())
      .where((l) => l.trim().isNotEmpty)
      .toList();

  int col(List<String> header, String name) {
    final i = header.indexWhere(
      (e) => e.trim().toLowerCase() == name.toLowerCase(),
    );
    if (i < 0) throw StateError('Colonne introuvable: ' + name);
    return i;
  }

  String cell(List<String> row, int i) => i < row.length ? row[i].trim() : '';

  // ---------- produits ----------
  final pLines = readCsv('produits_utf8.csv');
  final pH = pLines.first.split(';');
  final pNom = col(pH, 'nom produit');
  final pAmm = col(pH, 'numero AMM');
  final pTit = col(pH, 'titulaire');
  final pSub = col(pH, 'Substances actives');
  final pFon = col(pH, 'fonctions');
  final pFor = col(pH, 'formulations');
  final pGam = col(pH, 'gamme usage');
  final pEta = col(pH, 'Etat d\u2019autorisation');
  final pRes = col(pH, 'restrictions usage libelle');

  final produits = <String, List<String>>{};
  for (final l in pLines.skip(1)) {
    final r = l.split(';');
    final amm = cell(r, pAmm);
    if (amm.isEmpty) continue;
    produits[amm] = [
      cell(r, pNom),
      cell(r, pTit),
      cell(r, pSub),
      cell(r, pFon),
      cell(r, pFor),
      cell(r, pGam),
      cell(r, pEta),
      cell(r, pRes),
    ];
  }

  // ---------- intervalles (produits_usages) ----------
  final puLines = readCsv('produits_usages_utf8.csv');
  final puH = puLines.first.split(';');
  final puAmm = col(puH, 'numero AMM');
  final puId = col(puH, 'identifiant usage');
  final puInt = col(puH, 'intervalle minimum entre applications (jour)');
  final intervalles = <String, String>{};
  for (final l in puLines.skip(1)) {
    final r = l.split(';');
    final k = cell(r, puAmm) + '|' + cell(r, puId);
    final v = cell(r, puInt);
    if (v.isNotEmpty && !intervalles.containsKey(k)) intervalles[k] = v;
  }

  // ---------- usages ----------
  final uLines = readCsv('usages_des_produits_autorises_utf8.csv');
  final uH = uLines.first.split(';');
  final uAmm = col(uH, 'numero AMM');
  final uNom = col(uH, 'nom produit');
  final uId = col(uH, 'identifiant usage');
  final uCult = col(uH, 'identifiant usage lib court');
  final uStMin = col(uH, 'stade cultural min (BBCH)');
  final uStMax = col(uH, 'stade cultural max (BBCH)');
  final uEta = col(uH, 'etat usage');
  final uDose = col(uH, 'dose retenue');
  final uUn = col(uH, 'dose retenue unite');
  final uDar = col(uH, 'delai avant recolte jour');
  final uDarB = col(uH, 'delai avant recolte bbch');
  final uNb = col(uH, 'nombre max d\'application');
  final uZntA = col(uH, 'ZNT aquatique (en m)');
  final uZntAr = col(uH, 'ZNT arthropodes non cibles (en m)');
  final uZntP = col(uH, 'ZNT plantes non cibles (en m)');
  final uCond = col(uH, 'condition emploi');
  final uMen = col(uH, 'mentions autorisees');
  final uDec = col(uH, 'date decision');
  final uGam = col(uH, 'gamme usage');
  final uSub = col(uH, 'Substances actives');
  final uFon = col(uH, 'fonctions');
  final uFor = col(uH, 'formulations');

  final usages = <List<String>>[];
  final seen = <String>{};
  var doublons = 0;
  for (final l in uLines.skip(1)) {
    final r = l.split(';');
    final amm = cell(r, uAmm);
    final id = cell(r, uId);
    if (amm.isEmpty || id.isEmpty) continue;

    final key = [
      amm,
      id,
      cell(r, uDose),
      cell(r, uUn),
      cell(r, uDar),
      cell(r, uStMin),
      cell(r, uStMax),
      cell(r, uNb),
      cell(r, uCond),
      cell(r, uZntA),
      cell(r, uZntAr),
      cell(r, uZntP),
    ].join('|');
    if (!seen.add(key)) {
      doublons++;
      continue;
    }

    final idKey = amm + '|' + id;
    final parts = id.split('*');
    final culture = parts.first.trim();
    final type = parts.length >= 2 ? parts[1].trim() : '';
    final cible = parts.length >= 3 ? parts.sublist(2).join('*').trim() : '';

    if (!produits.containsKey(amm)) {
      produits[amm] = [
        cell(r, uNom),
        '',
        cell(r, uSub),
        cell(r, uFon),
        cell(r, uFor),
        cell(r, uGam),
        '',
        '',
      ];
    }
    usages.add([
      amm,
      culture,
      type,
      cible,
      cell(r, uCult),
      cell(r, uDose),
      cell(r, uUn),
      cell(r, uDar),
      cell(r, uDarB),
      cell(r, uNb),
      intervalles[idKey] ?? '',
      cell(r, uZntA),
      cell(r, uZntAr),
      cell(r, uZntP),
      cell(r, uStMin),
      cell(r, uStMax),
      cell(r, uEta),
      cell(r, uGam),
      cell(r, uMen),
      cell(r, uDec),
    ]);
  }

  // ---------- details ----------
  final cond = <String, List<List<String>>>{};
  final cLines = readCsv('produits_condition_emploi_utf8.csv');
  final cH = cLines.first.split(';');
  final cAmm = col(cH, 'numero AMM');
  final cCat = col(cH, 'catégorie de condition d\u2019emploi');
  final cLib = col(cH, 'condition d\u2019emploi libelle');
  for (final l in cLines.skip(1)) {
    final r = l.split(';');
    final a = cell(r, cAmm);
    if (a.isEmpty) continue;
    (cond[a] ??= []).add([cell(r, cCat), cell(r, cLib)]);
  }

  final risques = <String, List<List<String>>>{};
  final rLines = readCsv('produits_phrases_de_risque_utf8.csv');
  final rH = rLines.first.split(';');
  final rAmm = col(rH, 'numero AMM');
  final rCode = col(rH, 'Libellé court phrase de risque');
  final rLib = col(rH, 'Libellé long phrase de risque');
  for (final l in rLines.skip(1)) {
    final r = l.split(';');
    final a = cell(r, rAmm);
    if (a.isEmpty) continue;
    (risques[a] ??= []).add([cell(r, rCode), cell(r, rLib)]);
  }

  final danger = <String, List<List<String>>>{};
  final dLines = readCsv('produits_classe_et_mention_danger_utf8.csv');
  final dH = dLines.first.split(';');
  final dAmm = col(dH, 'numero AMM');
  final dCour = col(dH, 'Libellé court');
  final dLong = col(dH, 'Libellé long');
  for (final l in dLines.skip(1)) {
    final r = l.split(';');
    final a = cell(r, dAmm);
    if (a.isEmpty) continue;
    final v = cell(r, dLong);
    if (v.isEmpty) continue;
    (danger[a] ??= []).add([cell(r, dCour), v]);
  }

  // ---------- écriture ----------
  final core = {
    'v': 1,
    'source': 'Anses — E-Phy (catalogue des produits phytopharmaceutiques)',
    'date': date,
    'produits': produits,
    'usages': usages,
  };
  final details = {'conditions': cond, 'risques': risques, 'danger': danger};

  final coreGz = gzip.encode(utf8.encode(jsonEncode(core)));
  final detailsGz = gzip.encode(utf8.encode(jsonEncode(details)));
  final coreFile = File(outDir + '/phytia_core.json.gz');
  final detailsFile = File(outDir + '/phytia_details.json.gz');
  coreFile.writeAsBytesSync(coreGz);
  detailsFile.writeAsBytesSync(detailsGz);

  final cultures = usages.map((u) => u[1]).toSet();
  final cibles = usages.map((u) => u[1] + '|' + u[3]).toSet();

  final manifest = {
    'schema': 1,
    'version': date,
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'source': 'Anses — E-Phy',
    'counts': {
      'usages': usages.length,
      'produits': produits.length,
      'cultures': cultures.length,
      'cibles': cibles.length,
    },
    'files': {
      'core': {
        'name': 'phytia_core.json.gz',
        'bytes': coreGz.length,
        'sha256': sha256.convert(coreGz).toString(),
      },
      'details': {
        'name': 'phytia_details.json.gz',
        'bytes': detailsGz.length,
        'sha256': sha256.convert(detailsGz).toString(),
      },
    },
  };
  File(outDir + '/manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

  stdout
    ..writeln('Version      : ' + date)
    ..writeln('Produits     : ' + produits.length.toString())
    ..writeln(
      'Usages       : ' +
          usages.length.toString() +
          (doublons > 0
              ? ' (doublons ignorés : ' + doublons.toString() + ')'
              : ''),
    )
    ..writeln('Cultures     : ' + cultures.length.toString())
    ..writeln('Cibles       : ' + cibles.length.toString())
    ..writeln(
      'core         : ' +
          (coreGz.length / 1024 / 1024).toStringAsFixed(2) +
          ' Mo',
    )
    ..writeln(
      'details      : ' +
          (detailsGz.length / 1024 / 1024).toStringAsFixed(2) +
          ' Mo',
    )
    ..writeln('sha256 core  : ' + sha256.convert(coreGz).toString());
}

String? _arg(List<String> args, String name) {
  final prefix = '--' + name + '=';
  for (final a in args) {
    if (a.startsWith(prefix)) return a.substring(prefix.length);
  }
  return null;
}

String _defaultCsvDir() {
  if (Directory('_data/csv').existsSync()) return '_data/csv';
  return 'csv';
}

String _today() {
  final now = DateTime.now().toUtc();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return now.year.toString() + '-' + m + '-' + d;
}
