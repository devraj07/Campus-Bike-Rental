class AuthService {
  static const String _allowedDomain = '@iitgn.ac.in';

  bool isValidEmail(String email) {
    return email.trim().toLowerCase().endsWith(_allowedDomain) &&
        email.trim().length > _allowedDomain.length;
  }

  Future<bool> sendOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // In production, call backend API
    return true;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // In production, verify with backend; for demo accept any 6-digit
    return otp.length == 6;
  }

  Future<Map<String, dynamic>> login(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'userId': 'USR-001',
      'name': 'Devraj Rawat',
      'email': email,
      'token': 'demo_token_xyz',
    };
  }

  Future<Map<String, dynamic>> register(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'userId': 'USR-001',
      'name': 'Devraj Rawat',
      'email': email,
      'token': 'demo_token_xyz',
    };
  }
}
