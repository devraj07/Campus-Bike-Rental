import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import '../config/app_config.dart';
import 'session_service.dart';
import 'user_session.dart';

class AuthService {
  static const String _allowedDomain = '@iitgn.ac.in';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isValidEmail(String email) {
    return email.trim().toLowerCase().endsWith(_allowedDomain) &&
        email.trim().length > _allowedDomain.length;
  }

  // ─── OTP Generation ───────────────────────────────────────────────────────

  String _generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  // ─── Send OTP ─────────────────────────────────────────────────────────────

  Future<bool> sendOtp(String email) async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    // Store OTP in Firestore with expiry
    await _db.collection('otps').doc(_sanitize(email)).set({
      'otp': otp,
      'email': email,
      'expiresAt': Timestamp.fromDate(expiry),
      'createdAt': Timestamp.now(),
      'verified': false,
    });

    // Send email via Gmail SMTP
    await _sendEmail(email, otp);
    return true;
  }

  Future<void> _sendEmail(String toEmail, String otp) async {
    final smtpServer = gmail(AppConfig.smtpUser, AppConfig.smtpPassword);

    final message = Message()
      ..from = Address(AppConfig.smtpUser, AppConfig.otpSenderName)
      ..recipients.add(toEmail)
      ..subject = 'Your Campus Bike Rental OTP'
      ..html = '''
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;
                    padding:32px;border-radius:12px;background:#f9fbf0;">
          <h2 style="color:#1B5E20;margin-bottom:8px;">Campus Bike Rental</h2>
          <p style="color:#555;margin-bottom:24px;">IITGN · Eco-Friendly Commute</p>
          <p style="color:#333;">Your one-time login code is:</p>
          <div style="font-size:40px;font-weight:800;letter-spacing:12px;
                      color:#2E7D32;text-align:center;padding:20px 0;">
            $otp
          </div>
          <p style="color:#888;font-size:13px;">
            This code expires in <strong>10 minutes</strong>.<br/>
            Do not share this code with anyone.
          </p>
        </div>
      ''';

    await send(message, smtpServer);
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────

  Future<bool> verifyOtp(String email, String otp) async {
    final doc = await _db.collection('otps').doc(_sanitize(email)).get();

    if (!doc.exists) return false;
    final d = doc.data()!;

    // Check expiry
    final expiresAt = (d['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return false;

    // Check already used
    if (d['verified'] == true) return false;

    // Check code
    if (d['otp'] != otp) return false;

    // Mark as used
    await _db.collection('otps').doc(_sanitize(email)).update({'verified': true});
    return true;
  }

  // ─── Login / Register ─────────────────────────────────────────────────────

  /// Called after OTP is verified. Creates user doc on first login.
  Future<Map<String, dynamic>> login(String email) async {
    final userId = _sanitize(email);
    final docRef = _db.collection('users').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      final d = doc.data()!;
      UserSession.set(
        userId: userId,
        name: d['name'] as String,
        email: email,
        walletBalance: (d['walletBalance'] as num?)?.toDouble() ?? 0.0,
      );
      await SessionService.saveEmail(email);
      return {'userId': userId, 'name': d['name'], 'email': email};
    } else {
      final name = nameFromEmail(email);
      await docRef.set({
        'name': name,
        'email': email,
        'totalRides': 0,
        'totalSpent': 0.0,
        'walletBalance': 0.0,
        'createdAt': Timestamp.now(),
      });
      UserSession.set(userId: userId, name: name, email: email, walletBalance: 0.0);
      await SessionService.saveEmail(email);
      return {'userId': userId, 'name': name, 'email': email};
    }
  }

  Future<Map<String, dynamic>> register(String email) async => login(email);

  Future<void> logout() async {
    await SessionService.clearSession();
    UserSession.clear();
  }

  /// Restores UserSession from Firestore using a previously saved email.
  /// Returns true if the session was successfully restored.
  Future<bool> restoreSession(String email) async {
    try {
      final userId = _sanitize(email);
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      final d = doc.data()!;
      UserSession.set(
        userId: userId,
        name: d['name'] as String,
        email: email,
        walletBalance: (d['walletBalance'] as num?)?.toDouble() ?? 0.0,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// "devraj.rawat@iitgn.ac.in" → "devraj_rawat"
  String _sanitize(String email) =>
      email.split('@').first.replaceAll('.', '_').toLowerCase();

  /// "devraj.rawat@iitgn.ac.in" → "Devraj Rawat"
  String nameFromEmail(String email) {
    final local = email.split('@').first;
    return local
        .split('.')
        .map((p) => p.isNotEmpty
            ? '${p[0].toUpperCase()}${p.substring(1)}'
            : '')
        .join(' ');
  }
}
