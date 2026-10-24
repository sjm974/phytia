import 'package:flutter/material.dart';

import '../../data/journal_models.dart';
import '../../data/scope.dart';
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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nom = TextEditingController(text: initial?.nom ?? '');
    _surface = TextEditingController(
      text: initial?.surfaceM2 == null
          ? ''
          : initial!.surfaceM2!.toStringAsFixed(2).replaceAll('.', ','),
    );
    _note = TextEditingController(text: initial?.note ?? '');
    _culture = initial?.culture ?? '';
  }

  @override
  void dispose() {
    _nom.dispose();
    _surface.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donnez un nom à la parcelle.')),
      );
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
      );
    } else {
      scope.journal.updateParcelle(
        widget.initial!.copyWith(
          nom: nom,
          culture: _culture,
          surfaceM2: surface,
          note: _note.text.trim(),
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              hintText: 'Les Hauts, la Vigne du Puits…',
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final culture = await pickCulture(context);
                if (culture != null) setState(() => _culture = culture);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.agriculture_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _culture.isEmpty ? 'Culture (optionnel)' : _culture,
                        style: TextStyle(
                          fontSize: 14,
                          color: _culture.isEmpty
                              ? scheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                    if (_culture.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer',
                        onPressed: () => setState(() => _culture = ''),
                        icon: const Icon(Icons.close, size: 18),
                      )
                    else
                      const Icon(Icons.chevron_right, color: Colors.black26),
                  ],
                ),
              ),
            ),
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
          const Text(
            'La culture sert à préremplir les traitements et à retrouver les '
            'produits homologués.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7A70)),
          ),
        ],
      ),
    );
  }
}
