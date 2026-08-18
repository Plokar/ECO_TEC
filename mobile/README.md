# EcoQuest — mobile app

```bash
flutter pub get
flutter run
```

Firebase must be configured first, or the app stops at launch with instructions:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

The detector needs `assets/models/ecoquest_yolo26n.tflite`, produced by
[../ml/EcoQuest_YOLO26_TACO.ipynb](../ml/EcoQuest_YOLO26_TACO.ipynb). See
[assets/models/README.md](assets/models/README.md) for the tensor contract the
Dart code is written against.

Setup, architecture notes and the known-gaps table live in the
[root README](../README.md).

```bash
flutter analyze
flutter test    # game rules: streaks, level curve, EcoScore
```

## Android build notes

**JVM target mismatch.** `tflite_flutter` 0.12.1 pins its Android module to Java 11
and declares no Kotlin JVM target, so Kotlin defaults to the toolchain's 21 and
Gradle fails `:tflite_flutter:compileDebugKotlin` on the inconsistency. Worked
around with `kotlin.jvm.target.validation.mode=warning` in
[android/gradle.properties](android/gradle.properties) — safe here because D8/R8
dexes every module, so mixed class-file versions never reach a device. Remove the
line if the plugin ever ships a matching `jvmTarget`.

**`minSdk` is pinned to 24** in [android/app/build.gradle.kts](android/app/build.gradle.kts)
rather than following `flutter.minSdkVersion`; 23 is the floor for `firebase_auth`.

**`noCompress += "tflite"`** is set in the same file. Without it the model can't be
memory-mapped and either fails to load or copies 6 MB onto the heap.

**KGP warning.** `firebase_storage` applies the Kotlin Gradle Plugin directly, which
future Flutter versions will reject. Not currently breaking — it needs an upstream
fix in the plugin, not here.

The first `flutter build apk` runs long (~20 min) because Gradle fetches the
Android SDK 35 platform and its dependency graph. Later builds are minutes.

### Size

Measured, before the model asset is added:

| Build | Size |
|---|---|
| `app-debug.apk` | 190 MB |
| `app-arm64-v8a-release.apk` | 27.7 MB |
| `app-armeabi-v7a-release.apk` | 23.2 MB |
| `app-x86_64-release.apk` | 30.9 MB |

The debug figure looks alarming and isn't — it carries all three ABIs, no R8 and
full debug symbols. Ship with `--split-per-abi` (or an app bundle). Adding the
~6 MB `.tflite` puts arm64 release around 34 MB.

`tflite_flutter` pulls in `litert-gpu` alongside `litert` even though the detector
runs on CPU via XNNPACK. Excluding it looks like an easy size win; the release
numbers above say it isn't worth the risk of breaking native library loading.
