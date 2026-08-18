import 'dart:convert';
import 'dart:math' show sqrt;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

// ---------------------------------------------------------------------------
// Model taxonomy — shipped alongside the weights in assets/models/
// ---------------------------------------------------------------------------

/// One litter class the detector knows about, plus what it's worth in-game.
/// Points and CO₂ live in the label file, not in Dart, so the taxonomy can
/// never drift apart from the weights it was trained with.
class LitterClass {
  const LitterClass({
    required this.id,
    required this.name,
    required this.points,
    required this.bin,
    required this.co2g,
  });

  final int id;
  final String name;
  final int points;

  /// Which bin the app tells the user to use: plastic/glass/metal/paper/bio/general.
  final String bin;

  /// Grams of CO₂ avoided per item. Shown with its basis, never as a bare claim.
  final int co2g;

  factory LitterClass.fromJson(Map<String, dynamic> j) => LitterClass(
    id: j['id'] as int,
    name: j['name'] as String,
    points: j['points'] as int,
    bin: j['bin'] as String,
    co2g: j['co2_g'] as int,
  );

  String get displayName => switch (name) {
    'other_litter' => 'Other litter',
    _ => name[0].toUpperCase() + name.substring(1),
  };
}

/// Parsed `ecoquest_labels.json`. Also carries the tensor contract, so a model
/// swap that changes the contract fails loudly at load instead of silently
/// producing nonsense detections.
class LabelSet {
  const LabelSet({
    required this.classes,
    required this.imgsz,
    required this.confThreshold,
    required this.map50,
  });

  final List<LitterClass> classes;
  final int imgsz;
  final double confThreshold;
  final double map50;

  static Future<LabelSet> load([
    String asset = 'assets/models/ecoquest_labels.json',
  ]) async {
    final j = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;

    final input = j['input'] as Map<String, dynamic>;
    final output = j['output'] as Map<String, dynamic>;
    final layout = (output['layout'] as List).cast<String>();
    if (layout.join(',') != 'x1,y1,x2,y2,conf,class') {
      throw StateError(
        'Model output layout changed to $layout. The Dart decoder expects '
        '[x1,y1,x2,y2,conf,class]. Update Detector._decode before shipping.',
      );
    }
    if (input['dtype'] != 'float32') {
      throw StateError('Model input must be float32, got ${input['dtype']}.');
    }

    return LabelSet(
      classes: (j['classes'] as List)
          .map((c) => LitterClass.fromJson(c as Map<String, dynamic>))
          .toList(),
      imgsz: j['imgsz'] as int,
      confThreshold: (j['conf_threshold'] as num).toDouble(),
      map50: ((j['metrics'] as Map)['map50'] as num).toDouble(),
    );
  }

  LitterClass? byId(int id) =>
      id >= 0 && id < classes.length ? classes[id] : null;
}

/// One detected object, in the coordinate space of the *original* photo.
class Detection {
  const Detection({
    required this.cls,
    required this.confidence,
    required this.box,
  });

  final LitterClass cls;
  final double confidence;
  final Rect box;

  Map<String, dynamic> toJson() => {
    'class': cls.name,
    'conf': double.parse(confidence.toStringAsFixed(3)),
    'box': [box.left, box.top, box.right, box.bottom]
        .map((v) => v.roundToDouble())
        .toList(),
  };
}

// ---------------------------------------------------------------------------
// Quests
// ---------------------------------------------------------------------------

/// How a quest gets proven. `selfReport` results are labelled as such in the UI
/// and excluded from city/country totals — see BRANDING.md §7.
enum Verification { aiPhoto, selfReport }

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.targetClasses,
    required this.targetCount,
    required this.xpReward,
    required this.pointsReward,
    required this.verification,
    this.sponsorName,
    this.sponsorLogoUrl,
  });

  final String id;
  final String title;
  final String description;

  /// Detector class names that count toward this quest. Empty = any litter.
  final List<String> targetClasses;
  final int targetCount;
  final int xpReward;
  final int pointsReward;
  final Verification verification;

  /// Sponsored quests always render a visible `Sponsored by X` label.
  final String? sponsorName;
  final String? sponsorLogoUrl;

  bool get isSponsored => sponsorName != null;

  bool counts(String className) =>
      targetClasses.isEmpty || targetClasses.contains(className);

  factory Quest.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return Quest(
      id: d.id,
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      targetClasses: ((j['targetClasses'] as List?) ?? const []).cast<String>(),
      targetCount: (j['targetCount'] as num?)?.toInt() ?? 1,
      xpReward: (j['xpReward'] as num?)?.toInt() ?? 0,
      pointsReward: (j['pointsReward'] as num?)?.toInt() ?? 0,
      verification: j['verification'] == 'self_report'
          ? Verification.selfReport
          : Verification.aiPhoto,
      sponsorName: j['sponsorName'] as String?,
      sponsorLogoUrl: j['sponsorLogoUrl'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------

class Streak {
  const Streak({required this.current, required this.longest, this.lastActionDay});

  final int current;
  final int longest;

  /// Local day of the last counted action, as `yyyy-MM-dd`.
  final String? lastActionDay;

  factory Streak.fromJson(Map<String, dynamic>? j) => Streak(
    current: (j?['current'] as num?)?.toInt() ?? 0,
    longest: (j?['longest'] as num?)?.toInt() ?? 0,
    lastActionDay: j?['lastActionDay'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'current': current,
    'longest': longest,
    'lastActionDay': lastActionDay,
  };

  /// Advances the streak for an action taken on [today].
  ///
  /// Same day → unchanged (one action a day is what counts). Yesterday →
  /// continues. Anything older, or never → restarts at 1.
  Streak advance(DateTime today) {
    final day = dayKey(today);
    if (lastActionDay == day) return this;
    final continues = lastActionDay == dayKey(today.subtract(const Duration(days: 1)));
    final next = continues ? current + 1 : 1;
    return Streak(
      current: next,
      longest: next > longest ? next : longest,
      lastActionDay: day,
    );
  }

  /// True once the streak is stale enough to be lost — used for the warning UI.
  bool isBrokenOn(DateTime today) {
    if (lastActionDay == null) return false;
    final yesterday = dayKey(today.subtract(const Duration(days: 1)));
    return lastActionDay != dayKey(today) && lastActionDay != yesterday;
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.xp,
    required this.ecoPoints,
    required this.streak,
    required this.classCounts,
    required this.co2SavedG,
    required this.friends,
    this.photoUrl,
    this.city,
    this.country,
    this.school,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? city;
  final String? country;
  final String? school;
  final int xp;
  final int ecoPoints;
  final Streak streak;

  /// Verified item count per detector class, e.g. `{plastic: 47, metal: 12}`.
  final Map<String, int> classCounts;
  final int co2SavedG;
  final List<String> friends;

  int get itemsCollected => classCounts.values.fold(0, (a, b) => a + b);

  /// Level curve: each level costs 250 XP more than the last, so level N sits at
  /// 125·N·(N−1) XP total. Cheap early, meaningful later. Inverted here.
  int get level => (0.5 + sqrt(0.25 + xp / 125.0)).floor().clamp(1, 999);
  int get xpIntoLevel => xp - xpForLevel(level);
  int get xpForNextLevel => xpForLevel(level + 1) - xpForLevel(level);
  double get levelProgress =>
      xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  static int xpForLevel(int level) => (125 * level * (level - 1));

  /// Broader EcoScore — action mix, not just volume, so one heavy category
  /// can't carry the whole score. Capped at 1000.
  int get ecoScore {
    final variety = classCounts.values.where((c) => c > 0).length;
    return (itemsCollected * 4 + streak.longest * 12 + variety * 30 + ecoPoints ~/ 4)
        .clamp(0, 1000);
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? const {};
    return UserProfile(
      uid: d.id,
      displayName: (j['displayName'] as String?) ?? 'Player',
      photoUrl: j['photoUrl'] as String?,
      city: j['city'] as String?,
      country: j['country'] as String?,
      school: j['school'] as String?,
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      ecoPoints: (j['ecoPoints'] as num?)?.toInt() ?? 0,
      streak: Streak.fromJson(j['streak'] as Map<String, dynamic>?),
      classCounts:
          ((j['classCounts'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
      co2SavedG: (j['co2SavedG'] as num?)?.toInt() ?? 0,
      friends: ((j['friends'] as List?) ?? const []).cast<String>(),
    );
  }
}

// ---------------------------------------------------------------------------
// Map & rewards
// ---------------------------------------------------------------------------

enum PinKind { litterHotspot, recyclingPoint, cleanupEvent, completedQuest }

class MapPin {
  const MapPin({
    required this.id,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.title,
    this.resolved = false,
  });

  final String id;
  final PinKind kind;
  final double lat;
  final double lng;
  final String title;
  final bool resolved;

  factory MapPin.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return MapPin(
      id: d.id,
      kind: PinKind.values.firstWhere(
        (k) => k.name == j['kind'],
        orElse: () => PinKind.litterHotspot,
      ),
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      title: (j['title'] as String?) ?? '',
      resolved: (j['resolved'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'lat': lat,
    'lng': lng,
    'title': title,
    'resolved': resolved,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.partner,
    required this.costPoints,
    required this.stock,
    this.terms,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String partner;
  final int costPoints;
  final int stock;
  final String? terms;
  final String? imageUrl;

  bool get soldOut => stock <= 0;

  factory Reward.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return Reward(
      id: d.id,
      title: j['title'] as String,
      partner: (j['partner'] as String?) ?? '',
      costPoints: (j['costPoints'] as num?)?.toInt() ?? 0,
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      terms: j['terms'] as String?,
      imageUrl: j['imageUrl'] as String?,
    );
  }
}

/// Leaderboard scopes, in the hierarchy the product is built around:
/// World → Country → City → School → Friends.
enum Scope { friends, school, city, country, global }

extension ScopeLabel on Scope {
  String get title => switch (this) {
    Scope.friends => 'Friends',
    Scope.school => 'School',
    Scope.city => 'City',
    Scope.country => 'Country',
    Scope.global => 'Global',
  };
}
