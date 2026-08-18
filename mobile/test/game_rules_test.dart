// The rules that decide what a player earns. Everything here is pure — no
// Firebase, no camera — so it runs with `flutter test` in under a second.
import 'dart:ui' show Rect;

import 'package:ecoquest/models.dart';
import 'package:ecoquest/screens/streak_calendar.dart';
import 'package:ecoquest/services/auth.dart';
import 'package:ecoquest/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile profileWith({
  int xp = 0,
  int ecoPoints = 0,
  Map<String, int> classCounts = const {},
  Map<String, int> rarityCounts = const {},
  Streak streak = const Streak(current: 0, longest: 0),
  bool shareLocation = false,
}) => UserProfile(
  uid: 'u1',
  displayName: 'Test',
  xp: xp,
  ecoPoints: ecoPoints,
  streak: streak,
  classCounts: classCounts,
  rarityCounts: rarityCounts,
  co2SavedG: 0,
  friends: const [],
  avatar: Avatar.fallback,
  onboarded: true,
  shareLocation: shareLocation,
);

Presence presenceAt(DateTime at) => Presence(
  uid: 'u2',
  displayName: 'Friend',
  avatar: Avatar.fallback,
  lat: 52.0,
  lng: 4.9,
  at: at,
);

LitterClass clsWith({String name = 'plastic', int points = 3}) => LitterClass(
  id: 0,
  name: name,
  points: points,
  bin: name,
  co2g: 40,
);

void main() {
  group('Streak.advance', () {
    final tuesday = DateTime(2026, 8, 18);

    test('first ever action starts the streak at 1', () {
      final s = const Streak(current: 0, longest: 0).advance(tuesday);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.lastActionDay, '2026-08-18');
    });

    test('a second action the same day changes nothing', () {
      final first = const Streak(current: 0, longest: 0).advance(tuesday);
      final second = first.advance(tuesday.add(const Duration(hours: 6)));
      expect(second.current, 1, reason: 'one action per day is what counts');
      expect(second.lastActionDay, first.lastActionDay);
    });

    test('acting on consecutive days continues the streak', () {
      var s = const Streak(current: 0, longest: 0);
      for (var i = 0; i < 5; i++) {
        s = s.advance(tuesday.add(Duration(days: i)));
      }
      expect(s.current, 5);
      expect(s.longest, 5);
    });

    test('skipping a day restarts at 1 but keeps the record', () {
      final built = const Streak(current: 9, longest: 9, lastActionDay: '2026-08-16');
      final after = built.advance(tuesday); // 16th -> 18th, the 17th was missed
      expect(after.current, 1);
      expect(after.longest, 9, reason: 'longest is a record, not a current value');
    });

    test('crossing a month boundary still counts as consecutive', () {
      final s = const Streak(current: 3, longest: 3, lastActionDay: '2026-07-31')
          .advance(DateTime(2026, 8, 1));
      expect(s.current, 4);
    });

    test('isBrokenOn only fires once the gap is real', () {
      final yesterday =
          const Streak(current: 4, longest: 4, lastActionDay: '2026-08-17');
      expect(yesterday.isBrokenOn(tuesday), isFalse, reason: 'still today to act');

      final older =
          const Streak(current: 4, longest: 4, lastActionDay: '2026-08-15');
      expect(older.isBrokenOn(tuesday), isTrue);
    });
  });

  group('level curve', () {
    test('thresholds match 125·N·(N−1)', () {
      expect(UserProfile.xpForLevel(1), 0);
      expect(UserProfile.xpForLevel(2), 250);
      expect(UserProfile.xpForLevel(3), 750);
      expect(UserProfile.xpForLevel(10), 11250);
    });

    test('xp inverts back to the right level, including on the boundary', () {
      expect(profileWith(xp: 0).level, 1);
      expect(profileWith(xp: 249).level, 1);
      expect(profileWith(xp: 250).level, 2, reason: 'exact threshold levels up');
      expect(profileWith(xp: 749).level, 2);
      expect(profileWith(xp: 750).level, 3);
      expect(profileWith(xp: 11250).level, 10);
    });

    test('progress runs 0..1 within a level', () {
      expect(profileWith(xp: 250).levelProgress, 0.0);
      expect(profileWith(xp: 500).levelProgress, closeTo(0.5, 1e-9));
      expect(profileWith(xp: 749).levelProgress, lessThan(1.0));
    });
  });

  group('EcoScore', () {
    test('rewards variety, not just volume', () {
      final grinder = profileWith(classCounts: const {'plastic': 40});
      final rounded = profileWith(
        classCounts: const {'plastic': 10, 'glass': 10, 'metal': 10, 'paper': 10},
      );
      expect(rounded.itemsCollected, grinder.itemsCollected);
      expect(
        rounded.ecoScore,
        greaterThan(grinder.ecoScore),
        reason: 'same item count, more categories, should score higher',
      );
    });

    test('never exceeds 1000', () {
      final whale = profileWith(
        xp: 999999,
        ecoPoints: 999999,
        classCounts: const {'plastic': 99999},
        streak: const Streak(current: 900, longest: 900),
      );
      expect(whale.ecoScore, 1000);
    });
  });

  group('Quest.counts', () {
    test('an empty target list accepts any litter', () {
      const q = Quest(
        id: 'q',
        title: 'Anything',
        description: '',
        targetClasses: [],
        targetCount: 3,
        xpReward: 100,
        pointsReward: 10,
        verification: Verification.aiPhoto,
      );
      expect(q.counts('plastic'), isTrue);
      expect(q.counts('cigarette'), isTrue);
    });

    test('a target list filters everything else out', () {
      const q = Quest(
        id: 'q',
        title: 'Bottles only',
        description: '',
        targetClasses: ['plastic', 'glass'],
        targetCount: 5,
        xpReward: 150,
        pointsReward: 25,
        verification: Verification.aiPhoto,
      );
      expect(q.counts('plastic'), isTrue);
      expect(q.counts('glass'), isTrue);
      expect(q.counts('metal'), isFalse);
    });
  });

  group('formatCount', () {
    test('groups thousands and leaves small numbers alone', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1\u2009000');
      expect(formatCount(14820), '14\u2009820');
      expect(formatCount(1234567), '1\u2009234\u2009567');
    });

    test('keeps the sign outside the grouping', () {
      expect(formatCount(-4820), '-4\u2009820');
    });
  });

  group('Rarity.roll', () {
    final plastic = clsWith(points: 3);

    test('is deterministic in the seed and the index', () {
      final first = Rarity.roll('photo-1', 0, plastic);
      final second = Rarity.roll('photo-1', 0, plastic);
      expect(second, first, reason: 'a retake must not be able to reroll');
    });

    test('different items in one photo roll independently', () {
      final rolls = {
        for (var i = 0; i < 40; i++) Rarity.roll('photo-1', i, plastic),
      };
      expect(rolls.length, greaterThan(1));
    });

    test('the distribution is roughly the odds the UI promises', () {
      final counts = <Rarity, int>{};
      for (var i = 0; i < 4000; i++) {
        final r = Rarity.roll('seed-$i', i % 7, plastic);
        counts[r] = (counts[r] ?? 0) + 1;
      }
      // Loose bounds: this asserts the roll is not degenerate, not that the
      // generator hits an exact figure.
      expect(counts[Rarity.common]! / 4000, closeTo(0.5, 0.15));
      expect(counts[Rarity.legendary] ?? 0, greaterThan(0));
      expect((counts[Rarity.legendary] ?? 0) / 4000, lessThan(0.05));
    });

    test('valuable materials roll luckier than cheap ones', () {
      var metalRare = 0;
      var organicRare = 0;
      final metal = clsWith(name: 'metal', points: 5);
      final organic = clsWith(name: 'organic', points: 1);
      for (var i = 0; i < 3000; i++) {
        if (Rarity.roll('s$i', 0, metal).isBoasted) metalRare++;
        if (Rarity.roll('s$i', 0, organic).isBoasted) organicRare++;
      }
      expect(metalRare, greaterThan(organicRare));
    });
  });

  group('Detection worth', () {
    test('rarity multiplies points and xp, and common changes nothing', () {
      const box = Rect.fromLTWH(0, 0, 10, 10);
      final common = Detection(cls: clsWith(points: 4), confidence: 0.9, box: box);
      final epic = Detection(
        cls: clsWith(points: 4),
        confidence: 0.9,
        box: box,
        rarity: Rarity.epic,
      );
      expect(common.points, 4);
      expect(common.xp, 10);
      expect(epic.points, 16);
      expect(epic.xp, 40);
    });
  });

  group('Avatar', () {
    test('round-trips through its encoded form', () {
      const a = Avatar('🦊', 'violet');
      expect(Avatar.parse(a.encoded).encoded, a.encoded);
    });

    test('falls back rather than throwing on junk', () {
      expect(Avatar.parse(null).encoded, Avatar.fallback.encoded);
      expect(Avatar.parse('nonsense').encoded, Avatar.fallback.encoded);
      expect(Avatar.parse('👽|neon').encoded, Avatar.fallback.encoded);
    });

    test('seeding is stable and spreads across the roster', () {
      expect(Avatar.seeded('uid-1').encoded, Avatar.seeded('uid-1').encoded);
      final faces = {for (var i = 0; i < 60; i++) Avatar.seeded('uid-$i').face};
      expect(faces.length, greaterThan(3));
    });
  });

  group('Presence.isFresh', () {
    final now = DateTime.now();

    test('a just-published position is shown', () {
      expect(presenceAt(now).isFresh, isTrue);
      expect(presenceAt(now.subtract(const Duration(minutes: 30))).isFresh, isTrue);
    });

    test('a stale one is not', () {
      expect(
        presenceAt(now.subtract(const Duration(hours: 5))).isFresh,
        isFalse,
        reason: 'a five-hour-old dot is a lie about where somebody is',
      );
    });
  });

  group('bestFind', () {
    test('reports the rarest rarity actually pulled', () {
      expect(
        profileWith(rarityCounts: const {'common': 9, 'rare': 1}).bestFind,
        Rarity.rare,
      );
      expect(profileWith().bestFind, Rarity.common);
    });
  });

  group('streak calendar', () {
    Map<String, dynamic> sub(String isoDay, {bool met = true}) => {
      'targetMet': met,
      'clientTime': DateTime(
        int.parse(isoDay.split('-')[0]),
        int.parse(isoDay.split('-')[1]),
        int.parse(isoDay.split('-')[2]),
        12, // midday, so a UTC round-trip cannot fall into the day next door
      ).toUtc().toIso8601String(),
    };

    test('only days that met the target count', () {
      final days = activeDays([
        sub('2026-03-01'),
        sub('2026-03-02', met: false),
        sub('2026-03-01'), // two quests, one day
      ]);
      expect(days, {DateTime(2026, 3, 1)});
    });

    test('consecutive days group into one run', () {
      final runs = streakRuns(activeDays([
        for (final d in ['2026-03-01', '2026-03-02', '2026-03-03']) sub(d),
        sub('2026-03-06'),
      ]));
      expect(runs.map((r) => r.length), [3, 1]);
      expect(runs.first.first, DateTime(2026, 3, 1));
      expect(runs.first.last, DateTime(2026, 3, 3));
    });

    test('runs cross month and year ends', () {
      final runs = streakRuns(activeDays([
        sub('2025-12-31'),
        sub('2026-01-01'),
      ]));
      expect(runs.single.length, 2);
    });
  });

  group('provisional name from email', () {
    test('reads as a name, not as an address', () {
      expect(AuthService.nameFromEmail('sebastian.borik@x.com'), 'Sebastian borik');
      expect(AuthService.nameFromEmail('  ana_novak@x.com '), 'Ana novak');
      expect(AuthService.nameFromEmail('jo+ecoquest@x.com'), 'Jo');
    });

    test('never returns an empty name', () {
      expect(AuthService.nameFromEmail('@x.com'), 'Player');
      expect(AuthService.nameFromEmail('...@x.com'), 'Player');
    });

    test('a silly-long address is cut, not shipped whole', () {
      expect(AuthService.nameFromEmail('${'a' * 60}@x.com').length, 24);
    });
  });

  group('shipped label file', () {
    // rootBundle serves the real assets in a widget test, so this checks the
    // file that actually ships rather than a fixture that drifts away from it.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('parses, and says which coordinate space the boxes are in', () async {
      final labels = await LabelSet.load();

      expect(labels.modelAsset, 'assets/models/ecoquest_yolo26n.tflite');
      expect(labels.imgsz, 640);
      expect(labels.classes.map((c) => c.name), [
        'plastic',
        'glass',
        'metal',
        'paper',
        'cigarette',
        'other_litter',
      ]);
      // The TFLite export returns 0..1 and the decoder multiplies by imgsz.
      // If a re-export ever changes this, the boxes move — so it is asserted,
      // not assumed.
      expect(labels.normalized, isTrue);
    });

    test('the test-only COCO labels agree about that space', () async {
      final coco = await LabelSet.load('assets/models/coco_labels.json');
      expect(coco.modelAsset, 'assets/models/coco_yolo26n.tflite');
      expect(coco.normalized, isTrue);
      // Sparse COCO ids: 39 is a bottle, 0 is a person and must not resolve.
      expect(coco.byId(39)?.name, 'plastic');
      expect(coco.byId(0), isNull);
    });
  });
}
