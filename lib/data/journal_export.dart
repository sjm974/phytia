import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'journal_models.dart';

/// Génère le carnet de traitement au format CSV et PDF.
/// Aucune dépendance native : les octets sont produits ici, l'écriture du
/// fichier est laissée à l'interface.
class JournalExport {
  static const List<String> columns = [
    'Date',
    'Parcelle',
    'Culture',
    'Produit',
    'AMM',
    'Cible',
    'Dose',
    'Unité',
    'Surface (ha)',
    'Stade BBCH',
    'DAR (j)',
    'Récolte possible le',
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
          names[t.parcelleId] ?? '',
          t.culture,
          t.produit,
          t.amm,
          t.cible,
          t.dose,
          t.doseUnite,
          _number(t.surfaceTraiteeHa),
          t.stadeBbch,
          t.darJours?.toString() ?? '',
          recolte == null ? '' : frDate(recolte),
          t.operateur,
          t.note,
        ].map(_csvCell).join(';'),
      );
    }
    return buffer.toString();
  }

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
        names[t.parcelleId] ?? '',
        t.produit,
        t.cible,
        t.doseLabel,
        _number(t.surfaceTraiteeHa),
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
              'Parcelle',
              'Produit',
              'Cible',
              'Dose',
              'Surface',
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
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(4),
              3: pw.FlexColumnWidth(3.5),
              4: pw.FlexColumnWidth(2),
              5: pw.FlexColumnWidth(2),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(2),
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

/// Surface en hectares, formatée à la française.
String formatHa(double? value) {
  if (value == null) return '';
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2).replaceAll('.', ',');
  return '$text ha';
}

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
