# EcoQuest

> Save the planet. Beat your friends.

EcoQuest is a social game built around real-world environmental action. Players
take on a Quest, photograph what they did, see the on-device detector verify it,
then earn XP, EcoPoints and a place on the leaderboard.

It is not a recycling tracker and it does not rely on guilt. The product turns a
good intention into a visible, competitive loop:

```text
Quest → real-world action → photo → visible verification → reward → competition
```

**Status:** early product build · Android-first · EcoTech B.V.

## What makes EcoQuest different

- **Verification people can see.** The detector draws boxes and names classes on
  the captured image instead of returning a black-box approval.
- **Instant rewards.** Detection runs on the phone, so XP can land before the
  network catches up.
- **Competition with a place attached.** Players can compare friends, schools,
  cities and countries through EcoScore, streaks and leaderboards.
- **Offline by design.** Picking up litter in a park should not depend on a
  perfect connection. Writes queue locally and reconcile later.
- **Claims with a basis.** CO₂ estimates show their methodology, self-reported
  actions are labelled, and sponsored Quests remain visibly sponsored.

## Product surface

| Surface | What the player gets |
|---|---|
| **Home** | Daily Quest, progress, XP, EcoPoints and Streak state |
| **Capture** | One-tap camera flow with on-device litter detection |
| **Eco Map** | Nearby hotspots, recycling points and cleanup events |
| **Social** | Friends, activity and city/school/country competition |
| **Rewards** | EcoPoints redemption with partner terms and stock |
| **Trashdex** | A collection view of discovered litter classes |
| **Profile** | Level curve, impact totals, badges and streak history |

## Repository map

| Directory | Purpose | Main technology |
|---|---|---|
| [mobile/](mobile/) | Player-facing Android/iOS application | Flutter, Dart, TFLite, Firebase |
| [ml/](ml/) | Litter-detector training and export notebooks | YOLO26, Ultralytics, Colab |
| [firebase/](firebase/) | Rules, indexes, seed data and query checks | Firestore, Storage, Admin SDK |
| [web/](web/) | Public marketing and download site | Next.js, React, Tailwind |
| [BRANDING.md](BRANDING.md) | Product voice, visual tokens and impact rules | Design source of truth |

## Quick start

### Mobile app

Prerequisites: Flutter 3.44+, a configured Firebase project, and a device or
emulator. From the repository root:

```bash
cd mobile
flutter pub get
flutter run
```

The generated Firebase options are intentionally project-specific. For a new
environment, configure them with FlutterFire:

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

In Firebase Console, enable **Email/Password** and **Anonymous** sign-in,
create **Firestore** and **Storage**, then deploy the backend configuration:

```bash
cd firebase
npm install
firebase login
firebase use <your-firebase-project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node seed.mjs
```

Never commit `serviceAccount.json`. It is a full-admin credential and belongs in
your local environment or secret manager only.

### Web site

```bash
cd web
npm install
npm run dev       # http://localhost:3000
npm run lint
npm run build
```

The site contains the landing page plus `/schools`, `/cities`, `/partners`,
`/pricing`, `/about` and `/download`. It is designed to prerender and deploy to
Vercel or another static-friendly host.

Optional deployment variables are documented in
[web/.env.example](web/.env.example):

- `NEXT_PUBLIC_FORM_ENDPOINT` enables the launch-email form.
- `NEXT_PUBLIC_APK_URL` points the download page at an externally hosted APK.

## Model pipeline

The app's photo-verification flow expects a YOLO26 TFLite export. The training
notebook uses [TACO](http://tacodataset.org) and maps its 60 fine-grained labels
to the seven classes used by EcoQuest:

```text
plastic · glass · metal · paper · cigarette · organic · other_litter
```

To create the model:

1. Open [ml/EcoQuest_YOLO26_TACO.ipynb](ml/EcoQuest_YOLO26_TACO.ipynb) in Google
   Colab.
2. Select a GPU runtime. A T4 is sufficient.
3. Run all cells and download `ecoquest_model.zip` from the final cell.
4. Extract `ecoquest_yolo26n.tflite` and `ecoquest_labels.json` into
   [mobile/assets/models/](mobile/assets/models/).

The export is checked against the Dart tensor contract before it is accepted.
The expected input is `(1, 640, 640, 3)` float32, letterboxed with
`(114, 114, 114)`. The output is `(1, 300, 6)` with
`[x1, y1, x2, y2, confidence, classId]` in letterboxed pixel coordinates.

The trained TFLite weights are generated assets and are intentionally not kept
in Git. See [mobile/assets/models/README.md](mobile/assets/models/README.md) for
the export details and the stock COCO model used for development checks.

## Architecture

```text
Flutter app
├── screens/              sign-in, home, capture, map, social, rewards, profile
├── services/             auth, Firestore, Storage and location
├── ml/detector.dart      TFLite inference in a background isolate
├── models.dart            data models, levels, Streaks and EcoScore
├── widgets.dart           shared UI and detection-box painter
└── theme/tokens.dart      app design tokens

Firebase
├── Firestore              profiles, Quests, submissions, leagues and rewards
├── Storage                captured submission photos
├── firestore.rules        write boundaries and data validation
└── seed.mjs               initial Quests, rewards and map pins
```

### Important implementation decisions

**YOLO26 does not use Dart-side NMS.** The exported graph emits its final 300
boxes already sorted by confidence. The Dart decoder applies the threshold and
undoes letterboxing. A YOLO11-family export would require a separate NMS pass.

**Rewards do not wait for a transaction.** Batched writes and
`FieldValue.increment` support offline use and reconcile on reconnect. Streaks
are calculated from the cached profile for the same reason.

**Streams are the state layer.** Firestore streams and `StreamBuilder` keep the
profile state shared across the app without introducing a second state-management
framework.

## Quality checks

```bash
cd mobile
flutter analyze
flutter test
```

The current test suite focuses on pure game rules: Streaks, the level curve,
EcoScore and formatting. Firebase query coverage can be checked from
`firebase/` after credentials are configured:

```bash
cd firebase
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node verify_queries.mjs
```

## Verified status

The current build has been exercised on a moto g32 running Android 13 (arm64).
The verified path includes Firebase initialization, anonymous sign-in, profile
creation through the rules, the level curve, deterministic daily Quest rotation,
sponsor and self-reported labels, graceful location denial, and an OSM map with a
real GPS fix.

The complete camera → detect → claim path still requires the trained model and
has not been treated as release-verified. A passing static analysis run is not a
substitute for testing that flow on a physical device.

## Known limitations

| Area | Current behaviour | Next hardening step |
|---|---|---|
| Photo verification | Detection runs on the client, so a modified client can fake a plausible result. | Re-run detection in a Cloud Function and enable App Check. |
| League totals | Signed-in clients can currently increment city totals. | Move league aggregation server-side. |
| Upload recovery | XP can be awarded when the photo upload fails. | Add a retry queue and moderation state. |
| Map queries | Latitude is filtered server-side; longitude is filtered on the client. | Use geohash prefixes as pin volume grows. |
| Friend rules | The rules compile, but the set-difference path needs emulator coverage. | Test add/remove and third-party UID cases against the emulator. |
| Authentication | Email/password and anonymous sign-in are configured; Google and Apple are not. | Add provider-specific signing and consent configuration. |
| Notifications | There are no push notifications yet. | Add opt-in Streak reminders. |

## Trust rules

These product rules are part of the implementation contract, not just marketing:

- Every CO₂ figure shows its basis or a defensible range.
- Self-reported actions are visibly labelled and never enter city, school or
  country aggregates.
- Sponsored Quests always show `Sponsored by <name>`.
- EcoQuest+ cannot buy XP, EcoPoints or rank.

For the full visual and language system, see [BRANDING.md](BRANDING.md).
