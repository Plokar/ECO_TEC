import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'screens/capture.dart';
import 'screens/home.dart';
import 'screens/map.dart';
import 'screens/profile.dart';
import 'screens/rewards.dart';
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
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

/// Bottom-nav shell. The profile stream lives here so every tab reads the same
/// live player state instead of each one fetching its own.
class HomeShell extends StatefulWidget {
  const HomeShell({required this.uid, super.key});

  final String uid;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => StreamBuilder<UserProfile>(
    stream: data.profile(widget.uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: EmptyState(
            icon: Icons.cloud_off,
            title: 'Can\'t reach your profile',
            body: '${snapshot.error}',
          ),
        );
      }
      final profile = snapshot.data;
      if (profile == null) return const _Splash();

      final tabs = [
        HomeScreen(profile: profile),
        MapScreen(profile: profile),
        SocialScreen(profile: profile),
        RewardsScreen(profile: profile),
        ProfileScreen(profile: profile),
      ];

      return Scaffold(
        body: IndexedStack(index: _tab, children: tabs),
        // One tap to the shutter, from anywhere in the app.
        floatingActionButton: FloatingActionButton.large(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaptureScreen(profile: profile)),
          ),
          backgroundColor: Tokens.questGreen,
          foregroundColor: Tokens.deepForest,
          shape: const CircleBorder(),
          tooltip: 'Complete a quest',
          child: const Icon(Icons.camera_alt, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Tokens.forestSurface,
          height: 70,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.bolt,
                caption: 'Quest',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavIcon(
                icon: Icons.map_outlined,
                caption: 'Map',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 56), // notch for the FAB
              _NavIcon(
                icon: Icons.leaderboard_outlined,
                caption: 'Leagues',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
              _NavIcon(
                icon: Icons.redeem_outlined,
                caption: 'Rewards',
                selected: _tab == 3,
                onTap: () => setState(() => _tab = 3),
              ),
              _NavIcon(
                icon: Icons.person_outline,
                caption: 'You',
                selected: _tab == 4,
                onTap: () => setState(() => _tab = 4),
              ),
            ],
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
  Widget build(BuildContext context) {
    final color = selected ? Tokens.questGreen : Tokens.boneDim;
    return Semantics(
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
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(caption, style: ui(size: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
