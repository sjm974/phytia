import 'package:flutter/material.dart';

import '../../data/journal_export.dart';
import '../../data/journal_models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cible_warning.dart';
import 'parcelle_form.dart';
import 'pickers.dart';
import 'traitement_form.dart';

class ParcelleScreen extends StatelessWidget {
  const ParcelleScreen({super.key, required this.parcelleId});

  final String parcelleId;

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final journal = scope.journal;

    return AnimatedBuilder(
      animation: journal,
      builder: (context, _) {
        final parcelle = journal.parcelle(parcelleId);
        if (parcelle == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.map_outlined,
              title: 'Parcelle supprimée',
              message: 'Cette parcelle n\'existe plus.',
            ),
          );
        }
        final traitements = journal.traitementsFor(parcelleId);

        return Scaffold(
          appBar: AppBar(
            title: Text(parcelle.nom),
            actions: [
              IconButton(
                tooltip: 'Modifier la parcelle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ParcelleFormScreen(initial: parcelle),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Supprimer la parcelle',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    _confirmDelete(context, parcelle, traitements.length),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            children: [
              _Header(parcelle: parcelle, count: traitements.length),
              const SectionHeader(
                'Traitements',
                padding: EdgeInsets.fromLTRB(0, 22, 0, 8),
              ),
              if (traitements.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Aucun traitement enregistré. Le premier sera horodaté et '
                    'sa date de récolte calculée automatiquement.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (final t in traitements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TraitementTile(
                      traitement: t,
                      taille: journal.interventionDe(t).length,
                      retrait:
                          scope.dataset.product(t.amm)?.isWithdrawn ?? false,
                      onTap: () => _showSheet(context, t, parcelle.nom),
                    ),
                  ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TraitementFormScreen(parcelleId: parcelle.id),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Traitement'),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Parcelle parcelle,
    int count,
  ) async {
    final scope = PhytiaScope.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la parcelle ?'),
        content: Text(
          '« ${parcelle.nom} » et ses $count traitement(s) seront supprimés '
          'définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    scope.journal.deleteParcelle(parcelle.id);
    navigator.pop();
  }

  Future<void> _showSheet(
    BuildContext context,
    Traitement traitement,
    String parcelleNom,
  ) async {
    final scope = PhytiaScope.of(context);
    final navigator = Navigator.of(context);
    // Le contexte de la feuille est détruit au pop : on garde celui de l'écran.
    final pageContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                traitement.produit,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$parcelleNom · ${frDate(traitement.date)} · AMM ${traitement.amm}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _ajouterAuMelange(pageContext, traitement);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Ajouter un produit au mélange'),
                ),
              ),
              const SizedBox(height: 14),
              _row('Cible', traitement.cible),
              _row('Dose', traitement.doseLabel),
              _row('Surface traitée', formatM2(traitement.surfaceTraiteeM2)),
              _row('Quantité à prélever', JournalExport.quantite(traitement)),
              _row('Volume de bouillie', _volume(traitement)),
              _row('Heures', traitement.heureLabel),
              _row('Délai de rentrée', traitement.rentreeLabel),
              _row('SIRET', traitement.siret),
              _row('Mode de conduite', libelleMode(traitement.modeConduite)),
              _row('Position', traitement.positionLabel),
              _row('Stade BBCH', traitement.stadeBbch),
              _row(
                'Délai avant récolte',
                traitement.darJours == null ? '' : '${traitement.darJours} j',
              ),
              _row(
                'Récolte possible',
                traitement.recoltePossibleLe == null
                    ? ''
                    : frDate(traitement.recoltePossibleLe!),
              ),
              _row('Opérateur', traitement.operateur),
              if (traitement.note.isNotEmpty) _row('Note', traitement.note),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => TraitementFormScreen(
                              parcelleId: traitement.parcelleId,
                              existant: traitement,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: 'Supprimer',
                    onPressed: () {
                      scope.journal.deleteTraitement(traitement.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Un mélange fait une ligne par produit, reliées par le même '
                'identifiant d\'intervention. Chaque produit garde son AMM et '
                'son DAR ; la compatibilité physique n\'est jamais garantie par '
                'l\'AMM — faites un test en bidon.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Color(0xFF8A4B00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ajoute un second produit au même passage : deux lignes, un identifiant
  /// d'intervention commun.
  Future<void> _ajouterAuMelange(BuildContext context, Traitement base) async {
    final produit = await pickProduct(context);
    if (produit == null || !context.mounted) return;

    final scope = PhytiaScope.of(context);
    final data = scope.dataset;

    // On part de l'usage du catalogue propre à ce second produit : sa cible
    // peut être différente de celle du premier.
    var cible = base.cible;
    var dose = '';
    var unite = '';
    var dar = '';
    final usages = data
        .usagesForProduct(produit.amm, includeWithdrawn: false)
        .where((u) => u.culture == base.culture)
        .toList();
    if (usages.isNotEmpty) {
      cible = usages.first.targetLabel;
      dose = usages.first.dose;
      unite = usages.first.doseUnit;
      dar = usages.first.darDays;
    }

    final cibleCtrl = TextEditingController(text: cible);
    final doseCtrl = TextEditingController(text: dose);
    final uniteCtrl = TextEditingController(text: unite);
    final darCtrl = TextEditingController(text: dar);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(produit.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cibleCtrl,
                onChanged: (_) => setLocal(() {}),
                decoration: const InputDecoration(
                  labelText: 'Cible',
                  helperText: 'Peut différer de celle du premier produit',
                ),
              ),
              CibleWarning(
                amm: produit.amm,
                culture: base.culture,
                cible: cibleCtrl.text,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: doseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Dose'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: uniteCtrl,
                      decoration: const InputDecoration(labelText: 'Unité'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: darCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'DAR',
                  suffixText: 'jours',
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
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (confirme != true) {
      cibleCtrl.dispose();
      doseCtrl.dispose();
      uniteCtrl.dispose();
      darCtrl.dispose();
      return;
    }
    scope.journal.addTraitement(
      Traitement(
        id: scope.journal.newTraitementId(),
        interventionId: base.intervention,
        parcelleId: base.parcelleId,
        date: base.date,
        amm: produit.amm,
        produit: produit.name,
        culture: base.culture,
        cible: cibleCtrl.text.trim(),
        dose: doseCtrl.text.trim(),
        doseUnite: uniteCtrl.text.trim(),
        darJours: int.tryParse(darCtrl.text.trim()),
        surfaceTraiteeM2: base.surfaceTraiteeM2,
        stadeBbch: base.stadeBbch,
        operateur: base.operateur,
        note: base.note,
        modeConduite: base.modeConduite,
        latitude: base.latitude,
        longitude: base.longitude,
        heureDebut: base.heureDebut,
        heureFin: base.heureFin,
        volumeBouillie: base.volumeBouillie,
      ),
    );
    doseCtrl.dispose();
    uniteCtrl.dispose();
    darCtrl.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produit.name} ajouté au mélange'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _volume(Traitement traitement) {
    final volume = traitement.volumeLabel;
    if (volume.isEmpty) return '';
    final perHa = traitement.volumeParHectare;
    if (perHa == null) return volume;
    return '$volume (soit ${formatLitres(perHa)} L/ha)';
  }

  Widget _row(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A70)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: phytiaDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.parcelle, required this.count});

  final Parcelle parcelle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final details = [
      if (parcelle.surfaceM2 != null) formatM2(parcelle.surfaceM2),
      '$count traitement${count > 1 ? 's' : ''}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parcelle.culture.isNotEmpty)
            Text(
              parcelle.culture,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: phytiaGreen,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            details,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (parcelle.modeConduite.isNotEmpty || parcelle.aPosition) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (parcelle.modeConduite.isNotEmpty)
                  Pill(
                    libelleMode(parcelle.modeConduite),
                    icon: Icons.eco_outlined,
                  ),
                if (parcelle.aPosition)
                  const Pill('Position GPS', icon: Icons.my_location),
              ],
            ),
          ],
          if (parcelle.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              parcelle.note,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TraitementTile extends StatelessWidget {
  const _TraitementTile({
    required this.traitement,
    required this.taille,
    required this.retrait,
    required this.onTap,
  });

  final Traitement traitement;
  final int taille;
  final bool retrait;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recolte = traitement.recoltePossibleLe;
    final enAttente = recolte != null && recolte.isAfter(DateTime.now());

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      traitement.produit,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: phytiaDark,
                      ),
                    ),
                  ),
                  Text(
                    frDate(traitement.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [
                  traitement.cible,
                  traitement.doseLabel,
                  formatM2(traitement.surfaceTraiteeM2),
                  JournalExport.quantite(traitement),
                ].where((e) => e.isNotEmpty).join(' · '),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (taille > 1)
                    Pill(
                      'Mélange de $taille produits',
                      icon: Icons.science_outlined,
                    ),
                  if (retrait)
                    const Pill(
                      'Produit retiré',
                      icon: Icons.block,
                      color: Color(0xFFB3261E),
                      background: Color(0xFFFDECEA),
                    ),
                  if (recolte != null)
                    enAttente
                        ? Pill(
                            'Récolte dès le ${frDate(recolte)}',
                            icon: Icons.schedule,
                            color: const Color(0xFF8A4B00),
                            background: const Color(0xFFFFF1D6),
                          )
                        : Pill(
                            'Récolte possible',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF1E6B45),
                            background: const Color(0xFFE4F1E7),
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
