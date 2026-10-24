import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/data_files.dart';
import 'data/dataset.dart';
import 'data/details.dart';
import 'data/holder.dart';
import 'data/scope.dart';
import 'data/store.dart';
import 'data/update_config.dart';
import 'data/updater.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhytiaBootstrap());
}

class PhytiaBootstrap extends StatefulWidget {
  const PhytiaBootstrap({super.key});

  @override
  State<PhytiaBootstrap> createState() => _PhytiaBootstrapState();
}

class _BootData {
  _BootData({
    required this.holder,
    required this.store,
    required this.details,
    required this.updater,
  });

  final DatasetHolder holder;
  final UserStore store;
  final DetailsRepository details;
  final DataUpdater? updater;
}

class _PhytiaBootstrapState extends State<PhytiaBootstrap> {
  late final Future<_BootData> _future = _load();

  Future<_BootData> _load() async {
    Directory? dataDir;
    try {
      final support = await getApplicationSupportDirectory();
      dataDir = Directory('${support.path}/data');
    } catch (error) {
      debugPrint('Phytia: dossier de données indisponible ($error)');
    }

    final files = DataFiles(bundle: rootBundle, cacheDir: dataDir);

    PhytiaDataset dataset;
    try {
      dataset = PhytiaDataset.fromBytes(await files.core());
    } catch (error) {
      debugPrint('Phytia: catalogue en cache illisible ($error)');
      files.clearCache();
      dataset = PhytiaDataset.fromBytes(await files.coreAsset());
    }

    final store = await UserStore.load();
    final details = DetailsRepository(files.details);
    final updater = (dataDir != null && isDataUpdateConfigured)
        ? DataUpdater(baseUrl: kDataReleaseBase, directory: dataDir)
        : null;

    return _BootData(
      holder: DatasetHolder(dataset),
      store: store,
      details: details,
      updater: updater,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: buildPhytiaTheme(),
            debugShowCheckedModeBanner: false,
            home: _StartupError(error: snapshot.error!),
          );
        }
        final boot = snapshot.data;
        if (boot == null) {
          return MaterialApp(
            theme: buildPhytiaTheme(),
            debugShowCheckedModeBanner: false,
            home: const _SplashScreen(),
          );
        }
        return AnimatedBuilder(
          animation: boot.holder,
          builder: (context, _) => PhytiaScope(
            dataset: boot.holder.dataset,
            holder: boot.holder,
            store: boot.store,
            details: boot.details,
            updater: boot.updater,
            child: const PhytiaApp(),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: phytiaGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.eco, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Phytia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Le bon produit, sur la bonne culture',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chargement du catalogue E-Phy…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger le catalogue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
