import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_history_service.dart';

/// Thin wrapper around FirebaseAuth. Every sign-in path also makes sure
/// a matching `users/{uid}` Firestore document exists, so the rest of
/// the app can always read profile + major from one place, and records
/// the account in AccountHistoryService for the "switch account" menu.
///
/// Google sign-in uses FirebaseAuth's built-in web popup
/// (`signInWithPopup`) rather than the separate `google_sign_in`
/// package -- since this app targets Flutter Web only, that avoids an
/// extra dependency entirely (and that package's v7 API churn).
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Set right before calling signOut() when the user picked "switch
  /// account" for a specific remembered email. LoginScreen reads this
  /// once (and clears it) to pre-fill the email field after the
  /// AuthGate swaps back to the login screen.
  static String? pendingEmailHint;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _ensureUserDoc(cred.user!, nameOverride: name);
    await AccountHistoryService.instance.recordSignIn(email: email, name: name);
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDoc(cred.user!);
    await AccountHistoryService.instance.recordSignIn(
      email: cred.user!.email ?? email,
      name: cred.user!.displayName ?? '',
      photoUrl: cred.user!.photoURL,
    );
    return cred;
  }

  /// Opens a Google sign-in popup. Returns null if the user closes the
  /// popup without completing sign-in.
  Future<UserCredential?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    provider.addScope('email');
    provider.setCustomParameters({'prompt': 'select_account'});

    try {
      final userCred = await _auth.signInWithPopup(provider);
      await _ensureUserDoc(userCred.user!);
      await AccountHistoryService.instance.recordSignIn(
        email: userCred.user!.email ?? '',
        name: userCred.user!.displayName ?? '',
        photoUrl: userCred.user!.photoURL,
      );
      return userCred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') {
        return null; // user dismissed the popup -- not an error
      }
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  /// Signs out and primes [pendingEmailHint] so the login screen that
  /// AuthGate swaps back in can pre-fill that email. Pass null for a
  /// plain "add another account" flow (blank login form).
  Future<void> switchAccount(String? email) async {
    pendingEmailHint = email;
    await signOut();
  }

  Future<void> _ensureUserDoc(User user, {String? nameOverride}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': nameOverride ?? user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'studentId': null,
        'majorId': null,
        'majorName': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
