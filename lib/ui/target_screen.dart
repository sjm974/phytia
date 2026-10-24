import 'package:flutter/material.dart';

import '../data/dataset.dart';
import '../data/models.dart';
import '../data/scope.dart';
import 'results_screen.dart';
import 'widgets/common.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({
    super.key,
    required this.culture,
    this.stockOnly = false,
  });

  final String culture;
  final bool stockOnly;

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = PhytiaScope.of(context).dataset;
    final query = normalize(_query.trim());

    final entries = data.targetsForCulture(widget.culture).where((e) {
      if (query.isEmpty) return true;
      return normalize(e.label).contains(query);
    }).toList();

    final grouped = <String, List<TargetEntry>>{};
    for (final e in entries) {
      (grouped[e.typeLabel] ??= <TargetEntry>[]).add(e);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.culture,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Maladie ou ravageur',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: PhytiaSearchField(
              controller: _controller,
              hint: 'Mildiou, pucerons, désherbage…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucune cible trouvée',
                    message: 'Essayez un autre terme ou revenez à la liste des cultures.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      for (final entry in grouped.entries) ...[
                        SectionHeader(
                          entry.key,
                          padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
                        ),
                        for (final e in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TargetTile(
                              entry: e,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ResultsScreen(
                                    culture: widget.culture,
                                    target: e.target,
                                    type: e.type,
                                    stockOnly: widget.stockOnly,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({required this.entry, required this.onTap});

  final TargetEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15241B),
                  ),
                ),
              ),
              Text(
                '${entry.count}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
