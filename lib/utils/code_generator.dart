import 'dart:math';

/// Generates a random 4-digit code (1000–9999) for use as a short-lived OTP.
/// Regular Random is sufficient — the code expires in 60 s and is single-use.
String generate4DigitCode() {
  final random = Random();
  return (1000 + random.nextInt(9000)).toString();
}
