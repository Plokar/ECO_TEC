"""Turn trained weights into the .tflite the Flutter app loads, and install it.

The notebook exports TFLite too, but that step is the one that fails in Colab
(the onnx -> tf -> tflite chain fights Colab's TensorFlow), which is how a
trained run ends up shipping only an .onnx the app cannot read. Run this
locally on whatever the notebook did hand back:

    pip install ultralytics onnx onnxslim onnx2tf ai_edge_litert tensorflow tf_keras
    python ml/export_tflite.py ml/ecoquest_model/best.pt

It converts, gates the result against the app's tensor contract, measures which
coordinate space the graph actually returns, and copies both the weights and the
label file into mobile/assets/models/.

Coordinate space is measured rather than assumed on purpose. The same weights
export two different ways: ONNX emits 640px pixels, TFLite emits 0..1 and leaves
the multiply to the caller. They are indistinguishable from the tensor shape, so
the app reads `output.coords` out of the label file and scales accordingly —
guess it wrong and every box lands in the top-left corner.
"""

import argparse
import json
import shutil
import sys
from pathlib import Path

IMGSZ = 640
ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "mobile" / "assets" / "models"


def export(weights: Path, imgsz: int = IMGSZ) -> Path:
    from ultralytics import YOLO

    return Path(YOLO(str(weights)).export(format="tflite", imgsz=imgsz, half=True))


def probe(tflite: Path, imgsz: int = IMGSZ) -> tuple[list[int], bool]:
    """Contract gate. Returns (output shape, boxes are normalised).

    A bad export fails here rather than on a phone, where the symptom is boxes
    in the wrong place rather than an error.
    """
    import numpy as np
    import tensorflow as tf

    interp = tf.lite.Interpreter(model_path=str(tflite))
    interp.allocate_tensors()
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    print(f"input  {inp['shape']} {inp['dtype'].__name__}")
    print(f"output {out['shape']} {out['dtype'].__name__}")

    assert tuple(inp["shape"]) == (1, imgsz, imgsz, 3), inp["shape"]
    assert inp["dtype"] == np.float32, inp["dtype"]
    assert out["dtype"] == np.float32, out["dtype"]
    assert len(out["shape"]) == 3 and out["shape"][2] == 6, (
        f"expected (1, N, 6) = [x1,y1,x2,y2,conf,cls], got {out['shape']}"
    )

    # Noise in, real forward pass out: this checks behaviour, not just shapes.
    rng = np.random.default_rng(0)
    x = (rng.random((1, imgsz, imgsz, 3), dtype=np.float32) * 0.6 + 0.2)
    interp.set_tensor(inp["index"], x)
    interp.invoke()
    det = interp.get_tensor(out["index"])[0]

    assert np.all(np.diff(det[:, 4]) <= 1e-5), "rows are not conf-sorted descending"
    assert 0.0 <= det[:, 4].max() <= 1.0, f"confidence out of range: {det[:, 4].max()}"

    # The two spaces are two orders of magnitude apart on a 640px model, so the
    # cutoff never has to be close. ponytail: a magnitude probe, not a proof —
    # if a future export ever emits pixels in a tiny image, read the graph.
    reach = float(abs(det[:, :4]).max())
    normalized = reach <= 2.0
    print(f"box magnitude {reach:.3f} -> {'normalized 0..1' if normalized else 'pixels'}")
    print("CONTRACT OK")
    return [int(v) for v in out["shape"]], normalized


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("weights", type=Path, help="trained .pt, e.g. ml/ecoquest_model/best.pt")
    ap.add_argument("--imgsz", type=int, default=IMGSZ)
    ap.add_argument(
        "--labels",
        type=Path,
        help="label file to update (default: ecoquest_labels.json next to the weights)",
    )
    args = ap.parse_args()

    labels_src = args.labels or args.weights.parent / "ecoquest_labels.json"
    if not labels_src.exists():
        print(f"no label file at {labels_src} — the notebook writes one next to the weights")
        return 1

    tflite = export(args.weights, args.imgsz)
    out_shape, normalized = probe(tflite, args.imgsz)

    labels = json.loads(labels_src.read_text(encoding="utf-8"))
    labels["output"]["shape"] = out_shape
    labels["output"]["coords"] = (
        "normalized 0..1" if normalized else f"pixels in letterboxed {args.imgsz}x{args.imgsz}"
    )

    ASSETS.mkdir(parents=True, exist_ok=True)
    shutil.copy(tflite, ASSETS / labels["model"])
    (ASSETS / "ecoquest_labels.json").write_text(
        json.dumps(labels, indent=2) + "\n", encoding="utf-8"
    )

    size = (ASSETS / labels["model"]).stat().st_size / 1e6
    print(f"\ninstalled {labels['model']} ({size:.1f} MB) and ecoquest_labels.json")
    print(f"mAP50 {labels['metrics']['map50']} at conf {labels['conf_threshold']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
