import 'package:flutter/material.dart';

import '../data/scope.dart';
import '../data/update_config.dart';
import '../data/updater.dart';
import 'theme.dart';
import 'widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1E7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.eco, size: 34, color: phytiaGreen),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phytia',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: phytiaDark,
                    ),
                  ),
                  Text(
                    'Version 0.1.0',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Phytia indique le produit phytosanitaire homologué pour une culture, '
            'une maladie ou un ravageur, avec sa dose, son délai avant récolte et ses '
            'zones non traitées. Les données proviennent du catalogue officiel E-Phy '
            'de l\'Anses et sont embarquées dans l\'application : elle fonctionne sans '
            'réseau, au champ comme à la cabane.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SectionHeader(
            'Catalogue embarqué',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
          ),
          _InfoCard(
            rows: [
              ('Source', 'Anses — E-Phy'),
              ('Mise à jour', data.updatedAtLabel),
              (
                'Usages',
                '${data.usageCount} dont ${data.authorizedUsageCount} autorisés',
              ),
              ('Produits', '${data.productCount}'),
              ('Cultures', '${data.cultures.length}'),
              ('Cibles', '${data.targetCount}'),
            ],
          ),
          const SectionHeader(
            'Mise à jour',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
          ),
          const _UpdateCard(),
          const SectionHeader(
            'Avertissement',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0D9A8)),
            ),
            child: const Text(
              'Les données d\'E-Phy ne sont pas opposables : seules les décisions publiées '
              'au registre électronique des autorisations de mise sur le marché font foi. '
              'Phytia ne remplace ni l\'étiquette du produit, ni le respect de la '
              'réglementation (certiphyto, arrêtés préfectoraux, zones protégées).',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF6B4A00),
              ),
            ),
          ),
          const SectionHeader(
            'Vos données',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 8),
          ),
          Text(
            'Votre stock et vos favoris sont enregistrés uniquement sur cet appareil. '
            'Aucun compte, aucun envoi, aucune publicité.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          SourceNote(date: data.updatedAtLabel),
          const SizedBox(height: 8),
          Text(
            'Licence Ouverte / Open Licence (Etalab). Réutilisation des données avec '
            'mention de la source « Données E-Phy — Anses ».',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatefulWidget {
  const _UpdateCard();

  @override
  State<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<_UpdateCard> {
  bool _busy = false;
  double? _progress;
  String? _message;

  Future<void> _check() async {
    final scope = PhytiaScope.of(context);
    final updater = scope.updater;

    if (updater == null) {
      setState(() {
        _message = isDataUpdateConfigured
            ? 'Dossier de données indisponible sur cet appareil.'
            : 'Mises à jour non configurées : renseignez l\'adresse de publication '
                  'dans lib/data/update_config.dart.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _progress = null;
      _message = 'Recherche d\'une mise à jour…';
    });

    try {
      final manifest = await updater.fetchManifest();
      if (!manifest.isNewerThan(scope.dataset.updatedAt)) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message =
              'Catalogue à jour (version ${scope.dataset.updatedAtLabel}).';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _progress = 0;
        _message = 'Téléchargement de la version ${manifest.versionLabel}…';
      });

      final dataset = await updater.install(
        manifest,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      scope.holder.replace(dataset);
      scope.details.reset();

      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _message =
            'Mis à jour : ${manifest.versionLabel} · ${manifest.usageCount} usages.';
      });
    } on DataUpdateException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _message = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _progress = null;
        _message = 'Échec de la mise à jour : $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_sync_outlined,
                size: 18,
                color: phytiaGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catalogue du ${data.updatedAtLabel}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: phytiaDark,
                  ),
                ),
              ),
            ],
          ),
          if (_progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: _progress, minHeight: 6),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(
              _message!,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _check,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_busy ? 'Mise à jour…' : 'Vérifier les mises à jour'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nécessite une connexion internet. Le reste de l\'application '
            'fonctionne hors ligne, y compris après une mise à jour.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: phytiaDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
