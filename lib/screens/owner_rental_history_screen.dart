import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bike_rental_record.dart';
import '../services/api_service.dart';

class OwnerRentalHistoryScreen extends StatefulWidget {
  const OwnerRentalHistoryScreen({super.key});

  @override
  State<OwnerRentalHistoryScreen> createState() =>
      _OwnerRentalHistoryScreenState();
}

class _OwnerRentalHistoryScreenState extends State<OwnerRentalHistoryScreen> {
  late Future<List<BikeRentalRecord>> _historyFuture;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService().fetchRentalHistory('USR-001');
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}min';
    return '${d.inMinutes} min';
  }

  Future<void> _withdraw(double pendingAmount) async {
    setState(() => _withdrawing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _withdrawing = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2E7D32), size: 60),
            const SizedBox(height: 16),
            const Text('Withdrawal Successful!',
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
            child:
                const Text('Done', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
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
      body: FutureBuilder<List<BikeRentalRecord>>(
        future: _historyFuture,
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

          final records = snapshot.data!;
          final earnings = OwnerEarnings.fromRecords(records);

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
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.electric_bike_rounded,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text('Bike B201 • Academic Block A',
                                    style: TextStyle(
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
                                color: Colors.white.withOpacity(0.15),
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
                              onPressed: () => _showBikeStatusSheet(context),
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
                      Text('${records.length} records',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RentalRecordCard(
                      record: records[i], formatDuration: _formatDuration),
                  childCount: records.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  void _showBikeStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
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
                value: 'B201',
                color: const Color(0xFF2E7D32)),
            const Divider(height: 24),
            _StatusRow(
                icon: Icons.location_on_rounded,
                label: 'Current Stand',
                value: 'Academic Block A',
                color: const Color(0xFF1565C0)),
            const Divider(height: 24),
            _StatusRow(
                icon: Icons.circle_rounded,
                label: 'Status',
                value: 'Available',
                color: const Color(0xFF2E7D32)),
            const Divider(height: 24),
            _StatusRow(
                icon: Icons.battery_charging_full_rounded,
                label: 'Battery',
                value: '78%',
                color: const Color(0xFF2E7D32)),
            const SizedBox(height: 20),
          ],
        ),
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

class _RentalRecordCard extends StatelessWidget {
  final BikeRentalRecord record;
  final String Function(Duration) formatDuration;
  const _RentalRecordCard({required this.record, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM').format(record.date);
    final timeStr = DateFormat('hh:mm a').format(record.date);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF2E7D32), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Bike ${record.bikeId}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                              fontSize: 15)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('₹${record.earnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E7D32),
                                fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Rented by: ${record.rentedBy}',
                      style: const TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Duration: ${formatDuration(record.duration)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 14),
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$dateStr • $timeStr',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
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
              color: color.withOpacity(0.1),
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
