import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../fx.dart';
import '../ml/detector.dart';
import '../models.dart';
import '../services/data.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// What the shutter is for on this trip.
enum CaptureMode {
  /// Picked it up — verify and claim the reward.
  quest,

  /// Cannot pick it up right now — tag it on the map for somebody else.
  spot,
}

/// Step 1 of the core loop: point, shoot.
///
/// Nothing here waits on the network. The camera opens, the shutter fires, and
/// verification happens on-device on the next screen.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    required this.profile,
    this.quest,
    this.mode = CaptureMode.quest,
    this.clearing,
    super.key,
  });

  final UserProfile profile;

  /// Null when launched from the global shutter button — today's quest is
  /// fetched instead. Unused in [CaptureMode.spot].
  final Quest? quest;

  final CaptureMode mode;

  /// The litter pin this cleanup answers, if the player came from the map.
  /// Claiming retires it.
  final MapPin? clearing;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Quest? _quest;
  String? _error;
  bool _shooting = false;

  bool get _spotting => widget.mode == CaptureMode.spot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quest = widget.quest;
    _start();
    // Warm the model up while the user is still framing the shot, so the
    // analyse step doesn't pay the 6 MB load.
    detector().ignore();
    if (_quest == null && !_spotting) {
      data.dailyQuest().then((q) {
        if (mounted) setState(() => _quest = q);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android reclaims the camera when the app backgrounds; rebuild on return.
    if (state == AppLifecycleState.inactive) {
      _camera?.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      setState(
        () => _error = e.code == 'CameraAccessDenied'
            ? 'EcoQuest needs the camera to verify your quest. '
                  'Enable it in Settings.'
            : 'Camera error: ${e.description ?? e.code}',
      );
    }
  }

  Future<void> _shoot() async {
    final camera = _camera;
    final quest = _quest;
    if (camera == null || _shooting) return;
    if (!_spotting && quest == null) return;

    setState(() => _shooting = true);
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyScreen(
            profile: widget.profile,
            quest: quest,
            mode: widget.mode,
            clearing: widget.clearing,
            jpeg: bytes,
          ),
        ),
      );
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not take the photo: ${e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    // The banner is the only instruction the player gets while framing, so it
    // says what this particular shutter press will do.
    final banner = switch (widget.mode) {
      CaptureMode.spot => 'Tag litter you cannot carry',
      CaptureMode.quest =>
        widget.clearing != null
            ? 'Clearing: ${widget.clearing!.title}'
            : _quest?.title,
    };

    return Scaffold(
      backgroundColor: Tokens.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Paper(
              child: EmptyState(
                icon: Icons.no_photography,
                title: 'No camera',
                body: _error,
              ),
            )
          else if (camera == null)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreview(camera),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Tokens.s16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      if (banner case final text?)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Tokens.s12,
                              vertical: Tokens.s8,
                            ),
                            decoration: Tokens.card(
                              fill: _spotting ? Tokens.streakFire : Tokens.paper,
                              radius: Tokens.rPill,
                              offset: 3,
                            ),
                            child: Text(
                              text,
                              style: ui(
                                size: 13,
                                weight: FontWeight.w800,
                                color: _spotting ? Tokens.paper : Tokens.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (camera != null)
                    _ShutterButton(
                      busy: _shooting,
                      spotting: _spotting,
                      onTap: _shoot,
                    ),
                  const SizedBox(height: Tokens.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Press(
    onTap: onTap,
    radius: Tokens.rPill,
    child: Container(
      height: 48,
      width: 48,
      alignment: Alignment.center,
      decoration: Tokens.card(radius: Tokens.rPill, offset: 3),
      child: Icon(icon, color: Tokens.ink),
    ),
  );
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.busy,
    required this.spotting,
    required this.onTap,
  });

  final bool busy;
  final bool spotting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = spotting ? Tokens.streakFire : Tokens.questGreen;
    return Semantics(
      button: true,
      label: spotting ? 'Photograph litter to tag it' : 'Take proof photo',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          height: 82,
          width: 82,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: Tokens.ink, width: 4),
            boxShadow: const [
              BoxShadow(color: Tokens.ink, offset: Offset(4, 4), blurRadius: 0),
            ],
          ),
          child: busy
              ? const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Tokens.ink,
                  ),
                )
              : Icon(
                  spotting ? Icons.push_pin : Icons.eco,
                  color: Tokens.onFill(fill),
                  size: 34,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Step 2: on-device verification, shown rather than asserted.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    required this.profile,
    required this.quest,
    required this.jpeg,
    this.mode = CaptureMode.quest,
    this.clearing,
    super.key,
  });

  final UserProfile profile;

  /// Always set in [CaptureMode.quest]; ignored when spotting.
  final Quest? quest;
  final Uint8List jpeg;
  final CaptureMode mode;
  final MapPin? clearing;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  /// One id for this photo, generated before the roll and reused as the storage
  /// key. It seeds the rarity, so what the player is shown here is exactly what
  /// gets written — retries and retakes cannot reroll it.
  final _photoId = DateTime.now().microsecondsSinceEpoch.toString();

  DetectionResult? _result;
  List<Detection> _rolled = const [];
  String? _error;
  bool _claiming = false;

  /// The find worth celebrating, set once when the analysis lands and cleared
  /// when the burst is over. Null the rest of the time, so the burst plays once
  /// per photo and never on a rebuild.
  Rarity? _celebrating;

  bool get _spotting => widget.mode == CaptureMode.spot;

  @override
  void initState() {
    super.initState();
    _analyse();
  }

  Future<void> _analyse() async {
    try {
      final d = await detector();
      final result = await d.detect(widget.jpeg);
      if (!mounted) return;
      setState(() {
        _result = result;
        _rolled = [
          for (final (i, det) in result.detections.indexed)
            det.rolled(_photoId, i),
        ];
        // Only what the quest actually counts gets a burst — celebrating a
        // bottle on a cigarette quest would be a lie with confetti on it.
        _celebrating = _counted.isEmpty
            ? null
            : _counted
                  .map((d) => d.rarity)
                  .reduce((a, b) => a.index >= b.index ? a : b);
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Items this photo is worth something for. Spotting counts everything found;
  /// a quest counts only what it asked for.
  List<Detection> get _counted => widget.quest == null
      ? _rolled
      : _rolled.where((d) => widget.quest!.counts(d.cls.name)).toList();

  /// Uploads the proof, but never blocks on it: if the upload cannot get
  /// through the submission still lands (Firestore queues it) with the photo
  /// flagged as missing.
  ///
  /// ponytail: no background retry for the flagged photos. Add one when
  /// moderation actually needs to look at them.
  Future<String> _upload() async {
    try {
      return await data
          .uploadProof(widget.profile.uid, widget.jpeg, _photoId)
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      return '';
    }
  }

  Future<void> _claim() async {
    if (_result == null || _claiming) return;
    setState(() => _claiming = true);

    try {
      // Location strengthens the proof but never gates a quest.
      final position = await location.current();
      final photoUrl = await _upload();

      final reward = await data.submitQuest(
        profile: widget.profile,
        quest: widget.quest!,
        counted: _counted,
        photoUrl: photoUrl,
        lat: position?.latitude,
        lng: position?.longitude,
        clearedPinId: widget.clearing?.id,
      );

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) =>
            _RewardSheet(reward: reward, photoPending: photoUrl.isEmpty),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _failed(e);
    }
  }

  /// Spotting *does* need a position — a pin with no coordinates is not a pin.
  Future<void> _dropPin() async {
    if (_claiming) return;
    setState(() => _claiming = true);

    try {
      final position = await location.current();
      if (position == null) {
        _failed('EcoQuest needs your location to put this on the map.');
        return;
      }
      final photoUrl = await _upload();
      final pin = await data.spotLitter(
        profile: widget.profile,
        found: _counted,
        lat: position.latitude,
        lng: position.longitude,
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pin.title} — on the map. +5 XP for the tip-off.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _failed(e);
    }
  }

  void _failed(Object error) {
    if (!mounted) return;
    setState(() => _claiming = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not save that: $error')));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final counted = _counted;
    final met = _spotting
        ? counted.isNotEmpty
        : counted.length >= widget.quest!.targetCount;

    return Scaffold(
      backgroundColor: Tokens.ink,
      appBar: AppBar(
        title: Text(_spotting ? 'What did you find?' : 'Verification'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(widget.jpeg, fit: BoxFit.contain),
                if (result != null)
                  // Boxes snap in a beat after the shutter rather than being
                  // there already: the photo is the before, the boxes are the
                  // after, and the eye needs the gap to see it happen.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    builder: (context, v, child) => Opacity(
                      opacity: v.clamp(0, 1),
                      child: Transform.scale(scale: 0.94 + v * 0.06, child: child),
                    ),
                    child: DetectionOverlay(
                      imageSize: result.imageSize,
                      detections: _rolled,
                    ),
                  ),
                if (_celebrating case final rarity?)
                  RarityBurst(
                    rarity: rarity,
                    seed: _photoId.hashCode,
                    label: rarity.index >= Rarity.uncommon.index
                        ? rarity.title
                        : null,
                    onDone: () {
                      if (mounted) setState(() => _celebrating = null);
                    },
                  ),
                if (result == null && _error == null)
                  ColoredBox(
                    color: Tokens.ink.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Tokens.questGreen,
                          ),
                          const SizedBox(height: Tokens.s16),
                          Text(
                            'Checking your photo…',
                            style: ui(color: Tokens.page),
                          ),
                          Text(
                            'On this phone, not in the cloud',
                            style: ui(size: 12, color: Tokens.sky),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _ResultPanel(
            quest: widget.quest,
            spotting: _spotting,
            result: result,
            counted: counted,
            met: met,
            error: _error,
            claiming: _claiming,
            onClaim: _spotting ? _dropPin : _claim,
            onRetake: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.quest,
    required this.spotting,
    required this.result,
    required this.counted,
    required this.met,
    required this.error,
    required this.claiming,
    required this.onClaim,
    required this.onRetake,
  });

  final Quest? quest;
  final bool spotting;
  final DetectionResult? result;
  final List<Detection> counted;
  final bool met;
  final String? error;
  final bool claiming;
  final VoidCallback onClaim;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _Panel(
        child: Column(
          children: [
            Text(
              'The detector could not run',
              style: display(size: 18, color: Tokens.alertRed),
            ),
            const SizedBox(height: Tokens.s8),
            Text(error!, style: ui(size: 12, color: Tokens.inkDim)),
            const SizedBox(height: Tokens.s16),
            OutlinedButton(onPressed: onRetake, child: const Text('Back')),
          ],
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();

    final best = counted.isEmpty
        ? Rarity.common
        : counted
              .map((d) => d.rarity)
              .reduce((a, b) => a.index >= b.index ? a : b);
    final counts = <String, int>{};
    for (final d in counted) {
      counts[d.cls.name] = (counts[d.cls.name] ?? 0) + 1;
    }
    final ignored = result!.detections.length - counted.length;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                met ? Icons.verified : Icons.error_outline,
                color: met ? Tokens.questGreenDeep : Tokens.streakFire,
              ),
              const SizedBox(width: Tokens.s8),
              Expanded(
                child: Text(
                  spotting
                      ? '${counted.length} item${counted.length == 1 ? '' : 's'} found'
                      : met
                      ? '${counted.length} items verified'
                      : '${counted.length} of ${quest!.targetCount} — keep going',
                  style: display(size: 20),
                ),
              ),
              Text('${result!.elapsedMs} ms', style: label()),
            ],
          ),
          // The rare find is the headline, above the material breakdown.
          if (best.isBoasted) ...[
            const SizedBox(height: Tokens.s12),
            Row(
              children: [
                RarityBadge(best),
                const SizedBox(width: Tokens.s8),
                Expanded(
                  child: Text(
                    spotting
                        ? 'Worth flagging — this pin will stand out.'
                        : 'Rarity multiplies the XP and points for that item.',
                    style: ui(size: 12, color: Tokens.inkDim),
                  ),
                ),
              ],
            ),
          ],
          if (counts.isNotEmpty) ...[
            const SizedBox(height: Tokens.s12),
            Wrap(
              spacing: Tokens.s8,
              runSpacing: Tokens.s8,
              children: [
                for (final e in counts.entries)
                  Pill('${e.value}× ${e.key.replaceAll('_', ' ')}',
                      color: Tokens.bin(e.key)),
              ],
            ),
          ],
          if (ignored > 0) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              '$ignored other item${ignored == 1 ? '' : 's'} found but not '
              'counted for this quest.',
              style: ui(size: 12, color: Tokens.inkDim),
            ),
          ],
          if (counted.isEmpty) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              'Nothing matched. Get closer, fill more of the frame, and make '
              'sure the litter is clearly visible.',
              style: ui(size: 13, color: Tokens.inkDim),
            ),
          ],
          const SizedBox(height: Tokens.s16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: claiming ? null : onRetake,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: Tokens.s12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: counted.isEmpty || claiming ? null : onClaim,
                  child: claiming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Tokens.ink,
                          ),
                        )
                      : Text(
                          spotting
                              ? 'Put it on the map'
                              : met
                              ? 'Claim reward'
                              : 'Claim what I got',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      Tokens.s16,
      Tokens.s16,
      Tokens.s16,
      Tokens.s24,
    ),
    decoration: const BoxDecoration(
      color: Tokens.page,
      border: Border(top: BorderSide(color: Tokens.ink, width: Tokens.stroke)),
    ),
    child: SafeArea(top: false, child: child),
  );
}

class _RewardSheet extends StatelessWidget {
  const _RewardSheet({required this.reward, required this.photoPending});

  final QuestReward reward;
  final bool photoPending;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _body(context),
      // Second burst, on the sheet this time: the reward screen is where the
      // haul is named, so that is where the best find of it gets its moment.
      Positioned.fill(
        child: RarityBurst(rarity: reward.best, seed: reward.xp * 31 + reward.items),
      ),
    ],
  );

  Widget _body(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Tokens.s24),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reward.levelUp) ...[
            ShaderMask(
              shaderCallback: Tokens.gradient.createShader,
              child: Text(
                'LEVEL UP',
                style: display(size: 32, color: Tokens.paper),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Tokens.s12),
          ],
          if (reward.best.isBoasted) ...[
            Center(child: RarityBadge(reward.best)),
            const SizedBox(height: Tokens.s4),
            Text(
              'Best find of this haul',
              style: ui(size: 12, color: Tokens.inkDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Tokens.s12),
          ],
          Center(child: CountUp(reward.xp, prefix: '+')),
          Center(child: Text('XP EARNED', style: label())),
          const SizedBox(height: Tokens.s24),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '+${reward.points}',
                  caption: 'EcoPoints',
                  color: Tokens.impactCyan,
                  tilt: -1,
                ),
              ),
              const SizedBox(width: Tokens.s12),
              Expanded(
                child: StatTile(
                  value: '${reward.items}',
                  caption: 'items',
                  color: Tokens.questGreen,
                ),
              ),
              const SizedBox(width: Tokens.s12),
              Expanded(
                child: StatTile(
                  value: '${reward.streak.current}',
                  caption: 'streak',
                  color: Tokens.streakFire,
                  tilt: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.s12),
          Text(
            '${formatCo2(reward.co2g)} CO₂ avoided · based on per-material averages',
            style: ui(size: 11, color: Tokens.inkDim),
            textAlign: TextAlign.center,
          ),
          if (photoPending) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              'Saved without the photo — no connection. The XP is yours, but '
              'this one has no proof attached.',
              style: ui(size: 11, color: Tokens.streakFire),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Tokens.s24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nice'),
          ),
        ],
      ),
    ),
  );
}
