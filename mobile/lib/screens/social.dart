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
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('Friends & leagues'),
      bottom: TabBar(
        controller: _tabs,
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
                  _ScopeChip(
                    label: scope.title,
                    selected: _scope == scope,
                    onTap: () => setState(() => _scope = scope),
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
              backgroundColor: Tokens.paper,
              selectedBackgroundColor: Tokens.questGreen,
              selectedForegroundColor: Tokens.ink,
              foregroundColor: Tokens.inkDim,
              side: const BorderSide(color: Tokens.ink, width: 2),
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
                  return Sticker(
                    fill: isMine ? Tokens.pageSubtle : Tokens.paper,
                    accent: isMine ? Tokens.questGreen : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${i + 1}',
                            style: display(
                              size: 18,
                              color: i == 0
                                  ? Tokens.questGreenDeep
                                  : Tokens.inkDim,
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
                                style: ui(size: 12, color: Tokens.inkDim),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCount((row['points'] as num?)?.toInt() ?? 0),
                          style: display(size: 18),
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
            prefixIcon: const Icon(Icons.search, color: Tokens.inkDim),
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
            style: ui(size: 14, color: Tokens.inkDim),
          )
        else
          StreamBuilder<List<Presence>>(
            stream: data.friendsOnMap(p),
            builder: (context, liveSnap) {
              final live = {
                for (final presence in liveSnap.data ?? const <Presence>[])
                  presence.uid,
              };
              return StreamBuilder<List<UserProfile>>(
                stream: data.leaderboard(Scope.friends, p),
                builder: (context, snap) {
                  final friends = (snap.data ?? const <UserProfile>[])
                      .where((u) => u.uid != p.uid)
                      .toList();
                  return Column(
                    children: [
                      for (final friend in friends) ...[
                        _DuelCard(
                          me: p,
                          them: friend,
                          liveNow: live.contains(friend.uid),
                        ),
                        const SizedBox(height: Tokens.s8),
                      ],
                    ],
                  );
                },
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
  Widget build(BuildContext context) => Sticker(
    padding: const EdgeInsets.symmetric(
      horizontal: Tokens.s16,
      vertical: Tokens.s8,
    ),
    child: Row(
      children: [
        PlayerAvatar(
          avatar: player.avatar,
          photoUrl: player.photoUrl,
          size: 36,
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
            color: isFriend ? Tokens.alertRed : Tokens.questGreenDeep,
          ),
        ),
      ],
    ),
  );
}

/// Head-to-head. The comparison is the product — an abstract goal doesn't make
/// anyone go outside, but being 3 bottles behind Alex does.
class _DuelCard extends StatelessWidget {
  const _DuelCard({
    required this.me,
    required this.them,
    this.liveNow = false,
  });

  final UserProfile me;
  final UserProfile them;

  /// They are on the map right now — the single best reason to go out too.
  final bool liveNow;

  @override
  Widget build(BuildContext context) {
    final iLead = me.xp >= them.xp;
    return Sticker(
      accent: iLead ? Tokens.questGreen : Tokens.streakFire,
      child: Column(
        children: [
          Row(
            children: [
              PlayerAvatar(
                avatar: them.avatar,
                photoUrl: them.photoUrl,
                size: 34,
                ring: liveNow ? Tokens.duelViolet : null,
              ),
              const SizedBox(width: Tokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You vs ${them.displayName}',
                      style: display(size: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (liveNow)
                      Text(
                        'Out playing right now',
                        style: ui(size: 11, color: Tokens.duelViolet),
                      ),
                  ],
                ),
              ),
              Text(
                iLead ? 'Leading' : 'Behind',
                style: label(
                  color: iLead ? Tokens.questGreenDeep : Tokens.streakFire,
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
              color: iWin ? Tokens.questGreenDeep : Tokens.inkDim,
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
              color: iWin ? Tokens.inkDim : Tokens.streakFire,
            ),
          ),
        ),
      ],
    ),
  );
}


/// A sticker, not a Material chip — the whole app is made of one shape.
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.s16),
        decoration: Tokens.card(
          fill: selected ? Tokens.questGreen : Tokens.paper,
          radius: Tokens.rPill,
          offset: selected ? 3 : 2,
        ),
        child: Text(
          label,
          style: display(size: 15, color: selected ? Tokens.ink : Tokens.inkDim),
        ),
      ),
    ),
  );
}
