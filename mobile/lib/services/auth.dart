import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication plus first-run profile creation.
///
/// Email/password and anonymous only — both work with no extra native config.
/// Google and Apple sign-in need signing fingerprints and entitlements set up
/// per build flavour, so they are a deliberate follow-up rather than a blocker.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get changes => _auth.authStateChanges();
  User? get current => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  /// Signing up takes an email and a password, nothing else.
  ///
  /// The display name is deliberately *not* asked for here: the walkthrough
  /// asks for it one screen later, next to the avatar, where it comes with an
  /// explanation of where the name actually shows up. Asking twice was the bug.
  /// Until then the profile is called something derived from the address, so it
  /// is never blank and the walkthrough has something to pre-fill.
  Future<void> register({
    required String email,
    required String password,
    String? city,
    String? country,
    String? school,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final provisional = nameFromEmail(email);
    await cred.user!.updateDisplayName(provisional);
    await _createProfile(
      cred.user!,
      displayName: provisional,
      city: city,
      country: country,
      school: school,
    );
  }

  /// `sebastian.borik+spam@x.com` -> `Sebastian borik`. A guess, and one the
  /// player overwrites on the very next screen — it only has to beat "blank".
  static String nameFromEmail(String email) {
    final local = email.trim().split('@').first.split('+').first;
    final words = local.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
    if (words.isEmpty) return 'Player';
    final capped = words.length > 24 ? words.substring(0, 24).trim() : words;
    return capped[0].toUpperCase() + capped.substring(1);
  }

  /// "Try it now" path — a real account can be linked to it later.
  Future<void> continueAsGuest() async {
    final cred = await _auth.signInAnonymously();
    await _createProfile(cred.user!, displayName: 'Guest');
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Deletes the account and the profile behind it.
  ///
  /// Required by both app stores, and it has to be reachable from inside the
  /// app rather than by emailing support. Firebase refuses this on a stale
  /// session with `requires-recent-login`, which the caller surfaces as "sign
  /// in again first" rather than swallowing.
  ///
  /// ponytail: submissions, pins and league totals are left in place —
  /// they carry no name once the profile is gone. Add a cleanup function if a
  /// deletion request ever has to cover them too.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');
    await _db.collection('users').doc(user.uid).delete();
    // The position is the one piece of personal data that is not on the profile
    // document, so it needs deleting by name.
    await _db.collection('presence').doc(user.uid).delete();
    await user.delete();
  }

  /// Creates the profile doc if it isn't there yet. Safe to call on every
  /// sign-in: `merge` never clobbers an existing player's progress.
  Future<void> _createProfile(
    User user, {
    required String displayName,
    String? city,
    String? country,
    String? school,
  }) async {
    final doc = _db.collection('users').doc(user.uid);
    if ((await doc.get()).exists) return;
    await doc.set({
      'displayName': displayName,
      // Lowercased twin so friend search can do a case-insensitive prefix
      // match — Firestore range queries are case-sensitive.
      'displayNameLower': displayName.toLowerCase(),
      'photoUrl': user.photoURL,
      'city': city,
      'country': country,
      'school': school,
      'xp': 0,
      'ecoPoints': 0,
      'co2SavedG': 0,
      'classCounts': <String, int>{},
      'rarityCounts': <String, int>{},
      'streak': {'current': 0, 'longest': 0, 'lastActionDay': null},
      'friends': <String>[],
      // The walkthrough flips this, and picks the avatar and city while it is
      // at it. Written explicitly rather than left absent, because the presence
      // rule reads shareLocation and a missing field there fails the write.
      'onboarded': false,
      'shareLocation': false,
      'isAnonymous': user.isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Turns a guest account into a permanent one without losing progress —
  /// the uid, and therefore the profile document, stays the same.
  Future<void> linkGuestAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw StateError('Not signed in as a guest.');
    }
    await user.linkWithCredential(
      EmailAuthProvider.credential(email: email.trim(), password: password),
    );
    await user.updateDisplayName(displayName.trim());
    await _db.collection('users').doc(user.uid).update({
      'displayName': displayName.trim(),
      'displayNameLower': displayName.trim().toLowerCase(),
      'isAnonymous': false,
    });
  }
}
