import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in user's email across app restarts.
/// The email is the only thing we need — everything else is fetched
/// from Firestore on startup.
class SessionService {
  static const _keyEmail = 'session_email';

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
  }
}
