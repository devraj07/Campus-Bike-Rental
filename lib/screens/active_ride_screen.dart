import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../services/api_service.dart';
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
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  double _distance = 0.0;
  final _api = ApiService();
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
        _distance = (_elapsed.inSeconds * 0.0005);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _cost {
    final hours = _elapsed.inSeconds / 3600.0;
    return (hours * widget.bike.pricePerHour).clamp(0, double.infinity);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, "0");
    final m = (d.inMinutes % 60).toString().padLeft(2, "0");
    final s = (d.inSeconds % 60).toString().padLeft(2, "0");
    return "$h:$m:$s";
  }

  Future<void> _endRide() async {
    setState(() => _ending = true);
    _timer?.cancel();
    try {
      await _api.endRide(widget.rideId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            bike: widget.bike,
            rideId: widget.rideId,
            duration: _elapsed,
            distanceKm: _distance,
            cost: _cost,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text("Active Ride"),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text("RIDE IN PROGRESS",
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
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Ride Duration",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Text(_formatDuration(_elapsed),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatCard(
                      icon: Icons.electric_bike_rounded,
                      label: "Bike ID",
                      value: widget.bike.id,
                      color: const Color(0xFF1565C0))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                      icon: Icons.route_rounded,
                      label: "Distance",
                      value: "${_distance.toStringAsFixed(2)} km",
                      color: const Color(0xFF6A1B9A))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(
                      icon: Icons.currency_rupee_rounded,
                      label: "Current Cost",
                      value: "Rs.${_cost.toStringAsFixed(2)}",
                      color: const Color(0xFF2E7D32))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                      icon: Icons.speed_rounded,
                      label: "Avg Speed",
                      value: _elapsed.inSeconds > 0
                          ? "${(_distance / (_elapsed.inSeconds / 3600)).toStringAsFixed(1)} km/h"
                          : "0.0 km/h",
                      color: const Color(0xFFF57C00))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You have saved ${(_distance * 0.21).toStringAsFixed(0)}g CO2 by cycling!",
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _ending ? null : _endRide,
                icon: _ending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.stop_circle_outlined),
                label: Text(_ending ? "Ending Ride..." : "End Ride"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
