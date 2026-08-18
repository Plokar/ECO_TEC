"""Guards the class-index contract between the training notebook and the app.

Class order in the notebook IS the model's output index, and the app maps those
indices straight onto ecoquest_labels.json. If the two drift, every detection a
shipped build makes is mislabeled and nothing errors. Run: python ml/test_taxonomy.py

# ponytail: TACO's 60 category names are pasted in below rather than fetched from
# the repo, so this runs offline. Refresh them if TACO ever adds a category.
"""

import ast
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NOTEBOOK = ROOT / "ml" / "EcoQuest_YOLO26_TACO2.ipynb"
APP_LABELS = ROOT / "mobile" / "assets" / "models" / "ecoquest_labels.json"

TACO_CATEGORIES = """Cigarette;Broken glass;Glass bottle;Glass cup;Glass jar;Aerosol;
Aluminium blister pack;Aluminium foil;Drink can;Food Can;Metal bottle cap;Metal lid;Pop tab;
Scrap metal;Food waste;Battery;Rope & strings;Shoe;Unlabeled litter;Corrugated carton;
Drink carton;Egg carton;Magazine paper;Meal carton;Normal paper;Other carton;Paper bag;Paper cup;
Paper straw;Pizza box;Plastified paper bag;Tissues;Toilet tube;Wrapping paper;Carded blister pack;
Clear plastic bottle;Crisp packet;Disposable food container;Disposable plastic cup;Foam cup;
Foam food container;Garbage bag;Other plastic;Other plastic bottle;Other plastic container;
Other plastic cup;Other plastic wrapper;Plastic bottle cap;Plastic film;Plastic glooves;Plastic lid;
Plastic straw;Plastic utensils;Polypropylene bag;Single-use carrier bag;Six pack rings;Spread tub;
Squeezable tube;Styrofoam piece;Tupperware"""


def notebook_namespace():
    """Run the notebook's config and mapping cells in isolation."""
    cells = ["".join(c["source"]) for c in json.loads(NOTEBOOK.read_text(encoding="utf-8"))["cells"]]

    for i, source in enumerate(cells):
        # Shell/magic lines aren't Python; keep the indentation so bodies stay valid.
        stripped = re.sub(r"^(\s*)[!%].*$", r"\1pass", source, flags=re.M)
        try:
            ast.parse(stripped)
        except SyntaxError as e:
            if json.loads(NOTEBOOK.read_text(encoding="utf-8"))["cells"][i]["cell_type"] == "code":
                raise AssertionError(f"cell {i} does not parse: {e}") from e

    config = next(s for s in cells if "ECOQUEST_CLASSES = [" in s)
    mapping = next(s for s in cells if "NAME_MAP = {" in s)
    ns = {}
    # Don't touch Drive paths, and stop before the cell needs TACO's annotations.
    exec(config.replace('Path("/content/drive/MyDrive/ecoquest")', "Path('.')")
               .replace("ROOT.mkdir(parents=True, exist_ok=True)", ""), ns)
    exec(mapping.split("cat_to_cls =")[0], ns)
    return ns


def main():
    ns = notebook_namespace()
    classes, name_map, to_ecoquest = ns["ECOQUEST_CLASSES"], ns["NAME_MAP"], ns["to_ecoquest"]
    names = [n.strip() for n in TACO_CATEGORIES.replace("\n", "").split(";")]

    assert len(names) == 60, f"expected TACO's 60 categories, have {len(names)}"
    assert len(set(classes)) == len(classes), f"duplicate class: {classes}"
    assert set(ns["CLASS_META"]) == set(classes)

    # Every TACO name must hit NAME_MAP exactly. The keyword fallback exists so a
    # renamed category lands in other_litter instead of crashing -- not as the norm.
    fallback = [n for n in names if n.strip().lower() not in name_map]
    assert not fallback, f"these fell through to the keyword fallback: {fallback}"
    unknown = {to_ecoquest(n) for n in names} - set(classes)
    assert not unknown, f"mapped to classes that don't exist: {unknown}"

    app = json.loads(APP_LABELS.read_text(encoding="utf-8"))["classes"]
    assert [c["name"] for c in app] == classes, (
        f"app taxonomy {[c['name'] for c in app]} != notebook {classes}")
    assert [c["id"] for c in app] == list(range(len(classes))), "app class ids must be 0..n-1"
    for c in app:
        assert c["bin"] == ns["CLASS_META"][c["name"]]["bin"], f"bin drift on {c['name']}"
        assert c["points"] == ns["CLASS_META"][c["name"]]["points"], f"points drift on {c['name']}"

    print(f"OK  {len(classes)} classes: {', '.join(classes)}")
    print("OK  60/60 TACO categories mapped by exact name")
    print("OK  app labels JSON matches the notebook taxonomy")
    print("   ", dict(Counter(to_ecoquest(n) for n in names)))


if __name__ == "__main__":
    main()
