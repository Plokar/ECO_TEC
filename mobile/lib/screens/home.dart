import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';
import 'capture.dart';
import 'rewards.dart';
import 'streak_calendar.dart';

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
      backgroundColor: Colors.transparent,
      // This screen has no AppBar, so without a SafeArea the list scrolls its
      // content up underneath the status bar and the two collide illegibly.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => setState(() => _daily = data.dailyQuest()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Tokens.s16,
              Tokens.s16,
              Tokens.s16,
              120, // clear of the FAB and nav bar
            ),
            children: [
              Row(
                children: [
                  PlayerAvatar(avatar: p.avatar, photoUrl: p.photoUrl, size: 46),
                  const SizedBox(width: Tokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey ${p.displayName.split(' ').first}',
                          style: display(size: 22),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.city case final city? when city.isNotEmpty)
                          Text(city, style: ui(size: 13, color: Tokens.inkDim)),
                      ],
                    ),
                  ),
                  StreakChip(
                    p.streak,
                    onTap: () => showStreakCalendar(context, p),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.s16),

              // The wallet is the shop door. A player looking for "where do I
              // spend this" looks at the balance, so that is where it opens.
              _WalletCard(profile: p),
              const SizedBox(height: Tokens.s16),

              // Hero metric: one number owns this screen.
              Sticker(
                fill: Tokens.paper,
                accent: Tokens.questGreen,
                tilt: -0.6,
                padding: const EdgeInsets.symmetric(vertical: Tokens.s24),
                child: Column(
                  children: [
                    Text(formatCount(p.xp), style: display(size: 56)),
                    Text('TOTAL XP', style: label()),
                    const SizedBox(height: Tokens.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.s16,
                      ),
                      child: LevelBar(p),
                    ),
                  ],
                ),
              ),
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
                    return const Sticker(
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
                      tilt: -0.8,
                    ),
                  ),
                  const SizedBox(width: Tokens.s12),
                  Expanded(
                    child: StatTile(
                      value: formatCo2(p.co2SavedG),
                      caption: 'CO₂ avoided',
                      icon: Icons.cloud_outlined,
                      color: Tokens.impactCyan,
                      tilt: 0.8,
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
                style: ui(size: 11, color: Tokens.inkDim),
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
                      style: ui(size: 14, color: Tokens.inkDim),
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
      ),
    );
  }
}

/// EcoPoints balance, and the way into the shop.
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Sticker(
    fill: Tokens.sky,
    padding: const EdgeInsets.symmetric(
      horizontal: Tokens.s16,
      vertical: Tokens.s12,
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RewardsScreen(profile: profile)),
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatCount(profile.ecoPoints), style: display(size: 26)),
            Text('ECOPOINTS', style: label(color: Tokens.ink)),
          ],
        ),
        const Spacer(),
        const Pill('Shop', icon: Icons.redeem, color: Tokens.gold),
        const SizedBox(width: Tokens.s8),
        const Icon(Icons.chevron_right, color: Tokens.ink),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Sticker(
    accent: compact ? null : Tokens.gold,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(quest.title, style: display(size: compact ? 18 : 24)),
            ),
            if (quest.verification == Verification.selfReport)
              const SelfReportedChip(),
          ],
        ),
        if (quest.description.isNotEmpty) ...[
          const SizedBox(height: Tokens.s4),
          Text(quest.description, style: ui(size: 14, color: Tokens.inkDim)),
        ],
        const SizedBox(height: Tokens.s12),
        Wrap(
          spacing: Tokens.s8,
          runSpacing: Tokens.s8,
          children: [
            Pill('+${quest.xpReward} XP'),
            Pill('+${quest.pointsReward} EcoPoints', color: Tokens.impactCyan),
            if (quest.targetClasses.isNotEmpty)
              Pill(
                '${quest.targetCount}× ${quest.targetClasses.join(' / ')}',
                color: Tokens.gold,
              )
            else
              Pill(
                '${quest.targetCount} item${quest.targetCount == 1 ? '' : 's'}',
                color: Tokens.gold,
              ),
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

class _QuestSkeleton extends StatelessWidget {
  const _QuestSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    decoration: Tokens.card(),
    child: const Center(child: CircularProgressIndicator()),
  );
}
