import 'package:flutter/material.dart';

import 'models.dart';
import 'theme/tokens.dart';

/// Uppercase section header.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.s12),
    child: Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: label())),
        ?trailing,
      ],
    ),
  );
}

/// A single metric. One hero number, a caption, nothing else.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.caption,
    this.color = Tokens.bone,
    this.icon,
    super.key,
  });

  final String value;
  final String caption;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Tokens.s16),
    decoration: BoxDecoration(
      color: Tokens.forestSurface,
      borderRadius: BorderRadius.circular(Tokens.rCard),
      border: Border.all(color: Tokens.forestLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: Tokens.s8),
        ],
        Text(value, style: display(size: 26, color: color)),
        const SizedBox(height: Tokens.s4),
        Text(caption.toUpperCase(), style: label()),
      ],
    ),
  );
}

/// Level + XP progress. Always a filled bar with the numbers beside it.
class LevelBar extends StatelessWidget {
  const LevelBar(this.profile, {super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('LEVEL ${profile.level}', style: label(color: Tokens.questGreen)),
          const Spacer(),
          Text(
            '${formatCount(profile.xpIntoLevel)} / ${formatCount(profile.xpForNextLevel)} XP',
            style: ui(size: 13, color: Tokens.boneDim),
          ),
        ],
      ),
      const SizedBox(height: Tokens.s8),
      ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.rPill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: profile.levelProgress),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 400),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Tokens.forestLine,
            valueColor: const AlwaysStoppedAnimation(Tokens.questGreen),
          ),
        ),
      ),
    ],
  );
}

/// Streak pill. Turns to a warning once the streak is one day from lost.
class StreakChip extends StatelessWidget {
  const StreakChip(this.streak, {super.key});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final atRisk = streak.lastActionDay != Streak.dayKey(DateTime.now()) &&
        streak.current > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.s12,
        vertical: Tokens.s8,
      ),
      decoration: BoxDecoration(
        color: Tokens.streakFire.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Tokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 16, color: Tokens.streakFire),
          const SizedBox(width: Tokens.s4),
          Text(
            atRisk ? '${streak.current} · act today' : '${streak.current}',
            style: ui(size: 13, weight: FontWeight.w600, color: Tokens.streakFire),
          ),
        ],
      ),
    );
  }
}

/// Sponsored quests always carry a visible label — never blurred into the UI.
class SponsorChip extends StatelessWidget {
  const SponsorChip(this.sponsor, {super.key});

  final String sponsor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.s8, vertical: 3),
    decoration: BoxDecoration(
      border: Border.all(color: Tokens.forestLine),
      borderRadius: BorderRadius.circular(Tokens.rPill),
    ),
    child: Text('Sponsored by $sponsor', style: ui(size: 11, color: Tokens.boneDim)),
  );
}

/// Marks anything the AI didn't verify. Never counted in city totals.
class SelfReportedChip extends StatelessWidget {
  const SelfReportedChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.s8, vertical: 3),
    decoration: BoxDecoration(
      color: Tokens.forestLine,
      borderRadius: BorderRadius.circular(Tokens.rPill),
    ),
    child: Text('Self-reported', style: ui(size: 11, color: Tokens.boneDim)),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.title, this.body, super.key});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Tokens.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: Tokens.forestLine),
          const SizedBox(height: Tokens.s16),
          Text(title, style: display(size: 20), textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              body!,
              style: ui(color: Tokens.boneDim),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ),
  );
}

/// One leaderboard row.
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    required this.rank,
    required this.player,
    required this.isMe,
    super.key,
  });

  final int rank;
  final UserProfile player;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => Tokens.gold,
      2 || 3 => Tokens.bone,
      _ => Tokens.boneDim,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.s16,
        vertical: Tokens.s12,
      ),
      decoration: BoxDecoration(
        color: isMe ? Tokens.questGreen.withValues(alpha: 0.10) : Tokens.forestSurface,
        borderRadius: BorderRadius.circular(Tokens.rCard),
        border: Border.all(
          color: isMe ? Tokens.questGreen : Tokens.forestLine,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rank', style: display(size: 18, color: rankColor)),
          ),
          const SizedBox(width: Tokens.s8),
          CircleAvatar(
            radius: 18,
            backgroundColor: Tokens.forestLine,
            backgroundImage:
                player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
            child: player.photoUrl == null
                ? Text(
                    player.displayName.characters.first.toUpperCase(),
                    style: display(size: 15),
                  )
                : null,
          ),
          const SizedBox(width: Tokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: ui(size: 15, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatCount(player.itemsCollected)} items · '
                  'Lv ${player.level}',
                  style: ui(size: 12, color: Tokens.boneDim),
                ),
              ],
            ),
          ),
          Text('${formatCount(player.xp)} XP', style: display(size: 16)),
        ],
      ),
    );
  }
}

/// Draws the detector's boxes over the photo, so the user can see exactly what
/// the AI saw. A black-box "approved" invites distrust; a labelled box invites
/// bragging.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    required this.imageSize,
    required this.detections,
    super.key,
  });

  final Size imageSize;
  final List<Detection> detections;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BoxPainter(imageSize, detections),
    size: Size.infinite,
  );
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.imageSize, this.detections);

  final Size imageSize;
  final List<Detection> detections;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty) return;
    // Matches BoxFit.contain on the Image widget above the overlay.
    final scale = (size.width / imageSize.width) < (size.height / imageSize.height)
        ? size.width / imageSize.width
        : size.height / imageSize.height;
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    for (final d in detections) {
      final color = Tokens.bin(d.cls.name);
      final rect = Rect.fromLTRB(
        d.box.left * scale + dx,
        d.box.top * scale + dy,
        d.box.right * scale + dx,
        d.box.bottom * scale + dy,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final text = TextPainter(
        text: TextSpan(
          text: ' ${d.cls.displayName} ${(d.confidence * 100).round()}% ',
          style: ui(
            size: 11,
            weight: FontWeight.w600,
            color: Tokens.deepForest,
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Label sits above the box, or inside it when there's no room on top.
      final labelTop = rect.top - text.height >= 0 ? rect.top - text.height : rect.top;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rect.left, labelTop, text.width, text.height),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      text.paint(canvas, Offset(rect.left, labelTop));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.detections != detections || old.imageSize != imageSize;
}

/// Thin-space thousands separators, per BRANDING.md §4.
String formatCount(int n) {
  final s = n.abs().toString();
  final buffer = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('\u2009');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
