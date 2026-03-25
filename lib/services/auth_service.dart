import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static const String _allowedDomain = '@iitgn.ac.in';
  static const String _serviceId = 'service_v7ffzvl';
  static const String _templateId = 'template_irsiufi';
  static const String _publicKey = 'iOxkr6VrWmlbKP5ET';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, String> _otpStore = {};

  bool isValidEmail(String email) {
    return email.trim().toLowerCase().endsWith(_allowedDomain) &&
        email.trim().length > _allowedDomain.length;
  }

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> sendOtp(String email) async {
    final otp = _generateOtp();
    _otpStore[email] = otp;

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': email,
          'otp': otp,
        },
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final storedOtp = _otpStore[email];
    if (storedOtp == null) return false;
    if (storedOtp == otp) {
      _otpStore.remove(email);
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({
        'hd': 'iitgn.ac.in'
      });

      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);

      final User? user = userCredential.user;
      if (user == null) return null;

      final String email = user.email ?? '';

      if (!isValidEmail(email)) {
        await _auth.signOut();
        throw Exception('Only @iitgn.ac.in emails are allowed!');
      }

      return {
        'userId': user.uid,
        'name': user.displayName ?? '',
        'email': email,
        'photoUrl': user.photoURL ?? '',
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> login(String email) async {
    return {
      'userId': _auth.currentUser?.uid ?? 'USR-001',
      'name': _auth.currentUser?.displayName ?? '',
      'email': email,
    };
  }

  Future<Map<String, dynamic>> register(String email) async {
    return {
      'userId': _auth.currentUser?.uid ?? 'USR-001',
      'name': _auth.currentUser?.displayName ?? '',
      'email': email,
    };
  }
}