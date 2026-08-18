import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme/tokens.dart';

/// The flower from the wordmark. Drawn rather than shipped as an asset so it
/// can be tinted, sized and used as a bullet point.
class Flower extends StatelessWidget {
  const Flower({
    this.size = 24,
    this.petal = Tokens.questGreen,
    this.heart = Tokens.gold,
    super.key,
  });

  final double size;
  final Color petal;
  final Color heart;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _FlowerPainter(petal, heart)),
  );
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter(this.petal, this.heart);

  final Color petal;
  final Color heart;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final fill = Paint()..color = petal;
    // Ink outline, same pen as every card. Scaled so a 16px bullet flower
    // doesn't end up as a solid blob of outline.
    final line = Paint()
      ..color = Tokens.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.shortestSide / 14).clamp(1.0, 3.0);

    for (final paint in [fill, line]) {
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(i * 2 * math.pi / 5);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -r * 0.48),
            width: r * 0.76,
            height: r * 0.92,
          ),
          paint,
        );
        canvas.restore();
      }
    }
    canvas.drawCircle(c, r * 0.26, Paint()..color = heart);
    canvas.drawCircle(c, r * 0.26, line);
  }

  @override
  bool shouldRepaint(_FlowerPainter old) =>
      old.petal != petal || old.heart != heart;
}

/// The logo, drawn rather than shipped as a PNG.
///
/// `assets/brand/wordmark.png` is white letters on a hairline outline — it was
/// drawn for the old dark app and disappears on cream paper. Baloo 2 is the
/// face the wordmark itself is lettered in, so redrawing it as outlined text
/// keeps the logo, and it now works on any ground at any size.
class Wordmark extends StatelessWidget {
  const Wordmark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'EcoQuest',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _OutlinedWord('Eco', size: size),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: Flower(size: size * 0.82),
          ),
          _OutlinedWord('Quest', size: size),
        ],
      ),
    ),
  );
}

/// Fat white letters with an ink outline: the stroke pass is drawn first and
/// the fill sits exactly on top, which is the only way Flutter will outline
/// text without a shader.
class _OutlinedWord extends StatelessWidget {
  const _OutlinedWord(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Text(
        text,
        style: display(size: size).copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.1
            ..strokeJoin = StrokeJoin.round
            ..color = Tokens.ink,
        ),
      ),
      Text(text, style: display(size: size, color: Tokens.paper)),
    ],
  );
}

/// Cream paper with the site's two-dot grain. One widget behind the whole app
/// rather than a background on every screen, so it never seams at a boundary.
class Paper extends StatelessWidget {
  const Paper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Tokens.page),
    child: CustomPaint(painter: const _GrainPainter(), child: child),
  );
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Tokens.ink.withValues(alpha: 0.05);
    // Two offset lattices at 22px, the same figure the site uses. Drawn as
    // points in one call rather than per-circle, so a full-screen grain is a
    // single draw op instead of a few thousand.
    final points = <Offset>[];
    for (var y = 0.0; y < size.height; y += 22) {
      for (var x = 0.0; x < size.width; x += 22) {
        points.add(Offset(x, y));
        points.add(Offset(x + 11, y + 11));
      }
    }
    canvas.drawPoints(PointMode.points, points, dot..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// A card cut out and stuck down: fat ink outline, hard shadow, no blur. Every
/// surface in the app is one of these.
class Sticker extends StatelessWidget {
  const Sticker({
    required this.child,
    this.fill = Tokens.paper,
    this.accent,
    this.padding = const EdgeInsets.all(Tokens.s16),
    this.radius = Tokens.rCard,
    this.tilt = 0,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color fill;

  /// Colours the drop shadow — use it to mark the one card that matters.
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Degrees off square. Nothing in this app sits perfectly straight; keep it
  /// under ~1.5° or the text starts to look broken rather than hand-placed.
  final double tilt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: Tokens.card(fill: fill, accent: accent, radius: radius),
      child: child,
    );
    final tapped = onTap == null
        ? card
        : Press(onTap: onTap!, radius: radius, child: card);
    return tilt == 0
        ? tapped
        : Transform.rotate(angle: tilt * math.pi / 180, child: tapped);
  }
}

/// Anything sticker-shaped physically depresses instead of changing colour —
/// the site's `press` utility, ported.
class Press extends StatefulWidget {
  const Press({
    required this.child,
    required this.onTap,
    this.radius = Tokens.rCard,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        offset: _down && !still ? const Offset(0.012, 0.012) : Offset.zero,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// A solid label with an ink outline. Reads at arm's length in sunlight.
class Pill extends StatelessWidget {
  const Pill(this.text, {this.color = Tokens.questGreen, this.icon, super.key});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final on = Tokens.onFill(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.s12, vertical: 6),
      decoration: Tokens.chip(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: on),
            const SizedBox(width: Tokens.s4),
          ],
          Text(text, style: display(size: 14, color: on)),
        ],
      ),
    );
  }
}

/// A player's face: emoji on a tinted, outlined disc. Used everywhere a person
/// appears — leaderboards, friend lists, and their dot on the map.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    required this.avatar,
    this.size = 44,
    this.photoUrl,
    this.ring,
    super.key,
  });

  final Avatar avatar;
  final double size;

  /// An uploaded photo wins over the drawn avatar when a profile has one.
  final String? photoUrl;

  /// Outline colour, for marking "this is you" or "this friend is live".
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    height: size,
    width: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Tokens.tint(avatar.tint),
      shape: BoxShape.circle,
      border: Border.all(color: ring ?? Tokens.ink, width: size < 32 ? 2 : 3),
      image: photoUrl == null
          ? null
          : DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover),
    ),
    child: photoUrl != null
        ? null
        : Text(avatar.face, style: TextStyle(fontSize: size * 0.5)),
  );
}

/// The rarity of a find, said in words and colour at once — never colour alone.
class RarityBadge extends StatelessWidget {
  const RarityBadge(this.rarity, {this.compact = false, super.key});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Tokens.rarity(rarity.name);
    final on = Tokens.onFill(color);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Tokens.s8 : Tokens.s12,
        vertical: compact ? 2 : 5,
      ),
      decoration: Tokens.chip(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (rarity) {
              Rarity.legendary => Icons.auto_awesome,
              Rarity.epic => Icons.local_fire_department,
              Rarity.rare => Icons.diamond_outlined,
              _ => Icons.circle,
            },
            size: compact ? 10 : 13,
            color: on,
          ),
          const SizedBox(width: Tokens.s4),
          Text(
            rarity.title.toUpperCase(),
            style: ui(
              size: compact ? 9 : 11,
              weight: FontWeight.w800,
              color: on,
              tracking: 0.5,
            ),
          ),
          if (!compact && rarity.multiplier > 1) ...[
            const SizedBox(width: Tokens.s4),
            Text(
              '×${rarity.multiplier.toStringAsFixed(rarity.multiplier % 1 == 0 ? 0 : 1)}',
              style: display(size: 12, color: on),
            ),
          ],
        ],
      ),
    );
  }
}

/// Uppercase section header, with the flower standing in for a bullet.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Tokens.s12),
    child: Row(
      children: [
        const Flower(size: 18),
        const SizedBox(width: Tokens.s8),
        Expanded(child: Text(text.toUpperCase(), style: label(color: Tokens.ink))),
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
    this.color = Tokens.ink,
    this.icon,
    this.tilt = 0,
    super.key,
  });

  final String value;
  final String caption;
  final Color color;
  final IconData? icon;
  final double tilt;

  @override
  Widget build(BuildContext context) => Sticker(
    tilt: tilt,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: Tokens.chip(color, radius: Tokens.rChip),
            child: Icon(icon, size: 16, color: Tokens.onFill(color)),
          ),
          const SizedBox(height: Tokens.s12),
        ],
        Text(value, style: display(size: 30)),
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
          Text('LEVEL ${profile.level}', style: label(color: Tokens.ink)),
          const Spacer(),
          Text(
            '${formatCount(profile.xpIntoLevel)} / ${formatCount(profile.xpForNextLevel)} XP',
            style: ui(size: 13, color: Tokens.inkDim),
          ),
        ],
      ),
      const SizedBox(height: Tokens.s8),
      Container(
        height: 20,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Tokens.pageSubtle,
          borderRadius: BorderRadius.circular(Tokens.rPill),
          border: Border.all(color: Tokens.ink, width: Tokens.stroke),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: profile.levelProgress),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (context, value, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  color: Tokens.questGreen,
                  borderRadius: BorderRadius.circular(Tokens.rPill),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Streak pill. Turns to a warning once the streak is one day from lost.
/// Tapping it opens the streak calendar, where the runs live.
class StreakChip extends StatelessWidget {
  const StreakChip(this.streak, {this.onTap, super.key});

  final Streak streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final atRisk =
        streak.lastActionDay != Streak.dayKey(DateTime.now()) &&
        streak.current > 0;
    final pill = Pill(
      atRisk ? '${streak.current} · act today' : '${streak.current}',
      color: atRisk ? Tokens.gold : Tokens.streakFire,
      icon: Icons.local_fire_department,
    );
    return onTap == null
        ? pill
        : Press(onTap: onTap!, radius: Tokens.rPill, child: pill);
  }
}

/// Sponsored quests always carry a visible label — never blurred into the UI.
class SponsorChip extends StatelessWidget {
  const SponsorChip(this.sponsor, {super.key});

  final String sponsor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.s12, vertical: 4),
    decoration: BoxDecoration(
      color: Tokens.pageSubtle,
      border: Border.all(color: Tokens.ink, width: 2),
      borderRadius: BorderRadius.circular(Tokens.rPill),
    ),
    child: Text(
      'Sponsored by $sponsor',
      style: ui(size: 12, weight: FontWeight.w800, color: Tokens.inkDim),
    ),
  );
}

/// Marks anything the AI didn't verify. Never counted in city totals.
class SelfReportedChip extends StatelessWidget {
  const SelfReportedChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Tokens.s12, vertical: 4),
    decoration: BoxDecoration(
      color: Tokens.page,
      border: Border.all(color: Tokens.ink, width: 2),
      borderRadius: BorderRadius.circular(Tokens.rPill),
    ),
    child: Text(
      'Self-reported',
      style: ui(size: 12, weight: FontWeight.w800, color: Tokens.ink),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Tokens.s32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Flower(size: 84, petal: Tokens.pageSubtle, heart: Tokens.page),
              Icon(icon, size: 30, color: Tokens.inkDim),
            ],
          ),
          const SizedBox(height: Tokens.s16),
          Text(title, style: display(size: 22), textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              body!,
              style: ui(size: 15, color: Tokens.inkDim),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: Tokens.s24), action!],
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
    this.onTap,
    super.key,
  });

  final int rank;
  final UserProfile player;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => Tokens.gold,
      2 => Tokens.sky,
      3 => Tokens.streakFire,
      _ => Tokens.pageSubtle,
    };
    return Sticker(
      onTap: onTap,
      accent: isMe ? Tokens.questGreen : null,
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.s12,
        vertical: Tokens.s12,
      ),
      child: Row(
        children: [
          // The rank is a badge, not a number in a column.
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: Tokens.chip(rankColor, radius: Tokens.rPill),
            child: Text(
              '$rank',
              style: display(size: 15, color: Tokens.onFill(rankColor)),
            ),
          ),
          const SizedBox(width: Tokens.s12),
          PlayerAvatar(
            avatar: player.avatar,
            photoUrl: player.photoUrl,
            size: 38,
          ),
          const SizedBox(width: Tokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: display(size: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatCount(player.itemsCollected)} items · Lv ${player.level}',
                  style: ui(size: 12, color: Tokens.inkDim),
                ),
              ],
            ),
          ),
          Text('${formatCount(player.xp)} XP', style: display(size: 17)),
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
    final scale =
        (size.width / imageSize.width) < (size.height / imageSize.height)
        ? size.width / imageSize.width
        : size.height / imageSize.height;
    final dx = (size.width - imageSize.width * scale) / 2;
    final dy = (size.height - imageSize.height * scale) / 2;

    for (final d in detections) {
      // A rare find is outlined in its rarity colour, so the thing worth
      // shouting about is the thing that catches the eye first.
      final color = d.rarity == Rarity.common
          ? Tokens.bin(d.cls.name)
          : Tokens.rarity(d.rarity.name);
      final rect = Rect.fromLTRB(
        d.box.left * scale + dx,
        d.box.top * scale + dy,
        d.box.right * scale + dx,
        d.box.bottom * scale + dy,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

      // Ink halo first, colour on top: the box survives a bright photo.
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Tokens.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );

      final caption = d.rarity == Rarity.common
          ? ' ${d.cls.displayName} ${(d.confidence * 100).round()}% '
          : ' ${d.rarity.title.toUpperCase()} ${d.cls.displayName} ';
      final text = TextPainter(
        text: TextSpan(
          text: caption,
          style: display(size: 13, color: Tokens.onFill(color)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Label sits above the box, or inside it when there's no room on top.
      final labelHeight = text.height + 6;
      final labelTop = rect.top - labelHeight >= 0
          ? rect.top - labelHeight
          : rect.top;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, labelTop, text.width + 8, labelHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(labelRect, Paint()..color = color);
      canvas.drawRRect(
        labelRect,
        Paint()
          ..color = Tokens.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      text.paint(canvas, Offset(rect.left + 4, labelTop + 3));
    }
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.detections != detections || old.imageSize != imageSize;
}

/// Thin-space thousands separators, per BRANDING.md §4.
///
/// The separator is written as an escape, not as a literal character: a thin
/// space is indistinguishable from an ordinary one in an editor, and an
/// accidental "fix" to a plain space is a silent brand regression.
String formatCount(int n) {
  final s = n.abs().toString();
  final buffer = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// Grams, said the way a person would.
String formatCo2(int grams) =>
    grams >= 1000 ? '${(grams / 1000).toStringAsFixed(1)} kg' : '$grams g';
