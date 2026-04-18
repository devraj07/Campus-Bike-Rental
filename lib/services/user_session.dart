import '../models/bike.dart';

/// Holds the currently logged-in user's data for the lifetime of the app session.
/// Populated by AuthService on login/register.
class UserSession {
  static String userId = '';
  static String name = '';
  static String email = '';
  static double walletBalance = 0.0;

  // ── Active ride (set when a ride starts, cleared when it ends) ─────────────
  static String? activeRideId;
  static Bike? activeBike;
  static DateTime? rideStartTime;

  static bool get hasActiveRide => activeRideId != null;

  static void startRide({
    required String rideId,
    required Bike bike,
    required DateTime startTime,
  }) {
    activeRideId = rideId;
    activeBike = bike;
    rideStartTime = startTime;
  }

  static void endRide() {
    activeRideId = null;
    activeBike = null;
    rideStartTime = null;
  }

  static void set({
    required String userId,
    required String name,
    required String email,
    double walletBalance = 0.0,
  }) {
    UserSession.userId = userId;
    UserSession.name = name;
    UserSession.email = email;
    UserSession.walletBalance = walletBalance;
  }

  static void clear() {
    userId = '';
    name = '';
    email = '';
    walletBalance = 0.0;
    endRide();
  }

  /// First letter(s) of the user's name for avatar display.
  static String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
