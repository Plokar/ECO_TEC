// PLACEHOLDER — replace this whole file by running, from `mobile/`:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure --project=<your-firebase-project-id>
//
// That writes the real values and also drops `android/app/google-services.json`
// and the iOS `GoogleService-Info.plist` into place. Until then the app builds
// but stops at launch with the message below, rather than failing somewhere
// deep inside the Firebase SDK.
//
// This file is normally generated and git-ignored. It is checked in here only
// so the project analyzes and compiles before Firebase is wired up.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

const _placeholder = 'REPLACE_ME';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const options = {
      TargetPlatform.android: FirebaseOptions(
        apiKey: _placeholder,
        appId: _placeholder,
        messagingSenderId: _placeholder,
        projectId: _placeholder,
        storageBucket: _placeholder,
      ),
      TargetPlatform.iOS: FirebaseOptions(
        apiKey: _placeholder,
        appId: _placeholder,
        messagingSenderId: _placeholder,
        projectId: _placeholder,
        storageBucket: _placeholder,
        iosBundleId: 'com.ecotech.ecoquest',
      ),
    };

    final platform = options[defaultTargetPlatform];
    if (platform == null) {
      throw UnsupportedError(
        'EcoQuest targets Android and iOS. $defaultTargetPlatform is not configured.',
      );
    }
    if (platform.apiKey == _placeholder) {
      throw UnsupportedError(
        'Firebase is not configured yet.\n\n'
        'Run this from the mobile/ directory:\n'
        '  dart pub global activate flutterfire_cli\n'
        '  flutterfire configure --project=<your-firebase-project-id>\n\n'
        'It overwrites lib/firebase_options.dart with your real project values.',
      );
    }
    return platform;
  }
}
