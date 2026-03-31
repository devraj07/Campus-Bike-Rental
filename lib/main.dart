import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CampusBikeRentalApp());
}

class CampusBikeRentalApp extends StatelessWidget {
  const CampusBikeRentalApp({super.key});

  /// If user is already signed in from a previous session, restore UserSession
  /// and go straight to HomeScreen. Otherwise show LoginScreen.
  Widget _resolveHome() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      // Restore session — full profile loads lazily in each screen
      UserSession.set(
        userId: user.uid,
        name: AuthService().nameFromEmail(user.email!),
        email: user.email!,
      );
      return const HomeScreen();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Bike Rental – IITGN',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _resolveHome(),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF2E7D32); // Deep green
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFF2E7D32),
      secondary: const Color(0xFF66BB6A),
      tertiary: const Color(0xFF1B5E20),
      surface: const Color(0xFFF1F8E9),
      background: const Color(0xFFF9FBF0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Color(0xFF9E9E9E),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
