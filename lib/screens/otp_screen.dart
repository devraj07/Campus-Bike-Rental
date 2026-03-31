import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isRegister;

  const OtpScreen({super.key, required this.email, this.isRegister = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  bool _isVerifying = false;
  bool _linkReceived = false;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenForEmailLink();
  }

  /// Listens for the deep link when the user clicks the email link.
  void _listenForEmailLink() {
    final appLinks = AppLinks();

    // App opened from background via the link
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri.toString());
    });

    // App was cold-started by clicking the link
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri.toString());
    });
  }

  Future<void> _handleLink(String link) async {
    if (_linkReceived) return;
    setState(() {
      _linkReceived = true;
      _isVerifying = true;
    });

    try {
      final success =
          await _authService.signInWithEmailLink(widget.email, link);
      if (!mounted) return;
      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        setState(() {
          _isVerifying = false;
          _linkReceived = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid link. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _linkReceived = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _isVerifying = true);
    try {
      await _authService.sendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New link sent! Check your inbox.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend: $e')),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Check Your Email'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Color(0xFF2E7D32), size: 52),
            ),
            const SizedBox(height: 24),
            Text(
              'Login Link Sent!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a sign-in link to',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Status indicator
            _isVerifying
                ? Column(
                    children: [
                      const CircularProgressIndicator(
                          color: Color(0xFF2E7D32)),
                      const SizedBox(height: 16),
                      Text(
                        _linkReceived
                            ? 'Verifying your link…'
                            : 'Waiting for link…',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFFF9A825), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Open the email on this device and tap the link. The app will sign you in automatically.',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF795548)),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Didn't receive the email?",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isVerifying ? null : _resend,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Resend Link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Change Email',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
