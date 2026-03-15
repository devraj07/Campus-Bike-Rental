import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';
import '../services/api_service.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _api = ApiService();
  List<Ride> _rides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final rides = await _api.fetchRideHistory('USR-001');
    setState(() {
      _rides = rides;
      _loading = false;
    });
  }

  double get _totalSpent =>
      _rides.fold(0.0, (sum, r) => sum + r.cost);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : Column(
              children: [
                // Summary banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryCell(
                        icon: Icons.directions_bike_rounded,
                        label: 'Total Rides',
                        value: '${_rides.length}',
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _SummaryCell(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Total Spent',
                        value: '₹${_totalSpent.toStringAsFixed(0)}',
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      _SummaryCell(
                        icon: Icons.eco_rounded,
                        label: 'CO₂ Saved',
                        value:
                            '${(_rides.fold(0.0, (s, r) => s + r.distanceKm) * 0.21).toStringAsFixed(0)}g',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) => _RideCard(ride: _rides[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCell(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.electric_bike_rounded,
                  color: Color(0xFF2E7D32), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ride.bikeId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${ride.cost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ride.fromStation} → ${ride.toStation}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        formatter.format(ride.startTime),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.duration.inMinutes} min  •  ${ride.distanceKm} km',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
