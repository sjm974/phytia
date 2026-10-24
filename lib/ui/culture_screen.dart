import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/scope.dart';
import 'target_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

class CultureScreen extends StatefulWidget {
  const CultureScreen({super.key, this.stockOnly = false});

  final bool stockOnly;

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PhytiaScope.of(context);
    final data = scope.dataset;
    final query = normalize(_query.trim());

    final cultures = data.cultures.where((c) {
      if (query.isEmpty) return true;
      return normalize(c).contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stockOnly ? 'Que puis-je traiter ?' : 'Choisir une culture',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: PhytiaSearchField(
              controller: _controller,
              hint: 'Blé, vigne, tomate…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (widget.stockOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 15,
                    color: phytiaGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Seuls les produits de votre stock seront proposés.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: cultures.length,
              itemBuilder: (context, index) {
                final culture = cultures[index];
                final usages = data.usagesForCulture(culture);
                final targets = data.targetsForCulture(culture);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        scope.store.rememberCulture(culture);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TargetScreen(
                              culture: culture,
                              stockOnly: widget.stockOnly,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4F1E7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                culture.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: phytiaGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    culture,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: phytiaDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${targets.length} cibles · ${usages.length} usages',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
