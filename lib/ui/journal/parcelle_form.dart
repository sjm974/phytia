import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/journal_models.dart';
import '../../data/scope.dart';
import '../theme.dart';
import 'pickers.dart';

/// Création / modification d'une parcelle.
class ParcelleFormScreen extends StatefulWidget {
  const ParcelleFormScreen({super.key, this.initial});

  final Parcelle? initial;

  @override
  State<ParcelleFormScreen> createState() => _ParcelleFormScreenState();
}

class _ParcelleFormScreenState extends State<ParcelleFormScreen> {
  late final TextEditingController _nom;
  late final TextEditingController _surface;
  late final TextEditingController _note;
  late String _culture;
  late String _mode;
  double? _latitude;
  double? _longitude;
  bool _localisation = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nom = TextEditingController(text: initial?.nom ?? '');
    _surface = TextEditingController(
      text: initial?.surfaceM2 == null
          ? ''
          : initial!.surfaceM2!.toStringAsFixed(0),
    );
    _note = TextEditingController(text: initial?.note ?? '');
    _culture = initial?.culture ?? '';
    _mode = initial?.modeConduite ?? '';
    _latitude = initial?.latitude;
    _longitude = initial?.longitude;
  }

  @override
  void dispose() {
    _nom.dispose();
    _surface.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _localiser() async {
    setState(() => _localisation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _avertir(
          'Position refusée. Autorisez la localisation dans les réglages du système.',
        );
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _avertir(
          'Activez la localisation du système pour relever la position.',
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (error) {
      _avertir('Position indisponible : $error');
    } finally {
      if (mounted) setState(() => _localisation = false);
    }
  }

  void _avertir(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      _avertir('Donnez un nom à la parcelle.');
      return;
    }
    final scope = PhytiaScope.of(context);
    final surface = double.tryParse(_surface.text.replaceAll(',', '.'));

    if (widget.initial == null) {
      scope.journal.addParcelle(
        nom: nom,
        culture: _culture,
        surfaceM2: surface,
        note: _note.text.trim(),
        modeConduite: _mode,
        latitude: _latitude,
        longitude: _longitude,
      );
    } else {
      scope.journal.updateParcelle(
        widget.initial!.copyWith(
          nom: nom,
          culture: _culture,
          surfaceM2: surface,
          note: _note.text.trim(),
          modeConduite: _mode,
          latitude: _latitude,
          longitude: _longitude,
          effacerPosition: _latitude == null || _longitude == null,
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final position = _latitude == null || _longitude == null
        ? ''
        : '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Nouvelle parcelle' : 'Modifier'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _nom,
            autofocus: widget.initial == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom de la parcelle',
              hintText: 'Les Hauts, le Verger…',
            ),
          ),
          const SizedBox(height: 14),
          _ChoiceTile(
            icon: Icons.agriculture_outlined,
            label: 'Culture',
            value: _culture,
            hint: 'Choisir une culture',
            onTap: () async {
              final culture = await pickCulture(context);
              if (culture != null) setState(() => _culture = culture);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _surface,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Surface (m²)',
              suffixText: 'm²',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Mode de conduite',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in const [
                (modeBiologique, 'Agriculture biologique'),
                (modeConversion, 'Conversion'),
                (modeConventionnel, 'Conventionnel'),
              ])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: _mode == entry.$1,
                  onSelected: (selected) =>
                      setState(() => _mode = selected ? entry.$1 : ''),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, size: 18, color: phytiaGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Position de la parcelle',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (position.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer',
                        onPressed: () => setState(() {
                          _latitude = null;
                          _longitude = null;
                        }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
                Text(
                  position.isEmpty
                      ? 'Aucune position enregistrée. Le relevé se fait sur place, appareil à la main.'
                      : position,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _localisation ? null : _localiser,
                    icon: _localisation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.gps_fixed, size: 18),
                    label: Text(
                      _localisation ? 'Relevé en cours…' : 'Me localiser',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              hintText: 'Sol argileux, bord de cours d\'eau…',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: 12),
          Text(
            'La culture, le mode de conduite et la position sont recopiés dans '
            'chaque traitement : le registre reste lisible même si la parcelle '
            'change ensuite.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isEmpty ? scheme.onSurfaceVariant : null,
                  ),
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
