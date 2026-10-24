import 'package:flutter/material.dart';

import '../../data/journal_export.dart';
import '../../data/journal_models.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import 'cible_warning.dart';
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
  late final TextEditingController _volumeHa;

  late DateTime _date;
  String _amm = '';
  String _nomProduit = '';
  String _culture = '';
  String _mode = '';
  String _heureDebut = '';
  String _heureFin = '';
  double? _latitude;
  double? _longitude;
  double? _surfaceParcelle;
  bool _initialise = false;

  @override
  void initState() {
    super.initState();
    final existant = widget.existant;
    _date = existant?.date ?? DateTime.now();
    _amm = existant?.amm ?? widget.produit?.amm ?? '';
    _nomProduit = existant?.produit ?? widget.produit?.name ?? '';
    _mode = existant?.modeConduite ?? '';
    _latitude = existant?.latitude;
    _longitude = existant?.longitude;
    _heureDebut = existant?.heureDebut ?? '';
    _heureFin = existant?.heureFin ?? '';

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
    _volumeHa = TextEditingController();
  }

  /// Quantité à prélever d'après la dose et la surface traitée.
  String get _quantite {
    final surface = double.tryParse(_surface.text.replaceAll(',', '.').trim());
    if (surface == null) return '';
    return doseQuantite(
      _dose.text,
      _unite.text,
      surface,
      volumeBouillie: _volumeTotal,
    );
  }

  /// Volume total de bouillie pour la surface traitée, en litres.
  double? get _volumeTotal {
    final perHa = double.tryParse(_volumeHa.text.replaceAll(',', '.').trim());
    final surface = double.tryParse(_surface.text.replaceAll(',', '.').trim());
    if (perHa == null || surface == null || surface <= 0) return null;
    return volumeTotalLitres(perHa, surface);
  }

  String get _volumeTotalLabel {
    final total = _volumeTotal;
    if (total == null) return '';
    return '${formatLitres(total)} L de bouillie au total';
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
    if (_mode.isEmpty) _mode = parcelle?.modeConduite ?? '';
    if (_latitude == null) {
      _latitude = parcelle?.latitude;
      _longitude = parcelle?.longitude;
    }
    _surface.text = widget.existant?.surfaceTraiteeM2 == null
        ? (_surfaceParcelle?.toStringAsFixed(0) ?? '')
        : widget.existant!.surfaceTraiteeM2!.toStringAsFixed(0);
    final total = widget.existant?.volumeBouillie;
    final surface = double.tryParse(_surface.text.replaceAll(',', '.'));
    if (total != null && surface != null && surface > 0) {
      _volumeHa.text = formatLitres(total / surface * 10000);
    }
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
      _volumeHa,
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

  Future<void> _choisirHeure({required bool debut}) async {
    final actuel = debut ? _heureDebut : _heureFin;
    final initial = actuel.contains(':')
        ? TimeOfDay(
            hour: int.parse(actuel.split(':').first),
            minute: int.parse(actuel.split(':').last),
          )
        : TimeOfDay.now();
    final choix = await showTimePicker(context: context, initialTime: initial);
    if (choix == null) return;
    final heures = choix.hour.toString().padLeft(2, '0');
    final minutes = choix.minute.toString().padLeft(2, '0');
    setState(() {
      if (debut) {
        _heureDebut = '$heures:$minutes';
      } else {
        _heureFin = '$heures:$minutes';
      }
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
      modeConduite: _mode,
      latitude: _latitude,
      longitude: _longitude,
      heureDebut: _heureDebut,
      heureFin: _heureFin,
      volumeBouillie: _volumeTotal,
      interventionId: widget.existant?.interventionId ?? '',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.play_arrow_outlined,
                  label: 'Début',
                  value: _heureDebut.isEmpty ? '--:--' : _heureDebut,
                  onTap: () => _choisirHeure(debut: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(
                  icon: Icons.stop_outlined,
                  label: 'Fin',
                  value: _heureFin.isEmpty ? '--:--' : _heureFin,
                  onTap: () => _choisirHeure(debut: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Cible (maladie, ravageur, adventice)',
            ),
          ),
          CibleWarning(amm: _amm, culture: _culture, cible: _cible.text),
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
            _Info(
              icon: Icons.calculate_outlined,
              text: 'Quantité à prélever : $_quantite',
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _volumeHa,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Volume de bouillie (L/ha)',
              suffixText: 'L/ha',
              helperText: _volumeTotalLabel.isEmpty ? null : _volumeTotalLabel,
            ),
          ),
          if (_volumeHa.text.trim().isEmpty && _culture.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _volumeHa.text = volumeHaIndicatif(_culture).toString(),
                ),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: Text(
                  'Utiliser ${volumeHaIndicatif(_culture)} L/ha (ordre de grandeur)',
                ),
              ),
            ),
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
          const SizedBox(height: 16),
          _Info(
            icon: Icons.eco_outlined,
            text: _mode.isEmpty
                ? 'Mode de conduite non renseigné sur la parcelle.'
                : 'Mode de conduite : ${libelleMode(_mode)}',
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 8),
            _Info(
              icon: Icons.my_location,
              text:
                  'Position : ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
            ),
          ],
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

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F1E7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: phytiaGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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
