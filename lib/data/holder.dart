import 'package:flutter/foundation.dart';

import 'dataset.dart';

/// Détient le catalogue en mémoire et permet de le remplacer à chaud après une
/// mise à jour, sans redémarrer l'application.
class DatasetHolder extends ChangeNotifier {
  DatasetHolder(this._dataset);

  PhytiaDataset _dataset;

  PhytiaDataset get dataset => _dataset;

  void replace(PhytiaDataset dataset) {
    if (identical(dataset, _dataset)) return;
    _dataset = dataset;
    notifyListeners();
  }
}
