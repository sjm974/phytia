import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'journal_models.dart';
import 'models.dart';

/// Génère le carnet de traitement au format CSV et PDF.
/// Aucune dépendance native : les octets sont produits ici, l'écriture du
/// fichier est laissée à l'interface.
class JournalExport {
  static const List<String> columns = [
    'Date',
    'Intervention',
    'Heure début',
    'Heure fin',
    'Parcelle',
    'Culture',
    'Produit',
    'AMM',
    'Cible',
    'Dose',
    'Unité',
    'Surface (m²)',
    'Quantité',
    'Volume bouillie (L)',
    'Stade BBCH',
    'DAR (j)',
    'Récolte possible le',
    'Mode de conduite',
    'Latitude',
    'Longitude',
    'Opérateur',
    'Note',
  ];

  /// CSV point-virgule, avec BOM UTF-8, lisible directement par Excel.
  static String toCsv({
    required List<Parcelle> parcelles,
    required List<Traitement> traitements,
    DateTime? aujourdhui,
  }) {
    final names = {for (final p in parcelles) p.id: p.nom};
    final buffer = StringBuffer()
      ..write('\uFEFF')
      ..writeln(columns.map(_csvCell).join(';'));

    for (final t in _sorted(traitements)) {
      final recolte = t.recoltePossibleLe;
      buffer.writeln(
        [
          frDate(t.date),
          t.intervention,
          t.heureDebut,
          t.heureFin,
          names[t.parcelleId] ?? '',
          t.culture,
          t.produit,
          t.amm,
          t.cible,
          t.dose,
          t.doseUnite,
          _number(t.surfaceTraiteeM2),
          quantite(t),
          _number(t.volumeBouillie),
          t.stadeBbch,
          t.darJours?.toString() ?? '',
          recolte == null ? '' : frDate(recolte),
          t.modeConduite,
          t.latitude?.toStringAsFixed(6) ?? '',
          t.longitude?.toStringAsFixed(6) ?? '',
          t.operateur,
          t.note,
        ].map(_csvCell).join(';'),
      );
    }
    return buffer.toString();
  }

  /// Quantité de produit à prélever pour un traitement enregistré.
  static String quantite(Traitement traitement) => doseQuantite(
    traitement.dose,
    traitement.doseUnite,
    traitement.surfaceTraiteeM2 ?? 0,
    volumeBouillie: traitement.volumeBouillie,
  );

  /// PDF paysage : une ligne par traitement, tri par date.
  static Future<Uint8List> toPdf({
    required List<Parcelle> parcelles,
    required List<Traitement> traitements,
    required String versionDonnees,
    DateTime? aujourdhui,
  }) async {
    final names = {for (final p in parcelles) p.id: p.nom};
    final date = aujourdhui ?? DateTime.now();
    final doc = pw.Document();
    final rows = _sorted(traitements).map((t) {
      final recolte = t.recoltePossibleLe;
      return [
        frDate(t.date),
        t.heureLabel,
        names[t.parcelleId] ?? '',
        t.produit,
        t.cible,
        t.doseLabel,
        _number(t.surfaceTraiteeM2),
        quantite(t),
        t.volumeLabel,
        t.darJours?.toString() ?? '',
        recolte == null ? '' : frDate(recolte),
      ].map(pdfSafe).toList();
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              pdfSafe('Carnet de traitement'),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              pdfSafe(
                'Export du ${frDate(date)} - ${traitements.length} traitement(s)'
                ' - catalogue E-Phy du ${frDate(DateTime.parse(versionDonnees))}',
              ),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 0.8),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Heures',
              'Parcelle',
              'Produit',
              'Cible',
              'Dose',
              'Surface',
              'Quantité',
              'Volume',
              'DAR',
              'Récolte dès',
            ].map(pdfSafe).toList(),
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 3,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.7),
              1: pw.FlexColumnWidth(1.7),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(3.6),
              4: pw.FlexColumnWidth(3),
              5: pw.FlexColumnWidth(1.8),
              6: pw.FlexColumnWidth(1.3),
              7: pw.FlexColumnWidth(1.3),
              8: pw.FlexColumnWidth(1.2),
              9: pw.FlexColumnWidth(0.9),
              10: pw.FlexColumnWidth(1.8),
            },
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            pdfSafe(
              'Données E-Phy - Anses (non opposables). Document de suivi '
              "d'exploitation, ne remplace pas le registre réglementaire.",
            ),
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
        ),
      ),
    );
    return doc.save();
  }

  static List<Traitement> _sorted(List<Traitement> input) {
    final list = [...input];
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  static String _csvCell(String value) {
    final clean = value.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (clean.contains(';') || clean.contains('"')) {
      return '"${clean.replaceAll('"', '""')}"';
    }
    return clean;
  }

  static String _number(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

/// Volume de bouillie courant pour une culture, en litres par hectare.
/// Ordre de grandeur de départ, à remplacer par la calibration du
/// pulvérisateur (essai à l'eau sur une surface connue).
int volumeHaIndicatif(String culture) {
  final c = normalize(culture);
  if (c.contains('vigne') ||
      c.contains('arbre') ||
      c.contains('verger') ||
      c.contains('rosier') ||
      c.contains('pepiniere') ||
      c.contains('ornement')) {
    return 500;
  }
  if (c.contains('tomate') ||
      c.contains('laitue') ||
      c.contains('salade') ||
      c.contains('fraisier') ||
      c.contains('legume') ||
      c.contains('maraich') ||
      c.contains('poivron') ||
      c.contains('concombre')) {
    return 300;
  }
  if (c.contains('ble') ||
      c.contains('orge') ||
      c.contains('mais') ||
      c.contains('colza') ||
      c.contains('tournesol') ||
      c.contains('cereale') ||
      c.contains('betterave') ||
      c.contains('avoine') ||
      c.contains('seigle')) {
    return 150;
  }
  return 200;
}

/// Volume total de bouillie pour une surface traitée, en litres.
double volumeTotalLitres(double volumeHa, double surfaceM2) =>
    volumeHa * surfaceM2 / 10000;

/// Vrai si la cible saisie ressemble à une cible du catalogue.
/// Tolérant : « Mildiou » correspond à « Mildiou(s) ».
bool cibleCorrespond(String saisie, String catalogue) {
  final a = normalize(saisie).trim();
  final b = normalize(catalogue).trim();
  if (a.length < 3 || b.isEmpty) return false;
  return a.contains(b) || b.contains(a);
}

/// Surface en mètres carrés, formatée à la française.
String formatM2(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) {
    return '${_groupThousands(value.round())} m²';
  }
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} m²';
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Quantité de produit à prélever, à partir d'une dose exprimée par hectare,
/// par hectolitre de bouillie, par m² ou par 10 m².
///
/// Les doses par hectolitre (L/hL) sont une concentration : il faut le volume
/// de bouillie pour trouver la quantité, d'où le paramètre optionnel.
/// Renvoie une chaîne vide si l'unité n'est pas reconnue ou si une donnée
/// indispensable manque.
String doseQuantite(
  String dose,
  String unite,
  double surfaceM2, {
  double? volumeBouillie,
}) {
  final value = double.tryParse(dose.replaceAll(',', '.').trim());
  if (value == null || value <= 0) return '';

  final unit = unite.toLowerCase().replaceAll('²', '2').replaceAll(' ', '');
  final numerator = unit.split('/').first;

  double quantity;
  if (unit.contains('/hl')) {
    final volume = volumeBouillie;
    if (volume == null || volume <= 0) return '';
    quantity = value * volume / 100; // 1 hL = 100 L de bouillie
  } else if (unit.contains('/10m')) {
    if (surfaceM2 <= 0) return '';
    quantity = value * surfaceM2 / 10;
  } else if (unit.contains('/m2')) {
    if (surfaceM2 <= 0) return '';
    quantity = value * surfaceM2;
  } else if (unit.contains('/ha')) {
    if (surfaceM2 <= 0) return '';
    quantity = value * surfaceM2 / 10000;
  } else {
    return '';
  }

  switch (numerator) {
    case 'l':
      return _formatVolume(quantity);
    case 'ml':
      return _formatVolume(quantity / 1000);
    case 'kg':
      return _formatMass(quantity);
    case 'g':
      return _formatMass(quantity / 1000);
  }
  return '';
}

String _formatVolume(double litres) {
  if (litres < 0.001) return '';
  if (litres < 1) return '${(litres * 1000).round()} mL';
  return '${_pretty(litres.toStringAsFixed(2))} L';
}

String _formatMass(double kilograms) {
  if (kilograms < 0.001) return '';
  if (kilograms < 1) return '${(kilograms * 1000).round()} g';
  return '${_pretty(kilograms.toStringAsFixed(2))} kg';
}

String _pretty(String value) =>
    value.replaceAll(RegExp(r'\.?0+$'), '').replaceAll('.', ',');

/// Date au format jj/mm/aaaa.
String frDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Remplace les caractères hors Latin-1 (les polices PDF standard ne les
/// connaissent pas) pour éviter toute exception à la génération.
String pdfSafe(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune <= 0xFF) {
      buffer.writeCharCode(rune);
    } else {
      buffer.write(_replacements[rune] ?? '?');
    }
  }
  return buffer.toString();
}

const Map<int, String> _replacements = {
  0x0152: 'OE',
  0x0153: 'oe',
  0x2019: "'",
  0x2018: "'",
  0x201C: '"',
  0x201D: '"',
  0x2013: '-',
  0x2014: '-',
  0x2026: '...',
  0x00A0: ' ',
  0x20AC: 'EUR',
};
