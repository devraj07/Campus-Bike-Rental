import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Bike bike;
  final String rideId;
  final Duration duration;
  final double distanceKm;
  final double cost;

  const PaymentScreen({
    super.key,
    required this.bike,
    required this.rideId,
    required this.duration,
    required this.distanceKm,
    required this.cost,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'UPI';
  bool _paying = false;
  bool _paid = false;
  final _api = ApiService();

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final success = await _api.processPayment(
        rideId: widget.rideId,
        amount: widget.cost,
        method: _selectedMethod,
      );
      if (!mounted) return;
      if (success) {
        setState(() => _paid = true);
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_paid) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FBF0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 72),
              ),
              const SizedBox(height: 24),
              const Text('Payment Successful!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              Text('₹${widget.cost.toStringAsFixed(2)} paid via $_selectedMethod',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF0),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          'Ride Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _SummaryRow('Bike ID', widget.bike.id),
                    const SizedBox(height: 10),
                    _SummaryRow('Station', widget.bike.station),
                    const SizedBox(height: 10),
                    _SummaryRow('Duration', _formatDuration(widget.duration)),
                    const SizedBox(height: 10),
                    _SummaryRow('Distance',
                        '${widget.distanceKm.toStringAsFixed(2)} km'),
                    const SizedBox(height: 10),
                    _SummaryRow('Rate',
                        '₹${widget.bike.pricePerHour.toInt()}/hour'),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '₹${widget.cost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 12),
            // Payment Methods
            _PaymentOption(
              value: 'UPI',
              groupValue: _selectedMethod,
              icon: Icons.account_balance_wallet_rounded,
              label: 'UPI',
              subtitle: 'GPay, PhonePe, BHIM',
              color: const Color(0xFF6A1B9A),
              onChanged: (v) => setState(() => _selectedMethod = v!),
            ),
            _PaymentOption(
              value: 'WALLET',
              groupValue: _selectedMethod,
              icon: Icons.wallet_rounded,
              label: 'Campus Wallet',
              subtitle: 'Balance: ₹120.00',
              color: const Color(0xFF1565C0),
              onChanged: (v) => setState(() => _selectedMethod = v!),
            ),
            _PaymentOption(
              value: 'CARD',
              groupValue: _selectedMethod,
              icon: Icons.credit_card_rounded,
              label: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
              color: const Color(0xFFAD1457),
              onChanged: (v) => setState(() => _selectedMethod = v!),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.payment_rounded),
              label: Text(_paying
                  ? 'Processing…'
                  : 'Pay ₹${widget.cost.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Secured by IITGN Payment Gateway',
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? color : Colors.black87)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
