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
    required this.model,
    required this.normalized,
    required this.imgsz,
    required this.confThreshold,
    required this.map50,
  });

  final List<LitterClass> classes;
  final int imgsz;
  final double confThreshold;
  final double map50;

  /// Which weights this taxonomy belongs to. Named in the label file so a test
  /// build can point at a different `.tflite` without touching Dart.
  String get modelAsset => 'assets/models/$model';
  final String model;

  /// True when boxes come back in 0..1 and have to be multiplied by [imgsz].
  /// TFLite exports do; ONNX exports do not.
  final bool normalized;

  /// The label file the app loads. Overridable at build time, which is how the
  /// stock COCO yolo26n gets swapped in for testing:
  ///   flutter run --dart-define=ECOQUEST_LABELS=assets/models/coco_labels.json
  static const asset = String.fromEnvironment(
    'ECOQUEST_LABELS',
    defaultValue: 'assets/models/ecoquest_labels.json',
  );

  static Future<LabelSet> load([String asset = LabelSet.asset]) async {
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
    // Two coordinate spaces are in play and they look identical in a tensor
    // shape, so the label file has to say which one it is. The ONNX export
    // emits 640px pixels; the TFLite export emits 0..1 and expects the caller
    // to multiply by the input size, exactly as ultralytics' own TFLite backend
    // does. Guessing here would put every box in the top-left corner.
    final coords = output['coords'] as String? ?? '';
    final normalized = coords.contains('normal');
    if (!normalized && !coords.contains('pixel')) {
      throw StateError(
        'Model output coords is "$coords". Say either "normalized 0..1" or '
        '"pixels in letterboxed NxN" so the decoder knows how to scale.',
      );
    }
    if (input['dtype'] != 'float32') {
      throw StateError('Model input must be float32, got ${input['dtype']}.');
    }

    return LabelSet(
      classes: (j['classes'] as List)
          .map((c) => LitterClass.fromJson(c as Map<String, dynamic>))
          .toList(),
      model: j['model'] as String,
      normalized: normalized,
      imgsz: j['imgsz'] as int,
      confThreshold: (j['conf_threshold'] as num).toDouble(),
      map50: ((j['metrics'] as Map)['map50'] as num).toDouble(),
    );
  }

  /// Looks up by the declared `id`, not by list position, so a label file may
  /// cover only some of a model's classes. That is what lets the stock COCO
  /// model be used for testing: it maps the eight COCO ids that are actually
  /// litter and drops every detection of the other seventy-two.
  LitterClass? byId(int id) {
    for (final c in classes) {
      if (c.id == id) return c;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Rarity — the collectible layer
// ---------------------------------------------------------------------------

/// How rare one picked-up item turned out to be. Rarity multiplies what the
/// item is worth, which is what turns "pick up a can" into "pick up *this* can".
enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// Applied to both XP and EcoPoints for the item.
  double get multiplier => switch (this) {
    Rarity.common => 1,
    Rarity.uncommon => 1.5,
    Rarity.rare => 2.5,
    Rarity.epic => 4,
    Rarity.legendary => 8,
  };

  String get title => switch (this) {
    Rarity.common => 'Common',
    Rarity.uncommon => 'Uncommon',
    Rarity.rare => 'Rare',
    Rarity.epic => 'Epic',
    Rarity.legendary => 'Legendary',
  };

  /// Shown next to the badge, so the number is never a mystery.
  String get odds => switch (this) {
    Rarity.common => 'about 6 in 10',
    Rarity.uncommon => 'about 1 in 4',
    Rarity.rare => 'about 1 in 10',
    Rarity.epic => 'about 1 in 25',
    Rarity.legendary => 'about 1 in 100',
  };

  bool get isBoasted => index >= Rarity.rare.index;

  static Rarity byName(String? name) =>
      Rarity.values.firstWhere((r) => r.name == name, orElse: () => Rarity.common);

  /// Rolls the rarity of one item.
  ///
  /// Deterministic in ([seed], [index]): the same photo always yields the same
  /// result, so a player can't reshoot the same bottle fishing for a legendary,
  /// and the roll needs no server round trip — it works with no signal at all.
  /// Materials that are worth more to recycle roll a little luckier.
  static Rarity roll(String seed, int index, LitterClass cls) {
    final u = _unitHash('$seed#$index#${cls.name}');
    final luck = 1 + cls.points * 0.12;
    if (u < 0.010 * luck) return Rarity.legendary;
    if (u < 0.050 * luck) return Rarity.epic;
    if (u < 0.150 * luck) return Rarity.rare;
    if (u < 0.400 * luck) return Rarity.uncommon;
    return Rarity.common;
  }
}

/// FNV-1a over the string, mapped to [0, 1). Not cryptographic — it only has to
/// be stable across devices and evenly spread, which FNV-1a is.
double _unitHash(String s) {
  var hash = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash / 0x100000000;
}

/// One detected object, in the coordinate space of the *original* photo.
class Detection {
  const Detection({
    required this.cls,
    required this.confidence,
    required this.box,
    this.rarity = Rarity.common,
  });

  final LitterClass cls;
  final double confidence;
  final Rect box;

  /// Assigned at submission time, not at detection time — the detector has no
  /// business knowing about the game.
  final Rarity rarity;

  Detection rolled(String seed, int index) => Detection(
    cls: cls,
    confidence: confidence,
    box: box,
    rarity: Rarity.roll(seed, index, cls),
  );

  /// What this item is actually worth once its rarity is applied.
  int get points => (cls.points * rarity.multiplier).round();
  int get xp => (10 * rarity.multiplier).round();

  Map<String, dynamic> toJson() => {
    'class': cls.name,
    'rarity': rarity.name,
    'conf': double.parse(confidence.toStringAsFixed(3)),
    'box': [box.left, box.top, box.right, box.bottom]
        .map((v) => v.roundToDouble())
        .toList(),
  };
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

/// A player's face: one creature and one background tint.
///
/// Deliberately not an uploaded photo. Two taps, no camera roll permission, no
/// moderation queue, no storage bill, and it renders identically offline —
/// which matters because avatars show up on the map next to friends.
class Avatar {
  const Avatar(this.face, this.tint);

  final String face;
  final String tint;

  static const faces = [
    '🦊', '🐸', '🦉', '🐢', '🦔', '🐝', '🦋', '🐙',
    '🦝', '🐨', '🦦', '🐧', '🦕', '🌻', '🍄', '🌲',
  ];

  static const tints = [
    'green', 'cyan', 'violet', 'gold', 'fire', 'leaf', 'sky', 'red',
  ];

  static const fallback = Avatar('🌻', 'green');

  /// Parses the stored `face|tint` string. Anything unrecognised falls back
  /// rather than throwing — an old or hand-edited profile still renders.
  factory Avatar.parse(String? raw) {
    final parts = (raw ?? '').split('|');
    if (parts.length != 2) return fallback;
    return Avatar(
      faces.contains(parts[0]) ? parts[0] : fallback.face,
      tints.contains(parts[1]) ? parts[1] : fallback.tint,
    );
  }

  /// A stable starting avatar per player, so nobody begins as everyone else.
  factory Avatar.seeded(String seed) => Avatar(
    faces[(_unitHash(seed) * faces.length).floor() % faces.length],
    tints[(_unitHash('t$seed') * tints.length).floor() % tints.length],
  );

  String get encoded => '$face|$tint';
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
    required this.rarityCounts,
    required this.co2SavedG,
    required this.friends,
    required this.avatar,
    required this.onboarded,
    required this.shareLocation,
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

  /// Verified item count per rarity, e.g. `{common: 40, legendary: 1}`.
  final Map<String, int> rarityCounts;
  final int co2SavedG;
  final List<String> friends;
  final Avatar avatar;

  /// False until the player has been walked through the app once.
  final bool onboarded;

  /// Opt-in, off by default: whether friends can see this player on the map.
  /// The position itself lives in [Presence], never on this document — every
  /// signed-in player can read every profile, so a coordinate here would be a
  /// coordinate published to the world.
  final bool shareLocation;

  int get itemsCollected => classCounts.values.fold(0, (a, b) => a + b);

  /// Best rarity this player has ever found, for the profile headline.
  Rarity get bestFind => Rarity.values.lastWhere(
    (r) => (rarityCounts[r.name] ?? 0) > 0,
    orElse: () => Rarity.common,
  );

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
      rarityCounts:
          ((j['rarityCounts'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
      co2SavedG: (j['co2SavedG'] as num?)?.toInt() ?? 0,
      friends: ((j['friends'] as List?) ?? const []).cast<String>(),
      // Profiles created before avatars existed get a stable seeded one rather
      // than all landing on the same sunflower.
      avatar: j['avatar'] == null
          ? Avatar.seeded(d.id)
          : Avatar.parse(j['avatar'] as String),
      onboarded: (j['onboarded'] as bool?) ?? false,
      shareLocation: (j['shareLocation'] as bool?) ?? false,
    );
  }
}

/// Where a friend is right now.
///
/// Its own collection rather than a field on the profile, because profiles are
/// world-readable and positions must not be. Each document carries [visibleTo]
/// — a copy of the owner's friend list — and the security rules only hand the
/// document over to a uid inside it. The client query filters on the same field,
/// which is what makes the read provably safe to Firestore.
class Presence {
  const Presence({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.lat,
    required this.lng,
    required this.at,
  });

  final String uid;
  final String displayName;
  final Avatar avatar;
  final double lat;
  final double lng;
  final DateTime at;

  /// A dot from this morning is a lie about where somebody is standing now.
  static const staleAfter = Duration(hours: 2);

  bool get isFresh => DateTime.now().difference(at) < staleAfter;

  factory Presence.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return Presence(
      uid: d.id,
      displayName: (j['displayName'] as String?) ?? 'Friend',
      avatar: Avatar.parse(j['avatar'] as String?),
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      // Null while the server timestamp is still in flight; treat that as now
      // rather than as infinitely stale.
      at: (j['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    this.rarity = Rarity.common,
    this.className,
    this.photoUrl,
    this.uid,
    this.authorName,
    this.createdAt,
  });

  final String id;
  final PinKind kind;
  final double lat;
  final double lng;
  final String title;

  /// Set once somebody has actually cleaned this spot up.
  final bool resolved;

  /// Rarity of the litter waiting here — this is what makes a pin worth
  /// walking to rather than just something to look at.
  final Rarity rarity;
  final String? className;

  /// Proof photo of the spotted litter. A pin with no photo is a claim; a pin
  /// with one is a lead.
  final String? photoUrl;
  final String? uid;
  final String? authorName;
  final DateTime? createdAt;

  bool get isLead => kind == PinKind.litterHotspot && !resolved;

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
      rarity: Rarity.byName(j['rarity'] as String?),
      className: j['class'] as String?,
      photoUrl: j['photoUrl'] as String?,
      uid: j['uid'] as String?,
      authorName: j['authorName'] as String?,
      createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'lat': lat,
    'lng': lng,
    'title': title,
    'resolved': resolved,
    'rarity': rarity.name,
    'class': ?className,
    'photoUrl': ?photoUrl,
    'authorName': ?authorName,
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
