import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/journal_export.dart';
import '../../data/scope.dart';

/// Écrit le carnet dans un fichier CSV ou PDF et indique son emplacement.
Future<void> exportJournal(BuildContext context, {required bool pdf}) async {
  final scope = PhytiaScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final directory = await _exportDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final journal = scope.journal;

    late final File file;
    if (pdf) {
      final bytes = await JournalExport.toPdf(
        parcelles: journal.parcelles,
        traitements: journal.traitements,
        versionDonnees: scope.dataset.updatedAt,
      );
      file = File(
        '${directory.path}${Platform.pathSeparator}phytia-carnet-$stamp.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
    } else {
      final csv = JournalExport.toCsv(
        parcelles: journal.parcelles,
        traitements: journal.traitements,
      );
      file = File(
        '${directory.path}${Platform.pathSeparator}phytia-carnet-$stamp.csv',
      );
      await file.writeAsString(csv, flush: true);
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export terminé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${journal.traitements.length} traitement(s) exporté(s).'),
            const SizedBox(height: 10),
            SelectableText(file.path, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Export impossible : $error')),
    );
  }
}

Future<Directory> _exportDirectory() async {
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
  } catch (_) {
    // Pas de dossier Téléchargements sur cette plateforme.
  }
  return getApplicationDocumentsDirectory();
}
