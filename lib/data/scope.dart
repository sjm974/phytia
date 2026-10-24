import 'package:flutter/widgets.dart';

import 'dataset.dart';
import 'details.dart';
import 'holder.dart';
import 'store.dart';
import 'updater.dart';

/// Donne accès au catalogue et aux données personnelles depuis l'arbre.
class PhytiaScope extends InheritedWidget {
  const PhytiaScope({
    super.key,
    required this.dataset,
    required this.holder,
    required this.store,
    required this.details,
    required this.updater,
    required super.child,
  });

  /// Catalogue courant. C'est cette valeur qui déclenche la reconstruction des
  /// écrans quand une mise à jour est installée.
  final PhytiaDataset dataset;

  final DatasetHolder holder;
  final UserStore store;
  final DetailsRepository details;

  /// Nul quand les mises à jour ne sont pas configurées.
  final DataUpdater? updater;

  static PhytiaScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PhytiaScope>();
    assert(scope != null, 'PhytiaScope est absent de l\'arbre de widgets');
    return scope!;
  }

  @override
  bool updateShouldNotify(PhytiaScope oldWidget) =>
      dataset != oldWidget.dataset ||
      holder != oldWidget.holder ||
      store != oldWidget.store ||
      details != oldWidget.details ||
      updater != oldWidget.updater;
}
