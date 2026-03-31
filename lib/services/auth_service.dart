import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_session.dart';

class AuthService {
  static const String _allowedDomain = '@iitgn.ac.in';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // The URL Firebase will redirect to after the user clicks the email link.
  // Must be an authorized domain in Firebase Console → Authentication → Settings.
  static const String _continueUrl =
      'https://iitgn-campus-bike-rental.web.app/login';

  bool isValidEmail(String email) {
    return email.trim().toLowerCase().endsWith(_allowedDomain) &&
        email.trim().length > _allowedDomain.length;
  }

  /// Sends a Firebase sign-in link to the given email.
  Future<bool> sendOtp(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: _continueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.example.campus_bike_rental',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    return true;
  }

  /// Completes sign-in using the email link the user clicked.
  /// Call this from OtpScreen once the deep link is received.
  Future<bool> signInWithEmailLink(String email, String emailLink) async {
    if (!_auth.isSignInWithEmailLink(emailLink)) return false;

    final credential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    final user = credential.user;
    if (user == null) return false;

    await _createOrFetchUser(user.uid, email);
    return true;
  }

  /// Creates user doc in Firestore on first login, or loads existing data.
  Future<void> _createOrFetchUser(String uid, String email) async {
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      final d = doc.data()!;
      UserSession.set(
        userId: uid,
        name: d['name'] as String,
        email: email,
      );
    } else {
      final name = _nameFromEmail(email);
      await docRef.set({
        'name': name,
        'email': email,
        'totalRides': 0,
        'totalSpent': 0.0,
        'co2SavedGrams': 0.0,
        'walletBalance': 0.0,
        'createdAt': Timestamp.now(),
      });
      UserSession.set(userId: uid, name: name, email: email);
    }
  }

  /// Derives display name from email.
  /// e.g. "devraj.rawat@iitgn.ac.in" → "Devraj Rawat"
  String nameFromEmail(String email) => _nameFromEmail(email);

  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    return local
        .split('.')
        .map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '')
        .join(' ');
  }

  Future<void> logout() async {
    await _auth.signOut();
    UserSession.clear();
  }

  // Keep for compatibility — verifyOtp is no longer used with email link
  Future<bool> verifyOtp(String email, String otp) async => false;
}
