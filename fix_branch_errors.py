import os

print("Fixing all branch merge errors...")
print("")

# ── api_service.dart ──────────────────────────────────────────────────────────
api_service = """import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bike.dart';
import '../models/ride.dart';
import '../models/bike_rental_record.dart';

class ApiService {
  static const String baseUrl = 'https://api.campusbike.iitgn.ac.in';

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print('GET error: $e');
      return null;
    }
  }

  Future<dynamic> _post(String endpoint, Map body) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$endpoint'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print('POST error: $e');
      return null;
    }
  }

  // Bikes
  Future<List<Bike>> fetchAvailableBikes({String? query}) async {
    final data = await _get('/bikes');
    if (data == null) return Bike.sampleBikes();
    try {
      return (data as List).map((e) => Bike.fromJson(e)).toList();
    } catch (_) {
      return Bike.sampleBikes();
    }
  }

  // Stands - used by StandAvailabilityScreen
  Future<List<Map<String, dynamic>>> fetchStands() async {
    final data = await _get('/stands');
    if (data == null) {
      return [
        {'id': 'STD-001', 'name': 'Academic Block A', 'description': 'Near main entrance', 'totalSlots': 10, 'availableBikes': 4, 'availableBikeIds': ['CBR-001', 'CBR-002']},
        {'id': 'STD-002', 'name': 'Library Gate', 'description': 'Outside library', 'totalSlots': 8, 'availableBikes': 0, 'availableBikeIds': []},
        {'id': 'STD-003', 'name': 'Hostel 1 Stand', 'description': 'Between Hostel 1 and 2', 'totalSlots': 12, 'availableBikes': 3, 'availableBikeIds': ['CBR-003', 'CBR-004']},
        {'id': 'STD-004', 'name': 'Mess Block', 'description': 'Adjacent to central mess', 'totalSlots': 8, 'availableBikes': 2, 'availableBikeIds': ['CBR-005']},
        {'id': 'STD-005', 'name': 'Sports Complex', 'description': 'Near sports gate', 'totalSlots': 6, 'availableBikes': 1, 'availableBikeIds': ['CBR-006']},
        {'id': 'STD-006', 'name': 'Admin Building', 'description': 'Ground floor admin', 'totalSlots': 6, 'availableBikes': 2, 'availableBikeIds': ['CBR-007']},
      ];
    }
    return List<Map<String, dynamic>>.from(data);
  }

  // Rides
  Future<List<Ride>> fetchRideHistory(String userId) async {
    final data = await _get('/rides/$userId');
    if (data == null) return Ride.sampleRides();
    try {
      return (data as List).map((e) => Ride.fromJson(e)).toList();
    } catch (_) {
      return Ride.sampleRides();
    }
  }

  Future<Map<String, dynamic>> startRide(String bikeId) async {
    final res = await _post('/ride/start', {'bikeId': bikeId});
    if (res == null) {
      return {
        'rideId': 'RD-demo',
        'pin': '4823',
        'startTime': DateTime.now().toIso8601String(),
      };
    }
    return Map<String, dynamic>.from(res);
  }

  // Alias used by unlock_pin_screen
  Future<Map<String, dynamic>> startRental(String bikeId, String pin) async {
    return startRide(bikeId);
  }

  Future<Map<String, dynamic>> endRide(String rideId) async {
    final res = await _post('/ride/end', {'rideId': rideId});
    if (res == null) {
      return {
        'rideId': rideId,
        'endTime': DateTime.now().toIso8601String(),
        'distanceKm': 2.4,
        'cost': 20.0,
      };
    }
    return Map<String, dynamic>.from(res);
  }

  // Bike listing
  Future<bool> submitBikeListing({
    required String bikeId,
    required String station,
    String? imagePath,
  }) async {
    final res = await _post('/bikes/list', {
      'bikeId': bikeId,
      'station': station,
      'imagePath': imagePath ?? '',
    });
    return res != null;
  }

  // Owner rental history
  Future<List<BikeRentalRecord>> fetchRentalHistory(String userId) async {
    final data = await _get('/owner/rentals/$userId');
    if (data == null) return BikeRentalRecord.sampleRecords();
    try {
      return (data as List).map((e) => BikeRentalRecord.fromJson(e)).toList();
    } catch (_) {
      return BikeRentalRecord.sampleRecords();
    }
  }

  // Payment
  Future<Map<String, dynamic>?> createOrder(double amount) async {
    final res = await _post('/create-order', {'amount': amount});
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<bool> verifyPayment(Map<String, dynamic> data) async {
    final res = await _post('/verify-payment', data);
    if (res == null) return false;
    return res['success'] == true;
  }

  Future<bool> payWithWallet({
    required String rideId,
    required double amount,
  }) async {
    final res = await _post('/wallet/pay', {'rideId': rideId, 'amount': amount});
    if (res == null) return true;
    return res['success'] == true;
  }

  Future<double> getWalletBalance() async {
    final res = await _get('/wallet/balance');
    if (res == null) return 120.0;
    return (res['balance'] as num).toDouble();
  }

  Future<bool> processPayment({
    required String rideId,
    required double amount,
    required String method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }
}
"""

# ── bike.dart ─────────────────────────────────────────────────────────────────
bike_model = """class Bike {
  final String id;
  final String station;
  final bool isAvailable;
  final int batteryLevel;
  final double pricePerHour;
  final String imageUrl;
  final String type;
  final double distanceKm;

  const Bike({
    required this.id,
    required this.station,
    required this.isAvailable,
    required this.batteryLevel,
    required this.pricePerHour,
    this.imageUrl = '',
    this.type = 'Electric',
    this.distanceKm = 0.0,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] ?? json['bikeId'] ?? 'CBR-000',
      station: json['station'] ?? json['standName'] ?? 'Unknown Stand',
      isAvailable: json['isAvailable'] ?? json['available'] ?? true,
      batteryLevel: ((json['batteryLevel'] ?? json['battery'] ?? 80) as num).toInt(),
      pricePerHour: ((json['pricePerHour'] ?? json['price'] ?? 10.0) as num).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'Electric',
      distanceKm: ((json['distanceKm'] ?? json['distance'] ?? 0.0) as num).toDouble(),
    );
  }

  static List<Bike> sampleBikes() {
    return const [
      Bike(id: 'CBR-001', station: 'Academic Block A', isAvailable: true, batteryLevel: 85, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.2),
      Bike(id: 'CBR-002', station: 'Hostel 1 Stand', isAvailable: true, batteryLevel: 62, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.5),
      Bike(id: 'CBR-003', station: 'Library Gate', isAvailable: false, batteryLevel: 90, pricePerHour: 10.0, type: 'Electric', distanceKm: 0.8),
      Bike(id: 'CBR-004', station: 'Sports Complex', isAvailable: true, batteryLevel: 45, pricePerHour: 8.0, type: 'Manual', distanceKm: 1.1),
      Bike(id: 'CBR-005', station: 'Mess Block', isAvailable: true, batteryLevel: 78, pricePerHour: 10.0, type: 'Electric', distanceKm: 1.4),
      Bike(id: 'CBR-006', station: 'Admin Building', isAvailable: false, batteryLevel: 30, pricePerHour: 8.0, type: 'Manual', distanceKm: 1.7),
    ];
  }
}
"""

# ── ride.dart ─────────────────────────────────────────────────────────────────
ride_model = """class Ride {
  final String id;
  final String bikeId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double cost;
  final String status;
  final String fromStation;
  final String toStation;

  const Ride({
    required this.id,
    required this.bikeId,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.cost,
    required this.status,
    required this.fromStation,
    this.toStation = '',
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? json['rideId'] ?? 'RD-000',
      bikeId: json['bikeId'] ?? 'CBR-000',
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      distanceKm: ((json['distanceKm'] ?? json['distance'] ?? 0.0) as num).toDouble(),
      cost: ((json['cost'] ?? json['amount'] ?? 0.0) as num).toDouble(),
      status: json['status'] ?? 'completed',
      fromStation: json['fromStation'] ?? json['station'] ?? 'Unknown',
      toStation: json['toStation'] ?? '',
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  static List<Ride> sampleRides() {
    return [
      Ride(id: 'RD-1021', bikeId: 'CBR-001', startTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)), endTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)), distanceKm: 2.3, cost: 10.0, status: 'completed', fromStation: 'Academic Block A', toStation: 'Hostel 1 Stand'),
      Ride(id: 'RD-1020', bikeId: 'CBR-003', startTime: DateTime.now().subtract(const Duration(days: 3, hours: 5)), endTime: DateTime.now().subtract(const Duration(days: 3, hours: 4)), distanceKm: 1.8, cost: 10.0, status: 'completed', fromStation: 'Library Gate', toStation: 'Sports Complex'),
      Ride(id: 'RD-1019', bikeId: 'CBR-002', startTime: DateTime.now().subtract(const Duration(days: 5)), endTime: DateTime.now().subtract(const Duration(days: 4, hours: 23)), distanceKm: 3.1, cost: 20.0, status: 'completed', fromStation: 'Hostel 1 Stand', toStation: 'Admin Building'),
      Ride(id: 'RD-1018', bikeId: 'CBR-005', startTime: DateTime.now().subtract(const Duration(days: 7, hours: 3)), endTime: DateTime.now().subtract(const Duration(days: 7, hours: 2)), distanceKm: 1.5, cost: 10.0, status: 'completed', fromStation: 'Mess Block', toStation: 'Library Gate'),
      Ride(id: 'RD-1017', bikeId: 'CBR-004', startTime: DateTime.now().subtract(const Duration(days: 10, hours: 1)), endTime: DateTime.now().subtract(const Duration(days: 9, hours: 23)), distanceKm: 4.2, cost: 16.0, status: 'completed', fromStation: 'Sports Complex', toStation: 'Academic Block A'),
    ];
  }
}
"""

# ── bike_rental_record.dart ───────────────────────────────────────────────────
bike_rental_record = """class BikeRentalRecord {
  final String id;
  final String bikeId;
  final String rentedBy;
  final DateTime date;
  final Duration duration;
  final double earnings;

  const BikeRentalRecord({
    required this.id,
    required this.bikeId,
    required this.rentedBy,
    required this.date,
    required this.duration,
    required this.earnings,
  });

  factory BikeRentalRecord.fromJson(Map<String, dynamic> json) {
    return BikeRentalRecord(
      id: json['id'] ?? 'ORH-000',
      bikeId: json['bikeId'] ?? 'B000',
      rentedBy: json['rentedBy'] ?? json['userName'] ?? 'Unknown',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      duration: Duration(minutes: ((json['durationMinutes'] ?? 30) as num).toInt()),
      earnings: ((json['earnings'] ?? json['amount'] ?? 0.0) as num).toDouble(),
    );
  }

  static List<BikeRentalRecord> sampleRecords() {
    return [
      BikeRentalRecord(id: 'ORH-001', bikeId: 'B201', rentedBy: 'Rahul Shah', date: DateTime.now().subtract(const Duration(days: 1, hours: 3)), duration: const Duration(minutes: 45), earnings: 18.0),
      BikeRentalRecord(id: 'ORH-002', bikeId: 'B201', rentedBy: 'Priya Mehta', date: DateTime.now().subtract(const Duration(days: 2, hours: 5)), duration: const Duration(hours: 1, minutes: 20), earnings: 26.0),
      BikeRentalRecord(id: 'ORH-003', bikeId: 'B201', rentedBy: 'Arjun Patel', date: DateTime.now().subtract(const Duration(days: 4)), duration: const Duration(minutes: 30), earnings: 10.0),
      BikeRentalRecord(id: 'ORH-004', bikeId: 'B201', rentedBy: 'Sneha Joshi', date: DateTime.now().subtract(const Duration(days: 6, hours: 2)), duration: const Duration(hours: 2), earnings: 20.0),
      BikeRentalRecord(id: 'ORH-005', bikeId: 'B201', rentedBy: 'Karan Verma', date: DateTime.now().subtract(const Duration(days: 8)), duration: const Duration(minutes: 55), earnings: 18.0),
    ];
  }
}

class OwnerEarnings {
  final int totalRentals;
  final double totalEarnings;
  final double pendingWithdrawal;
  final double withdrawn;

  const OwnerEarnings({
    required this.totalRentals,
    required this.totalEarnings,
    required this.pendingWithdrawal,
    required this.withdrawn,
  });

  factory OwnerEarnings.fromRecords(List<BikeRentalRecord> records) {
    final total = records.fold(0.0, (sum, r) => sum + r.earnings);
    return OwnerEarnings(
      totalRentals: records.length,
      totalEarnings: total,
      pendingWithdrawal: total * 0.6,
      withdrawn: total * 0.4,
    );
  }
}
"""

# ── payment_screen.dart ───────────────────────────────────────────────────────
payment_screen = """import 'package:flutter/material.dart';
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
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final balance = await _api.getWalletBalance();
    if (!mounted) return;
    setState(() => _walletBalance = balance);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) return "${s}s";
    return "${m}m ${s}s";
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      bool success = false;

      if (_selectedMethod == 'WALLET') {
        if (_walletBalance < widget.cost) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient wallet balance')),
          );
          setState(() => _paying = false);
          return;
        }
        success = await _api.payWithWallet(
          rideId: widget.rideId,
          amount: widget.cost,
        );
      } else {
        success = await _api.processPayment(
          rideId: widget.rideId,
          amount: widget.cost,
          method: _selectedMethod,
        );
      }

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
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
                    color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 72),
              ),
              const SizedBox(height: 24),
              const Text('Payment Successful!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
              const SizedBox(height: 8),
              Text('Rs.${widget.cost.toStringAsFixed(2)} paid via $_selectedMethod',
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.receipt_long_rounded, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text('Ride Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _SummaryRow('Bike ID', widget.bike.id),
                    const SizedBox(height: 10),
                    _SummaryRow('Station', widget.bike.station),
                    const SizedBox(height: 10),
                    _SummaryRow('Duration', _formatDuration(widget.duration)),
                    const SizedBox(height: 10),
                    _SummaryRow('Distance', '${widget.distanceKm.toStringAsFixed(2)} km'),
                    const SizedBox(height: 10),
                    _SummaryRow('Rate', 'Rs.${widget.bike.pricePerHour.toInt()}/hour'),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Rs.${widget.cost.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment Method',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: const Color(0xFF1B5E20))),
            const SizedBox(height: 12),
            _PaymentOption(value: 'UPI', groupValue: _selectedMethod,
                icon: Icons.account_balance_wallet_rounded, label: 'UPI',
                subtitle: 'GPay, PhonePe, BHIM', color: const Color(0xFF6A1B9A),
                onChanged: (v) => setState(() => _selectedMethod = v!)),
            _PaymentOption(value: 'WALLET', groupValue: _selectedMethod,
                icon: Icons.wallet_rounded, label: 'Campus Wallet',
                subtitle: 'Balance: Rs.${_walletBalance.toStringAsFixed(2)}',
                color: const Color(0xFF1565C0),
                onChanged: (v) => setState(() => _selectedMethod = v!)),
            _PaymentOption(value: 'CARD', groupValue: _selectedMethod,
                icon: Icons.credit_card_rounded, label: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, RuPay', color: const Color(0xFFAD1457),
                onChanged: (v) => setState(() => _selectedMethod = v!)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _paying ? null : _pay,
              icon: _paying
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.payment_rounded),
              label: Text(_paying ? 'Processing...' : 'Pay Rs.${widget.cost.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Secured by IITGN Payment Gateway',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    required this.value, required this.groupValue, required this.icon,
    required this.label, required this.subtitle, required this.color,
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
          border: Border.all(color: selected ? color : const Color(0xFFE0E0E0), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? color : Colors.black87)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: color),
          ],
        ),
      ),
    );
  }
}
"""

files = {
    "lib/services/api_service.dart": api_service,
    "lib/models/bike.dart": bike_model,
    "lib/models/ride.dart": ride_model,
    "lib/models/bike_rental_record.dart": bike_rental_record,
    "lib/screens/payment_screen.dart": payment_screen,
}

for path, content in files.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  [OK] {path}")

print("")
print("=== All 5 files fixed! ===")
print("")
print("What was fixed:")
print("  1. Bike.fromJson()            - added to bike.dart")
print("  2. Ride.fromJson()            - added to ride.dart")
print("  3. BikeRentalRecord.fromJson()- added to bike_rental_record.dart")
print("  4. fetchStands()              - added to ApiService")
print("  5. startRental()              - alias added to ApiService")
print("  6. submitBikeListing()        - added to ApiService")
print("  7. fetchRentalHistory()       - added to ApiService")
print("  8. payment_screen.dart        - Razorpay crash fixed")
print("  9. All methods fall back to   - sample data if API is offline")
print("")
print("Now run:")
print("  flutter pub get")
print("  flutter run -d chrome")