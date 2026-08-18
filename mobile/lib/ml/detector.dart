import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models.dart';

/// Everything one photo produced.
class DetectionResult {
  const DetectionResult({
    required this.detections,
    required this.imageSize,
    required this.elapsedMs,
  });

  /// Boxes in the coordinate space of the original photo.
  final List<Detection> detections;
  final Size imageSize;
  final int elapsedMs;

  /// Items that count toward [quest] — the number the reward is based on.
  List<Detection> counting(Quest quest) =>
      detections.where((d) => quest.counts(d.cls.name)).toList();

  Map<String, int> get classCounts {
    final counts = <String, int>{};
    for (final d in detections) {
      counts[d.cls.name] = (counts[d.cls.name] ?? 0) + 1;
    }
    return counts;
  }
}

/// On-device YOLO26 litter detector.
///
/// YOLO26 is NMS-free: the exported graph already emits its top-300 boxes
/// sorted by confidence, so there is no non-max suppression to run here — just
/// a threshold and a coordinate un-letterbox.
///
/// Contract (asserted at [load], verified in the training notebook):
///   input  `(1, 640, 640, 3)` float32, 0..1, letterboxed with fill 114
///   output `(1, N, 6)` float32 `[x1, y1, x2, y2, conf, class]` in 640px pixels
class Detector {
  Detector._(this._interpreter, this.labels, this._outputLength);

  final Interpreter _interpreter;
  final LabelSet labels;
  final int _outputLength;

  /// TFLite interpreters are not thread-safe and we share one native handle
  /// across isolates, so detections run strictly one at a time.
  Future<void> _tail = Future.value();
  bool _closed = false;

  static Future<Detector> load() async {
    final labels = await LabelSet.load();
    final interpreter = await Interpreter.fromAsset(
      labels.modelAsset,
      options: InterpreterOptions()..threads = 4,
    );
    // We call invoke() directly rather than run(), so allocation is on us.
    interpreter.allocateTensors();

    final inShape = interpreter.getInputTensor(0).shape;
    final outShape = interpreter.getOutputTensor(0).shape;
    final expectedIn = [1, labels.imgsz, labels.imgsz, 3];

    if (!_sameShape(inShape, expectedIn)) {
      interpreter.close();
      throw StateError('Model input is $inShape, expected $expectedIn.');
    }
    if (outShape.length != 3 || outShape[2] != 6) {
      interpreter.close();
      throw StateError(
        'Model output is $outShape, expected [1, N, 6] = [x1,y1,x2,y2,conf,class].',
      );
    }
    return Detector._(interpreter, labels, outShape[1] * outShape[2]);
  }

  static bool _sameShape(List<int> a, List<int> b) =>
      a.length == b.length && !a.indexed.any((e) => e.$2 != b[e.$1]);

  /// Decodes, letterboxes and runs inference on [jpegBytes], all off the UI
  /// isolate. [confidence] defaults to the threshold shipped with the labels.
  Future<DetectionResult> detect(Uint8List jpegBytes, {double? confidence}) {
    if (_closed) throw StateError('Detector is closed.');
    final job = _Job(
      address: _interpreter.address,
      jpeg: jpegBytes,
      imgsz: labels.imgsz,
      outputLength: _outputLength,
      threshold: confidence ?? labels.confThreshold,
      boxScale: labels.normalized ? labels.imgsz.toDouble() : 1.0,
    );

    // Serial queue: each detection waits for the previous one to finish.
    final result = _tail.then((_) => Isolate.run(() => _runJob(job)));
    _tail = result.then((_) {}, onError: (_) {});

    return result.then((raw) => DetectionResult(
      detections: [
        // Rows are flat groups of 6: [x1, y1, x2, y2, conf, classId].
        for (var i = 0; i + 5 < raw.rows.length; i += 6)
          if (labels.byId(raw.rows[i + 5].toInt()) case final cls?)
            Detection(
              cls: cls,
              confidence: raw.rows[i + 4],
              box: Rect.fromLTRB(
                raw.rows[i],
                raw.rows[i + 1],
                raw.rows[i + 2],
                raw.rows[i + 3],
              ),
            ),
      ],
      imageSize: Size(raw.width.toDouble(), raw.height.toDouble()),
      elapsedMs: raw.elapsedMs,
    ));
  }

  void close() {
    _closed = true;
    _interpreter.close();
  }
}

/// Sendable job description for the worker isolate.
class _Job {
  const _Job({
    required this.address,
    required this.jpeg,
    required this.imgsz,
    required this.outputLength,
    required this.threshold,
    required this.boxScale,
  });

  final int address;
  final Uint8List jpeg;
  final int imgsz;
  final int outputLength;
  final double threshold;

  /// What a returned coordinate has to be multiplied by to become a pixel in
  /// the letterboxed square: 1 for a pixel-space model, [imgsz] for a
  /// normalised one.
  final double boxScale;
}

/// Flat `[x1, y1, x2, y2, conf, classId]` rows that survived the threshold,
/// already mapped back to original-image coordinates.
class _Raw {
  const _Raw({
    required this.rows,
    required this.width,
    required this.height,
    required this.elapsedMs,
  });

  final Float32List rows;
  final int width;
  final int height;
  final int elapsedMs;
}

/// Runs entirely in a background isolate: decode → letterbox → invoke → decode.
_Raw _runJob(_Job job) {
  final started = DateTime.now();
  final size = job.imgsz;

  final decoded = img.decodeImage(job.jpeg);
  if (decoded == null) throw StateError('Could not decode captured photo.');
  // Phone cameras write orientation into EXIF; bake it in or every box is rotated.
  final source = img.bakeOrientation(decoded);

  // Letterbox exactly as the export does: scale to fit, centre, fill 114.
  final ratio = (size / source.width) < (size / source.height)
      ? size / source.width
      : size / source.height;
  final newW = (source.width * ratio).round();
  final newH = (source.height * ratio).round();
  final padX = (size - newW) ~/ 2;
  final padY = (size - newH) ~/ 2;

  final canvas = img.Image(width: size, height: size, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
  img.compositeImage(
    canvas,
    img.copyResize(
      source,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    ),
    dstX: padX,
    dstY: padY,
  );

  final rgb = canvas.getBytes(order: img.ChannelOrder.rgb);
  final input = Float32List(size * size * 3);
  for (var i = 0; i < input.length; i++) {
    input[i] = rgb[i] / 255.0;
  }

  final interpreter = Interpreter.fromAddress(job.address, allocated: true);
  // setTo() only has a fast path for Uint8List — handing it a Float32List
  // would walk 1.2M elements one at a time.
  interpreter.getInputTensor(0).setTo(input.buffer.asUint8List());
  interpreter.invoke();

  // copyTo() both fills the buffer you hand it and returns one. It fills this
  // one (it shape-checks, then copies element-wise), so reading outBytes after
  // the call is correct — the return value is redundant, not the output.
  // The length must match the tensor's byte size exactly or it throws.
  final outBytes = Uint8List(job.outputLength * 4);
  interpreter.getOutputTensor(0).copyTo(outBytes);
  final out = outBytes.buffer.asFloat32List();
  // Deliberately not closing: the native interpreter is owned by the main isolate.

  final kept = <double>[];
  for (var i = 0; i + 5 < out.length; i += 6) {
    final conf = out[i + 4];
    // Rows arrive sorted by confidence descending, so the first miss ends it.
    if (conf < job.threshold) break;
    final k = job.boxScale;
    kept.addAll([
      ((out[i] * k - padX) / ratio).clamp(0.0, source.width.toDouble()),
      ((out[i + 1] * k - padY) / ratio).clamp(0.0, source.height.toDouble()),
      ((out[i + 2] * k - padX) / ratio).clamp(0.0, source.width.toDouble()),
      ((out[i + 3] * k - padY) / ratio).clamp(0.0, source.height.toDouble()),
      conf,
      out[i + 5],
    ]);
  }

  return _Raw(
    rows: Float32List.fromList(kept),
    width: source.width,
    height: source.height,
    elapsedMs: DateTime.now().difference(started).inMilliseconds,
  );
}
