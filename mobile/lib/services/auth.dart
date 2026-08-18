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

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? city,
    String? country,
    String? school,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    await _createProfile(
      cred.user!,
      displayName: displayName.trim(),
      city: city,
      country: country,
      school: school,
    );
  }

  /// "Try it now" path — a real account can be linked to it later.
  Future<void> continueAsGuest() async {
    final cred = await _auth.signInAnonymously();
    await _createProfile(cred.user!, displayName: 'Guest');
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

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
      'streak': {'current': 0, 'longest': 0, 'lastActionDay': null},
      'friends': <String>[],
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
