import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../models/bike_state.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../services/user_session.dart';
import 'payment_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final Bike bike;
  final String rideId;
  final DateTime startTime;

  const ActiveRideScreen({
    super.key,
    required this.bike,
    required this.rideId,
    required this.startTime,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final _api = ApiService();
  final _mqtt = MqttService();
  bool _ending = false;
  bool _waitingForHardware = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _endSub;
  Timer? _hardwareTimeout;
  String? _pendingToStation;

  @override
  void initState() {
    super.initState();
    _startMqttListener();
  }

  Future<void> _startMqttListener() async {
    try {
      await _mqtt.connect();
      _mqtt.listenForRideEnd('1', widget.rideId);
    } catch (_) {
      // MQTT unavailable — Firestore fallback still works
    }
  }

  @override
  void dispose() {
    _endSub?.cancel();
    _hardwareTimeout?.cancel();
    _mqtt.disconnect();
    super.dispose();
  }

  String _formatStartTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _elapsedLabel() {
    final d = DateTime.now().difference(widget.startTime);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _endRide() async {
    final toStation = await _showDropStandPicker();
    if (!mounted) return;

    _pendingToStation = toStation;
    setState(() {
      _ending = true;
      _waitingForHardware = true;
    });

    // 1. Signal ESP32 to lock the bike
    try {
      await _api.signalEndRide(widget.bike.id);
    } catch (_) {
      // If signal fails, fall back to client-side immediately
      if (mounted) _finishRide(null);
      return;
    }

    // 2. Listen to ride doc for rideDurationSeconds written by ESP32
    _endSub = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snap) {
      final secs = snap.data()?['rideDurationSeconds'] as int?;
      if (secs != null && mounted) {
        _endSub?.cancel();
        _hardwareTimeout?.cancel();
        _finishRide(secs);
      }
    });

    // 3. 30-second fallback — use client-side time if hardware doesn't respond
    _hardwareTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted && _waitingForHardware) {
        _endSub?.cancel();
        _finishRide(null);
      }
    });
  }

  Future<void> _finishRide(int? hardwareDurationSeconds) async {
    if (!mounted) return;
    try {
      final result = await _api.endRide(
        widget.rideId,
        toStation: _pendingToStation,
        hardwareDurationSeconds: hardwareDurationSeconds,
      );
      if (!mounted) return;
      UserSession.endRide();
      final finalCost = (result['cost'] as num).toDouble();
      final finalDuration =
          Duration(minutes: (result['durationMinutes'] as num).toInt());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            bike: widget.bike,
            rideId: widget.rideId,
            duration: finalDuration,
            cost: finalCost,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ending = false;
        _waitingForHardware = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end ride: $e')),
      );
    }
  }

  void _showBackWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF9A825)),
          SizedBox(width: 8),
          Text('Ride Still Active'),
        ]),
        content: const Text(
          'Your ride is in progress and billing is running.\n\n'
          'Use the "End Ride" button to stop billing and return the bike.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Stay on Ride'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showDropStandPicker() async {
    List<StandAvailability> stands = [];
    try {
      stands = await _api.fetchStands();
    } catch (_) {}

    if (!mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DropStandSheet(stands: stands),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showBackWarning();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Active Ride'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('RIDE IN PROGRESS',
                        style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Elapsed Time',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(
                      _elapsedLabel(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Started at ${_formatStartTime(widget.startTime)}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_waitingForHardware)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFF9A825)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Locking bike… waiting for hardware confirmation.',
                          style: TextStyle(
                              color: Color(0xFF5D4037), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.electric_bike_rounded,
                      label: 'Bike ID',
                      value: widget.bike.id,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Rate',
                      value: '₹${widget.bike.pricePerHour.toInt()}/hr',
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _ending ? null : _endRide,
                icon: _ending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(_ending ? 'Ending Ride...' : 'End Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ), // PopScope
    );
  }
}

// ── Drop Stand Picker ──────────────────────────────────────────────────────

class _DropStandSheet extends StatefulWidget {
  final List<StandAvailability> stands;
  const _DropStandSheet({required this.stands});

  @override
  State<_DropStandSheet> createState() => _DropStandSheetState();
}

class _DropStandSheetState extends State<_DropStandSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_parking_rounded,
                  color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Select Drop-off Stand',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose where you\'re parking the bike.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (widget.stands.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No stands available.',
                  style: TextStyle(color: Colors.grey))),
            )
          else
            ...widget.stands.map((s) => _StandTile(
                  stand: s,
                  selected: _selected == s.standName,
                  onTap: () => setState(() => _selected = s.standName),
                )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirm Drop-off'),
          ),
        ],
      ),
    );
  }
}

class _StandTile extends StatelessWidget {
  final StandAvailability stand;
  final bool selected;
  final VoidCallback onTap;

  const _StandTile(
      {required this.stand, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F5E9)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: selected
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stand.standName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xFF1B5E20)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    '${stand.availableBikes}/${stand.totalSlots} slots free',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 15),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
