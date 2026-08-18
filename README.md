# EcoQuest — EcoTech B.V.

> Save the planet. Beat your friends.

A social game whose scoreboard is made of real environmental actions, verified on
the phone that took the photo.

| Directory | What it is | Stack |
|---|---|---|
| [ml/](ml/) | YOLO26 litter-detector training | Colab notebook, Ultralytics |
| [mobile/](mobile/) | The EcoQuest app | Flutter 3.44, TFLite, Firebase |
| [web/](web/) | Company marketing site | Next.js 16, Tailwind 4 |
| [firebase/](firebase/) | Security rules, indexes, seed data | Firestore, Storage |
| [BRANDING.md](BRANDING.md) | Colour, type, voice, impact-claim rules | — |
| [intoduction.md](intoduction.md) | The original concept document | — |

---

## Start here: train the model

Nothing in the app's verification step works without weights, and training takes
a couple of hours, so kick it off before anything else.

1. Open [ml/EcoQuest_YOLO26_TACO.ipynb](ml/EcoQuest_YOLO26_TACO.ipynb) in Google Colab.
2. **Runtime → Change runtime type → GPU** (a T4 is enough).
3. **Runtime → Run all**, then leave it. ~1.5–3 h.
4. The last cell downloads `ecoquest_model.zip`. Unzip
   `ecoquest_yolo26n.tflite` and `ecoquest_labels.json` into
   [mobile/assets/models/](mobile/assets/models/).

It trains on [TACO](http://tacodataset.org) (1500 photos, 4784 annotations) and
collapses TACO's 60 fine-grained classes into the 7 the app cares about —
`plastic, glass, metal, paper, cigarette, organic, other_litter`. All 60 name
mappings were checked against TACO's live annotation file, so nothing silently
falls through to the keyword fallback.

Cell 9 asserts the tensor contract the Dart code is written against and refuses
to bless a bad export. If it fails, don't ship the model.

---

## Mobile app

```bash
cd mobile
flutter pub get
flutter run
```

### Firebase is required first

`lib/firebase_options.dart` is a committed placeholder that throws a clear
message at launch. Replace it:

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

Then, in the Firebase console, enable **Email/Password** and **Anonymous**
sign-in, create **Firestore** and **Storage**, and deploy the rules and seed
data:

```bash
cd firebase
firebase deploy --only firestore:rules,firestore:indexes,storage

npm install firebase-admin
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node seed.mjs
```

The indexes matter — the city/school/country leaderboards fail at runtime
without them. The seed script is what gives the app its first quests, rewards
and map pins; `dailyQuest()` rotates through whatever sits in `quests`.

### How it's put together

```
lib/
  app.dart              service singletons + lazily-loaded detector
  models.dart           data models, level curve, streak rules, EcoScore
  ml/detector.dart      TFLite YOLO26, runs in a background isolate
  services/             auth, Firestore + Storage, location
  screens/              sign-in, home, capture+verify, map, social, rewards, profile
  theme/tokens.dart     brand tokens — the only place a hex belongs
  widgets.dart          shared widgets incl. the detection-box painter
```

Three decisions worth knowing before changing anything:

**No NMS in Dart.** YOLO26 is NMS-free — the exported graph emits its final 300
boxes already sorted by confidence. The decoder is a threshold and an
un-letterbox, nothing more. Swapping in a YOLO11-family model means writing that
NMS pass yourself, because its raw output is `(1, 4+nc, 8400)`.

**No Firestore transactions.** Transactions need connectivity, and litter gets
picked in parks without signal. Everything goes out as batched writes with
`FieldValue.increment`, which queue offline and reconcile on reconnect. Streaks
are computed client-side from the cached profile for the same reason.

**No state-management package.** Firestore streams plus `StreamBuilder` cover it;
the profile stream lives once in `HomeShell` and every tab reads the same live
state.

### Tests

```bash
cd mobile
flutter test      # game rules: streaks, level curve, EcoScore, formatting
flutter analyze
```

The tests cover the logic that decides what a player earns — pure Dart, no
Firebase or camera, under a second to run.

---

## Web

```bash
cd web
npm install
npm run dev      # http://localhost:3000
npm run build
```

Six static pages: landing, `/schools`, `/cities`, `/partners`, `/pricing`,
`/about`. All prerendered, no client-side data fetching, deploys to Vercel or any
static host as-is.

The launch email form posts to a `REPLACE_ME` Formspree endpoint — point it at
whatever list tool marketing actually uses. There is deliberately no API route
for one text field.

---

## Known gaps

Being explicit about these, because each one is a decision rather than an
oversight.

| Gap | Why, and what closes it |
|---|---|
| Verification is client-side | A patched client can claim a plausible reward. `firestore.rules` bounds the damage by validating resulting values, but the real fix is a Cloud Function re-running detection on the uploaded photo, plus App Check. |
| League totals are client-incremented | Anyone signed in can add to a city's score. Same fix: move the increment server-side. |
| Failed photo uploads aren't retried | The submission still lands and the XP is awarded; the photo is just absent and the UI says so. Add a retry queue when moderation needs to look at these. |
| Map queries bracket latitude only | Longitude is filtered client-side. Fine at city zoom; switch to geohash prefixes if pin volume grows. |
| `firestore.rules` friend logic is untested | The set-difference rule that lets you add only yourself to someone else's friend list needs verifying against the Firebase emulator before it's relied on. |
| Google / Apple sign-in | Email-password and anonymous only, because those need no per-flavour signing setup. Anonymous accounts can be linked to a real one without losing progress. |
| No push notifications | Streak reminders are the obvious retention lever and the obvious next thing to build. |

## Ground rules that are load-bearing

From [BRANDING.md](BRANDING.md) §7 — these are enforced in code, not just
documented:

- Every CO₂ figure shows its basis. No unexplained totals.
- Self-reported actions carry a visible label and never count toward city,
  school or country aggregates.
- Sponsored quests always render a visible `Sponsored by` label. No tier removes
  it.
- EcoQuest+ cannot buy XP, EcoPoints or rank.
