import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme/tokens.dart';
import 'widgets.dart';

/// The catch moment: what the app does the instant a photo turns into a find.
///
/// Everything here is keyed off [Rarity], so the payoff scales with the pull —
/// a common bottle gets a short pop, a legendary gets rays, gold shards and a
/// double thump. That escalation is the whole point: a reward that always looks
/// identical stops being a reward by the tenth photo.
///
/// One controller, one painter, no packages.
class RarityBurst extends StatefulWidget {
  const RarityBurst({
    required this.rarity,
    this.seed = 0,
    this.label,
    this.onDone,
    super.key,
  });

  final Rarity rarity;

  /// Same photo, same shards — the burst is part of the roll, not decoration
  /// sprinkled on top of it.
  final int seed;

  /// Stamped over the burst once the shards are out. Null for a quiet burst
  /// behind other content.
  final String? label;

  final VoidCallback? onDone;

  @override
  State<RarityBurst> createState() => _RarityBurstState();
}

class _RarityBurstState extends State<RarityBurst>
    with SingleTickerProviderStateMixin {
  late final _tier = widget.rarity.index;
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 850 + _tier * 320),
  );
  late final List<_Shard> _shards = _makeShards();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced-motion is a real setting, not a preference to talk someone out
    // of: no burst, no haptics, straight to the result.
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone?.call());
      return;
    }
    _thump();
    _controller.forward().whenComplete(() => widget.onDone?.call());
  }

  /// Haptics carry the tier even in a pocket, in sunlight, with the sound off.
  Future<void> _thump() async {
    switch (widget.rarity) {
      case Rarity.common:
        await HapticFeedback.selectionClick();
      case Rarity.uncommon:
        await HapticFeedback.lightImpact();
      case Rarity.rare:
        await HapticFeedback.mediumImpact();
      case Rarity.epic:
        await HapticFeedback.heavyImpact();
      case Rarity.legendary:
        for (var i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 110));
        }
    }
  }

  List<_Shard> _makeShards() {
    final rng = math.Random(widget.seed ^ (_tier * 7919));
    final colour = Tokens.rarity(widget.rarity.name);
    final count = 14 + _tier * 14;
    return [
      for (var i = 0; i < count; i++)
        _Shard(
          // Even spread plus jitter: pure random clumps, pure even looks printed.
          angle: (i / count) * math.pi * 2 + rng.nextDouble() * 0.45,
          speed: 0.45 + rng.nextDouble() * 0.55,
          spin: (rng.nextDouble() - 0.5) * 8,
          size: 4 + rng.nextDouble() * (5 + _tier * 1.6),
          delay: rng.nextDouble() * 0.18,
          colour: switch (rng.nextInt(4)) {
            0 => Tokens.gold,
            1 => Tokens.paper,
            _ => colour,
          },
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _BurstPainter(
          t: _controller.value,
          tier: _tier,
          colour: Tokens.rarity(widget.rarity.name),
          shards: _shards,
        ),
        size: Size.infinite,
        child: widget.label == null
            ? null
            : Center(child: _Stamp(_controller, widget.rarity, widget.label!)),
      ),
    ),
  );
}

/// The rarity word, punched in on an overshoot and held.
class _Stamp extends StatelessWidget {
  const _Stamp(this.controller, this.rarity, this.text);

  final AnimationController controller;
  final Rarity rarity;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colour = Tokens.rarity(rarity.name);
    final t = controller.value;
    // Lands after the shards are away, so the eye reads motion then word.
    final in_ = Curves.elasticOut.transform(((t - 0.15) / 0.5).clamp(0, 1));
    if (in_ <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: (1 - ((t - 0.82) / 0.18).clamp(0, 1)).toDouble(),
      child: Transform.scale(
        scale: in_,
        child: Transform.rotate(
          angle: -0.04,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.s24,
              vertical: Tokens.s12,
            ),
            decoration: Tokens.chip(colour, radius: Tokens.rChip),
            child: Text(
              text.toUpperCase(),
              style: display(size: 26, color: Tokens.onFill(colour)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shard {
  const _Shard({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.delay,
    required this.colour,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final double delay;
  final Color colour;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.tier,
    required this.colour,
    required this.shards,
  });

  final double t;
  final int tier;
  final Color colour;
  final List<_Shard> shards;

  static double _easeOut(double x) => 1 - math.pow(1 - x, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final reach = size.shortestSide * 0.62;

    _rays(canvas, centre, reach);
    _flash(canvas, centre, reach);
    _rings(canvas, centre, reach);
    _shardsPass(canvas, centre, reach);
  }

  /// Legendary only: the slow rotating light behind everything, which is what
  /// separates "nice find" from "stop walking and look at this".
  void _rays(Canvas canvas, Offset centre, double reach) {
    if (tier < Rarity.legendary.index) return;
    final fade = (1 - t) * 0.35;
    if (fade <= 0) return;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(t * 1.6);
    final paint = Paint()..color = Tokens.gold.withValues(alpha: fade);
    for (var i = 0; i < 12; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(reach * 2.4, -reach * 0.09)
          ..lineTo(reach * 2.4, reach * 0.09)
          ..close(),
        paint,
      );
      canvas.rotate(math.pi * 2 / 12);
    }
    canvas.restore();
  }

  /// The hit: a hard bloom on the first frames, gone almost immediately.
  void _flash(Canvas canvas, Offset centre, double reach) {
    final f = 1 - (t / 0.16).clamp(0.0, 1.0);
    if (f <= 0) return;
    canvas.drawCircle(
      centre,
      reach * (0.3 + (1 - f) * 1.4),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Tokens.paper.withValues(alpha: f),
            colour.withValues(alpha: f * 0.8),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(
          Rect.fromCircle(center: centre, radius: reach * (0.3 + (1 - f) * 1.4)),
        ),
    );
  }

  /// Shockwaves. One per tier, each a beat behind the last.
  void _rings(Canvas canvas, Offset centre, double reach) {
    for (var i = 0; i <= tier; i++) {
      final local = ((t - i * 0.11) / 0.55).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final e = _easeOut(local);
      // Ink halo under the colour, same trick the detection boxes use, so the
      // ring survives a bright photo underneath.
      canvas.drawCircle(
        centre,
        reach * (0.15 + e * 0.95),
        Paint()
          ..color = Tokens.ink.withValues(alpha: (1 - local) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 * (1 - local) + 1,
      );
      canvas.drawCircle(
        centre,
        reach * (0.15 + e * 0.95),
        Paint()
          ..color = (i.isEven ? colour : Tokens.gold)
              .withValues(alpha: 1 - local)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - local) + 1,
      );
    }
  }

  void _shardsPass(Canvas canvas, Offset centre, double reach) {
    for (final s in shards) {
      final local = ((t - s.delay) / (0.78 - s.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final e = _easeOut(local);
      final d = reach * s.speed * 1.5 * e;
      // Gravity on the way out, so the shards fall rather than float — the
      // difference between confetti and a screensaver.
      final at = Offset(
        centre.dx + math.cos(s.angle) * d,
        centre.dy + math.sin(s.angle) * d + reach * 0.55 * local * local,
      );
      final alpha = 1 - ((local - 0.55) / 0.45).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(s.spin * e);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: s.size * 1.6,
          height: s.size,
        ),
        Radius.circular(s.size * 0.35),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = Tokens.ink.withValues(alpha: alpha * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawRRect(rect, Paint()..color = s.colour.withValues(alpha: alpha));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// A number that counts up to [value] instead of appearing. Costs nothing and
/// buys a second of watching the reward land.
class CountUp extends StatelessWidget {
  const CountUp(
    this.value, {
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final int value;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: value),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
    curve: Curves.easeOutCubic,
    builder: (context, v, _) =>
        Text('$prefix${formatCount(v)}', style: style ?? display(size: 54)),
  );
}
