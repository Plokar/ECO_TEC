"""Regenerates EcoQuest_YOLO26_TACO.ipynb next to this file.

Edit the cells here, not the .ipynb — hand-editing notebook JSON is how you end up
with mangled escapes in a training script. Then:

    python build_notebook.py
"""
import json, pathlib

C = []
def md(s): C.append({"cell_type": "markdown", "metadata": {}, "source": s.strip("\n").splitlines(keepends=True)})
def code(s): C.append({"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [], "source": s.strip("\n").splitlines(keepends=True)})


md(r"""
# EcoQuest — YOLO26 litter detector

Trains a **YOLO26n** object detector on the **TACO** litter dataset and exports a
`.tflite` model for the EcoQuest Flutter app.

**Runtime → Change runtime type → GPU (T4 is enough).** Then *Runtime → Run all*
and leave it. Expect ~1.5–3 h on a T4.

What comes out at the end (cell 13 zips them):

| File | Goes to |
|---|---|
| `ecoquest_yolo26n.tflite` | `mobile/assets/models/` |
| `ecoquest_labels.json` | `mobile/assets/models/` |
| `ecoquest_yolo26n.onnx` | keep as backup runtime |
| `results.png`, `confusion_matrix.png` | your pitch deck |

The app decodes a fixed contract — **input `(1,640,640,3)` float32 `0..1`,
output `(1,300,6)` = `[x1,y1,x2,y2,conf,class]`** in letterboxed 640px pixel
coordinates. YOLO26 is NMS-free, so there is no NMS to run on the phone.
Cell 12 asserts this contract before you ship the model.
""")

md("## 1 · Environment")

code(r"""
!nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
%pip install -q "ultralytics>=8.4.75"

import torch, ultralytics
print("ultralytics", ultralytics.__version__)
print("torch      ", torch.__version__, "| cuda:", torch.cuda.is_available())
assert torch.cuda.is_available(), "No GPU. Runtime -> Change runtime type -> GPU."
""")

md("## 2 · Config\n\nThe only cell you normally touch.")

code(r'''
from pathlib import Path

MODEL      = "yolo26n.pt"   # n=nano (phone). s=small if you want +accuracy for ~3x size.
IMGSZ      = 640
EPOCHS     = 150
PATIENCE   = 30             # early-stop after N epochs with no val improvement
BATCH      = -1             # -1 = auto-fit to GPU memory
SEED       = 0

ROOT       = Path("/content/ecoquest")
DATA_DIR   = ROOT / "dataset"
RUNS       = ROOT / "runs"
ROOT.mkdir(exist_ok=True)

# EcoQuest's own taxonomy. Order IS the class index the app relies on -- append
# only, never reorder, or a shipped model starts reading the wrong labels.
ECOQUEST_CLASSES = [
    "plastic",      # 0
    "glass",        # 1
    "metal",        # 2
    "paper",        # 3
    "cigarette",    # 4
    "other_litter", # 5
]

# Points awarded per verified item, and which bin the app tells you to use.
CLASS_META = {
    "plastic":      {"points": 3, "bin": "plastic",   "co2_g": 40},
    "glass":        {"points": 4, "bin": "glass",     "co2_g": 70},
    "metal":        {"points": 5, "bin": "metal",     "co2_g": 150},
    "paper":        {"points": 2, "bin": "paper",     "co2_g": 20},
    "cigarette":    {"points": 4, "bin": "general",   "co2_g": 5},
    "other_litter": {"points": 2, "bin": "general",   "co2_g": 15},
}
assert set(CLASS_META) == set(ECOQUEST_CLASSES)
print(len(ECOQUEST_CLASSES), "classes:", ", ".join(ECOQUEST_CLASSES))
''')

md(r"""
## 3 · Get TACO

[TACO](http://tacodataset.org) = 1500 photos of litter in the wild, 4784 annotations,
60 fine-grained classes. The repo ships the COCO annotations; the images live on
Flickr and get pulled here.

Some Flickr links rot over time. This downloader skips failures and then drops the
missing images from the annotation set, so a few dead links cost you a few images
instead of the whole run.
""")

code(r'''
import json, concurrent.futures as cf, urllib.request, urllib.error, shutil, os

TACO_REPO = ROOT / "TACO"
if not TACO_REPO.exists():
    !git clone -q --depth 1 https://github.com/pedropro/TACO.git {TACO_REPO}

ann_path = TACO_REPO / "data" / "annotations.json"
taco = json.loads(ann_path.read_text())
print("images:", len(taco["images"]), "| annotations:", len(taco["annotations"]),
      "| categories:", len(taco["categories"]))

IMG_DIR = ROOT / "images"
IMG_DIR.mkdir(exist_ok=True)

def fetch(img):
    """Download one TACO image. Returns (id, ok). Prefers the 640px Flickr render."""
    dest = IMG_DIR / f"{img['id']}.jpg"
    if dest.exists() and dest.stat().st_size > 1024:
        return img["id"], True
    # 1034 of the 1500 have the small render; the rest fall back to full size.
    for key in ("flickr_640_url", "flickr_url", "coco_url"):
        url = img.get(key)
        if not url:
            continue
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r, open(dest, "wb") as f:
                shutil.copyfileobj(r, f)
            if dest.stat().st_size > 1024:
                return img["id"], True
        except Exception:
            continue
    dest.unlink(missing_ok=True)
    return img["id"], False

with cf.ThreadPoolExecutor(max_workers=32) as ex:
    results = dict(ex.map(fetch, taco["images"]))

have = {i for i, ok in results.items() if ok}
missing = len(results) - len(have)
print(f"downloaded {len(have)}/{len(results)} images ({missing} dead links skipped)")
assert len(have) > 1000, f"Only {len(have)} images -- TACO's Flickr links may have rotted badly. Stop and check."
''')

md(r"""
## 4 · Collapse 60 TACO classes → 7 EcoQuest classes

`NAME_MAP` below was checked against TACO's live `annotations.json`: all 60
category names match exactly, nothing falls through to the keyword fallback.

1500 images cannot support 60 classes, and the app does not need them — it needs to
know *which bin this goes in*. Mapping is by exact TACO name, with a keyword
fallback so a renamed or new category lands in `other_litter` instead of crashing.

Read the printed table. If anything sits in the wrong bucket, fix `NAME_MAP` and
re-run this cell only.
""")

code(r'''
import re
from collections import Counter

NAME_MAP = {
    # --- plastic ---
    "clear plastic bottle": "plastic", "other plastic bottle": "plastic",
    "plastic bottle cap": "plastic", "disposable plastic cup": "plastic",
    "foam cup": "plastic", "other plastic cup": "plastic", "plastic lid": "plastic",
    "other plastic": "plastic", "plastic film": "plastic", "six pack rings": "plastic",
    "garbage bag": "plastic", "other plastic wrapper": "plastic",
    "single-use carrier bag": "plastic", "polypropylene bag": "plastic",
    "crisp packet": "plastic", "spread tub": "plastic", "tupperware": "plastic",
    "disposable food container": "plastic", "foam food container": "plastic",
    "other plastic container": "plastic", "plastic glooves": "plastic",
    "plastic utensils": "plastic", "squeezable tube": "plastic",
    "plastic straw": "plastic", "styrofoam piece": "plastic",
    "carded blister pack": "plastic",
    # --- glass ---
    "glass bottle": "glass", "broken glass": "glass", "glass cup": "glass",
    "glass jar": "glass",
    # --- metal ---
    "metal bottle cap": "metal", "food can": "metal", "aerosol": "metal",
    "drink can": "metal", "metal lid": "metal", "pop tab": "metal",
    "scrap metal": "metal", "aluminium foil": "metal",
    "aluminium blister pack": "metal",
    # --- paper ---
    "toilet tube": "paper", "other carton": "paper", "egg carton": "paper",
    "drink carton": "paper", "corrugated carton": "paper", "meal carton": "paper",
    "pizza box": "paper", "paper cup": "paper", "magazine paper": "paper",
    "tissues": "paper", "wrapping paper": "paper", "normal paper": "paper",
    "paper bag": "paper", "plastified paper bag": "paper", "paper straw": "paper",
    # --- rest ---
    "cigarette": "cigarette",
    "food waste": "other_litter",   # only 8 boxes in TACO -- not its own class
    "rope & strings": "other_litter", "shoe": "other_litter",
    "battery": "other_litter", "unlabeled litter": "other_litter",
}

KEYWORDS = [
    (r"cigarette|butt",                  "cigarette"),
    (r"glass",                           "glass"),
    (r"alumin|metal|\bcan\b|tab|steel",  "metal"),
    (r"paper|carton|cardboard|tissue",   "paper"),
    (r"plastic|foam|styro|poly|wrapper", "plastic"),
]

def to_ecoquest(name: str) -> str:
    key = name.strip().lower()
    if key in NAME_MAP:
        return NAME_MAP[key]
    for pattern, cls in KEYWORDS:
        if re.search(pattern, key):
            return cls
    return "other_litter"

cat_to_cls = {c["id"]: to_ecoquest(c["name"]) for c in taco["categories"]}
unmapped = [c["name"] for c in taco["categories"] if c["name"].strip().lower() not in NAME_MAP]

print(f"{'TACO category':<28} {'supercategory':<24} -> EcoQuest")
print("-" * 74)
for c in sorted(taco["categories"], key=lambda c: (cat_to_cls[c["id"]], c["name"])):
    flag = "  ~keyword" if c["name"].strip().lower() not in NAME_MAP else ""
    print(f"{c['name'][:27]:<28} {c.get('supercategory','')[:23]:<24} -> {cat_to_cls[c['id']]}{flag}")

per_class = Counter(cat_to_cls[a["category_id"]] for a in taco["annotations"])
print("\nannotations per EcoQuest class:")
for name in ECOQUEST_CLASSES:
    n = per_class[name]
    print(f"  {name:<14} {n:>5}  {'#' * (n // 40)}")
if unmapped:
    print(f"\n{len(unmapped)} category name(s) hit the keyword fallback:", unmapped)
''')

md(r"""
## 5 · Write it out as a YOLO dataset

COCO boxes are absolute `[x, y, w, h]`; YOLO wants normalised centre `xywh`.
Normalising by the *annotation's* `width`/`height` (not the downloaded file's) keeps
the labels correct even though we pulled the smaller 640px renders.

Split is 80/20 by image, seeded, so re-running gives the same split.
""")

code(r'''
import random, yaml
from collections import defaultdict

by_image = defaultdict(list)
for a in taco["annotations"]:
    if a["image_id"] in have and not a.get("iscrowd", 0):
        by_image[a["image_id"]].append(a)

meta = {im["id"]: im for im in taco["images"]}
ids = sorted(by_image)                       # sorted -> deterministic before shuffle
random.Random(SEED).shuffle(ids)
split_at = int(len(ids) * 0.8)
splits = {"train": ids[:split_at], "val": ids[split_at:]}

if DATA_DIR.exists():
    shutil.rmtree(DATA_DIR)

kept = skipped = 0
for split, split_ids in splits.items():
    (DATA_DIR / "images" / split).mkdir(parents=True)
    (DATA_DIR / "labels" / split).mkdir(parents=True)
    for img_id in split_ids:
        im = meta[img_id]
        W, H = im["width"], im["height"]
        lines = []
        for a in by_image[img_id]:
            x, y, w, h = a["bbox"]
            cx, cy = (x + w / 2) / W, (y + h / 2) / H
            nw, nh = w / W, h / H
            # Clamp: a handful of TACO boxes overhang the image edge by a pixel.
            cx, cy = min(max(cx, 0.0), 1.0), min(max(cy, 0.0), 1.0)
            nw, nh = min(nw, 1.0), min(nh, 1.0)
            if nw <= 0.001 or nh <= 0.001:
                skipped += 1
                continue
            idx = ECOQUEST_CLASSES.index(cat_to_cls[a["category_id"]])
            lines.append(f"{idx} {cx:.6f} {cy:.6f} {nw:.6f} {nh:.6f}")
            kept += 1
        if not lines:
            continue
        os.link(IMG_DIR / f"{img_id}.jpg", DATA_DIR / "images" / split / f"{img_id}.jpg")
        (DATA_DIR / "labels" / split / f"{img_id}.txt").write_text("\n".join(lines))

data_yaml = DATA_DIR / "data.yaml"
data_yaml.write_text(yaml.safe_dump({
    "path": str(DATA_DIR),
    "train": "images/train",
    "val": "images/val",
    "names": {i: n for i, n in enumerate(ECOQUEST_CLASSES)},
}, sort_keys=False))

for split in splits:
    n = len(list((DATA_DIR / "images" / split).glob("*.jpg")))
    print(f"{split}: {n} images")
print(f"boxes kept: {kept} | degenerate boxes dropped: {skipped}")
print(data_yaml.read_text())
''')

md("### Sanity check — do the boxes land on the litter?\n\nIf these look wrong, the training will be wrong. Look before you spend 2 GPU-hours.")

code(r'''
import matplotlib.pyplot as plt, matplotlib.patches as patches
from PIL import Image

samples = sorted((DATA_DIR / "images" / "train").glob("*.jpg"))[:6]
fig, axes = plt.subplots(2, 3, figsize=(15, 10))
COLORS = plt.cm.tab10.colors

for ax, img_path in zip(axes.flat, samples):
    im = Image.open(img_path)
    ax.imshow(im)
    label_path = DATA_DIR / "labels" / "train" / f"{img_path.stem}.txt"
    for line in label_path.read_text().splitlines():
        idx, cx, cy, w, h = line.split()
        idx = int(idx)
        cx, cy, w, h = (float(v) for v in (cx, cy, w, h))
        x0, y0 = (cx - w / 2) * im.width, (cy - h / 2) * im.height
        ax.add_patch(patches.Rectangle((x0, y0), w * im.width, h * im.height,
                                       fill=False, lw=2, edgecolor=COLORS[idx]))
        ax.text(x0, y0 - 4, ECOQUEST_CLASSES[idx], color="white", fontsize=8,
                bbox=dict(facecolor=COLORS[idx], edgecolor="none", pad=1))
    ax.set_axis_off()
plt.tight_layout()
plt.show()
''')

md(r"""
## 6 · Train

TACO is small, so augmentation carries a lot of the weight here: mosaic and mixup
for scene variety, HSV jitter because litter is photographed in every light there
is, and `degrees`/`scale` because people shoot from wherever they are standing.

`mosaic` is switched off for the last 10 epochs (`close_mosaic`) so the model
finishes on real, uncomposited images.
""")

code(r'''
from ultralytics import YOLO

model = YOLO(MODEL)
results = model.train(
    data=str(data_yaml),
    epochs=EPOCHS,
    imgsz=IMGSZ,
    batch=BATCH,
    patience=PATIENCE,
    seed=SEED,
    project=str(RUNS),
    name="litter",
    exist_ok=True,
    cache="ram",          # 1500 images fit comfortably; big speedup
    close_mosaic=10,
    # augmentation
    hsv_h=0.015, hsv_s=0.7, hsv_v=0.4,
    degrees=10.0, translate=0.1, scale=0.6, fliplr=0.5,
    mosaic=1.0, mixup=0.1,
    plots=True,
)
BEST = Path(model.trainer.best)
print("best weights:", BEST)
''')

md("## 7 · Validate\n\n`mAP50` is the number to quote in the pitch. Per-class rows tell you which bins the model actually understands.")

code(r'''
best = YOLO(str(BEST))
m = best.val(data=str(data_yaml), imgsz=IMGSZ, plots=True)

print(f"\nmAP50    {m.box.map50:.3f}")
print(f"mAP50-95 {m.box.map:.3f}")
print(f"\n{'class':<14} {'images':>7} {'P':>7} {'R':>7} {'mAP50':>7}")
print("-" * 46)
for i, ci in enumerate(m.ap_class_index):
    p, r, ap50 = m.box.p[i], m.box.r[i], m.box.ap50[i]
    print(f"{ECOQUEST_CLASSES[ci]:<14} {int(m.nt_per_class[ci]):>7} {p:>7.3f} {r:>7.3f} {ap50:>7.3f}")

if m.box.map50 < 0.35:
    print("\nmAP50 is low. Usual fixes, in order: more epochs, MODEL='yolo26s.pt',"
          "\nor merge the weakest classes into other_litter.")
''')

code(r'''
from IPython.display import Image as Show, display
run = RUNS / "litter"
for plot in ("results.png", "confusion_matrix_normalized.png", "val_batch0_pred.jpg"):
    if (run / plot).exists():
        print(plot)
        display(Show(filename=str(run / plot), width=900))
''')

md(r"""
## 8 · Export to TFLite

**float16, not int8.** float16 keeps float32 input/output tensors, so the Dart side
stays plain floats with no quantisation scale/zero-point arithmetic. yolo26n lands
around 6 MB either way — int8 would save ~3 MB and cost accuracy on a dataset this
small. Not a trade worth taking.

ONNX is exported too, as a backup runtime in case the TFLite conversion of YOLO26's
NMS-free head misbehaves on a specific device.
""")

code(r'''
# Ultralytics pulls the rest of the TFLite conversion chain itself on first use.
# Pre-installing all of it tends to pin a TensorFlow version that then fights
# with Colab's, so only onnx goes in up front.
%pip install -q onnx onnxslim

exported = {}
for fmt, kwargs in (("tflite", {"half": True}), ("onnx", {"opset": 19})):
    try:
        exported[fmt] = Path(YOLO(str(BEST)).export(format=fmt, imgsz=IMGSZ, **kwargs))
        print(f"OK   {fmt}: {exported[fmt]} ({exported[fmt].stat().st_size / 1e6:.1f} MB)")
    except Exception as e:
        print(f"FAIL {fmt}: {type(e).__name__}: {e}")

assert "tflite" in exported or "onnx" in exported, "Both exports failed -- nothing to ship."
''')

md(r"""
## 9 · Verify the contract the app depends on

The Flutter detector is written against a fixed tensor contract. If this cell
fails, **do not ship the model** — the app would silently read garbage. Fix the
export or tell the Flutter side the new shape.
""")

code(r'''
import numpy as np, tensorflow as tf
from PIL import Image   # re-imported so this gate stands alone if cells are re-run

if "tflite" in exported:
    interp = tf.lite.Interpreter(model_path=str(exported["tflite"]))
    interp.allocate_tensors()
    inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
    print("input ", inp["shape"], inp["dtype"].__name__, "quant:", inp["quantization"])
    print("output", out["shape"], out["dtype"].__name__, "quant:", out["quantization"])

    assert tuple(inp["shape"]) == (1, IMGSZ, IMGSZ, 3), f"unexpected input {inp['shape']}"
    assert inp["dtype"] == np.float32, f"input must be float32, got {inp['dtype']}"
    assert out["dtype"] == np.float32, f"output must be float32, got {out['dtype']}"
    assert len(out["shape"]) == 3 and out["shape"][2] == 6, (
        f"expected (1, N, 6) = [x1,y1,x2,y2,conf,cls], got {out['shape']}")

    # Real forward pass on a val image, so this checks behaviour and not just shapes.
    val_img = sorted((DATA_DIR / "images" / "val").glob("*.jpg"))[0]
    im = Image.open(val_img).convert("RGB")
    r = min(IMGSZ / im.width, IMGSZ / im.height)
    nw, nh = round(im.width * r), round(im.height * r)
    canvas = Image.new("RGB", (IMGSZ, IMGSZ), (114, 114, 114))
    canvas.paste(im.resize((nw, nh), Image.BILINEAR), ((IMGSZ - nw) // 2, (IMGSZ - nh) // 2))
    x = np.asarray(canvas, np.float32)[None] / 255.0

    interp.set_tensor(inp["index"], x)
    interp.invoke()
    det = interp.get_tensor(out["index"])[0]

    print(f"\n{val_img.name}: {len(det)} raw rows, coords in 0..{det[:, :4].max():.0f}")
    conf = det[:, 4]
    assert np.all(np.diff(conf) <= 1e-5), "rows are not sorted by confidence descending"
    assert 0.0 <= conf.max() <= 1.0, f"confidence out of range: {conf.max()}"
    keep = det[conf > 0.25]
    print(f"detections above 0.25: {len(keep)}")
    for x1, y1, x2, y2, c, cls in keep[:10]:
        print(f"  {ECOQUEST_CLASSES[int(cls)]:<14} {c:.2f}  "
              f"[{x1:.0f} {y1:.0f} {x2:.0f} {y2:.0f}]")
    assert det[:, :4].max() > 1.5, ("boxes look normalised, app expects 640px pixel "
                                    "coords -- tell the Flutter side")
    print("\nCONTRACT OK: input (1,640,640,3) f32 0..1 -> output (1,N,6) xyxy px, conf-sorted, NMS-free")
''')

md("## 10 · Labels file for the app\n\nShipped next to the model so class order, points and bin mapping can never drift apart from the weights.")

code(r'''
labels = {
    "model": "ecoquest_yolo26n.tflite",
    "arch": "yolo26n",
    "imgsz": IMGSZ,
    "nms_free": True,
    "input": {"shape": [1, IMGSZ, IMGSZ, 3], "dtype": "float32", "range": "0..1",
              "letterbox_fill": [114, 114, 114]},
    "output": {"shape": [1, 300, 6], "layout": ["x1", "y1", "x2", "y2", "conf", "class"],
               "coords": f"pixels in letterboxed {IMGSZ}x{IMGSZ}", "sorted_by_conf": True},
    "conf_threshold": 0.35,
    "metrics": {"map50": round(float(m.box.map50), 4), "map50_95": round(float(m.box.map), 4)},
    "classes": [
        {"id": i, "name": n,
         "points": CLASS_META[n]["points"],
         "bin": CLASS_META[n]["bin"],
         "co2_g": CLASS_META[n]["co2_g"]}
        for i, n in enumerate(ECOQUEST_CLASSES)
    ],
}
labels_path = ROOT / "ecoquest_labels.json"
labels_path.write_text(json.dumps(labels, indent=2))
print(labels_path.read_text())
''')

md("## 11 · Download\n\nUnzip into `mobile/assets/models/`. The Flutter app looks for exactly these two filenames.")

code(r'''
OUT = ROOT / "ecoquest_model"
if OUT.exists():
    shutil.rmtree(OUT)
OUT.mkdir()

if "tflite" in exported:
    shutil.copy(exported["tflite"], OUT / "ecoquest_yolo26n.tflite")
if "onnx" in exported:
    shutil.copy(exported["onnx"], OUT / "ecoquest_yolo26n.onnx")
shutil.copy(labels_path, OUT / "ecoquest_labels.json")
shutil.copy(BEST, OUT / "best.pt")
for plot in ("results.png", "confusion_matrix_normalized.png", "results.csv"):
    if (run / plot).exists():
        shutil.copy(run / plot, OUT / plot)

archive = shutil.make_archive(str(ROOT / "ecoquest_model"), "zip", OUT)
print("\n".join(f"{p.name:<34} {p.stat().st_size / 1e6:>6.1f} MB" for p in sorted(OUT.iterdir())))
print(f"\n{archive} ({Path(archive).stat().st_size / 1e6:.1f} MB)")

from google.colab import files
files.download(archive)
''')

md(r"""
---

### If it went badly

| Symptom | Fix |
|---|---|
| `Only N images` assert in cell 3 | TACO's Flickr links rotted. Grab a mirrored copy of the images and drop them in `/content/ecoquest/images/` as `{image_id}.jpg`, then re-run from cell 4. |
| mAP50 below ~0.35 | `MODEL = "yolo26s.pt"`, raise `EPOCHS`, or merge weak classes into `other_litter` in `NAME_MAP`. Small classes (`glass`) are the usual culprits — check the per-class table. |
| Colab disconnects mid-training | Re-run cells 1–5, then `YOLO(str(RUNS/"litter"/"weights"/"last.pt")).train(resume=True)`. Mount Drive and set `ROOT` there if it keeps happening. |
| TFLite export fails, ONNX succeeds | Ship the ONNX and switch the Flutter runtime — the `(1,300,6)` contract is identical, only the interpreter changes. |
| Contract assert fails in cell 9 | Do not ship. Paste the printed shapes to whoever owns the Flutter detector. |
""")

nb = {
    "cells": C,
    "metadata": {
        "accelerator": "GPU",
        "colab": {"provenance": [], "gpuType": "T4", "toc_visible": True},
        "kernelspec": {"display_name": "Python 3", "name": "python3"},
        "language_info": {"name": "python"},
    },
    "nbformat": 4,
    "nbformat_minor": 0,
}

out = pathlib.Path(__file__).with_name("EcoQuest_YOLO26_TACO.ipynb")
out.write_text(json.dumps(nb, indent=1), encoding="utf-8")
print("wrote", out, f"{len(C)} cells, {out.stat().st_size/1024:.0f} KB")
