import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';
import 'onboarding.dart';
import 'rewards.dart';
import 'trashdex.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('You'),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _SettingsSheet(profile: profile),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.s16, 0, Tokens.s16, 120),
      children: [
        Sticker(
          tilt: -0.7,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _EditSheet(profile: profile),
          ),
          child: Row(
            children: [
              PlayerAvatar(
                avatar: profile.avatar,
                photoUrl: profile.photoUrl,
                size: 64,
              ),
              const SizedBox(width: Tokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: display(size: 24),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [profile.city, profile.school, profile.country]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: ui(size: 13, color: Tokens.inkDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: Tokens.inkDim),
            ],
          ),
        ),
        const SizedBox(height: Tokens.s16),
        LevelBar(profile),
        const SizedBox(height: Tokens.s24),

        Row(
          children: [
            Expanded(
              child: _Shortcut(
                icon: Icons.grid_view_rounded,
                title: 'Trashdex',
                subtitle: profile.itemsCollected == 0
                    ? 'Nothing yet'
                    : 'Best: ${profile.bestFind.title}',
                color: Tokens.duelViolet,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrashdexScreen(profile: profile),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Tokens.s12),
            Expanded(
              child: _Shortcut(
                icon: Icons.redeem,
                title: 'Shop',
                subtitle: '${formatCount(profile.ecoPoints)} EcoPoints',
                color: Tokens.gold,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RewardsScreen(profile: profile),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Tokens.s32),
        const SectionLabel('EcoScore'),
        Sticker(
          child: Column(
            children: [
              Text(
                '${profile.ecoScore}',
                style: display(size: 46, color: Tokens.questGreenDeep),
              ),
              Text('OUT OF 1000', style: label()),
              const SizedBox(height: Tokens.s12),
              Text(
                'Built from how much you collect, how consistently, and how '
                'varied your actions are — so one easy category cannot carry it.',
                style: ui(size: 12, color: Tokens.inkDim),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: Tokens.s32),
        const SectionLabel('What you have collected'),
        if (profile.classCounts.isEmpty)
          Text(
            'Nothing yet. Your first quest is one tap away.',
            style: ui(size: 14, color: Tokens.inkDim),
          )
        else
          Sticker(
            child: Column(
              children: [
                for (final entry in _sorted(profile.classCounts))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Tokens.s8),
                    child: Row(
                      children: [
                        Container(
                          height: 14,
                          width: 14,
                          decoration: BoxDecoration(
                            color: Tokens.bin(entry.key),
                            shape: BoxShape.circle,
                            border: Border.all(color: Tokens.ink, width: 2),
                          ),
                        ),
                        const SizedBox(width: Tokens.s12),
                        Expanded(
                          child: Text(
                            entry.key.replaceAll('_', ' '),
                            style: ui(size: 14),
                          ),
                        ),
                        Text(formatCount(entry.value), style: display(size: 16)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: Tokens.s32),
        const SectionLabel('Recent quests'),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: data.recentSubmissions(profile.uid),
          builder: (context, snap) {
            final entries = snap.data;
            if (entries == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (entries.isEmpty) {
              return Text(
                'No history yet.',
                style: ui(size: 14, color: Tokens.inkDim),
              );
            }
            return Column(
              children: [
                for (final entry in entries) ...[
                  _HistoryRow(entry: entry),
                  const SizedBox(height: Tokens.s8),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );

  static List<MapEntry<String, int>> _sorted(Map<String, int> counts) {
    final list = counts.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Sticker(
    onTap: onTap,
    accent: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: Tokens.chip(color, radius: Tokens.rChip),
          child: Icon(icon, size: 18, color: Tokens.onFill(color)),
        ),
        const SizedBox(height: Tokens.s12),
        Text(title, style: display(size: 19)),
        Text(subtitle, style: ui(size: 12, color: Tokens.inkDim)),
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final items = (entry['itemsCounted'] as num?)?.toInt() ?? 0;
    final xp = (entry['xpAwarded'] as num?)?.toInt() ?? 0;
    final co2 = (entry['co2SavedG'] as num?)?.toInt() ?? 0;
    final selfReported = entry['verification'] == 'self_report';
    final photoUrl = (entry['photoUrl'] as String?) ?? '';
    final best = Rarity.byName(entry['bestRarity'] as String?);

    // createdAt is a server timestamp; it reads back null until the write
    // actually reaches the server, which is normal for a queued offline submit.
    final when = switch (entry['createdAt']) {
      final t? => (t as dynamic).toDate() as DateTime,
      _ => null,
    };

    return Sticker(
      padding: const EdgeInsets.all(Tokens.s12),
      accent: best.isBoasted ? Tokens.rarity(best.name) : null,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.s12),
            child: photoUrl.isEmpty
                ? Container(
                    height: 52,
                    width: 52,
                    color: Tokens.pageSubtle,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 18,
                      color: Tokens.inkDim,
                    ),
                  )
                : Image.network(
                    photoUrl,
                    height: 52,
                    width: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 52,
                      width: 52,
                      color: Tokens.pageSubtle,
                    ),
                  ),
          ),
          const SizedBox(width: Tokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry['questTitle'] as String?) ?? 'Quest',
                  style: display(size: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$items items · ${formatCo2(co2)} CO₂'
                  '${when == null ? ' · syncing' : ' · ${DateFormat.MMMd().add_Hm().format(when)}'}',
                  style: ui(size: 12, color: Tokens.inkDim),
                ),
                if (best.isBoasted) ...[
                  const SizedBox(height: Tokens.s4),
                  RarityBadge(best, compact: true),
                ],
              ],
            ),
          ),
          if (selfReported) const SelfReportedChip(),
          const SizedBox(width: Tokens.s8),
          Text(
            '+$xp',
            style: display(size: 16, color: Tokens.questGreenDeep),
          ),
        ],
      ),
    );
  }
}

/// Identity: face, name, and the fields that decide which leagues you play in.
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _name = TextEditingController(text: widget.profile.displayName);
  late final _city = TextEditingController(text: widget.profile.city ?? '');
  late final _country = TextEditingController(text: widget.profile.country ?? '');
  late final _school = TextEditingController(text: widget.profile.school ?? '');
  late Avatar _avatar = widget.profile.avatar;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    _school.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await data.updateProfile(
        widget.profile.uid,
        displayName: _name.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        school: _school.text.trim(),
        avatar: _avatar,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save that: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Edit profile',
    children: [
      AvatarPicker(
        avatar: _avatar,
        onChanged: (a) => setState(() => _avatar = a),
      ),
      const SizedBox(height: Tokens.s24),
      TextField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Display name'),
      ),
      const SizedBox(height: Tokens.s12),
      TextField(
        controller: _city,
        decoration: const InputDecoration(labelText: 'City'),
      ),
      const SizedBox(height: Tokens.s12),
      TextField(
        controller: _country,
        decoration: const InputDecoration(labelText: 'Country'),
      ),
      const SizedBox(height: Tokens.s12),
      TextField(
        controller: _school,
        decoration: const InputDecoration(labelText: 'School (optional)'),
      ),
      const SizedBox(height: Tokens.s8),
      Text(
        'Your city, country and school decide which leagues you compete in.',
        style: ui(size: 12, color: Tokens.inkDim),
      ),
      const SizedBox(height: Tokens.s24),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}

/// Privacy, the tutorial, and the two account actions the stores require.
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _share = widget.profile.shareLocation;
  bool _busy = false;

  Future<void> _setShare(bool value) async {
    setState(() {
      _share = value;
      _busy = true;
    });
    try {
      await data.setLocationSharing(widget.profile.uid, value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _share = !value);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not change that: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'Your profile, XP, streak and collection go for good. Pins and '
          'cleanups you already contributed stay on the map, without your name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: ui(color: Tokens.alertRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await auth.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'requires-recent-login'
                ? 'For safety, sign out and back in, then delete.'
                : e.message ?? 'Could not delete the account.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Settings',
    children: [
      Sticker(
        fill: Tokens.pageSubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined, size: 20),
                const SizedBox(width: Tokens.s8),
                Expanded(
                  child: Text('Show me on the map', style: display(size: 17)),
                ),
                Switch(
                  value: _share,
                  onChanged: _busy ? null : _setShare,
                  activeThumbColor: Tokens.ink,
                  activeTrackColor: Tokens.questGreen,
                ),
              ],
            ),
            const SizedBox(height: Tokens.s8),
            Text(
              'Only people on your friends list see your position, it is hidden '
              'again two hours after you last moved, and turning this off '
              'deletes the last one stored.',
              style: ui(size: 13, color: Tokens.inkDim),
            ),
          ],
        ),
      ),
      const SizedBox(height: Tokens.s12),
      _SettingRow(
        icon: Icons.school_outlined,
        title: 'How EcoQuest works',
        subtitle: 'Replay the walkthrough',
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  OnboardingScreen(profile: widget.profile, replay: true),
            ),
          );
        },
      ),
      _SettingRow(
        icon: Icons.logout,
        title: 'Sign out',
        subtitle: widget.profile.displayName,
        onTap: () {
          Navigator.of(context).pop();
          auth.signOut();
        },
      ),
      _SettingRow(
        icon: Icons.delete_forever_outlined,
        title: 'Delete account',
        subtitle: 'Permanent, and it cannot be undone',
        color: Tokens.alertRed,
        onTap: _busy ? null : _delete,
      ),
    ],
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = Tokens.ink,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.s12),
    child: Sticker(
      onTap: onTap,
      padding: const EdgeInsets.all(Tokens.s12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: Tokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: display(size: 17, color: color)),
                Text(subtitle, style: ui(size: 12, color: Tokens.inkDim)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Tokens.inkDim),
        ],
      ),
    ),
  );
}

/// Shared bottom-sheet chrome: scrollable, keyboard-aware, capped at most of
/// the screen so a long sheet cannot push its own save button out of reach.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Tokens.s24,
        Tokens.s24,
        Tokens.s24,
        MediaQuery.viewInsetsOf(context).bottom + Tokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: display(size: 24)),
          const SizedBox(height: Tokens.s16),
          ...children,
        ],
      ),
    ),
  );
}
