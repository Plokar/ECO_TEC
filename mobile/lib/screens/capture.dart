import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../ml/detector.dart';
import '../models.dart';
import '../services/data.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

/// Step 1 of the core loop: point, shoot.
///
/// Nothing here waits on the network. The camera opens, the shutter fires, and
/// verification happens on-device on the next screen.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({required this.profile, this.quest, super.key});

  final UserProfile profile;

  /// Null when launched from the global shutter button — today's quest is
  /// fetched instead.
  final Quest? quest;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Quest? _quest;
  String? _error;
  bool _shooting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quest = widget.quest;
    _start();
    // Warm the model up while the user is still framing the shot, so the
    // analyse step doesn't pay the 6 MB load.
    detector().ignore();
    if (_quest == null) {
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
    if (camera == null || quest == null || _shooting) return;

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
            jpeg: bytes,
          ),
        ),
      );
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t take the photo: ${e.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            EmptyState(icon: Icons.no_photography, title: 'No camera', body: _error)
          else if (camera == null)
            const Center(child: CircularProgressIndicator())
          else
            CameraPreview(camera),

          // Quest reminder, so you know what you're shooting for.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Tokens.s16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Tokens.bone,
                        ),
                      ),
                      const Spacer(),
                      if (_quest case final q?)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Tokens.s12,
                              vertical: Tokens.s8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(Tokens.rPill),
                            ),
                            child: Text(
                              q.title,
                              style: ui(size: 13, weight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (camera != null)
                    _ShutterButton(busy: _shooting, onTap: _shoot),
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

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Take proof photo',
    child: GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 78,
        width: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Tokens.bone,
          border: Border.all(color: Tokens.questGreen, width: 4),
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Tokens.deepForest,
                ),
              )
            : const Icon(Icons.eco, color: Tokens.deepForest, size: 32),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

/// Step 2: on-device verification, shown rather than asserted.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    required this.profile,
    required this.quest,
    required this.jpeg,
    super.key,
  });

  final UserProfile profile;
  final Quest quest;
  final Uint8List jpeg;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  DetectionResult? _result;
  String? _error;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _analyse();
  }

  Future<void> _analyse() async {
    try {
      final d = await detector();
      final result = await d.detect(widget.jpeg);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _claim() async {
    final result = _result;
    if (result == null || _claiming) return;
    setState(() => _claiming = true);

    final counted = result.counting(widget.quest);
    try {
      // Location strengthens the proof but never gates it.
      final position = await location.current();
      final photoId = DateTime.now().microsecondsSinceEpoch.toString();

      // Reward instantly, sync later: if the upload can't get through, the
      // submission still lands (Firestore queues it) with the photo flagged.
      //
      // ponytail: no background retry for the flagged photos. Add one when
      // moderation actually needs to look at them.
      var photoUrl = '';
      try {
        photoUrl = await data
            .uploadProof(widget.profile.uid, widget.jpeg, photoId)
            .timeout(const Duration(seconds: 20));
      } catch (_) {
        photoUrl = '';
      }

      final reward = await data.submitQuest(
        profile: widget.profile,
        quest: widget.quest,
        counted: counted,
        photoUrl: photoUrl,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => _RewardSheet(reward: reward, photoPending: photoUrl.isEmpty),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _claiming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save that: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final counted = result?.counting(widget.quest) ?? const <Detection>[];
    final met = counted.length >= widget.quest.targetCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(widget.jpeg, fit: BoxFit.contain),
                if (result != null)
                  DetectionOverlay(
                    imageSize: result.imageSize,
                    detections: result.detections,
                  ),
                if (result == null && _error == null)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: Tokens.s16),
                          Text('Checking your photo…', style: ui()),
                          Text(
                            'On this phone, not in the cloud',
                            style: ui(size: 12, color: Tokens.boneDim),
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
            result: result,
            counted: counted,
            met: met,
            error: _error,
            claiming: _claiming,
            onClaim: _claim,
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
    required this.result,
    required this.counted,
    required this.met,
    required this.error,
    required this.claiming,
    required this.onClaim,
    required this.onRetake,
  });

  final Quest quest;
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
              'The detector couldn\'t run',
              style: display(size: 18, color: Tokens.alertRed),
            ),
            const SizedBox(height: Tokens.s8),
            Text(error!, style: ui(size: 12, color: Tokens.boneDim)),
            const SizedBox(height: Tokens.s16),
            OutlinedButton(onPressed: onRetake, child: const Text('Back')),
          ],
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();

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
                color: met ? Tokens.questGreen : Tokens.streakFire,
              ),
              const SizedBox(width: Tokens.s8),
              Expanded(
                child: Text(
                  met
                      ? '${counted.length} items verified'
                      : '${counted.length} of ${quest.targetCount} — keep going',
                  style: display(size: 20),
                ),
              ),
              Text('${result!.elapsedMs} ms', style: label()),
            ],
          ),
          if (counts.isNotEmpty) ...[
            const SizedBox(height: Tokens.s12),
            Wrap(
              spacing: Tokens.s8,
              runSpacing: Tokens.s8,
              children: [
                for (final e in counts.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.s12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Tokens.bin(e.key).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(Tokens.rPill),
                    ),
                    child: Text(
                      '${e.value}× ${e.key}',
                      style: ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: Tokens.bin(e.key),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (ignored > 0) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              '$ignored other item${ignored == 1 ? '' : 's'} found but not '
              'counted for this quest.',
              style: ui(size: 12, color: Tokens.boneDim),
            ),
          ],
          if (counted.isEmpty) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              'Nothing matched. Get closer, fill more of the frame, and make '
              'sure the litter is clearly visible.',
              style: ui(size: 13, color: Tokens.boneDim),
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
                            color: Tokens.deepForest,
                          ),
                        )
                      : Text(met ? 'Claim reward' : 'Claim what I got'),
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
      color: Tokens.forestSurface,
      border: Border(top: BorderSide(color: Tokens.forestLine)),
    ),
    child: SafeArea(top: false, child: child),
  );
}

class _RewardSheet extends StatelessWidget {
  const _RewardSheet({required this.reward, required this.photoPending});

  final QuestReward reward;
  final bool photoPending;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Tokens.s24),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reward.levelUp) ...[
            ShaderMask(
              shaderCallback: (r) => Tokens.gradient.createShader(r),
              child: Text(
                'LEVEL UP',
                style: display(size: 30, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Tokens.s16),
          ],
          Center(child: Text('+${formatCount(reward.xp)}', style: display(size: 52))),
          Center(child: Text('XP EARNED', style: label())),
          const SizedBox(height: Tokens.s24),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '+${reward.points}',
                  caption: 'EcoPoints',
                  color: Tokens.impactCyan,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.s12),
          Text(
            '${reward.co2g} g CO₂ avoided · based on per-material averages',
            style: ui(size: 11, color: Tokens.boneDim),
            textAlign: TextAlign.center,
          ),
          if (photoPending) ...[
            const SizedBox(height: Tokens.s8),
            Text(
              'Saved without the photo — no connection. The XP is yours, but '
              'this one has no proof attached.',
              style: ui(size: 11, color: Tokens.gold),
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
