import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'screens/capture.dart';
import 'screens/home.dart';
import 'screens/map.dart';
import 'screens/onboarding.dart';
import 'screens/profile.dart';
import 'screens/sign_in.dart';
import 'screens/social.dart';
import 'theme/tokens.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline persistence is what makes "reward instantly, sync later" work:
  // queued writes survive a walk through a park with no signal.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const EcoQuestApp());
}

class EcoQuestApp extends StatelessWidget {
  const EcoQuestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EcoQuest',
    debugShowCheckedModeBanner: false,
    theme: ecoQuestTheme(),
    // The grain sits behind every route at once, so it never seams at a screen
    // boundary or restarts mid-transition.
    builder: (context, child) => Paper(child: child ?? const SizedBox.shrink()),
    home: const _AuthGate(),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: auth.changes,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _Splash();
      }
      final user = snapshot.data;
      if (user == null) return const SignInScreen();
      return HomeShell(uid: user.uid);
    },
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Wordmark(size: 44),
          const SizedBox(height: Tokens.s32),
          const _SpinningFlower(),
        ],
      ),
    ),
  );
}

/// The wordmark's flower, turning. Cheaper to read than a progress ring and it
/// is the one piece of motion every cold start shows.
class _SpinningFlower extends StatefulWidget {
  const _SpinningFlower();

  @override
  State<_SpinningFlower> createState() => _SpinningFlowerState();
}

class _SpinningFlowerState extends State<_SpinningFlower>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _spin, child: const Flower(size: 48));
}

/// Bottom-nav shell. The profile stream lives here so every tab reads the same
/// live player state instead of each one fetching its own.
///
/// Four destinations, not five: the shop moved onto the home screen behind the
/// EcoPoints balance, which is where a player looks for it anyway, and that
/// bought enough width for the labels to stop colliding with the shutter.
class HomeShell extends StatefulWidget {
  const HomeShell({required this.uid, super.key});

  final String uid;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  /// Tabs the user has actually opened.
  ///
  /// IndexedStack builds every child eagerly, which meant MapScreen ran its
  /// initState — and fired the location permission prompt — the moment anyone
  /// signed in, before they had gone anywhere near the map. Unvisited tabs are
  /// stubbed out until first use, so permissions are asked for in context and
  /// the map and league streams don't open until someone wants them.
  final _visited = <int>{0};

  void _select(int index) => setState(() {
    _tab = index;
    _visited.add(index);
  });

  Widget _tabAt(int index, UserProfile profile) => switch (index) {
    0 => HomeScreen(profile: profile),
    1 => MapScreen(profile: profile),
    2 => SocialScreen(profile: profile),
    _ => ProfileScreen(profile: profile),
  };

  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile>(
    stream: data.profile(widget.uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: EmptyState(
            icon: Icons.cloud_off,
            title: 'Cannot reach your profile',
            body: '${snapshot.error}',
          ),
        );
      }
      final profile = snapshot.data;
      if (profile == null) return const _Splash();

      // First run: teach the game before showing it. Finishing writes
      // `onboarded`, which comes back down this same stream.
      if (!profile.onboarded) return OnboardingScreen(profile: profile);

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _tab,
          // Always four children so the indices keep lining up with _tab —
          // unvisited ones are just empty until they're opened.
          children: [
            for (var i = 0; i < 4; i++)
              _visited.contains(i) ? _tabAt(i, profile) : const SizedBox.shrink(),
          ],
        ),
        // One tap to the shutter, from anywhere in the app.
        floatingActionButton: Semantics(
          button: true,
          label: 'Complete a quest',
          child: Press(
            radius: Tokens.rPill,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CaptureScreen(profile: profile)),
            ),
            child: Container(
              height: 74,
              width: 74,
              alignment: Alignment.center,
              decoration: Tokens.card(
                fill: Tokens.questGreen,
                radius: Tokens.rPill,
              ),
              child: const Icon(Icons.camera_alt, size: 32, color: Tokens.ink),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          height: 78,
          decoration: const BoxDecoration(
            color: Tokens.paper,
            border: Border(
              top: BorderSide(color: Tokens.ink, width: Tokens.stroke),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(
                  icon: Icons.bolt,
                  caption: 'Quests',
                  selected: _tab == 0,
                  onTap: () => _select(0),
                ),
                _NavIcon(
                  icon: Icons.map_outlined,
                  caption: 'Map',
                  selected: _tab == 1,
                  onTap: () => _select(1),
                ),
                // The FAB is 74dp wide; a narrower gap than this and it sits on
                // top of the neighbouring nav labels.
                const SizedBox(width: 86),
                _NavIcon(
                  icon: Icons.groups_outlined,
                  caption: 'Friends',
                  selected: _tab == 2,
                  onTap: () => _select(2),
                ),
                _NavIcon(
                  icon: Icons.person_outline,
                  caption: 'You',
                  selected: _tab == 3,
                  onTap: () => _select(3),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: caption,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.rCard),
      child: Container(
        // >= 48dp touch target, walking, one-handed, gloves in winter.
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.s12,
                vertical: 3,
              ),
              decoration: selected ? Tokens.chip(Tokens.questGreen) : null,
              child: Icon(
                icon,
                color: selected ? Tokens.ink : Tokens.inkDim,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              style: ui(
                size: 10,
                weight: FontWeight.w800,
                color: selected ? Tokens.ink : Tokens.inkDim,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
