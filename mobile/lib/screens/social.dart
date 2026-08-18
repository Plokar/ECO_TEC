import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// World → Country → City → School → Friends, the hierarchy the whole game
/// hangs off. Every level gives a different reason to care about your rank.
class SocialScreen extends StatefulWidget {
  const SocialScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Leagues'),
      bottom: TabBar(
        controller: _tabs,
        indicatorColor: Tokens.questGreen,
        labelColor: Tokens.bone,
        unselectedLabelColor: Tokens.boneDim,
        labelStyle: ui(size: 14, weight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Players'),
          Tab(text: 'Cities'),
          Tab(text: 'Friends'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _PlayerBoards(profile: widget.profile),
        _LeagueBoards(profile: widget.profile),
        _FriendsTab(profile: widget.profile),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------

class _PlayerBoards extends StatefulWidget {
  const _PlayerBoards({required this.profile});

  final UserProfile profile;

  @override
  State<_PlayerBoards> createState() => _PlayerBoardsState();
}

class _PlayerBoardsState extends State<_PlayerBoards> {
  Scope _scope = Scope.friends;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.s12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final scope in Scope.values) ...[
                  ChoiceChip(
                    label: Text(scope.title),
                    selected: _scope == scope,
                    onSelected: (_) => setState(() => _scope = scope),
                    labelStyle: ui(
                      size: 13,
                      weight: FontWeight.w600,
                      color: _scope == scope ? Tokens.deepForest : Tokens.bone,
                    ),
                    selectedColor: Tokens.questGreen,
                    backgroundColor: Tokens.forestSurface,
                    side: const BorderSide(color: Tokens.forestLine),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: Tokens.s8),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserProfile>>(
            stream: data.leaderboard(_scope, p),
            builder: (context, snap) {
              if (snap.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Couldn\'t load that board',
                  // Missing composite indexes are the usual cause here.
                  body: '${snap.error}',
                );
              }
              final players = snap.data;
              if (players == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (players.isEmpty) {
                return EmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'Nothing here yet',
                  body: switch (_scope) {
                    Scope.friends => 'Add a friend and the duel begins.',
                    Scope.school => 'Set your school in your profile to join its league.',
                    Scope.city => 'Set your city in your profile to join its league.',
                    Scope.country => 'Set your country in your profile.',
                    Scope.global => 'Be the first on the board.',
                  },
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.s16,
                  0,
                  Tokens.s16,
                  120,
                ),
                itemCount: players.length,
                separatorBuilder: (_, _) => const SizedBox(height: Tokens.s8),
                itemBuilder: (context, i) => PlayerRow(
                  rank: i + 1,
                  player: players[i],
                  isMe: players[i].uid == p.uid,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// City vs city and country vs country — the table built to be screenshotted.
class _LeagueBoards extends StatefulWidget {
  const _LeagueBoards({required this.profile});

  final UserProfile profile;

  @override
  State<_LeagueBoards> createState() => _LeagueBoardsState();
}

class _LeagueBoardsState extends State<_LeagueBoards> {
  String _kind = 'city';

  @override
  Widget build(BuildContext context) {
    final mine = _kind == 'city' ? widget.profile.city : widget.profile.country;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Tokens.s12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'city', label: Text('Cities')),
              ButtonSegment(value: 'country', label: Text('Countries')),
              ButtonSegment(value: 'school', label: Text('Schools')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Tokens.forestSurface,
              selectedBackgroundColor: Tokens.questGreen,
              selectedForegroundColor: Tokens.deepForest,
              foregroundColor: Tokens.bone,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: data.leagueTable(_kind),
            builder: (context, snap) {
              final rows = snap.data;
              if (rows == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (rows.isEmpty) {
                return const EmptyState(
                  icon: Icons.public,
                  title: 'The league is empty',
                  body: 'Verified quests build these totals. Go collect something.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.s16,
                  0,
                  Tokens.s16,
                  120,
                ),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: Tokens.s8),
                itemBuilder: (context, i) {
                  final row = rows[i];
                  final name = (row['name'] as String?) ?? '—';
                  final isMine = mine != null && name == mine;
                  return Container(
                    padding: const EdgeInsets.all(Tokens.s16),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Tokens.questGreen.withValues(alpha: 0.10)
                          : Tokens.forestSurface,
                      borderRadius: BorderRadius.circular(Tokens.rCard),
                      border: Border.all(
                        color: isMine ? Tokens.questGreen : Tokens.forestLine,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${i + 1}',
                            style: display(
                              size: 18,
                              color: i == 0 ? Tokens.gold : Tokens.boneDim,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: ui(size: 16, weight: FontWeight.w600),
                              ),
                              Text(
                                '${formatCount((row['items'] as num?)?.toInt() ?? 0)} items',
                                style: ui(size: 12, color: Tokens.boneDim),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCount((row['points'] as num?)?.toInt() ?? 0),
                          style: display(size: 18, color: Tokens.impactCyan),
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
    );
  }
}

// ---------------------------------------------------------------------------

class _FriendsTab extends StatefulWidget {
  const _FriendsTab({required this.profile});

  final UserProfile profile;

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  final _search = TextEditingController();
  List<UserProfile> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(String query) async {
    setState(() => _searching = true);
    final found = await data.searchPlayers(query);
    if (!mounted) return;
    setState(() {
      _results = found.where((u) => u.uid != widget.profile.uid).toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tokens.s16, Tokens.s16, Tokens.s16, 120),
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Find a player by name',
            prefixIcon: const Icon(Icons.search, color: Tokens.boneDim),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onSubmitted: _run,
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: Tokens.s24),
          const SectionLabel('Search results'),
          for (final found in _results) ...[
            _FriendRow(
              player: found,
              isFriend: p.friends.contains(found.uid),
              onToggle: () async {
                if (p.friends.contains(found.uid)) {
                  await data.removeFriend(p.uid, found.uid);
                } else {
                  await data.addFriend(p.uid, found.uid);
                }
              },
            ),
            const SizedBox(height: Tokens.s8),
          ],
        ],
        const SizedBox(height: Tokens.s24),
        SectionLabel('Your friends · ${p.friends.length}'),
        if (p.friends.isEmpty)
          Text(
            'No friends yet. Competing against an abstract environmental goal is '
            'much less motivating than beating someone you know.',
            style: ui(size: 14, color: Tokens.boneDim),
          )
        else
          StreamBuilder<List<UserProfile>>(
            stream: data.leaderboard(Scope.friends, p),
            builder: (context, snap) {
              final friends =
                  (snap.data ?? const <UserProfile>[])
                      .where((u) => u.uid != p.uid)
                      .toList();
              return Column(
                children: [
                  for (final friend in friends) ...[
                    _DuelCard(me: p, them: friend),
                    const SizedBox(height: Tokens.s8),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.player,
    required this.isFriend,
    required this.onToggle,
  });

  final UserProfile player;
  final bool isFriend;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Tokens.s16,
      vertical: Tokens.s8,
    ),
    decoration: BoxDecoration(
      color: Tokens.forestSurface,
      borderRadius: BorderRadius.circular(Tokens.rCard),
      border: Border.all(color: Tokens.forestLine),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Tokens.forestLine,
          child: Text(
            player.displayName.characters.first.toUpperCase(),
            style: display(size: 14),
          ),
        ),
        const SizedBox(width: Tokens.s12),
        Expanded(
          child: Text(
            player.displayName,
            style: ui(size: 15, weight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onToggle,
          tooltip: isFriend ? 'Remove friend' : 'Add friend',
          icon: Icon(
            isFriend ? Icons.person_remove_outlined : Icons.person_add_outlined,
            color: isFriend ? Tokens.alertRed : Tokens.questGreen,
          ),
        ),
      ],
    ),
  );
}

/// Head-to-head. The comparison is the product — an abstract goal doesn't make
/// anyone go outside, but being 3 bottles behind Alex does.
class _DuelCard extends StatelessWidget {
  const _DuelCard({required this.me, required this.them});

  final UserProfile me;
  final UserProfile them;

  @override
  Widget build(BuildContext context) {
    final iLead = me.xp >= them.xp;
    return Container(
      padding: const EdgeInsets.all(Tokens.s16),
      decoration: BoxDecoration(
        color: Tokens.forestSurface,
        borderRadius: BorderRadius.circular(Tokens.rCard),
        border: Border.all(color: Tokens.forestLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sports_kabaddi, size: 18, color: Tokens.duelViolet),
              const SizedBox(width: Tokens.s8),
              Expanded(
                child: Text(
                  'You vs ${them.displayName}',
                  style: ui(size: 15, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                iLead ? 'Leading' : 'Behind',
                style: label(
                  color: iLead ? Tokens.questGreen : Tokens.streakFire,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.s12),
          _DuelRow('XP', formatCount(me.xp), formatCount(them.xp), me.xp >= them.xp),
          _DuelRow(
            'Items',
            formatCount(me.itemsCollected),
            formatCount(them.itemsCollected),
            me.itemsCollected >= them.itemsCollected,
          ),
          _DuelRow(
            'Streak',
            '${me.streak.current}',
            '${them.streak.current}',
            me.streak.current >= them.streak.current,
          ),
        ],
      ),
    );
  }
}

class _DuelRow extends StatelessWidget {
  const _DuelRow(this.metric, this.mine, this.theirs, this.iWin);

  final String metric;
  final String mine;
  final String theirs;
  final bool iWin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            mine,
            style: display(
              size: 15,
              color: iWin ? Tokens.questGreen : Tokens.boneDim,
            ),
          ),
        ),
        Text(metric.toUpperCase(), style: label()),
        Expanded(
          child: Text(
            theirs,
            textAlign: TextAlign.right,
            style: display(
              size: 15,
              color: iWin ? Tokens.boneDim : Tokens.streakFire,
            ),
          ),
        ),
      ],
    ),
  );
}
