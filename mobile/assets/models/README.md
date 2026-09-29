# Model assets

Two files belong here. Both come out of [`ml/EcoQuest_YOLO26_TACO.ipynb`](../../../ml/EcoQuest_YOLO26_TACO.ipynb),
zipped by its last cell.

| File | Status |
|---|---|
| `ecoquest_labels.json` | committed labels from the trained run (mAP50 0.201) |
| `ecoquest_yolo26n.tflite` | generated locally, gitignored — regenerate with the script below |

Without the `.tflite`, everything except the camera verification step works;
`Detector.load()` throws and the verify screen shows the error rather than
pretending a photo passed.

## Converting a trained run

The notebook's TFLite export is the step that fails in Colab, so a finished run
usually hands back `best.pt` and an `.onnx` the app cannot read. Convert locally:

```bash
pip install ultralytics onnx onnxslim onnx2tf ai_edge_litert tensorflow tf_keras
python ml/export_tflite.py ml/ecoquest_model/best.pt
```

That converts, gates the result against the contract below, **measures** which
coordinate space the graph returns, and installs both files here.

### The coordinate trap

The same weights export two different ways and the tensor shape cannot tell them
apart:

| Export | Box coordinates |
|---|---|
| ONNX | pixels in the letterboxed 640×640 |
| TFLite | **normalized 0..1** — the caller multiplies by the input size |

Ultralytics' own TFLite backend does that multiply for you; the Dart decoder has
to do it itself. So `output.coords` in the label file is load-bearing: it says
`normalized 0..1` or `pixels in letterboxed NxN`, `LabelSet` refuses to load
anything else, and `Detector` scales by it. Get it wrong and every box collapses
into the top-left corner while the confidences still look perfect.

## Testing without the trained weights

The stock COCO `yolo26n` exports into exactly this contract, and COCO knows about
bottles, cups, cutlery and fruit — enough real detections to exercise
camera → detect → rarity → burst → reward end to end.

```bash
pip install ultralytics onnx onnxslim
python ml/export_stock_yolo26n.py        # writes coco_yolo26n.tflite here
flutter run --dart-define=ECOQUEST_LABELS=assets/models/coco_labels.json
```

`coco_labels.json` is committed, so the export script's only real job is the
`.tflite`. It maps thirteen COCO ids onto EcoQuest's six classes and lists
nothing else, which is what makes the detector ignore the other sixty-seven —
pointing the camera at a person or a sofa hands out no XP.

`LabelSet.byId` looks a class up by its declared `id`, not by list position, so a
label file may cover only part of a model's output range. `LabelSet.model` names
the weights, so swapping models is a label-file change and never a Dart change.

**Never ship a build against COCO weights.** Its `metrics` are zeroed and its
`_comment` says so; it detects tableware, not litter.

The `.tflite` is a binary of several MB. Keep it out of git history — either
Git LFS or fetch it in CI from wherever the trained artefact lives.

## The contract

`Detector` is written against fixed tensor shapes and refuses to load anything
else, so a bad export fails at startup instead of quietly returning nonsense:

```
input   (1, 640, 640, 3)  float32, 0..1, letterboxed with fill (114,114,114)
output  (1, 300, 6)       float32, [x1, y1, x2, y2, conf, classId]
                          coords in letterboxed 640px pixels
                          rows sorted by confidence, descending
```

YOLO26 is NMS-free, which is why there is no non-max suppression in the Dart
code — the graph already emits its final boxes. Swapping in a YOLO11-family
model would mean writing that NMS pass, because its raw output is
`(1, 4+nc, 8400)` instead.

Class order in `ecoquest_labels.json` is the model's output index. Append new
classes at the end; reordering them silently mislabels every detection a shipped
build makes.
