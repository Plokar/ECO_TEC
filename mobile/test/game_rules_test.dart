// The rules that decide what a player earns. Everything here is pure — no
// Firebase, no camera — so it runs with `flutter test` in under a second.
import 'package:ecoquest/models.dart';
import 'package:ecoquest/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile profileWith({
  int xp = 0,
  int ecoPoints = 0,
  Map<String, int> classCounts = const {},
  Streak streak = const Streak(current: 0, longest: 0),
}) => UserProfile(
  uid: 'u1',
  displayName: 'Test',
  xp: xp,
  ecoPoints: ecoPoints,
  streak: streak,
  classCounts: classCounts,
  co2SavedG: 0,
  friends: const [],
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
}
