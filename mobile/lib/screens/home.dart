import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';
import 'capture.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Quest?> _daily = data.dailyQuest();

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _daily = data.dailyQuest()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Tokens.s16,
            Tokens.s16,
            Tokens.s16,
            120, // clear of the FAB and nav bar
          ),
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hey ${p.displayName.split(' ').first}', style: display(size: 24)),
                        if (p.city case final city? when city.isNotEmpty)
                          Text(city, style: ui(size: 13, color: Tokens.boneDim)),
                      ],
                    ),
                  ),
                  StreakChip(p.streak),
                ],
              ),
            ),
            const SizedBox(height: Tokens.s24),

            // Hero metric: one number owns this screen.
            Center(
              child: Column(
                children: [
                  Text(formatCount(p.xp), style: display(size: 56)),
                  Text('TOTAL XP', style: label()),
                ],
              ),
            ),
            const SizedBox(height: Tokens.s16),
            LevelBar(p),
            const SizedBox(height: Tokens.s32),

            const SectionLabel('Today\'s quest'),
            FutureBuilder<Quest?>(
              future: _daily,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _QuestSkeleton();
                }
                final quest = snap.data;
                if (quest == null) {
                  return const _FlatCard(
                    child: EmptyState(
                      icon: Icons.hourglass_empty,
                      title: 'No quest yet',
                      body: 'Seed the quests collection and pull to refresh.',
                    ),
                  );
                }
                return QuestCard(
                  quest: quest,
                  onStart: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CaptureScreen(profile: p, quest: quest),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: Tokens.s32),
            const SectionLabel('Your impact'),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: formatCount(p.itemsCollected),
                    caption: 'items collected',
                    icon: Icons.cleaning_services_outlined,
                    color: Tokens.questGreen,
                  ),
                ),
                const SizedBox(width: Tokens.s12),
                Expanded(
                  child: StatTile(
                    value: _co2(p.co2SavedG),
                    caption: 'CO₂ avoided',
                    icon: Icons.cloud_outlined,
                    color: Tokens.impactCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.s12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${p.ecoScore}',
                    caption: 'EcoScore',
                    icon: Icons.eco_outlined,
                    color: Tokens.gold,
                  ),
                ),
                const SizedBox(width: Tokens.s12),
                Expanded(
                  child: StatTile(
                    value: '${p.streak.longest}',
                    caption: 'longest streak',
                    icon: Icons.local_fire_department_outlined,
                    color: Tokens.streakFire,
                  ),
                ),
              ],
            ),
            // Never claim an impact figure without showing its basis.
            const SizedBox(height: Tokens.s8),
            Text(
              'CO₂ estimates use per-material averages (EPA WARM factors). '
              'Tap an entry in your history to see how one was calculated.',
              style: ui(size: 11, color: Tokens.boneDim),
            ),

            const SizedBox(height: Tokens.s32),
            const SectionLabel('More quests'),
            StreamBuilder<List<Quest>>(
              stream: data.bonusQuests(),
              builder: (context, snap) {
                final quests = snap.data ?? const <Quest>[];
                if (quests.isEmpty) {
                  return Text(
                    'Nothing extra right now. Check back tomorrow.',
                    style: ui(size: 14, color: Tokens.boneDim),
                  );
                }
                return Column(
                  children: [
                    for (final q in quests) ...[
                      QuestCard(
                        quest: q,
                        compact: true,
                        onStart: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CaptureScreen(profile: p, quest: q),
                          ),
                        ),
                      ),
                      const SizedBox(height: Tokens.s12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _co2(int grams) =>
      grams >= 1000 ? '${(grams / 1000).toStringAsFixed(1)} kg' : '$grams g';
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.quest,
    required this.onStart,
    this.compact = false,
    super.key,
  });

  final Quest quest;
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) => _FlatCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(quest.title, style: display(size: compact ? 18 : 22))),
            if (quest.verification == Verification.selfReport)
              const SelfReportedChip(),
          ],
        ),
        if (quest.description.isNotEmpty) ...[
          const SizedBox(height: Tokens.s4),
          Text(quest.description, style: ui(size: 14, color: Tokens.boneDim)),
        ],
        const SizedBox(height: Tokens.s12),
        Wrap(
          spacing: Tokens.s8,
          runSpacing: Tokens.s8,
          children: [
            _Pill('+${quest.xpReward} XP', Tokens.questGreen),
            _Pill('+${quest.pointsReward} EcoPoints', Tokens.impactCyan),
            if (quest.targetClasses.isNotEmpty)
              _Pill(
                '${quest.targetCount}× ${quest.targetClasses.join(' / ')}',
                Tokens.boneDim,
              )
            else
              _Pill('${quest.targetCount} items', Tokens.boneDim),
          ],
        ),
        if (quest.isSponsored) ...[
          const SizedBox(height: Tokens.s12),
          SponsorChip(quest.sponsorName!),
        ],
        const SizedBox(height: Tokens.s16),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.camera_alt, size: 20),
          label: const Text('Start quest'),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.s12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(Tokens.rPill),
    ),
    child: Text(text, style: ui(size: 12, weight: FontWeight.w600, color: color)),
  );
}

class _FlatCard extends StatelessWidget {
  const _FlatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Tokens.s16),
    decoration: BoxDecoration(
      color: Tokens.forestSurface,
      borderRadius: BorderRadius.circular(Tokens.rCard),
      border: Border.all(color: Tokens.forestLine),
    ),
    child: child,
  );
}

class _QuestSkeleton extends StatelessWidget {
  const _QuestSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    decoration: BoxDecoration(
      color: Tokens.forestSurface,
      borderRadius: BorderRadius.circular(Tokens.rCard),
      border: Border.all(color: Tokens.forestLine),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}
