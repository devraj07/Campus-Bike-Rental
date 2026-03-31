import 'dart:math';

/// Generates a cryptographically secure random 4-digit code (1000–9999).
String generate4DigitCode() {
  final random = Random.secure();
  return (1000 + random.nextInt(9000)).toString();
}
