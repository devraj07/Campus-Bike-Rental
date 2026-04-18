import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../utils/code_generator.dart';
import 'active_ride_screen.dart';

class UnlockPinScreen extends StatefulWidget {
  final Bike bike;
  const UnlockPinScreen({super.key, required this.bike});

  @override
  State<UnlockPinScreen> createState() => _UnlockPinScreenState();
}

class _UnlockPinScreenState extends State<UnlockPinScreen>
    with TickerProviderStateMixin {
  // ── PIN / Timer state ──────────────────────────────────────────────────
  late String _currentPin;
  int _seconds = 60;
  Timer? _pinTimer;

  // ── Lock / ride state ─────────────────────────────────────────────────
  bool _pushingOtp = false;        // writing OTP to Firestore
  bool _unlocking = false;         // startRental in progress
  bool _rideStarted = false;       // guard against duplicate starts
  _LockStatus _lockStatus = _LockStatus.waitingForEsp;

  // ── Firestore stream ───────────────────────────────────────────────────
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lockSub;

  // ── Animation ─────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;    // mapped to 0.95–1.05 scale

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _currentPin = generate4DigitCode();

    // Controller must stay in [0,1] — CurvedAnimation asserts t ∈ [0,1].
    // Map to 0.95–1.05 scale via Tween instead of using non-standard bounds.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startPinTimer();
    // Defer until after the first frame so setState isn't called mid-initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pushOtpAndListen();
    });
  }

  @override
  void dispose() {
    _pinTimer?.cancel();
    _lockSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── OTP push + Firestore listener ─────────────────────────────────────

  Future<void> _pushOtpAndListen() async {
    setState(() => _pushingOtp = true);
    try {
      await _api.pushOtpToLock(widget.bike.id, _currentPin);
    } catch (e) {
      // If push fails, the manual button is still available as fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach lock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pushingOtp = false);
    }

    // Start listening for ESP32 confirmation
    _lockSub?.cancel();
    _lockSub = FirebaseFirestore.instance
        .collection('bikes')
        .doc(widget.bike.id)
        .snapshots()
        .listen(
      (snap) {
        if (!snap.exists || _rideStarted) return;
        final status = snap.data()?['lockStatus'] as String? ?? 'locked';
        if (mounted) {
          setState(() {
            _lockStatus = _LockStatusX.fromString(status);
          });
        }
        if (status == 'unlocked' && mounted) {
          _autoStartRide();
        }
      },
      onError: (e) {
        // Firestore stream error (e.g. permission denied) — fail silently,
        // manual fallback button remains available.
        debugPrint('[UnlockPin] Firestore stream error: $e');
      },
    );
  }

  // ── Auto-start triggered by ESP32 confirmation ────────────────────────

  Future<void> _autoStartRide() async {
    if (_rideStarted || _unlocking) return;
    setState(() {
      _rideStarted = true;
      _unlocking = true;
    });
    _pinTimer?.cancel();
    _lockSub?.cancel();

    try {
      final result = await _api.startRental(widget.bike.id, _currentPin);
      if (!mounted) return;
      final rideId = result['rideId'] as String;
      // Use the Firestore-stored startTime so timing is accurate regardless
      // of network latency or whether hardware/manual path was used.
      final startTime = DateTime.parse(result['startTime'] as String);
      UserSession.startRide(
        rideId: rideId,
        bike: widget.bike,
        startTime: startTime,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveRideScreen(
            bike: widget.bike,
            rideId: rideId,
            startTime: startTime,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _rideStarted = false;
          _unlocking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start ride: $e')),
        );
      }
    }
  }

  // ── PIN timer ─────────────────────────────────────────────────────────

  void _startPinTimer() {
    _pinTimer?.cancel();
    setState(() => _seconds = 60);
    _pinTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _regeneratePin() {
    setState(() => _currentPin = generate4DigitCode());
    _startPinTimer();
    _pushOtpAndListen(); // push new OTP to ESP32
  }

  // ── Manual fallback confirm ───────────────────────────────────────────

  void _showManualConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.lock_open_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text('Confirm Unlock'),
        ]),
        content: const Text(
          'Have you entered the PIN on the bicycle lock keypad and heard the click?\n\n'
          'Billing starts only after you confirm the lock is physically open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoStartRide();
            },
            child: const Text('Yes, Start Billing'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Color get _timerColor {
    if (_seconds > 30) return const Color(0xFF2E7D32);
    if (_seconds > 10) return const Color(0xFFFFA000);
    return const Color(0xFFD32F2F);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Unlock Your Bike'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Bike info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.electric_bike_rounded,
                      color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.bike.id,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF1B5E20))),
                      Text(widget.bike.station,
                          style: const TextStyle(
                              color: Color(0xFF4CAF50), fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  // ESP32 connection status indicator
                  _LockStatusBadge(status: _lockStatus, pushing: _pushingOtp),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // PIN display
            Text(
              'Your Unlock PIN',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _currentPin.split('').map((d) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 4,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_open_rounded,
                      color: Color(0xFFF9A825), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter this PIN on the bicycle lock keypad. '
                      'Billing starts automatically once the lock opens.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Timer
            Text('PIN expires in',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: _seconds / 60.0),
              duration: const Duration(milliseconds: 200),
              builder: (_, val, __) => SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: val,
                      strokeWidth: 6,
                      color: _timerColor,
                      backgroundColor: Colors.grey[200],
                    ),
                    Text(
                      '$_seconds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _timerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Auto-unlock progress (shown while ESP32 has confirmed)
            if (_lockStatus == _LockStatus.unlocked || _unlocking)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _unlocking
                          ? 'Starting your ride...'
                          : 'Lock opened! Starting billing...',
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // Regenerate PIN
            OutlinedButton.icon(
              onPressed: (_unlocking || _rideStarted) ? null : _regeneratePin,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Regenerate PIN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            // Manual fallback button
            ElevatedButton.icon(
              onPressed: (_unlocking || _rideStarted)
                  ? null
                  : _showManualConfirmDialog,
              icon: _unlocking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_unlocking
                  ? 'Starting...'
                  : 'Bike Unlocked – Start Ride'),
            ),

            const SizedBox(height: 12),
            Text(
              'Use the button above only if the lock hardware is offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lock status enum ───────────────────────────────────────────────────────

enum _LockStatus { waitingForEsp, locked, unlocked, onRide }

extension _LockStatusX on _LockStatus {
  static _LockStatus fromString(String s) {
    switch (s) {
      case 'unlocked': return _LockStatus.unlocked;
      case 'on_ride':  return _LockStatus.onRide;
      case 'locked':   return _LockStatus.locked;
      default:         return _LockStatus.waitingForEsp;
    }
  }
}

// ── Lock status badge widget ───────────────────────────────────────────────

class _LockStatusBadge extends StatelessWidget {
  final _LockStatus status;
  final bool pushing;

  const _LockStatusBadge({required this.status, required this.pushing});

  @override
  Widget build(BuildContext context) {
    if (pushing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Color(0xFF2E7D32)),
      );
    }

    final (color, icon, label) = switch (status) {
      _LockStatus.waitingForEsp => (Colors.grey,       Icons.wifi_off_rounded,        'Offline'),
      _LockStatus.locked        => (const Color(0xFF1565C0), Icons.lock_rounded,       'Locked'),
      _LockStatus.unlocked      => (const Color(0xFF2E7D32), Icons.lock_open_rounded,  'Open'),
      _LockStatus.onRide        => (const Color(0xFF6A1B9A), Icons.directions_bike_rounded, 'On Ride'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
