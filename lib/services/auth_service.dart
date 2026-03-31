import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_session.dart';

class AuthService {
  static const String _allowedDomain = '@iitgn.ac.in';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    return email.trim().toLowerCase().endsWith(_allowedDomain) &&
        email.trim().length > _allowedDomain.length;
  }

  Future<bool> sendOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // TODO: Keshav — trigger real OTP via Firebase Auth here
    return true;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // TODO: Keshav — verify OTP via Firebase Auth here
    // For demo: accept any 6-digit code
    return otp.length == 6;
  }

  /// Derives a clean document ID from the email.
  /// e.g. "devraj.rawat@iitgn.ac.in" → "devraj_rawat"
  String _userIdFromEmail(String email) {
    return email.split('@').first.replaceAll('.', '_').toLowerCase();
  }

  /// Derives a display name from the email local part.
  /// e.g. "devraj.rawat" → "Devraj Rawat"
  String _nameFromEmail(String email) {
    final local = email.split('@').first;
    return local
        .split('.')
        .map((part) => part.isNotEmpty
            ? '${part[0].toUpperCase()}${part.substring(1)}'
            : '')
        .join(' ');
  }

  /// Fetches user from Firestore (or creates doc on first login).
  /// Populates UserSession so all screens can access the current user.
  Future<Map<String, dynamic>> login(String email) async {
    final userId = _userIdFromEmail(email);
    final docRef = _db.collection('users').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      final d = doc.data()!;
      UserSession.set(
        userId: userId,
        name: d['name'] as String,
        email: email,
      );
      return {
        'userId': userId,
        'name': d['name'],
        'email': email,
      };
    } else {
      // First login — create user document
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
      UserSession.set(userId: userId, name: name, email: email);
      return {
        'userId': userId,
        'name': name,
        'email': email,
      };
    }
  }

  Future<Map<String, dynamic>> register(String email) async {
    return login(email); // same flow — create if not exists
  }

  Future<void> logout() async {
    UserSession.clear();
  }
}
