import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  // ✅ Change these to your admin credentials
  static const _adminEmail = 'admin7802@gmail.com';
  static const _adminPassword = 'Admin@1234';

  // ── Public getters ────────────────────────────────────────────
  static String get adminEmail => _adminEmail;
  static String get adminPassword => _adminPassword;

  // ── Check if currently logged in user is admin ────────────────
  static bool get isCurrentUserAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return email != null && email == _adminEmail;
  }

  static bool isAdminEmail(String email) =>
      email.trim() == _adminEmail;

  // ── Firestore isAdmin flag check ──────────────────────────────
  static Future<bool> isAdmin(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return (doc.data()?['isAdmin'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Set admin flag in Firestore ───────────────────────────────
  static Future<void> setAdmin(String uid, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(
        {
          'isAdmin': value,
          'email': _adminEmail,
          'name': 'Admin',
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // ── Auto create admin on first launch ─────────────────────────
  static Future<void> ensureAdminExists() async {
    try {
      // Try signing in
      final credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );
      // Exists — update Firestore flag
      await setAdmin(credential.user!.uid, true);
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential') {
        // Does not exist — create it
        try {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: _adminEmail,
            password: _adminPassword,
          );
          await credential.user!.updateDisplayName('Admin');
          await setAdmin(credential.user!.uid, true);
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
    } catch (_) {}
  }
}