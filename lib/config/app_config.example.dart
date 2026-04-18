/// Copy this file to app_config.dart and fill in real values.
/// app_config.dart is gitignored — never commit real credentials.
class AppConfig {
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String smtpUser = 'YOUR_PROJECT_GMAIL@gmail.com';
  static const String smtpPassword = 'YOUR_16_CHAR_APP_PASSWORD';
  static const String otpSenderName = 'Campus Bike Rental – IITGN';

  /// Razorpay key ID. Use rzp_test_* for test mode, rzp_live_* for production.
  static const String razorpayKeyId = 'rzp_test_YOUR_KEY_HERE';
}
