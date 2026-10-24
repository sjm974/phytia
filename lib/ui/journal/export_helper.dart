import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/journal_export.dart';
import '../../data/registre_export.dart';
import '../../data/scope.dart';

/// Écrit le carnet dans un fichier CSV ou PDF et indique son emplacement.
Future<void> exportJournal(BuildContext context, {required bool pdf}) async {
  final scope = PhytiaScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final directory = await _exportDirectory();
    final stamp = _stamp();
    final journal = scope.journal;

    late final File file;
    late final int lignes;
    if (pdf) {
      final bytes = await JournalExport.toPdf(
        parcelles: journal.parcelles,
        traitements: journal.traitements,
        versionDonnees: scope.dataset.updatedAt,
      );
      file = File('${directory.path}/phytia-carnet-$stamp.pdf');
      await file.writeAsBytes(bytes, flush: true);
      lignes = journal.traitements.length;
    } else {
      final csv = JournalExport.toCsv(
        parcelles: journal.parcelles,
        traitements: journal.traitements,
      );
      file = File('${directory.path}/phytia-carnet-$stamp.csv');
      await file.writeAsString(csv, flush: true);
      lignes = journal.traitements.length;
    }

    if (!context.mounted) return;
    await _confirmer(context, file.path, lignes, 'Export terminé');
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Export impossible : $error')),
    );
  }
}

/// Export « registre 2027 » : intitulés de la notice, une ligne par produit.
/// Signale les mentions manquantes sans bloquer l'export.
Future<void> exportRegistre(BuildContext context, {required bool json}) async {
  final scope = PhytiaScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final journal = scope.journal;

  if (journal.traitements.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Aucun traitement à exporter.')),
    );
    return;
  }

  final manquants = <String, int>{};
  for (final traitement in journal.traitements) {
    for (final champ in RegistreExport.champsManquants(traitement)) {
      manquants[champ] = (manquants[champ] ?? 0) + 1;
    }
  }

  if (manquants.isNotEmpty && context.mounted) {
    final continuer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mentions manquantes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le registre doit contenir ces mentions. Elles manquent sur :',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            for (final entree in manquants.entries)
              Text(
                '· ${entree.key} — ${entree.value} enregistrement(s)',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            const SizedBox(height: 10),
            Text(
              'Vous pouvez exporter quand même : complétez les fiches ensuite.',
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exporter quand même'),
          ),
        ],
      ),
    );
    if (continuer != true) return;
  }

  try {
    final directory = await _exportDirectory();
    final parcelles = {for (final p in journal.parcelles) p.id: p.nom};
    final stamp = _stamp();

    late final File file;
    if (json) {
      final contenu = RegistreExport.toJson(
        journal.traitements,
        parcelles: parcelles,
      );
      file = File('${directory.path}/phytia-registre-$stamp.json');
      await file.writeAsString(contenu, flush: true);
    } else {
      final contenu = RegistreExport.toCsv(
        journal.traitements,
        parcelles: parcelles,
      );
      file = File('${directory.path}/phytia-registre-$stamp.csv');
      await file.writeAsString(contenu, flush: true);
    }

    if (!context.mounted) return;
    await _confirmer(
      context,
      file.path,
      journal.traitements.length,
      'Registre exporté',
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Export impossible : $error')),
    );
  }
}

Future<void> _confirmer(
  BuildContext context,
  String path,
  int lignes,
  String titre,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$lignes ligne(s) exportée(s).'),
          const SizedBox(height: 10),
          SelectableText(path, style: const TextStyle(fontSize: 12)),
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
}

String _stamp() {
  final now = DateTime.now();
  final mois = now.month.toString().padLeft(2, '0');
  final jour = now.day.toString().padLeft(2, '0');
  return '${now.year}-$mois-$jour';
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
