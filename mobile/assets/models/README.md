# Model assets

Two files belong here. Both come out of [`ml/EcoQuest_YOLO26_TACO.ipynb`](../../../ml/EcoQuest_YOLO26_TACO.ipynb),
zipped by its last cell.

| File | Status |
|---|---|
| `ecoquest_labels.json` | placeholder committed — overwrite with the notebook's version |
| `ecoquest_yolo26n.tflite` | **missing** — train first, then drop it in |

Until the `.tflite` is here, everything except the camera verification step works;
`Detector.load()` throws and the verify screen shows the error rather than
pretending a photo passed.

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
