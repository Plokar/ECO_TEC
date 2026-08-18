import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// The streak calendar: every day the player kept the fire alive, and the runs
/// those days add up to. Opened from the fire chip.
Future<void> showStreakCalendar(BuildContext context, UserProfile profile) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StreakSheet(profile: profile),
    );

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _prevDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

/// Days that actually counted, read back off the player's own submissions.
///
/// ponytail: derived from the last 150 submissions instead of a stored day
/// list — no new field, no new write path, no migration. Swap to a `streakDays`
/// array on the profile if anyone ever plays daily for more than five months.
Set<DateTime> activeDays(List<Map<String, dynamic>> submissions) => {
  for (final s in submissions)
    if (s['targetMet'] == true)
      if (DateTime.tryParse(s['clientTime'] as String? ?? '') case final t?)
        _day(t.toLocal()),
};

/// Consecutive days, grouped. Each inner list is one streak, oldest first.
List<List<DateTime>> streakRuns(Set<DateTime> days) {
  final sorted = days.toList()..sort();
  final runs = <List<DateTime>>[];
  for (final d in sorted) {
    if (runs.isNotEmpty && runs.last.last == _prevDay(d)) {
      runs.last.add(d);
    } else {
      runs.add([d]);
    }
  }
  return runs;
}

class _StreakSheet extends StatefulWidget {
  const _StreakSheet({required this.profile});

  final UserProfile profile;

  @override
  State<_StreakSheet> createState() => _StreakSheetState();
}

class _StreakSheetState extends State<_StreakSheet> {
  late final _subs = data.recentSubmissions(widget.profile.uid, limit: 150);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final streak = widget.profile.streak;
    final today = _day(DateTime.now());
    final atRisk =
        streak.lastActionDay != Streak.dayKey(today) && streak.current > 0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _subs,
        builder: (context, snap) {
          final days = activeDays(snap.data ?? const []);
          final runs = streakRuns(days);
          // Which day of its run each day is — that is what earns a milestone star.
          final nth = <DateTime, int>{
            for (final run in runs)
              for (final (i, d) in run.indexed) d: i + 1,
          };
          final best = runs.toList()..sort((a, b) => b.length.compareTo(a.length));

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Tokens.s24,
              Tokens.s24,
              Tokens.s24,
              Tokens.s32,
            ),
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Tokens.streakFire,
                    size: 30,
                  ),
                  const SizedBox(width: Tokens.s8),
                  Expanded(child: Text('Your streak', style: display(size: 24))),
                ],
              ),
              const SizedBox(height: Tokens.s16),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${streak.current}',
                      caption: 'day streak',
                      color: Tokens.streakFire,
                      tilt: -1,
                    ),
                  ),
                  const SizedBox(width: Tokens.s12),
                  Expanded(
                    child: StatTile(
                      value: '${streak.longest}',
                      caption: 'longest ever',
                      color: Tokens.gold,
                      tilt: 1,
                    ),
                  ),
                ],
              ),
              if (atRisk) ...[
                const SizedBox(height: Tokens.s12),
                Sticker(
                  fill: Tokens.gold,
                  padding: const EdgeInsets.all(Tokens.s12),
                  child: Text(
                    'One quest today keeps the fire going. Miss it and the '
                    'streak restarts at 1.',
                    style: ui(size: 13, weight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: Tokens.s24),

              _MonthHeader(
                month: _month,
                onStep: (by) => setState(
                  () => _month = DateTime(_month.year, _month.month + by),
                ),
              ),
              const SizedBox(height: Tokens.s12),
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(Tokens.s32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _MonthGrid(month: _month, days: days, nth: nth, today: today),

              const SizedBox(height: Tokens.s24),
              const SectionLabel('Best runs'),
              if (best.isEmpty)
                const Sticker(
                  child: EmptyState(
                    icon: Icons.local_fire_department,
                    title: 'No runs yet',
                    body: 'Finish a quest today and day one is on the board.',
                  ),
                )
              else
                for (final run in best.take(5)) _RunRow(run: run, today: today),
            ],
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onStep});

  final DateTime month;
  final void Function(int months) onStep;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final atNewest = month.year == now.year && month.month == now.month;
    return Row(
      children: [
        _Arrow(icon: Icons.chevron_left, onTap: () => onStep(-1)),
        Expanded(
          child: Text(
            DateFormat.yMMMM().format(month),
            style: display(size: 20),
            textAlign: TextAlign.center,
          ),
        ),
        _Arrow(
          icon: Icons.chevron_right,
          onTap: atNewest ? null : () => onStep(1),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: 40,
      width: 40,
      alignment: Alignment.center,
      decoration: Tokens.chip(onTap == null ? Tokens.pageSubtle : Tokens.paper),
      child: Icon(icon, color: onTap == null ? Tokens.inkDim : Tokens.ink),
    );
    return onTap == null
        ? Opacity(opacity: 0.5, child: box)
        : Press(onTap: onTap!, radius: Tokens.rPill, child: box);
  }
}

/// One month, Monday-first. Active days are fire stickers; consecutive ones are
/// chained by an ink bar, so a streak reads as a single object rather than as
/// dots you have to count.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.days,
    required this.nth,
    required this.today,
  });

  final DateTime month;
  final Set<DateTime> days;
  final Map<DateTime, int> nth;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    // Monday = 1 in Dart, so a Monday-first grid needs weekday - 1 blanks.
    final lead = DateTime(month.year, month.month).weekday - 1;
    // Day 0 of the next month is the last day of this one.
    final length = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(lead, null),
      for (var d = 1; d <= length; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(d, style: label(), textAlign: TextAlign.center),
              ),
          ],
        ),
        const SizedBox(height: Tokens.s8),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _DayCell(
                    day: cells[row * 7 + col],
                    days: days,
                    nth: nth,
                    today: today,
                    // Chains only join inside a row; a run crossing Sunday
                    // simply continues on the next line.
                    linkLeft: col > 0,
                    linkRight: col < 6,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.days,
    required this.nth,
    required this.today,
    required this.linkLeft,
    required this.linkRight,
  });

  final DateTime? day;
  final Set<DateTime> days;
  final Map<DateTime, int> nth;
  final DateTime today;
  final bool linkLeft;
  final bool linkRight;

  @override
  Widget build(BuildContext context) {
    final d = day;
    if (d == null) return const SizedBox(height: 44);

    final active = days.contains(d);
    final isToday = d == today;
    final future = d.isAfter(today);
    // Every 7th day of a run is a milestone — the thing worth coming back for.
    final milestone = active && (nth[d] ?? 0) % 7 == 0;
    final fill = milestone ? Tokens.gold : Tokens.streakFire;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active && linkLeft && days.contains(_prevDay(d)))
            const Align(alignment: Alignment.centerLeft, child: _Chain()),
          if (active && linkRight && days.contains(_nextDay(d)))
            const Align(alignment: Alignment.centerRight, child: _Chain()),
          Container(
            height: 34,
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? fill
                  : (isToday ? Tokens.paper : Colors.transparent),
              shape: BoxShape.circle,
              border: active || isToday
                  ? Border.all(
                      color: isToday ? Tokens.questGreenDeep : Tokens.ink,
                      width: isToday ? 3 : 2,
                    )
                  : null,
            ),
            child: milestone
                ? const Icon(Icons.star_rounded, size: 20, color: Tokens.ink)
                : Text(
                    '${d.day}',
                    style: ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: active
                          ? Tokens.onFill(fill)
                          : (future ? Tokens.inkDim : Tokens.ink),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The ink bar that welds two streak days together.
class _Chain extends StatelessWidget {
  const _Chain();

  @override
  Widget build(BuildContext context) =>
      Container(height: 4, width: 16, color: Tokens.ink);
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run, required this.today});

  final List<DateTime> run;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final live = run.last == today || run.last == _prevDay(today);
    final fmt = DateFormat.MMMd();
    return Padding(
      padding: const EdgeInsets.only(bottom: Tokens.s8),
      child: Sticker(
        accent: live ? Tokens.streakFire : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.s16,
          vertical: Tokens.s12,
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: live ? Tokens.streakFire : Tokens.inkDim,
            ),
            const SizedBox(width: Tokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${run.length} day${run.length == 1 ? '' : 's'}',
                    style: display(size: 18),
                  ),
                  Text(
                    run.length == 1
                        ? fmt.format(run.first)
                        : '${fmt.format(run.first)} – ${fmt.format(run.last)}',
                    style: ui(size: 12, color: Tokens.inkDim),
                  ),
                ],
              ),
            ),
            if (live) const Pill('Live', color: Tokens.streakFire),
          ],
        ),
      ),
    );
  }
}
