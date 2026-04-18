import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bike.dart';
import '../models/bike_rental_record.dart';
import '../models/ride.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class _OwnerData {
  final List<Ride> rides;
  final Bike? bike;
  final double withdrawnEarnings;
  const _OwnerData({
    required this.rides,
    required this.bike,
    required this.withdrawnEarnings,
  });
}

class OwnerRentalHistoryScreen extends StatefulWidget {
  const OwnerRentalHistoryScreen({super.key});

  @override
  State<OwnerRentalHistoryScreen> createState() =>
      _OwnerRentalHistoryScreenState();
}

class _OwnerRentalHistoryScreenState extends State<OwnerRentalHistoryScreen> {
  late Future<_OwnerData> _dataFuture;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_OwnerData> _loadData() async {
    final api = ApiService();
    final bike = await api.fetchOwnerBike(UserSession.userId);
    final results = await Future.wait([
      bike != null
          ? api.fetchBikeRides(bike.id)
          : Future.value(<Ride>[]),
      api.fetchWithdrawnEarnings(UserSession.userId),
    ]);
    return _OwnerData(
      rides: results[0] as List<Ride>,
      bike: bike,
      withdrawnEarnings: results[1] as double,
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}min';
    return '${d.inMinutes} min';
  }

  Future<void> _withdraw(double pendingAmount) async {
    if (pendingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No earnings available to withdraw.')),
      );
      return;
    }
    setState(() => _withdrawing = true);
    try {
      await ApiService().withdrawEarnings(UserSession.userId, pendingAmount);
      if (!mounted) return;
      // Reload data so the UI reflects the new withdrawn amount
      setState(() {
        _dataFuture = _loadData();
        _withdrawing = false;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 60),
              const SizedBox(height: 16),
              const Text('Withdrawal Requested!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              Text(
                '₹${pendingAmount.toStringAsFixed(0)} will be credited to your UPI in 24 hours.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(color: Color(0xFF2E7D32))),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Withdrawal failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('My Bike Earnings'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder<_OwnerData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load history: ${snapshot.error}'),
            );
          }

          final rides = snapshot.data!.rides;
          final bike = snapshot.data!.bike;
          final completedRides = rides.where((r) => r.status == 'completed').toList();
          final totalEarned = completedRides.fold(0.0, (s, r) => s + r.cost * 0.7);
          final withdrawn = snapshot.data!.withdrawnEarnings;
          final pending = (totalEarned - withdrawn).clamp(0.0, double.infinity);
          final earnings = OwnerEarnings(
            totalRentals: completedRides.length,
            totalEarnings: totalEarned,
            withdrawn: withdrawn,
            pendingWithdrawal: pending,
          );

          final bikeLabel = bike != null
              ? 'Bike ${bike.id} • ${bike.station}'
              : 'No bike listed yet';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.electric_bike_rounded,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(bikeLabel,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _EarningsStat(
                                    label: 'Total Rentals',
                                    value: '${earnings.totalRentals}',
                                    icon: Icons.people_rounded),
                                Container(
                                    width: 1, height: 50, color: Colors.white24),
                                _EarningsStat(
                                    label: 'Total Earned',
                                    value:
                                        '₹${earnings.totalEarnings.toStringAsFixed(0)}',
                                    icon: Icons.currency_rupee_rounded),
                                Container(
                                    width: 1, height: 50, color: Colors.white24),
                                _EarningsStat(
                                    label: 'Withdrawn',
                                    value:
                                        '₹${earnings.withdrawn.toStringAsFixed(0)}',
                                    icon: Icons.account_balance_rounded),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Available to Withdraw',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  Text(
                                    '₹${earnings.pendingWithdrawal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: bike != null
                                  ? () => _showBikeStatusSheet(context, bike)
                                  : null,
                              icon: const Icon(Icons.info_outline_rounded,
                                  size: 18),
                              label: const Text('View Bike Status'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side:
                                    const BorderSide(color: Color(0xFF2E7D32)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _withdrawing
                                  ? null
                                  : () => _withdraw(earnings.pendingWithdrawal),
                              icon: _withdrawing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 18),
                              label: Text(
                                  _withdrawing ? 'Processing…' : 'Withdraw'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 8),
                      Text('Rental History',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20))),
                      const Spacer(),
                      Text('${rides.length} rides',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _BikeRideCard(
                      ride: rides[i], formatDuration: _formatDuration),
                  childCount: rides.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  void _showBikeStatusSheet(BuildContext context, Bike bike) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bike Status',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 20),
            _StatusRow(
                icon: Icons.electric_bike_rounded,
                label: 'Bike ID',
                value: bike.id,
                color: const Color(0xFF2E7D32)),
            const Divider(height: 24),
            _StatusRow(
                icon: Icons.location_on_rounded,
                label: 'Current Stand',
                value: bike.station,
                color: const Color(0xFF1565C0)),
            const Divider(height: 24),
            _StatusRow(
                icon: Icons.circle_rounded,
                label: 'Status',
                value: bike.isAvailable ? 'Available' : 'On Ride',
                color: bike.isAvailable
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1565C0)),
            const Divider(height: 24),
            // Hourly rate row with edit button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.currency_rupee_rounded,
                      color: Color(0xFF6A1B9A), size: 18),
                ),
                const SizedBox(width: 14),
                const Text('Hourly Rate',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const Spacer(),
                Text('₹${bike.pricePerHour.toInt()}/hr',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A1B9A),
                        fontSize: 14)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showEditRateDialog(bike);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditRateDialog(Bike bike) {
    final controller =
        TextEditingController(text: bike.pricePerHour.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Hourly Rate',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹ ',
            suffixText: '/hr',
            hintText: '10',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 1 || value > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a valid rate between ₹1–₹200.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService().updatePricePerHour(bike.id, value);
                if (!mounted) return;
                setState(() { _dataFuture = _loadData(); });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Rate updated to ₹${value.toInt()}/hr.'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update rate: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _EarningsStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _BikeRideCard extends StatelessWidget {
  final Ride ride;
  final String Function(Duration) formatDuration;
  const _BikeRideCard({required this.ride, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    final isActive = ride.status == 'active';
    final isPaid = ride.paymentStatus == 'paid';
    final dateStr = DateFormat('dd MMM yyyy').format(ride.startTime);
    final timeStr = DateFormat('hh:mm a').format(ride.startTime);
    final earnings = ride.cost * 0.7;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.renterName.isNotEmpty ? ride.renterName : 'Unknown Renter',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                            fontSize: 15),
                      ),
                      Text('$dateStr • $timeStr',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isActive ? 'Active' : '₹${earnings.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF2E7D32),
                          fontSize: 16),
                    ),
                    if (!isActive)
                      Text('your cut (70%)',
                          style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Tag(
                  label: isActive ? 'Active' : 'Completed',
                  color: isActive ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                if (!isActive)
                  _Tag(
                    label: isPaid ? 'Paid' : 'Unpaid',
                    color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                  ),
                const Spacer(),
                if (!isActive) ...[
                  const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(formatDuration(ride.duration),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ],
            ),
            if (ride.fromStation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.route_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ride.toStation.isNotEmpty
                          ? '${ride.fromStation} → ${ride.toStation}'
                          : ride.fromStation,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatusRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 14)),
      ],
    );
  }
}
