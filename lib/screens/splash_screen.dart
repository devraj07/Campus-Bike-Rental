import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/user_session.dart';
import 'active_ride_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // 1. Check for a saved login session
    final savedEmail = await SessionService.getSavedEmail();

    if (savedEmail == null) {
      _go(const LoginScreen());
      return;
    }

    // 2. Restore UserSession from Firestore
    final restored = await AuthService().restoreSession(savedEmail);
    if (!restored) {
      // Saved email no longer valid (account deleted, etc.)
      await SessionService.clearSession();
      _go(const LoginScreen());
      return;
    }

    // 3. Check for an in-progress ride
    final activeRide = await ApiService().fetchActiveRide(UserSession.userId);

    if (activeRide != null) {
      // Restore UserSession active ride state
      UserSession.startRide(
        rideId: activeRide.rideId,
        bike: activeRide.bike,
        startTime: activeRide.startTime,
      );
      _go(ActiveRideScreen(
        bike: activeRide.bike,
        rideId: activeRide.rideId,
        startTime: activeRide.startTime,
      ));
    } else {
      _go(const HomeScreen());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electric_bike_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Campus Bike Rental',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'IITGN',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
