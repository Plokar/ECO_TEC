import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// EcoPoints → real-world rewards. One of the four revenue streams: partners
/// pay to put their offer in front of an audience that just did something good.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({required this.profile, super.key});

  final UserProfile profile;

  Future<void> _redeem(BuildContext context, Reward reward) async {
    // Grabbed before the dialog await — the context may be gone afterwards.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Tokens.forestSurface,
        title: Text(reward.title, style: display(size: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spend ${formatCount(reward.costPoints)} EcoPoints?',
              style: ui(),
            ),
            const SizedBox(height: Tokens.s8),
            Text(
              'You\'ll have ${formatCount(profile.ecoPoints - reward.costPoints)} left.',
              style: ui(size: 13, color: Tokens.boneDim),
            ),
            if (reward.terms case final terms? when terms.isNotEmpty) ...[
              const SizedBox(height: Tokens.s12),
              Text(terms, style: ui(size: 12, color: Tokens.boneDim)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final code = await data.redeem(profile, reward);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Redeemed. Your code: ${code.substring(0, 8).toUpperCase()}'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rewards')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.s16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Tokens.s16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Tokens.impactCyan.withValues(alpha: 0.18),
                  Tokens.questGreen.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(Tokens.rCard),
              border: Border.all(color: Tokens.forestLine),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR BALANCE', style: label()),
                    Text(
                      formatCount(profile.ecoPoints),
                      style: display(size: 34, color: Tokens.impactCyan),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.savings_outlined, size: 40, color: Tokens.impactCyan),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Reward>>(
            stream: data.rewards(),
            builder: (context, snap) {
              final rewards = snap.data;
              if (rewards == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (rewards.isEmpty) {
                return const EmptyState(
                  icon: Icons.redeem_outlined,
                  title: 'No rewards yet',
                  body: 'Partner offers show up here once they go live.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.s16,
                  Tokens.s24,
                  Tokens.s16,
                  120,
                ),
                itemCount: rewards.length,
                separatorBuilder: (_, _) => const SizedBox(height: Tokens.s12),
                itemBuilder: (context, i) {
                  final reward = rewards[i];
                  final affordable = profile.ecoPoints >= reward.costPoints;
                  return Container(
                    padding: const EdgeInsets.all(Tokens.s16),
                    decoration: BoxDecoration(
                      color: Tokens.forestSurface,
                      borderRadius: BorderRadius.circular(Tokens.rCard),
                      border: Border.all(color: Tokens.forestLine),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reward.title, style: display(size: 18)),
                              const SizedBox(height: 2),
                              Text(
                                reward.partner,
                                style: ui(size: 13, color: Tokens.boneDim),
                              ),
                              const SizedBox(height: Tokens.s8),
                              Row(
                                children: [
                                  Text(
                                    '${formatCount(reward.costPoints)} pts',
                                    style: display(
                                      size: 16,
                                      color: Tokens.impactCyan,
                                    ),
                                  ),
                                  if (reward.stock > 0 && reward.stock < 20) ...[
                                    const SizedBox(width: Tokens.s8),
                                    Text(
                                      'only ${reward.stock} left',
                                      style: ui(
                                        size: 11,
                                        color: Tokens.streakFire,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Tokens.s12),
                        FilledButton(
                          onPressed: (!affordable || reward.soldOut)
                              ? null
                              : () => _redeem(context, reward),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(96, 48),
                          ),
                          child: Text(
                            reward.soldOut
                                ? 'Gone'
                                : affordable
                                    ? 'Redeem'
                                    : 'Locked',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
