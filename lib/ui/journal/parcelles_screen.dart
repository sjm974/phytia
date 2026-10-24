import 'package:flutter/material.dart';

import '../../data/journal_export.dart';
import '../../data/journal_models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'export_helper.dart';
import 'parcelle_form.dart';
import 'parcelle_screen.dart';

class ParcellesScreen extends StatelessWidget {
  const ParcellesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final journal = scope.journal;

    return AnimatedBuilder(
      animation: journal,
      builder: (context, _) {
        final parcelles = journal.parcelles;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes parcelles'),
            actions: [
              PopupMenuButton<bool>(
                tooltip: 'Exporter le carnet',
                icon: const Icon(Icons.ios_share),
                onSelected: (pdf) => exportJournal(context, pdf: pdf),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: false, child: Text('Exporter en CSV')),
                  PopupMenuItem(value: true, child: Text('Exporter en PDF')),
                ],
              ),
            ],
          ),
          body: parcelles.isEmpty
              ? EmptyState(
                  icon: Icons.map_outlined,
                  title: 'Aucune parcelle',
                  message:
                      'Créez vos parcelles pour enregistrer les traitements, '
                      'suivre les délais avant récolte et sortir votre carnet.',
                  action: FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une parcelle'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    for (final parcelle in parcelles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ParcelleTile(
                          parcelle: parcelle,
                          traitements: journal.traitementsFor(parcelle.id),
                        ),
                      ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Parcelle'),
          ),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ParcelleFormScreen()));
  }
}

class _ParcelleTile extends StatelessWidget {
  const _ParcelleTile({required this.parcelle, required this.traitements});

  final Parcelle parcelle;
  final List<Traitement> traitements;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = [
      if (parcelle.culture.isNotEmpty) parcelle.culture,
      if (parcelle.surfaceM2 != null) formatM2(parcelle.surfaceM2),
      '${traitements.length} traitement${traitements.length > 1 ? 's' : ''}',
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ParcelleScreen(parcelleId: parcelle.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.terrain, color: phytiaGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcelle.nom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: phytiaDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
