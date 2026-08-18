import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// The collection. Every litter class the detector knows about, whether you
/// have found one, and how the rarities you have pulled break down.
///
/// The point is the gap: an unfound class is drawn greyed rather than hidden,
/// because "one more to complete the set" is the whole reason to go outside.
class TrashdexScreen extends StatelessWidget {
  const TrashdexScreen({required this.profile, super.key});

  final UserProfile profile;

  /// The taxonomy comes off the loaded detector, so the dex can never list a
  /// class the model cannot actually recognise.
  Future<List<LitterClass>> get _classes =>
      detector().then((d) => d.labels.classes);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text('Trashdex')),
    body: FutureBuilder<List<LitterClass>>(
      future: _classes,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Cannot read the taxonomy',
            body: '${snap.error}',
          );
        }
        final classes = snap.data;
        if (classes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final found = classes.where((c) => (profile.classCounts[c.name] ?? 0) > 0).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Tokens.s16,
            0,
            Tokens.s16,
            Tokens.s32,
          ),
          children: [
            Sticker(
              fill: Tokens.pageSubtle,
              tilt: -0.8,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$found / ${classes.length}',
                        style: display(size: 34),
                      ),
                      Text('MATERIALS FOUND', style: label()),
                    ],
                  ),
                  const Spacer(),
                  if (profile.itemsCollected > 0) RarityBadge(profile.bestFind),
                ],
              ),
            ),
            const SizedBox(height: Tokens.s24),

            const SectionLabel('Rarities pulled'),
            Sticker(
              child: Column(
                children: [
                  for (final r in Rarity.values.reversed) ...[
                    _RarityRow(
                      rarity: r,
                      count: profile.rarityCounts[r.name] ?? 0,
                      total: profile.itemsCollected,
                    ),
                    if (r != Rarity.common) const SizedBox(height: Tokens.s12),
                  ],
                ],
              ),
            ),

            const SizedBox(height: Tokens.s24),
            const SectionLabel('Materials'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Tokens.s12,
              crossAxisSpacing: Tokens.s12,
              childAspectRatio: 1.05,
              children: [
                for (final cls in classes)
                  _DexTile(
                    cls: cls,
                    count: profile.classCounts[cls.name] ?? 0,
                  ),
              ],
            ),
            const SizedBox(height: Tokens.s16),
            Text(
              'Rarity is rolled per item when you claim it, seeded by the photo '
              'itself — the same shot always gives the same result, so there is '
              'nothing to reroll. Metal and glass roll a little luckier.',
              style: ui(size: 12, color: Tokens.inkDim),
            ),
          ],
        );
      },
    ),
  );
}

class _RarityRow extends StatelessWidget {
  const _RarityRow({
    required this.rarity,
    required this.count,
    required this.total,
  });

  final Rarity rarity;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(width: 116, child: RarityBadge(rarity, compact: true)),
        const SizedBox(width: Tokens.s12),
        Expanded(
          child: Container(
            height: 14,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Tokens.pageSubtle,
              borderRadius: BorderRadius.circular(Tokens.rPill),
              border: Border.all(color: Tokens.ink, width: 2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: share.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Tokens.rarity(rarity.name),
                    borderRadius: BorderRadius.circular(Tokens.rPill),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Tokens.s12),
        SizedBox(
          width: 44,
          child: Text(
            formatCount(count),
            style: display(size: 16),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DexTile extends StatelessWidget {
  const _DexTile({required this.cls, required this.count});

  final LitterClass cls;
  final int count;

  @override
  Widget build(BuildContext context) {
    final found = count > 0;
    final color = Tokens.bin(cls.name);
    return Sticker(
      fill: found ? Tokens.paper : Tokens.pageSubtle,
      accent: found ? color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Tokens.s8),
            decoration: Tokens.chip(
              found ? color : Tokens.page,
              radius: Tokens.rChip,
            ),
            child: Icon(
              switch (cls.bin) {
                'plastic' => Icons.local_drink_outlined,
                'glass' => Icons.wine_bar_outlined,
                'metal' => Icons.opacity,
                'paper' => Icons.description_outlined,
                'bio' => Icons.compost,
                _ => Icons.delete_outline,
              },
              size: 20,
              color: found ? Tokens.onFill(color) : Tokens.inkDim,
            ),
          ),
          const Spacer(),
          Text(
            cls.displayName,
            style: display(size: 17, color: found ? Tokens.ink : Tokens.inkDim),
          ),
          Text(
            found ? '${formatCount(count)} collected' : 'Not found yet',
            style: ui(size: 12, color: Tokens.inkDim),
          ),
          const SizedBox(height: Tokens.s4),
          Text(
            '${cls.points} pts · ${cls.co2g} g CO₂ · ${cls.bin} bin',
            style: ui(size: 11, color: Tokens.inkDim),
          ),
        ],
      ),
    );
  }
}
