class AppConfig {
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String smtpUser = 'campus.bike.rental.iitgn@gmail.com';
  static const String smtpPassword = 'gwhoywjczausgzmw';
  static const String otpSenderName = 'Campus Bike Rental – IITGN';

  /// Razorpay key ID. Use rzp_test_* for test mode, rzp_live_* for production.
  static const String razorpayKeyId = 'rzp_test_SddlsGLr37PWhI';

  /// Set to false to bypass Razorpay and simulate instant payment success.
  /// Flip back to true once KYC is approved and you want real payments.
  static const bool razorpayEnabled = false;

  // ── MQTT (HiveMQ Cloud) ──────────────────────────────────────────────────
  static const bool mqttEnabled = true;
  static const String mqttHost =
      '654dcb2e2b224e16af4fe695597c1b42.s1.eu.hivemq.cloud';
  static const int mqttPort = 8883;
  static const String mqttClientId = 'flutter_app';
  static const String mqttUsername = 'esp32_user';
  static const String mqttPassword = 'Esp32_user';
  static const String mqttTopicPrefix = 'lock';
  static const int mqttKeepAliveSeconds = 60;
}