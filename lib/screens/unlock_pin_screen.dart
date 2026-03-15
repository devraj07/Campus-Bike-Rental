import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import 'active_ride_screen.dart';

class UnlockPinScreen extends StatefulWidget {
  final Bike bike;
  final String pin;
  final String rideId;

  const UnlockPinScreen({
    super.key,
    required this.bike,
    required this.pin,
    required this.rideId,
  });

  @override
  State<UnlockPinScreen> createState() => _UnlockPinScreenState();
}

class _UnlockPinScreenState extends State<UnlockPinScreen>
    with TickerProviderStateMixin {
  late int _seconds;
  Timer? _timer;
  late String _currentPin;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _seconds = 60;
    _currentPin = widget.pin;
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _regeneratePin() {
    final newPin =
        (1000 + DateTime.now().millisecond % 9000).toString().substring(0, 4);
    setState(() => _currentPin = newPin);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _timerColorValue {
    if (_seconds > 30) return const Color(0xFF2E7D32);
    if (_seconds > 10) return const Color(0xFFFFA000);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Your Unlock PIN',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 16),
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF2E7D32), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.15),
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
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20),
                              letterSpacing: 4)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                      'Enter this PIN on the bicycle lock keypad to unlock your bike',
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
            const Text('PIN expires in',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _seconds / 60.0,
                    strokeWidth: 6,
                    color: _timerColorValue,
                    backgroundColor: Colors.grey[200],
                  ),
                  Text('',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _timerColorValue)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _regeneratePin,
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
            ElevatedButton.icon(
              onPressed: () {
                _timer?.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveRideScreen(
                      bike: widget.bike,
                      rideId: widget.rideId,
                      startTime: DateTime.now(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Bike Unlocked - Start Ride'),
            ),
          ],
        ),
      ),
    );
  }
}
