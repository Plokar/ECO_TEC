import 'package:flutter/material.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// First run: what the app is, how the loop works, and the two settings that
/// are useless to ask for later — a face and a home city.
///
/// Shown once, gated on `profile.onboarded`. Everything it collects is optional
/// except the avatar, which already has a value, so a player who taps through
/// without reading still lands on a working profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.profile, this.replay = false, super.key});

  final UserProfile profile;

  /// Re-opened from the profile screen rather than shown on first run: the
  /// setup page is dropped, since those settings live in the profile already.
  final bool replay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  final _city = TextEditingController();

  late Avatar _avatar = widget.profile.avatar;
  late String _name = widget.profile.displayName;
  bool _shareLocation = false;
  bool _saving = false;
  int _page = 0;

  late final List<_Lesson> _lessons = [
    _Lesson(
      art: '🌍',
      tint: Tokens.sky,
      title: 'Real rubbish,\nreal points',
      body:
          'EcoQuest turns picking up litter into a game you play outside. '
          'Every piece you collect is worth XP, EcoPoints and a measured bit '
          'of CO₂ kept out of the air.',
      chips: ['Free to play', 'No ads in the loop'],
    ),
    _Lesson(
      art: '📸',
      tint: Tokens.questGreen,
      title: 'Snap it\nto claim it',
      body:
          'Point the camera at litter and shoot. The app checks the photo on '
          'your phone — not in the cloud — and draws a box around everything it '
          'recognises. You see exactly what it counted before you claim.',
      chips: ['Works offline', 'Photo never leaves unless you claim'],
    ),
    _Lesson(
      art: '💎',
      tint: Tokens.duelViolet,
      title: 'Some rubbish\nis rare',
      body:
          'Every item you pick up rolls a rarity. Commons are the bread and '
          'butter; a Legendary is worth eight times as much and is the kind of '
          'thing you send your friends a screenshot of.',
      rarityStrip: true,
      chips: ['Metal and glass roll luckier'],
    ),
    _Lesson(
      art: '🗺️',
      tint: Tokens.streakFire,
      title: 'The map is\nthe game board',
      body:
          'Litter you cannot carry, you tag: photograph it and it drops a pin '
          'for everyone else. Clear somebody else\'s pin and it disappears off '
          'the map. Friends who opt in show up as their avatar, live.',
      chips: ['Spot litter', 'Clear pins', 'See friends'],
    ),
    _Lesson(
      art: '🏆',
      tint: Tokens.gold,
      title: 'Then beat\nyour city',
      body:
          'Your verified pickups feed your friends board, your school, your '
          'city and your country. EcoPoints buy real rewards from local '
          'partners in the shop.',
      chips: ['Friends', 'School', 'City', 'Country'],
    ),
  ];

  int get _lastPage => widget.replay ? _lessons.length - 1 : _lessons.length;

  @override
  void dispose() {
    _pages.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await data.updateProfile(
        widget.profile.uid,
        displayName: _name.trim().isEmpty ? null : _name.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        avatar: _avatar,
        shareLocation: _shareLocation,
        onboarded: true,
      );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save that: $e')));
    }
  }

  void _next() {
    if (_page >= _lastPage) {
      widget.replay ? Navigator.of(context).maybePop() : _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSetup = _page == _lessons.length;
    return Paper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.s16,
                  Tokens.s8,
                  Tokens.s16,
                  0,
                ),
                child: Row(
                  children: [
                    const Wordmark(size: 22),
                    const Spacer(),
                    // Skipping is allowed and obvious. A tutorial you cannot
                    // leave is the fastest way to lose someone on day one.
                    if (!onSetup)
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => widget.replay
                                  ? Navigator.of(context).maybePop()
                                  : _pages.jumpToPage(_lessons.length),
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final lesson in _lessons) _LessonPage(lesson: lesson),
                    if (!widget.replay)
                      _SetupPage(
                        avatar: _avatar,
                        name: _name,
                        city: _city,
                        shareLocation: _shareLocation,
                        onAvatar: (a) => setState(() => _avatar = a),
                        onName: (n) => _name = n,
                        onShare: (v) => setState(() => _shareLocation = v),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Tokens.s16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i <= _lastPage; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 10,
                            width: i == _page ? 26 : 10,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? Tokens.questGreen
                                  : Tokens.pageSubtle,
                              borderRadius: BorderRadius.circular(Tokens.rPill),
                              border: Border.all(color: Tokens.ink, width: 2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Tokens.s16),
                    FilledButton(
                      onPressed: _saving ? null : _next,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Tokens.ink,
                              ),
                            )
                          : Text(
                              _page < _lastPage
                                  ? 'Next'
                                  : widget.replay
                                  ? 'Done'
                                  : 'Start playing',
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Lesson {
  const _Lesson({
    required this.art,
    required this.tint,
    required this.title,
    required this.body,
    this.chips = const [],
    this.rarityStrip = false,
  });

  final String art;
  final Color tint;
  final String title;
  final String body;
  final List<String> chips;
  final bool rarityStrip;
}

class _LessonPage extends StatelessWidget {
  const _LessonPage({required this.lesson});

  final _Lesson lesson;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(Tokens.s24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Tokens.s16),
        Sticker(
          fill: lesson.tint,
          tilt: -1.4,
          accent: Tokens.ink,
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.s32,
            vertical: Tokens.s24,
          ),
          child: Text(lesson.art, style: const TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: Tokens.s24),
        Text(lesson.title, style: display(size: 38)),
        const SizedBox(height: Tokens.s12),
        Text(lesson.body, style: ui(size: 16, color: Tokens.inkDim)),
        if (lesson.rarityStrip) ...[
          const SizedBox(height: Tokens.s16),
          Column(
            children: [
              for (final r in Rarity.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Tokens.s8),
                  child: Row(
                    children: [
                      RarityBadge(r),
                      const Spacer(),
                      Text(r.odds, style: ui(size: 12, color: Tokens.inkDim)),
                    ],
                  ),
                ),
            ],
          ),
        ],
        if (lesson.chips.isNotEmpty) ...[
          const SizedBox(height: Tokens.s16),
          Wrap(
            spacing: Tokens.s8,
            runSpacing: Tokens.s8,
            children: [
              for (final chip in lesson.chips)
                Pill(chip, color: Tokens.pageSubtle),
            ],
          ),
        ],
        const SizedBox(height: Tokens.s24),
      ],
    ),
  );
}

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.avatar,
    required this.name,
    required this.city,
    required this.shareLocation,
    required this.onAvatar,
    required this.onName,
    required this.onShare,
  });

  final Avatar avatar;
  final String name;
  final TextEditingController city;
  final bool shareLocation;
  final ValueChanged<Avatar> onAvatar;
  final ValueChanged<String> onName;
  final ValueChanged<bool> onShare;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      Tokens.s24,
      Tokens.s16,
      Tokens.s24,
      MediaQuery.viewInsetsOf(context).bottom + Tokens.s24,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Make yourself', style: display(size: 34)),
        const SizedBox(height: Tokens.s8),
        Text(
          'This is the face your friends see on the map and on the boards. '
          'You can change all of it later.',
          style: ui(size: 15, color: Tokens.inkDim),
        ),
        const SizedBox(height: Tokens.s24),
        AvatarPicker(avatar: avatar, onChanged: onAvatar),
        const SizedBox(height: Tokens.s24),
        // The only place the app asks for a name. Sign-up pre-fills it from the
        // email address, so this is never blank and clearing it keeps that.
        TextFormField(
          initialValue: name,
          onChanged: onName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
            helperText: 'How you appear on every leaderboard.',
          ),
        ),
        const SizedBox(height: Tokens.s12),
        TextField(
          controller: city,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'City',
            helperText: 'Decides which city league you play for.',
          ),
        ),
        const SizedBox(height: Tokens.s16),
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
                    value: shareLocation,
                    onChanged: onShare,
                    activeThumbColor: Tokens.ink,
                    activeTrackColor: Tokens.questGreen,
                  ),
                ],
              ),
              const SizedBox(height: Tokens.s8),
              Text(
                'Off by default. Only people on your friends list ever see your '
                'position, it stops being shown two hours after you last moved, '
                'and turning this off deletes it.',
                style: ui(size: 13, color: Tokens.inkDim),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Two rows of taps: a creature and a background. No upload, no camera roll
/// permission, no moderation queue — and it renders the same with no signal.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({required this.avatar, required this.onChanged, super.key});

  final Avatar avatar;
  final ValueChanged<Avatar> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(child: PlayerAvatar(avatar: avatar, size: 96)),
      const SizedBox(height: Tokens.s16),
      Text('CHARACTER', style: label()),
      const SizedBox(height: Tokens.s8),
      Wrap(
        spacing: Tokens.s8,
        runSpacing: Tokens.s8,
        children: [
          for (final face in Avatar.faces)
            _Choice(
              selected: face == avatar.face,
              onTap: () => onChanged(Avatar(face, avatar.tint)),
              label: face,
              child: Text(face, style: const TextStyle(fontSize: 24)),
            ),
        ],
      ),
      const SizedBox(height: Tokens.s16),
      Text('BACKGROUND', style: label()),
      const SizedBox(height: Tokens.s8),
      Wrap(
        spacing: Tokens.s8,
        runSpacing: Tokens.s8,
        children: [
          for (final tint in Avatar.tints)
            _Choice(
              selected: tint == avatar.tint,
              onTap: () => onChanged(Avatar(avatar.face, tint)),
              label: tint,
              child: Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: Tokens.tint(tint),
                  shape: BoxShape.circle,
                  border: Border.all(color: Tokens.ink, width: 2),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.child,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        // 48dp: chosen while walking, one-handed.
        height: 48,
        width: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Tokens.questGreen : Tokens.paper,
          borderRadius: BorderRadius.circular(Tokens.rChip),
          border: Border.all(
            color: Tokens.ink,
            width: selected ? Tokens.stroke : 2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Tokens.ink,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    ),
  );
}
