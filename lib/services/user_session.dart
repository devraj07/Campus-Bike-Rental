/// Holds the currently logged-in user's data for the lifetime of the app session.
/// Populated by AuthService on login/register.
class UserSession {
  static String userId = '';
  static String name = '';
  static String email = '';

  static void set({
    required String userId,
    required String name,
    required String email,
  }) {
    UserSession.userId = userId;
    UserSession.name = name;
    UserSession.email = email;
  }

  static void clear() {
    userId = '';
    name = '';
    email = '';
  }

  /// First letter(s) of the user's name for avatar display.
  static String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
