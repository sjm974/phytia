import 'package:flutter/material.dart';

import '../../data/journal_export.dart';
import '../../data/journal_models.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import 'pickers.dart';

/// Saisie d'un traitement, éventuellement préremplie depuis une fiche produit.
class TraitementFormScreen extends StatefulWidget {
  const TraitementFormScreen({
    super.key,
    required this.parcelleId,
    this.produit,
    this.usage,
    this.existant,
  });

  final String parcelleId;
  final Product? produit;
  final Usage? usage;
  final Traitement? existant;

  @override
  State<TraitementFormScreen> createState() => _TraitementFormScreenState();
}

class _TraitementFormScreenState extends State<TraitementFormScreen> {
  late final TextEditingController _cible;
  late final TextEditingController _dose;
  late final TextEditingController _unite;
  late final TextEditingController _surface;
  late final TextEditingController _bbch;
  late final TextEditingController _dar;
  late final TextEditingController _operateur;
  late final TextEditingController _note;

  late DateTime _date;
  String _amm = '';
  String _nomProduit = '';
  String _culture = '';
  double? _surfaceParcelle;
  bool _initialise = false;

  @override
  void initState() {
    super.initState();
    final existant = widget.existant;
    _date = existant?.date ?? DateTime.now();
    _amm = existant?.amm ?? widget.produit?.amm ?? '';
    _nomProduit = existant?.produit ?? widget.produit?.name ?? '';

    final usage = widget.usage;
    _cible = TextEditingController(
      text: existant?.cible ?? usage?.targetLabel ?? '',
    );
    _dose = TextEditingController(text: existant?.dose ?? usage?.dose ?? '');
    _unite = TextEditingController(
      text: existant?.doseUnite ?? usage?.doseUnit ?? '',
    );
    _surface = TextEditingController();
    _bbch = TextEditingController(text: existant?.stadeBbch ?? _bbchDe(usage));
    _dar = TextEditingController(
      text: existant?.darJours?.toString() ?? usage?.darDays ?? '',
    );
    _operateur = TextEditingController(text: existant?.operateur ?? '');
    _note = TextEditingController(text: existant?.note ?? '');
  }

  /// Quantité à prélever d'après la dose et la surface traitée.
  String get _quantite {
    final surface = double.tryParse(_surface.text.replaceAll(',', '.').trim());
    if (surface == null) return '';
    return doseQuantite(_dose.text, _unite.text, surface);
  }

  static String _bbchDe(Usage? usage) {
    if (usage == null) return '';
    final min = usage.bbchMin;
    final max = usage.bbchMax;
    if (min.isNotEmpty && max.isNotEmpty) return '$min-$max';
    if (max.isNotEmpty) return '≤ $max';
    return min;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialise) return;
    _initialise = true;
    final scope = PhytiaScope.of(context);
    final parcelle = scope.journal.parcelle(widget.parcelleId);
    _culture = parcelle?.culture ?? '';
    _surfaceParcelle = parcelle?.surfaceM2;
    _surface.text = widget.existant?.surfaceTraiteeM2 == null
        ? (_surfaceParcelle?.toStringAsFixed(2).replaceAll('.', ',') ?? '')
        : widget.existant!.surfaceTraiteeM2!
              .toStringAsFixed(2)
              .replaceAll('.', ',');
  }

  @override
  void dispose() {
    for (final controller in [
      _cible,
      _dose,
      _unite,
      _surface,
      _bbch,
      _dar,
      _operateur,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirProduit() async {
    final produit = await pickProduct(context);
    if (produit == null || !mounted) return;
    setState(() {
      _amm = produit.amm;
      _nomProduit = produit.name;
    });
    _prefillDepuisCatalogue(produit);
  }

  /// Complète les champs vides avec l'usage correspondant du catalogue.
  void _prefillDepuisCatalogue(Product produit) {
    if (_culture.isEmpty) return;
    final data = PhytiaScope.of(context).dataset;
    final usages = data
        .usagesForProduct(produit.amm, includeWithdrawn: false)
        .where((u) => u.culture == _culture);
    if (usages.isEmpty) return;

    final cible = _cible.text.trim().toLowerCase();
    Usage? choix;
    for (final u in usages) {
      if (cible.isNotEmpty && u.target.toLowerCase().contains(cible)) {
        choix = u;
        break;
      }
    }
    choix ??= usages.first;

    setState(() {
      if (_cible.text.trim().isEmpty) _cible.text = choix!.targetLabel;
      if (_dose.text.trim().isEmpty) _dose.text = choix!.dose;
      if (_unite.text.trim().isEmpty) _unite.text = choix!.doseUnit;
      if (_bbch.text.trim().isEmpty) _bbch.text = _bbchDe(choix);
      if (_dar.text.trim().isEmpty) _dar.text = choix!.darDays;
    });
  }

  Future<void> _enregistrer() async {
    if (_nomProduit.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez le produit appliqué.')),
      );
      return;
    }
    final scope = PhytiaScope.of(context);
    final journal = scope.journal;

    final traitement = Traitement(
      id: widget.existant?.id ?? journal.newTraitementId(),
      parcelleId: widget.parcelleId,
      date: _date,
      amm: _amm,
      produit: _nomProduit.trim(),
      culture: _culture,
      cible: _cible.text.trim(),
      dose: _dose.text.trim(),
      doseUnite: _unite.text.trim(),
      surfaceTraiteeM2: double.tryParse(_surface.text.replaceAll(',', '.')),
      stadeBbch: _bbch.text.trim(),
      darJours: int.tryParse(_dar.text.trim()),
      operateur: _operateur.text.trim(),
      note: _note.text.trim(),
    );

    if (widget.existant == null) {
      journal.addTraitement(traitement);
    } else {
      journal.updateTraitement(traitement);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parcelle = PhytiaScope.of(context).journal
        .parcelle(widget.parcelleId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existant == null
              ? 'Nouveau traitement'
              : 'Modifier le traitement',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            parcelle == null
                ? ''
                : '${parcelle.nom} · ${_culture.isEmpty ? 'culture non précisée' : _culture}',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.event_outlined,
            label: 'Date du traitement',
            value: frDate(_date),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 10),
          _Tile(
            icon: Icons.science_outlined,
            label: 'Produit',
            value: _nomProduit.isEmpty
                ? 'Choisir un produit'
                : '$_nomProduit${_amm.isEmpty ? '' : ' · AMM $_amm'}',
            onTap: _choisirProduit,
            highlight: _nomProduit.isEmpty,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _cible,
            decoration: const InputDecoration(
              labelText: 'Cible (maladie, ravageur, adventice)',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _dose,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Dose'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _unite,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Unité',
                    hintText: 'L/ha ou mL/10 m²',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _surface,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Surface traitée (m²)',
                    suffixText: 'm²',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _bbch,
                  decoration: const InputDecoration(
                    labelText: 'Stade BBCH',
                    hintText: '12-77',
                  ),
                ),
              ),
            ],
          ),
          if (_quantite.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: phytiaGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quantité à prélever : $_quantite',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: phytiaDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dar,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'DAR',
                    suffixText: 'jours',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _operateur,
                  decoration: const InputDecoration(
                    labelText: 'Opérateur',
                    hintText: 'Nom, certiphyto',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              hintText: 'Conditions, matériel, observations…',
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _enregistrer,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer le traitement'),
          ),
          const SizedBox(height: 10),
          Text(
            'Le DAR est recopié du catalogue quand vous partez d\'une fiche '
            'produit ; vérifiez-le sur l\'étiquette. La date de récolte '
            'possible est calculée automatiquement.',
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight ? phytiaGreen : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: highlight ? phytiaGreen : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: phytiaDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
