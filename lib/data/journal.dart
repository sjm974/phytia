import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'journal_models.dart';

export 'journal_models.dart';

/// Parcelles et traitements, persistés sur l'appareil dans un fichier JSON.
class JournalStore extends ChangeNotifier {
  JournalStore._(this._file, this._journal);

  final File? _file;
  final Journal _journal;

  static Future<JournalStore> load() async {
    var journal = Journal();
    File? file;
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}phytia_journal.json');
      if (file.existsSync()) {
        journal = Journal.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
      }
    } catch (error) {
      debugPrint('Phytia: carnet indisponible ($error)');
    }
    return JournalStore._(file, journal);
  }

  List<Parcelle> get parcelles => List.unmodifiable(_journal.parcelles);
  List<Traitement> get traitements => List.unmodifiable(_journal.traitements);
  int get traitementCount => _journal.traitements.length;

  Parcelle? parcelle(String id) => _journal.parcelle(id);

  List<Traitement> traitementsFor(String parcelleId) =>
      _journal.traitementsFor(parcelleId);

  List<Traitement> get derniersTraitements => _journal.derniersTraitements;

  String newTraitementId() => Journal.newId();

  Parcelle addParcelle({
    required String nom,
    String culture = '',
    double? surfaceM2,
    String note = '',
  }) {
    final parcelle = _journal.addParcelle(
      nom: nom,
      culture: culture,
      surfaceM2: surfaceM2,
      note: note,
    );
    _persist();
    return parcelle;
  }

  void updateParcelle(Parcelle parcelle) {
    _journal.updateParcelle(parcelle);
    _persist();
  }

  void deleteParcelle(String id) {
    _journal.deleteParcelle(id);
    _persist();
  }

  void addTraitement(Traitement traitement) {
    _journal.addTraitement(traitement);
    _persist();
  }

  void updateTraitement(Traitement traitement) {
    _journal.updateTraitement(traitement);
    _persist();
  }

  void deleteTraitement(String id) {
    _journal.deleteTraitement(id);
    _persist();
  }

  void _persist() {
    notifyListeners();
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync(jsonEncode(_journal.toJson()));
    } catch (error) {
      debugPrint('Phytia: écriture du carnet impossible ($error)');
    }
  }
}
