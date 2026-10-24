import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Données personnelles de l'utilisateur : stock, favoris, cultures récentes.
/// Tout reste sur l'appareil, dans un simple fichier JSON.
class UserStore extends ChangeNotifier {
  UserStore._(this._file, this._stock, this._favorites, this._recentCultures);

  final File? _file;
  final Set<String> _stock;
  final Set<String> _favorites;
  final List<String> _recentCultures;

  static Future<UserStore> load() async {
    File? file;
    Set<String> stock = <String>{};
    Set<String> favorites = <String>{};
    List<String> recent = <String>[];
    try {
      final dir = await getApplicationSupportDirectory();
      file = File('${dir.path}${Platform.pathSeparator}phytia_user.json');
      if (file.existsSync()) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        stock = (json['stock'] as List?)?.cast<String>().toSet() ?? <String>{};
        favorites =
            (json['favoris'] as List?)?.cast<String>().toSet() ?? <String>{};
        recent =
            (json['recent'] as List?)?.cast<String>().toList() ?? <String>[];
      }
    } catch (error) {
      debugPrint('Phytia: stockage local indisponible ($error)');
    }
    return UserStore._(file, stock, favorites, recent);
  }

  List<String> get stock => _stock.toList();
  List<String> get favorites => _favorites.toList();
  List<String> get recentCultures => List.unmodifiable(_recentCultures);

  bool inStock(String amm) => _stock.contains(amm);
  bool isFavorite(String amm) => _favorites.contains(amm);
  int get stockCount => _stock.length;
  int get favoriteCount => _favorites.length;

  void toggleStock(String amm) {
    if (!_stock.remove(amm)) _stock.add(amm);
    _persist();
  }

  void toggleFavorite(String amm) {
    if (!_favorites.remove(amm)) _favorites.add(amm);
    _persist();
  }

  void rememberCulture(String culture) {
    _recentCultures.remove(culture);
    _recentCultures.insert(0, culture);
    if (_recentCultures.length > 6) _recentCultures.removeLast();
    _persist();
  }

  void _persist() {
    notifyListeners();
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync(
        jsonEncode({
          'stock': _stock.toList(),
          'favoris': _favorites.toList(),
          'recent': _recentCultures,
        }),
      );
    } catch (error) {
      debugPrint('Phytia: écriture impossible ($error)');
    }
  }
}
