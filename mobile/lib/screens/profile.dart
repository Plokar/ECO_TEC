import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('You'),
      actions: [
        IconButton(
          tooltip: 'Edit profile',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => _EditSheet(profile: profile),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: auth.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.s16, 0, Tokens.s16, 120),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Tokens.forestLine,
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Text(
                      profile.displayName.characters.first.toUpperCase(),
                      style: display(size: 24),
                    )
                  : null,
            ),
            const SizedBox(width: Tokens.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayName, style: display(size: 24)),
                  Text(
                    [
                      profile.city,
                      profile.school,
                      profile.country,
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                    style: ui(size: 13, color: Tokens.boneDim),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.s24),
        LevelBar(profile),
        const SizedBox(height: Tokens.s32),

        const SectionLabel('EcoScore'),
        Container(
          padding: const EdgeInsets.all(Tokens.s16),
          decoration: BoxDecoration(
            color: Tokens.forestSurface,
            borderRadius: BorderRadius.circular(Tokens.rCard),
            border: Border.all(color: Tokens.forestLine),
          ),
          child: Column(
            children: [
              Text('${profile.ecoScore}', style: display(size: 44, color: Tokens.gold)),
              Text('OUT OF 1000', style: label()),
              const SizedBox(height: Tokens.s12),
              Text(
                'Built from how much you collect, how consistently, and how '
                'varied your actions are — so one easy category can\'t carry it.',
                style: ui(size: 12, color: Tokens.boneDim),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: Tokens.s32),
        const SectionLabel('What you\'ve collected'),
        if (profile.classCounts.isEmpty)
          Text(
            'Nothing yet. Your first quest is one tap away.',
            style: ui(size: 14, color: Tokens.boneDim),
          )
        else
          Column(
            children: [
              for (final entry in _sorted(profile.classCounts))
                Padding(
                  padding: const EdgeInsets.only(bottom: Tokens.s8),
                  child: Row(
                    children: [
                      Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: Tokens.bin(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Tokens.s12),
                      Expanded(
                        child: Text(
                          entry.key.replaceAll('_', ' '),
                          style: ui(size: 14),
                        ),
                      ),
                      Text(
                        formatCount(entry.value),
                        style: display(size: 16, color: Tokens.bin(entry.key)),
                      ),
                    ],
                  ),
                ),
            ],
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
                style: ui(size: 14, color: Tokens.boneDim),
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

    // createdAt is a server timestamp; it reads back null until the write
    // actually reaches the server, which is normal for a queued offline submit.
    final when = switch (entry['createdAt']) {
      final t? => (t as dynamic).toDate() as DateTime,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(Tokens.s12),
      decoration: BoxDecoration(
        color: Tokens.forestSurface,
        borderRadius: BorderRadius.circular(Tokens.rCard),
        border: Border.all(color: Tokens.forestLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photoUrl.isEmpty
                ? Container(
                    height: 48,
                    width: 48,
                    color: Tokens.forestLine,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 18,
                      color: Tokens.boneDim,
                    ),
                  )
                : Image.network(
                    photoUrl,
                    height: 48,
                    width: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 48,
                      width: 48,
                      color: Tokens.forestLine,
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
                  style: ui(size: 14, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$items items · $co2 g CO₂'
                  '${when == null ? ' · syncing' : ' · ${DateFormat.MMMd().add_Hm().format(when)}'}',
                  style: ui(size: 12, color: Tokens.boneDim),
                ),
              ],
            ),
          ),
          if (selfReported) const SelfReportedChip(),
          const SizedBox(width: Tokens.s8),
          Text('+$xp', style: display(size: 16, color: Tokens.questGreen)),
        ],
      ),
    );
  }
}

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
    await data.updateProfile(
      widget.profile.uid,
      displayName: _name.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
      school: _school.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
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
        Text('Edit profile', style: display(size: 22)),
        const SizedBox(height: Tokens.s8),
        Text(
          'Your city, country and school decide which leagues you compete in.',
          style: ui(size: 13, color: Tokens.boneDim),
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
        const SizedBox(height: Tokens.s24),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
