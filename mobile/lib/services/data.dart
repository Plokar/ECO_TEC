import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models.dart';

/// Result of a completed quest, used to drive the reward screen.
class QuestReward {
  const QuestReward({
    required this.xp,
    required this.points,
    required this.items,
    required this.co2g,
    required this.streak,
    required this.levelUp,
    required this.best,
    required this.rarityCounts,
  });

  final int xp;
  final int points;
  final int items;
  final int co2g;
  final Streak streak;
  final bool levelUp;

  /// The best rarity in this haul — the thing the reward screen celebrates.
  final Rarity best;
  final Map<String, int> rarityCounts;
}

/// Everything that touches Firestore or Storage.
///
/// Deliberately no transactions: Firestore transactions require connectivity,
/// and litter gets picked in parks with no signal. Batched writes with
/// `FieldValue.increment` queue offline and reconcile on reconnect, which is
/// what "reward instantly, sync later" actually needs.
class DataService {
  DataService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // -- profile ------------------------------------------------------------

  Stream<UserProfile> profile(String uid) =>
      _users.doc(uid).snapshots().map(UserProfile.fromDoc);

  Future<UserProfile?> profileOnce(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserProfile.fromDoc(doc) : null;
  }

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? city,
    String? country,
    String? school,
    Avatar? avatar,
    bool? onboarded,
    bool? shareLocation,
  }) => _users.doc(uid).update({
    'displayName': ?displayName,
    'displayNameLower': ?displayName?.toLowerCase(),
    'city': ?city,
    'country': ?country,
    'school': ?school,
    'avatar': ?avatar?.encoded,
    'onboarded': ?onboarded,
    'shareLocation': ?shareLocation,
  });

  // -- live location ------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _presence =>
      _db.collection('presence');

  /// Flips map visibility. Turning it off deletes the stored position rather
  /// than just hiding it — a player who opts out expects the dot gone now, not
  /// two hours from now when it would have expired.
  Future<void> setLocationSharing(String uid, bool on) async {
    await _users.doc(uid).update({'shareLocation': on});
    if (!on) await _presence.doc(uid).delete();
  }

  /// Publishes where the player is, for friends only.
  ///
  /// Refuses unless the player has opted in — the check lives here so no caller
  /// can leak a position by forgetting it, and firestore.rules enforces the
  /// same thing server-side.
  ///
  /// `visibleTo` is a copy of the friend list, which is both the security rule's
  /// input and the friends' query filter. A friend added since the last publish
  /// sees nothing until the next one, at most a couple of minutes later — the
  /// safe direction for a stale copy to fail in.
  Future<void> shareLocation(UserProfile profile, double lat, double lng) {
    if (!profile.shareLocation) return Future.value();
    return _presence.doc(profile.uid).set({
      'displayName': profile.displayName,
      'avatar': profile.avatar.encoded,
      'lat': lat,
      'lng': lng,
      'at': FieldValue.serverTimestamp(),
      'visibleTo': profile.friends,
    });
  }

  /// Friends who are currently sharing a position.
  ///
  /// Filtered on `visibleTo` rather than on a list of friend ids: that is the
  /// field the rules gate on, so the query is provably safe, and it sidesteps
  /// the 30-value ceiling a `whereIn` would impose.
  Stream<List<Presence>> friendsOnMap(UserProfile me) => _presence
      .where('visibleTo', arrayContains: me.uid)
      .snapshots()
      .map(
        (s) => s.docs
            .map(Presence.fromDoc)
            .where((p) => p.isFresh && p.uid != me.uid)
            .toList(),
      );

  // -- quests -------------------------------------------------------------

  /// Today's quest, the same one for everybody so city-vs-city stays fair.
  ///
  /// Rotates the daily pool by day number rather than relying on a scheduler,
  /// so there is no server-side cron to run or to go wrong.
  Future<Quest?> dailyQuest([DateTime? now]) async {
    final snap = await _db
        .collection('quests')
        .where('isDaily', isEqualTo: true)
        .orderBy(FieldPath.documentId)
        .get();
    if (snap.docs.isEmpty) return null;
    final day = (now ?? DateTime.now()).toUtc();
    final dayNumber = DateTime.utc(day.year, day.month, day.day)
            .difference(DateTime.utc(2026, 1, 1))
            .inDays;
    return Quest.fromDoc(snap.docs[dayNumber.abs() % snap.docs.length]);
  }

  /// Extra quests on offer beside the daily one, sponsored ones included.
  Stream<List<Quest>> bonusQuests() => _db
      .collection('quests')
      .where('isDaily', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.map(Quest.fromDoc).toList());

  // -- submitting a completed quest ---------------------------------------

  /// Uploads the proof photo. Returns the download URL.
  Future<String> uploadProof(String uid, Uint8List jpeg, String submissionId) async {
    final ref = _storage.ref('proofs/$uid/$submissionId.jpg');
    await ref.putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Records a verified quest completion and awards everything it earns.
  ///
  /// [counted] must already be filtered to detections the quest accepts.
  /// Everything below goes out in one batch, so an offline submission lands
  /// whole or not at all.
  Future<QuestReward> submitQuest({
    required UserProfile profile,
    required Quest quest,
    required List<Detection> counted,
    required String photoUrl,
    double? lat,
    double? lng,

    /// Set when this cleanup was started from somebody's litter pin — that pin
    /// gets retired in the same batch.
    String? clearedPinId,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final batch = _db.batch();
    final submission = _db.collection('submissions').doc();

    final classCounts = <String, int>{};
    final rarityCounts = <String, int>{};
    var co2g = 0;
    var itemPoints = 0;
    var itemXp = 0;
    var best = Rarity.common;
    for (final d in counted) {
      classCounts[d.cls.name] = (classCounts[d.cls.name] ?? 0) + 1;
      rarityCounts[d.rarity.name] = (rarityCounts[d.rarity.name] ?? 0) + 1;
      co2g += d.cls.co2g;
      // Rarity multiplies what the item pays, but never what it saves: a
      // legendary can is still one can of aluminium in the real world.
      itemPoints += d.points;
      itemXp += d.xp;
      if (d.rarity.index > best.index) best = d.rarity;
    }

    // Quest rewards land only if the target was actually met; short of that the
    // player still keeps per-item credit, so a half-finished cleanup isn't wasted.
    final met = counted.length >= quest.targetCount;
    final xp = met ? quest.xpReward + itemXp : itemXp;
    final points = met ? quest.pointsReward + itemPoints : itemPoints;
    final streak = met ? profile.streak.advance(today) : profile.streak;

    batch.set(submission, {
      'uid': profile.uid,
      'questId': quest.id,
      'questTitle': quest.title,
      'photoUrl': photoUrl,
      'detections': counted.map((d) => d.toJson()).toList(),
      'itemsCounted': counted.length,
      'classCounts': classCounts,
      'rarityCounts': rarityCounts,
      'bestRarity': best.name,
      'targetMet': met,
      'xpAwarded': xp,
      'pointsAwarded': points,
      'co2SavedG': co2g,
      // Same wire format the quests collection uses, so both read alike.
      'verification': quest.verification == Verification.selfReport
          ? 'self_report'
          : 'ai_photo',
      'lat': lat,
      'lng': lng,
      // Server timestamp, so a device with a shifted clock can't fake recency.
      'createdAt': FieldValue.serverTimestamp(),
      'clientTime': today.toUtc().toIso8601String(),
    });

    batch.update(_users.doc(profile.uid), {
      'xp': FieldValue.increment(xp),
      'ecoPoints': FieldValue.increment(points),
      'co2SavedG': FieldValue.increment(co2g),
      'streak': streak.toJson(),
      for (final e in classCounts.entries)
        'classCounts.${e.key}': FieldValue.increment(e.value),
      for (final e in rarityCounts.entries)
        'rarityCounts.${e.key}': FieldValue.increment(e.value),
    });

    // League totals. Self-reported actions never feed city/country/school
    // aggregates — see BRANDING.md §7.
    if (quest.verification == Verification.aiPhoto) {
      for (final league in _leaguesFor(profile)) {
        batch.set(league.$1, {
          'kind': league.$2,
          'name': league.$3,
          'points': FieldValue.increment(points),
          'items': FieldValue.increment(counted.length),
          'co2SavedG': FieldValue.increment(co2g),
        }, SetOptions(merge: true));
      }
    }

    // A litter hotspot the app now knows about, so the map improves as people play.
    if (lat != null && lng != null && counted.isNotEmpty) {
      batch.set(_db.collection('mapPins').doc(), {
        ...MapPin(
          id: '',
          kind: PinKind.completedQuest,
          lat: lat,
          lng: lng,
          title: '${counted.length} items collected',
          rarity: best,
          authorName: profile.displayName,
        ).toJson(),
        'uid': profile.uid,
      });
    }

    // Cleaning up a spot somebody else flagged retires their pin, so the map
    // shows what still needs doing rather than everything ever reported.
    if (clearedPinId != null) {
      batch.update(_db.collection('mapPins').doc(clearedPinId), {
        'resolved': true,
        'resolvedBy': profile.uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    final newLevel = UserProfile.xpForLevel(profile.level + 1) <= profile.xp + xp;
    return QuestReward(
      xp: xp,
      points: points,
      items: counted.length,
      co2g: co2g,
      streak: streak,
      levelUp: newLevel,
      best: best,
      rarityCounts: rarityCounts,
    );
  }

  /// Tags litter the player found but is not picking up right now, so somebody
  /// else can go and get it. The photo is what makes it a lead rather than a
  /// rumour, and the rarity is what makes it worth the walk.
  ///
  /// Pays a small finder's fee — enough that scouting is worth doing, far less
  /// than actually clearing the spot, so tagging never beats cleaning.
  Future<MapPin> spotLitter({
    required UserProfile profile,
    required List<Detection> found,
    required double lat,
    required double lng,
    required String photoUrl,
  }) async {
    if (found.isEmpty) throw StateError('Nothing to pin.');
    final best = found.reduce((a, b) => a.rarity.index >= b.rarity.index ? a : b);
    final pin = MapPin(
      id: '',
      kind: PinKind.litterHotspot,
      lat: lat,
      lng: lng,
      title: '${found.length} item${found.length == 1 ? '' : 's'} spotted',
      rarity: best.rarity,
      className: best.cls.name,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      authorName: profile.displayName,
    );

    final ref = _db.collection('mapPins').doc();
    final batch = _db.batch();
    batch.set(ref, {...pin.toJson(), 'uid': profile.uid});
    batch.update(_users.doc(profile.uid), {
      'xp': FieldValue.increment(5),
      'ecoPoints': FieldValue.increment(1),
    });
    await batch.commit();

    return MapPin(
      id: ref.id,
      kind: pin.kind,
      lat: lat,
      lng: lng,
      title: pin.title,
      rarity: pin.rarity,
      className: pin.className,
      photoUrl: pin.photoUrl,
      uid: profile.uid,
      authorName: pin.authorName,
      createdAt: DateTime.now(),
    );
  }

  /// (doc ref, kind, display name) for each league this player contributes to.
  List<(DocumentReference<Map<String, dynamic>>, String, String)> _leaguesFor(
    UserProfile p,
  ) => [
    if (p.city case final city? when city.isNotEmpty)
      (_db.collection('leagues').doc('city:$city'), 'city', city),
    if (p.country case final country? when country.isNotEmpty)
      (_db.collection('leagues').doc('country:$country'), 'country', country),
    if (p.school case final school? when school.isNotEmpty)
      (_db.collection('leagues').doc('school:$school'), 'school', school),
  ];

  Stream<List<Map<String, dynamic>>> recentSubmissions(String uid, {int limit = 20}) =>
      _db
          .collection('submissions')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  // -- leaderboards -------------------------------------------------------

  /// Player leaderboard for a scope. `global` has no filter; the rest match on
  /// the player's own city/country/school.
  Stream<List<UserProfile>> leaderboard(
    Scope scope,
    UserProfile me, {
    int limit = 50,
  }) {
    switch (scope) {
      case Scope.friends:
        // Firestore allows at most 30 values in a `whereIn`, and the query needs
        // to include the player themselves.
        final ids = <String>{me.uid, ...me.friends}.take(30).toList();
        return _users
            .where(FieldPath.documentId, whereIn: ids)
            .snapshots()
            .map(_sortByXp);
      case Scope.global:
        return _users
            .orderBy('xp', descending: true)
            .limit(limit)
            .snapshots()
            .map(_sortByXp);
      case Scope.city:
      case Scope.country:
      case Scope.school:
        final field = scope.name;
        final value = switch (scope) {
          Scope.city => me.city,
          Scope.country => me.country,
          _ => me.school,
        };
        if (value == null || value.isEmpty) return Stream.value(const []);
        return _users
            .where(field, isEqualTo: value)
            .orderBy('xp', descending: true)
            .limit(limit)
            .snapshots()
            .map(_sortByXp);
    }
  }

  static List<UserProfile> _sortByXp(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map(UserProfile.fromDoc).toList();
    list.sort((a, b) => b.xp.compareTo(a.xp));
    return list;
  }

  /// City-vs-city / country-vs-country — the viral table.
  Stream<List<Map<String, dynamic>>> leagueTable(String kind, {int limit = 25}) =>
      _db
          .collection('leagues')
          .where('kind', isEqualTo: kind)
          .orderBy('points', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  // -- friends ------------------------------------------------------------

  /// Prefix search on display name.
  ///
  /// Firestore has no substring or case-insensitive search, so every profile
  /// carries a lowercased `displayNameLower` and this walks a range over it.
  /// The `endAt` bound ends in a literal U+F8FF — an invisible private-use
  /// character that sorts after every normal one, which is what turns the range
  /// into a prefix match. It looks like nothing in an editor; don't "clean" it.
  Future<List<UserProfile>> searchPlayers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final snap = await _users
        .orderBy('displayNameLower')
        .startAt([q])
        .endAt(['$q'])
        .limit(20)
        .get();
    return snap.docs.map(UserProfile.fromDoc).toList();
  }

  Future<void> addFriend(String uid, String friendUid) async {
    if (uid == friendUid) return;
    final batch = _db.batch();
    batch.update(_users.doc(uid), {
      'friends': FieldValue.arrayUnion([friendUid]),
    });
    batch.update(_users.doc(friendUid), {
      'friends': FieldValue.arrayUnion([uid]),
    });
    await batch.commit();
  }

  Future<void> removeFriend(String uid, String friendUid) async {
    final batch = _db.batch();
    batch.update(_users.doc(uid), {
      'friends': FieldValue.arrayRemove([friendUid]),
    });
    batch.update(_users.doc(friendUid), {
      'friends': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }

  // -- map ----------------------------------------------------------------

  /// Pins near a point. Firestore can't do radius queries, so this brackets
  /// latitude server-side and filters longitude on the client — fine at city
  /// zoom levels.
  ///
  /// ponytail: bounding box on latitude only. If pin volume grows enough that
  /// this pulls too many docs, switch to geohash prefixes.
  Stream<List<MapPin>> pinsNear(double lat, double lng, {double degrees = 0.15}) =>
      _db
          .collection('mapPins')
          .where('lat', isGreaterThan: lat - degrees)
          .where('lat', isLessThan: lat + degrees)
          .limit(300)
          .snapshots()
          .map(
            (s) => s.docs
                .map(MapPin.fromDoc)
                .where((p) => (p.lng - lng).abs() < degrees)
                .toList(),
          );

  Future<void> reportPin(MapPin pin, String uid) =>
      _db.collection('mapPins').add({...pin.toJson(), 'uid': uid});

  // -- rewards ------------------------------------------------------------

  Stream<List<Reward>> rewards() => _db
      .collection('rewards')
      .orderBy('costPoints')
      .snapshots()
      .map((s) => s.docs.map(Reward.fromDoc).toList());

  /// Spends EcoPoints on a reward.
  ///
  /// The affordability check here is a UX guard, not a security boundary — the
  /// balance rule is enforced in firestore.rules, which is what actually stops
  /// a patched client from going negative.
  Future<String> redeem(UserProfile profile, Reward reward) async {
    if (profile.ecoPoints < reward.costPoints) {
      throw StateError('Not enough EcoPoints.');
    }
    if (reward.soldOut) throw StateError('That reward is gone.');

    final redemption = _db.collection('redemptions').doc();
    final batch = _db.batch();
    batch.set(redemption, {
      'uid': profile.uid,
      'rewardId': reward.id,
      'rewardTitle': reward.title,
      'partner': reward.partner,
      'costPoints': reward.costPoints,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_users.doc(profile.uid), {
      'ecoPoints': FieldValue.increment(-reward.costPoints),
    });
    batch.update(_db.collection('rewards').doc(reward.id), {
      'stock': FieldValue.increment(-1),
    });
    await batch.commit();
    return redemption.id;
  }
}
